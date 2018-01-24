#!/bin/bash
set -e

if [[ "$TRAVIS_TAG" ]]; then
  tag=$TRAVIS_TAG
else
  tag=latest
fi

image="whatever4711/picapport"
docker push "$image:linux-$ARCH-$tag"

if [ "$ARCH" == "amd64" ]; then
  # test image
  docker run -d -p 8080:8080 --name=picapporttest "$image:linux-$ARCH-$tag"

  sleep 5

  docker logs picapporttest
fi
