import pexpect, json, argparse, sys, os, csv, getpass

DEFAULT_PASSWORD_LENGTH = 16
server = ''

def runShellCmd(shell_cmd):
	child = pexpect.spawn('/bin/bash', ['-c', shell_cmd])
	child.expect(pexpect.EOF)

def login():
	global server
	loginCommand ='ndslabsctl --server {} login admin'.format(server)
	child = pexpect.spawn(loginCommand)
	child.expect('Password:')
	password = getpass.getpass(prompt='Enter admin password for ' + server + " :")
	child.sendline(password)
	output = str(child.read().decode("utf-8"))
	if 'Login succeeded' not in output:
		print("Invalid password")
		return False
	return True

def generatePassword(length):
	password = ''
	while len(password) < length:
		gen = os.urandom(1)
		intRep = ord(gen)
		if intRep >= ord('!') and intRep <= ord('~'):
			password += str(gen.decode("utf-8"))
	return password

def saltPassword(password):
	apriCmd = 'openssl passwd -apr1'
	child = pexpect.spawn(apriCmd)
	child.expect('Password:')
	child.sendline(password)
	child.sendline(password)
	apriPassword = str(child.read())
	apriPassword = apriPassword[apriPassword.index('$apr1$'):]
	apriPassword = apriPassword.replace("\n", "")
	apriPassword = apriPassword.replace("\r", "")
        apriPassword = apriPassword.replace("\\n", "")
        apriPassword = apriPassword.replace("\\r'", "")
	return apriPassword


def createUser(name, user_id, email, unsalted_password, description=''):
	global server
	f = open('account.tmpl')
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
	runShellCmd(userImportCommand)
	pexpect.run('rm temp.json')

def deleteUser(userName):
	global server
	deleteCmd = 'ndslabsctl --server {} delete account {}'.format(server, userName)
	pexpect.run(deleteCmd)

def listUsers():
	global server
	return pexpect.spawn('ndslabsctl --server {} list accounts'.format(server)).read()

def readFileP2(fileName, randomPassword):
	with open(fileName, 'rb') as csvfile:
		readFile(fileName, randomPassword, csvfile)

def readFileP3(fileName, randomPassword):
	with open(fileName, 'rt', encoding='utf8') as csvfile:
		readFile(fileName, randomPassword, csvfile)

def readFile(fileName, randomPassword, csvfile):
	csvReader = csv.reader(csvfile, delimiter=',')
	for row in csvReader:
		desc = row[0]
		name = row[1] + ' ' + row[2]
		email = row[3]
		user_id = email[:email.index('@')]
		if randomPassword == True:
			password = generatePassword(DEFAULT_PASSWORD_LENGTH)
			print(user_id + '\t' + password)
		else:
			password = randomPassword
		createUser(name, user_id, email, password, description = desc)




def main():
	parser = argparse.ArgumentParser()
	group = parser.add_mutually_exclusive_group()
	group.add_argument("--prefix", help="set new user with given prefix. Must specify prefix or csv", action='store')
	group.add_argument("--csv", help="import users from csv file. Must specify prefix or csv", action='store', metavar='FILENAME')

	group2 = parser.add_mutually_exclusive_group()
	group2.add_argument("--randomPassword", action='store_true', help='generate a random password')
	group2.add_argument("--passwordPrefix", action='store', help="if used for a csv file, the passwords will be the same. Otherwise, it'll increment: password1, password2, etc.")

	parser.add_argument("--count", nargs='?', type=int)
	parser.add_argument("server", help="specifies server to connect to")

	args = parser.parse_args()

	global server
	server = args.server
	if server is None:
		server = ''

	if '/api' not in server:
		if server[-1] != '/':
			server = server + '/'
		server = server + 'api'
	
	if not args.prefix and not args.csv:
		print(parser.parse_args(['-h']))
		return


	if not login():
		return

	if args.count is None:
		args.count = 1

	if args.prefix:
		for i in range(args.count):
			name = args.prefix + str(i + 1)
			user_id = name
			email = name + '@ndslabs.org'
			if args.passwordPrefix:
				password = args.passwordPrefix + str(i + 1)
			else:
				password = generatePassword(DEFAULT_PASSWORD_LENGTH)
				print(user_id + '\t' + password)
			createUser(name, user_id, email, password)
	elif sys.version_info.major == 3:
		readFileP3(args.csv, args.randomPassword or args.passwordPrefix)
	else:
		readFileP2(args.csv, args.randomPassword or args.passwordPrefix)


if __name__ == "__main__":
	main()
