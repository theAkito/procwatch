import
  strutils
from puppy import Header

const
  exceptMsgMsgPostErrorParse* = "Unable to post a message due to JSON parsing error!"
  exceptMsgMsgPostErrorAPI* = "Unable to post a message due to an API error!"
  headerJson* = Header(key: "Content-type", value: "application/json")

func is20x*(code: int): bool = code.intToStr().startsWith("20")