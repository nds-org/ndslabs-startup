import pexpect

def login():
	password = pexpect.run('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')
	password = "".join(password.split())

	loginCommand ='ndslabsctl --server https://www.cmdev.ndslabs.org/api login admin'
	child = pexpect.spawn(loginCommand)
	child.expect('Password:')
	child.sendline(password)
	
	pexpect.run('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts')
	

if __name__ == "__main__":
	login()

	print pexpect.run('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts')


