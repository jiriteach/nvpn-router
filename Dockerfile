# s6 overlay builder
FROM alpine:3.20.2 AS s6-builder

ENV PACKAGE="just-containers/s6-overlay"
ENV PACKAGEVERSION="3.2.0.0"
ARG TARGETPLATFORM

RUN echo "**** Install security fix packages ****" && \
    echo "**** Install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        tar=1.35-r2 \
        xz=5.6.1-r3 \
        && \
    echo "**** Create required folders ****" && \
    mkdir -p /s6 && \
    echo "**** Download ${PACKAGE} ****" && \
    PACKAGEPLATFORM=$(case ${TARGETPLATFORM} in \
        "linux/amd64")    echo "x86_64"   ;; \
        "linux/386")      echo "i486"     ;; \
        "linux/arm64")    echo "aarch64"  ;; \
        "linux/arm/v7")   echo "armhf"    ;; \
        "linux/arm/v6")   echo "arm"      ;; \
        *)                echo ""         ;; esac) && \
    echo "Package ${PACKAGE} platform ${PACKAGEPLATFORM} version ${PACKAGEVERSION}" && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-noarch.tar.xz" -qO /tmp/s6-overlay-noarch.tar.xz && \
    wget -q "https://github.com/${PACKAGE}/releases/download/v${PACKAGEVERSION}/s6-overlay-${PACKAGEPLATFORM}.tar.xz" -qO /tmp/s6-overlay-binaries.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C /s6/ -Jxpf /tmp/s6-overlay-binaries.tar.xz

# rootfs builder
FROM alpine:3.20.2 AS rootfs-builder

RUN echo "**** Install security fix packages ****" && \
    echo "**** End run statement ****"

COPY root/ /rootfs/
RUN chmod +x /rootfs/usr/bin/*
RUN chmod +x /rootfs/etc/nordvpn/init/*
COPY --from=s6-builder /s6/ /rootfs/

# Main image
FROM alpine:3.20.2

LABEL maintainer="Jithen Singh <jxs@s7n.dev>"

ENV TECHNOLOGY=openvpn_udp \
    RANDOM_TOP=0 \
    CHECK_CONNECTION_ATTEMPTS=5 \
    CHECK_CONNECTION_ATTEMPT_INTERVAL=10 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=120000

RUN echo "**** Install security fix packages ****" && \
    echo "**** Install mandatory packages ****" && \
    apk --no-cache --no-progress add \
        traceroute \
        dnsmasq \
        openrc \
        bash=5.2.26-r0 \
        curl=8.7.1-r0 \
        iptables=1.8.10-r3 \
        ip6tables=1.8.10-r3 \
        jq=1.7.1-r0 \
        shadow=4.15.1-r0 \
        shadow-login=4.15.1-r0 \
        openvpn=2.6.10-r0 \
        bind-tools=9.18.27-r0 \
        && \
    echo "**** Create process user ****" && \
    addgroup --system --gid 912 nordvpn && \
    adduser --system --uid 912 --disabled-password --no-create-home --ingroup nordvpn nordvpn && \
    echo "**** Cleanup ****" && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/*

COPY --from=rootfs-builder /rootfs/ /

 ENTRYPOINT ["/init"]
