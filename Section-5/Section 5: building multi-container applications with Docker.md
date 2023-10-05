# Section 5: building multi-container applications with Docker

We're going to build a multi container app and therefore mor erealistic

We're going to combine what wwe saw in previous parts to form a more realistic example, with mulitple services/container

## Target app & Setup

3 parts:

- database: mongodb
- backend: nodeJS Rest api
- frontend: React SPA

## Dockerizing the MongoDB Service

Using the offical image

`docker run --name mongo-db --rm -d -p 27017:27017 mongo`

Note: we expose the port as API is not dockerized in the same network (will remove it later)

Quick test:

in `backend` run `npm install` then `node app.js`

Result:

```
node app.js
CONNECTED TO MONGODB
```

## Dockerinzing the Node App

For this we need our own image so we create a Dockerfile

```
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD [ "node", "app.js" ]
```

Lets build it

`docker build -t goals-node .`

Then run it:

`docker run --name goals-backend --rm -d goals-node`

This will start, but then crash as it fails to connect to mongo db

we need to change the url to use `host.docker.internal`

Note: don't forget to rebuild the image :)

And don't to map the exposed ports !

`docker run --name goals-backend --rm -d -p 80:80 goals-node`

## Moving the React SPA into a Container

Create a node container to install and run our app

```
FROM node

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
```

Build it

`docker build -t goals-react .`

Run it

`docker run --name goals-frontend -d --rm -p 3000:3000 goals-react`

It starts the server put it stops

we need to add `-it` as the app is expecting inputs to be kept alive

`docker run --name goals-frontend -d --rm -p 3000:3000 -it goals-react`

This works, but can be improve with volumes and networks

## Adding Docker Networks for Efficient Cross-Container Communication

`docker network ls` to view existing

`docker network create goals-net` to create the goals network

Let's start mongodb inside the network

`docker run --name mongodb --rm -d --network goals-net mongo`

We no longer need to add ports (-p) as the containers will be able to talk to each other

This also means that we won't be able to access mongodb from the host

Let's continue with back end:

We replace the port by the network AND we need to update the url.

We are no longer accessing mongodb on the host (with `host.docker.internal`) we need to refer to the container `mongodb`

rebuild (to update the url)

and run

`docker run --name goals-backend --rm -d --network goals-net goals-node`

And the frontend:

- update `localhost` to `goals-backend`

- build `docker build -t goals-react .`

- run `docker run --name goals-frontend --rm --network goals-net -p 3000:3000 -it goals-react`

Note: we keep the port -p because we still want to interact with it from the host machine

However this doesn't work: ERR_NAME_NOT_RESOLVED

The problem lies in the fact that the react app is not run in the container but in the browser, so it doesn't understand http://goals-backend/

Because it's a react app in the browser, we need to use the host url to backend and expose the port 80 on the BE

we rebuild and run

`docker run --name goals-frontend --rm -p 3000:3000 -it goals-react`

stop goals-node

and run it again with the port

`docker run --name goals-backend --rm -d --network goals-net -p 80:80 goals-node`

So in the end we don't put react app in the network, but it was a useful example to know what was happening and understand the solution

## Fixing MongoDB Authentication Errors (relevant for next lecture)

https://www.udemy.com/course/docker-kubernetes-the-practical-guide/learn/lecture/22626647/#questions/13014650

## Adding Data Persistence to MongoDB with Volumes

If we restart mongodb, the data is gone because it's not (yet) persisted because we use --rm

If we look at the official image in docker hub we can find the documentation on where the data is stored in the container to be able to create a map

`docker run --name some-mongo -v /my/own/path:/data/db -d mongo`

The internal path is /data/db

In this example, the volume is a bind mount which is useful if you want to inspect/debug

here we don't need a bind volume, we can just use a named volume so that it's always stored in the same place

`docker run --name mongodb -v data:/data/db --rm -d --network goals-net mongo`

Now, the data is persisted outside of the container

Lets add security

In the docs we find there is 2 environement variables

- MONGO_INITDB_ROOT_USERNAME
- MONGO_INITDB_ROOT_PASSWORD

if used, the deb will be started with these user/password and make them required to connect

`docker run --name mongodb -v data:/data/db --rm -d --network goals-net -e MONGO_INITDB_ROOT_USERNAME=jason -e MONGO_INITDB_ROOT_PASSWORD=secret mongo`

And now it fails to fetch because node doesn't auth

Note: you might need to restart node to sever the connect

Now we need to add auth to node

Mongodb accepts username password in the url

`mongodb://[username:password@]host1[:port1]?authSource=admin`

might need to also add `authSource=admin` (worked without, might have changed since video)

## Volumes, Bind Mounts & Polishing for the NodeJS Container

We want our nodeJs app to:

- persist data
- live source code update

We want to run with 2 volumes:

- one for the log files (named to persist tear down): `-v logs:/app/logs`
- one for the code live update (bindmount): -v [PATH TO CODE FOLDER]/backend:/app

`docker run --name goals-backend -v [PATH TO CODE FOLDER]/backend:/app -v logs:/app/logs -v /app/node_modules --rm --network goals-net -p 80:80 -d  goals-node`

Note: we also want to protect our node_modules to avoid it being overriden `-v /app/node_modules`

when we run it, it all works ... except the code doesn't refresh

This is because we use `node app.js` that doesn't respond to changes

Lets add `nodemon` to add the code watch and reload

add it to package.json
`"start": "nodemon app.js"`

and update the Dockerfile CMD

`CMD ['npm', 'start']`

and now it reflects changes

Lets now move user/pwd to env

in dockerfile lets add username/pwd

```
ENV MONGODB_USERNAME=admin
ENV MONGODB_PASSWORD=secret
```

Note defaults to admin:secret

and update the js url

`mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@mongodb:27017/course-goals?authSource=admin"`

Now lets rebuild (docker file changes) and re run our container with values

`docker run --name goals-backend -v [PATH TO CODE FOLDER]/backend:/app -v logs:/app/logs -v /app/node_modules --network goals-net -e MONGODB_USERNAME=jason -p 80:80 -d --rm goals-node`

Finally, we don't want to copy everything (node_modules) so lets create a `.dockerignore` file

## Live Source Code Updates for the React Container (with Bind Mounts)

We want to start container with live updated => bind mount

`docker run -v [PATH TO CODE]:/app/src --name goals-frontend --rm --network goals-net -p 3000:3000 -it -d goals-react`

And now it auto reloads

Note: if on windows wsl2 , you need to create your files in the linux file system

We also want to improve the the image build by adding .dockerignore
