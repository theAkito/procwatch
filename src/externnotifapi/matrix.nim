## https://matrix.org/docs/guides/client-server-api
## https://ma1uta.github.io/spec/client_server/unstable.html

import
  ../meta,
  json,
  strutils,
  sequtils,
  apiutils,
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
  exceptMsgPasswordLoginUnsupported = "This Matrix instance does not support login by username and password!"
  exceptMsgPasswordLoginError = "Error occured when trying to log into Matrix instance!"
  exceptMsgSendMsgError = "Error occured when trying to send message in Matrix room!"
  apiPathLogin = "/_matrix/client/r0/login"
  flowTypeLogin = "m.login.password"
  eventTypeMsg = "m.room.message"
  msgTypeText = "m.text"

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameMatrix & logMsgSuffix)

func genApiLoginURL(baseURL: string): string = baseURL & apiPathLogin
func genApiMsgSendPath(roomID, token: string): string = r"/_matrix/client/r0/rooms/$#/send/$#?access_token=$#" % [roomID, eventTypeMsg, token]
template raiseGeneric(msg: untyped) = raise MatrixDefect.newException(msg)
template raiseMalformedURL() = raise MatrixDefect.newException(exceptMsgMalformedURL)

proc apiLogin(ctx: MatrixContext): MatrixLoginRes =
  ctx.url.normalizePathEnd()
  let
    urlApiLogin = parseUrl(genApiLoginURL(ctx.url))
    reqPrep = Request(
      url: urlApiLogin,
      verb: "get"
    )
    req = Request(
      url: urlApiLogin,
      verb: "post",
      body: $(%* MatrixLoginReq(
        `type`: flowTypeLogin,
        user: ctx.username,
        password: ctx.password
      ))
    )
    respPrep = reqPrep.fetch()
    respPrepCode = respPrep.code
    jRespPrep =
      try: respPrep.body.parseJson()
      except: raiseMalformedURL()
    successPrep = try: jRespPrep["flows"].getElems().anyIt(it.fields["type"].getStr() == flowTypeLogin) except: false
  if successPrep and respPrepCode.is20x():
    logger.log(lvlDebug, jRespPrep.pretty)
  else:
    logger.log(lvlError, jRespPrep.pretty)
    raiseGeneric(exceptMsgPasswordLoginUnsupported)
  let
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raiseMalformedURL()
  if respCode.is20x():
    logger.log(lvlDebug, jResp.pretty)
  else:
    logger.log(lvlError, jResp.pretty)
    raiseGeneric(exceptMsgPasswordLoginError)
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
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raiseMalformedURL()
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raiseGeneric(exceptMsgSendMsgError)
  jResp.to(MatrixMsgRes)

proc postMatrix*(ctx: MatrixContext): bool = apiMsgSend(ctx, apiLogin(ctx)).event_id != ""