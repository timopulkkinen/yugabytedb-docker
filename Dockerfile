FROM centos:8 AS builder

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
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
RUN git checkout cd3c1a4

RUN cd ./src/postgres/contrib; git clone https://github.com/EnterpriseDB/pldebugger.git; sed -i 's/\$(recurse)/SUBDIRS += pldebugger\n&/' Makefile

ENV YB_COMPILER_TYPE=clang11
RUN ./yb_build.sh release

RUN ./yb_release --force

FROM centos:8

RUN cd /etc/yum.repos.d/
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*
RUN dnf -y update
RUN dnf install -y wget git python39 python39-pip curl chrony libatomic procps \
    && dnf clean all

COPY --from=builder /yugabyte-db/build/yugabyte*.gz /
RUN cd / && tar xvzf yugabyte*.tar.gz --one-top-level=yugabyte --strip-components 1 && rm -f yugabyte*.tar.gz
RUN alternatives --set python /usr/bin/python3
ENV container=yugabyte-db
ENV YB_HOME=/yugabyte
WORKDIR /yugabyte

RUN ./bin/post_install.sh

EXPOSE 5433
EXPOSE 7000

VOLUME /mnt/data

CMD ["/bin/bash", "-c", "/yugabyte/bin/yugabyted start --daemon=false --ui=false --base_dir=/mnt/data --initial_scripts_dir=/init-scripts --tserver_flags=ysql_pg_conf=\"shared_preload_libraries='/yugabyte/postgres/lib/plugin_debugger.so'\""]




