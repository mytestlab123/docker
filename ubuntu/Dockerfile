FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY welcome.sh /app/

RUN chmod +x /app/welcome.sh

CMD ["/app/welcome.sh"]