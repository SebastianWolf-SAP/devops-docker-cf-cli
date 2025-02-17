FROM buildpack-deps:stretch-curl

ENV VERSION 0.1

# https://github.com/hadolint/hadolint/wiki/DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ps needs to be available to be able to be used in docker.inside, see https://issues.jenkins-ci.org/browse/JENKINS-40101
RUN apt-get update && \
    apt-get install -y --no-install-recommends procps && \
    rm -rf /var/lib/apt/lists/*

# add group & user
ARG USER_HOME=/home/piper
RUN addgroup -gid 1000 piper && \
    useradd piper --uid 1000 --gid 1000 --shell /bin/bash --home-dir "${USER_HOME}" --create-home && \
    curl --location --silent "https://packages.cloudfoundry.org/stable?release=linux64-binary&version=v7&source=github" | tar -zx -C /usr/local/bin && \
    cf --version

USER piper
WORKDIR ${USER_HOME}

ARG MTA_PLUGIN_VERSION=2.6.3
ARG MTA_PLUGIN_URL=https://github.com/cloudfoundry-incubator/multiapps-cli-plugin/releases/download/v${MTA_PLUGIN_VERSION}/mta_plugin_linux_amd64
ARG CSPUSH_PLUGIN_VERSION=1.3.2
ARG CSPUSH_PLUGIN_URL=https://github.com/dawu415/CF-CLI-Create-Service-Push-Plugin/releases/download/${CSPUSH_PLUGIN_VERSION}/CreateServicePushPlugin.linux64

RUN cf add-plugin-repo CF-Community https://plugins.cloudfoundry.org && \
    cf install-plugin blue-green-deploy -f -r CF-Community && \
    cf install-plugin ${MTA_PLUGIN_URL} -f && \
    cf install-plugin ${CSPUSH_PLUGIN_URL} -f && \
    cf plugins

# allow anybody to read/write/exec at HOME
RUN chmod -R o+rwx "${USER_HOME}"
ENV HOME=${USER_HOME}
