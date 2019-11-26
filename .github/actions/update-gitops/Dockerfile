FROM ubuntu:18.04

RUN apt-get install -y --no-cache curl ca-certificates

COPY README.md /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
