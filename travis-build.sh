#!/bin/bash
set -e

docker version
uname -a
echo "Updating Docker engine to have multi-stage builds"
sudo service docker stop
curl -fsSL https://get.docker.com/ | sudo sh
docker version

if [ -d tmp ]; then
  docker rm build
  rm -rf tmp
fi

docker run --rm --privileged multiarch/qemu-user-static:register --reset
docker build -t picapport --build-arg "ARCH=$ARCH" --build-arg "VERSION=$(cat VERSION)" .
