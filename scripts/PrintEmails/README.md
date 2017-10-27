# Workbench E-mail Helper
This script, when run on the master node, will print out the e-mail addresses of all registered users on the Workbench instance.

The output can then be copied into the `To:` field of your favorite e-mail client.

## Running the scripts
The script takes no arguments:
```bash
./print-emails.sh
```

## Expected Output
Valid/approved users will be printed, followed by unapproved/unverified users:
```bash
core@workbench-master1 ~ $ ./prints-emails.sh 
approved.user.1@email.com
approved.user.2@email.com
approved.user.3@email.com
approved.user.4@email.com
approved.user.5@email.com
approved.user.6@email.com
approved.user.7@email.com

The following emails were unapproved or unverified:
unveried.user.1@email.com
unapproved.user.1@email.com
unapproved.user.2@email.com
unveried.user.2@email.com
```
