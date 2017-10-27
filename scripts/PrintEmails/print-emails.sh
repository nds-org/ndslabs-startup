#!/bin/bash
# 
# Prints all emails registered in Workbench
# 
# Usage: ./print-emails.sh
#

ACCOUNTS=$(etcdctl ls /ndslabs/accounts)
SKIPPED=""

for i in $ACCOUNTS; do
    # Retrieve / format email address
    email=$(etcdctl get $i/account | jq '.email')
    email="${email%\"}"
    email="${email#\"}"

    # If account is approved, print out the email address now, otherwise print it at the end 
    if [ "$(etcdctl get $i/account | jq '.status')" != "\"approved\"" ]; then
        SKIPPED="${SKIPPED} $email"
    else
        echo $email
    fi
done



echo ""
echo ""
echo "The following emails were unapproved or unverified:"
for i in $SKIPPED; do
    echo $i
done
