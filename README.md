# NDS Account Creation Scripts

This repo creates new accounts for NDS workbench, through either a csv file, or a given username prefix.  Password generation can be set or random.

## Installation
1. Clone repo 

`git clone https://github.com/c1mckay/AccountCreation.git`

2. Install python requirements

`pip install -r requirements.txt`

3. Put ndslabsctl binary in the path

`wget https://github.com/nds-org/ndslabs/releases/download/v1.0-alpha/ndslabsctl-linux-amd64 -O /usr/local/bin/ndslabsctl`



## Example Usage

#### Importing from csv file
The following imports from a csv file named 'accountsFile.csv.'

`python account.py SERVER_URL --csv accountsFile.csv --randomPassword`




#### Generating using a prefix
The following creates 200 users with username prefix 'testuser' and password 'insecurepass'.  For example, the third account generated will have username 'testuser3' and password 'insecurepass3'

`python account.py SERVER_URL  --prefix testuser --passwordPrefix insecurepass --count 200`
