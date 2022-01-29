import std/[terminal, strformat]


var hadErrorInternal = false


proc err*(msg: string, pos: Natural)=
  styledEcho(fgRed, fmt"{msg} at {pos}")
  hadErrorInternal = true

proc hadError*(): bool=
  hadErrorInternal