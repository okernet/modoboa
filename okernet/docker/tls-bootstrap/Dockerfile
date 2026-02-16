FROM alpine:3.20

RUN apk add --no-cache openssl

COPY okernet/docker/tls-bootstrap/bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

ENTRYPOINT ["/bootstrap.sh"]
