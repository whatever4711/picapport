[![CircleCI](https://circleci.com/gh/whatever4711/picapport.svg?style=svg)](https://circleci.com/gh/whatever4711/picapport)
[![Build status](https://ci.appveyor.com/api/projects/status/m7ndvfjyf106ivd4?svg=true)](https://ci.appveyor.com/project/whatever4711/picapport)

[![](https://images.microbadger.com/badges/version/whatever4711/picapport.svg)](https://microbadger.com/images/whatever4711/picapport "Get your own version badge on microbadger.com")
[![](https://images.microbadger.com/badges/image/whatever4711/picapport.svg)](https://microbadger.com/images/whatever4711/picapport "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/commit/whatever4711/picapport.svg)](https://microbadger.com/images/whatever4711/picapport "Get your own commit badge on microbadger.com")

# Picapport in a Container

Currently, this is a docker image based on Alpine and has [Picapport](http://www.picapport.de/) installed.

## Supported Architectures

This multiarch image supports `amd64`, `i386`, `arm32v6`, `arm64v8`, `ppc64le`, and `s390x` on Linux and `amd64` on Windows

## Starting the container
### For Linux
`docker run -d --name picapport -p 8080:80 whatever4711/picapport`


## Starting the container
### For Windows
`docker run -d --name picapport -p 8080:80 whatever4711/picapport:windows-amd64`

Thereafter you can access picapport on http://localhost:8080

## Specifying Custom Configurations

Create a file `picapport.properties` and save it in a folder, e.g. `config`. You can specify all parameter described in the [Picapport server guide](http://wiki.picapport.de/display/PIC/PicApport-Server+Guide):
```
server.port=80
robot.root.0.path=/srv/photos
foto.jpg.usecache=2
foto.jpg.cache.path=/srv/cache
```
In this file we specified, e.g., the path for picapport to search for the pictures inside the docker container, and the path, where all cached photos are stored.

## Mounting Volumes

- Mount your configuration with: `-v $PWD/config:/opt/picapport/.picapport`
- Mount your photos with: `-v /path/to/your/fotos:/srv/photos`
- Eventually mount the cache with `-v /path/to/cache:/srv/cache`

`docker run -d --name picapport -p 8080:80 -v $PWD/config:/opt/picapport/.picapport -v /path/to/fotos:/srv/photos -v /path/to/cache:/srv/cache whatever4711/picapport`

## Easier setup with docker-compose
```YAML
version: '3'

services:
  picapport:
    image: whatever4711/picapport
    restart: always
    expose:
      - 80
    networks:
      - backend
    volumes:
      - /path/to/your/configuration:/opt/picapport/.picapport
      - /path/to/your/fotos:/srv/photos
```
Run it with `docker-compose up -d`
