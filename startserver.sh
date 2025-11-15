#!/bin/bash
set -euo pipefail

SERVER_DIR=/server/7d2d
CONFIG_FILE="$SERVER_DIR/serverconfig.xml"
STEAM_SDK_DIR=/root/.steam/sdk64
STEAM_CLIENT_SRC="$SERVER_DIR/steamclient.so"

mkdir -p "$SERVER_DIR"
mkdir -p "$STEAM_SDK_DIR"

link_steamclient() {
    if [ -f "$STEAM_CLIENT_SRC" ]; then
        ln -sf "$STEAM_CLIENT_SRC" "$STEAM_SDK_DIR/steamclient.so"
    elif [ -f "$SERVER_DIR/7DaysToDieServer_Data/Plugins/x86_64/steamclient.so" ]; then
        ln -sf "$SERVER_DIR/7DaysToDieServer_Data/Plugins/x86_64/steamclient.so" \
            "$STEAM_SDK_DIR/steamclient.so"
    else
        echo "WARNING: steamclient.so not found; Steam networking may fail."
    fi
}

install_server() {
    echo "=== Installing/Updating 7 Days to Die Dedicated Server ==="
    /steamcmd/steamcmd.sh \
        +force_install_dir "$SERVER_DIR" \
        +login anonymous \
        +app_update 294420 validate \
        +quit
}

if [ "${FORCE_UPDATE:-0}" = "1" ]; then
    install_server
elif [ ! -x "$SERVER_DIR/7DaysToDieServer.x86_64" ]; then
    install_server
else
    echo "=== Server files detected; skipping SteamCMD update ==="
fi

link_steamclient
export SteamAppId=251570

cd "$SERVER_DIR"
mkdir -p logs

echo "=== Starting 7 Days to Die Dedicated Server ==="
exec ./7DaysToDieServer.x86_64 \
    -logfile logs/latest.log \
    -configfile="$CONFIG_FILE"
