import std/[parseutils, strutils]

type
  TokenKind* = enum
    tokNum, tokPlus, tokMinus, tokStar, tokSlash, tokErr,
    tokLParen, tokRParen, tokEof
  
  Token* = ref object
    pos*: Natural
    case kind*: TokenKind
    of tokNum:
      val*: float
    of tokErr:
      message*: string
    else:
      discard

  Lexer* = object
    bufPos: int
    buf: string

const 
  WhitespaceChars = {' ', '\t', '\v', '\f', '\c', '\n' }

proc pointToToken*(L: Lexer, tk: Token)=
  echo L.buf
  echo repeat(' ', tk.pos) & "^"
proc initLexer*(code: string): Lexer =
  Lexer(bufPos: 0, buf: code)

proc `$`*(t: Token): string =
  case t.kind:
  of tokNum:
    "<" & $t.kind & " " & $t.val & ">"
  of tokErr:
    "<" & $t.kind & " " & t.message & ">"
  else:
    "<" & $t.kind & ">"

template isAtEnd*(L: Lexer): bool =
  L.bufPos >= len(L.buf)
  
template current(L: Lexer): char = 
  L.buf[L.bufPos]

proc parseNum(L: var Lexer): Token =
  var fval: float = 0.0
  let x: int = parseFloat(L.buf, fval, L.bufPos)
  result = Token(kind: tokNum, val: fval, pos: L.bufPos)
  inc(L.bufPos, x)

proc skipWhitespace(L: var Lexer)=
  while not L.isAtEnd and L.current() in WhitespaceChars:
    inc(L.bufPos)

proc nextToken*(L: var Lexer): Token =
  L.skipWhitespace()

  if L.isAtEnd():
    return Token(kind: tokEof, pos: L.bufPos)

  case L.current()
  of '+': 
    result = Token(kind: tokPlus, pos: L.bufPos)
    inc(L.bufPos)
  of '-': 
    result = Token(kind: tokMinus, pos: L.bufPos)
    inc(L.bufPos)
  of '*': 
    result = Token(kind: tokStar, pos: L.bufPos)
    inc(L.bufPos)
  of '/': 
    result = Token(kind: tokSlash, pos: L.bufPos)
    inc(L.bufPos)
  of '(':
    result = Token(kind:tokLParen, pos: L.bufPos)
    inc(L.bufPos)
  of ')':
    result = Token(kind:tokRParen, pos: L.bufPos)
    inc(L.bufPos)
  of '0'..'9': 
    result = L.parseNum()
  else:
    let cur = L.current()
    result = Token(kind: tokErr, message: "Invalid token '" & cur & "'", pos: L.bufPos)
    inc(L.bufPos)

proc tokenize*(code: string): seq[Token] =
  result = newSeq[Token]()
  var lexer = initLexer(code)
  while not lexer.isAtEnd():
    let tk = lexer.nextToken()
    if not tk.isNil():
      result.add(tk)
