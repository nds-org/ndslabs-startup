import pexpect

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
	
def createUser(name, user_id, email):
	userFileCreateCommand = 'cat etk.tmpl | sed "s/NAME/{0}/g" | sed "s/USER_ID/{1}/g" | sed "s/EMAIL/{2}/g" > temp.json'.format(name, user_id, email)
	print userFileCreateCommand
	userImportCommand = 'ndslabsctl --server https://www.cmdev.ndslabs.org/api import -f temp.json'
	print userImportCommand
	runShellCmd(userFileCreateCommand)
	runShellCmd(userImportCommand)
	print pexpect.run('cat temp.json')
	pexpect.run('rm temp.json')

def deleteUser(userName):
	deleteCmd = 'ndslabsctl --server https://www.cmdev.ndslabs.org/api delete account {0}'.format(userName)
	pexpect.run(deleteCmd)

def generateUser(pattern):


if __name__ == "__main__":
	login()

	generateUser('user')

	print pexpect.run('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts')


