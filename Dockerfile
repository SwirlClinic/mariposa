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
        ca-certificates locales \
		sudo \
        curl \
		wget \
		ca-certificates \
		lib32gcc-s1 lib32stdc++6 \
		lib32z1 \
		libtinfo5:i386 \
		libncurses5:i386 \
		libcurl3-gnutls:i386 \
		xdg-user-dirs xdg-utils 
# More commands
RUN set -x \
    && echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER \
    && mkdir -p "${STEAMCMDDIR}" \
    && mkdir -p "${HOME}/.steam/sdk32" \
    && mkdir -p "${HOME}/.steam/sdk64" \
    && chown -R "${USER}:${USER}" "${STEAMCMDDIR}" "${HOME}/.steam/sdk32" "${HOME}/.steam/sdk64" \
    # Download SteamCMD, execute as user
	&& su "${USER}" -c \
		"curl -fsSL 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
                && \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
                && ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${STEAMCMDDIR}/steamservice.so\" \
                && ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOME}/.steam/sdk32/steamclient.so\" \
                && ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
                && ln -s \"${STEAMCMDDIR}/linux64/steamclient.so\" \"${HOME}/.steam/sdk64/steamclient.so\" \
                && ln -s \"${STEAMCMDDIR}/linux64/steamcmd\" \"${STEAMCMDDIR}/linux64/steam\" \
                && ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
    # Symlink steamclient.so; So misconfigured dedicated servers can find it
 	&& ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" \
	&& rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR $HOME

# Create symlink for executable
RUN ln -s /usr/games/steamcmd /usr/bin/steamcmd

# Set default command
ENTRYPOINT ["steamcmd"]
CMD ["+help", "+quit"]