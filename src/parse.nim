import ./lex, std/strformat, std/options
type
  ParseError = object of Exception
  BinaryOpKind* = enum
    bokAdd, bokSub, bokMul, bokDiv, bokMod
  
  UnaryOpKind* = enum
    uokPositive, uokNegative
  
  ExprKind* = enum
    ekTerm, ekBinary, ekUnary, ekGroup

  Expr* {.acyclic.} = ref object 
    case kind: ExprKind
    of ekBinary:
      binOp*: BinaryOpKind
      lhs*, rhs*: Expr
    of ekUnary:
      unaryOp*: UnaryOpKind
      unaryOperand*: Expr
    of ekTerm:
      val*: Token
    of ekGroup:
      sub*: Expr
      
  Parser* = object
    tokens: seq[Token]
    tkPos: int

proc newParser*(tks: seq[Token]): Parser =
  Parser(tokens: tks, tkPos: 0)

template isAtEnd(p: Parser): bool = 
  p.tkPos >= p.tokens.len()
    

template current(p: Parser): Token = 
  if p.isAtEnd():
    p.tokens[p.tokens.len() - 1]
  else:
    p.tokens[p.tkPos]

template advance(p: Parser) =
  p.tkPos += 1

    

proc match(p: var Parser, options: varargs[TokenKind]): bool =
  for option in options: 
    if p.current.kind == option:
      p.advance()
      return true
  return false

proc check(p: var Parser, options: varargs[TokenKind]): bool =
  for option in options:
    if p.current.kind == option:
      return true
  return false

proc consume(p: var Parser, kind: TokenKind)=
  if p.current.kind == kind:
    p.advance()
  raise newException(ParseError, fmt"Expected {kind} but got {p.current.kind}")

proc expression(p: var Parser): Expr

proc term(p: var Parser): Expr =
  if p.match(tokLParen):
    let sub = p.expression()
    p.consume(tokRParen)
    return Expr(kind: ekGroup, sub: sub)
  
  if p.check(tokNum):
    let t = Expr(kind: ekTerm, val: p.current)
    p.advance()
    return t
  
  raise newException(ParseError, fmt"Expected expression but got {p.current.kind}")

proc unary(p: var Parser): Expr =
  case p.current.kind
  of tokMinus:
    p.advance()
    let operand = p.unary()
    Expr(kind: ekUnary, unaryOp: uokNegative, unaryOperand: operand)
  of tokPlus:
    p.advance()
    let operand = p.unary()
    Expr(kind: ekUnary, unaryOp: uokPositive, unaryOperand: operand)
  else:
    p.term()

proc mul(p: var Parser): Expr =
  var lhs = p.unary()
  while p.check(tokStar, tokSlash, tokPercent):
    let op = 
      case p.current.kind:
        of tokStar:
          bokMul
        of tokSlash:
          bokDiv
        else:
          bokMod

    p.advance()
    let rhs = p.unary()
    lhs = Expr(kind: ekBinary, binOp: op, lhs: lhs, rhs: rhs) 
  lhs
      

proc add(p: var Parser): Expr=
  var lhs = p.mul()
  while p.check(tokPlus, tokMinus):
    let op = 
      case p.current.kind:
        of tokPlus:
          bokAdd
        else:
          bokSub

    p.advance()
    let rhs = p.mul()
    lhs = Expr(kind: ekBinary, binOp: op, lhs: lhs, rhs: rhs) 
  lhs


proc expression(p: var Parser): Expr =
  p.add()

proc parse*(p: var Parser): Expr =
  p.expression()

proc `$`*(e: Expr): string = 
  case e.kind:
  of ekTerm:
    $e.val
  of ekGroup:
    fmt"({$e.sub})"
  of ekBinary:
    let op = 
      case e.binOp
      of bokAdd: "+"
      of bokSub: "-"
      of bokMul: "*"
      of bokDiv: "/"
      of bokMod: "%"

    fmt"{e.lhs}{op}{e.rhs}"
  of ekUnary:
    let op =
      case e.unaryOp
      of uokPositive: "+"
      of uokNegative: "-"
    fmt"{op}{e.unaryOperand}"
