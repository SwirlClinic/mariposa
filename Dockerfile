######## INSTALL ########

# Set the base image
FROM --platform=linux/amd64 debian:12-slim

# Set environment variables
ENV USER steam
ENV HOME "/home/${USER}"
ENV APP "/app"
ENV STEAMCMDDIR "${APP}/steamcmd"

ENV CPU_MHZ ${CPU_MHZ:-3000}

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


# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Set working directory
WORKDIR $HOME

# Fix missing directories and libraries
RUN set -eux; \
    mkdir -p ${HOME}/.steam; \
    steamcmd +quit; \
    ln -s ${HOME}/.local/share/Steam/steamcmd/linux32 ${HOME}/.steam/sdk32; \
    ln -s ${HOME}/.local/share/Steam/steamcmd/linux64 ${HOME}/.steam/sdk64; \
    ln -s ${HOME}/.steam/sdk32/steamclient.so ${HOME}/.steam/sdk32/steamservice.so; \
    ln -s ${HOME}/.steam/sdk64/steamclient.so ${HOME}/.steam/sdk64/steamservice.so;



# Set default command
ENTRYPOINT ["steamcmd"]
CMD ["+help", "+quit"]