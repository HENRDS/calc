import ./lex, ./compiler, ./vm, os, std/sequtils
  
proc main()=  
  for arg in commandLineParams():  
    var compiler = initCompiler(arg)
    let chunk = compiler.compile()
    var vm = initVm(chunk)
    vm.run()
    


when isMainModule:
  main()