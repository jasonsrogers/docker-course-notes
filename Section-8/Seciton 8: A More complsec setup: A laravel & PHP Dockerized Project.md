# Seciton 8: A More complex setup: A laravel & PHP Dockerized Project

We are going to look at how to setup laravel setup through docker without installing anything localy

We want to change from node to show that we can work with anything

## The Target

Laravel is great but the php setup requirements are a pain

Node is a one stop shop where we have everything we need

PHP requires more than just PHP, we need a additional server (and potentially a database etc), suddenly we have to install multiple products our machine

Our goal here is to have:

- a folder on our machine that contains our source code
- a container with the php interpreter
- a container with nginx we server (to host our php)
- a container with (mysql) database to store

These are all app container that will stay up and running

We also need utility containers:

- a container for compose (equivalent of npm)
- a container for laravel artisan (migration and write db schema)
- a container for npm

6 container around our code!

```
services:
  server:
  php:
  mysql:
  composer:
  artisan:
  npm:
```

## Adding nginx (web server) container

```
server:
    image: "nginx:stable-alpine"
    ports:
      - "8000:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
```

`nginx:stable-alpine` to use a stable slim image of nginx

`8000:80` to expose the port

`volumes` following the officials docks, we'll bind mount `./nginx/nginx.conf` to `/etc/nginx/nginx.conf:ro` and make it read only

And that is it

## adding a PHP container

We need a custom image base of php official images:

```
FROM php:7.4-fpm-alpine

WORKDIR /var/www/html

RUN docker-php-ext-install pdo pdo_mysql
```

We need custom because we want to add `pdo` and `pdo_mysql`

We don't have a `CMD`, if we don't specify one it will default to the `CMD` of the base image

Defining the php service in yaml

```
  php:
    build:
      context: ./dockerfiles
      dockerfile: php.dockerfile
```

We need to use the advanced build option to specify context and the name of the dockerfile

We also need a bindmount to make the source code available inside of the container

```
volumes:
      - ./src:/var/www/html:delegated
```

Note: `:delegated` will delay passing the changes to the container and instead will copy them in batches, this improves performance (just like a debounce)

```
ports:
      - "3000:9000"
```

nginx sends to 3000, php exposes 9000

so we should map the ports as above.

BUT, since it's container to container communication in the same network, we don't need to open ports, we can just adjust nginx.conf to 9000

## mysql container

We're going to use the official image

```
mysql:
    image: "mysql:5.7"
    env_file:
      - ./env/mysql.env
```

And we'll specify the defaults in an env file

## Composer container

custom image because we need to set the entry point

```
FROM composer:latest

WORKDIR /var/www/html

ENTRYPOINT [ "composer", "--ignore-plarform-reqs" ]
```

add it to compose

```
composer:
    build:
      context: ./dockerfiles
      dockerfile: composer.dockerfile
```

we also need a bindmount to our source code so that it can create code (like npm init did )

## Creating a laravel app via the composer utility container

via composer create project

`composer create-project --prefer-dist laravel/laravel .`

using out container would be:

`docker compose run --rm composer create-project --prefer-dist laravel/laravel .`

## Launching only some docker compose services

First in `src` we need to set some values in `.env`

we need to db values to match in src and in mysqlenv

```
DB_DATABASE=homestead
DB_USERNAME=homestead
DB_PASSWORD=secret
```

but also adjust the url:

```
DB_HOST=mysql
```

we use the name of the service as it will be managed by docker compose

Looking out our setup, we need nginx to know about our php files, so we need to expose them by updating `services -> server -> volumes`

Now to run it:

we want to run `server`, `php` and `mysql` but not the rest

so we are going to use `docker compose up` but specifying what we want to run

`docker compose up -d server php mysql`

If we check, php and mysql started but not server

` - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro` is wrong

it should be

`- ./nginx/nginx.conf:/etc/nginx/conf.d/default.conf:ro`

Note: M1/M2 need to add `platform: linux/x86_64` in the mysql image

`docker compose up -d server php mysql`

this allows us to only run server, php and mysql

But it's a bit annoying to type out

We can leverage `depends_on` in server to make it so that `php` and `mysql` always start when server start

now out command is just:

`docker compose up -d server`

Currently our docker compose only looks if the image exists, so if we make changes to code or docker file, it will not pick up on it automatically.

To fix this, we can add `--build` it will force docker to go through the dockerfiles and recreate if something changed, if nothing changed, it doesn't build

`docker compose up -d --build server`

Now if we change src, it will be reflected

for example: src/resources/views/welcome.blade.php

## adding more utilities

Artisan is based on php, so let reuse the php.dockerfile and tweak the volumes

However we want to add an entry point for `artisan` but not `php` and we can do that at a docker compose level

```
entrypoint: ["php", "/var/www/html/artisan"]
```

This will execute php inside the artisan file effectively starting the artisan utility (you can see the file at `src/artisan`)

for practice we'll define the npm container by overriding the node image form docker compose

```
 npm:
    image: node:14
    working_dir: /var/www/html
    entrypoint: ["npm"]
    volumes:
      - ./src:/var/www/html
```

Let now try running artisan

`docker compose run --rm artisan migrate`

## Docker compose with and without dockerfile

you can chose to use in your docker compose

- docker file + instruction overides
- docker file only (all instructions are in docker file)
- image + instruction overides
- image only

it's up to you to determine what makes the most sense for your use case

having docker files makes compose lean but you have to open the files to know what is happening.
Also you can't use copy and run in compose, so sometimes you have to use docker

Bind mounts are great for dev but not great for deployment

you need the files/directory to exist on the host, which is the case when doing dev, but when deploying you don't want to have to do setup outside of the container (that would beat the point of have containers :) )

To get round this we could create a container to make a snapshot of the source code

## Bind mounts and copy: when to use what

Here is an example of how to create it (dockerfiles/nginx.dockerfile)

```
FROM nginx:stable-alpine

# set the working directory to to the nginx config directory
WORKDIR /etc/nginx/conf.d
# copy the content of the local nginx config directory to the working directory
COPY nginx/nginx.conf .
# rename the nginx config file to default.conf
RUN mv nginx.conf default.conf
# change the working directory to the nginx html directory
WORKDIR /var/www/html
# copy the content of the local src directory to the working directory
COPY src/ .
```

Now we can use this image in compose

```
build:
      context: .
      dockerfile: dockerfiles/nginx.dockerfile
```

Note: we set the context to `.` because we want it to have access to src and nginx which are at the same level as yaml
If we did `context: ./dockerfiles` our container would only have access to dockerfiles and fail to copy

Now we have an image that snapshots nginx cong and src when it's built so it can be deployed but also can act with bind mounts for dev as defined previously

We want to do the same for php

```
COPY src .
```

now if we comment out the bing mount volumes form nginx and php we can simulate running a snapshot

`docker compose up -d --build server`

This builds but when we try to access it, it doesn't work due to access error

By default images allow read/write of files, but the `php` image doesn't allow!

`RUN chown -R www-data:www-data /var/www/html`

we add -R read access to `/var/www/html` for the default user `www-data:www-data`

Obviously lets update artisan that relies on php

```
artisan:
    build:
      context: .
      dockerfile: dockerfiles/php.dockerfile
```
