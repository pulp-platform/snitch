# Docker Container

Docker container based on Ubuntu 18.04 LTS containing various hardware and
software development tools for Snitch.

## Pre-built Container

There is an experimental version of the container available.
To download, first login to the GitHub container registry:
```shell
$ docker login ghcr.io
```
You will be asked for a username (your GitHub username).
As a password you should use a
[PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
that at least has package registry read permission.

Then you can run:

```shell
$ docker pull ghcr.io/pulp-platform/snitch
```

## Using the Container

To run container in interactive mode:

```shell
$ docker run -it -v $REPO_TOP:/repo -w /repo ghcr.io/pulp-platform/snitch
```

## Local Build Instructions

In case you do not want to use the pre-built container you can also build the
container in local mode:

```shell
$ cd $REPO_TOP
$ sudo docker build -t ghcr.io/pulp-platform/snitch -f util/container/Dockerfile .
```

## Limitations

Some operations require more memory than the default Docker VM might provide by
default (2 GB on OS X for example). *We recommend at least 16 GB of memory.*

The memory resources can be adjusted in the Docker daemon's settings.

> The swap space is limited to 4 GB in OS X default VM image. It doesn't seem as
> this is enough for using `verilator`, `cc` keeps crashing because it runs out
> of swap space (at least that is what `dmesg` tells us). Also 8 GB of swap
> space don't seem to be enough.
>
> ```shell
> dd if=/dev/zero of=/var/lib/swap bs=1k count=8388608
> chmod go= /var/lib/swap && mkswap /var/lib/swap
> swapon -v /var/lib/swap
> ```
