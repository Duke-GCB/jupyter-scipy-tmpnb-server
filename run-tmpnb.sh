#!/bin/sh

# This script starts a tmpnb server using docker, with a user-configurable jupyter notebook container

NOTEBOOK_PASSWORD="secret" # The password users will have to provide to access a notebook

# Can use "jupyter/scipy-notebook" once they merge https://github.com/jupyter/docker-stacks/issues/353
NOTEBOOK_IMAGE="dukegcb/scipy-notebook-with-xelatex"
EXTERNAL_PORT="80"

INTERNAL_PORT=$(($EXTERNAL_PORT+1))
TOKEN=$( head -c 30 /dev/urandom | xxd -p )

# Clear out any existing containers
docker rm -f proxy tmpnb
docker rm -f $(docker ps --filter=ancestor=${NOTEBOOK_IMAGE} -a -q)

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
  jupyter/tmpnb python orchestrate.py --image='${NOTEBOOK_IMAGE}' --command='start-notebook.sh "--NotebookApp.base_url={base_path} --ip=0.0.0.0 --port={port} --NotebookApp.trust_xheaders=True" --NotebookApp.token=${NOTEBOOK_PASSWORD}'
