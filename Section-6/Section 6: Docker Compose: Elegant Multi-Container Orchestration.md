# Section 6: Docker Compose: Elegant Multi-Container Orchestration

## Intro

In the previous lecture we created 3 containers with several options, but it's complicated to manage the commands

(cf docker-commands.txt)

It's already a lot with such a basic app. It's manageable but not convienent, this is why docker also has `docker-compose`

## Docker-compose: What & Why?

This is a tool that allows you to replace `docker build ...` and `docker run ...` commands with one configuration file + orchestration commands (build, start, stop)

However:

- it will not replace `Dockerfile` for custom images
- doe not replace images or container
- it is not suited for managing multiple containers on different hosts

For this we'll create a Docker Compose File that contains

- services (containers)
  - publish ports
  - volumes
  - network
  - env

We can do anything of docker commands as it's goal is to replace having to enter commands

## Creating a Compose File

in the root create a file `docker-compose.yaml`

There are TONS of config options [here](https://docs.docker.com/compose/compose-file/) and we'll need only a few

Note: keys in the file are exact (case sensitive)
Note: indentation is import as it makes it a child (2 space = indent)

`version` (optional) specifies maps to the version of the docker engine (https://docs.docker.com/compose/compose-file/compose-versioning/)

`services` to create the containers, keys are the container names

```
services:
  mongodb:
  backend:
  frontend:
```

setup a config for each service

How do we transpose our docker commands to yaml

### Mongo

```
docker run --name mongodb \
    -e MONGO_INITDB_ROOT_USERNAME=jason \
    -e MONGO_INITDB_ROOT_PASSWORD=secret \
    -v data:/data/db \
    --rm \
    -d \
    --network goals-net \
    mongo
```

Pick the image `image: mongo`

Image can be a name, a url or custom image

-d detach: specified at command level
--rm remove: by default tears down containers

-v volume:

```
volumes:
    - data:/data/db
```

Same syntax as volumes in docker, use multiple `-` for multiple volumes

environment variables:

```
environment:
    MONGO_INITDB_ROOT_USERNAME: jason
    MONGO_INITDB_ROOT_PASSWORD: secret
    # or
    - MONGO_INITDB_ROOT_USERNAME=jason
    - MONGO_INITDB_ROOT_PASSWORD=secret
```

Or as a environment file:
(this is at the same level as `environment:`)

```
# mongo.env file
MONGO_INITDB_ROOT_USERNAME=jason
MONGO_INITDB_ROOT_PASSWORD=secret

#yaml
env_file:
    - [relative file to file]/file.env
    - ./env/mongo.env
```

Note: why `- MONGO_INITDB_ROOT_USERNAME=jason` has a `-` and `MONGO_INITDB_ROOT_USERNAME: jason` doesn't

`-` signifies a single value
without it's a key/value with the value being a yaml object
key value paires will have `: ` (semi colon + space)

Networks:

We could define a network, but it's not useful.
Docker compose already creates a network per yaml and the containers are already binded to it

```
networks:
    - goals-net
```

defining a network would be for other cases where containers sit outside the yaml

Note:
for name `volumes` we need to reference them in the `volumes:` section of the yaml (same level as services)
This is to tell docker compose that it has to create a named volume
Furthermore, those named volumes are for all the yaml, meaning that if 2 container declare the same named volume, it will be share (useful for db etc)

```
volumes:
  data:
```

Note: there is no value associated with the `data` key

## Docker compose up/down

In the terminal run:

`docker-compose up` will run all the services defined in file attached to the terminal

`docker-compose up -d` run but detached

`docker-compose down` will stop

```
[+] Running 2/2
 ✔ Container compose-01-starting-setup-mongodb-1  Removed                                                                                                        0.1s
 ✔ Network compose-01-starting-setup_default      Removed                                                                                                        0.1s
```

Note: it uses the folder as part of the name `compose-01-starting-setup-`

It does not tear down volumes, for that:

`docker compose down -v`

note: `docker image prune` removes unused images, `docker image prune -a` removes all images

## Working with Multiple Containers

We could use
`image: goals-node` if the image already exists
we could rebuild it ourselves, but docker-compose can do that for us

simplest:
specify just the path to the dockerfile

```
backend:
    build: ./backend
```

longer version:

```
 build:
      context: ./backend
      dockerfile: Dockerfile
```

This is only useful for 2 more adavanced cases:

- if our docker file is names differently like `Dockerfile-dev`
- if our build context is different from where our dockerfile is, or needs access to files in a different directory branch

```
docker build -t goals-node .
```

is replaced by

```
 build: ./backend
```

Now to run this:

```
docker run --name goals-backend \
    -e MONGODB_USERNAME=jason
    -e MONGODB_PASSWORD=secret
    -v logs:/app/logs \
    -v [PATH TO CODE FOLDER]/backend:/app \
    -v /app/node_modules \
    --rm \
    --network goals-net \
    -p 80:80 \
    -d \
    goals-node
```

in compose

Ports:

```
ports:
    - '80:80'
```

Volumes:

```
volumes:
    - logs:/app/logs
    - ./backend:/app
    - /app/node_modules
```

the bind mount needed a absolute path, but compose only needs a relative to the yaml file path

anonymous are identical as docker commands

Finally we add `depends_on`

```
depends_on:
    - mongodb
```

This will ensure that mongodb is up a running because starting with backend

Note: specify the service name

Note:
Image name
`compose-01-starting-setup-backend`

the name of the container is
`[folder]-[image name]-1`
`compose-01-starting-setup-backend-1`

This is the name we would use internally for connecting between containers

### Adding Another Container

```
docker build -t goals-react .
```

```
docker run
    -v [PATH TO CODE]:/app/src \
    --name goals-frontend \
    --rm \
    --network goals-net \
    -p 3000:3000 \
    -it \
    -d \
    goals-react
```

We've already covered everything except `-it`

```
 frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    volumes:
      - ./frontend/src:/app/src
    # equivalent to -it 
    stdin_open: true
    tty: true

    depends_on:
      - backend
```

Note: `depends_on` is not really needed as the front end container will not fail, it will just not show much untile backend is ready

and that is it, 

`docker compose up -d` will start our project

`docker compose down` will stop it

## Building Images & Understanding Container Names

### extra commands

`docker compose up --build`

This will force that images to be rebuilt, otherwise it will just resuse previous image if availalbe. This is useful we know the code has changed

`docker compose build`

This will build the images if needed but not start the containers

### container names

`[folder name]-[service name]-[incrementing number]`

you can force the name with: 

```
container_name: super-name
```

