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

POds can be created manaually but it's not recommended. It's better for pods to be managed for you, you need a "controller" (eg deployment) to manage the pods.

## the "Deployment" object (resource)

You typically don't create the pods on your own but you create a deployment object which for which you'll give instructions on how many pods to create, what image to use etc. The deployment object will then create the pods for you.

The deployment object is able to create one or multiple pods.

You set a desired state, then k8s will make sure that the desired state is met. Define which pods and containers to run and the nubmer of instances.

deployements can be paused, deleted and rolledback.

Deployments can be scaled dynamically (and automatically based on watchers). you can change the number of desired pods as needed.

Deployments manage a pod for you, you can also create multiple deployments.

you therefore typically don't directly control pods, instead you use deployments to set up the desired end state.

## A first deployment - using the imperative approach

We still need to use docker to build the image that kubernetes will use.

`docker built -t kub-first-app .`

Then we want want to send the image to the kubernetes cluster, but not as an image but as part of a pod or more specifically a deployment which will then create the pod for us.

- ensure that the cluster is running

`minikube status`

```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

if it's not running, start it with `minikube start --driver=docker` or `minikube start --driver=virtualbox`

- create the deployment

`kubectl create deployment first-app --image=kub-first-app`

`kubectl` is the tool to send commands to the cluster locally. This will be the same on the cloud.

`kubectl --help` to see all the commands

`kubectl create` shows all the options for the create command

`first-app` is the name of the deployment

we would think that we just need to pass the image name `--image=kub-first-app`, it show a success message `deployment.apps/first-app created` but it's not working.

`kubectl get deployments` will show the deployments

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   0/1     1            0           32s
```

we can see that the deployment is not ready, it's not available.

to get more info about the deployment we can use `kubectl get pods`

```
NAME                         READY   STATUS             RESTARTS   AGE
first-app-6f58f94cf5-xrpmb   0/1     ImagePullBackOff   0
```

Here we see all pods create and the status of the pods. We can see that the pod is not ready and the status is `ImagePullBackOff`. This means that the image could not be pulled from the registry. We need to tell kubernetes where to find the image.

The kubernetes cluster is running in a virtual machine, so it's not the same as our local machine. We need to specify the registry to use.

Lets try to delete the deployment and recreate it with the registry specified.

`kubectl delete deployment first-app`

Lets retag the image with the registry

`docker tag kub-first-app anarkia1985/kub-first-app`

push to docker hub

`docker push anarkia1985/kub-first-app`

Now we can recreate the deployment with the registry specified

`kubectl create deployment first-app --image=anarkia1985/kub-first-app`

Now we can see that the pod is running

`kubectl get deployments`

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   1/1     1            1           15s
```

Note: you might need to wait a bit for the pod to be ready.

Before we see how we can reach it, lets check with `miniube dashboard` to see what is running.

In there we can see our cluster:

- deployments
- pods
- replica sets

## kubectl: behind the scenes

We just executed `kubectl create deployment --image ...` but what is happening behind the scenes?

It created a deployment object and sends it to the kubernetes cluster. To the master node (control plane) which will then create the pod for us and distributing it across the worker nodes.

The scheduler will then decide where to place the pod. It will automatically look at the resources available and the requirements of the pod and then decide where to place it.

On the worker node the kubelet will then create/manage/monitor the pod.

## the service object

Exposes pods to the cluster or externally.

Note, our machine is not part of the cluster, it's outside of it. We need to expose the pod to the cluster and then we can access it from our machine (so we are part of the outside world).

Pods have an internal IP address that can be used to communicate with each other. But we can't use that to communicate with the pod from outside the cluster. (we can see it in `minikube dashboard`). We can't use that IP address to communicate with the pod from outside the cluster and the IP address is not static and will change when teh pod is replaced.

We can't rely on the IP address of the pod even internally to the cluster. Finding pods is challenging as their ip changes all the time (similar to ECS).

A service goups pods together under a shared IP and we can tell the service to share this IP with the outside world. (by default it's interal only but we can overwrite that).

Without services, pods are very hard to reach and comminication is difficult.

Reaching a pod from outside the cluster is not possible without a service.

## Exposing a deployment with a service

If we look at the docs of `kubectl create` we can see that there is an option to create a service, this would work, but for this scenario we'll use a different approach.

`kubectl expose` is more practical for this scenario. it exposes a pod create by a deployment and creates a service for it.

`kubectl expose deployment first-app --type=LoadBalancer --port=8080`

`--port=8080` is the port of the pod that we want to expose (as defined in the app/dockerfile)

There are several types of services:

- ClusterIP (default) - only accessible from within the cluster but the IP is static
- NodePort - exposes the service on each node's IP at a static port (the same port on each node)
- LoadBalancer - exposes the service externally using a load balancer that needs to exist in the infrastructure our cluster runs, then it will generate a unique address + it will also evenly distribute the load across all pods in the service.

To check the service we can use `kubectl get services`

We'll see 2 services, one is the kubernetes service and the other is our service.

```
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
first-app    LoadBalancer   10.100.50.134   <pending>     8080:31850/TCP   29s
kubernetes   ClusterIP      10.96.0.1       <none>        443/TCP          4d
```

If we were running on a cloud provider, we would get an external-ip, but minikube is not a cloud provider, so we get `<pending>`.

We can use `minikube service first-app` to open the service in the browser.

```
|-----------|-----------|-------------|---------------------------|
| NAMESPACE |   NAME    | TARGET PORT |            URL            |
|-----------|-----------|-------------|---------------------------|
| default   | first-app |        8080 | http://192.168.49.2:31850 |
|-----------|-----------|-------------|---------------------------|
🏃  Starting tunnel for service first-app.
|-----------|-----------|-------------|------------------------|
| NAMESPACE |   NAME    | TARGET PORT |          URL           |
|-----------|-----------|-------------|------------------------|
| default   | first-app |             | http://127.0.0.1:64537 |
|-----------|-----------|-------------|------------------------|
🎉  Opening service default/first-app in default browser...
❗  Because you are using a Docker driver on darwin, the terminal needs to be open to run it
```

And tada, we can see our app running.

## Restarting containers

In our app, we have an end point that automically crashed the app

```
app.get('/error', (req, res) => {
  process.exit(1);
});
```

The app craches, but if you check the main app page it's still running.

if we check the `kubectl get pods` we see the status is error, we see that the restart has increased

```
NAME                        READY   STATUS    RESTARTS      AGE
first-app-986ff4b56-58p4q   1/1     Running   3 (92s ago)   23h
```

Thanks to the monitoring of the kubelet, it will restart the pod if it crashes. This is a default behaviour of the kubelet.

We can check the events log of the pod and we see that the container was recreated after crashing.

## scaling in action

Scaling is a core feature of kubernetes. It's easy to scale up and down manually from the kubectl cli.

`kubectl scale deployment/first-app --replicas=3`

This will create 3 pods for us.

Note: replica just means the number of instances we want to run.

Now if we run `kubectl get pods` we see 3 pods running

```
NAME                        READY   STATUS    RESTARTS        AGE
first-app-986ff4b56-58p4q   1/1     Running   4 (4m27s ago)   23h
first-app-986ff4b56-tfjz9   1/1     Running   0               3s
first-app-986ff4b56-z8hbd   1/1     Running   0               3s
```

because minikube has a load balancer, traffic will be distributed across the pods.

if we visit /error a couple of times we wills till be able to see our site as the load balancer will send the request to a different pod.

```
NAME                        READY   STATUS             RESTARTS      AGE
first-app-986ff4b56-58p4q   0/1     CrashLoopBackOff   4 (15s ago)   23h
first-app-986ff4b56-tfjz9   1/1     Running            0             2m13s
first-app-986ff4b56-z8hbd   0/1     Error              1 (17s ago)   2m13s
```

we can see that 2 crashed and 1 is running. kubernetes will eventually restart the other 2 pods.

to scale back down, set the replica to 1 `kubectl scale deployment/first-app --replicas=1` and kubernetes will eventually terminate the other pods.

## Updating a deployment

Now lets take a look at how we can update a deployment after making code changes.

Once the image is rebuilt and pushed

`docker build -t anarkia1985/kub-first-app .`

`docker push anarkia1985/kub-first-app`

we can update the deployment with the new image

- check the deployment name `kubectl get deployments`

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   1/1     1            1           23h
```

- update the deployment

`kubectl set image deployment/first-app kub-first-app=anarkia1985/kub-first-app`

`kubectl set image deployment/[DEPLOYMENT_NAME] [OLD_IMAGE_NAME_LOCAL]=[NEW_IMAGE_NAME]`

- check the deployment

`kubectl get deployments`

```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
first-app   1/1     1            1           23h
```

There is no difference, and the app hasn't changed. This is because the deployment is still running the old image. We need to tell the deployment to use the new image by updating the tags. It's a good pratice also to version the images in docker.

`docker build -t anarkia1985/kub-first-app:2 .`

`docker push anarkia1985/kub-first-app:2`

`kubectl set image deployment/first-app kub-first-app=anarkia1985/kub-first-app:2`

now we get image updated confirmation

```
deployment.apps/first-app image updated
```

To check the rollout status we can use 

`kubectl rollout status deployment/first-app`

```
deployment "first-app" successfully rolled out`
```

Note: updating message

```
Waiting for deployment "first-app" rollout to finish: 1 old replicas are pending termination...
```

Now we can see that the app has been updated.

On the dashboard pods details we can see the events and container iamge have been updated.

## Deployments: rollout, rollback and history

Now lets try something that fails. 

Let set the image to a non existing image

`kubectl set image deployment/first-app kub-first-app=anarkia1985/kub-first-app:3333`

if you check the rollout status

`kubectl rollout status deployment/first-app`

```
Waiting for deployment "first-app" rollout to finish: 1 old replicas are pending termination...
```

and it doesn't finish. It's stuck in a pending state. This is because the image doesn't exist.

If we check the dashboard we see that the old pods is still running because the new one is pending. and it has issues with error pulling the image.

So we need to rollback to the previous version.

Lets check the stuck pods

`kubectl get pods`

```
NAME                         READY   STATUS             RESTARTS   AGE
first-app-54d6779784-ch2lt   1/1     Running            0          7m23s
first-app-6b9f58fd44-wsb59   0/1     ImagePullBackOff   0          3m19s
```

To rollback we can use

`kubectl rollout undo deployment/first-app`

Now our pods are back to normal

```
NAME                         READY   STATUS    RESTARTS   AGE
first-app-54d6779784-ch2lt   1/1     Running   0          8m17s
```

and our rollout status is back to normal

`kubectl rollout status deployment/first-app`

```
deployment "first-app" successfully rolled out
```

If we wanted to go back further we could look at the rollout history

`kubectl rollout history deployment/first-app`

```
REVISION  CHANGE-CAUSE
1         <none>
3         <none>
4         <none>
```

and check the details of a specific revision

`kubectl rollout history deployment/first-app --revision=3`

```
deployment.apps/first-app with revision #3
Pod Template:
  Labels:       app=first-app
        pod-template-hash=6b9f58fd44
  Containers:
   kub-first-app:
    Image:      anarkia1985/kub-first-app:3333
    Port:       <none>
    Host Port:  <none>
    Environment:        <none>
    Mounts:     <none>
```

let see if we can rollback to revision 1 

`kubectl rollout undo deployment/first-app --to-revision=1`

before switching, lets delete out service

`kubectl delete service first-app` 

and the deployment

`kubectl delete deployment first-app`

to ensure all the resources are deleted

## The imperative approach Vs the declarative approach