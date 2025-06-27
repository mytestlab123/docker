FROM alpine:latest

RUN apk add --no-cache \
    curl \
    wget \
    bash \
    jq \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY entrypoint.sh /app/

RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]