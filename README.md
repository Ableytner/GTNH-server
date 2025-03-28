# GTNH server docker images

This repository contains docker images for hosting a dedicated server for the [GT New Horizons](https://www.gtnewhorizons.com/) Minecraft modpack.

At the moment, only nightly GTNH versions are supported, stable versions will follow in the future.

It has worked without issues for the last few months for me, but you should use it at your own risk. (And don't forget to make regular backups!)

## Usage example

This image can be used in a docker-compose.yml files as follows:
```yml
services:
  mc:
    container_name: gtnh
    image: ghcr.io/ableytner/gtnh-server:nightly
    tty: true
    stdin_open: true
    ports:
      - 25565:25565
    volumes:
      - ./server:/data
      - ./additional_mods:/mods
    environment:
      MEMORY: 12G
      MOTD: "GT New Horizons MODPACK_VERSION-nightlyNIGHTLY_BUILD"
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

'MODPACK_VERSION' and 'NIGHTLY_BUILD' in the MOTD are placeholder variables that get substituted with the current GT New Horizons version and nightly build version.

Also included in the example is an automatic backup service which creates a full server backup every 24 hours.

## Credits

Many thanks to [Geoff Bourne](https://github.com/itzg) for creating the docker-minecraft-server image!

### TO-DO

* Build images for stable releases
* Remove existing mod if modid matches with mod from additional_mods
* Create tests for backup/rollback functionality
