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
