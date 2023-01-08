FROM debian:11

ARG edition_arg
ARG version_arg

ENV edition="${edition_arg}"
ENV platform=docker

RUN useradd --create-home minecraft

# /tmp/* to match what the other available platforms use
COPY scripts /tmp/scripts
COPY server-cfg /tmp/server-cfg

RUN /tmp/scripts/init.sh "${edition_arg}" "${version_arg}" "${platform}"

USER minecraft
ENV SHELL="/usr/bin/env bash"
WORKDIR /home/minecraft

COPY docker-entrypoint.sh /home/minecraft/docker-entrypoint.sh

CMD ["sh", "-c", "bash /home/minecraft/docker-entrypoint.sh ${edition}"]
