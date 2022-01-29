import std/strformat, std/sugar

type 
  Opcode* = enum
    opConst, opNegate, opAdd, opSub, opMul, opDiv, opRet
  Chunk* = ref object
    code*: seq[uint8]
    constants*: seq[float]
  Vm* = object
    chunk: Chunk
    stack: seq[float]
    ip: int

proc initVm*(c: Chunk): Vm=
  Vm(chunk: c, stack: newSeq[float](), ip:0)

proc newChunk*(): Chunk =
  Chunk(
    code: newSeq[uint8](), 
    constants: newSeq[float]()
  )

proc emit*(c: Chunk, op: Opcode, args: varargs[uint8]) =
  c.code.add(op.uint8)
  for a in args:
    c.code.add(a)

proc addConstant*(c: Chunk, val: float): uint8 =
  if c.constants.len() == 255:
    raise newException(OverflowDefect, "Too many constants")
  c.constants.add(val)
  (c.constants.len() - 1).uint8

proc pop(vm: var Vm): float =
  vm.stack.pop()

proc push(vm: var Vm, val: float)=
  vm.stack.add(val)

template binary(vm: var Vm, op: (float, float)->float)=
  let 
    x = vm.pop()
    y = vm.pop()
  vm.push(op(x, y))

proc run*(vm: var Vm)=
  while true:
    try:
      let instr = Opcode(vm.chunk.code[vm.ip])
      inc(vm.ip)
      case instr
      of opAdd:
        vm.binary(`+`)
      of opSub:
        vm.binary(`-`)
      of opMul:
        vm.binary(`*`)
      of opDiv:
        vm.binary(`/`)
      of opNegate:
        let x = vm.pop()
        vm.push(-x)
      of opConst:
        let x = vm.chunk.constants[vm.chunk.code[vm.ip]]
        vm.push(x)
        inc(vm.ip)
      of opRet:
        let x = vm.pop()
        echo $x
        break
    except RangeDefect:
      echo fmt"Invalid opcode {vm.chunk.code[vm.ip]:X}"


proc disassembleInstruction(c: Chunk, offset: var int)=
  try:
    stdout.write(fmt"{offset:04} ")
    let instr = Opcode(c.code[offset])
    case instr
    of opAdd:
      echo "OP_ADD"
    of opSub:
      echo "OP_SUB"
    of opMul:
      echo "OP_MUL"
    of opDiv:
      echo "OP_DIV"
    of opNegate:
      echo "OP_NEGATE"
    of opRet:
      echo "OP_RET"
    of opConst:
      inc(offset)
      let constant = c.constants[c.code[offset]]
      echo "OP_CONST " & $constant
    inc(offset)    
  except RangeDefect:
    echo "Invalid instruction"

proc disassemble*(c: Chunk)=
  var offset = 0
  while offset < c.code.len(): 
    c.disassembleInstruction(offset)
