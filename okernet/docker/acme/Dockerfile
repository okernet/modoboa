FROM goacme/lego:latest

COPY okernet/docker/acme/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
