FROM alpine/git:2.52.0@sha256:b4ba5e95ee803a9f98fe9f4306e0105f679d2386dedaf207ffe62dd20fdd3f1c
LABEL maintainer="honeok <i@honeok.com>"
RUN set -ex \
    && apk add --no-cache --update bash
COPY --chmod=755 *.sh /
ENTRYPOINT ["/entrypoint.sh"]
