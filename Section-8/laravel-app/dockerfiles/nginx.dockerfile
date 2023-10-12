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