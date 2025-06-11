# At time of writing, Bookworm is the stable Debian release. The testing
# release, Trixie, is used to gain access to the `guile-commonmark` apt
# package.
FROM debian:trixie-20250610-slim

RUN DEBIAN_FRONTEND=noninteractive apt-get update --yes \
    && DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
        autoconf \
        ca-certificates \
        curl \
        gcc \
        guile-3.0 \
        guile-3.0-dev \
        guile-commonmark \
        make \
        pkg-config \
        tar \
    && rm -fr /var/lib/apt/lists/*

RUN update-ca-certificates

# Modify this in case the default UID/GIDs cause permission problems when
# working inside bind-mounted volumes.
ARG USER_UID_GID=1000

RUN groupadd -g "$USER_UID_GID" user \
    && useradd --create-home --uid "$USER_UID_GID" --gid "$USER_UID_GID" user
USER user

RUN mkdir -p ~/workspace
WORKDIR /home/user/workspace

RUN curl -LSfsO https://files.dthompson.us/releases/haunt/haunt-0.3.0.tar.gz
RUN tar xf haunt-0.3.0.tar.gz
WORKDIR /home/user/workspace/haunt-0.3.0
RUN ./configure
RUN make

USER root
WORKDIR /home/user/workspace/haunt-0.3.0
RUN make install
USER user
WORKDIR /home/user/workspace
RUN rm -fr /home/user/workspace/haunt-0.3.0

# Mount the Haunt site at this directory to build it.
VOLUME /home/user/workspace

ENTRYPOINT ["haunt"]
CMD ["build"]

