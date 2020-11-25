# Copyright 2020 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

# Docker container for Snitch development.

FROM ubuntu:18.04 AS snitch
ARG RISCV_GCC_VERSION=8.3.0-2020.04.0
ARG VERIBLE_VERSION=0.0-776-g09e0b87
ARG VERILATOR_VERSION=4.040

LABEL version="0.1"
LABEL description="Snitch container for hardware and software development."
LABEL maintainer="zarubaf@iis.ee.ethz.ch"

WORKDIR /tools

# Install (and cleanup) required packages (from apt-requirements.txt)
# The list of extra packages is leftover from before this Dockerfile used
# apt-requirements.txt
#
# This also adds `locales` and `locales-all` so we can set the locale to utf-8
COPY apt-requirements.txt /tmp/apt-requirements.txt
RUN apt-get update && \
    sed 's/#.*//' /tmp/apt-requirements.txt \
        | xargs apt-get install -y && \
    apt-get install -y \
        locales \
        locales-all \
        gnupg2 \
        libc6-i386 \
        libtool \
        screen \
        curl \
        gpg && \
    apt-get clean ; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# Set Locale to utf-8 everywhere
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

# Install Verilator
RUN echo 'deb http://download.opensuse.org/repositories/home:/phiwag:/edatools/xUbuntu_18.04/ /' | tee /etc/apt/sources.list.d/home:phiwag:edatools.list
RUN curl -fsSL https://download.opensuse.org/repositories/home:phiwag:edatools/xUbuntu_18.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/home_phiwag_edatools.gpg > /dev/null
RUN apt-get update && apt-get install -y verilator-${VERILATOR_VERSION}

# Copy repository into tmp directory to execute additional install steps.
COPY python-requirements.txt /tmp/python-requirements.txt
RUN pip3 install -r /tmp/python-requirements.txt

# Get the precompiled toolchain
RUN wget https://static.dev.sifive.com/dev-tools/riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz
RUN mkdir -p riscv && tar -x -f riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz --strip-components=1 -C riscv
RUN rm -rf riscv64-unknown-elf-gcc-${RISCV_GCC_VERSION}-x86_64-linux-ubuntu14.tar.gz
ENV PATH "/tools/riscv/bin:${PATH}"

# Install Verible
RUN wget https://github.com/google/verible/releases/download/master/verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz
RUN tar -x -f verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz --strip-components=1 -C .
RUN rm -rf verible-v${VERIBLE_VERSION}-Ubuntu-18.04-bionic-x86_64.tar.gz
ENV PATH "/tools/bin:${PATH}"
