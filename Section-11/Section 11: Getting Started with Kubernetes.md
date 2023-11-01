# Section 11: Getting Started with Kubernetes

## Module intro

We are going to dig deeper into deploying containers, specifically deploying them using k8s

k8s is an additional framework that help with independent container orchastration independently from the cloud provider. 

We're going to: 

- understand container deployment challenges
- What is k8s? and why? (k8s = kubernetes)
- kubernetes concepts & components

## More problems with manual deployment

K8s is an open-source system for automating deployment, scaling, and management of containerized applications

It's a collection of tools that will help with container deployment.

When we consider deployment of containers, we might have a problem, sepcifically when deploying them manually (for example EC2) 

Manual deployement of containers is hard to maintain, error-prone and tedious, putting aside security and config, we might run into other problems: 
- containers might crash/go down and need to be replaced (when manually managing, we need to monotor and redeploy ourselves)
- we might need more container instances upon traffic spikes (we would have to scale up/down number of containers as the workload changes)
- incoming traffic should be distributed equally

currently we only saw how to run one container at a time, in reality we will want to run multiple times the same container to solve the problems above

## Why k8s

Ecs can help with some of these problems 

- container helth checks + automatic re-redeployment
- ECS has autoscaling
- load balancer

but there is still a downside, using a specific cloud service locks us into that service

with ECS, we need to define everything like aws things (clusters, services, tasks) and we can only set the options that AWS allows us to set

We can use cli + config files to manages this better but it will always be aws, switching to another provider, we can't reuse. 

You need to leanr about the specifics, services and config options of another provider if you want to switch 

Just knowing docker isn't enough 

(of course it might be fine if you know we stick to one provider)

This is where kubernetes can help!

## What is Kubernetes

With Kubernetes with a way to define deployments,  our scaling and our monitoring, independently of provider.

It's an open-source system (and de facto standard) for orchestrating container deployments

It helps with, automatic deployment, scaling & Load Balancing and management

Kubernetes works throught configs where we define: 
- desired architecture, 
- number of running containers 
- scaling 
etc

Then through provider specific setup or tools, we can deploy to any cloud provider or remote machine.

We have one way of writing the config, and that is a standardized way of descibing the to-be-created and to be managed resources of the kubernetes cluster

Cloud-provider specific settings can be added per cloud provider, but the rest will remain unchanged

What it is not:
- it's not a cloud service provider, it's and open-source project
- it's not a service by a cloud service provider, it can be used with any provider
- it's not restricted to any specific (cloud) service provider, it can be used with any provider
- it's not just a software you run on some machine, it's a collection of concepts and tools
- it's not an alternative to Docker, it works with (docker) container
- it's not a  paid service, it's a free open source project

Kubernetes is like docker-compose for multiple machines.

## Kubernetes: architectue & core concepts

Let's take a look at what k8s can manage.

At the core with have a `pod` (how containers are named/container is inside the pod), it is the smallest unit that k8s can create. A pod can actually hold multiple containers.

The `pod`  is inside a `worker node`, worked nodes run the containers of your application. `Nodes` are  your machines/virtual instances.  (in aws a EC2 could be a worker node). It's basically a machine with cpu/ram that can run one or multiple pods.

K8s also needs a `proxy/config` to control the network traffic on the worker node. This controls if the pods can reach or be reached from the internet for example.

You need at least one `worker node` (otherwise you wouldn't have a place to run the pod) but as your application scales up you would have multiple nodes.

Multiple pods can be created and removed to scale you app. Pods are distributed accross all worker nodes.

We also need something to control, run, replace, shut down nodes as needed. And that is done by the `master node` `control plane`. This is the control center that interacts with the worker nodes to control them. You don't directly interact with workers, you just defined the desired end state that k8s should take into account.

The master node controls your deployment (i.e all worker nodes).

master node and worker node could be on same machine, but for larger project, they are usually split so that if there is a problem with worker node, it doesn't take down the master with it.

The `control plane` is a collection of various tools and components which help with managing the worker nodes

All together this is called a cluster, the master node is able to send instructions to the cloud provider api to tell the provider to create it's provider specific resources to replicate the end state descrbe in the k8s config.

## Kubernetes will not manage your infrastructure

### What k8s will do:

Create your pods and manage them

monitor pods and re-create them, scale pods etc.

k8s utilizes the provided (cloud) resources to apply your configuration/goals

### What you need to do/setup (what k8s requires)

Create the cluster and the node instances(worked + master nodes)

setup api server, kubelet and other k8s services/software on nodes

Create other (cloud) provider resouces that might be needed (load balancer, file systems)

## A Closer look at the worker nodes

Worker node:
Think of it as one computer/machine/virtual instance

The worker node is managed by the master node, what's happening on the worked node (creating pods) is managed by the master node!

Inside the worker node, we have our pods that hosts one or more application containers and their resources (volumes, IP, run config)
Pods are created and managed by k8s

Your container is in a pod, but if you have several containers that need to run closely together, then you can have multiple containers in a pod.

It will also house the volumes that these containers need.

You can have multiple pods running on a worker node. It can be the same or different pods 

The worker node is not pod/task specific, the worker node is just a machine that has resources to run pods.

Also insider the worker node, we will have things like: 
- docker
- kubelet (handles communication between master and worker node)
- kube-proxy to handle incoming/outgoinng traffic to ensure only traffic that is desired goes through the the right resources.

## A Closer look at the master node

Inside the master node, the most important service running is the API server which is the counter point for the kublets to communicate of the work nodes.

Scheduler watches our pods and choses new worked nodes on which new pods should be created on. Responsible for telling api server what to thell the ndoes 

Kube-controller manager, watches and controls worker nodes, correct number of pods etc...

cloud controller managed,like kuber controller manager BUT for specific cloud provider: knows how to interact with cloud provider resources.

## Important terms & Concepts

cluster: a set of node machines which are running the containerized application (worker nodes) or control other nodes (master node)

nodes: physical or virtual machine with a certain hardware capacity which hosts one or multiple pods and communicates with the cluster

Master node: cluster control pane, managing pods across workder nodes

Worker node: Hosts pods, running app contianer (+ resources)

Pods: pods hold the actual running app containers + their required resources (volumes)

Containers: Normal (docker) containers

Services: a logical set (group) of pods with a unque, pod and container independant IP address



