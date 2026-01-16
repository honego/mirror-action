FROM alpine:3.23.2@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62
LABEL maintainer="honeok <i@honeok.com>"
RUN set -ex \
    && apk add --no-cache --update bash git
COPY --chmod=755 *.sh /
ENTRYPOINT ["/entrypoint.sh"]
