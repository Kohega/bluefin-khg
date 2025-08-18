FROM scratch AS ctx
COPY build_files /

# Bluefin base
FROM ghcr.io/ublue-os/bluefin:stable
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
COPY system_files /
    ostree container commit

RUN bootc container lint