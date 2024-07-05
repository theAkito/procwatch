FROM akito13/nim:alpine AS build

ARG nimble_task_build=docker_build_prod
ARG app_version=0.4.0

WORKDIR /app

COPY . .

RUN \
  apk --no-cache add libressl-dev dbus-dev && \
  rm -fr /var/cache/apk/* && \
  nimble install --depsOnly --accept --verbose && \
  nimble "${nimble_task_build}" "${app_version}"


FROM alpine:3.20.0

COPY --from=build /app/app /

RUN \
  apk --no-cache add libcurl libressl dbus && \
  rm -fr /var/cache/apk/*

ENTRYPOINT ["/app"]