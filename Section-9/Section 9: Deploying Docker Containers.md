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
