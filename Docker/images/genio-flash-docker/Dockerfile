FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 基本工具 + MediaTek 文件需要的 python/pip/adb/fastboot
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    adb \
    fastboot \
    usbutils \
    udev \
    wget \
    unzip \
    git \
    vim \
    less \
    screen \
    picocom \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 升級 pip，安裝 genio-tools
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install -U genio-tools

# 驗證工具是否在 PATH
RUN python3 --version && \
    pip3 --version && \
    fastboot --version && \
    genio-config || true

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace