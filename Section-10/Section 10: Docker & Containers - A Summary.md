# Section 10: Docker & Containers - A Summary

Quick summary

## Core concepts

Containers are isolated boxes that contain our code and execute it. 

They focus on signle task focused.

Shareable and reproducible.

They are stateless (+ volumes)

Containers are created from images created from dockerfiles or pulled from the hub, they contain the code and env.

Multiple containers can run from one image. 

Images are read only, the container is what is executed.

Can be built and shared.

Images are layered to avoid re-running everything when build when possible. 

## Key commands

`docker build -t NAME .`

`.` build context

`docker run --name NAME --rm -d IMAGE`

`docker push repo/name` `docker pull repo/name`

to share and image

Note: name needs to match repo name (or url if pushing elswhere than docker hub)

## Data, Volumes & Networking

Containers by default are isolated and stateless, so data won't survive the container

Use bind mounts to connect host machine folders `-v /local/path:/container/path` (source code etc)

Use Volumes to persist data `-v NAME:/container path` (we don't know where this data is on the host)

Anonymous volumes is mainly to protect container data from being overriten.

Networks and container communication

Connecting to the outside world is possible by default.

Container to container: 
- determine container IP and use that => ip might change, determining the address is tedious
- create a docker network and add containers to it. Now you can use the container name as an address.

## Docker compose

repeating long docker build and docker run commands gets annoying especially when working with multiple containers

Docker compose allows yo to pre-define build and run configuration in a yaml file

`docker compose up` build missing images and start all containers

`docker compose down` stops all started cotnainers

## Local vs remote

We can use docker locally for dev and reproducable work env

Isolated excapsulated reproducible development environments.

No dependency or software clashes.

Easy to share and re-produce


We can use docker remote for deployement. 

For the same reason

Isolated excapsulated reproducible development environments.

easy updates: simpl.y replace a running container with an updated one

## Deployment

Replace bind mounts with volumes or copy

Multiple containers might need multiple hosts

but they can also run on the same host (depends on application)

Multi-satge builds help with apps that need a build step

Tradeo off

Control:
(EC2 etc) you can launch a remote server, install docker and run your containers
Full control but you also need to manage everything

You can use a manged service instead
Less control and extra knowledge required but easier use, less responsibilty.

