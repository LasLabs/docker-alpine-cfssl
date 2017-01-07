FROM golang:alpine
MAINTAINER Dave Lasley <dave@laslabs.com>

# Install Build Dependencies

ENV BUILD_DEPS="build-base gcc git libtool sqlite-dev"

RUN apk add --no-cache $BUILD_DEPS

# Install CFSSL

RUN git clone --depth=1 "https://github.com/cloudflare/cfssl.git" "$GOPATH/src/github.com/cloudflare/cfssl"

WORKDIR "$GOPATH/src/github.com/cloudflare/cfssl"

RUN set -x \
	&& go get github.com/GeertJohan/go.rice/rice \
    && rice embed-go -i=./cli/serve \
	&& cp -R "$GOPATH/src/github.com/cloudflare/cfssl/vendor/github.com/cloudflare/cfssl_trust" /etc/cfssl \
	&& go build -o /usr/bin/cfssl ./cmd/cfssl \
	&& go build -o /usr/bin/cfssljson ./cmd/cfssljson \
	&& go build -o /usr/bin/mkbundle ./cmd/mkbundle \
	&& go build -o /usr/bin/multirootca ./cmd/multirootca \
	&& apk del $BUILD_DEPS \
	&& rm -rf "$GOPATH/src" \
	&& echo "Build complete."

# Create and Change to PKI Dir
RUN mkdir -p /var/pki
WORKDIR /var/pki

# Setup Environment
ENV CFSSL_DATA=/var/pki

ENV CFSSL_CERT="$CFSSL_DATA/ca.pem" \
    CFSSL_KEY="$CFSSL_DATA/ca_key.pem" \
    CFSSL_CSR="$CFSSL_DATA/csr_ca.json"

COPY ./docker-entrypoint.sh /

# Create root certs & Init CA
COPY ./etc/csr_ca.json "$CFSSL_DATA/"

# Entrypoint & Command
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["cfssl", \
     "serve", \
     "-address=0.0.0.0", \
     "-port=8080", \
     "-ca='/var/pki/ca.pem'", \
     "-ca-key='/var/pki/ca-key.pem'"]
