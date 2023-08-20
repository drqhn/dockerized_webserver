#!/bin/bash

##############################################################################################
# App to be started in the container
# - Requires ${DOMAINS} to be set, which must contain one or more comma separated domains
#   (without whitespace), e.g. DOMAINS=drstefankuhn.de,www.drstefankuhn.de,smrtptr.com
# - Retrieves SSL certificates for all ${DOMAINS} using certbot (https://letsencrypt.org/) and
#   renews these every 30 days
# - Configures nginx web server for all ${DOMAINS} that also anynomizes IPs in the logs; and
#   starts the nginx web server in non-daemon mode.
##############################################################################################

# Immediately exit script on error and treat unset variables as error

set -e -u
echo "Starting web server for ${DOMAINS} with SSL certificates and anonymized logs"


###### SSL Certificates ######################################################################

# Create and start script '/certbot.sh' in background for initializing and renewing the SSL
# certificates for all ${DOMAINS} after nginx web server has started.

CERTBOT_DOMAINS=$(echo ${DOMAINS} | awk -v RS=, -v ORS=" " '{print "-d " $0}' | sed 's/ $//')

cat >/certbot.sh <<EOL
#!/bin/bash
until pidof nginx > /dev/null; do sleep 1; done
sleep 5
certbot -n ${CERTBOT_DOMAINS} --nginx --register-unsafely-without-email --agree-tos --redirect
while pidof nginx > /dev/null; do sleep 30d && /usr/bin/certbot renew --quiet; done
EOL

chmod 755 /certbot.sh
/certbot.sh &


###### Web Server ############################################################################

# Configure nginx web server to anonymize IPs by replacing the last octet by 0

cat >/etc/nginx/conf.d/anonymized_logging.conf <<EOL
map \$remote_addr \$remote_addr_anonymized {
    ~(?P<ip>\\d+\\.\\d+\\.\\d+)\\. \$ip.0;
    ~(?P<ip>[^:]+:[^:]+):      \$ip::;
    127.0.0.1                  \$remote_addr;
    ::1                        \$remote_addr;
    default                    0.0.0.0;
}
log_format anonymized '\$remote_addr_anonymized - \$remote_user [\$time_local] "" '
                      '"\$request" \$status \$body_bytes_sent '
                      '"\$http_referer" "\$http_user_agent" "\$http_x_forwarded_for"';
access_log off;
error_log off;
EOL

# Create nginx web server entry for all ${DOMAINS}

SERVER_DOMAINS=$(echo ${DOMAINS} | awk -v RS=, -v ORS=" " '{print " " $0}' | sed 's/ $//')

cat >/etc/nginx/sites-available/site <<EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/site;
    server_name ${SERVER_DOMAINS};
    index index.html index.htm;
    location / {
        try_files \$uri \$uri/ =404;
    }
    access_log /var/log/nginx/access.log anonymized;
    error_log /var/log/nginx/error.log;
}
EOL

# Enable only the new nginx web server entry and start nginx in non-daemon mode

rm /etc/nginx/sites-enabled/*
ln -s /etc/nginx/sites-available/site /etc/nginx/sites-enabled/site
nginx -g 'daemon off;'
