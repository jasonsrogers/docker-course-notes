- from the app folder (where there is Docker)
- `docker build .`
- `docker run -p 3000:3000 sha_id`

To stop:

- `docker ps`
- find container name
- `docker stop name`

## Images & containers

### pre-built and custom images

Containers: small packages that contains your code and it's env
running unit of software

Images: is the template/bleuprint for the containers
contains code + required tools/runtimes

one image, multiple containers

### example

to run we first need image

2 ways:

- existing, pre built, via docker hub
- create your own custom image

to use an existing image:
`docker run node`

Unable to find image 'node:latest' locally

so it will go to docker hub to download

`ps -a` shows all containers running and finished

the container is isolated by default so we can't interact with it

but we can change that
`docker run -it node`
-it interactive sessions

so we can run and execute

node is running in the container, not on our machine

ctrl + v twice to exit

### create your own

write your own Dockerfile

`FROM node`
what the docker image is based on

`COPY . /app`
copy files from . to . (excluding the Dockerfile)
first . is host file system
second /app is image/container file system
(better naming the copy folder)

`RUN npm install`
to install node dep
however we need to run it inside /app

so we need to set `WORKDIR /app`
all commands will be executed in this

which also means that we can revert to

`COPY . ./`

as second `.` will be the working directory

finally we want to run the `server.js`

we could think of doing:

```
RUN npm install

RUN node server.js
```

but that would be wrong
these are the setup instruction for the image
so we would be trying to run the server in the image, not the container

instead use

`CMD ['node','server.js']`

CMD executes on launch of the container

finally we need to specify the port on which runs aka 80 in this case

`EXPOSE 80`

Note: CMD is always last

### convert to image and container

first we need to build an image from the Docker

`docker build .`
`.` to point the Dockerfile

last output:
` => => writing image sha256:048f01e65f917725c27c8fe6579d9bcb3f7ffe3cbde47fc13d709100`
then we can create an container

`docker run 048f01e65f917725c27c8fe6579d9bcb3f7ffe3cbde47fc13d709100`

it doesn't finish executing because we are running a server.js

but localhost:80 is not displaying anything because that is the internal port

so lets stop

`docker ps`
Note without `-a` we only see container that are currently running

`docker stop id`

we need to map the port

`docker run -p 8080:80 image_id`

8080 => host port
80 => internal port

Note:

As an additional quick side-note: For all docker commands where an ID can be used, you don't always have to copy / write out the full id.

You can also just use the first (few) character(s) - just enough to have a unique identifier.

So instead of

docker run abcdefg
you could also run

docker run abc
or, if there's no other image ID starting with "a", you could even run just:

docker run a
This applies to ALL Docker commands where IDs are needed.

### how to reflect changes

if I change something in the files (like server.js)

`docker run -p 8080:80 id`

doesn't reflect changes because those are image level changes
the files are copied over when building, not when running
so first:
`docker build .`
then
`docker run -p 8080:80 image_id`

images are read only

Note: there is ways to do this in a more streamlined way

### images are layer based

only the instruction that changed and the ones after are executed

aka if we have

FROM
WORKDIR
COPY
RUN
EXPOSE
CMD

and we change a file that is copied
COPY
RUN
EXPOSE
CMD
are going to be run

if you don't change anything, it will use cached

an image is layer based
instruction #3 image layer 3
instruction #2 image layer 2
instruction #1 image layer 1

image is read only, content cannot be change unless you rebuild, then it's a new image

final layer is the container with read/write

This leads to an optimization

```
COPY package.json /app

RUN npm install

COPY . /app
```

this means that unless package.json changes, it won't run npm install

changes to other files would not trigger npm install as they are copied after

### Summary

We take our code

and place it in an image along with what environment it needs to run

This is the Dockerfile

We can then run one or multiple container based on the image

the containers all share the same image, the code/resources of the image are not copied to the container

the container is only the running layer

### Quiz 1

What are "Images" (when working with Docker)?

Images are the blueprints for containers which then are running instances with read and write access

Why do we have "Images" and "Containers"? Why not just "Containers"?

This concept allows multiple containers to be based on the same image without interfering with each other

What does "Isolation" mean in the context of containers?

Containers are separated from each other and have no shared data or state by default

What's a "Container"?

An isolated unit of software which is based on an image. a running instance of that image

What are "Layers" in the context of images?

Every instruction in an image creates a cacheable layer - layers help image re-building and sharing

What does this command do?

    docker build .

it builds an image

What does this command do?

    docker run node

it creates and runs a container based on the node image

### manage image & container

-- help on any command to get more info and options

Images:
tag
list
analyze
remove

Containers:
name
configure
listing
start stop restart
remove

`docker --help` list of commands
There is a lot but most are most likely not needed

Some commands are legacy
Some are can be executed in other ways

`docker ps` list of running containers

`docker ps -a` all containers including past ones

`docker ps --help` help of ps

you can restart container that are stopped without using `docker run ...`

`docker run` creates a new image

if nothing changed, there is no need to to create a new container

grab the name of the container and run `docker start [name]`

`docker start influxdb`

note this will start it in the background

## different modes

when restarting the container is running but not attached to the terminal `background`

but when running `docker run [id]` is blocking the terminal `foreground`

`attached`/`detached` mode

if running attached/foreground,we are listening to the output of the container, so we get the logs in the terminal

we can `run` in detach `docker run -p 8000:80 -d [id]`

`-d` for detached

you can attach yourself again by running

`docker container attach [container_name or id]`

To see logs like console outputs

`docker logs [container_name]`

to get logss until now

`docker logs -f [container_name]`

to follow live logs (`-f` => follow)

if you want to restart in attached mode

`docker start -a [container_name]`

(`-a` => attached)

### docker interactive

For example running a simple python code (no flask/server)

```Dockerfile
FROM python

WORKDIR /app

COPY . /app

CMD ["python", "rng.py"]
```

`docker build .`

`docker run -i [ID]

`-i` to run in interactive mode, aka we can input to the container

`-t` creates a sudo-tty (aka a terminal)

if we try `docker start` the container is detached and we can't interact with it

`docker start -a` attach to it, but it doesn't work as expected (can only enter one number)

`docker start -ai` we want to be in iteractive mode. We don't need `-t` as the container will remember

### deleting containers

`docker rm [id]` (remove)

can't remove running containers

can do multiple at once

`docker rm [id1] [id2] [id3]`

to remove all at once

`docker container prune`

### list and removing images

`docker images` to list all images

`docker rmi [id]`
`docker rmi [id] [id2] [id3]`

can only remove images if they are not use by any container anymore including stopped containers

remove all

`docker image prune`

### automatically removing stopper containers

`--rm` automatically remove container when it exits

`docker run -p 3000:80 -d --rm efd9ab7603fe`

you'll see it in `docker ps -a`

when you do `docker stop [id]` it will be automatically removed

you'll won't see it in `docker ps -a`

### Size

Docker images contain all the code and are big

Docker containers are small as they reuse/share the code

`docker image inspect [id]` to see the size of the image

long output with a lot of info

- id of the image
- created date
- configuration for container
- entrypoint
- docker version
- operating system image
- layers of the image

layers are not just the instructions in the Dockerfile it's also all the instructions in the base image

### Look into a container add/extract files

`docker cp [local_path] [container_name]:[container_path]`

assuming we have a container running with a name `my_container`
and files `sub_folder/my_file.txt` `sub_folder/my_file2.txt`

Copy one file:
`docker cp sub_folder/my_file.txt my_container:/app`

Copy all files:
`docker cp sub_folder/. my_container:/app`

Copy the files from container to local:
`docker cp my_container:/app sub_folder`

This is a way to get files in/out of a container without having to restart it

But this is not a good way to update code in a container

this is good for config files

this is also good for debugging but copying logs out of a container

## naming and tagging images

`docker run image_id --name my_container`

now the container has a name that we don't need to look up

`docker run -p 3000:80 -d --rm --name goalsapp aa44fce2f9d2`

`docker stop goalsapp`

same for images

image tags are composed of 2 parts
`name:tag`
name: defines a group of possible more specialized images example `node`
tag: defines a specific version of the image example `10.15.3`

https://hub.docker.com/_/node/

Supported tags and respective Dockerfile links
19-alpine3.16, 19.9-alpine3.16, 19.9.0-alpine3.16, alpine3.16, current-alpine3.16

`FROM node:12` to use version 12 of node

for example:

`docker build -t goals:latest .`

if we list the images: `docker images`

REPOSITORY        TAG        IMAGE ID       CREATED          SIZE
goals             latest     4a72056453f0   26 seconds ago   923MB

## sharing images

first advantage of docker is that we don't have to manage dependencies

second advantage is that we can share images and containers

### sharing images and containers

everyone who has the image can create a container based on it

two ways to share

- share the Dockerfile and code and let the other person build the image
- share a complete built image

Sharing the dockerfile, simply run `docker build .`
Important , the Dockerfile might need the surrounding files/folders (e.g source code)

Sharing image, download the  and run a container based on it. No build steps required, everything is included in the image (which is why it's so big)

### sharing via docker hub or private registry

#### docker hub

Official docker hub: https://hub.docker.com/

maintained by docker

free to use for individual developers

you can store public private and "official" (python, node etc.) images there

#### private registry

tons of other registries know how to handle docker images being uploaded

### share images

`docker push [image_name]`

Note: for private registries you need to specify the host
`docker push [host]:[image_name]`

### use images

`docker pull [image_name]`

Note: for private registries you need to specify the host
`docker pull [host]:[image_name]`

### create a docker hub repository

sign in/up

repositories

create new repository

### push to docker hub

`docker push [username]/[repository_name]`

error:

`An image does not exist locally with the tag: [username]/[repository_name]`

we created it in docker hub but we didn't create it locally

to fix, we need to name the image it the same as the repository on the hub

2 ways: 

rebuild: `docker build -t [username]/[repository_name] .`

renaming/re-tagging: `docker tag [image_id] [username]/[repository_name]`

Note: with the `/`

`docker tag node-app:latest anarkia1985/docker-course`

when retagging, you don't delete the old image, you create a clone

### Authentication

if you are logged in to docker desktop, you can push as you already have a session 

otherwise you'll get an access denied error

to resolve that you need to login to docker hub

`docker login` and enter your credentials

### pull from docker hub

`docker pull [username]/[repository_name]`

Note: you need to be logged in to docker hub to PUSH but not to PULL if you repository is public

By default `docker pull` will pull the latest tag, so if there was a change, it will pull it

you can use `docker run [username]/[repository_name]` to run the current local version, and it will fetch the image 
if it's not there

`Docker run` will not automatically check for updates

## Quiz 2 Managing Images & Containers

What's the result of these commands?

```bash
docker build -t myimage .
docker run --name mycontainer myimage
docker stop mycontainer
```

A: an image is created, a container is started, the container is stopped
both the image and the container are still there
Both the image and the container are named

Assume that these commands were executed:

```bash
docker build -t myimage:latest .
docker run --name mycontainer --rm myimage
docker stop mycontainer
```

Which of the below commands will fail?

A: `docker rm mycontainer` as it's already removed when it stopped because of the --rm flag

what is the idea behing tags?

A: tags are used to identify different versions of the same image

## summary

docker is all about images and containers

images are templates/blueprints for containers
multiple containers can be created from the same image

containers are a thin layer on top of the image

images are either pulled or created from a Dockerfile

images contain multiple layers (instructions in the Dockerfile) to optimize build speed and reusability

Containers are created with `docker run [image_name]` and can be configured with flags

Containers can be listed with `docker ps` and stopped/started with `docker stop/start [container_id]`

Images can be listed with `docker images` and shared with `docker push/pull [image_name]`