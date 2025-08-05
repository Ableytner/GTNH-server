# GTNH server docker images

This repository contains docker images for hosting a dedicated server for the [GT New Horizons](https://www.gtnewhorizons.com/) Minecraft modpack.

At the moment, only daily GTNH versions are supported, stable versions will follow in the future.

It has worked without issues for the last few months for me, but you should use it at your own risk. (And don't forget to make regular backups!)

## Usage example

This image can be used in a docker-compose.yml files as follows:
```yml
services:
  mc:
    container_name: gtnh
    image: ghcr.io/ableytner/gtnh-server:daily
    tty: true
    stdin_open: true
    ports:
      - 25565:25565
    volumes:
      - ./server:/data
      - ./additional_mods:/mods
    environment:
      MEMORY: 12G
      MOTD: "GT New Horizons MODPACK_VERSION-dailyDAILY_BUILD"
      TZ: Europe/Vienna
      EULA: "TRUE"
    restart: no
  backups:
    container_name: gtnh-backups
    image: itzg/mc-backup:latest
    depends_on:
      mc:
        condition: service_healthy
    volumes:
      - ./server:/data:ro
      - ./backups:/backups
    environment:
      SERVER_PORT: 25565
      SRC_DIR: /data
      DEST_DIR: /backups
      INCLUDES: ./World
      BACKUP_METHOD: tar
      BACKUP_INTERVAL: 24h
      BACKUP_ON_STARTUP: true
      PAUSE_IF_NO_PLAYERS: false
      PRUNE_BACKUPS_DAYS: 7
      RCON_HOST: mc
      RCON_RETRIES: 15
```
where ./server contains the minecraft server files and ./additional_mods contains any additional mods (as .jar files).

As this image is based on [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server), it supports all environment variables allowed there. All possible variables are listed [here](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#server).

'MODPACK_VERSION' and 'DAILY_BUILD' in the MOTD are placeholder variables that get substituted with the current GT New Horizons version and daily build version.

Also included in the example is an automatic backup service which creates a full server backup every 24 hours.

## Upgrading from nightlys (old) to dailys

As of 05.08.2025, this repository offers daily builds, which substitute the old nightly format.
More information can be found [here](https://github.com/GTNewHorizons/DreamAssemblerXXL/pull/210) and [here](https://github.com/GTNewHorizons/DreamAssemblerXXL/pull/217)

To upgrade an existing server to the new format:
* stop and remove the container (`docker compose down`)
* open the folder server/docker-backups and move the newest backup file somewhere save, in case something goes wrong during the upgrade
* open the folder server/docker-backups and remove all files (`rm ./server/docker-backups/*`)
* change compose file to daily releases by setting the image to ghcr.io/ableytner/gtnh-server:daily
* pull and start with the new version (`docker compose pull && docker compose up`)

## Credits

Many thanks to [Geoff Bourne](https://github.com/itzg) for creating the docker-minecraft-server image, which this project is based on!

### TO-DO

* Build images for stable and experimental releases
* Remove existing mod if modid matches with mod from additional_mods to allow for manually adding newer versions
* Create tests for backup/rollback functionality
