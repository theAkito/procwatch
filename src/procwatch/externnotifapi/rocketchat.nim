## https://developer.rocket.chat/reference/api/rest-api/endpoints/other-important-endpoints/access-tokens-endpoints
## https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/chat-endpoints/postmessage

##[
  With the token in hand you can add in the header X-Auth-Token along with your user id X-User-Id of the request that is made to the REST API.
]##

import
  ../meta,
  json,
  options,
  strutils,
  apiutils,
  os,
  logging,
  strtabs,
  pkg/[
    puppy
  ]
from tables import `[]`

type
  RocketChatDefect * = object of Defect

  RocketChatContext * = ref object
    url      * : string
    token    * : string
    userID   * : string
    roomID   * : string
    channel  * : string # Posted in channel, if `toUser` is not provided.
    toUser   * : string # Overrides channel.
    message  * : string

  RocketChatMsgPostReq = ref object
    ## https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/chat-endpoints/postmessage#payload
    roomId           : Option[string]
    channel          : Option[string]
    text             : Option[string]
    alias            : Option[string]
    emoji            : Option[string]
    avatar           : Option[string]
    attachments      : Option[JsonNode] ## https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/chat-endpoints/postmessage#attachments-detail

  RocketChatMsgPostRes = ref object
    ## https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/chat-endpoints/postmessage#example-result
    ts               : int
    channel          : string
    message          : JsonNode
    success          : bool

  RocketChatRoomsGetRes = ref object
    ## https://developer.rocket.chat/reference/api/rest-api/endpoints/team-collaboration-endpoints/rooms-endpoints/get-rooms#example-result
    update           : JsonNode

const
  exceptMsgRoomsGetErrorParse = "Unable to retrieve Rooms from Server due to a JSON parsing error!"
  exceptMsgRoomsGetErrorAPI = "Unable to retrieve Rooms from Server due to an API error!"
  exceptMsgMsgPostErrorParse = "Unable to post a message due to JSON parsing error!"
  exceptMsgMsgPostErrorAPI = "Unable to post a message due to an API error!"
  apiTypePrefixUser = "@"
  apiTypePrefixChannel = "#"
  apiPathRoomsGet = "/api/v1/rooms.get"
  apiPathMsgPost = "/api/v1/chat.postMessage"

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameRocketChat & logMsgSuffix)

func genApiLoginHeaders(userID, token: string): seq[Header] = @[Header(key: "X-User-Id", value: userID), Header(key: "X-Auth-Token", value: token), Header(key: "Content-type", value: "application/json")]
func genRecipient(ctx: RocketChatContext): string =
  if not ctx.toUser.isEmptyOrWhitespace(): apiTypePrefixUser & ctx.toUser
  elif not ctx.channel.isEmptyOrWhitespace(): apiTypePrefixChannel & ctx.channel
  else: ctx.roomID
func genRocketChatMsgPostReq(ctx: RocketChatContext): RocketChatMsgPostReq =
  let recipient = genRecipient(ctx)
  if recipient.startsWith(apiTypePrefixUser) or recipient.startsWith(apiTypePrefixChannel):
    RocketChatMsgPostReq(
      channel: recipient.some,
      text: ctx.message.some
    )
  else:
    RocketChatMsgPostReq(
      roomId: recipient.some,
      text: ctx.message.some
    )
func genRequest(ctx: RocketChatContext, apiPath: string): Request =
  Request(
    url: parseUrl(ctx.url & apiPath),
    verb: if apiPath == apiPathMsgPost: "post" else: "get",
    headers: genApiLoginHeaders(ctx.userID, ctx.token),
    body: $ %* genRocketChatMsgPostReq(ctx)
  )

proc getNameToRoomID(src: RocketChatRoomsGetRes): owned(StringTableRef) =
  result = newStringTable(modeCaseInsensitive)
  let rooms = src.update.getElems()
  for room in rooms:
    let name = try: room.fields["name"].getStr() except: continue
    try: result[name] = room.fields["_id"].getStr() except: continue

proc apiRoomsGet(ctx: RocketChatContext): RocketChatRoomsGetRes =
  ctx.url.normalizePathEnd()
  let
    req = genRequest(ctx, apiPathRoomsGet)
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise RocketChatDefect.newException(exceptMsgRoomsGetErrorParse)
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raise RocketChatDefect.newException(exceptMsgRoomsGetErrorAPI)
  jResp.to(RocketChatRoomsGetRes)

proc apiMsgPost(ctx: RocketChatContext): RocketChatMsgPostRes =
  ctx.url.normalizePathEnd()
  logger.log(lvlDebug, pretty(%* ctx))
  let
    req = genRequest(ctx, apiPathMsgPost)
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise RocketChatDefect.newException(exceptMsgMsgPostErrorParse)
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raise RocketChatDefect.newException(exceptMsgMsgPostErrorAPI)
  jResp.to(RocketChatMsgPostRes)

proc postRocketChat*(ctx: RocketChatContext): bool =
  ctx.roomID = if ctx.roomID.isEmptyOrWhitespace(): apiRoomsGet(ctx).getNameToRoomID()[ctx.channel] else: ctx.roomID
  apiMsgPost(ctx).success