FROM alpine

MAINTAINER Aleksandr Chazov <develop@chazer.ru>

ENV TORAN_VERSION=v1.1.7
ENV TORAN_HOME=/var/www/toran


# Install
RUN /sbin/apk update \
 && /sbin/apk add supervisor nginx \
 && /sbin/apk add curl git openssh-client \
 && /sbin/apk add php-fpm php-ctype php-dom php-json php-openssl php-phar \
#
# Add web user
 && adduser -h /var/www -S -D www-data www-data \
#
# Install Toran-Proxy package
 && curl -sL https://toranproxy.com/releases/toran-proxy-$TORAN_VERSION.tgz | tar xzC /var/www \
#
# Clear cache
 && rm -rf /var/cache/apk/*


RUN cd $TORAN_HOME \
 && cp app/config/parameters.yml.dist app/config/parameters.yml \
#
# Patch configuraton file
 && sed -i 's/secret:.*$/secret: '$(cat /dev/urandom|tr -dc 'a-zA-Z0-9'|fold -w 32|head -n 1)'/' app/config/parameters.yml \
 && mkdir -p /tmp/composer-cache \
 && mkdir -p /tmp/toran-cache \
 && chown -R www-data:www-data /tmp/composer-cache \
 && chown -R www-data:www-data /tmp/toran-cache \
 && echo "    composer_cache_dir: /tmp/composer-cache" >> app/config/parameters.yml \
 && echo "    toran_cache_dir: /tmp/toran-cache" >> app/config/parameters.yml \
#
# First run dialog
 && echo "" | ./bin/cron -v \
#
# Fix permissions
 && chmod -R 777 app/toran app/cache app/logs web/repo app/bootstrap.php.cache \
 && chown -R www-data:www-data ~www-data \
 && chown -Rf www-data:www-data /var/lib/nginx


# Add external files
ADD etc /etc/
ADD crontabs /var/spool/cron/crontabs/
ADD user /var/www/
ADD bin/start.sh /start.sh


RUN cd ~www-data \
#
# Generate keys
 && [ -d .ssh ] || mkdir .ssh \
 && [ -d .ssh/known_hosts ] || touch .ssh/known_hosts \
 && ssh-keygen -b 2048 -t rsa -f .ssh/id_rsa -q -N '' \
#
# Fix permissions
 && chown -R www-data:www-data .ssh \
 && chmod 700 .ssh \
 && chmod 600 .ssh/id_rsa \
 && chmod 644 .ssh/id_rsa.pub \
 && chmod 644 .ssh/known_hosts \
#
# Add mount point for external keys
 && mkdir -p /data/keys \
 && mkdir -p /data/config


VOLUME ["/data/keys/", "/data/config/"]

EXPOSE 80

CMD ["/bin/sh", "/start.sh"]
