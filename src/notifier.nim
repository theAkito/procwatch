import
  meta,
  configurator,
  externnotifapi/[
    mattermost,
    matrix,
    rocketchat
  ],
  std/[
    smtp,
    with,
    strutils,
    strformat,
    logging
  ],
  notification
from os import sleep

type NotificationDefect = object of OSError

const
  nameMail      : string = "E-Mail"
  nameDbus      : string = "Desktop"
  nameMattermost: string = "Mattermost"
  nameMatrix    : string = "Matrix"
  nameRocketChat: string = "Rocket.Chat"

let
  logger = newConsoleLogger(defineLogLevel(), "[$levelname]:[$datetime] ~ ")
  intervalPoll                = config.intervalPoll
  nameSender         : string = config.mailNameSender
  username           : string = config.mailUsername
  password           : string = config.mailPassword
  subject            : string = config.mailSubject
  message            : string = config.mailMessage
  portOutgoing       : Port = config.mailPortOutgoing.Port
  smtpOutgoing       : string = config.mailSmtpServerOutgoing
  mailAddressSource  : string = config.mailAddressSource
  mailAddressTarget  : seq[string] = config.mailAddressTarget

proc logApiError(service, exceptMsg: string) = logger.log(lvlError, &"Connection error occurred when trying to notify via {service}:\n" & exceptMsg)
proc waitPoll*() = sleep intervalPoll

proc notifiyViaMail() =
  let
    msg = createMessage(
      subject,
      message,
      mailAddressTarget, #[Addressee]#
      @[], #[CC]#
      @[ #[Headers]#
        ("From", "$# <$#>" % [nameSender, mailAddressSource])
      ]
    )
    smtpConn = newSmtp(debug = meta.debug)
  with smtpConn:
    connect(smtpOutgoing, portOutgoing)
    startTls()
    auth(username, password)
    sendMail(mailAddressSource, mailAddressTarget, $msg)

proc notifyViaDbus() =
  var notification = initNotification(
    summary = config.dbusSummary,
    body = config.dbusMessage,
    icon = config.dbusNameIcon,
    timeout = initTimeout(config.dbusTimeout)
  )
  notification.add Hint(kind: hkUrgency, urgency: Normal)
  discard notification.notify()

proc notifyViaMattermost() =
  var context = MattermostContext(
    url: config.mattermostURL,
    loginID: config.mattermostLoginID,
    password: config.mattermostPassword,
    token: config.mattermostToken,
    channelID: config.mattermostChannelID,
    message: config.mattermostMessage,
    rootID: config.mattermostRootID,
    fileIDs: config.mattermostFileIDs,
    properties: config.mattermostProperties
  )
  discard context.postMattermost()

proc notifyViaMatrix() =
  var context = MatrixContext(
    url: config.matrixURL,
    username: config.matrixUsername,
    password: config.matrixPassword,
    roomID: config.matrixRoomID,
    message: config.matrixMessage
  )
  discard context.postMatrix()

proc notifyViaRocketChat() =
  var context = RocketChatContext(
    url: config.rocketChatURL,
    token: config.rocketChatToken,
    userID: config.rocketChatUserID,
    roomID: config.rocketChatRoomID,
    channel: config.rocketChatChannel,
    toUser: config.rocketChatUserTarget,
    message: config.rocketChatMessage
  )
  discard context.postRocketChat()

proc notify*() =
  if config.useMail:
    try: notifiyViaMail() except: logApiError(nameMail, getCurrentExceptionMsg())
  if config.useDesktop:
    try: notifyViaDbus() except: logApiError(nameDbus, getCurrentExceptionMsg())
  if config.useMattermost:
    try: notifyViaMattermost() except: logApiError(nameMattermost, getCurrentExceptionMsg())
  if config.useMatrix:
    try: notifyViaMatrix() except: logApiError(nameMatrix, getCurrentExceptionMsg())
  if config.useRocketChat:
    try: notifyViaRocketChat() except: logApiError(nameRocketChat, getCurrentExceptionMsg())