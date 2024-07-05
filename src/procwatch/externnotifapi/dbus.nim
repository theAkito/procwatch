import
  ../meta,
  ../model/[
    context
  ],
  json,
  logging,
  notification

type
  DBusContext * = ref object of Context
    nameApp               *: string
    summary               *: string
    message               *: string
    nameIcon              *: string
    timeout               *: int32

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameDbus & logMsgSuffix)

proc broadcastDbus*(ctx: DBusContext) =
  logger.log(lvlDebug, pretty(%* ctx))
  var notification = initNotification(
    summary = ctx.summary,
    body    = ctx.message,
    icon    = ctx.nameIcon,
    timeout = initTimeout(ctx.timeout)
  )
  notification.add Hint(kind: hkUrgency, urgency: Normal)
  discard notification.notify()