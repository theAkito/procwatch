from options import Option

type
  ContextMessageAddMode* = enum
    APPEND, PREPEND
  ContextMessage* = ref object
    mode*: ContextMessageAddMode
    text*: string
  Context* = ref object of RootObj
    ctxMessage*: Option[ContextMessage]