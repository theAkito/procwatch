import
  meta,
  configurator,
  model/[
    context
  ]

from std/strutils import repeat
from externnotifapi/mail import MailContext
from externnotifapi/dbus import DBusContext
from externnotifapi/mattermost import MattermostContext
from externnotifapi/matrix import MatrixContext
from externnotifapi/rocketchat import RocketChatContext
from externnotifapi/gotify import GotifyContext

from options import some

proc applyContext*(ctx:
  MailContext or
  DBusContext or
  MattermostContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext
): MattermostContext or
  MailContext or
  DBusContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext =
  for msg in config.getContextMaster.messages:
    if ctx.ctxMessage.isNone:
      ctx.ctxMessage = some @[ContextMessage()]
      ctx.ctxMessage.get.del(0)
    ctx.ctxMessage.get &= msg
  ctx

proc applyContextMessage*(ctx:
  MailContext or
  DBusContext or
  MattermostContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext
): MattermostContext or
  MailContext or
  DBusContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext =
  for msg in config.getContextMaster.messages:
    ctx.message = case msg.mode
      of APPEND:
        ctx.message & lineEnd.repeat(2) & msg.text
      of PREPEND:
        msg.text & lineEnd.repeat(2) & ctx.message
  result = ctx

proc applyCtx*(ctx:
  MailContext or
  DBusContext or
  MattermostContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext
): MattermostContext or
  MailContext or
  DBusContext or
  MatrixContext or
  RocketChatContext or
  GotifyContext =
  ctx.applyContext.applyContextMessage