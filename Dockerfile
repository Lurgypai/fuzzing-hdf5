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
    vim \
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
RUN unzip drivers.zip \
    && rm drivers.zip
RUN unzip summary.zip \
    && rm summary.zip

# compile AFL++
# RUN git clone https://github.com/AFLplusplus/AFLplusplus.git
RUN git clone https://github.com/cychen2021/AFLplusplus.git
WORKDIR /workspace/AFLplusplus
RUN make

WORKDIR /workspace
RUN mkdir /workspace/output

ENV PATH="/workspace/AFLplusplus:$PATH"
ENV AFL_PATH="/workspace/AFLplusplus"

RUN /workspace/build_afl.sh > build.hdf5.log 2>&1
RUN /workspace/build_fuzzers.sh
