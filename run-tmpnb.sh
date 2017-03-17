#!/bin/sh

# This script starts a tmpnb server using docker, with a user-configurable jupyter notebook container

if [ -z "$1" ]; then
  echo "Usage: $0 <notebook_password>"
  echo
  echo "notebook_password should be a simple password users will use to access the tmpnb server"
  exit 1
fi

NOTEBOOK_PASSWORD=$1 # The password users will have to provide to access a notebook

export NOTEBOOK_IMAGE="jupyter/scipy-notebook"
export EXTERNAL_PORT="8000"

export INTERNAL_PORT=$(($EXTERNAL_PORT+1))
export TOKEN=$( head -c 30 /dev/urandom | xxd -p )

# Clear out any existing containers
docker rm -f proxy tmpnb 2> /dev/null

OLD_NOTEBOOKS=$(docker ps --filter=ancestor=${NOTEBOOK_IMAGE} -a -q)

if [ "$OLD_NOTEBOOKS" ]; then
  docker rm -f $OLD_NOTEBOOKS
fi

# First, pull the notebook image. The orchestration container (tmpnb) will not pull the notebook image before launching
docker pull ${NOTEBOOK_IMAGE}

# Start the web proxy container that listens for user web requests
docker run \
  --restart=unless-stopped \
  --net=host \
  -d \
  -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
  --name=proxy jupyter/configurable-http-proxy \
  --port ${EXTERNAL_PORT} \
  --default-target http://127.0.0.1:9999

# Start the tmpnb orchestration container that launches notebook images
docker run \
  --net=host \
  --restart=unless-stopped \
  -d \
  -e CONFIGPROXY_AUTH_TOKEN=$TOKEN \
  -e CONFIGPROXY_ENDPOINT=http://127.0.0.1:${INTERNAL_PORT} \
  --name=tmpnb \
  -v /var/run/docker.sock:/docker.sock \
  jupyter/tmpnb python orchestrate.py --image=$NOTEBOOK_IMAGE --command='start-notebook.sh "--NotebookApp.base_url={base_path} --ip=0.0.0.0 --port={port} --NotebookApp.trust_xheaders=True" --NotebookApp.token='"${NOTEBOOK_PASSWORD}"
