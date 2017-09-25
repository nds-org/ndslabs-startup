import pexpect, json, argparse, sys, os, csv

DEFAULT_PASSWORD_LENGTH = 16
server = ''

def runShellCmd(shell_cmd):
	child = pexpect.spawn('/bin/bash', ['-c', shell_cmd])
	child.expect(pexpect.EOF)

def login():
	#password = pexpect.run('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')
	#password = "".join(password.split())
	#print password
	print server
	loginCommand ='ndslabsctl --server {} login admin'.format(server)
	child = pexpect.spawn(loginCommand)
	print loginCommand
	child.expect('Password:')
	print 'Enter admin password for ' + server
	child.sendline(raw_input())
	if 'Login succeeded' not in child.read():
		print "Invalid password"
		return False
	return True

def generatePassword(length):
	password = ''
	while len(password) < length:
		gen = os.urandom(1)
		intRep = ord(gen)
		if intRep >= ord('!') and intRep <= ord('~'):
			password += gen
	return password

def saltPassword(password):
	apriCmd = 'openssl passwd -apr1'
	child = pexpect.spawn(apriCmd)
	child.expect('Password:')
	child.sendline(password)
	child.sendline(password)
	apriPassword = child.read()
	apriPassword = apriPassword[apriPassword.index('$apr1$'):]
	apriPassword = apriPassword.replace("\n", "")
	apriPassword = apriPassword.replace("\r", "")
	return apriPassword


def createUser(name, user_id, email, unsalted_password, description=''):
	f = open('etk.tmpl')
	template = f.read()
	template = json.loads(template)
	template['account']['name'] = name
	template['account']['namespace'] = user_id
	template['account']['email'] = email
	template['account']['password'] = saltPassword(unsalted_password)
	template['account']['description'] = description
	tempFile = open('temp.json', 'w')
	tempFile.write(json.dumps(template))
	tempFile.close()
	userImportCommand = 'ndslabsctl --server {} import -f temp.json'.format(server)
	print userImportCommand
	runShellCmd(userImportCommand)
	#pexpect.run('rm temp.json')

def deleteUser(userName):
	deleteCmd = 'ndslabsctl --server {} delete account {}'.format(server, userName)
	pexpect.run(deleteCmd)

def listUsers():
	return pexpect.spawn('ndslabsctl --server {} list accounts'.format(server)).read()

def readFile(fileName, randomPassword):
	with open(fileName, 'rb') as csvfile:
		csvReader = csv.reader(csvfile, delimiter=',')
		for row in csvReader:
			desc = row[0]
			name = row[1] + ' ' + row[2]
			email = row[3]
			user_id = email[:email.index('@')]
			if randomPassword == True:
				password = generatePassword(DEFAULT_PASSWORD_LENGTH)
			else:
				password = randomPassword
			createUser(name, user_id, email, password, description = desc)




def main():
	#login()

	parser = argparse.ArgumentParser()
	group = parser.add_mutually_exclusive_group()
	group.add_argument("--prefix", help="set new user with given prefix", action='store')
	group.add_argument("--csv", help="import users from csv file", action='store', metavar='FILENAME')

	group2 = parser.add_mutually_exclusive_group()
	group2.add_argument("--randomPassword", action='store_true', help='generate a random password')
	group2.add_argument("--passwordPrefix", action='store', help="if used for a csv file, the passwords will be the same. Otherwise, it'll increment: password1, password2, etc.")

	parser.add_argument("--count", nargs='?', type=int)
	parser.add_argument("server", help="specifies server to connect to")

	args = parser.parse_args()

	server = args.server

	if not login():
		return

	if args.count is None:
		args.count = 1

	if args.prefix:
		for i in range(args.count):
			name = pattern + str(i + 1)
			user_id = name
			email = name + '@ndslabs.org'
			if args.randomPassword:
				password = generatePassword(DEFAULT_PASSWORD_LENGTH)
			else:
				password = args.passwordPrefix + str(i + 1)
			createUser(name, user_id, email, password)
	else:
		readFile(args.csv, args.randomPassword or args.passwordPrefix)


if __name__ == "__main__":
	main()
