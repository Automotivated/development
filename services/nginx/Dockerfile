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
    nginx && \

  # Clean-up
  apk del tzdata && \
  rm -rf /var/cache/apk/* && \
  rm -rf /var/lib/apt/lists/* && \

  ln -sf /dev/stdout /var/log/nginx/access.log && \
  ln -sf /dev/stderr /var/log/nginx/error.log

CMD ["nginx", "-g", "daemon off;"]
