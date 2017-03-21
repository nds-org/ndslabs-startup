#!/bin/bash

export BINDIR="$HOME/bin"
ECHO='echo -e'

# Ensure that Kubernetes / Labs Workbench are running
./ndslabs.sh --api-only 

if [ "${1,,}" == "down" ]; then
    # Stop Dev version of webui and a cloud9 container
    $ECHO 'Starting developer environment and UI...'
    $BINDIR/kubectl delete svc,rc ndslabs-webui >/dev/null 2>&1
    $BINDIR/kubectl delete svc,rc,ing cloud9 >/dev/null 2>&1

    # Start production version of webui
    $ECHO 'Starting production Labs Workbench UI...'
    $BINDIR/kubectl create -f templates/core/webui.yaml >/dev/null 2>&1

else
    # Ensure that user has created a basic-auth secret
    $BINDIR/kubectl get secret basic-auth >/dev/null 2>&1 || $ECHO 'You will now be prompted for your desired credentials for basic-auth into Cloud9.' && ./kube.sh basic-auth

    # Notify user that source should be cloned to the correct location
    $ECHO "\nThe developer environment assumes that you have the ndslabs source code checked out at /home/core/ndslabs"
    $ECHO "If your path differs, you can manually alter the YAML templates for cloud9 and the webui located in ./templates/dev/"

    # Stop production version of webui, start dev one with cloud9
    $ECHO '\nReplacing Labs Workbench UI with developer instance...'
    $BINDIR/kubectl delete svc,rc ndslabs-webui >/dev/null 2>&1

    $ECHO 'Starting developer environment and UI...'
    $BINDIR/kubectl create -f templates/dev/ >/dev/null 2>&1

    $ECHO 'Waiting for Cloud9 developer environment to start...'
    until $(curl --output /dev/null --silent --fail localhost/ide.html); do
        $ECHO "Trying again in 10 seconds..."
        sleep 10s # wait before checking again
    done

    $ECHO 'Labs Workbench Developer Environment successfully started!'
    $ECHO "\nYou should now be able to access Cloud9 via:"
    $ECHO "https://$DOMAIN/ide.html"
    $ECHO "\nNOTE: Your basic-auth secret will be needed to authenticate you into this Cloud9 instance.\n"
fi

# Wait for the UI server to start
$ECHO 'Waiting for Labs Workbench UI server to start...'
$ECHO '(NOTE: This can take a couple of minutes)'
sleep 10s # wait before checking again
until $(curl --output /dev/null --silent --fail localhost/); do
    $ECHO "Trying again in 10 seconds..."
    sleep 10s # wait before checking again
done

$ECHO "https://www.$DOMAIN"

exit 0
