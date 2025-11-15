FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&     apt-get install -y wget lib32gcc-s1 screen ca-certificates &&     rm -rf /var/lib/apt/lists/*

WORKDIR /server/7d2d

# Install SteamCMD
RUN mkdir -p /steamcmd &&     cd /steamcmd &&     wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz &&     tar -xvzf steamcmd_linux.tar.gz &&     rm steamcmd_linux.tar.gz

# Install 7 Days to Die Dedicated Server
COPY startserver.sh /server/startserver.sh
RUN chmod +x /server/startserver.sh

EXPOSE 26900/tcp 26900/udp
EXPOSE 26901-26905/tcp 26901-26905/udp

VOLUME ["/server/7d2d"]

CMD ["/server/startserver.sh"]
