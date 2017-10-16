#!/bin/bash
#
# Usage: ./export-cluster-templates.sh default kube-system namespace3 ...
#
# This script assumes file write permissions on the current directory


KUBECTL="/opt/bin/kubectl"
ECHO="echo -e -n"

# Leave blank => ALL namespaces
NAMESPACES=""
if [ "$1" == "" ]; then
	read -p 'WARNING: No namespaces given - operate on all namespaces? [y/N] ' export_all
        if [ "${export_all:0:1}" != "y" -a "${export_all:0:1}" != "Y" ]; then
            exit 1
        fi
	NAMESPACES="$($KUBECTL get ns | grep -v NAME | awk '{print $1}')"
else
	NAMESPACES="$@"
fi

# Subroutine to export Kubernetes resource to YAML file
# $1 = namespace
# $2 = resource type
# $3 = resource name
function export_resource() {
    if [ "$1" == "" ]; then return 0; fi
    if [ "$2" == "" ]; then return 0; fi
    if [ "$3" == "" ]; then return 0; fi

    namespace="$1"
    type="$2"
    name="$3"

    # If there will be a conflict, confirm before overwriting
    result_file="${namespace}/${name}.${type}.yaml"
    if [ -f "$result_file" ]; then
        overwrite="n"
        read -p "WARNING: file exists: $result_file - overwrite? [y/N] " overwrite
        if [ "${overwrite:0:1}" != "y" -a "${overwrite:0:1}" != "Y" ]; then
            return 0
        fi
    fi

    $ECHO "Writing to $result_file...\n"
    mkdir -p $namespace

    # Export resource YAML, strip out useless metadata
    $KUBECTL get ${type} --namespace=${namespace} ${name} -o yaml | sed -e "s#[ \s]*uid:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*selfLink:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*resourceVersion:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*creationTimestamp:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*clusterIP:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*status:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*sessionAffinity:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*loadBalancer:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*replicas:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*availableReplicas:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*readyReplicas:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*fullyLabeledReplicas:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*observedGeneration:[ \s]*.*[ \s]*##" | sed -e "s#[ \s]*deployment:[ \s]*.*[ \s]*##" > $result_file
    return 1
}


# Loop over given namespaces and export all ingress / services / rcs within
for namespace in $NAMESPACES; do
        $ECHO "Exporting all templates from $namespace: "

	INGRESSES="$($KUBECTL get ingress --namespace=$namespace | grep -v NAME | awk '{print $1}')"
	for ingress in $INGRESS; do
		export_resource $namespace ingress $ingress
	done

	SERVICES="$($KUBECTL get services --namespace=$namespace | grep -v NAME | awk '{print $1}')"
	for service in $SERVICE; do
		export_resource $namespace svc $service
	done

	RCS="$($KUBECTL get rc --namespace=$namespace | grep -v NAME | awk '{print $1}')"
	for rc in $RCS; do
		export_resource $namespace rc $rc
	done
done

$ECHO "Done.\n"
