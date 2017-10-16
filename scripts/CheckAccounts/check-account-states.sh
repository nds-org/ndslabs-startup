#!/bin/bash
#
# Usage: ./check-account-states.sh [-f]
#

ECHO="echo -e -n"

# Assumes multi-node, falls back to single-node
KUBECTL="$(which kubectl) || /home/core/bin/kubectl"
ETCDCTL="$(which etcdctl) || $KUBECTL exec -it $($KUBECTL get pods | grep ndslabs-etcd | grep -v Terminating | awk '{print $1}') etcdctl"

# Loop over all accounts in etcdand verify the state of each one
USERS=$($ETCDCTL ls /ndslabs/accounts)
#USERS="/ndslabs/accounts/lambert8"
for namespace in $USERS; do
        $ECHO "Checking etcd account for $namespace\n"
        output=$($ETCDCTL get ${namespace}/account | grep -v "\"inactiveTimeout\":0" | grep -v "\"inactiveTimeout\":480")
        if [ "$output" == "" ]; then
                $ECHO "Found missing timeout: $namespace\n"
        fi
done

# Loop over the rest of all namespaces and verify the state of each one
#USERS=$($KUBECTL get secret --all-namespaces | grep tls | grep -v default | grep -v kube-system | awk '{print $1}')
#for namespace in $USERS; do
#        $ECHO "Checking Kubernetes namespace for $namespace: "
#done

