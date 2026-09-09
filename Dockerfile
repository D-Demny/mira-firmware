FROM ghcr.io/void-linux/void-glibc:20250801R1
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Use the official default repository (repo-default.voidlinux.org) shipped with
# the base image — mirrors.servercentral.com was intermittently unreachable
# ("Operation not permitted") and broke `xbps-install` in CI.

RUN xbps-install -Suy xbps

# acl is listed explicitly: base image is a frozen snapshot, and -uy only upgrades the
# packages named here — rsync >= 3.5 needs ACL_1.3 which the snapshot's libacl lacks.
RUN xbps-install -uy acl bash curl dosfstools e2fsprogs findutils util-linux gzip \
    git m4 mtools pigz tar zstd xz zip mkpasswd zip unzip just rsync \
    autoconf automake libtool pkg-config make gcc confuse-devel openssl patchelf

RUN curl -L https://github.com/pengutronix/genimage/archive/refs/tags/v18.tar.gz | tar --use-compress-program=pigz -x -C /tmp \
    && cd /tmp/genimage-18 \
    && ./autogen.sh \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && cd / \
    && rm -rf /tmp/genimage-18

COPY resources/ /work/resources/
COPY scripts/ /work/scripts/
COPY docker-entrypoint.sh build.sh /work/
COPY go-librespot-armv6 ui.zip go-librespot-config.yml lp.env iap2-sidecar-armv7 setup-pi.sh setup-tethering.sh /work/
COPY voice-artifacts/ /work/voice-artifacts/

WORKDIR /work

CMD ["/bin/bash", "/work/docker-entrypoint.sh"]
