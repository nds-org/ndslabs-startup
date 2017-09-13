from subprocess import Popen, PIPE, STDOUT


def runCommand(cmd):

	if type(cmd) != type([]):
		cmd = cmd.split(' ')
	sp = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True)
	out, err = sp.communicate()

	return out

def login():
	#get password
	password = runCommand('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')
	password = "".join(password.split())
	loginCommand = 'ndslabsctl --server https://www.cmdev.ndslabs.org/api login admin'
	sp = Popen(loginCommand, stdout=PIPE, stderr=PIPE, shell=True)
	print sp.communicate(password)
	print 'done logging in'

if __name__ == "__main__":
	login()

	print runCommand('ndslabsctl --server https://www.cmdev.ndslabs.org/api list accounts')


