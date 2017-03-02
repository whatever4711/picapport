[![Build Status](https://travis-ci.org/whatever4711/picapport.svg?branch=master)](https://travis-ci.org/whatever4711/picapport) [![](https://images.microbadger.com/badges/version/whatever4711/picapport.svg)](https://microbadger.com/images/whatever4711/picapport "Get your own version badge on microbadger.com") [![](https://images.microbadger.com/badges/image/whatever4711/picapport:amd64.svg)](https://microbadger.com/images/whatever4711/picapport:amd64 "Get your own image badge on microbadger.com")

# Picapport in a Container

Currently, this is a docker image based on the rpi-java image (whatever4711/rpi-java) and has [Picapport](http://www.picapport.de/) installed.

## Starting the container
`docker run -d --name picapport -p 8080:80 whatever4711/rpi-picapport`
Thereafter you can access picapport on http://ip-pi:8080

## Specifying Custom Configurations

Create a file `picapport.properties` and save it in a folder, e.g. `config`. You can specify all parameter described in the [Picapport server guide](http://wiki.picapport.de/display/PIC/PicApport-Server+Guide):
```
server.port=80
robot.root.0.path=/srv/photos
foto.jpg.usecache=2
foto.jpg.cache.path=/srv/cache
```
In this file we specified, e.g., the path for picapport to search for the pictures inside the docker container, and the path, where all cached photos are stored.

### Mounting Volumes

- Mount your configuration with: `-v $PWD/config:/opt/picapport/.picapport`
- Mount your photos with: `-v /path/to/fotos:/srv/photos`
- Eventually mount the cache with `-v /path/to/cache:/srv/cache`

`docker run -d --name picapport -p 8080:80 -v $PWD/config:/opt/picapport/.picapport -v /path/to/fotos:/srv/photos -v /path/to/cache:/srv/cache whatever4711/rpi-picapport`
