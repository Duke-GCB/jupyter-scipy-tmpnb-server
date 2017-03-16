FROM jupyter/scipy-notebook:latest
MAINTAINER dan.leehr@duke.edu
USER root
RUN apt-get update && apt-get install -y texlive-xetex
