
def runCommand(cmd):

	if type(cmd) != type([]):
		cmd = cmd.split(' ')
	sp = Popen(cmd, stdout=PIPE, stderr=PIPE, cwd='billing', shell=False, env=my_env)
	out, err = sp.communicate()

	return out

def login():
	#get password
	password = runCommand('kubectl exec -it ndslabs-apiserver-6rc4k cat password.txt')

if __name__ == "__main__":
	login()

