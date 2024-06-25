# nginx HTTPS proxy
This repository contains a bash setup script for creating a fully configured nginx HTTPS proxy Docker image for local web development.

### How to use it?
Run the script:
```
./setup.sh
```
... and follow instructions in the script's output.
### What does it do?
- creates a Certificate Authority
- generates certificates for a given domain and signs them using aforementioned CA
- sets up an nginx configuration, a Dockerfile and a docker-compose.yml
- gives you a summary of what to do next (import CA, hosts entry, commands)

### Why?
It's not always viable to use HTTP-only in local web development, and some browsers i.e. Chrome can give you annoying problems when you're using HTTPS without proper certificates and a trusted authority, for example blocked requests associated with secure cookies, not remembering passwords etc, not to mention plethora of warnings you have to click trough. 
Having a fully configured proxy between a browser and your app solves these problems. 
