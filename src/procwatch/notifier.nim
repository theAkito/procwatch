import
  meta,
  configurator,
  externnotifapi/[
    mail,
    dbus,
    mattermost,
    matrix,
    rocketchat,
    gotify
  ],
  std/[
    strformat,
    logging
  ]
from os import sleep

let
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "notifier" & logMsgSuffix)
  intervalPoll                = config.intervalPoll

proc logApiError(service, exceptMsg: string) = logger.log(lvlError, &"Connection error occurred when trying to notify via {service}:" & exceptMsg)
proc waitPoll*() = sleep intervalPoll

proc notifyViaMail() = config.mail.sendMail()
proc notifyViaDbus() = config.dbus.broadcastDbus()
proc notifyViaMattermost() = discard config.mattermost.postMattermost()
proc notifyViaMatrix() = discard config.matrix.postMatrix()
proc notifyViaRocketChat() = discard config.rocketchat.postRocketChat()
proc notifyViaGotify() = discard config.gotify.postGotify()

template notify(enabled: bool, doNotify: proc, nameService: string): untyped =
  if enabled:
    try: doNotify() except: logApiError(nameService, getCurrentExceptionMsg())

proc notify*() =
  notify(config.useMail      , notifyViaMail      , nameMail)
  notify(config.useDesktop   , notifyViaDbus      , nameDbus)
  notify(config.useMattermost, notifyViaMattermost, nameMattermost)
  notify(config.useMatrix    , notifyViaMatrix    , nameMatrix)
  notify(config.useRocketChat, notifyViaRocketChat, nameRocketChat)
  notify(config.useGotify    , notifyViaGotify    , nameGotify)