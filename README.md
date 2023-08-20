# Dockerized Nginx web server with Let's Encrypt SSL certificates and anonymized log files

* Based on ubuntu:latest image, nginx-light and certbot.
* Can be configured by setting some environment variables in the `webserver.conf` file.
* IPs in the log files are anonymized by replacing the last octet with 0.

## Usage

### Prerequisites

* At least one domain is required that points to your server IP in order to apply SSL certificates.

### Configuration

* Edit `webserver.conf` and ensure `.env` links to it. (Otherwise, create a link: `ln -s webserver.conf .env`).

### Start webserver

```bash
docker compose up -d
```

* Builds the web server docker image.
* Uses `.env` (which points to `webserver.conf`).
* Starts the nginx web server for all configured domains.
* Retrieves SSL certificates for all configured domains and renews those every 30 days.
* Delivers the web site files from the configured document root on the host for all configured domains at the configured ports.
* Anonymizes IPs in the log files.

You might want to have a look at the _docker_ logs if everything went fine: `docker compose logs`. (Note: Retrieving the SSL certificates can take some time).

### Stop webserver

```bash
docker compose down -v
```

* Stops the container that runs the nginx web server.

## Discussion

* The renewal of the SSL certificates is achieved by a script running in the background - most of the time sleeping. Maybe using mcuadros/ofelia might be a cleaner and more docker-like solution.

## License

* See [LICENSE](LICENSE)

## References

* Docker [https://docs.docker.com/](https://docs.docker.com/)
* Ubuntu (Docker) [https://hub.docker.com/_/ubuntu](https://hub.docker.com/_/ubuntu)
* Nginx [https://docs.nginx.com/](https://docs.nginx.com/)
* Let's Encrypt [https://letsencrypt.org/](https://letsencrypt.org/)
