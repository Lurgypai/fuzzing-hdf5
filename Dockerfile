FROM ubuntu:22.04

# install necessary
RUN apt update && apt install -y \
    build-essential \
    make \
    git \
    python3 \
    automake \
    autoconf \
    libtool \
    wget \
    lsb-release \
    software-properties-common \
    gnupg \
    zip \
    cmake \
    && apt clean

# setup clang 16
RUN wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 16
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-16 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-16 100

# copy important files to workspace
COPY docker_contents/* /workspace/

WORKDIR /workspace
RUN unzip models.zip \
    && rm models.zip

# compile AFL++
RUN git clone https://github.com/AFLplusplus/AFLplusplus.git
WORKDIR /workspace/AFLplusplus
RUN make

WORKDIR /workspace
