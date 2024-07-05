import
  os,
  logging,
  parseopt,
  strutils,
  sequtils,
  times,
  timestamp,
  procwatch/[
    meta,
    notifier,
    configurator
  ]

proc getDefaultTime(): DateTime
proc isProkRunningLive(): bool
proc areProksRunningsLive(): bool

type
  ProcessNotFoundError = object of OSError

  ProcStatus = ref object
    peak: string
    size: string
    hwm : string
    rss : string

  Proc = ref object
    pid: int
    name: string
    pathCmd: string
    running: bool
    start: DateTime
    finish: DateTime
    status: ProcStatus

const
  pidUnassigned = -1
  pidsInvalid = [ pidUnassigned, 0 ]

let
  logger = newConsoleLogger(defineLogLevel(), logMsgPrefix & logMsgInter & "master" & logMsgSuffix)
  prok: Proc = Proc(
    pid: pidUnassigned,
    start: getDefaultTime()
  )

var
  configPath: string = meta.configPath
  pidsRunning: seq[int] = @[]
  pidsFoundByName: seq[int] = @[]
  proksFoundByName: seq[Proc] = @[]

func basename(path: string): string =
  let pathSplit = path.split(DirSep)
  pathSplit[pathSplit.high]

func basenamePid(path: string): int =
  try: basename(path).parseInt
  except ValueError: pidUnassigned

proc getDefaultTime(): DateTime = initTimeStamp(0).toDateTime
proc constructPathPid(pid: int): string = dirProc.joinPath($pid)
proc constructPathPid(): string = constructPathPid(prok.pid)
proc isProkRunning(): bool = prok.running
proc readPathCmd(pid: int): string =
  try: constructPathPid(pid).joinPath("cmdline").readFile except: ""
proc readCmdName(pid: int): string =
  try: constructPathPid(pid).joinPath("comm").readFile except: ""
proc waitForProkSingle() =
  while isProkRunningLive(): waitPoll()
proc waitForProksMulti() =
  while areProksRunningsLive(): waitPoll()

proc showHelp() =
  echo "Check out the Usage Guide: "
  echo "https://github.com/theAkito/procwatch/wiki/Usage-Guide"

proc setOpts() =
  for kind, key, val in commandLineParams().getopt():
    case kind
      of cmdArgument:
        try:
          prok.pid = key.parseInt
        except ValueError:
          prok.name = key
      of cmdLongOption, cmdShortOption:
        case key
          of "p", "pid":
            prok.pid = val.parseInt
          of "c", "config":
            configPath = val
          of "h", "help":
            showHelp()
      of cmdEnd: assert(false)

proc isInputValid(): bool =
  if prok.pid == pidUnassigned or prok.name == "": false else: true

proc findPidsByName(name: string): seq[int] =
  for pid in pidsRunning:
    var cmd = pid.readCmdName()
    cmd.stripLineEnd()
    if cmd == name: result.add pid

proc readProcCreationTime(pid: int): DateTime = 
  try: constructPathPid(pid).open(fmRead).getFileInfo().creationTime.toTimestamp().toDateTime()
  except: getDefaultTime()

proc getDurationText(duration: Duration): string =
  let
    inHours = duration.inHours
    inMinutes = duration.inMinutes
    inSeconds = duration.inSeconds
    txtTimePassed = "Time passed until process(es) finished: "
    txtH = "h "
    txtM = "m "
    charS = 's'
  if inHours <= 0:
    if inMinutes > 0:
      txtTimePassed & $inMinutes & txtM & $(inSeconds mod 60) & charS
    else:
      txtTimePassed & $inSeconds & charS
  else:
    txtTimePassed & $inHours & txtH & $(inMinutes mod 60) & txtM & $(inSeconds mod 60) & charS

proc getProkInfos(pids: seq[int]): seq[Proc] =
  for pid in pids:
    let
      prokRunning = constructPathPid(pid).dirExists
      itProc = Proc(
        pid: pid,
        name: prok.name,
        pathCmd: readPathCmd(pid),
        running: prokRunning,
        start: readProcCreationTime(pid),
        finish: if not prokRunning: now() else: getDefaultTime()
      )
    result.add itProc

proc setProkInfo(fresh: bool #[Set to `true` when running this proc for the first time.]#) =
  try:
    if prok.name != "" and prok.pid == pidUnassigned:
      pidsFoundByName = findPidsByName(prok.name)
    if pidsFoundByName.len != 0:
      proksFoundByName = getProkInfos(pidsFoundByName)
      return
    if prok.name == "" and prok.pid != pidUnassigned: prok.name = readCmdName(prok.pid)
    let pathPid = constructPathPid()
    prok.running = pathPid.dirExists
    if not prok.running and not fresh: prok.finish = now(); return
    if not isInputValid(): raise ProcessNotFoundError.newException("Command could not be detected, because neither a process name nor a process PID was provided or matched. Please, make sure, you provide a valid PID or process name of a program, that is running right now.")
    if prok.pathCmd == "": prok.pathCmd = readPathCmd(prok.pid)
    if prok.running and prok.start == getDefaultTime(): prok.start = readProcCreationTime(prok.pid)
  except ProcessNotFoundError:
    raise getCurrentException()
  except:
    logger.log(lvlError, getCurrentExceptionMsg())
    prok.finish = now()

proc readRunningPids(): seq[int] =
  for kind, path in dirProc.walkDir:
    case kind
      of pcDir:
        var pid: int
        try:
          pid = path.basenamePid()
        except ValueError:
          continue
        if not pidsInvalid.anyIt(it == pid): result.add pid
      else: continue

proc isProkRunningLive(): bool = readRunningPids().contains(prok.pid)

proc areProksRunningsLive(): bool =
  if proksFoundByName.len == 0: return false
  pidsRunning = readRunningPids()
  #[
    As long as at least one process with the provided name
    is still running, we are not finished, yet.
    All processes of the same name have to be finished,
    before calling it a day.
  ]#
  pidsFoundByName.anyIt(pidsRunning.contains(it))

proc run() =
  #[ Manifest command line options. ]#
  setOpts()
  #[ Initialise configuration file. ]#
  if not initConf(configPath): raise OSError.newException("Config file could neither be found nor generated!")
  #[ Discover running processes by PID in /proc. ]#
  pidsRunning = readRunningPids()
  #[ Gather data regarding selected process. ]#
  try:
    setProkInfo(true)
  except:
    logger.log(lvlError, getCurrentExceptionMsg())
    showHelp()
    quit(2)
  let proksFoundByNameAreAvailable = proksFoundByName.len != 0
  #[ Find out, if a single process or a process group is being watched by name. ]#
  if proksFoundByNameAreAvailable:
    logger.log(lvlDebug, "Proks found by name are available.")
  elif not isProkRunning():
    logger.log(lvlError, "Process with pid $# and name $# is not running!" % [$prok.pid, prok.name])
    quit(3)
  #[ Record time at which process watching started. ]#
  let timeStart = now()
  if proksFoundByNameAreAvailable:
    #[ Multiple processes are being watched by name. ]#
    waitForProksMulti()
  else:
    #[ A single process is being watched by PID. ]#
    waitForProkSingle()
  #[ Record duration of how long process watching took. ]#
  let durationText = getDurationText(now() - timeStart)
  #[ Log duration of how long process watching took. ]#
  logger.log lvlNotice, durationText
  #[ Append time passed text to message body. ]#
  config.getContextMaster.message = durationText
  #[ Watching ended, which means the processes finished executing. Time to notify the configured targets. ]#
  notify()

when isMainModule: run()
