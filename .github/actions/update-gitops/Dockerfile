FROM ubuntu:18.04

RUN apt-get update && apt-get install -y  curl ca-certificates jq

COPY README.md /

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
