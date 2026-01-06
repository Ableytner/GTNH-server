# GTNH server docker images

This repository contains docker images for running a dedicated server for the [GT New Horizons](https://www.gtnewhorizons.com/) Minecraft modpack.

Stable GTNH versions are released under the `stable` tag, and built manually whenever a new version releases.

Daily GTNH versions are built automatically every day and available under the `daily` tag.

There is also backup / rollback functionality builtin, but you shouldn't rely on it. (Don't forget to make regular backups!)

## Usage example

This image can be used in a docker-compose.yml file as follows:
```yml
services:
  mc:
    container_name: minecraft-gtnh
    image: ghcr.io/ableytner/gtnh-server:daily
    tty: true
    stdin_open: true
    ports:
      - 25565:25565
      - 8123:8123
    volumes:
      - ./server:/data
      - ./additional_mods:/mods
    environment:
      MOTD: "GT New Horizons MODPACK_VERSION-dailyDAILY_BUILD"
      EULA: "TRUE"
      WEBMAP: "TRUE"
    restart: no
```
where ./server contains the minecraft server files (automatically downloaded) and ./additional_mods contains any additional mods (as .jar files).

Some environment variables are set to sane default that should always work with the modpack, but feel free to change them.
As this image is based on [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server), it supports [all](https://docker-minecraft-server.readthedocs.io/en/latest/variables/#server) environment variables allowed there.

'MODPACK_VERSION' and 'DAILY_BUILD' in the MOTD are placeholder variables that get substituted with the current GT New Horizons version and daily build version.

'WEBMAP' enables a [web map](https://github.com/GTNewHorizons/GTNH-Web-Map) of the server world, which is accessible through a browser on port 8123. You may need to open ports in your firewall and/or router.

## Upgrading from nightlys (old) to dailys

As of 05.08.2025, this repository offers daily builds, which substitute the old nightly format.
More information can be found [here](https://github.com/GTNewHorizons/DreamAssemblerXXL/pull/210) and [here](https://github.com/GTNewHorizons/DreamAssemblerXXL/pull/217)

To upgrade an existing server to the new format:
* stop and remove the container (`docker compose down`)
* open the folder server/docker-backups and move the newest backup file somewhere save, in case something goes wrong during the upgrade
* open the folder server/docker-backups and remove all files (`rm ./server/docker-backups/*`)
* change your docker-compose.yml file to daily releases by setting the image to ghcr.io/ableytner/gtnh-server:daily
* pull and start with the new version (`docker compose pull && docker compose up`)

## Credits

Many thanks to [Geoff Bourne](https://github.com/itzg) for creating the [docker-minecraft-server](https://github.com/itzg/docker-minecraft-server) image, which this project is based on!

Many thanks to [David Lindström](https://github.com/dvdmandt) for forking and maintaining the [GTNH-Web-Map](https://github.com/GTNewHorizons/GTNH-Web-Map) mod, which this image includes.

### TO-DO

* Remove existing mod if modid matches with mod from additional_mods to allow for manually adding newer versions
* Create tests for backup/rollback functionality
