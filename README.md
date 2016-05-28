# NDSLabs startup

Startup scripts for the NDS Labs services

## Generate TLS certs

```
openssl genrsa 2048 > certs/ndslabs.key
openssl req -new -x509 -nodes -sha1 -days 3650 -key certs/ndslabs.key > certs/ndslabs.cert
#[enter *.ndslabs.org for the Common Name]
cat certs/ndslabs.cert certs/ndslabs.key > certs/ndslabs.pem
chmod 400 certs/ndslabs.key certs/ndslabs.pem
```
