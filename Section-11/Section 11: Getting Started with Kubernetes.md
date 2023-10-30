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
