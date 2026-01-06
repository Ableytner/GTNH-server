FROM itzg/minecraft-server:java25-graalvm

ARG GTNH_VERSION \
  GTNH_DAILY_BUILD

RUN dnf update -y \
  && dnf install -y jq zip unzip \
  && mkdir -p /download \
  && mkdir -p /tmp

# download either daily or stable modpack zip
RUN --mount=type=secret,id=github_token \
  if [ "$GTNH_DAILY_BUILD" != "" ]; then \
  curl --fail-with-body -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github_token)" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/GTNewHorizons/DreamAssemblerXXL/actions/workflows/daily-modpack-build.yml/runs?per_page=100 \
  | jq -r ".workflow_runs[] | select(.run_number==${GTNH_DAILY_BUILD}) | .url" \
  | xargs -I{} \
  curl --fail-with-body -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github_token)" -H "X-GitHub-Api-Version: 2022-11-28" "{}/artifacts" \
  | jq -r '.artifacts[] | select(.name | endswith("server-new-java")) | .archive_download_url' \
  | xargs -I{} \
  curl --fail-with-body -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github_token)" -H "X-GitHub-Api-Version: 2022-11-28" {} -o /download/server.zip \
  && cd /download \
  && unzip server.zip -d . \
  && rm server.zip \
  && mv *.zip server.zip \
  ; else \
  curl --fail-with-body -L https://downloads.gtnewhorizons.com/ServerPacks/?raw \
  | grep -P "${GTNH_VERSION}_Server_Java_1" \
  | xargs -I {} \
  curl --fail-with-body -L {} -o /download/server.zip \
  ; fi

# download gtnh web map
RUN --mount=type=secret,id=github_token \
  curl --fail-with-body -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github_token)" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/GTNewHorizons/GTNH-Web-Map/releases/latest \
  | jq -r '.assets[] | select(.name | test("gtnh-web-map-[\\d\\.]+\\.jar")) | .browser_download_url' \
  | xargs -I{} \
  curl --fail-with-body -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github_token)" -H "X-GitHub-Api-Version: 2022-11-28" {} --remote-name \
  && mv gtnh-web-map-*.jar /download/

# set default environment variables for GTNH
ENV GTNH_VERSION=${GTNH_VERSION} \
  GTNH_DAILY_BUILD=${GTNH_DAILY_BUILD} \
  TYPE="custom" \
  CUSTOM_SERVER="/data/lwjgl3ify-forgePatches.jar" \
  JVM_OPTS="@java9args.txt" \
  JVM_XX_OPTS="-Dfml.queryResult=confirm -Dgt.recipebuilder.recipe_collision_check=true -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3  -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:GCTimeRatio=99" \
  MEMORY="8G" \
  DUMP_SERVER_PROPERTIES="TRUE" \
  CREATE_CONSOLE_IN_PIPE="TRUE"

COPY --chmod=755 scripts/* /gtnh/scripts/

RUN dos2unix /gtnh/scripts/*

ENTRYPOINT [ "/gtnh/scripts/backup-and-install" ]
HEALTHCHECK --start-period=2m --retries=2 --interval=30s CMD mc-health

RUN if [ "$GTNH_DAILY_BUILD" != "" ]; then \
  echo "gtnh-version=${GTNH_VERSION}\ndaily=${GTNH_DAILY_BUILD:-1}\n" >> /etc/image.properties \
  ; else \
  echo "gtnh-version=${GTNH_VERSION}\n" >> /etc/image.properties \
  ; fi
