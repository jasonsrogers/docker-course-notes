# Section 13: managing Data & Volumes with Kubernetes.md

We face the same type of problems with kubernetes as we did when we were working with docker. We need to persist data, we need to share data between containers, we need to share data between pods, we need to share data between nodes, we need to share data between clusters.

We're going to have another look at volumes, but this time we're going to look at them from a kubernetes perspective.

We're going to see how we can make volumes work and survive in kubernetes. We're going to have a look at persistent volumes & persistent volume claims.

We'll also look at environment variables and how we can use them to share data between containers.

## Starting project & what we know already

We'll use a simple node app with 2 endpoints:
- GET story
- POST story

we'll be using as simple txt file to store the stories and read them.

This example runs inside a simple docker container. We use a docker-compose file to run the container so that setting up volumes is easier.

## Kubernetes & volumens - More that docker volumes

Understanding state

State is a data created and used by your application which must not be lost. For example:

- User generated data, user accounts...
Often stored in database, but can also be files (e.g. uploads)
- intermediate results derived by the app
often stored in memory, temporary databas tables or files.

Regardless of where the data is stored, it must not be lost and survive restarts.

This is why we have volumes

Volumes still matter in kubernetes because we are still dealing with Containers

However we don't run the containers directly, it's controlled by kubernetes.

so we can't run `-v` or composes `volumes` in kubernetes. Instead kubernetes needs to be configured to add columes to our containers.

## Kubernetes volumes: Theory & docker comparison

Kubernetes can mount volumes into containers

We can add information about volumes to our pod definition.

Kubernetes supports a wide range of volume types and drivers. Since we are potentially running on different nodes or or cloud providers. it is flexible in regards to where the data is stored.

- "local" volumes (i.e on nodes)
- cloud provider specific volumes

Volume lifetime depends on the pod lifetime by default, because the volumes are part of the pods that are managed by kubernetes.

Usually this is fine as the pod manages creation/restart of containers and volumes.

- Volumes survive container restarts (and removals) by default.
- volumes are removed when pods are destroyed

if you want volumes to survive pod destruction, you can but it's a more advanced topic covered later.

Kubernetes and docker volumes follow the same idea but are not the same. Kubernetes volumes are more flexible and powerful.

Kkubernetes volumes:
- support many types of volumes and drivers (gives you great control over where data is stored)
- Voumens are not necessarily persistent (they survive container restarts/destruction but not pods)
- Volumes survive container restarts (and removals) by default.

Docker volumes:
- basically no driver/type support, since you basically run it on your local machine it only needs to support local volumes.
- volumes persist until manually cleared
- volumes survive container restarts (and removals) by default.

## Creating a new deployment and service

We create a deployment.yaml and a service.yaml file.

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: story-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: story
  template:
    metadata:
      labels:
        app: story
    spec:
      containers:
        - name: story
          image: anarkia1985/kube-data-demo

```

Setup new deployment `story-deployment` with a single replica, and a selector that matches the label `app: story`. The template metadata also has the label `app: story`. The container is called `story` and uses the image `anarkia1985/kube-data-demo`.

Then our service.yaml file:

```
apiVersion: v1
kind: Service
metadata:
  name: story-service
spec:
  selector:
    app: story
  type: LoadBalancer
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
```

We create a service called `story-service` that selects the pods with the label `app: story`. It exposes port 80 and forwards it to port 3000.

We build our image and push it to docker hub.

`docker build -t anarkia1985/kube-data-demo .`

`docker push anarkia1985/kube-data-demo`

Apply the deployment and service:

`kubectl apply -f=deployment.yaml -f=service.yaml`

Now lets see how to solve our persistence problem.

## Getting started with volumes

As we are not using volumes yet our data doesn't survive a crash/restart.

Kubernetes supports a wide range of volume types and drivers. Since we are potentially running on different nodes or or cloud providers. it is flexible in regards to where the data is stored. (see docs for more info)

We're going to be looking at the following types of volumes:
- emptyDir
- hostPath
- csi

The key things is that our container doesn't know where the data is stored, it just knows the path where it is mounted.

## A first volume: the emptyDir type



