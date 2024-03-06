ARG RELEASE=3.19
FROM alpine:${RELEASE}

LABEL maintainer="NGINX Docker Maintainers <docker-maint@nginx.com>"

# Define NGINX versions for NGINX Plus and NGINX Plus modules
# Uncomment this block and the versioned nginxPackages in the main RUN
# instruction to install a specific release
# ENV NGINX_VERSION      31
# ENV NGINX_PKG_RELEASE  2
# ENV NJS_VERSION        0.8.2
# ENV NJS_PKG_RELEASE    1
# ENV OTEL_VERSION       0.1.0
# ENV OTEL_PKG_RELEASE   2
# ENV PKG_RELEASE        1

# Download your NGINX license certificate and key from the F5 customer portal (https://account.f5.com) and copy to the build context
RUN --mount=type=secret,id=nginx-crt,dst=cert.pem \
    --mount=type=secret,id=nginx-key,dst=cert.key \
    set -x \
# Create nginx user/group first, to be consistent throughout Docker variants
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx \
# Install the latest release of NGINX Plus and/or NGINX Plus modules (written and maintained by F5)
# Uncomment any desired module packages to install the latest release or use the versioned package format to specify a release
# For an exhaustive list of supported modules and how to install them, see https://docs.nginx.com/nginx/admin-guide/dynamic-modules/dynamic-modules/
    && nginxPackages=" \
        nginx-plus \
        # nginx-plus=${NGINX_VERSION}-r${NGINX_PKG_RELEASE} \
        # nginx-plus-module-geoip \
        # nginx-plus-module-geoip=${NGINX_VERSION}-r${PKG_RELEASE} \
        # nginx-plus-module-image-filter \
        # nginx-plus-module-image-filter=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-plus-module-njs \
        # nginx-plus-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${NJS_PKG_RELEASE} \
        # nginx-plus-module-otel \
        # nginx-plus-module-otel=${NGINX_VERSION}.${OTEL_VERSION}-r${OTEL_PKG_RELEASE} \
        # nginx-plus-module-perl \
        # nginx-plus-module-perl=${NGINX_VERSION}-r${PKG_RELEASE} \
        # nginx-plus-module-xslt \
        # nginx-plus-module-xslt=${NGINX_VERSION}-r${PKG_RELEASE} \
    " \
    KEY_SHA512="e09fa32f0a0eab2b879ccbbc4d0e4fb9751486eedda75e35fac65802cc9faa266425edf83e261137a2f4d16281ce2c1a5f4502930fe75154723da014214f0655" \
    && wget -O /tmp/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub \
    && if echo "$KEY_SHA512 */tmp/nginx_signing.rsa.pub" | sha512sum -c -; then \
        echo "key verification succeeded!"; \
        mv /tmp/nginx_signing.rsa.pub /etc/apk/keys/; \
    else \
        echo "key verification failed!"; \
        exit 1; \
    fi \
    && cat cert.pem > /etc/apk/cert.pem \
    && cat cert.key > /etc/apk/cert.key \
    && apk add -X "https://pkgs.nginx.com/plus/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" --no-cache $nginxPackages \
    && if [ -f "/etc/apk/keys/nginx_signing.rsa.pub" ]; then rm -f /etc/apk/keys/nginx_signing.rsa.pub; fi \
    && if [ -f "/etc/apk/cert.key" ] && [ -f "/etc/apk/cert.pem" ]; then rm -f /etc/apk/cert.key /etc/apk/cert.pem; fi \
# Bring in tzdata so users could set the timezones through the environment variables
    && apk add --no-cache tzdata \
# Bring in curl and ca-certificates to make registering on DNS SD easier
    && apk add --no-cache curl ca-certificates \
# Forward request and error logs to Docker log collector
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx /etc/nginx/

EXPOSE 80

STOPSIGNAL SIGQUIT

CMD ["nginx", "-g", "daemon off;"]
