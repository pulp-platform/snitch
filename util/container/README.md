# Docker Container

Docker container based on Ubuntu 18.04 LTS containing various hardware and
software development tools for Snitch.

## Local Build Instructions

Skip this step if planning to use the pre-built container. To build in local
mode:

```shell
$ cd $REPO_TOP
$ sudo docker build -t snitch -f util/container/Dockerfile .
```

## Using the Container

To run container in interactive mode:

```shell
$ docker run -it -v $REPO_TOP:/repo -w /repo snitch
```
