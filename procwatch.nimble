# Package

version       = "0.1.0"
author        = "Akito <the@akito.ooo>"
description   = "Get notified by e-mail or notification, once a Linux process finishes."
license       = "GPL-3.0-or-later"
srcDir        = "src"
bin           = @["procwatch"]
skipDirs      = @["tasks"]
skipFiles     = @["README.md"]
skipExt       = @["nim"]


# Dependencies

requires "nim          >= 1.4.0"
requires "timestamp    >= 0.4.2"
requires "notification >= 0.2.0"
requires "puppy        >= 1.0.3"


# Tasks

task intro, "Initialize project. Run only once at first pull.":
  exec "git submodule add https://github.com/theAkito/nim-tools.git tasks || true"
  exec "git submodule update --init --recursive"
  exec "git submodule update --recursive --remote"
  exec "nimble configure"
task configure, "Configure project. Run whenever you continue contributing to this project.":
  exec "git fetch --all"
  exec "nimble check"
  exec "nimble --silent refresh"
  exec "nimble install --accept --depsOnly"
  exec "sudo apt install -y libdbus-1-dev libssl-dev >/dev/null"
  exec "git status"
task fbuild, "Build project.":
  exec """nim c \
            --define:danger \
            --define:ssl \
            --opt:speed \
            --out:procwatch \
            src/procwatch && \
          strip procwatch
       """
task dbuild, "Debug Build project.":
  exec """nim c \
            --define:debug:true \
            --define:ssl \
            --debuginfo:on \
            --out:procwatch \
            src/procwatch
       """
# https://github.com/treeform/hottie/issues/11
# task pbuild, "Debug Build project for sampling profiler.":
#   exec """nim c \
#             --passL:"-no-pie" \
#             --define:ssl \
#             --define:danger \
#             --debugger:native \
#             --out:procwatch \
#             src/procwatch
#        """
task makecfg, "Create nim.cfg for optimized builds.":
  exec "nim tasks/cfg_optimized.nims"
task clean, "Removes nim.cfg.":
  exec "nim tasks/cfg_clean.nims"
