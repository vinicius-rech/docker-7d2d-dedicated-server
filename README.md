# 7 Days to Die Dedicated Server Stack

Containerized setup for hosting a 7 Days to Die dedicated server plus an optional Loki/Promtail/Prometheus/Grafana stack for log aggregation and dashboards. The `docker-compose.yml` file wires everything together and persists all game data under `server/7d2d` on the host.

## Preview

<p align="center">
  <img src="docs/preview.png" alt="7 Days to Die Dedicated Server Stack Docker Preview" width="1440" />
</p>

## Requirements

- Docker 24+ and the Docker Compose plugin
- ~10 GB free disk space for the server files downloaded by SteamCMD on first run

## Repository Layout

- `Dockerfile` – Builds the base image that installs SteamCMD and runs `startserver.sh`.
- `docker-compose.yml` – Spins up the game server and the monitoring stack.
- `server/7d2d` – Bind-mounted persistent data (Saves, Mods, logs, config files, etc.).
- `server/7d2d/serverconfig_example.xml` – Sample configuration committed to git; copy it before editing.
- `startserver.sh` – Entrypoint that ensures the server is installed/updated and then launches it with the chosen config.

## Configure `serverconfig.xml`

`serverconfig.xml` is intentionally ignored by git so you can keep credentials or passwords out of the repository. To create your config:

1. Copy the example file:
   ```bash
   cp server/7d2d/serverconfig_example.xml server/7d2d/serverconfig.xml
   ```
2. Edit `server/7d2d/serverconfig.xml` and adjust the properties in `<ServerSettings>` (e.g., `ServerName`, `ServerPort`, `ServerPassword`, `WebDashboardEnabled`, etc.).
3. Keep `serverconfig_example.xml` updated with sane defaults if you want teammates to have a working starting point; they can repeat the copy step locally.

The server container always loads `/server/7d2d/serverconfig.xml`, so make sure the file exists before running `docker compose up`.

## Running the stack

```bash
# Build the custom server image (once, or when the Dockerfile changes)
docker compose build 7d2d

# Start everything in the background (downloads the server on first run)
docker compose up -d

# Follow the dedicated server logs
docker compose logs -f 7d2d
```

First startup downloads the full dedicated server through SteamCMD and may take several minutes. `startserver.sh` symlinks the default `~/.local/share/7DaysToDie` data directory into `server/7d2d`, so game saves, mods, and logs remain on the host and survive container rebuilds/recreations.

### Stopping and removing containers

```bash
docker compose down
```

Adding `-v` to the command would also drop the named Docker volumes used by Loki/Grafana/Prometheus (not recommended unless you really want to reset monitoring data).

## Mods, Saves, and Logs

- Place Mods inside `server/7d2d/Mods/`.
- Game worlds and player data live under `server/7d2d/Saves/` (which maps to the server's `~/.local/share/7DaysToDie/Saves` path).
- Runtime logs are written to `server/7d2d/logs/` and are shipped to Loki via Promtail automatically.

Because the whole `server/7d2d` directory is bind-mounted, you can back it up or edit files from the host at any time.

## Monitoring & Dashboards

The compose file includes optional observability services:

- **Promtail** tails `server/7d2d/logs` and sends entries to **Loki**.
- **Grafana** (http://localhost:3000, default creds `admin` / `admin123`) can visualize Loki or Prometheus data; add your own dashboards as needed.
- **Prometheus** (http://localhost:9090) is currently provided for future metrics scraping.

Ports for Loki, Grafana, and Prometheus are bound to `127.0.0.1` so they are only accessible from the host machine.

## Updating the server binaries

`startserver.sh` automatically runs SteamCMD the first time or whenever the executable is missing. To force an update on demand:

```bash
FORCE_UPDATE=1 docker compose up -d 7d2d
```

This sets the `FORCE_UPDATE` environment variable for the `7d2d` service, triggering SteamCMD to validate and update the installation before launching the server.

## Troubleshooting

- Ensure `server/7d2d/serverconfig.xml` exists and is valid XML; otherwise the dedicated server will exit immediately.
- Verify the `server/7d2d` folder is writable by your user so Docker can bind-mount it.
- Use `docker compose logs grafana|promtail|loki|prometheus` if any monitoring component misbehaves.

With the config template committed (`serverconfig_example.xml`) and the personal config ignored, each collaborator can quickly spin up their own server instance without leaking secrets into git.
