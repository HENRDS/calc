import ./lex, ./parse
proc main()=  
  let tokens = tokenize("2 + 2")
  var parser = newParser(tokens)
  let expression = parser.parse()
  echo $expression

when isMainModule:
  main()