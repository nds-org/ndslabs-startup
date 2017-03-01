# Labs Workbench Developer Startup

This repository contains startup scripts to run the Labs Workbench services on a single developer node. This includes:
* Small Kubernetes cluster via Docker containers or [Minikube](https://github.com/kubernetes/minikube)
* Nginx ingress controller
* Labs Workbench Angular UI and REST API Server

## Prerequisites
* Docker 1.9+
* Wildcard DNS (contact us for *.ndslabs.org testing address) or /etc/hosts entries

## Starting Kubernetes

To start Kubernetes, you can either use [Minikube](https://github.com/kubernetes/minikube) or Hyperkube via ```kube-up.sh```.

To start via Minikube:
* Download [minikube](https://github.com/kubernetes/minikube) binary for your OS
* Run ```minikube start```
* Confirm working via ```kubectl get pods``` (which should return "No resources found")

To start via kube-up.sh
* ```./kube-up.sh```: this will download the ```kubectl``` binary and put it in ~/bin

Wait for the Kubernetes API server to start (check via docker ps)

```
docker ps | grep "hyperkube apiserver"
b4e5680246f7        gcr.io/google_containers/hyperkube-amd64:v1.2.0           "/hyperkube apiserver"   3 days ago          Up 3 days                                    k8s_apiserver.fe8bc1dc_k8s-master-127.0.0.1_default_a61437d0ef757ee8c4f6fcc7a34bdeaa_6608c7a9
```

### Starting Labs Workbench
Once Kubernetes is running either via ```minikube``` or ```kube-up.sh``, run:

```
./ndslabs-up.sh
```

You will be prompted for the following:
* Base domain name for instance.  This assumes wildcard DNS is available, but you can add individual /etc/hosts entries if needed.
* Internal IP address (should be detected by ifconfig)
* Whether to enable account approval workflow (disabled by default)

The startup script will start the ingress controller, webui, apiserver, and nrpe container for optional monitoring
