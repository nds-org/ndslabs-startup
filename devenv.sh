#!/bin/bash

export BINDIR="$HOME/bin"
ECHO='echo -e'

command="$(echo $1 | tr '[A-Z]' '[a-z]')"

# Ensure that Kubernetes / Labs Workbench are running
./ndslabs.sh up --no-ui

if [ "$command" == "down" ]; then
    # Stop Dev version of webui and a cloud9 container
    $ECHO 'Stopping developer environment and UI...'
    $BINDIR/kubectl delete rc ndslabs-webui
    $BINDIR/kubectl delete svc,rc,ing cloud9

    # Start production version of webui
    $ECHO 'Starting production Labs Workbench UI...'
    $BINDIR/kubectl create -f templates/core/webui.yaml


# If "basic-auth" is passed as a command, offer to regenerate the user's basic-auth secret
elif [ "$command" == "basic-auth" ]; then
    kube_output="$($BINDIR/kubectl get secret -o name basic-auth 2>&1)"
    if [ "$kube_output" == "secret/basic-auth" ]; then
        read -p 'Secret "basic-auth" exists. Regenerate it? [y/N] ' regenerate
        if [ "${regenerate:0:1}" != "y" -a "${regenerate:0:1}" != "Y" ]; then
            exit 1
        fi

        $BINDIR/kubectl delete secret basic-auth
    fi


    read -p "Username: " username
    if [ ! -n "$username" ]; then
        $ECHO 'No username entered... Aborting'
        exit 1
    fi

    read -s -p "Password: " password
    if [ ! -n "$password" ]; then
        $ECHO 'No password entered... Aborting'
        exit 1
    fi
    $ECHO ""

    read -s -p "Confirm password: " password_confirm
    if [ ! -n "$password_confirm" -o "$password" != "$password_confirm" ]; then
        $ECHO 'Passwords did not match.'
        exit 1
    fi
    $ECHO ""

    # Duplicate stdout
    auth="$(docker run -it --rm bodom0015/htpasswd -b -c /dev/stdout $username $password | tail -1)"
    $BINDIR/kubectl create secret generic basic-auth --from-literal=auth="$auth"


    exit 0
  elif [ "$command" == "up" ]; then
    # Ensure that user has created a basic-auth secret
    $BINDIR/kubectl get secret basic-auth >/dev/null 2>&1 || $ECHO 'You will now be prompted for your desired credentials for basic-auth into Cloud9.' && ./devenv.sh basic-auth

    # Notify user that source should be cloned to the correct location
    $ECHO "\nThe developer environment assumes that you have the ndslabs source code checked out at /home/core/ndslabs"
    $ECHO "If your path differs, you can manually alter the YAML templates for cloud9 and the webui located in ./templates/dev/"

    # Grab our DOMAIN from the configmap
    DOMAIN="$(cat templates/config.yaml | grep domain | awk '{print $2}' | sed s/\"//g)"
    $ECHO "    DOMAIN=$DOMAIN"

    $ECHO '\nStarting developer environment and restarting UI...'
    $BINDIR/kubectl apply -f templates/dev/webui.yaml
    $BINDIR/kubectl delete pod $(kubectl get pods | grep ndslabs-webui | awk '{print $1}')
    cat templates/dev/cloud9.yaml | sed -e "s#{{[ ]*DOMAIN[ ]*}}#${DOMAIN}#g" | kubectl apply -f -

    $ECHO '\nWaiting for Cloud9 developer environment to start...'
    until $(curl --output /dev/null --silent --fail --header "Host: cloud9.$DOMAIN" localhost/); do
        $ECHO "Trying again in 10 seconds..."
        sleep 10s # wait before checking again
    done

    $ECHO 'Labs Workbench Developer Environment successfully started!'
    $ECHO "\nYou should now be able to access Cloud9 via:"
    $ECHO "https://cloud9.$DOMAIN"
    $ECHO "Any changes made here will be reflected on disk and mapped into the webui container"
    $ECHO "\nNOTE: Your basic-auth secret will be needed to authenticate you into this Cloud9 instance.\n"
  else
    $ECHO 'Labs Workbench Developer Environment usage: devenv.sh [up|down|basic-auth]'
    exit 0
fi

# Wait for the UI server to start
$ECHO '\nWaiting for Labs Workbench UI server to start...'
$ECHO '(NOTE: This can take a couple of minutes)'
sleep 10s # wait before checking again
until $(curl --output /dev/null --silent --fail --header "Host: www.$DOMAIN" localhost/); do
    $ECHO "Trying again in 10 seconds..."
    sleep 10s # wait before checking again
done

$ECHO 'Labs Workbench UI successfully started!'
$ECHO "\nYou should now be able to access the Labs Workbench UI via:"
$ECHO "https://www.$DOMAIN"

exit 0
