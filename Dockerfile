ARG NODE_VERSION=18.10.0
FROM node:$NODE_VERSION as theia-builder
RUN apt-get -qq update && apt-get install -y libsecret-1-dev
WORKDIR /home/theia
ADD ./package.json ./package.json
ARG GITHUB_TOKEN
RUN yarn --pure-lockfile
RUN NODE_OPTIONS="--max_old_space_size=4096" yarn theia build && \
    yarn theia download:plugins && \
    yarn --production && \
    yarn autoclean --init && \
    echo *.ts >> .yarnclean && \
    echo *.ts.map >> .yarnclean && \
    echo *.spec.* >> .yarnclean && \
    yarn autoclean --force && \
    yarn cache clean

# ARG OCAML_VERSION=debian-11-ocaml-4.14
FROM ocaml/opam:debian-11-ocaml-4.14

USER opam

ARG NODE_VERSION=18
ENV NODE_VERSION $NODE_VERSION

RUN sudo apt-get update && \
    sudo apt-get install -y build-essential curl libsecret-1-0

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo bash
RUN sudo apt-get install -y nodejs
RUN sudo apt-get -y install git

ENV HOME /home/opam
# ENV OPAMROOT /home/opam/.opam
WORKDIR /home/theia
COPY --from=theia-builder /home/theia /home/theia

RUN curl -sL https://github.com/tarides/ocaml-platform-installer/releases/latest/download/installer.sh | bash

RUN ocaml-platform

# configure Theia
ENV SHELL=/bin/bash \
    THEIA_DEFAULT_PLUGINS=local-dir:/home/theia/plugins

EXPOSE 8080
ENTRYPOINT [ "node", "/home/theia/src-gen/backend/main.js", "/home/project", "--hostname=0.0.0.0", "--port=8080" ]
