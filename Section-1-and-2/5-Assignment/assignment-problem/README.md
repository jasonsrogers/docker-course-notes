# Docker Basics

In this article we are going to look at the basics of Docker. We will be using the Docker CLI to create and run containers. For this we are going to take 2 simple applications, one in Node.js and one in Python. We will create Docker images for both of these applications and then run them in containers.

We will also look at various flags we can add to the `docker build` and `docker run` commands to make our lives easier.

## Create and run images

### Node app

Our node app is a simple express server that returns a message when we hit the `/` endpoint.

This means our container will be running a web server, which will require us to map the port on the host to the port on the container. But will not require us to run the container in interactive mode.

#### Dockerfile

```dockerfile
# Node Dockerfile
FROM node
# Create app directory
WORKDIR /app
# copy package.json to app directory to install dependencies (this avoids reinstalling dependencies on every build when the dependencies are not changed)
COPY package.json /app
# Install app dependencies
RUN npm install
# Copy rest of the app
COPY . /app
# indicate that the container listens on port 3000
EXPOSE 3000
# run the app
# Note: use "..." and not '...'
CMD ["node", "server.js"]
```

#### Build the image

`docker build .`

#### Get the image id

Either from the output of the `docker build` command or by running `docker images`

#### Run the image

`docker run -p 4000:3000 -d <image-id>`

Notes:

- `-p 4000:3000` maps the port 4000 on the host to port 3000 on the container. Our express server is listening on port 3000. But on the host 3000 might be taken by another application. So we map it to 4000. this allows us to access the app on `localhost:4000`

- `-d` runs the container in detached mode. This means that the container runs in the background and we can continue to use the terminal. As this is an express server, we will use it via the browser.

## Python app

Our python app is a simple BMI calculator. It takes the height and weight as console input and returns the BMI.

This means our container will be running a command line application, which will not require us to map the port on the host to the port on the container. But will require us to run the container in interactive mode.

```dockerfile
# Python Dockerfile
FROM python
# Create app directory
WORKDIR /app
# copy script to app directory
COPY . /app
# run the app
CMD ["python", "bmi.py"]
```

#### Build the image

`docker build .`

#### Get the image id

Either from the output of the `docker build` command or by running `docker images`

#### Run the image

`docker run -i <image_id>`

Notes:

- `-i` runs the container in interactive mode. This means that the container runs in the foreground and we can use the terminal to interact with the container.

## Naming containers

Naming containers makes it easier to manage them. We can stop, remove and run containers by name instead of by hash. However, you have to clean up the containers by name as well otherwise you will get an error when you try to run a container with the same name.

### node-app

`docker run -d --name node-app -p 3000:3000 <image_id>`

### python-app

`docker run --name python-app -i <image_id>`

## Cleanup

To clean up the containers and images we can use the following commands.

You need to remember to stop the containers before removing them. Otherwise you will get an error.

### Stop containers by container id

`docker ps -a` to get the container id (-a to get stopped containers as well)

`docker stop <container_id> <container_id2>`

### Stop containers by name

`docker stop node-app python-app`

### remove containers by container id

`docker ps -a` to get the container id (-a to get stopped containers as well)

`docker rm <container_id> <container_id2>`

### remove containers by name

`docker rm node-app python-app`

### remove images by image id

`docker images` to get the image id

`docker rmi <image_id> <image_id>`

## Naming images with names and tags

Naming images with names and tags makes it easier to manage them. We can build, run and remove images by name and tag instead of there auto generated name.

`docker build -t node-app:latest .`

`docker build -t python-app:latest .`

## Run images with names and tags and auto-remove

`--name` flag makes it clear which image the container will be running.

`--rm` flag removes the container when it stops, thus avoiding clutter and the naming issue when trying to run a container with the same name.

### node-app

`docker run --name node-app -p 3000:3000 -d --rm node-app:latest`

### python-app

`docker run --name python-app -i --rm python-app:latest`
