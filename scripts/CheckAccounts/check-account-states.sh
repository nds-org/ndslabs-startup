#!/bin/bash
#
# Usage: ./check-account-states.sh
#

ECHO="echo -e "

# Assume Multi-node
# TODO: fall back to single-node?
KUBECTL="$(which kubectl)"
ETCDCTL="$(which etcdctl)"

DEFAULT_TIMEOUT=480
DEFAULT_LASTLOGIN=0

# Loop over all accounts in etcdand verify the state of each one
USERS=$($ETCDCTL ls /ndslabs/accounts)
for namespace in $USERS; do
	# Print progress (in case of error)
	$ECHO "Checking $namespace/account..."

	# Fix any unescaped control characters in account object
	original_json=$($ETCDCTL get $namespace/account  | sed -e 's#\\n# #g')
	fixed_json="$original_json"

	# Verify correct settings for inactive service timeout
	timeout=$($ECHO $fixed_json | jq ".inactiveTimeout")
	if [ "$timeout" == "null" -o "$timeout" == "0" ]; then
		$ECHO "Found missing timeout: $namespace => $timeout. Adjusting to $DEFAULT_TIMEOUT"
		fixed_json=$($ECHO $fixed_json | jq --compact-output ".inactiveTimeout = $DEFAULT_TIMEOUT" | sed -e '#\"#\\"#g' | sed -e '#\#\\#g')
	fi

	# Verify that user has a lastLogin field
	last_login=$($ECHO $fixed_json | jq ".lastLogin")
	if [ "$last_login" == "null" ]; then
		$ECHO "Found missing lastLogin: $namespace => $last_login. Adjusting to $DEFAULT_LASTLOGIN"
		fixed_json=$($ECHO $fixed_json | jq --compact-output ".lastLogin = $DEFAULT_LASTLOGIN" | sed -e '#\"#\\"#g' | sed -e '#\#\\#g')
	fi

	# If our JSON value changed, prompt to update it in etcd
	if [ "$fixed_json" != "$original_json" ]; then
		$ECHO "Currently: ${original_json}"
		$ECHO "New Value: ${fixed_json}"
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
