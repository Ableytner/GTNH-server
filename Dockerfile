FROM itzg/minecraft-server:java25-graalvm

ARG GTNH_VERSION \
  GTNH_DAILY_BUILD

RUN dnf update -y \
  && dnf install -y jq zip unzip \
  && mkdir -p /download \
  && mkdir -p /tmp

# download server zip
RUN --mount=type=secret,id=github_token \
  if [ "$GTNH_DAILY_BUILD" != "" ]; then \
  curl -Lf https://api.ableytner.at/gtnh/daily/${GTNH_DAILY_BUILD} \
  | jq -r ".downloads.server" \
  | xargs -I{} \
  curl -Lf -H "Authorization: Bearer $(cat /run/secrets/github_token)" {} -o /download/server.zip \
  ; else \
  curl -Lf https://api.ableytner.at/gtnh/stable/${GTNH_VERSION} \
  | jq -r ".downloads.server" \
  | xargs -I{} \
  curl -Lf -H "Authorization: Bearer $(cat /run/secrets/github_token)" {} -o /download/server.zip \
  ; fi

# download gtnh web map
RUN --mount=type=secret,id=github_token \
  curl -Lf https://api.ableytner.at/gtnh/webmap/latest \
  | jq -r ".download_url" \
  | xargs -I{} \
  curl -Lf -H "Authorization: Bearer $(cat /run/secrets/github_token)" {} --remote-name \
  && mv gtnh-web-map-*.jar /download/

# set default environment variables for GTNH
ENV GTNH_VERSION=${GTNH_VERSION} \
  GTNH_DAILY_BUILD=${GTNH_DAILY_BUILD} \
  TYPE="custom" \
  CUSTOM_SERVER="/data/lwjgl3ify-forgePatches.jar" \
  JVM_OPTS="@java9args.txt" \
  JVM_XX_OPTS="-Dfml.queryResult=confirm -Dgt.recipebuilder.recipe_collision_check=true -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:GCTimeRatio=99" \
  MEMORY="8G" \
  DUMP_SERVER_PROPERTIES="TRUE" \
  CREATE_CONSOLE_IN_PIPE="TRUE" \
  LEVEL_TYPE="rwg" \
  DIFFICULTY="hard" \
  ALLOW_FLIGHT="TRUE"

COPY --chmod=755 scripts/* /gtnh/scripts/

RUN dos2unix /gtnh/scripts/*

ENTRYPOINT [ "/gtnh/scripts/backup-and-install" ]
HEALTHCHECK --start-period=2m --retries=2 --interval=30s CMD mc-health

RUN BACKUP_ID=$(bash -c 'source /gtnh/scripts/gtnh-utils; version_to_int "$1" "$2"' _ "$GTNH_VERSION" "$GTNH_DAILY_BUILD") \
    && if [ "$GTNH_DAILY_BUILD" != "" ]; then \
    printf 'gtnh-version=%s\ndaily=%s\nbackup-id=%s\n' "$GTNH_VERSION" "${GTNH_DAILY_BUILD:-1}" "$BACKUP_ID" >> /etc/image.properties \
    ; else \
    printf 'gtnh-version=%s\nbackup-id=%s\n' "$GTNH_VERSION" "$BACKUP_ID" >> /etc/image.properties \
    ; fi
