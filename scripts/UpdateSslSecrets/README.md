# Workbench Scripts: Updating TLS Secrets
This script will replace existing Workbench SSL/TLS certificate (in all namespaces) with a new one. This is useful if your certificate is about to expire and you have already acquired a new one.

# Example Usage

WARNING: This process will overwrite your existing certificates. Before proceeding, please create a **backup** your old certificates if you haven't already.

1. Place your new `workbench.cert` and `workbench.key` files alongside this script (in the same directory - adjust filename/script if necessary)
2. Run the script using `./update-ssl-secrets.sh`


You should see the existing TLS secrets being replaced one by one, as below:
```
core@workbench-master1 ~ $ ./update-cert-secret.sh 
secret "new-tls" created
secret "new-tls" deleted
Updating TLS certificate for default: secret "ndslabs-tls-secret" replaced
Updating TLS certificate for kube-system: secret "ndslabs-tls-secret" replaced
Updating TLS certificate for user1: secret "user1-tls-secret" replaced
Updating TLS certificate for user2: secret "user2-tls-secret" replaced
Updating TLS certificate for user3: secret "user3-tls-secret" replaced
Updating TLS certificate for user4: secret "user4-tls-secret" replaced
Updating TLS certificate for user5: secret "user5-tls-secret" replaced
```
