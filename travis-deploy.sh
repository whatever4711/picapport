#!/bin/bash
set -e

if [[ "$TRAVIS_TAG" ]]; then
  tag=$TRAVIS_TAG
else
  tag=latest
fi

image="whatever4711/picapport"
docker tag picapport "$image:linux-$ARCH-$tag"
docker push "$image:linux-$ARCH-$tag"

if [ "$ARCH" == "amd64" ]; then
  set +e
  echo "Waiting for other images $image:linux-arm-$tag"
  until docker run --rm stefanscherer/winspector "$image:linux-arm-$tag"
  do
    sleep 15
    echo "Try again"
  done
  until docker run --rm stefanscherer/winspector "$image:linux-arm64-$tag"
  do
    sleep 15
    echo "Try again"
  done
  set -e

  echo "Downloading docker client with manifest command"
  wget https://6582-88013053-gh.circle-artifacts.com/1/work/build/docker-linux-amd64
  mv docker-linux-amd64 docker
  chmod +x docker
  ./docker version

  set -x

  echo "Pushing manifest $image:$tag"
  ./docker -D manifest create "$image:$tag" \
    "$image:linux-amd64-$tag" \
    "$image:linux-arm-$tag" \
    "$image:linux-arm64-$tag"
  ./docker manifest annotate "$image:$tag" "$image:linux-arm-$tag" --os linux --arch arm --variant v6
  ./docker manifest annotate "$image:$tag" "$image:linux-arm64-$tag" --os linux --arch arm64 --variant v8
  ./docker manifest push "$image:$tag"
fi
