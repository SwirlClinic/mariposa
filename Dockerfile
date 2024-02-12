######## INSTALL ########

# Set the base image
FROM --platform=linux/amd64 debian:12-slim

# Set environment variables
ENV USER steam
ENV HOME "/home/${USER}"
ENV PROTON_DIR "${HOME}/proton-ge"
ENV APP "/app"

ENV CPU_MHZ ${CPU_MHZ:-3000}

ENV PROTON_VERSION=GE-Proton8-32
ENV PROTON=${PROTON_DIR}/${PROTON_VERSION}/proton

ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG DEBIAN_FRONTEND=noninteractive
COPY sources.list /etc/apt/sources.list


RUN groupadd --gid $USER_GID $USER \
    && useradd --uid $USER_UID --gid $USER_GID -m $USER

# set -x will print all commands to terminal
# Install packages
RUN set -x \
    && dpkg --add-architecture i386 \
	&& apt-get update -y \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		sudo \
        curl \
		wget \
        python3 libfreetype6 \
		lib32gcc-s1 lib32stdc++6 \
		lib32z1 \
		libtinfo5:i386 \
		libncurses5:i386 \
		libcurl3-gnutls:i386 \
		xdg-user-dirs xdg-utils \
    && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER 

RUN echo steam steam/question select "I AGREE" | debconf-set-selections \
 && echo steam steam/license note '' | debconf-set-selections

RUN apt-get install -y --no-install-recommends ca-certificates locales steamcmd \
	&& rm -rf /var/lib/apt/lists/* 

# Add unicode support
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen en_US.UTF-8
ENV LANG 'en_US.UTF-8'
ENV LANGUAGE 'en_US:en'

# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Set working directory
WORKDIR $HOME

# Setup Proton
RUN mkdir -p ${PROTON_DIR}
RUN wget --directory-prefix ${PROTON_DIR} -O - \
    https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VERSION}/${PROTON_VERSION}.tar.gz \
    | tar -xz -C ${PROTON_DIR}/

# Fix missing directories and libraries
RUN set -eux; \
    mkdir -p ${HOME}/.steam; \
    steamcmd +quit; \
    ln -s ${HOME}/.local/share/Steam/steamcmd/linux32 ${HOME}/.steam/sdk32; \
    ln -s ${HOME}/.local/share/Steam/steamcmd/linux64 ${HOME}/.steam/sdk64; \
    ln -s ${HOME}/.steam/sdk32/steamclient.so ${HOME}/.steam/sdk32/steamservice.so; \
    ln -s ${HOME}/.steam/sdk64/steamclient.so ${HOME}/.steam/sdk64/steamservice.so;

RUN ln -s "${HOME}/.local/share/Steam/steamcmd/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so"

# Set default command
ENTRYPOINT ["steamcmd"]
CMD ["+help", "+quit"]