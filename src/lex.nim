import parseutils

type
  TokenKind* = enum
    tokNum, tokPlus, tokMinus, tokStar, tokSlash, tokPercent, tokErr,
    tokLParen, tokRParen
  
  Token* = ref object
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
   

proc newLexer*(code: string): Lexer =
  Lexer(bufPos: 0, buf: code)

proc `$`*(t: Token): string =
  case t.kind:
  of tokNum:
    "<" & $t.kind & " " & $t.val & ">"
  of tokErr:
    "<" & $t.kind & " " & t.message & ">"
  else:
    "<" & $t.kind & ">"

template isAtEnd(l: Lexer): bool =
  l.bufPos >= len(l.buf)
  

template current(l: Lexer): char = 
  l.buf[l.bufPos]

template advance(l: var Lexer) =
  l.bufPos += 1
  

proc tryParseNum(l: var Lexer): Token =
  var fval: float = 0.0
  let x: int = parseFloat(l.buf, fval, l.bufPos)

  if x == 0:
    nil
  else:
    l.bufPos += x
    Token(kind: tokNum, val: fval)

proc nextToken(l: var Lexer): Token =
  case l.current
  of '+': 
    l.advance()
    Token(kind: tokPlus)
  of '-': 
    l.advance()
    Token(kind: tokMinus)
  of '*': 
    l.advance()
    Token(kind: tokStar)
  of '/': 
    l.advance()
    Token(kind: tokSlash)
  of '%': 
    l.advance()
    Token(kind: tokPercent)
  of '(':
    l.advance()
    Token(kind:tokLParen)
  of ')':
    l.advance()
    Token(kind:tokRParen)
  of '0'..'9': 
    l.tryParseNum()
  of ' ', '\t', '\c', '\n':
    l.advance()
    nil
  else:
    let cur = l.current
    l.advance()
    Token(kind: tokErr, message: "Invalid token '" & cur & "'")

proc tokenize*(code: string): seq[Token] =
  result = newSeq[Token]()
  var lexer = newLexer(code)
  while not lexer.isAtEnd():
    let tk = lexer.nextToken()
    if not tk.isNil():
      result.add(tk)
