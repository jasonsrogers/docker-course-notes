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

Volumes are attached to pods and are pods specific, which means we have to define volumes in the pod definition.

First lets change our app to have an error route

```
app.get("/error", (req, res) => {
  process.exit(1);
});
```

so we can crash our app and see what happens.

Rebuild with a tag of 1

`docker build -t anarkia1985/kube-data-demo:1 .`

and push

`docker push anarkia1985/kube-data-demo:1`

update the container spec in our deployment.yaml file to use the new tag.

```
spec:
      containers:
        - name: story
          image: anarkia1985/kube-data-demo:1
```

and apply to kubernetes

`kubectl apply -f=deployment.yaml`

expose (if you've stopped it)

`miniKube service story-service`

Our app is working, but when we crash it, it restarts without the data.

Note: the pod didn't restart, simply the container inside the pod restarted.

Lets add a volume to our pod definition.

```
      volumes:
        - name: story-volume
          emptyDir: {}
```

Volumes is a list. We give it a name and a type. In this case we're using the emptyDir type. `{}` is an empty object were we could add more configuration if the default wasn't enough.

Now that we have a volume, we need to mount it to our container.

```
      containers:
        - name: story
          image: anarkia1985/kube-data-demo:1
          volumeMounts:
            - name: story-volume
              mountPath: /app/story
```

`/app` is the working directory of our container, `/story`

```
const filePath = path.join(__dirname, "story", "text.txt");
```

Since there can be multiple volumes and and container might bound to multiple volumes, we need to specify which volume we want to mount. We do this by giving it the name of the volume.

```
name: story-volume
```

Let's re apply our deployment

```
GET
{
    "message": "Failed to open file."
}
```

This time we get a new error. This is because we have an empty volume, so the file doesn't exist.

but if we do a post first, the file is created and we can get it.

But now is we GET `/error` the container restarts but the data is still there.

## A second volume: the hostPath type

The emptyDir type is good basic volume type, but what happens if we have 2 replicas

if I post/get, I still get my data, but if I `/error` I will get the file not found error. This is because we're now using the second replica, which doesn't have the data.

There are several ways to fix this but the easiest is to use the `hostPath` type. This allows to specify a path of the host machine to use as a volume. So just like bind mounts in docker, the volume will be the same for all replicas.

```
    volumes:
        - name: story-volume
          hostPath:
            path: /data
            type: DirectoryOrCreate
```

Note: this will only solve the issue on the same host machine, if we have multiple nodes, we'll need to use a different type of volume.

type: `DirectoryOrCreate` will create the directory if it doesn't exist. it could be `Directory` if we want to make sure it exists.

now if we apply the deployment, when we crash a container, the data is still there when we are using another replica.

## third volume: the csi type

csi stands for Container Storage Interface. It's very flexible (unlike some others which are specific to a providers or a tech).

It was created as a clear interface for storage providers to implement. It's a standard that allows us to use different storage providers. This was to avoid kubernetes having to maintain an every growing list of drivers.

For example if we wanted to use AWS EFS, we would need to use the csi type. AWS has created a driver that implements the csi interface.

## From volumes to persistent volumes

All these volumes have a disadvantage, they are tied to the pod. If the pod is destroyed, the volume is destroyed.

Also if you scale up, some types of volumes won't be shared between pods or nodes.

For storing some temp data/intermediate results, this is fine. But for storing user data, we need something more persistent.

Kubernetes has a solution for this, called persistent volumes.

Multiple types of volumes by there nature are persistent, because they are storing it outside of kubernetes: for example a cloud provider volume like awsElascticBlockStore.

Persistent volume is more that just volume, it is, among other things, a volume that is completely independent of a pod and it's deployment lifecyle.

We'll also be able to define it once and use it in multiple pods.

So how do they work and differ from normal volumes?

Persistent volumes are defined at a cluster level and are therefore independent of pods and nodes. Instead we'll define `persistent volume claims` at a pod level which are bound to persistent volumes. You can setup multiple PV and PVC.

## Defining a persistent volume

Lets create a new yaml `host-pv.yaml` (name as you like)
We'll use hostpath as we are familiar with normal hostpath volumes. This will restrict us to 1 host machine which is ok for our case. The core concept is the same for other types of volumes.

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: host-pv
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
    - ReadOnlyMany
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

`kind: PersistentVolume` is the type of object we are creating.

```
  hostPath:
    path: /data
    type: DirectoryOrCreate
```

We're using hostpath, so we need to specify the path on the host machine. We also need to specify the type, which is `DirectoryOrCreate` in our case. This is the same as regular hostpath volumes.

```
  accessModes:
    - ReadWriteOnce
    - ReadWriteMany
    - ReadOnlyMany
```

We can specify the access modes. This is the same as regular hostpath volumes. `Once` means that it can only be mounted by one node at a time (but used by multiple pods in that node). `Many` means it can be mounted by multiple nodes at the same time. `ReadOnlyMany` means it can be mounted by multiple nodes at the same time, but only read.

```
  volumeMode: Filesystem
```

We can specify the volume mode. This is the same as regular hostpath volumes. `Filesystem` means it's a file system. `Block` means it's a block device

```
  capacity:
    storage: 1Gi
```

## Creating a persistent volume claim

Now that we have a persistent volume, we need to create a persistent volume claim.

```
kind: PersistentVolumeClaim
metadata:
  name: host-pvc
```

We'll be sticking to `static provisioning` for now. This means that we'll create the PV and PVC manually. `dynamic provisioning` is an advance administation concept.

```
spec:
  volumeName: host-pv
```

```
resources:
    requests:
      storage: 1Gi
```

Is the counterpart to the capacity of the PV.

Now we need to bind our pod to the PVC.

```
      volumes:
        - name: story-volume
          persistentVolumeClaim:
            claimName: host-pvc
```

Now we just need to apply everything and we'll have our persistent volume.

## using a claim in a pod

Kubernetes has a concept called storage classes. 

by defualt we have one: 

`kubectl get sc`

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate           false                  15d
```

The storage class tells kubernetes how to provision the volume/storage.

we need to add the same default storage class (standard) to our PV and PVC 

```
storageClassName: standard
```

Now lets apply everything and see what happens.

`kubectl apply -f=host-pv.yaml`

`kubectl apply -f=host-pvc.yaml`

`kubectl apply -f=deployment.yaml`

`kubectl get pv`

```
NAME      CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   REASON   AGE
host-pv   1Gi        RWO,ROX,RWX    Retain           Bound    default/host-pvc   standard                77s
```

and `kubectl get pvc`

```
NAME       STATUS   VOLUME    CAPACITY   ACCESS MODES   STORAGECLASS   AGE
host-pvc   Bound    host-pv   1Gi        RWO,ROX,RWX    standard       69s
```

to see that it was created

And it works!

Note: there will already be data because we used the same hostpath as before.

Understanding state:

State is a data created and used by your application which must not be lost.

- user generated data, user accounts... often stored in database, but can also be files (e.g. uploads)

- intermediate results derived by the app often stored in memory, temporary databas tables or files.

Regardless of where the data is stored, it must not be lost and survive restarts. This is why we have volumes.

For intermediate results, we probably can use normal volumes. For user data, we need persistent volumes.