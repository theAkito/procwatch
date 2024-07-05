## https://api.mattermost.com/#operation/CreatePost

import
  ../meta,
  ../model/[
    context
  ],
  json,
  strutils,
  apiutils,
  os,
  logging,
  puppy

type
  MattermostDefect = object of Defect

  MattermostContext* = ref object of Context
    url          * : string      # Example: http://localhost:8065/api/v4
    loginID      * : string      # Only necessary, if using a temporary session token, instead of a voluntarily permanent Bearer token.
    password     * : string      # Only necessary, if using a temporary session token, instead of a voluntarily permanent Bearer token.
    token        * : string
    channelID    * : string
    message      * : string
    rootID       * : string      # Optional
    fileIDs      * : seq[string] # Optional
    properties   * : JsonNode    # Optional

const apiPathRoot = "/api/v4"

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & nameMattermost & logMsgSuffix)

func appendApiPathRoot(baseUrl: string): string =
  if not baseUrl.endsWith("apiPathRoot"): baseUrl.normalizePathEnd() & apiPathRoot else: baseUrl
func prepApiUrl(ctx: MattermostContext) = ctx.url = appendApiPathRoot(ctx.url)

proc apiMsgPost(ctx: MattermostContext): JsonNode =
  ctx.prepApiUrl()
  logger.log(lvlDebug, pretty(%* ctx))
  let
    req = Request(
      url: parseUrl(ctx.url & "/posts"),
      verb: "post",
      headers: @[Header(key: "Authorization", value: "Bearer " & ctx.token), headerJson],
      body: "{ \"channel_id\": \"$#\", \"message\": \"$#\", \"root_id\": \"$#\", \"file_ids\": \"$#\", \"props\": \"$#\" }" % [ctx.channelID, ctx.message, ctx.rootID, $(% ctx.fileIDs), $ctx.properties]
    )
    resp = req.fetch()
    respCode = resp.code
    jResp =
      try: resp.body.parseJson()
      except: raise MattermostDefect.newException("Unable to post a message due to JSON parsing error!")
    respBody = jResp.pretty
  if respCode.is20x():
    logger.log(lvlDebug, respBody)
  else:
    logger.log(lvlError, respBody)
    raise MattermostDefect.newException("Unable to post a message due to an API error!")
  jResp

proc postMattermost*(ctx: MattermostContext): bool = apiMsgPost(ctx){"status_code"} == nil