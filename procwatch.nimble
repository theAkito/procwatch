# Package

version       = "0.5.1"
author        = "Akito <the@akito.ooo>"
description   = "Get notified by e-mail or notification, once a Linux process finishes."
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["procwatch"]
skipDirs      = @["tasks"]
skipFiles     = @["README.md"]
skipExt       = @["nim"]


# Dependencies

requires "nim          >= 2.0.4" ## https://github.com/nim-lang/Nim
requires "timestamp    >= 0.4.2" ## https://github.com/jackhftang/timestamp.nim
requires "notification >= 0.2.0" ## https://github.com/SolitudeSF/notification
requires "puppy        >= 2.1.2" ## https://github.com/treeform/puppy
requires "smtp#8013aa199dedd04905d46acf3484a232378de518" ## https://github.com/nim-lang/smtp/issues/9


# Tasks
import os, strformat, strutils

const defaultVersion = "unreleased"

let
  buildParams   = if paramCount() > 8: commandLineParams()[8..^1] else: @[]    ## Actual arguments passed to task. Previous arguments are only for internal use.
  buildVersion  = if buildParams.len > 0: buildParams[^1] else: defaultVersion ## Semver compliant App Version
  buildRevision = gorge """git log -1 --format="%H""""                         ## Build revision, i.e. Git Commit Hash
  buildDate     = gorge """date"""                                             ## Build date; Example: Sun 10 Apr 2022 01:13:09 AM CEST

task configure, "Configure project. Run whenever you continue contributing to this project.":
  exec "git fetch --all"
  exec "nimble check"
  exec "nimble --silent refresh"
  exec "nimble install --accept --depsOnly --verbose"
  exec "git status"
task fbuild, "Build Production Project.":
  exec &"""nim c \
            --define:appVersion:"{buildVersion}" \
            --define:appRevision:"{buildRevision}" \
            --define:appDate:"{buildDate}" \
            --define:danger \
            --define:ssl \
            --opt:speed \
            --excessiveStackTrace:off \
            --out:procwatch \
            src/procwatch && \
          strip procwatch \
            --strip-all \
            --remove-section=.comment \
            --remove-section=.note.gnu.gold-version \
            --remove-section=.note \
            --remove-section=.note.gnu.build-id \
            --remove-section=.note.ABI-tag
       """
task dbuild, "Build Debug Project.":
  exec &"""nim c \
            --define:appVersion:"{buildVersion}" \
            --define:appRevision:"{buildRevision}" \
            --define:appDate:"{buildDate}" \
            --define:debug:true \
            --define:ssl \
            --debugger:native \
            --debuginfo:on \
            --opt:none \
            --excessiveStackTrace:off \
            --out:procwatch_debug \
            src/procwatch
       """
task docker_build_prod, "Build Production Docker.":
  exec &"""nim c \
            --define:appVersion:"{buildVersion}" \
            --define:appDate:"{gorge "date"}" \
            --define:configPath:/data/config \
            --define:logDirPath:/data/logs \
            --define:dirProc:/data/proc \
            --define:danger \
            --define:ssl \
            --opt:speed \
            --excessiveStackTrace:off \
            --out:app \
            src/procwatch && \
          strip app \
            --strip-all \
            --remove-section=.comment \
            --remove-section=.note.gnu.gold-version \
            --remove-section=.note \
            --remove-section=.note.gnu.build-id \
            --remove-section=.note.ABI-tag
       """
task docker_build_debug, "Build Debug Docker.":
  exec &"""nim c \
            --define:appVersion:"{buildVersion}" \
            --define:appDate:"{gorge "date"}" \
            --define:debug:true \
            --define:configPath:/data/config \
            --define:logDirPath:/data/logs \
            --define:dirProc:/data/proc \
            --define:ssl \
            --debugger:native \
            --debuginfo:on \
            --opt:none \
            --excessiveStackTrace:off \
            --out:app \
            src/procwatch
       """