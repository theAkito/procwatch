import
  meta,
  json,
  base64,
  os,
  logging,
  strutils
from externnotifapi/mail import MailContext
from externnotifapi/dbus import DBusContext
from externnotifapi/mattermost import MattermostContext
from externnotifapi/matrix import MatrixContext
from externnotifapi/rocketchat import RocketChatContext

type
  MasterConfig = object
    version                   *: string
    intervalPoll              *: int
    useMail                   *: bool
    useDesktop                *: bool
    useMattermost             *: bool
    useMatrix                 *: bool
    useRocketChat             *: bool
    useRevoltChat             *: bool
    useMumble                 *: bool
    mail                      *: MailContext
    dbus                      *: DBusContext
    mattermost                *: MattermostContext
    matrix                    *: MatrixContext
    rocketchat                *: RocketChatContext
    debug                     *: bool

let logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "configurator" & logMsgSuffix)

var
  mailContext = MailContext(
    message: defaultMsg,
    portOutgoing: 587
  )
  dbusContext = DBusContext(
    nameApp: "Process Watcher",
    summary: defaultMsg,
    message: "Watched process finished executing.",
    timeout: 15_000,
    nameIcon: "help-faq",
  )
  mattermostContext = MattermostContext(
    url: "https://mattermost.com",
    message: defaultMsg,
    properties: parseJson("{}"),
  )
  matrixContext = MatrixContext(
    url: "https://matrix.org",
    message: defaultMsg,
  )
  rocketChatContext = RocketChatContext(
    url: "https://example.rocket.chat",
    message: defaultMsg
  )
  config* = MasterConfig(
    version: appVersion,
    intervalPoll: 5_000,
    mail: mailContext,
    dbus: dbusContext,
    mattermost: mattermostContext,
    matrix: matrixContext,
    rocketchat: rocketChatContext,
    debug: meta.debug
  )

func pretty(node: JsonNode): string = node.pretty(configIndentation)

func genPathFull(path, name: string): string =
  if path != "": path.normalizePathEnd() & '/' & name else: name

proc getConfig*(): MasterConfig = config

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
    config = pathFull.parseFile().to(MasterConfig)
    config.mail.password = config.mail.password.decode()
    config.mattermost.password = config.mattermost.password.decode()
    config.matrix.password = config.matrix.password.decode()
    return true
  try:
    genDefaultConfig(path, name)
  except:
    return false
  true