import
  meta,
  json,
  base64,
  os,
  logging,
  strutils

type
  ProcwatchConfig = object
    version                   *: string
    intervalPoll              *: int
    useMail                   *: bool
    useDesktop                *: bool
    useMattermost             *: bool
    useMatrix                 *: bool
    useRocketChat             *: bool
    useRevoltChat             *: bool
    useMumble                 *: bool
    mailNameSender            *: string
    mailUsername              *: string
    mailPassword              *: string
    mailSubject               *: string
    mailMessage               *: string
    mailPortOutgoing          *: int
    mailSmtpServerOutgoing    *: string
    mailAddressSource         *: string
    mailAddressTarget         *: seq[string]
    dbusNameApp               *: string
    dbusSummary               *: string
    dbusMessage               *: string
    dbusNameIcon              *: string
    dbusTimeout               *: int32
    mattermostURL             *: string
    mattermostLoginID         *: string
    mattermostPassword        *: string
    mattermostToken           *: string
    mattermostChannelID       *: string
    mattermostMessage         *: string
    mattermostRootID          *: string
    mattermostFileIDs         *: seq[string]
    mattermostProperties      *: JsonNode
    matrixURL                 *: string
    matrixUsername            *: string
    matrixPassword            *: string
    matrixRoomID              *: string
    matrixMessage             *: string
    rocketChatURL             *: string
    rocketChatUserID          *: string
    rocketChatToken           *: string
    rocketChatRoomID          *: string
    rocketChatChannel         *: string
    rocketChatUserTarget      *: string
    rocketChatMessage         *: string
    debug                     *: bool

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "configurator" & logMsgSuffix)

var config* = ProcwatchConfig(
  version: appVersion,
  intervalPoll: 5_000,
  mailPortOutgoing: 587,
  dbusNameApp: "Process Watcher",
  dbusSummary: "Process Finished",
  dbusMessage: "Watched process finished executing.",
  dbusTimeout: 15_000,
  dbusNameIcon: "help-faq",
  mattermostURL: "https://mattermost.com",
  mattermostProperties: parseJson("{}"),
  matrixURL: "https://matrix.org",
  matrixMessage: "Process Finished",
  debug: meta.debug
)

func pretty(node: JsonNode): string = node.pretty(configIndentation)

func genPathFull(path, name: string): string =
  if path != "": path.normalizePathEnd() & '/' & name else: name

proc getConfig*(): ProcwatchConfig = config

proc genDefaultConfig(path = configPath, name = configName): JsonNode =
  let
    pathFull = path.genPathFull(name)
    conf = %* config
  pathFull.writeFile(conf.pretty())
  conf

proc initConf*(path = configPath, name = configName): bool =
  let
    pathFull = path.genPathFull(name)
    configAlreadyExists = pathFull.fileExists
  if configAlreadyExists:
    logger.log(lvlDebug, "Config already exists! Not generating new one.")
    config = pathFull.parseFile().to(ProcwatchConfig)
    config.mailPassword = config.mailPassword.decode()
    config.mattermostPassword = config.mattermostPassword.decode()
    config.matrixPassword = config.matrixPassword.decode()
    return true
  try:
    genDefaultConfig(path, name)
  except:
    return false
  true