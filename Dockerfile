FROM debian:12

ARG bedrock_version
ARG java_version

# hostuid is needed to make sure the created image has a user with the same
# UID/GID as the host, so that mounts will work without permission errors. This
# is usually not needed, but sometimes your host UID might be e.g. 1001 when the
# image's UID will be 1000
ARG hostuid
ENV hostuid="${hostuid}"

RUN useradd --create-home --uid "${hostuid}" minecraft

# /tmp/* to match what the other available platforms use
COPY ./scripts/init.sh /tmp/scripts/init.sh
COPY ./server-cfg /tmp/server-cfg

RUN /tmp/scripts/init.sh bedrock "${bedrock_version}" docker
RUN /tmp/scripts/init.sh java "${java_version}" docker

COPY ./mods /tmp/mods
COPY ./scripts/init-mods-docker.sh /tmp/init-mods-docker.sh
RUN chown -R minecraft:minecraft /tmp/mods

USER minecraft
ENV SHELL="/usr/bin/env bash"
WORKDIR /home/minecraft

COPY ./scripts/docker-entrypoint.sh /home/minecraft/docker-entrypoint.sh

ENTRYPOINT ["/home/minecraft/docker-entrypoint.sh"]
