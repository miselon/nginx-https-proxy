#!/bin/bash

SUBJECT="/C=US/ST=whatever/L=whatever/O=whatever/CN=whatever.com"

set -e

read -p ">>> Enter your domain: " DOMAIN
read -p ">>> Port your local app will be running on: " PORT

# generate CA
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -sha256 -days 9999 -subj $SUBJECT -out ca.pem

# generate domain key and CSR
openssl genrsa -out $DOMAIN.key 2048
openssl req -new -key $DOMAIN.key -subj $SUBJECT -out tmp.csr

# signing config
cat > tmp.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

# sign CSR
openssl x509 -req -in tmp.csr -CA ca.pem -CAkey ca.key -CAcreateserial -out $DOMAIN.crt -days 9999 -sha256 -extfile tmp.ext
rm -f tmp.ext tmp.csr

# setup nginx configuration
NGINX_DIR=nginx-config
rm -rf $NGINX_DIR
mkdir $NGINX_DIR
mv -t $NGINX_DIR $DOMAIN.key $DOMAIN.crt

cat > $NGINX_DIR/nginx.conf << EOF
events {}

http {

	server {
		listen 80;
		listen 443 ssl http2;
		listen [::]:443 ssl http2;

		server_name $DOMAIN;
		ssl_certificate /etc/nginx/$DOMAIN.crt;
		ssl_certificate_key /etc/nginx/$DOMAIN.key;

		location / {
			proxy_pass http://host.docker.internal:$PORT;
		}
	}
}
EOF

# create Dockerfile
cat > Dockerfile << EOF
FROM nginx:latest

COPY ./$NGINX_DIR /etc/nginx

EXPOSE 80
EXPOSE 443
EOF

# create docker-compose
cat > docker-compose.yml << EOF
services:
  nginx:
    image: nginx:latest
    restart: "no"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./$NGINX_DIR:/etc/nginx
    extra_hosts:
      - "host.docker.internal:host-gateway"
EOF

echo "
>>> 1. Add this new entry in /etc/hosts: 127.0.0.1 $DOMAIN
>>> 2. Add this to your browser/other authority trust store: $(pwd)/ca.pem
>>> 3. Run nginx: 
>>>    a) build and run from Dockerfile
>>>         docker build -t nginx-proxy .
>>>         docker run -d -p 80:80 443:443 --add-host="host.docker.internal:host-gateway" nginx-proxy
>>>    b) run with docker-compose up nginx
"
