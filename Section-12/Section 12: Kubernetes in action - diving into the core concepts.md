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

Kubernetes works with objects

- pods
- deployments
- services
- volumes 
- ...

THe idea behind these objects is that you can create the object, and k8s will do things based on the instructions encoded in it (it's code at the end of the day).

Objects can be created in 2 ways:
- imperative
- declarative

A couple of key objects that we will be working with:

### pods

the smallest unit in k8s, a container or a group of containers that are tightly coupled together. They share the same resources and are deployed together. They are the smallest unit that k8s can manage. the smallest "unit" kubernetes interacts with. The most common use case is "one container per Pod". 

Pods contain shared resources (eg columes) for all pod cotnainers. They manage the volumes (more on that later).

Pods are part of the cluster and can communicate with each other. They are not isolated from each other. They have a cluster-internal IP address that can be used the send requests. If there is multiple containers in a pod, they can talk to each other via localhost. This concept is similar to ECS task definition.

Pods are designed to be ephemeral: kubernetes will start, stop and replace them as needed. They are not designed to be long lived. If you need to store data, you need to use volumes.

POds can be created manaually but it's not recommended. It's better for pods to be managed for you,  you need a "controller" (eg deployment) to manage the pods.

## the "Deployment" object (resource)

You typically don't create the pods on your own but you create a deployment object which for which you'll give instructions on how many pods to create, what image to use etc. The deployment object will then create the pods for you.

The deployment object is able to create one or multiple pods.

You set a desired state, then k8s will make sure that the desired state is met. Define which pods and containers to run and the nubmer of instances.

deployements can be paused, deleted and rolledback.

Deployments can be scaled dynamically (and automatically based on watchers). you can change the number of desired pods as needed.

Deployments manage a pod for you, you can also create multiple deployments.

you therefore typically don't directly control pods, instead you use deployments to set up the desired end state.