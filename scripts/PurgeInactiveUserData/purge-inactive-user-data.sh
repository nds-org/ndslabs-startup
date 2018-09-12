#!/bin/bash
#
# Usage: ./purge-inactive-user-data.sh [epochThreshold] > ./purge-data.sh; chmod 755 ./purge-data.sh; bash purge-data.sh
#
set -e

ECHO="echo -e"

# Assume Multi-node
# TODO: fall back to single-node?
KUBECTL="$(which kubectl)"

ETCD_POD_NAME="$($KUBECTL get pods | grep -v Terminating | grep ndslabs-etcd | awk '{print $1}')"
ETCDCTL="kubectl exec -it $ETCD_POD_NAME -- etcdctl"

WBAPI_POD_NAME="$($KUBECTL get pods | grep -v Terminating | grep ndslabs-apiserver | awk '{print $1}')"
WBAPI_EXEC="$ECHO kubectl exec -it $WBAPI_POD_NAME -- "
#$ECHO "Pod name: $ETCD_POD_NAME"

# TODO: Roll the default epoch threshold forward occasionally
EPOCH_THRESHOLD=${1:-1525205042}

DEFAULT_TIMEOUT=480
DEFAULT_LASTLOGIN=0

#$ECHO "Printing list of inactive users (since $THRESHOLD):"

# Loop over all accounts in etcd and check for inactivity
USERS=$($ETCDCTL ls /ndslabs/accounts | sed -e 's#\r# #g')
for namespace in $USERS; do
        # Print progress (in case of error)
        namespace="$($ECHO $namespace | sed -e 's#\n##g' | sed -e 's#\r##g')"
#       $ECHO "Checking $namespace/account..."

        # Fix any unescaped control characters in account object
        original_json="$($ETCDCTL get $($ECHO $namespace)/account)"

        # Check if this user has logged in since the checkpoint
        last_login=$($ECHO $original_json | jq ".lastLogin")
        if [ "$last_login" -lt "$EPOCH_THRESHOLD" -a "$last_login" -ne "0" ]; then
#               $ECHO "Purging user data: ${namespace} has been inactive since $last_login.."
                username=$(echo $namespace | awk -F'/' '{print $4}')
                $WBAPI_EXEC bash -c \'rm -rf /data/ndslabs/$username/*\'
#       else
#               $ECHO "$namespace still in use. Skipping..."
        fi
done
