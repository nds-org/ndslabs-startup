# NDS Account Creation Scripts

This repo creates new accounts for NDS workbench, through either a csv file, or a given username prefix.  Password generation can be set or random.

## Example Usage

#### Importing from csv file
The following imports from a csv file named 'accountsFile.csv.'

`python account.py --server SERVER_URL --csv accountsFile.csv --randomPassword`




#### Generating using a prefix
The following creates 200 users with username prefix 'testuser' and password 'insecurepass'.  For example, the third account generated will have username 'testuser3' and password 'insecurepass3'

`python account.py --server SERVER_URL  --prefix testuser --passwordPrefix insecurepass --count 200`
