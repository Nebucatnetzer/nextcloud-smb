FROM nextcloud:25.0.4-apache@sha256:d843e067c42af1baf7780af1da56f79e3537d5476429b2ae1dd38092d10099db

RUN set -ex; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libmagickcore-6.q16-6-extra \
    procps \
    smbclient \
    supervisor \
    #       libreoffice \
    ; \
    rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    \
    savedAptMark="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    libbz2-dev \
    libc-client-dev \
    libkrb5-dev \
    libsmbclient-dev \
    ; \
    \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install \
    bz2 \
    imap \
    ; \
    pecl install smbclient; \
    docker-php-ext-enable smbclient; \
    \
    # reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p \
    /var/log/supervisord \
    /var/run/supervisord \
    ;

COPY supervisord.conf /

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
