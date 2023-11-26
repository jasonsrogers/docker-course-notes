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

