FROM golang:1.20-alpine AS builder

ENV TZ=Asia/Tehran
WORKDIR /go/src/github.com/sagernet
ARG GOPROXY=""
ENV GOPROXY ${GOPROXY}
ENV CGO_ENABLED=1
ENV TAGS="with_quic,with_grpc,with_dhcp,with_wireguard,with_shadowsocksr,with_ech,with_utls,with_reality_server,with_acme,with_clash_api,with_v2ray_api,with_gvisor"
ENV GOAMD64="v3"

RUN set -ex; \
    apk upgrade; \
    apk add --no-cache git build-base curl jq; \
    LATEST_VERSION=""; \
    until [ -n "$LATEST_VERSION" ]; do \
    LATEST_VERSION=$(curl -sX GET "https://api.github.com/repos/SagerNet/sing-box/releases" | \
    jq -r 'map(select(.prerelease)) | first | .tag_name'); \
    done; \
    git clone -b $LATEST_VERSION https://github.com/SagerNet/sing-box.git \
    && cd sing-box \
    && export COMMIT=$(git rev-parse --short HEAD) \
    && export VERSION=$(go run ./cmd/internal/read_tag) \
    && go build -v -trimpath -tags "$TAGS" \
    -o /go/bin/sing-box \
    -ldflags "-X \"github.com/sagernet/sing-box/constant.Version=$VERSION\" -s -w -buildid=" \
    ./cmd/sing-box

FROM alpine AS dist
ENV TZ=Asia/Tehran
# RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf
RUN set -ex; \
    apk upgrade; \
    apk add --no-cache bash tzdata ca-certificates; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime;
COPY --from=builder /go/bin/sing-box /usr/local/bin/sing-box

VOLUME /etc/sing-box/config/
WORKDIR /etc/sing-box/
ENTRYPOINT ["sing-box"]