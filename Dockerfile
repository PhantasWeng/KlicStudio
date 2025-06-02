FROM golang:1.22-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git ca-certificates
COPY go.mod go.sum ./
RUN go mod download
COPY . ./
RUN CGO_ENABLED=0 GOOS=linux go build -o KrillinAI ./cmd/server

FROM ubuntu:latest AS runtime
ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /app
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates ffmpeg fontconfig xfonts-utils && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/share/fonts/msyh && \
    wget -O /usr/share/fonts/msyh/msyh.ttc "https://modelscope.cn/models/Maranello/KrillinAI_dependency_cn/resolve/master/%E5%AD%97%E4%BD%93/msyh.ttc" && \
    wget -O /usr/share/fonts/msyh/msyhbd.ttc "https://modelscope.cn/models/Maranello/KrillinAI_dependency_cn/resolve/master/%E5%AD%97%E4%BD%93/msyhbd.ttc" && \
    mkfontscale /usr/share/fonts/msyh && \
    mkfontdir /usr/share/fonts/msyh && \
    fc-cache -fv
RUN mkdir -p bin models
RUN ARCH=$(uname -m) && \
    case "$ARCH" in \
        x86_64) URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.01.15/yt-dlp_linux";; \
        armv7l) URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.01.15/yt-dlp_linux_armv7l";; \
        aarch64) URL="https://github.com/yt-dlp/yt-dlp/releases/download/2025.01.15/yt-dlp_linux_aarch64";; \
        *) echo "Unsupported architecture: $ARCH" && exit 1;; \
    esac && \
    wget -O bin/yt-dlp "$URL" && \
    chmod +x bin/yt-dlp
COPY --from=builder /app/KrillinAI ./KrillinAI
RUN chmod +x ./KrillinAI
VOLUME ["/app/bin", "/app/models"]
ENV PATH="/app/bin:${PATH}"
EXPOSE 8888/tcp
ENTRYPOINT ["./KrillinAI"]
