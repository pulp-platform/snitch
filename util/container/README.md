# Docker Container

Docker container based on Ubuntu 18.04 LTS containing various hardware and
software development tools for Snitch.

## Local Build Instructions

To build the container in local mode:

```shell
$ cd $REPO_TOP
$ sudo docker build -t snitch -f util/container/Dockerfile .
```

> We currently do not provide a pre-built image from a registry. This might
> change in the future.

## Using the Container

To run container in interactive mode:

```shell
$ docker run -it -v $REPO_TOP:/repo -w /repo snitch
```
