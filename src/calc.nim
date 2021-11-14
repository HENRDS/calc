import ./lex, ./parse, ./interp, os
  
proc main()=  
  for arg in commandLineParams():    
    let tokens = tokenize(arg)
    var parser = newParser(tokens)
    let expression = parser.parse()
    echo $eval(expression)


when isMainModule:
  main()