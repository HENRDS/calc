import ./lex, ./vm, std/tables, ./err

type
  Compiler = object
    lex: Lexer
    chunk: Chunk
    prev, cur: Token
    panic, hadError: bool
  Precedence = enum
    prNone, prAdd, prMul, prPow, prUnary, prPrimary
  ParserRuleFn = proc(c: var Compiler): void
  ParserRule = ref object
    prefix, infix: ParserRuleFn
    precedence: Precedence



proc advance(c: var Compiler)=
  c.prev = c.cur
  c.cur = c.lex.nextToken()
  while c.cur.isNil() and not c.lex.isAtEnd():
    c.cur = c.lex.nextToken()

proc initCompiler*(code: string): Compiler =
  result = Compiler(lex: initLexer(code), chunk: newChunk())
  result.advance()

proc errAt(c: var Compiler, m: string, t: Token)=
  if c.panic:
    return
  c.panic = true
  c.hadError = true
  err(m, t.pos)


proc err(c: var Compiler, m: string)=
  c.errAt(m, c.prev)

proc match(c: var Compiler, tk: TokenKind): bool = 
  result = false 
  if c.cur.kind == tk:
    c.advance()
    result = true

proc consume(c: var Compiler, t: TokenKind, m: string)=
  if not c.match(t):
    c.errAt(m, c.cur)

proc parsePrecedence(c: var Compiler, prec: Precedence)
proc getRule(k: TokenKind): ParserRule
proc compile(c: var Compiler, prec: Precedence)

proc literal(c: var Compiler)=
  case c.prev.kind
  of tokNum: 
    let idx = c.chunk.addConstant(c.prev.val)
    c.chunk.emit(opConst, idx)     
  else:
    discard

proc unary(c: var Compiler)=
  let op = c.prev.kind
  c.parsePrecedence(prUnary)
  case op
  of tokMinus:
    c.chunk.emit(opNegate)
  else:
    return

proc binary(c: var Compiler)=
  let 
    op = c.prev.kind
    rule = getRule(op)

  c.parsePrecedence(succ(rule.precedence))
  case op
  of tokPlus:
    c.chunk.emit(opAdd)
  of tokMinus:
    c.chunk.emit(opSub)
  of tokStar:
    c.chunk.emit(opMul)
  of tokSlash:
    c.chunk.emit(opDiv)
  else:
    return


proc grouping(c: var Compiler)=
  c.compile(prAdd)
  c.consume(tokRParen, "Expected ')' after expression")


let rules = {
    tokLParen: ParserRule(prefix: grouping, infix: nil, precedence: prNone),
    tokNum: ParserRule(prefix: literal, infix: nil, precedence: prNone),
    tokPlus: ParserRule(prefix: unary, infix: binary, precedence: prAdd),
    tokMinus: ParserRule(prefix: unary, infix: binary, precedence: prAdd),
    tokStar: ParserRule(prefix: nil, infix: binary, precedence: prMul),
    tokSlash: ParserRule(prefix: nil, infix: binary, precedence: prMul),
    tokRParen: ParserRule(prefix: nil, infix: nil, precedence: prNone),
    tokEof: ParserRule(prefix: nil, infix: nil, precedence: prNone),

  }.toTable()



proc getRule(k: TokenKind): ParserRule = 
  rules[k]

proc parsePrecedence(c: var Compiler, prec: Precedence)=
  c.advance()
  let fn = getRule(c.prev.kind).prefix
  if fn.isNil():
    c.err("Expected expression")
    return
  fn(c)
  while prec <= getRule(c.cur.kind).precedence:
    c.advance()
    let fn = getRule(c.prev.kind).infix
    if (fn.isNil()):
      c.err("Invalid rule")
    else:
      fn(c)


proc compile(c: var Compiler, prec: Precedence)=
  c.parsePrecedence(prec)

proc compile*(c: var Compiler): Chunk =
  c.compile(prAdd)
  if c.hadError:
    nil
  else:
    c.chunk.emit(opRet)
    c.chunk
