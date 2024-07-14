import
  meta,
  configurator,
  contextor,
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
  intervalPoll = config.intervalPoll

proc logApiError(service, exceptMsg: string) = logger.log(lvlError, &"Connection error occurred when trying to notify via {service}: " & exceptMsg)
proc waitPoll*() = sleep intervalPoll

proc notifyViaMail() = config.mail.applyCtx.sendMail()
proc notifyViaDbus() = config.dbus.applyCtx.broadcastDbus()
proc notifyViaMattermost(): bool {.discardable.} = config.mattermost.applyCtx.postMattermost()
proc notifyViaMatrix(): bool {.discardable.} = config.matrix.applyCtx.postMatrix()
proc notifyViaRocketChat(): bool {.discardable.} = config.rocketchat.applyCtx.postRocketChat()
proc notifyViaGotify(): bool {.discardable.} = config.gotify.applyCtx.postGotify()

template notify(enabled: bool, doNotify: proc, nameService: string): untyped =
  if enabled:
    try: doNotify() except:
      logApiError(nameService, getCurrentExceptionMsg())
      when meta.debug: echo getCurrentException().getStackTrace

proc notify*() =
  notify(config.useMail      , notifyViaMail      , nameMail)
  notify(config.useDesktop   , notifyViaDbus      , nameDbus)
  notify(config.useMattermost, notifyViaMattermost, nameMattermost)
  notify(config.useMatrix    , notifyViaMatrix    , nameMatrix)
  notify(config.useRocketChat, notifyViaRocketChat, nameRocketChat)
  notify(config.useGotify    , notifyViaGotify    , nameGotify)