import
  strutils

func is20x*(code: int): bool = code.intToStr().startsWith("20")