FROM alpine:latest

ENV DEBIAN_FRONTEND=noninteractive

############################### Install packages ###############################
RUN apk update -y


RUN apk add -y \
		nano \
		less \
		unzip \
		net-tools \
		iputils-ping \
		git \
		curl \
		build-essential \
		cmake=3.22.1-1ubuntu1.22.04.2 \
		python3=3.10.6-1~22.04 \
		python3-venv=3.10.6-1~22.04 \
		python3-pip=22.0.2+dfsg-1ubuntu0.4 \
        clang

        
# install ghcup
RUN curl https://downloads.haskell.org/~ghcup/x86_64-linux-ghcup > /usr/bin/ghcup 
RUN chmod +x /usr/bin/ghcup 

ARG GHC=8.6.5
ARG CABAL=latest

# install GHC and cabal
RUN ghcup -v install ghc --isolate /usr/local --force ${GHC} 
RUN ghcup -v install cabal --isolate /usr/local/bin --force ${CABAL}


# SSH Server
RUN apk add -y \
		openssh-server
RUN rm /etc/ssh/ssh_host_*

##########
# SGX Linux SDK
##########

ARG LINUX_SGX_VER=2.23
ARG SGX_SDK_VER=${LINUX_SGX_VER}.100.2

# SGX PSW
RUN curl \
	-o /opt/sgx_debian_local_repo.tgz \
	-fSL https://download.01.org/intel-sgx/sgx-linux/${LINUX_SGX_VER}/distro/ubuntu22.04-server/sgx_debian_local_repo.tgz

RUN tar -xzf /opt/sgx_debian_local_repo.tgz -C /opt
RUN echo 'deb [arch=amd64 trusted=yes] file:/opt/sgx_debian_local_repo/ jammy main' > /etc/apt/sources.list.d/intel-sgx.list
RUN apk add -y \
	libsgx-enclave-common \
	libsgx-enclave-common-dbgsym \
	libsgx-urts \
	libsgx-urts-dbgsym \
	libsgx-epid \
	libsgx-uae-service

# AESM Service

# SGX SDK
RUN curl \
	-o /opt/sgx_linux_x64_sdk.bin \
	-fSL https://download.01.org/intel-sgx/sgx-linux/${LINUX_SGX_VER}/distro/ubuntu22.04-server/sgx_linux_x64_sdk_${SGX_SDK_VER}.bin
RUN chmod 755 /opt/sgx_linux_x64_sdk.bin
RUN /opt/sgx_linux_x64_sdk.bin --prefix /opt/intel


## Additional Dependencies
RUN apk update
RUN pip install jinja2
RUN apk add -y libgmp3-dev
RUN apk add python3-sphinx -y
RUN apk add vim -y
RUN apk add autoconf -y
RUN apk add libtool -y

## Final
ENV DEBIAN_FRONTEND=
ENV LANG=C.UTF-8

ENTRYPOINT [ "/bin/bash" ]