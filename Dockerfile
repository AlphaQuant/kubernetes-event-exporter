# syntax=docker.io/docker/dockerfile:1.25.0

FROM docker.io/library/golang:1.26.5-alpine3.23 AS builder

ENV GOPROXY="https://goproxy.cn,direct" \
    GONOSUMDB='*' \
    GONOSUMCHECK='*'

WORKDIR /gomod/kubernetes-event-exporter

COPY go.mod go.sum ./

RUN --mount=type=cache,mode=0755,target=/go/pkg/mod go mod download

WORKDIR /usr/local/src/kubernetes-event-exporter

COPY . .

ARG VERSION
ENV PKG=github.com/alphaquant/kubernetes-event-exporter/pkg

RUN --mount=type=cache,mode=0755,target=/go/pkg/mod \
    \
    CGO_ENABLED=0 \
    GOOS=linux \
    GO11MODULE=on \
    go build -ldflags="-s -w -X ${PKG}/version.Version=${VERSION}" \
    -a -o /kubernetes-event-exporter \
    ./cmd/kubernetes-event-exporter/

FROM docker.io/library/alpine:3.23

COPY --from=builder --chown=1729:1729 \
    /kubernetes-event-exporter \
    /kubernetes-event-exporter

USER 1729

ENTRYPOINT ["/kubernetes-event-exporter"]
