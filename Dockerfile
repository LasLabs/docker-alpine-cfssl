# Copyright 2016-2017 LasLabs Inc.
# License Apache 2.0 (https://www.apache.org/licenses/LICENSE-2.0.html).

FROM golang:alpine
MAINTAINER Dave Lasley <dave@laslabs.com>

ENV CFSSL_CSR="csr_root_ca.json" \
    CFSSL_CONFIG="ca_root_config.json" \
    DB_CONFIG="db_config.json" \
    DB_ENVIRONMENT="production" \
    DB_INIT="1" \
    DB_DESTROY="0"

# Copy Docker Entrypoint
COPY ./docker-entrypoint.sh /

# Copy default CSR JSON
COPY ./etc/* /etc/cfssl/

# Copy binaries
COPY ./bin/ /cfssl-bin

# Install Build Dependencies
RUN apk add --no-cache --virtual .build-deps \
        build-base \
        gcc \
        git \
        libtool \
        sqlite-dev \
# Install curl and python for API interaction
    && apk add --no-cache \
        curl \
        python \
# Create CFSSL User and Group
    && addgroup -S cfssl \
    && adduser -S -g cfssl cfssl \
# Install Goose
    && go get bitbucket.org/liamstask/goose/cmd/goose \
# Install CFSSL
    && git clone --depth=1 "https://github.com/cloudflare/cfssl.git" "${GOPATH}/src/github.com/cloudflare/cfssl" \
    && cd "${GOPATH}/src/github.com/cloudflare/cfssl" \
	&& go build -o /usr/bin/cfssl ./cmd/cfssl \
	&& go build -o /usr/bin/cfssljson ./cmd/cfssljson \
	&& go build -o /usr/bin/mkbundle ./cmd/mkbundle \
	&& go build -o /usr/bin/multirootca ./cmd/multirootca \
# Install trusted certs
	&& cp -R "${GOPATH}/src/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust" / \
	&& ln -s /cfssl_trust /etc/cfssl/ \
# Move database migrations to /opt
    && mkdir /opt/ \
    && cp -R "${GOPATH}/src/github.com/cloudflare/cfssl/certdb/" /opt/ \
# Install go.rice
    && set -x \
	&& go get github.com/GeertJohan/go.rice/rice \
    && rice embed-go -i=./cli/serve \
# Create PKI directory
	&& mkdir -p /etc/cfssl \
# Create symlink CSR to root
    && ln -s "/etc/cfssl/${CFSSL_CSR}" / \
# Directory/File permissions
    && chown -R cfssl:cfssl /etc/cfssl \
    && chmod 770 /etc/cfssl \
    && chmod 644 /etc/cfssl/*.json \
    && chown cfssl:cfssl /docker-entrypoint.sh \
    && chmod 770 /docker-entrypoint.sh \
    && chown cfssl:cfssl /cfssl_trust \
    && chown cfssl:cfssl /opt/certdb \
    && chown -R cfssl:cfssl /cfssl-bin \
    && chmod -R 770 /cfssl-bin \
# Add Binaries to /bin
    && ln -s /cfssl-bin/* /bin \
# Cleanup
	&& apk del .build-deps \
	&& rm -rf "${GOPATH}/src"

# Switch from root user
USER "cfssl:cfssl"

# Change to PKI Dir
WORKDIR /etc/cfssl

# Exose ports & volumes
VOLUME ["/etc/cfssl", "/cfssl_trust"]
EXPOSE 8080

# Entrypoint & Command
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["cfssl", \
     "serve", \
     "-address=0.0.0.0", \
     "-ca=/etc/cfssl/ca.pem", \
     "-ca-key=/etc/cfssl/ca-key.pem", \
     "-port=8080"]

# Metadata
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="CFSSL - Alpine" \
      org.label-schema.description="Provides a Docker image for CFSSL based on Alpine Linux." \
      org.label-schema.url="https://laslabs.com/" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/LasLabs/docker-alpine-cfssl" \
      org.label-schema.vendor="LasLabs Inc." \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"
