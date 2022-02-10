import
  meta,
  configurator,
  externnotifapi/mattermost,
  std/[
    smtp,
    with,
    strutils
  ],
  notification

let
  nameSender: string = config.mailNameSender
  username: string = config.mailUsername
  password: string = config.mailPassword
  subject: string = config.mailSubject
  message: string = config.mailMessage
  portOutgoing: Port = config.mailPortOutgoing.Port
  smtpOutgoing: string = config.mailSmtpServerOutgoing
  mailAddressSource: string = config.mailAddressSource
  mailAddressTarget: string = config.mailAddressTarget

proc notifiyViaMail*() =
  let
    msg = createMessage(
      subject,
      message,
      @[mailAddressTarget], #[Addressee]#
      @[], #[CC]#
      @[ #[Headers]#
        ("From", "$# <$#>" % [nameSender, mailAddressSource])
      ]
    )
    smtpConn = newSmtp(debug = debug)
  with smtpConn:
    connect(smtpOutgoing, portOutgoing)
    startTls()
    auth(username, password)
    sendMail(mailAddressSource, @[mailAddressTarget], $msg)

proc notifyViaDbus*() =
  var notification = initNotification(
    summary = config.dbusSummary,
    body = config.dbusMessage,
    icon = config.dbusNameIcon,
    timeout = initTimeout(config.dbusTimeout)
  )
  notification.add Hint(kind: hkUrgency, urgency: Normal)
  discard notification.notify()

proc notifyViaMattermost*() =
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