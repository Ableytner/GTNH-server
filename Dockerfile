FROM itzg/minecraft-server:java21

ARG GTNH_NIGHTLY_BUILD

RUN apt-get update \
  && apt-get install -y jq zip unzip \
  && mkdir -p /download \
  && mkdir -p /tmp

RUN --mount=type=secret,id=github_token \
  curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github-token)" -H "X-GitHub-Api-Version: 2022-11-28" https://api.github.com/repos/GTNewHorizons/DreamAssemblerXXL/actions/runs?per_page=100 \
  | jq -r ".workflow_runs[] | select(.run_number==${GTNH_NIGHTLY_BUILD}) | .url" \
  | curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github-token)" -H "X-GitHub-Api-Version: 2022-11-28" "$(cat -)/artifacts" \
  | jq -r '.artifacts[] | select(.name | endswith("server-new-java")) | .archive_download_url' \
  | curl -L -H "Accept: application/vnd.github+json" -H "Authorization: Bearer $(cat /run/secrets/github-token)" -H "X-GitHub-Api-Version: 2022-11-28" "$(cat -)" -o /download/server.zip \
  && cd /download \
  && unzip server.zip -d . \
  && rm server.zip \
  && mv "$(ls *.zip)" server.zip

# read gtnh version from zip file

# set default environment variables for GTNH
ENV GTNH_NIGHTLY_BUILD=${GTNH_NIGHTLY_BUILD} \
  TYPE=custom \
  CUSTOM_SERVER="/data/lwjgl3ify-forgePatches.jar" \
  JVM_OPTS="@java9args.txt" \
  JVM_XX_OPTS="-Dfml.queryResult=confirm -Dgt.recipebuilder.recipe_collision_check=true -XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3  -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:GCTimeRatio=99"

COPY --chmod=755 scripts/backup-and-install /backup-and-install

RUN dos2unix /backup-and-install

ENTRYPOINT [ "/backup-and-install" ]
HEALTHCHECK --start-period=30s --retries=24 --interval=60s CMD mc-health
