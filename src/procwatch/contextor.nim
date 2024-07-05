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
  ctx.ctxMessage = ContextMessage(
    mode: APPEND,
    text: config.getContextMaster.message
  ).some
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
  ctx.message = case ctx.ctxMessage.get.mode
    of APPEND:
      ctx.message & lineEnd.repeat(2) & ctx.ctxMessage.get.text
    of PREPEND:
      ctx.ctxMessage.get.text & lineEnd.repeat(2) & ctx.message
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