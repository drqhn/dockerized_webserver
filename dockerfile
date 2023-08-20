FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    nginx-light \
    certbot \
    python3-certbot-nginx \
 && rm -rf /var/lib/apt/lists/*

COPY app.sh /app.sh
RUN chmod 755 /app.sh

EXPOSE 80 443

ENTRYPOINT /app.sh
