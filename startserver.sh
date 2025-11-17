#!/bin/bash
set -euo pipefail

SERVER_DIR=/server/7d2d
CONFIG_FILE="$SERVER_DIR/serverconfig.xml"
STEAM_SDK_DIR=/root/.steam/sdk64
STEAM_CLIENT_SRC="$SERVER_DIR/steamclient.so"
CONTAINER_LOCAL_SHARE=/root/.local/share/7DaysToDie
PERSISTENT_LOCAL_SHARE="$SERVER_DIR/.local/share/7DaysToDie"

mkdir -p "$SERVER_DIR"
mkdir -p "$STEAM_SDK_DIR"

ensure_persistent_saves() {
    mkdir -p "$PERSISTENT_LOCAL_SHARE"
    mkdir -p "$(dirname "$CONTAINER_LOCAL_SHARE")"

    if [ ! -L "$CONTAINER_LOCAL_SHARE" ]; then
        if [ -d "$CONTAINER_LOCAL_SHARE" ] && [ "$(ls -A "$CONTAINER_LOCAL_SHARE")" ]; then
            cp -a "$CONTAINER_LOCAL_SHARE/." "$PERSISTENT_LOCAL_SHARE/"
        fi

        rm -rf "$CONTAINER_LOCAL_SHARE"
        ln -s "$PERSISTENT_LOCAL_SHARE" "$CONTAINER_LOCAL_SHARE"
    fi

    mkdir -p "$PERSISTENT_LOCAL_SHARE/Saves"
    local saves_target=".local/share/7DaysToDie/Saves"

    if [ -d "$SERVER_DIR/Saves" ] && [ ! -L "$SERVER_DIR/Saves" ]; then
        if [ "$(ls -A "$SERVER_DIR/Saves")" ]; then
            cp -a "$SERVER_DIR/Saves/." "$PERSISTENT_LOCAL_SHARE/Saves/"
        fi
        rm -rf "$SERVER_DIR/Saves"
    elif [ -e "$SERVER_DIR/Saves" ] && [ ! -L "$SERVER_DIR/Saves" ]; then
        mv "$SERVER_DIR/Saves" "$PERSISTENT_LOCAL_SHARE/Saves"
    fi

    if [ -L "$SERVER_DIR/Saves" ]; then
        local current_target
        current_target="$(readlink "$SERVER_DIR/Saves")"
        if [ "$current_target" != "$saves_target" ]; then
            rm "$SERVER_DIR/Saves"
        fi
    fi

    if [ ! -L "$SERVER_DIR/Saves" ]; then
        ln -s "$saves_target" "$SERVER_DIR/Saves"
    fi
}

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

ensure_persistent_saves
link_steamclient
export SteamAppId=251570

cd "$SERVER_DIR"
mkdir -p logs

echo "=== Starting 7 Days to Die Dedicated Server ==="
exec ./7DaysToDieServer.x86_64 \
    -logfile logs/latest.log \
    -configfile="$CONFIG_FILE"
