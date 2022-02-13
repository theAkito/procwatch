from logging import Level

const
  debug             * {.booldefine.} = false
  logMsgPrefix      * {.strdefine.}  = "[$levelname]:[$datetime]"
  appVersion        * {.strdefine.}  = "0.1.0"
  configName        * {.strdefine.}  = "procwatch.json"
  configPath        * {.strdefine.}  = ""
  configIndentation * {.intdefine.}  = 2
  dirProc           *                = "/proc"
  nameMail          *                = "E-Mail"
  nameDbus          *                = "Desktop"
  nameMattermost    *                = "Mattermost"
  nameMatrix        *                = "Matrix"
  nameRocketChat    *                = "Rocket.Chat"


func defineLogLevel*(): Level =
  if debug: lvlDebug else: lvlInfo