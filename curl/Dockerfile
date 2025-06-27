FROM alpine:latest

RUN apk add --no-cache \
    curl \
    ca-certificates \
    jq \
    && rm -rf /var/cache/apk/*

WORKDIR /app

COPY test-apis.sh /app/

RUN chmod +x /app/test-apis.sh

ENTRYPOINT ["/app/test-apis.sh"]