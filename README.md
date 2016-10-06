# Labs Workbench Developer Startup

Startup scripts to run the Labs Workbench services on a single developer node.

## Prerequisites
* Docker 1.9+
* Wildcard DNS or etc hosts entry

## To run
```
./kube-up.sh
```

Wait for the Kubernetes API server to start (check via docker ps)

```
docker ps | grep "hyperkube apiserver"
b4e5680246f7        gcr.io/google_containers/hyperkube-amd64:v1.2.0           "/hyperkube apiserver"   3 days ago          Up 3 days                                    k8s_apiserver.fe8bc1dc_k8s-master-127.0.0.1_default_a61437d0ef757ee8c4f6fcc7a34bdeaa_6608c7a9
```

Run the Labs Workbench startup:

```
./ndslabs-up.sh
```
