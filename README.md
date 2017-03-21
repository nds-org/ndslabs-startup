# Labs Workbench Developer Startup

This repository contains startup scripts to run the Labs Workbench services on a single developer node. This includes:
* Small Kubernetes cluster via Docker containers
* Nginx ingress controller
* Labs Workbench etcd and SMTP servers
* Labs Workbench Angular UI and REST API Server
* Cloud9 IDE for development

## Prerequisites
* Docker 1.9+
* Wildcard DNS or etc hosts entry

## Platform Evaluation
Run the Labs Workbench:
```
./ndslabs.sh
```

This will automatically start all necessary Kubernetes and Labs Workbench components.

NOTE: assumes wildcard DNS is available, but you can add individual /etc/hosts entries if needed.

## Development
```
./devenv.sh
```

This will generate a basic-auth secret and start up a Cloud9 IDE to use to for development.

The Labs Workbench UI will then be replaced by a version that mounts the source directly into the container (via hostPath).
