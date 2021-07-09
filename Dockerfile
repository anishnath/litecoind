FROM debian:buster-20210621-slim

LABEL maintainer "Anish Nath" \
      org.label-schema.vcs-description="litecoind secure docker image" \
      org.label-schema.docker.cmd="docker run -p 9333:9333 anishnath/litecoind" \
      image-size="181 MB"

ARG LITECOIN_VERSION=0.18.1
ARG LITECOIN_GPGKEY=FE3348877809386C

RUN set -eux && \
    addgroup --system --gid 101 litecoin && \
    adduser --system  --ingroup litecoin --no-create-home --home /nonexistent --gecos "litecoin user" --shell /bin/false --uid 101 litecoin && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates \
        supervisor \
        wget \
        gpg \
        gpg-agent \
        dirmngr && \
    \
    found=''; \
    gpg_key_server=''; \
    for server in \
        hkp://keyserver.ubuntu.com:80 \
        pgp.mit.edu \
        ha.pool.sks-keyservers.net \
        hkp://p80.pool.sks-keyservers.net:80 \
    ; do \
        echo "Fetching GPG key $LITECOIN_GPGKEY from $server"; \
        gpg_key_server=$server; \
        apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$LITECOIN_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $LITECOIN_GPGKEY" && exit 1; \
    wget https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz.asc && \
    wget https://download.litecoin.org/litecoin-${LITECOIN_VERSION}/linux/litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz && \
    gpg --keyserver $gpg_key_server --recv-key $LITECOIN_GPGKEY && \
    gpg --verify litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz.asc && \
    tar xfz /litecoin-${LITECOIN_VERSION}-x86_64-linux-gnu.tar.gz && \
    mv litecoin-${LITECOIN_VERSION}/bin/* /usr/local/bin/ && \
    rm -rf litecoin-* /root/.gnupg/ && \
    apt-get remove --purge -y \
        ca-certificates \
        wget \
        gpg \
        gpg-agent \
        dirmngr && \
    apt-get autoremove --purge -y && \
    rm -r /var/lib/apt/lists/* && \
    /usr/local/bin/litecoind --version && \
    mkdir /litecoin-data && chown litecoin:litecoin /litecoin-data && \
    mkdir /litecoin-conf && chown litecoin:litecoin /litecoin-conf && \
    mkdir /var/run/litecoin && chown litecoin:litecoin /var/run/litecoin && \
    chown litecoin:litecoin /var/log/supervisor && \
    chown -R litecoin:litecoin /etc/supervisor

COPY --chown=litecoin:litecoin supervisord/supervisord.conf /etc/supervisor/supervisord.conf
COPY --chown=litecoin:litecoin supervisord/conf.d/litecoin.conf /etc/supervisor/conf.d/litecoin.conf
COPY litecoin.sh /usr/local/bin/

VOLUME ["/litecoin-data","/litecoin-conf"]

EXPOSE 9333 9332

USER litecoin

HEALTHCHECK --interval=5s --timeout=3s CMD litecoin-cli -conf=/litecoin-conf/litecoin.conf  -getinfo || exit 1

STOPSIGNAL SIGTERM

CMD ["/usr/bin/supervisord","-n"]
