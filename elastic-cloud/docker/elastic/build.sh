#!/usr/bin/env bash

REPO=wizes
IMAGE=elasticsearch
TAG=4

RELEASE=test

docker build -t $REPO/$IMAGE:$TAG .

# docker run -p 9200:9200 -p 9300:9300 --name $RELEASE $REPO/$IMAGE:$TAG
docker run -d --rm -p 9200:9200 -p 9300:9300 --name $RELEASE $REPO/$IMAGE:$TAG

# docker container prune
# docker images prune

# registry/distribution.sh
docker tag $REPO/$IMAGE:$TAG localhost:5000/$IMAGE:$TAG
docker push localhost:5000/$IMAGE:$TAG
