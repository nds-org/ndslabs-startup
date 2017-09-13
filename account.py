from subprocess import Popen, PIPE, STDOUT


def runCommand(cmd):

	if type(cmd) != type([]):
		cmd = cmd.split(' ')
	sp = Popen(cmd, stdout=PIPE, stderr=PIPE, cwd='billing', shell=False)
	out, err = sp.communicate()

	return out

def login():
	#get password
	password = runCommand('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')
	print password

if __name__ == "__main__":
	login()

