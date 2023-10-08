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


