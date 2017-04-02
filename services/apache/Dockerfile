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
		apache2-proxy && \

	# Clean-up
	apk del tzdata && \
	rm -rf /var/cache/apk/* && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p /run/apache2 && \
	mkdir -p /etc/apache2/vhosts.d && \

	# Fix loaded modules
	sed -i -e "s/^LoadModule mpm_prefork_module/#LoadModule mpm_prefork_module/" \
		/etc/apache2/httpd.conf && \
	sed -i -e "s/^#LoadModule mpm_event_module/LoadModule mpm_event_module/" \
		/etc/apache2/httpd.conf && \
	sed -i -e "s/^#LoadModule slotmem_shm_module/LoadModule slotmem_shm_module/" \
		/etc/apache2/httpd.conf && \
	sed -i -e "s/^#LoadModule rewrite_module/LoadModule rewrite_module/" \
		/etc/apache2/httpd.conf && \
	sed -i -e "s/^#ServerName www.example.com:80/ServerName example.local/" \
		/etc/apache2/httpd.conf && \

	# Include our custom vhosts folder
	echo "IncludeOptional /etc/apache2/vhosts.d/*.conf" >> /etc/apache2/httpd.conf && \

	ln -sf /dev/stdout /var/log/apache2/access.log && \
	ln -sf /dev/stderr /var/log/apache2/error.log

EXPOSE 80

CMD ["httpd", "-D", "FOREGROUND"]
