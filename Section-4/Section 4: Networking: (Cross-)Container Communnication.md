# Section 4: Networking: (Cross-)Container Communnication

Containers & Networks, how to use/access networks form inside a container

Networks: how to connect containers together or how to connect container to an app running on localhost or how to reach the WWW

## Cases Overview:

### Case 1: Container to WWW Communication

Case, you have an app and you want to call a web api on the www (not another container etc)

Node app that sends request to a star waars api https://swapi.dev/api/films

### Case 2: Container to localhost machine communication

Our container is going to connect to mongodb that is running on our local machine to store the results we queried from swapi

### Case 3: Container to container communication

Our container is going to talk to a container running a SQL database (or any other container containing a service running in it)

It is recommended that a container only does one main thing.
For example if your nodejs app also needs a mangodb database then we split:

- nodejs app => one container
- mangodb => another container

## Analysing demo app

Node using axios express mongoose

/favorites GET POST => local file + mangodb
/movies GET => external url
/people GET => external url

## Creating a container & communicating to the web

Build the container

```
docker build -t favorites-node .
```

Run the container

```
docker run --name favorites -d --rm -p 3000:3000 favorites-node
```

No container visibile with `docker ps -a` (it crashed and --rm removed it)

Run again without -d (so we see logs) and we see that it can't connect to mango

For now lets remove mongoose and focus on connecting the www by only using `app.listen(3000);`

Rebuild and run again and our container stays up!

`localhost:3000/movies` works
`localhost:3000/people` works

This means that by default container can reach out to the www

## container to host machine

To get a container to talk to localhost setting, we "just" need to change the url to a specific one that docker understands

from:

`"mongodb://localhost:27017/swfavorites"`

to

`"mongodb://host.docker.internal:27017/swfavorites"`

`host.docker.internal` is understood by docker and transformed to localhost

## container to container

For that we need ... at least 2 container :)

Here we'll use one container for node and one for the db

Since mongodb has an official image on docker hub, we don't need a Dockerfile

`docker run mongo` would create a new container based on the official image

`docker run -d --name mongodb mongo` run it detacehd and with a nice name

How to connect node to it?

`docker inspect mongodb` to get the properties of the container

=> "IPAddress": "172.17.0.2" can be used to connect to the container

use that in mangoos.connect

then build `docker build -t favorites-node .`

and run `
docker run --name favorites -d --rm -p 3000:3000 favorites-node`

Now we have 2 containers running

we can see list of movies on `localhost:3000/movies` (www calls work)

we can see favorited movies on `local:3000/favorites` (calls to container mongo work)

we can add favorites with POST to `localhost:3000/favorites` with JSON body:

```
{
    "name": "A New Hope",
    "type": "movie",
    "url": "http://swapi.dev/api/films/1"
}
```

Problem:

this relies on inspecting a running container to then put the ip in and rebuild the image

## Creating Container networks

If you have multiple container (1,2,3) with docker, you can put them in a same network

`docker run --network my_network ...`

This creates a network where containers can talk to each other, and IPs are automatically resolved

### How to change running mongo

we started with `docker run -d --name mongodb mongo`

Lets try add the network

`docker run -d --name mongodb --network favorites-net mongo`

=> docker: Error response from daemon: network favorites-net not found.

unlike volumes, you have to create the network yourselvf

`docker network create favorites-net`

Inspect all networks with `docker network ls`

now running `docker run -d --name mongodb --network favorites-net mongo`will work as expected.

### how to change node to talk to mongo in network

If 2 containers are in the same network, you can use the name of the container

"mongodb://172.17.0.2:27017/swfavorites"

becomes

"mongodb://mongodb:27017/swfavorites"

Docker will then translate the name to the image

`docker run --name favorites -d --rm -p 3000:3000 --network favorites-net favorites-node`

Note: we don't need to do -p 27017:27017 on the mongodb, this is because our host maching doesn't talk to mongodb, only containers inside the docker netowrk talks to it

IP resolving doesn't change source code, Docker instead checks calls leaving the container for specific values an re routes them

## Docker Network Drivers

Docker Networks actually support different kinds of "Drivers" which influence the behavior of the Network.

The default driver is the "bridge" driver - it provides the behavior shown in this module (i.e. Containers can find each other by name if they are in the same Network).

The driver can be set when a Network is created, simply by adding the --driver option.

`docker network create --driver bridge my-net`

Of course, if you want to use the "bridge" driver, you can simply omit the entire option since "bridge" is the default anyways.

Docker also supports these alternative drivers - though you will use the "bridge" driver in most cases:

host: For standalone containers, isolation between container and host system is removed (i.e. they share localhost as a network)

overlay: Multiple Docker daemons (i.e. Docker running on different machines) are able to connect with each other. Only works in "Swarm" mode which is a dated / almost deprecated way of connecting multiple containers

macvlan: You can set a custom MAC address to a container - this address can then be used for communication with that container

none: All networking is disabled.

Third-party plugins: You can install third-party plugins which then may add all kinds of behaviors and functionalities

As mentioned, the "bridge" driver makes most sense in the vast majority of scenarios.
