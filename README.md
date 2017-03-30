# Labs Workbench Developer Startup

This repository contains startup scripts to run the Labs Workbench services on a single developer node. This includes:
* Small Kubernetes cluster via Docker containers
* Nginx ingress controller
* Labs Workbench etcd and SMTP servers
* Labs Workbench Angular UI and REST API Server
* Cloud9 IDE for development

## Minimum System Requirements
* 2 CPUs
* 2+ GB RAM
* 40+ GB storage 

## Prerequisites
* Git
* Docker 1.9+ or Minikube
* Wildcard DNS or /etc/hosts entry

## Getting Started
Clone this repo, then set up desired instance parameters by editing the following ConfigMap:
```
git clone https://github.com/nds-org/ndslabs-startup
cd ndslabs-startup/
vi templates/config.yaml
```

### Configuration Options
Within `templates/config.yaml` you can customize your instance of workbench with the following options:
```
# Enable TLS (recommended)
tls.enable: "true"

# Enable account approval by configuring a target SMTP server, or use our provided G-Mail relay
workbench.require_account_approval: "false"

# To use the G-Mail SMTP relay, you will need to provide a set of credentials
# See https://support.google.com/accounts/answer/185833?hl=en
smtp.gmail_user: "YourGmailUsername"
smtp.gmail_pass: "YouGeneratedAppPassword"

# Customize the product name as it appears in the UI
workbench.name: "Labs Workbench"

# Customize support e-mail that help requests are sent to
workbench.support_email: "support@example.com"

# Customize Google Analytics tracking ID
workbench.analytics_tracking_id: ""

# Customize the JSON catalog of tools offered by this instance
git.spec_repo: "https://github.com/nds-org/ndslabs-specs.git"
git.spec_branch: "master"
```

### Advanced Customization
For futher customization, you can fork the entire [ndslabs repo](https://github.com/nds-org/ndslabs) and point these config options to your new fork, allowing you to override anything in the UI source code.
```
# Drop-in a customized UI from git (custom CSS/HTML, new views, additional functionality, etc)
git.dropin_repo: ""
git.dropin_branch: ""
```

## Kubernetes
There are multiple ways to run a local single-node Kubernetes cluster.

Two of the most popular methods are [MiniKube](https://github.com/kubernetes/minikube) and Hyperkube.

### Available Commands
* `./kube.sh`: Bring up a local Kubernetes cluster with [hyperkube](https://github.com/kubernetes/community/blob/master/contributors/devel/local-cluster/docker.md) which uses Docker to run the other Kubernetes microservices as containers.
* `./kube.sh minikube`: Bring up a local Kubernetes cluster with [minikube](https://kubernetes.io/docs/getting-started-guides/minikube/), which spawns a local VM running Kubernetes
* `./kube.sh down`: Bring down all Kubernetes services and deletes all leftover Kuberenetes containers
* `./kube.sh basic-auth`: Generate a new basic-auth secret for use with the development environment (see below)
* `./kube.sh deploy-tools`: (DEPRECATED) Shortcut for running an ndslabs/deploy-tools container

#### Via Minikube
Minikube will run a local VM on your host machine that provides the Kubernetes services installed and running.

First, you will need to download the [minikube](https://github.com/kubernetes/minikube) binary for your OS. Then, to start a local Kubernetes via minikube, simply run our provided `./kube.sh` with the appropriate command:
```
./kube.sh minikube
```

With the minikube container passed, this script just wraps around the `minikube start` command.

#### Via Hyperkube
Hyperkube will run a local Kubernetes cluster in several Docker containers all running on the host.

To start a local Kubernetes via hyperkube, simply run our provided `./kube.sh`:
```
./kube.sh
```

With no command passed, this will automatically start all necessary Kubernetes services running as separate Docker containers.

## Labs Workbench
To evaluate the Labs Workbench platform, simply run `./ndslabs.sh`:
```
./ndslabs.sh
```

With no command passed, this will automatically start all necessary Kubernetes and Labs Workbench components.

NOTE: assumes wildcard DNS is available, but you can add individual /etc/hosts entries if needed.

### Available Commands
* `./ndslabs.sh`: Start Kubernetes, then bring all ndslabs services online
* `./ndslabs.sh down`: Bring down all ndslabs services (but leaves Kubernetes running)
* `./ndslabs.sh apipass`: Print the Admin Password of the currently running ndslabs-apiserver pod to the console
* `./ndslabs.sh apipasswd`: Alias for `./ndslabs.sh apipass`

## Development Environment (Optional)
```
./devenv.sh
```

With no command passed, this will automatically generate a basic-auth secret and start up a Cloud9 IDE to use to for development.
It will then replace the running instace of ndslabs-webui with a version that reflects changes made dynamicly from within Cloud9.

### Available Commands
* `./devenv.sh`: Start Kubernetes and Labs Workbench services, then bring up a development environment to modify the UI source
* `./devenv.sh down`: Bring down development environment and swap running UI with static image

