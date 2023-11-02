# Section 12: Kubernetes in action - diving into the core concepts

We are going to dive into k8s

how to setup and testing environemtn setup

working with kubernetes objects

and examples

## Kubernetes does not manage your infrastructure

It does not create the cluster and the node instances (worker + master nodes)

Kubernetes helps you with monitoring and orchestrating the pods ... ensuring everything is up and running.

It manages the deployed application.

Kubernetes is not a cloud provider or a tool from a sepcific providers.

It doesn't know anything about the machine that it runs on.

We have to do all the instance creating and management and the insstallation of the software. and other cloud related products like load balancer, file systems etc

So we are heading back to the ec2 disadvantages where we have to do it ourselves. Updating os, security etc is not something k8s can help with.

Recap, k8s will help with:

- create pods and manage them
- monitor pods and re-create them scale pods etc.
- k8s utilizes the provided resources to apply your config and goals.

If your a experienced admin, you can do all that. Otherwise there are tools/solutions like "kubermatic" which is built for k8s (but not by k8s) and helps with managing the infrastructure needed.

in addition, cloud providers do have dedicated services (AWS: Elastic Kubernetes Service) which helps with this.

EKS uses the K8S configuration to setup the instances needed.

## Kubernetes: Required setup & installation steps

What do we need to install:

- cluster(s)
- master node(s) (shoudl be distributed to ensure it never goes down)
- also all required "software" (services: kublet etc)
- kubectl (kube control tool) tool for sending instructions to the cluster (e.g. a new deployment)

Cluster is the infrastructure, Kubectl is the tool for us to talk to the infrastructure.

Master node sends commands to make sure everything is working, kubectl is how we give the commadns to the master node.

We'll create a dummy cluster locally ysing `Minikube`

Minikube is a tool to create a virtual machine in which our k8s environment will be built and hold our cluster. Minikube will create everything in one place to make it easy to work on/try things out, but in production things will be split across multiple machines.

We'll aslo need to install kubectl (as it's independant from our infrastructure setup).

## macOS Setup

[Instructions for kubectl](https://kubernetes.io/docs/tasks/tools/#install-with-homebrew-on-macos)

[Instructions for minikube](https://minikube.sigs.k8s.io/docs/start/)

Note: virtual box for M1/M2 is supported but only in certain 7+ builds that can be found here:

https://www.virtualbox.org/wiki/Download_Old_Builds_7_0

then `brew install minikube`

and to start the cluster

`minikube start --driver=virtualbox`

If you have docker you can try

`minikube start --driver=docker` and use that too

`minikube status` to make sure everything is working well

`minikube dashboard` to see an web overview of what is running.

## widows

https://kubernetes.io/docs/tasks/tools/#install-on-windows-using-chocolatey-or-scoop

## Uderstanding Kubernetes Objects (resources)
