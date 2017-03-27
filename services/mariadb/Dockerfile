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
		mariadb \
		mariadb-client \
		pwgen

ADD scripts/run.sh /scripts/run.sh
RUN mkdir /scripts/pre-exec.d && \
    mkdir /scripts/pre-init.d && \
    chmod -R 755 /scripts

EXPOSE 3306

ENTRYPOINT ["/scripts/run.sh"]
