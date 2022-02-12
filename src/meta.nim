from logging import Level

const
  debug             * {.booldefine.} = false
  appVersion        * {.strdefine.}  = "0.1.0"
  configName        * {.strdefine.}  = "procwatch.json"
  configPath        * {.strdefine.}  = ""
  configIndentation * {.intdefine.}  = 2
  dirProc           *                = "/proc"


func defineLogLevel*(): Level =
  if debug: lvlDebug else: lvlInfo