ARG COMMIT_SHA=""

# Builder stage
FROM --platform=$BUILDPLATFORM node:alpine AS builder
WORKDIR /app

RUN npm i -g pnpm
COPY pnpm-lock.yaml package.json ./
COPY ./patches/ ./patches/
RUN pnpm i

COPY . .
RUN pnpm build \
  # remove source maps - people like small image
  && rm public/*.map || true

# Nginx stage
# FROM --platform=$TARGETPLATFORM alpine AS nginx
# the brotli module is only in the alpine *edge* repo
RUN apk add --no-cache \
  nginx \
  nginx-mod-http-brotli \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community

COPY docker/nginx-default.conf /etc/nginx/conf.d/default.conf
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/public /usr/share/nginx/html
ENV YACD_DEFAULT_BACKEND "http://127.0.0.1:9090"

# Clash stage
FROM --platform=$TARGETPLATFORM dreamacro/clash:dev AS clash

ADD docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh
CMD ["/docker-entrypoint.sh"]