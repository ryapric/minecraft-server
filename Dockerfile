FROM debian:11

ARG bedrock_version
ARG java_version

RUN useradd --create-home minecraft

# /tmp/* to match what the other available platforms use
COPY ./scripts/init.sh /tmp/scripts/init.sh
COPY ./server-cfg /tmp/server-cfg

RUN /tmp/scripts/init.sh bedrock "${bedrock_version}" docker
RUN /tmp/scripts/init.sh java "${java_version}" docker

USER minecraft
ENV SHELL="/usr/bin/env bash"
WORKDIR /home/minecraft

COPY ./scripts/docker-entrypoint.sh /home/minecraft/docker-entrypoint.sh

ENV edition=""

CMD ["sh", "-c", "bash /home/minecraft/docker-entrypoint.sh ${edition}"]
