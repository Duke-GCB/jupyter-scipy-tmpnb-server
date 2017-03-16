jupyter-scipy-tmpnb-server
==========================

Script for creating a tmpnb server launching a jupyter/scipy-notebook using Docker

## Usage

1. Install docker on your host
2. Run the script: `run-tmpnb.sh <notebook_password>`
  - Where `<notebook_password>` is a simple password you can provide to users to let them launch a container.
3. Visit http://your-host, and provide the password when prompted.

For troubleshooting, check the docker logs of the `tmpnb` or `proxy` containers

The docker containers use host networking, which does not work on macOS as of this writing.
