#!/bin/sh

export NOTEBOOK_IMAGE="jupyter/scipy-notebook"

# Clear out any existing containers
docker rm -f proxy tmpnb 2> /dev/null
OLD_NOTEBOOKS=$(docker ps --filter=ancestor=${NOTEBOOK_IMAGE} -a -q)
if [ "$OLD_NOTEBOOKS" ]; then
  docker rm -f $OLD_NOTEBOOKS
fi
