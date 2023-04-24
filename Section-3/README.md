# managing data and working with volumes

Managing data in images and containers.

Write, read & persist.

understanding different kinds of data

volumes

using arguments and environment variables

## understanding data categories

### application
application (code + environment)

written & provided by us

added to image and container in build phase

Is "fixed" in the sense that it is not changed after the image is built

images are read only 

Read-only hence stored in images

### temporary app data (entered by user input)

fetched/produced in running container 

stored in memory or temporary files 

dynamic and changiong but cleared regularly

Read + write temporary, hence stored in containers

### permanent app data

user accounts

fetched/produced in running container

stored in files or a database

must not be lost if container is stopped/restared/deleted

read + write permanent sored with container & volumes

## analyzing a real app

Node 

couple of routes to handle

form that enters feedback 

stores feedback in a couple of file in temp and feedback.

### Dockerize the app 

```Dockerfile
FROM node: 14

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

EXPOSE 80

CMD ["node", "sever.js"]
```

build the image

`docker build -t feedback-node .`

Note: we don't separate the tag after the image name, this will default to latest

`docker run -p 3000:80 -d --name feedback-app --rm feedback-node`

The app saves the feedback in a file called `/feedback/[title].txt`

if we go to `localhost:3000/feedback/test.txt` we can see the feedback, but it's not in our feedback folder in the project directory.

Since the `COPY . .` we create a new file structure inside the container but it's not reflected in the host.

When we stop the container is deleted thanks to the `--rm` flag. So when we run it again, it has forgotten the feedback.

if we run it without the `--rm` flag, we can see the feedback is still there.

`docker run -p 3000:80 -d --name feedback-app feedback-node`

`docker stop feedback-app`

`docker start feedback-app`

the feedback is still there.

stopping a container doesn't clear the content of the container.

but it's isolated in the container, it can't be shared, it doesn't survive destruction (for example building a new version of the image)

## introducing volumes

Volumes are folders on your host that are mounted into the container.

These are made available to the container and can be used to store data. The container will have a local reference to the volume.

It sounds like `COPY` but it's not. `COPY` is a one time operation, volumes are shared between the host and the container.

Changes in the container are reflected in the host and vice versa.

Volumes allows persistence of data. Containers can both read and write to volumes.

### How to add a volume

In our application, we save the feedback in a folder called `feedback`. So we should create a volume with that name.

`VOLUME ["/app/feedback"]`

We specify the path inside the container, not the host. The host path is specified when we run the container.

`docker build -t feedback-node:volumes .`

Note: leveraging tags

`docker run -d -p 3000:80 --rm feedback-node:volumes`

But this doesn't work, lets check the logs 

`docker logs feedback-app`

error: UnhandledPromiseRejectionWarning: Error: EXDEV: cross-device link not permitted, rename '/app/feedback' -> '/app/feedback.txt'

The reason is the rename function as the sync  between container and host doesn't like it.

`await fs.rename(tempFilePath, finalFilePath);`

solution: use `fs.copyFileSync` instead of `fs.rename`

```js
// create a copy of the file
await fs.copyFile(tempFilePath, finalFilePath);
// delete file by using unlink
await fs.unlink(tempFilePath);
```

And... it still doesn't work :(


