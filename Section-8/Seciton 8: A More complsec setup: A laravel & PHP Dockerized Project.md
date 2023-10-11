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

