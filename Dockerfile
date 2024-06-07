#/bin/sh
# postgresql 16
FROM debian:bookworm-slim

LABEL author="TheAFKGamer10" maintainer="mail@afkhosting.win"

USER root
RUN set -eux; \
    adduser -D -h /home/container container; \
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
  ; \
  rm -rf /var/lib/apt/lists/*


ENV PGDATA "/home/container/postgresql/data"
ENV PGFOLDER "/home/container/postgresql"

ENV GOSU_VERSION 1.17
RUN set -eux; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ca-certificates wget; \
	rm -rf /var/lib/apt/lists/*; \
	dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	apt-mark auto '.*' > /dev/null; \
	[ -z "$savedAptMark" ] || apt-mark manual $savedAptMark > /dev/null; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	chmod +x /usr/local/bin/gosu; \
	gosu --version; \
	gosu nobody true

RUN set -eux; \
	if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then \
		grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
		sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; \
		! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; \
	fi; \
	apt-get update; apt-get install -y --no-install-recommends locales; rm -rf /var/lib/apt/lists/*; \
	echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen; \
	locale-gen; \
	locale -a | grep 'en_US.utf8'
ENV LANG en_US.utf8

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libnss-wrapper \
		xz-utils \
		zstd \
	; \
	rm -rf /var/lib/apt/lists/*

RUN mkdir /docker-entrypoint-initdb.d

RUN set -ex; \
	key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; \
	export GNUPGHOME="$(mktemp -d)"; \
	mkdir -p /usr/local/share/keyrings/; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	gpg --batch --export --armor "$key" > /usr/local/share/keyrings/container.gpg.asc; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME"

ENV PG_MAJOR 16
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin

ENV PG_VERSION 16.3-1.pgdg120+1

RUN set -ex; \
	\
	export PYTHONDONTWRITEBYTECODE=1; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	aptRepo="[ signed-by=/usr/local/share/keyrings/container.gpg.asc ] http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main $PG_MAJOR"; \
	case "$dpkgArch" in \
		amd64 | arm64 | ppc64el | s390x) \
			echo "deb $aptRepo" > /etc/apt/sources.list.d/pgdg.list; \
			apt-get update; \
			;; \
		*) \
			echo "deb-src $aptRepo" > /etc/apt/sources.list.d/pgdg.list; \
			\
			savedAptMark="$(apt-mark showmanual)"; \
			\
			tempDir="$(mktemp -d)"; \
			cd "$tempDir"; \
			apt-get update; \
			apt-get install -y --no-install-recommends dpkg-dev; \
			echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; \
			_update_repo() { \
				dpkg-scanpackages . > Packages; \				apt-get -o Acquire::GzipIndexes=false update; \
			}; \
			_update_repo; \
			nproc="$(nproc)"; \
			export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"; \
			apt-get build-dep -y postgresql-common pgdg-keyring; \
			apt-get source --compile postgresql-common pgdg-keyring; \
			_update_repo; \
			apt-get build-dep -y "postgresql-$PG_MAJOR=$PG_VERSION"; \
			apt-get source --compile "postgresql-$PG_MAJOR=$PG_VERSION"; \
			apt-mark showmanual | xargs apt-mark auto > /dev/null; \
			apt-mark manual $savedAptMark; \
			\
			ls -lAFh; \
			_update_repo; \
			grep '^Package: ' Packages; \
			cd /; \
			;; \
	esac; \
	\
	apt-get install -y --no-install-recommends postgresql-common; \
	sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf; \
	apt-get install -y --no-install-recommends \
		"postgresql-$PG_MAJOR=$PG_VERSION" \
	; \
	\
	rm -rf /var/lib/apt/lists/*; \
	\
	if [ -n "$tempDir" ]; then \
		apt-get purge -y --auto-remove; \
		rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
	fi; \
  find /usr -name '*.pyc' -type f -exec bash -c 'for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done' -- '{}' +; \
	\
	postgres --version

RUN set -eux; \
	dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
	ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

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

ENV NODE_VERSION 18.20.3

RUN apt update && apt install -y curl gnupg2 dirmngr xz-utils && rm -rf /var/lib/apt/lists/* \
  && ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && export GNUPGHOME="$(mktemp -d)" \
  && set -ex \
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
    if [ "$key" = "CC68F5A3106FF448322E48ED27F5E38D5B0A215F" ]; then \
      # because the keyserver is unreliable, we use the web key directory instead
      curl -sSL https://keys.openpgp.org/vks/v1/by-fingerprint/CC68F5A3106FF448322E48ED27F5E38D5B0A215F | gpg --batch --import - ; \
    else \
      gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
    fi \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && gpgconf --kill all \
  && rm -rf "$GNUPGHOME" \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs \
  # smoke tests
  && node --version \
  && npm --version


# Install pnpm
RUN         npm install npm typescript ts-node @types/node --location=global
RUN         npm install pnpm --location=global

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
RUN ln -sT docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh
STOPSIGNAL SIGINT
RUN chown -R container:root /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh /usr/local/bin/docker-ensure-initdb.sh /usr/local/bin/docker-enforce-initdb.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-D", "/home/container/postgresql/data", "-c", "config_file=/home/container/postgresql/postgresql.conf"]
RUN chmod 00700 "$PGDATA" && \
    chmod 700 "/home/container/postgresql/service"


USER container