#!/bin/bash
#
# First, load the new cert/key into workbench.cert and workbench.key alongside this script.
# Then, run ./update-ssl-secrets.sh to apply that cert to all existing TLS secret
#
set -e

KUBECTL_BIN='kubectl'

ECHO='echo -e -n'
TMP_SECRET='new-tls'
KEY_FILE="workbench.key"
CRT_FILE="workbench.cert"

# Create a temp secret and export it to produce a valid YAML template
$KUBECTL_BIN create secret generic ${TMP_SECRET} --from-file=tls.crt="${CRT_FILE}" --from-file=tls.key="${KEY_FILE}" || exit 1
$KUBECTL_BIN get secret new-tls -o yaml | sed -e "s#[ \s]*uid:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*selfLink:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*resourceVersion:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*creationTimestamp:[ \s]*.*[ \s]*##" > ${TMP_SECRET}.secret.yaml || exit 1
$KUBECTL_BIN delete secret new-tls

# Manually update TLS secret for default namespace
$ECHO "Updating TLS certificate for default: "
cat ${TMP_SECRET}.secret.yaml | sed -e "s#  namespace:.*#  namespace: default#" | sed -e "s#  name:.*#  name: ndslabs-tls-secret#" | $KUBECTL_BIN replace -f -

# Manually update TLS secret for kube-system namespace
$ECHO "Updating TLS certificate for kube-system: "
cat ${TMP_SECRET}.secret.yaml | sed -e "s#  namespace:.*#  namespace: kube-system#" | sed -e "s#  name:.*#  name: ndslabs-tls-secret#" | $KUBECTL_BIN replace -f -

# Loop over the rest of the namespaces to update TLS in each one
USERS=$($KUBECTL_BIN get secret --all-namespaces | grep tls | grep -v default | grep -v kube-system | awk '{print $1}')
for namespace in $USERS; do
        $ECHO "Updating TLS certificate for $namespace: "
        cat ${TMP_SECRET}.secret.yaml | sed -e "s#  namespace:.*#  namespace: ${namespace}#" | sed -e "s#  name:.*#  name: ${namespace}-tls-secret#" | $KUBECTL_BIN replace -f -
done

# TODO: Clean up temp secret file when we're done?
