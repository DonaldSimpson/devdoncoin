### This is taken from here:
### https://github.com/uphold/docker-litecoin-core/blob/master/0.17/Dockerfile
### with a few changes as noted below to make it simpler and meet the requirements

### There's an automated build on Dockerhub here:
### https://hub.docker.com/r/donaldsimpson/doncoin
### that pulls this file on change and publishes "donaldsimpson/doncoin" to Dockerhub

FROM debian:stable-slim

### LABEL and maintainer removed

### add a non-root user, update and install packages and add keys
RUN useradd -r litecoin \
  && apt-get update -y \
  && apt-get install -y curl gnupg \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && set -ex \
  && for key in \
    B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    FE3348877809386C \
  ; do \
    gpg --no-tty --keyserver pgp.mit.edu --recv-keys "$key" || \
    gpg --no-tty --keyserver keyserver.pgp.com --recv-keys "$key" || \
    gpg --no-tty --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --no-tty --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done

### ENV statements colated, gosu removed
ENV LITECOIN_VERSION=0.17.1
ENV LITECOIN_DATA=/home/litecoin/.litecoin

### RUN commands combined with user & data dir setup
### I would consider using a trusted in-house source, e.g. artifactory or nexus for these files
RUN curl -O https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz \
  && curl https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-linux-signatures.asc | gpg --verify - \
  && tar --strip=2 -xzf *.tar.gz -C /usr/local/bin \
  && rm *.tar.gz \
  && mkdir -p "$LITECOIN_DATA" \
  && chmod 770 "$LITECOIN_DATA" \
  && chown -R litecoin "$LITECOIN_DATA"

VOLUME ["/home/litecoin/.litecoin"]

EXPOSE 9332 9333 19332 19333 19444


### switch user to litecoin
USER litecoin

### entrypoint.sh deleted and replaced with:
ENTRYPOINT ["litecoind"]
### to output directly to the console
