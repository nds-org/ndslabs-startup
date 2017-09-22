import pexpect, json

def runShellCmd(shell_cmd):
	child = pexpect.spawn('/bin/bash', ['-c', shell_cmd])
	child.expect(pexpect.EOF)

def login():
	password = pexpect.run('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')
	password = "".join(password.split())

	loginCommand ='ndslabsctl --server https://www.cmdev.ndslabs.org/api login admin'
	child = pexpect.spawn(loginCommand)
	child.expect('Password:')
	child.sendline(password)
	
	pexpect.run('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts')

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


def createUser(name, user_id, email, unsalted_password):
	f = open('etk.tmpl')
	template = f.read()
	template = json.loads(template)
	template['account']['name'] = name
	template['account']['namespace'] = user_id
	template['account']['email'] = email
	template['account']['password'] = saltPassword(unsalted_password)
	tempFile = open('temp.json', 'w')
	tempFile.write(json.dumps(template))
	tempFile.close()
	userImportCommand = 'ndslabsctl --server https://www.cmdev.ndslabs.org/api import -f temp.json'
	print userImportCommand
	runShellCmd(userFileCreateCommand)
	runShellCmd(userImportCommand)
	#pexpect.run('rm temp.json')

def deleteUser(userName):
	deleteCmd = 'ndslabsctl --server https://www.cmdev.ndslabs.org/api delete account {0}'.format(userName)
	pexpect.run(deleteCmd)

def listUsers():
	return pexpect.spawn('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts').read()

def generateUser(pattern, quantity):
	for i in range(50):
		name = pattern + str(i)
		user_id = name
		email = name + '@ndslabs.org'
		createUser(pattern, quantity, email)


if __name__ == "__main__":
	login()


