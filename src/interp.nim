import ./parse

proc eval*(e: Expr): float =
    case e.kind
    of ekTerm:
        e.val.val
    of ekGroup:
        eval(e.sub)
    of ekUnary:
        case e.unaryOp:
        of uokNegative:
            -eval(e.unaryOperand)
        of uokPositive:
            +eval(e.unaryOperand)
    of ekBinary:
        let lhs = eval(e.lhs)
        let rhs = eval(e.rhs)
        case e.binOp:
        of bokAdd:
            lhs + rhs
        of bokSub:
            lhs - rhs
        of bokMul:
            lhs * rhs
        of bokDiv:
            lhs / rhs

