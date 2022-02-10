import
  ../meta,
  json,
  strutils,
  os,
  logging,
  puppy

type
  MattermostContext* = ref object
    url          * : string      # Example: http://localhost:8065/api/v4
    loginID      * : string      # Only necessary, if using a temporary session token, instead of a voluntarily permanent Bearer token.
    password     * : string      # Only necessary, if using a temporary session token, instead of a voluntarily permanent Bearer token.
    token        * : string
    channelID    * : string
    message      * : string
    rootID       * : string      # Optional
    fileIDs      * : seq[string] # Optional
    properties   * : JsonNode    # Optional

let logger = newConsoleLogger(lvlInfo, "[$levelname]:[$datetime] ~ ")

proc postMattermost*(ctx: MattermostContext): bool =
  ctx.url.normalizePathEnd()
  let
    req = Request(
      url: parseUrl(ctx.url & "/posts"),
      verb: "post",
      headers: @[Header(key: "Authorization", value: "Bearer " & ctx.token)],
      body: "{ \"channel_id\": \"$#\", \"message\": \"$#\", \"root_id\": \"$#\", \"file_ids\": \"$#\", \"props\": \"$#\" }" % [ctx.channelID, ctx.message, ctx.rootID, $(% ctx.fileIDs), $ctx.properties]
    )
    resp = req.fetch()
    respCode = $resp.code
  logger.log(lvlDebug, resp.body.parseJson().pretty)
  respCode.startsWith("20")