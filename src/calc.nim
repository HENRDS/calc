import ./compiler, ./vm, std/[parseopt, terminal, strformat]

type Args = tuple[exprs: seq[string], disasm: bool]

proc run(s: string, disasm: bool)=
  var compiler = initCompiler(s)
  let chunk = compiler.compile()
  if disasm:
    styledEcho(styleBright, fmt"--DISASM '{s}'--", resetStyle)
    chunk.disassemble()
    styledEcho("\n", styleBright, "RESULT:", resetStyle)
  var vm = initVm(chunk)
  vm.run()

proc usage()=
  styledEcho(styleBright, "Usage:", resetStyle)
  echo "  calc [OPTION] [EXPR]..."
  echo "Optional arguments:"
  styledEcho(styleBright, "    -d --disasm", resetStyle, 
             "  Disassemble expression instructions before executing")
  styledEcho(styleBright, "      -h --help", resetStyle,
             "  Show this help and exit")

proc parseCliArgs(): Args = 
  var 
    p = initOptParser(shortNoVal= {'d', 'h'}, longNoVal= @["disasm", "help"])
    exprs = newSeq[string]()
    disasm = false
  for kind, key, val in p.getopt():
    case kind
    of cmdEnd:
      doAssert(false)
    of cmdArgument:
      exprs.add(key)
    of cmdLongOption, cmdShortOption:
      case key
      of "d", "disasm":
        disasm = true
      of "h", "help":
        usage()
        quit()
      else:
        styledEcho(fgRed, fmt"Invalid argument {key} {val}", resetStyle)
        quit(1)
  (exprs: exprs, disasm: disasm)

proc main()=  
  let args = parseCliArgs()

  for arg in args.exprs:  
    run(arg, args.disasm)
    


when isMainModule:
  main()