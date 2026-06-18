FROM golang:latest AS builder

WORKDIR /app

ADD tailscale /app/tailscale

# build derper (no code modifications needed since v1.98+)
RUN cd /app/tailscale/cmd/derper && \
    CGO_ENABLED=0 /usr/local/go/bin/go build -buildvcs=false -ldflags "-s -w" -o /app/derper && \
    cd /app && \
    rm -rf /app/tailscale

FROM ubuntu:22.04
WORKDIR /app

# ========= CONFIG =========
ENV DERP_ADDR :443
ENV DERP_HTTP_PORT -1
ENV DERP_HOST=127.0.0.1
ENV DERP_CERTS=/app/certs/
ENV DERP_STUN true
ENV DERP_VERIFY_CLIENTS false
# ==========================

RUN apt-get update && \
    apt-get install -y ca-certificates && \
    mkdir -p /app/certs

COPY --from=builder /app/derper /app/derper

# v1.98+ auto-creates self-signed cert for IP hostnames
CMD /app/derper --hostname=$DERP_HOST \
    --certmode=manual \
    --certdir=$DERP_CERTS \
    --stun=$DERP_STUN \
    --a=$DERP_ADDR \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS
