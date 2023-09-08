# managing data and working with volumes

Managing data in images and containers.

Write, read & persist.

understanding different kinds of data

volumes

using arguments and environment variables

## understanding data categories

### application
application (code + environment)

written & provided by us

added to image and container in build phase

Is "fixed" in the sense that it is not changed after the image is built

images are read only 

Read-only hence stored in images

### temporary app data (entered by user input)

fetched/produced in running container 

stored in memory or temporary files 

dynamic and changiong but cleared regularly

Read + write temporary, hence stored in containers

### permanent app data

user accounts

fetched/produced in running container

stored in files or a database

must not be lost if container is stopped/restared/deleted

read + write permanent sored with container & volumes

## analyzing a real app

Node 

couple of routes to handle

form that enters feedback 

stores feedback in a couple of file in temp and feedback.

### Dockerize the app 

```Dockerfile
FROM node: 14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "sever.js"]
```

build the image

`docker build -t feedback-node .`

Note: we don't separate the tag after the image name, this will default to latest

`docker run -p 3000:80 -d --name feedback-app --rm feedback-node`

The app saves the feedback in a file called `/feedback/[title].txt`

if we go to `localhost:3000/feedback/test.txt` we can see the feedback, but it's not in our feedback folder in the project directory.

Since the `COPY . .` we create a new file structure inside the container but it's not reflected in the host.

When we stop the container is deleted thanks to the `--rm` flag. So when we run it again, it has forgotten the feedback.

if we run it without the `--rm` flag, we can see the feedback is still there.

`docker run -p 3000:80 -d --name feedback-app feedback-node`

`docker stop feedback-app`

`docker start feedback-app`

the feedback is still there.

stopping a container doesn't clear the content of the container.

but it's isolated in the container, it can't be shared, it doesn't survive destruction (for example building a new version of the image)

## introducing volumes

Volumes are folders on your host that are mounted into the container.

These are made available to the container and can be used to store data. The container will have a local reference to the volume.

It sounds like `COPY` but it's not. `COPY` is a one time operation, volumes are shared between the host and the container.

Changes in the container are reflected in the host and vice versa.

Volumes allows persistence of data. Containers can both read and write to volumes.

### How to add a volume

In our application, we save the feedback in a folder called `feedback`. So we should create a volume with that name.

`VOLUME ["/app/feedback"]`

We specify the path inside the container, not the host. The host path is specified when we run the container.

`docker build -t feedback-node:volumes .`

Note: leveraging tags

`docker run -d -p 3000:80 --rm feedback-node:volumes`

But this doesn't work, lets check the logs 

`docker logs feedback-app`

error: UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/feedback' -> '/app/feedback.txt'

The reason is the rename function as the sync  between container and host doesn't like it.

`await fs.rename(tempFilePath, finalFilePath);`

solution: use `fs.copyFileSync` instead of `fs.rename`

```js
// create a copy of the file
await fs.copyFile(tempFilePath, finalFilePath);
// delete file by using unlink
await fs.unlink(tempFilePath);
```

And... it still doesn't work :(

## Named volumes

### Bind mounts

Currently if you change something if your source code, you need to rebuild the image. We only copy over a snapshot when it's created, further changes are not copied

During dev, the would not work

In a similar way as `docker volume` (which is managed by docker and we don't know where things are stored), 

With Bind mounts, we set the path so the container knows where to read/write, it is perfect for persistent and *`editable `*

You can't specify it in the `Dockerfile` as it's not a something global but something dependant on where the container is run

build the image: 

`docker build -t feedback-node:volumes .`

create the container while specifying a volume 

`docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "[absolute path to source]:/app" feedback-node:volumes`

Note: `"` are optional in path

Container is not working, how to debug:
- remove `-rm` to keep the container after is has stopped
- `docker logs [container name]`

Error is:
Cannot find module 'express'

Despite running `npm install` in the Docker file.

### Bind mount shortcut

If you don't always want to copy and use the full path, you can use these shortcuts:

macOS / Linux: `-v $(pwd):/app`

Windows: `-v "%cd%":/app`

### Fixing install

We are binding our external folder to the /app inside the container, effectively over writing it


These steps are useless as such:

```
COPY package.json .

RUN npm install

COPY . .
```

#### how do container manage volumes

container can have volumes mounted to it with `-v`

folders are connected to the host files

volumes => container stores and read files in host

bind mount => host has files that the container reads/copies over

but here we have both, files inside the container (npm, cp) that are then overriden by host files

Docker doesn't override localhost folder with content of inside.

We need to tell docker that there is files that it shouldn't override, we do this with anonymous volumes.


`docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "[absolute path to source]:/app" -v /app/node_modules feedback-node:volumes`

(anonymous because with don't specify a-name:/app/node_modules)]

We could also specify it inside the Dockerfile 

```
VOLUME ["/app/node_modules"]
```

But changes in Dockerfile implies rebuilding the image (depends what you want)

Why does it work: 

Docker evaluates all volume paths, and if there is a clash, it priorities the longest internal path

- /app => one level 
- /app/node_modules => two levels => priority

This means that /app is bound to our machine except to /app/node_modules, that one will override take precedence over any potential node_modules in the host machine 

#### Node specific refresh

if we want to change server.js by adding `console.log('FEEDBACK')` it doesn't refresh.

server.js is run by node and it's runtime, so need to restart the webserver for the changes to be applied

You can check that the changes have been copied over by connecting to the container interactively and starting a bash

`docker exec -it [CONTAINER ID] bash`

```
cat server.js
```

It is not trivial to restart the node inside the container so the simplest is to 
`docker stop [CONTAINER NAME]`
`docker start [CONTAINER NAME]`

To avoid this, we actually change the behavior of node to use `nodemon`

```
"scripts": {
    "start": "nodemon server.js"
  },

 "devDependencies": {
    "nodemon": "X.X.X"
}```

this adds file change detection on top of node

Change the docker file to

```
CMD ["npm", "start"]
```

see: `data-volumes-04-added-nodemon`

`docker stop feedback-app`

`
```
docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "[ABS PATH]:/app" -v /app/node_modules feedback-node:volumes
```

Note: windows with WSL2 users need to put files in the Linux file system

### recap

three ways to use volumes `-v`:

- `docker run -v /app/data`
anonymous volumes
creates a volume linked to a single container, survives start/stop but not remove
can't use to share data across containers
can't use to persist past destruction
CAN be useful for locking in data inside volume (inside a bind mount for example)
it outsources data to host which can help improve performance as it need to handle less

- `docker run -v data:/app/data`
named volume
can't be created in docker file 
general container, not tied to specific container 
persist through start/stop but also removal (need separate command for remove these volumes)
can share data across containers
store data

- `docker run -v [abs path]:/app/code`
bind mount (path as name)
specify where data is stored 
general container, not tied to specific container 
persist through start/stop but also removal (need separate command for remove these volumes)
deleting data has to be done on the host machine

### managin docker volumes

 `docker volume ls`

 list volumes of all active containers

 DRIVER    VOLUME NAME
local     project_node_modules              <= named 
local     a09c8q907sd09asc098d09a8sd...     <= anonymous volume

bind mount will not appear in this list as it's not a volume managed by docker

`docker volume create feedback-files` 

will create a named volume for us that can be used when creating our container

`docker run -d --rm -p 3000:80 --name feedback-app -v feedback-files:/app/feedback`

Note: if the volume doesn't exist, docker will create it 

`docker volume rm [VOLUME NAME] [...]`

Delete a volume

`docker volume prune` 

Delete all unused local volumes

`docker volume inspect feedback`

```
[
    {
        "CreatedAt": "2023-09-08T13:54:33Z",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/feedback/_data",
        "Name": "feedback",
        "Options": null,
        "Scope": "local"
    }
]
```

`Mountpoint` is the path to where the volume is, but it's not a path on your machine but a path in a VM that docker created, making it hard to find where it's actually is

Inspect does give us info like if the volume is read only (would be in `Options`)

`docker volume rm feedback-files`

remove the created volume

### Using COPY vs Bind mounts

If we bind the whole volume `[path to app]:/app`, do we still need `COPY . .`

`docker run -d -p 3000:80 --rm --name feedback-app -v feedback:/app/feedback -v "[PATH]:/app" -v /app/node_modules feedback-node`

(reminder -v /app/node_modules tells docker not to override /app/node_modules)

During dev phase, we use a bind mount to map our local folder and the docker folder so that our changes are reflected without restarting container

But when deploying, we won't bind mount a folder to our server, we'll be running this container in isolation, so we want to keep the `COPY . .` so that it does this one time copy

### We don't need to copy everything, use ".dockerignore"

`.dockerignore` file, similar principal to `.gitignore`

```
node_modules
.git
Dockerfile
```

doesn't copy `node_modules`, this prevents any system `node_modules` to be copied and override the container `node_modules` 

In our docker file we do a `COPY . .` after `RUN npm install` which would mean we would lose our container install

### ARGuments & ENVironment Variables

Dokcer suppoers built-time ARGuments and runtime ENVironment variables

#### ARG

Available insid of Dockerfile, NOT accessible in CMD or any application code

Set on image build (docker build) via --build-arg

#### ENV 

Availalbe inside of Dockerfile & in application code

Set via ENV in Dockerfile  or via --env on docker run

Example parameterise port: 

```
EXPOSE 80

app.listen(80)
```

Node uses `process` to expose environement variables

```
app.listen(process.env.PORT)
```

Now to set the environment variable, in the docker file, you can specify what env variable you want to expose

```
ENV PORT 80
```

PORT is available and the default in 80

```
EXPOSE $PORT
```

Now we can use that var in our Dockerfile as well as in our code

Note: `ENV PORT` to declare `$PORT` to use

now we can sepcify the variable when running the container: 

```
--env PORT=8000

// or 

-e PORT=8000
```

```
docker run -d -p 3000:80 --env PORT=8000 --rm --name feedback-app -v feedback:/app/feedback -v "/Users/jason/Dev/Udemy/Docker/docker-course-notes/Section-3/data-volumes-04-added-nodemon:/app" -v /app/node_modules feedback-node:env
```

We now don't need to rebuild the container to change the port 

We can also specify a env file (usually .env)

```
--env-file ./.env
```

values will be read from the file 

```.env
PORT=8000
```

This avoid having to add them in the command

Note: evn is a good way to keep sensitive values out of the image baking

`docker history <image>` allows to see values backed into the image

```
ason@Jasons-MacBook-Pro data-volumes-08-args-and-env % docker history feedback-node
IMAGE          CREATED             CREATED BY                                      SIZE      COMMENT
144cfb658bf6   About an hour ago   CMD ["npm" "start"]                             0B        buildkit.dockerfile.v0
<missing>      About an hour ago   EXPOSE map[80/tcp:{}]                           0B        buildkit.dockerfile.v0
<missing>      About an hour ago   COPY . . # buildkit                             10.2kB    buildkit.dockerfile.v0
<missing>      About an hour ago   RUN /bin/sh -c npm install # buildkit           10.5MB    buildkit.dockerfile.v0
<missing>      About an hour ago   COPY package.json . # buildkit                  364B      buildkit.dockerfile.v0
<missing>      About an hour ago   WORKDIR /app                                    0B        buildkit.dockerfile.v0
<missing>      4 months ago        /bin/sh -c #(nop)  CMD ["node"]                 0B        
<missing>      4 months ago        /bin/sh -c #(nop)  ENTRYPOINT ["docker-entry…   0B        
<missing>      4 months ago        /bin/sh -c #(nop) COPY file:4d192565a7220e13…   388B      
<missing>      4 months ago        /bin/sh -c set -ex   && for key in     6A010…   7.67MB    
<missing>      4 months ago        /bin/sh -c #(nop)  ENV YARN_VERSION=1.22.19     0B  
```

### build time arguments

They allow us to bake in different values into the image without hardcoding them

For example the default port number is currently 80, but maybe we want to build different images with different defaults

```
ARG DEFAULT_PORT=80

ENV PORT $DEFAULT_PORT
```

This ARG is only available in Dockerfile and not in all instructions (for example, can't be used in CMD which is container level instruction)

```
docker build -t feedback-node:web-app .

docker build -t feedback-node:dev --build-arg DEFAULT_PORT=8000 .
```

Note: where you place ARG/ENV impacts the layers of the Dockerfile, if place before `RUN npm install` it re-run npm install everytime you change the var, if placed after, it won't re-run npm install

## Summary

Containers can read + write data

Volumes can help with data storage, Bind Mounts can help with direct container interaction.

Containers can read + write data, but data is lost if the container is removed, Adds the read/write layer on top of the image.

Volumes are folders on the host machine, managed by Docker, which are mounted into the container.

Named Volumes survive container removal and therefore be used to store persistent data

Anonymous Volumes are attached to a container, they can be used to save (temporary) data inside the container.

Bind Mounts are folders on the host machine which are specified by the user and mounted into containers - like named volumes

Build ARGuments and runtime ENVironment variables can be used to make images and containers more dynamic/configurable

