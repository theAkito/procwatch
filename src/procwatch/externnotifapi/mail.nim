import
  ../meta,
  std/[
    json,
    with,
    strutils,
    logging
  ],
  pkg/[
    smtp
  ]

type
  MailContext * = ref object
    nameSender            *: string
    username              *: string
    password              *: string
    subject               *: string
    message               *: string
    portOutgoing          *: int
    smtpServerOutgoing    *: string
    addressSource         *: string
    addressTarget         *: seq[string]

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameMail & logMsgSuffix)

proc sendMail*(ctx: MailContext) =
  logger.log(lvlDebug, pretty(%* ctx))
  let
    nameSender         : string      = ctx.nameSender
    username           : string      = ctx.username
    password           : string      = ctx.password
    subject            : string      = ctx.subject
    message            : string      = ctx.message
    portOutgoing       : Port        = ctx.portOutgoing.Port
    smtpOutgoing       : string      = ctx.smtpServerOutgoing
    mailAddressSource  : string      = ctx.addressSource
    mailAddressTarget  : seq[string] = ctx.addressTarget
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
