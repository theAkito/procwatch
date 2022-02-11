## https://matrix.org/docs/guides/client-server-api
## https://ma1uta.github.io/spec/client_server/unstable.html

import
  ../meta,
  json,
  strutils,
  sequtils,
  os,
  logging,
  pkg/[
    puppy
  ]
from tables import `[]`

type
  MatrixDefect * = object of Defect

  MatrixContext * = ref object
    url      * : string
    username * : string
    password * : string
    roomID   * : string
    message  * : string

  MatrixLoginReq = ref object
    `type`: string
    user: string
    password: string

  MatrixLoginRes = ref object
    access_token: string
    home_server: string
    user_id: string

  MatrixMsgReq = ref object
    msgtype: string
    body: string

  MatrixMsgRes = ref object
    event_id: string

const
  exceptMsgMalformedURL = "Malformed URL or wrong URL queries provided!"
  apiPathLogin = "/_matrix/client/r0/login"
  flowTypeLogin = "m.login.password"
  eventTypeMsg = "m.room.message"
  msgTypeText = "m.text"

let logger = newConsoleLogger(lvlInfo, "[$levelname]:[$datetime] ~ ")

func is20x(code: string): bool = code.startsWith("20")
func genApiMsgSendPath(roomID, token: string): string = r"/_matrix/client/r0/rooms/!$#/send/$#?access_token=$#" % [roomID, eventTypeMsg, token]
template raiseGeneric(msg: untyped) = raise MatrixDefect.newException(msg)
template raiseMalformedURL() = raise MatrixDefect.newException(exceptMsgMalformedURL)

proc apiLogin(ctx: MatrixContext): MatrixLoginRes =
  ctx.url.normalizePathEnd()
  let
    reqPrep = Request(
      url: parseUrl(ctx.url & apiPathLogin),
      verb: "get"
    )
    req = Request(
      url: parseUrl(ctx.url & apiPathLogin),
      verb: "post",
      body: $(%* MatrixLoginReq(
        `type`: flowTypeLogin,
        user: ctx.username,
        password: ctx.password
      ))
    )
    respPrep = reqPrep.fetch()
    respPrepCode = $respPrep.code
    jRespPrep =
      try: respPrep.body.parseJson()
      except: raiseMalformedURL()
    successPrep = jRespPrep["flows"].getElems().anyIt(it.fields["type"].getStr() == flowTypeLogin)
  if successPrep and respPrepCode.is20x():
    logger.log(lvlDebug, jRespPrep.pretty)
  else:
    logger.log(lvlError, jRespPrep.pretty)
    raiseGeneric("This Matrix instance does not support login by username and password!")
  let
    resp = req.fetch()
    respCode = $resp.code
    jResp =
      try: resp.body.parseJson()
      except: raiseMalformedURL()
  if respCode.is20x():
    logger.log(lvlDebug, jResp.pretty)
  else:
    logger.log(lvlError, jResp.pretty)
    raiseGeneric("Error occured when trying to log into Matrix instance!")
  jResp.to(MatrixLoginRes)

proc apiMsgSend(ctx: MatrixContext, login: MatrixLoginRes): MatrixMsgRes =
  ctx.url.normalizePathEnd()
  let
    req = Request(
      url: parseUrl(ctx.url & genApiMsgSendPath(ctx.roomID, login.access_token)),
      verb: "post",
      body: $(%* MatrixMsgReq(
        msgtype: msgTypeText,
        body: ctx.message
      ))
    )
    resp = req.fetch()
    respCode = $resp.code
    jResp =
      try: resp.body.parseJson()
      except: raiseMalformedURL()
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raiseGeneric("Error occured when trying to send message in Matrix room!")
  jResp.to(MatrixMsgRes)

proc postMatrix*(ctx: MatrixContext): bool = apiMsgSend(ctx, apiLogin(ctx)).event_id != ""