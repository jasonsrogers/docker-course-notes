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

1) Create and launch EC2 instance, vpx and security group
2) configure security gorup to expose all required ports to www
3) connect to instance (ssh) install docker and run container

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







