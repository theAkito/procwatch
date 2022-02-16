## https://gotify.net/api-docs

import
  ../meta,
  json,
  options,
  strutils,
  apiutils,
  os,
  logging,
  pkg/[
    puppy
  ]

type
  GotifyDefect * = object of Defect

  GotifyContext * = ref object
    url      * : string
    token    * : string # appToken
    title    * : string
    message  * : string
    priority * : int64
    extras   * : JsonNode

  GotifyMsgPostReq = ref object
    title    : string
    message  : string
    priority : int64
    extras   : JsonNode

  GotifyMsgPostRes = ref object
    id       : int64
    appid    : int64
    date     : string
    message  : string
    title    : Option[string]
    priority : Option[int64]
    extras   : Option[JsonNode]

const
  exceptMsgMsgPostErrorParse = "Unable to post a message due to JSON parsing error!"
  exceptMsgMsgPostErrorAPI = "Unable to post a message due to an API error!"
  apiPathMsgCreate = "/message"
  apiHeaderNameToken = "X-Gotify-Key"

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameGotify & logMsgSuffix)

func genApiUrlMsg(ctx: GotifyContext): string = ctx.url.normalizePathEnd(); ctx.url & apiPathMsgCreate
func genApiHeaders(ctx: GotifyContext): seq[Header] = @[Header(key: apiHeaderNameToken, value: ctx.token), Header(key: "Content-type", value: "application/json")]
func genGotifyMsgPostReq(ctx: GotifyContext): GotifyMsgPostReq =
  GotifyMsgPostReq(
    title: ctx.title,
    message: ctx.message,
    priority: ctx.priority,
    extras: ctx.extras
  )
func genRequest(ctx: GotifyContext): Request =
  Request(
    url: parseUrl(ctx.genApiUrlMsg()),
    verb: "post",
    headers: ctx.genApiHeaders(),
    body: $ %* ctx.genGotifyMsgPostReq()
  )

proc apiMsgCreate(ctx: GotifyContext): GotifyMsgPostRes =
  logger.log(lvlDebug, pretty(%* ctx))
  let
    req = ctx.genRequest()
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise GotifyDefect.newException(exceptMsgMsgPostErrorParse)
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raise GotifyDefect.newException(exceptMsgMsgPostErrorAPI)
  jResp.to(GotifyMsgPostRes)

proc postGotify*(ctx: GotifyContext): bool = ctx.apiMsgCreate().id != 0