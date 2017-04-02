# Use Alpine Linux Edge
FROM alpine:edge

# Maintainer
MAINTAINER Ferry Kobus <ferry@automotivated.nl>

# Environments
ENV TIMEZONE Europe/Amsterdam

RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
	apk update && \
	apk upgrade && \
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
	echo "${TIMEZONE}" > /etc/timezone && \
	apk add --update \
		libxml2 \
		git \
		curl \
		unzip \
		bash \
		bash-doc \
		bash-completion \
		php7-phar \
		php7-curl \
		php7-xml \
		php7-dom \
		php7-iconv \
		php7-json \
		php7-openssl \
		php7-mcrypt \
		php7-zip \
		php7-pdo_mysql \
		php7-mysqli \
		php7-mbstring \
		php7-ctype \
		php7-posix \
		php7-intl \
		php7-fpm \
		php7-session \
		php7-opcache \
		php7-xmlwriter \
		php7 && \

	# Clean-up
	apk del tzdata && \
	rm -rf /var/cache/apk/* /var/lib/apt/lists/* && \

	# Fixes for docker
	sed -i -e "s|;daemonize\s*=.*|daemonize = no|" \
		/etc/php7/php-fpm.conf && \
  sed -i -e "s|listen\s*=.*|listen = 9999|" \
    /etc/php7/php-fpm.d/www.conf && \

  # Install Composer globally
  curl -L -o /usr/local/bin/composer https://getcomposer.org/composer.phar && \
  chmod +x /usr/local/bin/composer

EXPOSE 9999

CMD ["/usr/sbin/php-fpm7"]
