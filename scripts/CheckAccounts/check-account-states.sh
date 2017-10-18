#!/bin/bash
#
# Usage: ./check-account-states.sh
#

ECHO="echo -e"
KUBECTL="/opt/bin/kubectl"
ETCDCTL="etcdctl"

DEFAULT_VALUE=480
FIELD_NAME="inactiveTimeout"

# Loop over all accounts in etcdand verify the state of each one
USERS=$($ETCDCTL ls /ndslabs/accounts)
for namespace in $USERS; do
	# Print progress (in case of error)
	$ECHO "Checking $namespace/account..."

	# Fix any unescaped control characters in account object
        output=$($ETCDCTL get $namespace/account  | sed -e 's#\\n# #g')

	# Verify correct settings for inactive service timeout
	timeout=$($ECHO $output | jq ".$FIELD_NAME")
	if [ "$timeout" == "null" -o "$timeout" == "0" ]; then
		$ECHO "Found missing timeout: $namespace => $timeout. Adjusting to $DEFAULT_VALUE"
		fixed_json=$($ECHO $output | jq --compact-output ".$FIELD_NAME = $DEFAULT_VALUE" | sed -e '#\"#\\"#g' | sed -e '#\#\\#g')
		$ECHO "New JSON: ${fixed_json}"
		read -p 'Replace existing JSON with the above value? [y/N] ' replace
        	if [ "${replace:0:1}" == "y" -o "${replace:0:1}" == "Y" ]; then
			results=$($ETCDCTL set $namespace/account "$fixed_json")
        	fi
        fi
done

# TODO: Loop over the rest of all namespaces and verify the state of each one
#USERS=$($KUBECTL get secret --all-namespaces | grep tls | grep -v default | grep -v kube-system | awk '{print $1}')
#for namespace in $USERS; do
#        $ECHO "Checking Kubernetes namespace $namespace"
#done
