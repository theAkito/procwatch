import
  meta,
  configurator,
  externnotifapi/[
    mail,
    dbus,
    mattermost,
    matrix,
    rocketchat
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

proc notify*() =
  if config.useMail:
    try: notifyViaMail() except: logApiError(nameMail, getCurrentExceptionMsg())
  if config.useDesktop:
    try: notifyViaDbus() except: logApiError(nameDbus, getCurrentExceptionMsg())
  if config.useMattermost:
    try: notifyViaMattermost() except: logApiError(nameMattermost, getCurrentExceptionMsg())
  if config.useMatrix:
    try: notifyViaMatrix() except: logApiError(nameMatrix, getCurrentExceptionMsg())
  if config.useRocketChat:
    try: notifyViaRocketChat() except: logApiError(nameRocketChat, getCurrentExceptionMsg())