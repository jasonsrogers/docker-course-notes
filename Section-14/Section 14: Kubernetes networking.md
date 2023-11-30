# Section 14: Kubernetes networking

We don't just want to run containers individually, we want them to be able to talk to each other and for the right ones to be able to talk and reached by the outside world.

We're going to have a look at kubernetes & networking, connecting pods, container & the world.

For this we'll have another look at services, pod internal communication, and pod to pod communication.

## Starting Project & our goal

We'll use a demo app with 3 different backend api's working together

- auth api to handle authentication, tokens etc
- users api to handle user data, login etc
- tasks api to handle tasks data, creation etc

These are dummy apis that don't talk to actual databases, but it's not what we're focusing on here.

All three apis will be in a cluster
users api talks to auth api to authenticate users, to start of with, they'll be in the same pod and use pod internal communication.

The task api will run in a separate pod.

And both pods will be reachable from the outside world, but the auth api will not directly be reachable.

Firstly we'll start with just the users api and ensure that it can handle incoming requests.

## Creating a first deployment

Check that minikube is running

`minikube status`

Clear previous deployments and services if any

`kubectl delete deployments NAME`
`kubectl delete services NAME`

// or
`kubectl delete all --all`

Now lets get started with users

1. tweak the user-app.js to return hardcoded string or object rather than call axios
2. build the image
   `docker build -t anarkia1985/kub-users .`
3. push to docker hub
   `docker push anarkia1985/kub-users`

Lets create a kubernetes folder (optional) to store our kubernetes files

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: users-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: users
  template:
    metadata:
      labels:
        app: users
    spec:
      - containers:
          - name: users
            image: anarkia1985/kub-users

```

`kubectl apply -f users-deployment.yaml`

## Another look at services

We're going add a service so taht we can reach the users api from the outside world.

Services allow us to do 2 main things:

- gives us a stable ip address to reach our pods
- allow outside world to reach our pods

lets add a `users-service.yaml` file

In the specs of the service we want to define 3 things:

- selector: which pods to target
- ports: which ports to open on the service
- type: how the service is exposed (LoadBalancer will allow us to reach the service from outside the cluster on a stable address)

ClusterIP gives the same functionality but only within the cluster, not from outside

Note of ports: `port` is the outside port, `targetPort` is the port inside the pod

lets apply:

`kubectl apply -f users-service.yaml`

and enable access to it in minikube

`minikube service users-service`

Go to postman and test it out

POST http://[URL]/login

```
{
    "email": "..."
    "password": "...""
}
```

And we should be back:

```
{
    "token": "some-token"
}
```

This is what we saw before, but the key here is that services are key to networking in kubernetes and handling requests.

Now lets add the auth api to the mix:

- adding multiple containers to a pod
- pod to pod communication

## Multiple containers in a pod

Let's make the user api talk to the auth api.

We put dummy code in the user api to call the auth api, but we need to add the auth api to the pod.

Let's put back the axios call. It currently makes calls to the user api using the `auth` domain that is defined in docker compose.

```
 auth:
    build: ./auth-api
```

Note: because out service is named `auth`, docker compose will automatically create a dns entry for it, so we can use `auth` as the domain name.

This won't work in kubernetes so we'll need to adjust the url via environment variables.

```
  `http://${process.env.AUTH_ADDRESS}/token/` + hashedPassword + "/" + password
```

Then in docker compose

```
users:
    build: ./users-api
    environment:
      AUTH_ADDRESS: auth
    ports:
      - "8080:8080"
```

Then lets build the auth image and push it to docker hub

`docker build -t anarkia1985/kub-demo-auth .`

`docker push anarkia1985/kub-demo-auth`

Now we could create a new deployment, but we want to keep the users deployment and just add the auth container to it.

```
 containers:
        - name: users
          image: anarkia1985/kub-demo-users:latest
        - name: auth
          image: anarkia1985/kub-demo-auth:latest
```

We don't need to update the service, because auth does listen to port 80, but we don't want to expose it to the outside world.

let's rebuild and push the users image

`docker build -t anarkia1985/kub-demo-users .`

`docker push anarkia1985/kub-demo-users`

Let's apply the change making sure we provide a value for the environment variable

But which value should we use?

## pod internal communication

For pod internal communication between containers, we can use the pod localhost address.

So lets add it to the deployment

```
env:
  - name: AUTH_ADDRESS
    value: localhost
```

```
containers:
        - name: users
          image: anarkia1985/kub-demo-users:latest
          env:
            - name: AUTH_ADDRESS
              value: localhost
        - name: auth
          image: anarkia1985/kub-demo-auth:latest
```

Let's apply the change

`kubectl apply -f users-deployment.yaml`

And test it out

```
NAME                                READY   STATUS        RESTARTS   AGE
users-deployment-576d57b797-bkb7w   1/1     Terminating   0          24h
users-deployment-5d98cc4fb8-m6tlf   2/2     Running       0          26s
```

2/2 means that both containers are running

POST to the minikube url/signup

returns

```
{
    "message": "User created!"
}
```

## Creating multiple deployments

Now we are going to look at the task api. it should run in an separate pod, but is should be able to talk to the auth api as well. (while keep the auth api internal).

This means we'll need to break up users and auth into separate pods and rely on cluster internal communication.

This means different deployments and different services (as the services are tied to the pods and will have different access rules).

Let's move the auth to a separate deployment `auth-deployment.yaml`

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: auth
  template:
    metadata:
      labels:
        app: auth
    spec:
      containers:
        - name: auth
          image: anarkia1985/kub-demo-auth:latest
```

and remove the auth container from the users deployment

Since we need to access it from inside the cluster, we'll need a new service `auth-service.yaml`

```
apiVersion: v1
kind: Service
metadata:
  name: auth-service
spec:
  selector:
    app: auth
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP

```

Note: we don't want LoadBalancer, because we don't want to expose it to the outside world, instead we want to expose it to the cluster with ClusterIP.

So how can we reach it from the users pod? aka what should we use as the AUTH_ADDRESS?

## Pod to pod communication with IP addresses and environment variables

We need the ip address that is generated for the auth service, with services you get stable ip addresses and therefor we can reach the pods

You could apply the auth service and deployment

`kubectl apply -f=auth-deployment.yaml -f=auth-deployment.yaml`

Then get the services

`kubectl get services`

```
NAME            TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
auth-service    ClusterIP      10.106.81.187    <none>        80/TCP
...
```

you can get the ip of the auth service.

Let's set it as an environment variable AUTH_ADDRESS in the users deployment

and apply

`kubectl apply -f=users-deployment.yaml`

But this is not a good way to do it as it's a lot a manual work and what happens if the service restarts and gets a new ip address?

There is a better way, kubernetes provides environment variables for services.

Kubernetes will automatically create environment variables for each service that is running in the cluster and they will be named after the service name.

auth-service -> AUTH_SERVICE_SERVICE_HOST
users-service -> USERS_SERVICE_SERVICE_HOST

So we can use that in our code

```
const response = await axios.get(
    `http://${process.env.AUTH_SERVICE_SERVICE_HOST}/token/` + hashedPassword + "/" + password
  );

```

we would also need to update the docker compose file environment variable to use the new name

Rebuild:

`docker build -t anarkia1985/kub-demo-users .`

`docker push anarkia1985/kub-demo-users`

and delete then apply

`kubectl delete -f=users-deployment.yaml`

`kubectl apply -f=users-deployment.yaml`

## Using DNS for pod to pod communication

Using the automatically generated environment variables is a good way to do it, but there is a better way.

Modern kubernetes versions have a built in DNS server (coreDNS) that allows us to use DNS names to reach services.

Cluster interal domain names that are not exposed to the outside world but only used for pod to pod communication.

The pattern is just the service name, so we can use `service-name.namespace` as the domain name.

How to find the namespace?

`kubectl get namespace`

```
NAME                   STATUS   AGE
default                Active   25d
kube-node-lease        Active   25d
kube-public            Active   25d
kube-system            Active   25d
kubernetes-dashboard   Active   25d
```

Since we didn't specify a namespace, it's in the default namespace.

So we can use `auth-service.default` as the domain name.

## Which approach to use?

It depends on the situation.

If you want to have multiple containers in the same pod, you can use localhost.

But as a rule of thumb, you don't want to have multiple containers in the same pod, because it makes it harder to scale and manage.

If we want pod to pod communication, we'll need to use services as they'll give us stable ip addresses.

Then we can:

- look up the ip address of the service and use it as an environment variable
- use the automatically generated environment variable
- use the dns name

DNS will tend to be the best option, as it's simple, we don't need env variables if we are not messing around with docker compose.

## Connecting the task api

Let's replace `auth` in urls with environment variables

```
  const response = await axios.get(
    `http://${process.env.AUTH_ADDRESS}/verify-token/` + token
  );
```

We'll need a new deployment and service for the task api (service as we'll want to reach it from the outside world)

first let's looks at the deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tasks-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: tasks
  template:
    metadata:
      labels:
        app: tasks
    spec:
      containers:
        - name: tasks
          image: anarkia1985/kub-demo-tasks:latest
          env:
            - name: AUTH_ADDRESS
              # value: "10.106.81.187"
              value: "auth-service.default"
```

and the service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: tasks-service
spec:
  selector:
    app: tasks
  ports:
    - protocol: TCP
      port: 8000
      targetPort: 8000
  type: LoadBalancer
```

Build and push the image

`docker build -t anarkia1985/kub-demo-tasks .`
`docker push anarkia1985/kub-demo-tasks`

Now let's apply the deployment and service

`kubectl apply -f=tasks-deployment.yaml -f=tasks-service.yaml`

It's trying to launch but:

```
tasks-deployment-85cd876c56-vbzdf   0/1     CrashLoopBackOff   6 (4m58s ago)   11m
```

Tasks is crashing, why?

If we look at the docker compose, we see that we are using 2 env

```
environment:
      TASKS_FOLDER: tasks
      AUTH_ADDRESS: auth
```

We need to add the TASKS_FOLDER to the deployment

```
env:
  - name: AUTH_ADDRESS
    # value: "10.106.81.187"
    value: "auth-service.default"
  - name: TASKS_FOLDER
    value: "tasks"
```

And now it starts

with `kubectl get services` we can get the cluster ip address, then we can do

`minikube service tasks-service`

to get a url to test it out

Postman GET ip/tasks

```
{
    "message": "No token provided."
}
```

Let's add a token

Headers => authorization => Bearer abc

```
{
    "message": "Loading the tasks failed."
}
```

But that is normal as we don't have any tasks yet.

Note: don't forget to create `tasks-api/tasks/text.txt`

## Adding a Containerized Front end

Using postman is fine, but having a front end is better :P

In front end we find a simple react app that calls the tasks api which will require user and auth api.

in frontend we can build the image using:

`docker build -t anarkia1985/kub-demo-frontend .`

and push it to docker hub

`docker push anarkia1985/kub-demo-frontend`

to run it locally:

`docker run -p 80:80 anarkia1985/kub-demo-frontend`

We need to allow cors for tasks-app.js

```
app.use((req, res, next) => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "POST,GET,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type,Authorization");
  next();
});
```

and the authorization header

````
fetch("http://127.0.0.1:56559/tasks", {
      headers: {
        Authorization: "Bearer abc",
      },
    })
    ```

and rebuild and push the image

`docker build -t anarkia1985/kub-demo-tasks .`

`docker push anarkia1985/kub-demo-tasks`

Note: Don't forget to add a task to the tasks file otherwise it will fail

Now we need want to deploy it to kubernetes, but what about the url, and what about the deployment?

## Adding a containerized front end

