FROM almalinux:8 AS builder

RUN dnf -y update
RUN dnf install -y wget git
RUN dnf groupinstall -y 'Development Tools'
RUN dnf install -y ruby perl-Digest epel-release yum-utils python2-pip python3 python3-pip python3-devel
RUN dnf config-manager --set-enabled powertools
RUN dnf install -y \
      autoconf \
      bind-utils \
      bzip2 \
      bzip2-devel \
      ccache \
      chrpath \
      clang \
      cmake3 \
      curl \
      gcc \
      gcc-c++ \
      gdbm-devel \
      glibc-all-langpacks \
      java-1.8.0-openjdk \
      java-1.8.0-openjdk-devel \
      langpacks-en \
      less \
      libatomic \
      libffi-devel \
      libsqlite3x-devel \
      libtool \
      langpacks-en \
      glibc-all-langpacks \
      maven \
      ninja-build \
      openssl-devel \
      patch \
      patchelf \
      perl-Digest \
      php \
      php-common \
      php-curl \
      readline-devel  \
      rsync \
      ruby \
      ruby-devel \
      sudo \
      vim \
      xz \
      libselinux \
      libselinux-devel \
      llvm-toolset \
      python38 \
      python38-devel \
      python38-pip \
      python38-psutil \
      glibc-locale-source \
      glibc-langpack-en \
      golang

RUN ln -s /usr/bin/cmake3 /usr/local/bin/cmake && ln -s /usr/bin/ctest3 /usr/local/bin/ctest


RUN git clone https://github.com/yugabyte/yugabyte-db.git
WORKDIR yugabyte-db

ENV YB_COMPILER_TYPE=clang12
RUN ./yb_build.sh release

RUN ./yb_release

FROM almalinux:8

RUN dnf -y update
RUN dnf install -y wget git python38 python38-pip curl chrony libatomic procps \
    && dnf clean all

COPY --from=builder /yugabyte-db/build/yugabyte*.gz /home
RUN cd /home && tar xvzf yugabyte*.tar.gz --one-top-level=yugabyte --strip-components 1 && rm -f yugabyte*.tar.gz
RUN ln -s /usr/bin/python3 /usr/bin/python
ENV container=yugabyte-db
ENV YB_HOME=/home/yugabyte
WORKDIR /home/yugabyte
ENV BOTO_PATH=/home/yugabyte/.boto/config
ENV AZCOPY_JOB_PLAN_LOCATION=/tmp/azcopy/jobs-plan
ENV AZCOPY_LOG_LOCATION=/tmp/azcopy/logs
ENV TINI_VERSION="v0.19.0"

RUN ./bin/post_install.sh

EXPOSE 10100 11000 12000
VOLUME /mnt/disk0 /mnt/disk1
ENTRYPOINT "/sbin/tini" "--"




