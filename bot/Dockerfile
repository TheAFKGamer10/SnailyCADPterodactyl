#/bin/sh
# postgresql 16
FROM postgres:16.4

LABEL author="TheAFKGamer10" maintainer="mail+dockerimage@afkhosting.win"

USER root
RUN set -eux; \
    adduser -D -h /home/container container; \
    groupmod -g 998 $(getent group 999 | cut -d: -f1); \
    usermod -u 998 $(getent passwd 999 | cut -d: -f1); \
    groupadd -r container --gid=999; \
    useradd -r -g container --uid=999 --home-dir=/home/container/postgresql --shell=/bin/bash container; \
    mkdir -p /home/container/postgresql; \
    usermod -aG root container; \
    chown -R container:root /home/container/postgresql; \
    chmod -R 777 /home/container/postgresql


RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    gnupg \
    less \
    curl \
    ca-certificates \
    iproute2 \
    git \
    make \
    tar \
    xz-utils \
    build-essential \
    ; \
    rm -rf /var/lib/apt/lists/*


ENV PGDATA "/home/container/postgresql/data"
ENV PGFOLDER "/home/container/postgresql"

RUN mkdir -p "$PGDATA" && chown -R container:root "$PGFOLDER" && chmod 1777 "$PGDATA"
# VOLUME "$PGFOLDER"

# Create the new directory for the socket files
RUN mkdir -p /home/container/postgresql/service && \
    chown -R container:root /home/container/postgresql/service && \
    chmod 777 /home/container/postgresql/service


# Node.js and pnpm
USER root
RUN groupadd --gid 1000 node \
    && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 20.14.0

RUN ARCH= OPENSSL_ARCH= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64' OPENSSL_ARCH='linux-x86_64';; \
    ppc64el) ARCH='ppc64le' OPENSSL_ARCH='linux-ppc64le';; \
    s390x) ARCH='s390x' OPENSSL_ARCH='linux*-s390x';; \
    arm64) ARCH='arm64' OPENSSL_ARCH='linux-aarch64';; \
    armhf) ARCH='armv7l' OPENSSL_ARCH='linux-armv4';; \
    i386) ARCH='x86' OPENSSL_ARCH='linux-elf';; \
    *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && set -ex \
    # libatomic1 for arm
    && apt-get update && apt-get install -y ca-certificates curl wget gnupg dirmngr xz-utils libatomic1 --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    # use pre-existing gpg directory, see https://github.com/nodejs/docker-node/pull/1895#issuecomment-1550389150
    && export GNUPGHOME="$(mktemp -d)" \
    # gpg keys listed at https://github.com/nodejs/node#release-keys
    && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    141F07595B7B3FFE74309A937405533BE57C7D57 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    DD792F5973C6DE52C432CBDAC77ABFA00DDBF2B7 \
    61FC681DFB92A079F1685E77973F295594EC4689 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    890C08DB8579162FEE0DF9DB8BEAB4DFCF555EF4 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    A363A499291CBBC940DD62E41F10027AF002F8B0 \
    CC68F5A3106FF448322E48ED27F5E38D5B0A215F \
    ; do \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
    gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
    && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
    # Remove unused OpenSSL headers to save ~34MB. See this NodeJS issue: https://github.com/nodejs/node/issues/46451
    && find /usr/local/include/node/openssl/archs -mindepth 1 -maxdepth 1 ! -name "$OPENSSL_ARCH" -exec rm -rf {} \; \
    && apt-mark auto '.*' > /dev/null \
    && find /usr/local -type f -executable -exec ldd '{}' ';' \
    | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
    | sort -u \
    | xargs -r dpkg-query --search \
    | cut -d: -f1 \
    | sort -u \
    | xargs -r apt-mark manual \
    # && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
    # smoke tests
    && node --version \
    && npm --version


# Install Yarn
RUN curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn && \
    rm -rf /var/lib/apt/lists/*

ENV SHELL=/bin/bash

RUN mkdir -p /home/container/postgresql/service && \
    mkdir -p /home/container/postgresql/data && \
    chown -R container:root /home/container/postgresql && \
    chmod -R 0770 /home/container/postgresql 

    
# Final Commands
RUN chown -R container:root /home/container
RUN chmod -R 777 /home/container

COPY        --chown=container:root ./docker-entrypoint.sh /docker-entrypoint.sh
RUN         chmod +x /docker-entrypoint.sh
ENV HOME /home/container
WORKDIR /home/container
EXPOSE 5432

# Example step in Dockerfile
RUN mkdir -p /home/container/postgresql/service && chown -R container:root /home/container

COPY docker-entrypoint.sh docker-ensure-initdb.sh /usr/local/bin/
RUN rm -f /usr/local/bin/docker-enforce-initdb.sh && \
    ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh
STOPSIGNAL SIGINT
RUN chown -R container:root /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh && \
    chmod 777 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-D", "/home/container/postgresql/data", "-c", "config_file=/home/container/postgresql/postgresql.conf"]
RUN chmod 00700 "$PGDATA" && \
    chmod 700 "/home/container/postgresql/service"

USER container