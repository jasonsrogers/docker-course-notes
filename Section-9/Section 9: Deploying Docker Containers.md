# Section 9: Deploying Docker Containers

This is a big module

From development to production

We are going to run our containers to other machines on the cloud, the deployment process, scenarios, examples and common problems

## From development to production

Containers are great

- standard unit for shipping goods
- can be moved
- independent from other containers
- self contained
- isolated, standalone env
- reproductible environment, easy to share and use
- no surprises

Things to watch out for:

- bind mounts shouldn't be used in production
- containerized apps might need a build step (react app is run in dev but built to a static version in prod)
- multi container projects might need to be split (or should be split) accross multiple hosts/remote machines
- trad-offs between control and responsibility might be worth it

## Deployment process & provider

basic first example: standalone nodejs app

just node js, no database, nothing else

Hosting provider. There are tons of providers for various prices and they have slightly different process

the 3 major ones are:

- aws
- azure
- google cloud

We'll use aws as it's the biggest one atm

## Getting started with aws

Sign up for an account (there is a free tier and free services for 1 year, but you need to enter a credit cart and phone)

Example: deploy to aws ec2

AWS EC2 is a service that allows you to spin up and manage your own remote machines

1. Create and launch EC2 instance, vpx and security group
2. configure security gorup to expose all required ports to www
3. connect to instance (ssh) install docker and run container

Create the image in deployement-01

`docker build -t node-deploy-example-1 .`

test it
`docker run -d --rm --name node-dep -p 80:80 node-deploy-example-1`

## Bind Mounts in production

There are differences between running in dev or in prod

in dev:

- containers should encapsulate the runtime environement but not necessarily the code, we are fine with the container picking up changes to the code from outside as long as it can run/execute it.
- use "bind mounts" to provide your local host project files to the running container. We can make changes to the code and see them be reflected instantly inside the container.
- allows for instant udates without restarting the container

in production

- we move out code to a distant machine so it's different
- a container should really work standalon, you should NOT rely on external setup or code. The image/container is the "signle source of truth"
- So we rely COPY to copy a code snapshot into the image, we don't use bound mount
- Ensures that every image runs without any extra, surrounding configuration or code

## Introducing AWS & EC2

Log into aws

In the home console locate EC2 or use the search bar to search for EC2

Then locate `Launch instance`

## Connecting to an ECC2 Instance

Chose `Amazon Linux`

Then `Amazon Linux 2 AMI (HMV)`

Architecture: 64-bit (x86)

Instance: the one with free tier

Create a key/pair to connect via ssh

Note: save the file carefully as you can only download it once

Then navigate back to `instances`

Once it's up and running, select and click `connect`

There are several ways to connect detailed here

In terminal

- Ensure you change permissions `chmod 400 deployment-01.pem`
- connect via ssh (copy the command)

`ssh -i "deployment-01.pem" ec2-user@ec2-16-171-182-21.eu-north-1.compute.amazonaws.com`

Note: run this from the folder you have your pem or adjust path

## Installing Docker on a VM

Connect to VM

ssh -i ~/.ssh/deployment-01.pem ec2-user@ec2-XXXX.eu-north-1.compute.amazonaws.com

Update packages

`sudo yum update -y`

Install docker

`sudo amazon-linux-extras install docker`
or if it doesn't work due to end of life
`sudo yum -y install docker`

Start docker
`sudo service docker start`

Docker is now running

`sudo usermod -a -G docker ec2-user`
Make sure to log out + back in after running these commands.

Once you logged back in, run this command:

`sudo systemctl enable docker`

Thereafter, you can check whether Docker is available by running:

`docker version`

## Installing Docker on Linux in General

In the last lecture, you saw the AWS-specific command for installing Docker on a Linux machine:

amazon-linux-extras install docker
Of course you might not always want to install it on a AWS EC2 instance though - maybe you are using a different provider.

In that case, you can always follow the Linux setup instructions you find on the official Docker page: https://docs.docker.com/engine/install/ (under "Server").

## Pushing our local image to the cloud

Now we want to put our local image onto our remote machine, there are 2 main ways:

- deploy source code and build image on remote machine then run. But this is complex and unecessary

- deploy built image then run

Lets go with the second option

- Sign into docker hub
- create new repository (name it what you want)
- if you are on a free tier, leave it public
- now we can push to this repo
- build the image
  `docker build -t node-deploy-example .`
- rename the image to match the repo
  `docker tag node-deploy-example {name}/node-deploy-example-1`
- push the image
  `docker push {name}/node-deploy-example-1`
  Note: you need to be logged in (`docker login`)

Now we just need to pull it and run

## Running & publiishing the app (on EC2)

`docker run {name}/node-deploy-example-1`

M1/M2 Note:

you might get the following error:

```
WARNING: The requested image's platform (linux/arm64/v8) does not match the detected host platform (linux/amd64) and no specific platform was requested
```

It's a mismatch between mac M1/M2 and EC2

First deleted the image from local and ec2 (it did some wierd caching for me)

Rebuild the image using `--platform`

`deployment-01-starting-setup % docker build --platform linux/amd64 -t node-deploy-example-1 .`

tag it again !!!

`docker tag node-deploy-example-1 {name}/node-deploy-example-1`

push it

`docker push {name}/node-deploy-example-1`

On the EC2, remove old image

`docker rmi {name}/node-deploy-example-1`

And run again:

`docker run -d --rm -p 80:80 {name}/node-deploy-example-1`

To test that it's working, go to the AWS instance

locate the ipv4 public ip and... it does't work because we haven't enabled the instance security group to be opened to the internet

In the instance information, you can locate the security tab, in it, there will be the security group defautls

either select it

or

locate security groups in the left panel, and locate the right security group

outbound rules control outgoing traffic (allowing docker to connect to the hub)

inbound rules control traffic to the instance (http request etc)

Currently only ssh (port 22) is open

`0.0.0.0/0` means any ip range

`edit inbound rules`

`add rule`

type => http

source type => anywhere ipv4

`save rules`

Refresh your browser !!!

## Managing & updating the container/image

how to update the code?

After a change, how do we manage updating the running container

Rebuild
`docker build --platform linux/amd64 -t node-deploy-example-1 .`

`docker tag node-deploy-example-1 {name}/node-deploy-example-1`

Push

`docker push {name}/node-deploy-example-1`

Use:

`docker stop [CONTAINER]`

but if we use:

`docker run -d --rm -p 80:80 {name}/node-deploy-example-1`

we won't see the changes because it used the localy cached image. Therefore first pull the latest

`docker pull {name}/node-deploy-example-1`

then run

`docker run -d --rm -p 80:80 {name}/node-deploy-example-1`

## Disadvantages of our current approach

We've seen how to run a app inside of a container on a remote machine without any additional setup then installing docker

Only docker needs to be installed (no other runtimes or tools!)

uploading our code/built up is very easy as it's inside the container

it's the exact same app and environement as on our machine

However the "do it yourself" approach has disadvantages

"do it yourself":

- create instance manually
- configure it manually
- connect it manually
- install docker manually

We fully "own" the remote machine -> we're responsible for it

- keep essentials software updated
- manage network and security groups/firewall

SSHing into the machine to manage it can be annoying

This approach requires "know how" that is not part of the primary skills of a web dev etc. and if you make a mistake, it can be problematic. It's a totally different set of skills

Relying on a more automated approach remove control but also responsability/risk

## From manual deployment to managed services

### Dev to prod: things to watch out for

- bind mounts shouldn't be used in production
- containerising apps might need a build step
- multi-container projects might need to be split (or should be split) across multiple hosts/remote machines
- trade-offs between control and responsibility might be worth it

### a Managed/automated approach

Instead of running our own ec2/remote machines has drawbacks if we don't have the know how

We can run managed remote machines (eg AWS ECS)

Elastic Container Service, allows to manage containers (launch, monitor etc)

Creation, management, updating is handled automatically, monitoring and scaling is simplified

Great if you simply want to deploy your app/containers

## Important: AWS, Pricing and ECS

In the next lectures, we're using a service called AWS ECS (Elastic Container Service).

Unlike EC2, it's NOT covered by the AWS free tier - you can check the "Free Tier" page to see what's included: https://aws.amazon.com/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc

You should therefore only follow along actively, if you are okay with incurring some costs. You'll only be charged a few dollars if you follow along as shown (and you then remove all resources thereafter) - to learn more about the AWS pricing, please visit their pricing page: https://aws.amazon.com/pricing/

---

Important: You really should double-check to remove ALL created resources (e.g. load balancers, NAT gateways etc.) once you're done - otherwise, monthly costs can be much higher!

## Deploying with AWS ECS: a managed docker container service

In aws, navigate to ECS (or use search bar)

Note: check the pricing, it may or may not be free (hey, they have to make money somehwere !)

Click `get started`

ECS has 4 categories/layers

- cluster
- service
- task definition
- container definition

### Container definition:

We are basically defining how docker run should be executed:

- name
- image
- port
  ...

There is also more advanced commande like

- environment, where we can override command/entry point, environement var
- network settings
- healthcheck
- storage & logging

### task definition

is the bleuprint of the application, telling aws how to launch the server running the container

Here we use FARGATE which launches it in serveless mode (this could also be set to EC2), fargate means that it will start the container when needed, run it's task and then shut down avoid additional billing

### Service

service controls how the taks & server is executed. here we can use a load balancer.

### Cluster

Overall network were our service runs
If we had a multi container app, we could group multiple container together

Note:
In current state of AWS ECS, these section are grouped:

- cluster => service
- task definition => container

You'll also need the task setup to define it in the server

Once created, you can go to `cluster -> service -> tasks` to find the instance, click on it's id, and you should find the public address you can reach

Note: the service security group needs to allow tcp:80, if you don't create a new security group you'll have to either recreate a service or modify the group

## More on AWS

Free youtube tutorials:

https://academind.com/tutorials/aws-the-basics

Fargate:

it will spin up a server only when needed and it will be managed for us

## Updating managed container

Lets make another change to welcome.html

Then build:

`docker build --platform linux/amd64 -t node-deploy-example-1 .`

Tag it

`docker tag node-deploy-example-1 {name}/node-deploy-example-1`

Push it

`docker push {name}/node-deploy-example-1`

Now, how do we update the image in aws. It doesn't do it automatically (would be kind of bad).

Task deinition => select => create new revision

Leave all as the same as aws will pull down the latest image

Create

Then go to service and update the service.

## clean up

As AWS bills for the various elements, better stop and delete them.

clusters => my cluster => select service => delete

If you get:

`The service cannot be stopped while it is scaled above 0.`

you either force delete or go and update the desired count of the service to 0.

Then the Cluster

## Preparing for multi container app

Here we going to deploy 2 containers:

- backend
- mongodb

We have docker-compose for running definitions of containers on our machine. But it doesn't allow us to set thiungs that are important like capacity, deploy across machines etc

Different providers might want different extra information to run the containers etc.

Docker compose is greate for running and managing containers on one/same machine.

So lets build the images we're going to use starting with the backend

First, we have the fix the urls!
We've been relying on the service names to reference other cotnainers in the same docker network. `mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@mongodb:27017/course-goals?authSource=admin`,

But on the cloud the docker network won't work. Localy our network is on the same machine so it's easy to find the matching containers. But on the cloud, there is no guarantee where our 2 containers are going to run.

If we add both containers to the same task (which we are going to do), then they are guaranteed to be on the same machine, but ecs will not create a docker network. However, this does allow us to use localhost to access other containers.

To handle different urls in different builds, we can leverage env variables

`MONGODB_URL`

`mongodb://${process.env.MONGODB_USERNAME}:${process.env.MONGODB_PASSWORD}@${process.env.MONGODB_URL}:27017/course-goals?authSource=admin`,

add it to your local env/backend.env

`MONGODB_URL=mongodb`

And ECS, we pass in a different value.

Now we can build

`docker build -t goals-node-04  --platform linux/amd64 ./backend/`

`docker tag goals-node-04 {name}/goals-node-04`

`docker push goals-node-04

Create a new repo in docker hub (note: it is possible to hust push without create in the repo)

```
1. docker buildx build --platform linux/amd64 -t {name}/goals-node ./backend

(buildx & --platform is for Apple M1 chip)

2. docker push {name}/goals-node
```

## Configuring the nodejs back end container

Now we can create a new cluster/service/task to run our backend service

Create Cluster

Create task definition

Launch type: fargate

Task role: ecsTaskExecutionRole

Create a container using image anarkia1985/goals-node-04

Expose port 80

Docker configuration:
We want to override the default command as we don't want to run nodemon and instead we want to just run `node app.js`
command: `node,app.js`

Environment variables:
Create the same vars are in backend.env and set values
Note: MONGODB_URL needs to be `localhost`

Leave the rest (as all other configs in docker compose where for local purposes)

Now lets add mongodb

## Deploying a second container & a load balancer

Add another container

Name `mongodb` or whatever you want

Image: `mongo`

Add a port 27017

add the environment vars of mongo.env

We need a storage, but we'll come back on how to persist it

Now we can launch a service

Clusters => my cluster => create (service)

keep as fargate

Select newly created task

name it

Under networking select the vc of the cluster

Under subnet add both subnets

Add/create security group that allows 80

and public ip

Add a load balance `application load balancer`

Create a new one, name it, ensure it uses port 80

create target group (just name it)

Hit create

Eventually you'll see

cluster shows service

service shows task

task shows container

## Using a Load Balancer for a Stable Domain

Each time we update our service, it changes IP which is annoying, Load Balancer can help with this

In EC2 -> loadbalancer you can see the LB we created

In the LB details there is a DNS name that looks like an url (DNS name)

If we copy it, you can access the service without neededing to know the ip. This allows us to have a persistent url no matter what the actual ip of the service becomes

Note: when creating the target group of the load balancer, we left the Path as `/` but our app doesn't respond to just `/` so it will always return `404` which is unhealthy. We need to change the path to an existing end point `/goals`

## Using EFS Volumes with ECS

Currently if we deploy anything new (update container code), everything wil work, but the previous data will be destroyed along with the container.

This is because we haven't defined any volume to persist data past the container destruction

Lets go to task definitions and create a new revision from the latest revision available

Keep the same config

In `Storage` select `add volume`

Name it whatever you want (it doesn't have to follow the naming you localy due to file structure)

Then chose `Volume type` => `EFS` (elastic file system)

We currently don't have a file system so lets go to the EFS console

Chose a name, and select the same VPC as your service and containers

Then `Customize`

Click next, then in `Network Access`

Then in a separate tab, go to ec2 security group and create a new security group

Check that VPC is the same

Add an inboud rule

NFS

Custom

then in source select the security group that is managing the container

This will allow our containers to talk to the NFS created in the NFS security group

Then in the EFS network, replace the default SG by the new one we just created

Back in the Task definition revision, use the files system id we just created

Then select Add Mount point

Container => mongodb
Source Volume => your EFS name
Container Path => /data/db

Now Create the new revision

Go to the service and select `Update Service`

Select the revision (and force new deployment if needed)

Then click update and wait for it to redeploy

## Databases & containers: An important consideration

A note about databases

You can absolutly manage your own database containers but

- scaling & managing availability can be challenging
- performance (also traffic spikes) could be bad
- taking care about backups and security can be challenging

Consider using a managed database service (eg AWS RDS, MongoDB Atlas...)

## Moving to MongoDB Atlas

Go to mongo db atlas an chose the free tier

Select `Create cluster`

`FREE` tiers

`aws`

chose a name and a region (close to your aws cluster)

Fill in other user related questions

then create.

Once it's ready, chose `connect` for details on how to access it

Copy the sample url string into your app

Now we face a dilema do we want to use our cloud db for dev and prod or just prod

if we don't use it for dev, then we have to ensure that we are using the same versions of mongo db locally and remotely

if we use both in the cloud, we would have to find a way to manage dev data from prod data, we would also have to always be connected to it

We're going to go with the approach of always keeping it in sync by using cloud for everything

let's update the url

update the url (we are adding a new env param MONGODB_NAME for switching db in the cloud)

Add MONGODB_NAME to docker file

Update the credentials in mongo.env and backend.env

Now lets update our docker compose, as we are going to be using our cloud, we no longer need the mongodb container in the yaml

we also need to update the url 

`MONGODB_URL=oalsnode04cluster.fnt8edn.mongodb.net`

You'll also need to configure in the cloud: 
- network access with your ip
- database access, create a new user with read/write access

Now we should be able to do `docker up` and connect to mongo db

## Using MongoDB Atlas in Production

To get it working in prod is straight forwards

- rebuild the image so that it has the new parameter (technically could be skipped if we use the same db)
```
docker build -t anarkia1985/goals-node-04  --platform linux/amd64 ./backend/

docker push anarkia1985/goals-node-04
```
- remove mongo db from task definition
- remove the volume and volume related resources
- update the env variables to point to mongo db atlas

We can use the same load balancing url (as it hasn't changed)

Now lets look at deploying the front end too

## Understanding a Common problem

Typically, web apps have a build step as we can't run them in the same way as locally 

Optimizing the scripts that needs to be executed AFTER dev but BEFORE deployment (typically js app that run in the browser)

Dev setup !== production setup 

Locally we work with jsx/ts/frameworks/hot reload/dev server etc. It's vebrose so that developers can follow/understand what is happening.

Locally we run scripts that `npm start` that create a locally creates a environment that is freindly for development. The drawback is that this is serving dozens or hundreds of files to the user(s) which would be ineffecient (as the users don't need/care about individual files, granularity etc)

For production, react has a build step that will do build compilation and optimization so that it's servered properly.
The Build script will give us what we need for production, but not a server to run it in

## Creating a "build-only" container

For some projects like web apps, there is a build set that compiles the code for deployments, in our cases 

`"build": "react-scripts build"`

Lets see how docker can be utilized to create a image ready for deployment.

In prod we won't need all the features of node, we just need enough to build the app and run a prod server

So we'll create a new Dockerfile (let's call it `Dockerfile.prod` to differentiate)

```
FROM node:14-alpine

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 3000

CMD [ "npm", "run", "build" ]
```

This will build the app, but not the server, so we'll use multi-stage builds

## Introducing multi-stage builds

One dockerfile, multiple build/setup steps ("stages")

Stages can copy results (created files and folders) from each other

You can either ubild the complete image or select individual stages

Instead of `CMD` we use `RUN` and then we can continue with more steps

`CMD [ "npm", "run", "build" ]` becomes

`RUN npm run build`

But we only need node for install and build, not to server

So we'll want to switch to a different base image

Note: Every FROM instruction creates a new stage in your dockerfile. even if you use the same image as in the previous step

Lets use nginx as the next stage

`FROM nginx:stable-alpine`

We'll want to reuse the result of the first stage in the second stage, so to be able to reference it, we need to name the first stage

`FROM node:14-alpine as build`

This way we can copy and reuse it 

`COPY --from=build /app/build /usr/share/nginx/html`

export the port 

`EXPOSE 80`

launch nginx ourself

`CMD [ "nginx", "-g", "daemon off;" ]`

Now lets see how we can deploy this

## BUilding a Multi-stage image

First, we need to make some adjustments

Using `localhost` will no longer work. In AWS ECS `localhost` works if the code is run on the server directly, however for a web app, we'll be server the compiled code the the client browser were it will be executed.

We are planning on serving the app as part of the same ECS server so we can reuse the url 

`http://localhost/goals` becomes `/goals` because by default, the browser will send this request the the same url as the sever

If we were serving from a different server, we would have to pass in the backend server url through env

Create a new repo on docker hub `goals-react-04`

Build the image

`docker build -t anarkia1985/goals-react-04 -f ./frontend/Dockerfile.prod ./frontend`

Note: we need to use -f to specify the file name, and for that we have to sepcify the relative file path AND still the folder at the end of the command. at the end, we specify the context, with -f sets the name of the file

Then push it 

`docker push anarkia1985/goals-react-04`

## Deploying a standalone frontend app

First lets go back to our task definitions to add a new container

New revision 

Add container

name it and enter your dockerhub iamge `anarkia1985/goals-react-04`

Lets also add a `startup dependency ordering` to ensure our back end has `success`fully started

However we have a problem, now our Backend and our Frontend use port 80, which is not possible on the same server

We could: 

- merge front and back end as they are both node apps 
- change the port of the backend

Or we can split the frontend and backend in 2 separate tasks

Lets use the same config 
- fargate
- min ram/cpu
- container 

We'll also have to rebuild our image as we'll have to pass in the urls

`const backendUrl = process.env.NODE_ENV === "development" ? "http://localhost" : 'urlFromLoadBalancer;'`

Get the url for the BE loadbalancer 
Create a new load balancer for FE while your there (with target group set to ip)

Now rebuild, push and we can use it

Once pusehd we can create a new service `GoalsReact04Service` 

fargate

1 task 

Rolling updates 

Select the subnets, security group and load balancer

## Understanding Multi-Stage Build targets

Additional note on how to run only sime sateges

`docker build --target build -t anarkia1985/goals-react-04 -f ./frontend/Dockerfile.prod ./frontend`

if we wanted to just build the code but not run the nginx part

## Beyond AWS

AWS was just the example provider in this section 

Other providers will provider similar solutions








