ARG BASE_IMAGE=quay.io/jupyter/minimal-notebook:latest

FROM ${BASE_IMAGE}
LABEL org.opencontainers.image.source="https://github.com/jimwhite/acl2"
LABEL org.opencontainers.image.description="A Docker image for building the ACL2 theorem proving system and books in JupyterLab"
LABEL org.opencontainers.image.licenses=MIT

ARG SBCL_VERSION=2.5.11

ARG Z3_VERSION=4.15.4

ARG USER=jovyan
ENV HOME=/home/${USER}

USER root

# This will have RW permission for the ACL2 directory.
# `sudo` does not require a password.
RUN echo 'jovyan ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && adduser jovyan sudo \
    && groupadd acl2 \
    && usermod -aG acl2 ${USER} \
    && mkdir /opt/acl2 \
    && chown -R ${USER}:acl2 /opt/acl2 


# sbcl is needed to config sbcl build

# Based on https://github.com/wshito/roswell-base

# openssl-dev is needed for Quicklisp
# perl is needed for ACL2's certification scripts
# wget is needed for downloading some files while building the docker image
# The rest are needed for Roswell

# libczmq-dev because otherwise loading quicklisp in sbcl gets:
# quicklisp/software/pzmq-20210531-git/grovel__grovel.c:6:10: fatal error: zmq.h: No such file or directory
#    6 | #include <zmq.h>
# https://github.com/yitzchak/common-lisp-jupyter/blob/2df55291592943851d013c66af920e7c150b1de2/docs/install.md?plain=1#L18

# pipx is for poetry install for acl2-kernel

# nodejs and npm for Claude Code
# TODO: Switch to Deno.

# retry might be used to retry book certification makefiles that are flaky.

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential file \
        gcc \
        git git-lfs \
        automake \
        autoconf \
        make \
        libcurl4-openssl-dev \
        ca-certificates \
        libssl-dev \
        wget \
        perl \
        zlib1g-dev \
        libzstd-dev \
        libczmq-dev \
        curl \
        unzip \
        sbcl \
        rlwrap \
        retry

        # nodejs npm
        # pipx


# This /root/sbcl dir seems to be a tmp so why in /root?
RUN mkdir /root/sbcl \
    && cd /root/sbcl \
    && wget "https://github.com/sbcl/sbcl/archive/refs/tags/sbcl-${SBCL_VERSION}.tar.gz" -O sbcl.tar.gz -q \
    && tar -xzf sbcl.tar.gz \
    && cd sbcl-* \
    && sh make.sh --without-immobile-space --without-immobile-code --without-compact-instance-header --fancy --dynamic-space-size=4Gb \
    && apt-get remove -y sbcl \
    && sh install.sh \
    && cd /root \
    && rm -R /root/sbcl

# # Include Z3
# # Do we get everything with pip? pip install z3-solver
# RUN mkdir /root/z3 \
#     && cd /root/z3 \
#     && wget "https://github.com/Z3Prover/z3/archive/refs/tags/z3-${Z3_VERSION}.tar.gz" -O z3.tar.gz -q \
#     && tar -xzf z3.tar.gz --strip-components=1 \
#     && ./configure \
#     && cd build \
#     && make -j$(nproc) \
#     && make install \
#     && cd /root \
#     && rm -R /root/z3

# COPY archlinux-cl/asdf-add /usr/local/bin/asdf-add
# COPY archlinux-cl/make-rc /usr/local/bin/make-rc
# COPY archlinux-cl/lisp /usr/local/bin/lisp

ENV LISP="sbcl"

ARG ACL2_BUILD_OPTS=""
ARG ACL2_CERTIFY_OPTS="-j 6"
ARG ACL2_CERTIFY_TARGETS="basic"
# The ACL2 Bridge and such for Jupyter need everything.
# ARG ACL2_CERTIFY_TARGETS="all acl2s centaur/bridge"
ENV CERT_PL_RM_OUTFILES="1"

RUN chown -R ${USER}:users ${HOME}

USER ${USER}
