FROM alpine:3.10

RUN apk add --no-cache curl ca-certificates

COPY README.md /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
