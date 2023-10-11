FROM composer:latest

WORKDIR /var/www/html

# ENTRYPOINT [ "composer", "--ignore-plarform-reqs" ]
ENTRYPOINT [ "composer" , "--ignore-platform-req=php"]