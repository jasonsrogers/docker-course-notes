# Section 15: Kubernetes - Deployment (AWS EKS)

We're now going to have a look at how we can deploy our application to AWS EKS. 

We're going to look at options and concepts.

## Deployment Options & steps

Reminder:

Kubernetes will: 
- create your objects and manage them
- monitor pods and re-create them, scale them, etc.
-utilize the provided resources to apply your configuration/goald

What we need to do/setup:
- Create a cluster and the node instances
- setup api server and kubelet and other kubernetes services/software on nodes
- create other providers resources (e.g. load balancer, etc.)

Minikube gave use a dummy cluster that was running on our local machine.

Now we want to do this for real, so how do we deploy this?

Are we going to use our own data center or a cloud provider?

Custom data center:
- install + configure everything on your own
- machine
- kubernetes software

Cloud provider 2 options:
Manually, install + configure most things your own create + connect machines and install kubernetes software can be done manually or via kops etc

Use a managed service, define cluster architecture, services like aws eks.

## AWS EKS vs AWS ECS

We use ECS before, so what is the difference between ECS and EKS?

AWS EKS (Elastic Kubernetes Service):
- Managed service for Kubernetes deployments (knows everything needed about kubernetes for deployment etc)
- No AWS specific syntax or philosophy required
- Use standard Kubernetes configurations and resources

AWS ECS (Elastic Container Service):
- managed service for container deployments, but doesn't know anything about kubernetes
- AWS specific syntax and philosophy required
- Use AWS specific configurations and concepts

Third option: setup everything on your own, but this is not recommended.

Forth option using kops

## Preparing the stating project

Similar to the previous section, we have an auth and an users api, the auth api is not reacheable from the outside, but the users api is.

There a docker-compose file that we can use to start the project locally 

And Auth.yaml and Users.yaml files that we can use to deploy to kubernetes.

It's a node app that uses mongodb. (we need a mongodb instance see earlier section)

Create a mondodbb cluster and get the connection string.

Create a mongodb database access user and update the connection string.

We also need to adjust the image name to our own.

build and push images

`docker build --platform linux/amd64 -t anarkia1985/kub-dep-users .`

`docker push anarkia1985/kub-dep-users`

`docker build --platform linux/amd64 -t anarkia1985/kub-dep-auth .`

`docker push anarkia1985/kub-dep-auth`

## Diving into AWS

We're going to use AWS EKS as we need a provider that supports kubernetes, there are otheres that have kubernetes support with variations in how it is setup, but the Kubernetes part remains the same.

Warning: AWS is a paid service, so you will might be charged for it depending on the current free tier offered and your usage.

Once logged in to AWS, we need to go to the EKS service.

## Creating & Configuring the Kubernetes Cluster with EKS

We're going to create a cluster as this is what we need to deploy our application. The deployments etc
will be taken care of by kubernetes.

Let's create a cluster

name it `kub-dep-demo` (or whatever you want)

Keep the latest version

Cluster service role: what is this?

In order to function, the cluster needs to be able to access/create other AWS resources, so we need to create a role that has the required permissions.

For this we need to use another service called IAM (Identity and Access Management).

- Create a new role
- AWS service
- EKS
- EKS cluster

This is a role preconfigured with the required permissions.

skip along until you see `Role name` and give a meaningful name to the role like `eksClusterRole`

Finally create the role.

Now, in the cluster configuration, we can select the role we just created.

The next step is the network of the cluster.

We could use the VPC console, but we're going to go directly to the `CloudFormation` service.

Create a new stack (standard)

Leave the defaults

For the S3 url, go to the following url to find it https://docs.aws.amazon.com/eks/latest/userguide/creating-a-vpc.html#create-vpc

Then next

Give it a name `eksVpc` , leave the rest and create the stack.

Set the VPC to the one we just created.

`Cluster endpoint access` chose public and private

Next until create

Now we have a cluster, we're going to add the nodes.

It will take a bit of time to create

Now let's change out kubctl to use ou aws cluster rather than minikube.

Make a clone of the kubctl config file and rename it (so that we can switch between them)

We're going to overwrite the current config file with the one from aws eks. Tje easiest way to do this is to use the aws cli. (download it and install it if you don't have it)

Also create a credentials for it (account => secuirty credentials => access keys)

Now connect to aws using the cli

`aws configure`

Enter the access key and secret key

Now the cli is configured to talk to aws and can do things for us.

By now our cluster should be ready (it needs to be ready in order to talk to it :) )

`aws eks --region eu-north-1 update-kubeconfig --name kub-dep-demo`

Now our ~/.kube/config file should be updated with the new cluster information.

Now we can use `kubectl` to talk to our cluster.

`kubectl version` will show that we are no longer talking to mini kube, but to our aws cluster.

## Adding worked nodes

Custer details => compute => add node group

name it `demo-dep-nodes` (or whatever you want)

we need to create an IAM role for the nodes to use (for the same reasons, they need to be able to create other resources)

Go to IAM console => create role => aws service => ec2 

next add permissions => filter to find 
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

next add a role name `eksNodeGroup` (or whatever you want)

and create the role

Go back to node group creation and select the role we just created.

Chose the compute configuration, we're going to use t3.small (smaller might fail to start)

Leave the rest as is, we're note going to dig into scaling. These are the number of physical machines that will be created, not the number of pods

Next, we can keep the defaults for networking

Wait until they are created.

(you can go to ec2 and see the nodes instances)

EKS created those for us.

Now that it's created, it's up and running and we can use it just like minikube.

## Applying our kubernetes configuration

Now "all"  we need to do is apply our yaml files to the cluster in the same way we did with minikube.

` kubectl apply -f=auth.yaml -f=users.yaml`

```bash
service/auth-service created
deployment.apps/auth-deployment created
service/users-service created
deployment.apps/users-deployment created
```

`kubectl get deployments`

```bash
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
auth-deployment    0/1     1            0           24s
users-deployment   0/1     1            0           24s
```

Note: this actually failed because I built the image with the wrong architecture (M2 for the win ...)

 `kubectl logs auth-deployment-...`

gave me the error

`exec /usr/local/bin/docker-entrypoint.sh: exec format error`

which is a clear indication that the image is not compatible with the architecture of the node.

Once fixed, delete

`kubectl delete -f=auth.yaml -f=users.yaml`

and reapply

`kubectl apply -f=auth.yaml -f=users.yaml`

Once we can see that it's running with `kubectl get deployments`

and `kubectl get pods`

if we look at services

`kubectl get services`

```bash
kubectl get services
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP                                                                PORT(S)        AGE
auth-service    ClusterIP      10.100.150.10   <none>                                                                     3000/TCP       6m28s
kubernetes      ClusterIP      10.100.0.1      <none>                                                                     443/TCP        24h
users-service   LoadBalancer   10.100.39.95    aa3e982434e554a7b815d0dc22e4a6e9-1574671317.eu-north-1.elb.amazonaws.com   80:32410/TCP   6m28s
```

external ip is none (different from minikube)

But we have a load balancer url that we can use to access the service (via postman for example)

we can `POST` to the url/signup with: 

JSON payload

```json
{
    "email": "test@test.com",
    "password": "testers"
}
```

and we get a response

```json
{
    "message": "User created.",
    "user": {
        "_id": "656fa88acf82b73ab195dc4d",
        "email": "test@test.com",
        "password": "$2a$12$VUUTUIrP657Y4hw.Vl9f5uSvk.zmWxlWYmTMSv2kwetxptVOqMFCS",
        "__v": 0
    }
}
```

## Getting started with volumes

We used emptyDir and hostPath volumes in the previous section, now we're going to dive into other types of volumes: csi

We don't actually write anything to a file in our application, but let's pretend we do.

In docker compose we would add a volume.

In kubernetes we have 2 main ways of adding volumes:

- add it to the pod template directly
- create a persistent volume and claim it in the pod template

EmptyDir was easy but not persistent, hostPath was persistent and useful in mini kube as we only had one node, but not in a real cluster.

In the real world, you'll have more than one node in your cluster and you don't know where they'll be running, so you can't use hostPath.

CSI (Container Storage Interface) is useful for this, it's very flexible and third parties can create their own drivers/integrations for it.

We're going to use AWS EFS CSI driver.

## Adding EDS as a volume (with the CSI volume type) 

from [github](https://github.com/kubernetes-sigs/aws-efs-csi-driver):

`kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"`

This installs the driver in our cluster, now we need to create a persistent volume as it won't be done for us

Let's create the security group first. Go to ec2 => security groups => create security group

Name it `eks-efs` (or whatever you want)

For vpc make sure to chose your vpc `eskVpc` (or whatever you named it)

Add an inbound rule, type NFS

For source, chose custom and get the ipv4 CIDR of the vpc from 



Now go to the EFS service in aws

Create a new file system

name it `eks-efs` (or whatever you want)

chose the right vpc `eskVpc` (or whatever you named it)

Then CUSTOMIZE (not create)

leave defaults, got to next to the network access.

change the `availability zone` security group to the one we just created `eks-efs` (or whatever you named it)

Leave the rest and create the file system.

Grab the file system id.

and lets more to create the persistent volume

## Creating the persistent volume for EFS

Note: make sure to add a `users` folder in the users api project

We're going to create a persistent volume for EFS

Let's add it to `users.yaml` before the service

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-05bd4c9167b977cb5
---
apiVersion: v1
kind: Service
...
```

Volume handle is the file system id we got from the EFS service.

storageClassName is the name of the storage class we're going to create.

In the aws-efs-csi-driver repo, go to `aws-efs-csi-driver/examples/kubernetes/static_provisioning/specs` and open `storageclass.yaml`

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
```

and copy it above the persistent volume in `users.yaml`

Now we need to claim the volume.

let's create the claim name `efs-pvc`

above service

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

in the deployment template, next to containers, add a volumes section

```yaml
    volumes:
        - name: efs-vol
          persistentVolumeClaim:
            claimName: efs-pvc
```

and in the container, add a volume mount

```yaml
        volumeMounts:
          - name: efs-vol
            mountPath: /app/users
```