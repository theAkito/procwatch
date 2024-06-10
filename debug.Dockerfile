FROM akito13/nim:2.0.0-alpine AS build

ARG nimble_task_build=docker_build_debug
ARG app_version=0.2.0

WORKDIR /app

COPY . .

RUN \
  nimble install --depsOnly --accept --verbose && \
  nimble "${nimble_task_build}" "${app_version}"


FROM alpine:3.20.0

COPY --from=build /app/app /

RUN \
  apk --no-cache add libcurl && \
  rm -fr /var/cache/apk/*

ENTRYPOINT ["/app"]