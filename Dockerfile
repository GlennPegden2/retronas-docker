FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV TERM=xterm-256color
ENV RETRONAS_ROOT=/opt/retronas

RUN apt-get update && apt-get install -y --no-install-recommends \
    ansible \
    dialog \
    git \
    iproute2 \
    jq \
    less \
    lynx \
    pandoc \
    sudo \
    tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/retronas
COPY . /opt/retronas

RUN chmod +x /opt/retronas/retronas.sh \
    /opt/retronas/install_retronas.sh \
    /opt/retronas/docker-entrypoint.sh \
    && find /opt/retronas -type f -name "*.sh" -exec sed -i 's/\r$//' {} + \
    && find /opt/retronas/dialog /opt/retronas/lib /opt/retronas/scripts -type f -name "*.sh" -exec chmod +x {} \; \
    && cp /opt/retronas/dist/retronas /usr/local/bin/retronas \
    && chmod 0755 /usr/local/bin/retronas

# Create retronas user and group
RUN groupadd --system retronas \
    && useradd --system --create-home --gid retronas retronas

VOLUME ["/data/retronas", "/opt/retronas/etc", "/opt/retronas/log", "/opt/retronas/cache"]

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/retronas/docker-entrypoint.sh"]
CMD ["/opt/retronas/retronas.sh", "-g"]