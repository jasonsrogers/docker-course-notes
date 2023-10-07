# Section 7: Working with "Utility Containers" & Executing Commands in containers

What are "Utility Containers"? 

This is not an official term

The primary use of Docker is what we saw before:

Create an image with env and app, then run the CMD that start the app.

`docker run myapp`

Utility containers just have an environement (node, php etc) 

We then run a command specified by us to execute a custome command

`docker run mynpm init`

We add an extra after the name of the image.

## Why would we use them

If we want to create a new node project, we could create the package.json by hand, but that would be tedious. 

Instead we usually rely on an `init` method provided.

For a basic node app, we would use `npm init` and answer some questions.

But this implies have node installed on the host.

This can be avoided by using utility containers.

Note: this is not a problem limited to node, a lot of other frameworks also require this (for example: php laravel willb e show in next section)

## Different ways of running commands in containers

`docker run node`

this would start and stop because there is nothing to do, because we need to start it in `-it` (interactive) mode

`docker run -it node`

Now lets run it detached :) 

`docker run -it -d node`

Now we have a container running separatly waiting for interactions

lets connect to it using exec, exec will allow us to run different commands that the one specified in the image CMD

`docker exec [NAME] [CMD]`

`docker exec -it [NAME] npm init`

Now we run npm init inside the container (note: we need -it just like when we run the container)

We can also override the default command of `run`

`docker run -it node npm init`

## BUilding a First Utility Container

Create a image (without even a cmd to give user full control)

```
FROM node:14-alpine

WORKDIR /app
```

then run it

`docker run -it node-util npm init`

but lets also bind mount it locally to get the result synced to our host

`docker run -it -v [absolute path]]/app:/app node-util npm init`

`docker run -it -v [absolute path]]/app:/app node-util npm install prettier`

It will prompt questions and when finished we will have a package.json

## Utilizing ENTRYPOINT

Now let's look at the restricting our util to only npm commands rather than all node commands.

Currently, if we add a CMD at the end of the run command, it overrides the CMD inside the Dockerfile.

However, if we use `ENTRYPOINT` it acts in a similar way as CMD but it will append extra run commands after the entry point 

example: 

CMD ["node"]

`docker run node-util npm init`

will result in `npm init` being executed

ENTRYPOINT ['npm']

`docker run npm-util init`

will result in `npm init`

`docker run npm-util init`
`docker run npm-util install`
`docker run npm-util install prettier`

Once again, we run into the long commands issue

## Using docker compose

Let's recreate the command in docker-compose 

```
version: '3.8'
services:
  npm:
    build: ./
    stdin_open: true
    tty: true
    volumes:
      - ./app:/app
```

but if we run `docker compose up`, it doesn't quite work

we only execute `npm` (entrypoint) without anything else

so we have to specify a npm command to run

`docker compose up init`

=> it fails `no such service: init`

`docker compose run [service] [command]`

`docker compose run init`

Note: `docker compose run` doesn't tear down the containers like `docker compose down` so we have to add a flag

`docker compose run --rm [service] [command]`
