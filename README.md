# Docker CentOS7 LAMP

This project was born out of a need to have a base-image that is a solid LAMP stack. I wasn't happy with any of the other Dockerfiles I could find that other people have built. I do recognize that this project violates Docker best-practices by combining multiple applications into a single container image. However, I find that using Docker in this manner allows me to create a simple single project that will stand up a containerized image of an application. While not as flexible as a Docker swarm, it is vastly simpler to create and maintain by a user not familiar with Docker swarm.

## Installed Packages

1. CentOS 7: Latest at the time you build

  - supervisor, with CLI script to easily add new applications to config file
  - syslog-ng
  - cron
  - logrotate

2. Apache 2.4.6: Latest from CentOS YUM, at the time you build

3. MariaDB 10.3: Downloaded directly from MariaDB's YUM repository

  - Supports auto-loading an .sql file if it exists on the filesystem
  - No root MySQL password is set, so it is ready for you to connect to and use!

4. PHP 7.2: Downloaded from Webtatic's YUM repository; mod_php + CLI

--------------------------------------------------------------------------------

This package was originally built for my docker-c7-rtorrent-flood project. As such, this project contains a one-liner script that will fully download, build/compile, both this project and the docker-c7-rtorrent-flood project. This results in an rTorrent+Flood instance that is ready for you to log in and use.

With that said, this is perfectly usable as a CentOS7 LAMP stack to build your Docker application on top of.

## To build the docker-c7 & docker-c7-rtorrent-flood projects

```
curl -o latest -L https://raw.githubusercontent.com/XelaNull/docker-c7/master/latest && sh latest
```

--------------------------------------------------------------------------------

## To build JUST this docker-c7 project:

```
docker build -t c7/lamp .
```

## To run JUST this docker-c7:

```
docker run -dt -p8080:80 --name=c7-lamp c7/lamp
```

## To enter JUST this docker-c7:

```
docker exec -it c7-lamp bash
```
