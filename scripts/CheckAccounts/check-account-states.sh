#!/bin/bash
#
# Usage: ./check-account-states.sh [-f]
#

ECHO="echo -e -n"
KUBECTL="/opt/bin/kubectl"
ETCDCTL="etcdctl"

# Loop over all accounts in etcdand verify the state of each one
USERS=$($ETCDCTL ls /ndslabs/accounts)
#USERS="/ndslabs/accounts/lambert8"
for namespace in $USERS; do
#        $ECHO "Checking etcd account for $namespace: \n"
        output=$($ETCDCTL get ${namespace}/account | jq '.inactiveTimeout')
	if [ "$output" == "null" -o "$output" == "0" ]; then
		$ECHO "Found missing timeout: $namespace => $output\n"
        fi
done

# Loop over the rest of all namespaces and verify the state of each one
#USERS=$($KUBECTL get secret --all-namespaces | grep tls | grep -v default | grep -v kube-system | awk '{print $1}')
#for namespace in $USERS; do
#        $ECHO "Checking Kubernetes namespace for $namespace: "
#done

