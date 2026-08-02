' ============================================================
' TITLE:    Recursive Descent Calculator
' CATEGORY: Recursion & Debugging
' LEVEL:    Advanced
' TAGS:     recursion, parser, grammar, expressions, calculator, mutual recursion
' SUMMARY:  A real calculator that understands + - * / ^, parentheses and unary minus, built from four mutually recursive functions.
' ------------------------------------------------------------
' WHAT IT DOES
'   Type an expression like  2 + 3 * (4 - 1) ^ 2  and it is
'   evaluated with correct precedence.  The trick is a GRAMMAR where
'   each rule becomes one FUNCTION:
'
'     Expr   = Term   { (+ | -) Term }        lowest precedence
'     Term   = Power  { (* | /) Power }
'     Power  = Factor [ ^ Power ]              right-associative
'     Factor = number | ( Expr ) | - Factor    highest precedence
'
'   Factor calls Expr when it sees "(" - so the functions call each
'   other in a circle.  That is how nesting like ((1+2)*3) works.
'   With TRACE on, every function prints when it is entered, so you
'   can see the descent.
'
' HOW TO USE
'   Type an expression and press Enter.  Type T to toggle the trace.
'   Empty line quits.  Errors (like "2 + * 3") are reported nicely.
'
'   DEBUGGER TOUR
'   1. Type  2*(3+4).  Break on <<< BREAK FACTOR.  The CALL STACK
'      shows Expr -> Term -> Power -> Factor: precedence levels
'      appear as stack frames!
'   2. Continue until the "(" is seen.  Now the stack is
'      Expr Term Power Factor Expr Term Power Factor - the
'      parenthesised part runs a whole new Expr on top.
'   3. WATCH  p   and   MID$(src$, p)   to see how much of the input
'      is left at each moment.  p only ever moves forward.
'   4. Break on <<< BREAK ERROR, type  (1+2  and look at the stack
'      to see exactly which rule noticed the missing ")".
'
' CONCEPTS YOU WILL LEARN
'   * Grammars and recursive descent parsing (used in real compilers,
'     including the one that runs this program!)
'   * Mutual recursion across several functions
'   * Operator precedence and associativity
'   * Error handling with a SHARED error flag
'
' THINGS TO TRY
'   * Add the % (MOD) operator to Term.
'   * Add functions: if Factor sees letters "SQR(", parse an Expr and
'     return SQR of it.
'   * Add variables:  X = 5  then  X * 2.
' ============================================================
DECLARE FUNCTION ParseExpr# (lvl AS INTEGER)
DECLARE FUNCTION ParseTerm# (lvl AS INTEGER)
DECLARE FUNCTION ParsePower# (lvl AS INTEGER)
DECLARE FUNCTION ParseFactor# (lvl AS INTEGER)
DECLARE FUNCTION Peek$ ()
DECLARE SUB Fail (msg$)
DECLARE SUB Trace (lvl AS INTEGER, who$)

DIM SHARED src$        ' the text being parsed
DIM SHARED p AS INTEGER ' current position in src$
DIM SHARED errMsg$     ' "" means no error so far
DIM SHARED tracing AS INTEGER

CLS
PRINT "RECURSIVE DESCENT CALCULATOR   (T = toggle trace, Enter = quit)"
PRINT "Examples:  2+3*4    (2+3)*4    2^3^2    -(4-10)/3    1.5*(2+(3-1))"
PRINT
tracing = -1
DO
    LINE INPUT "> "; line$
    IF line$ = "" THEN EXIT DO
    IF UCASE$(line$) = "T" THEN
        tracing = NOT tracing
        IF tracing THEN PRINT "trace ON" ELSE PRINT "trace OFF"
    ELSE
        src$ = line$: p = 1: errMsg$ = ""
        v# = ParseExpr#(0)
        ' After a full expression there must be nothing left over.
        IF errMsg$ = "" AND Peek$ <> "" THEN Fail "unexpected '" + Peek$ + "'"
        IF errMsg$ = "" THEN
            PRINT "  = "; v#
        ELSE
            PRINT "  "; line$
            PRINT "  "; SPACE$(p - 1); "^ "; errMsg$
        END IF
    END IF
LOOP
PRINT "Bye!"
END

' Skip spaces and return the next character ("" at the end).
FUNCTION Peek$
    DO WHILE MID$(src$, p, 1) = " "
        p = p + 1
    LOOP
    Peek$ = MID$(src$, p, 1)
END FUNCTION

SUB Fail (msg$)
    ' Only remember the FIRST error; later ones are side effects.
    IF errMsg$ = "" THEN errMsg$ = msg$  ' <<< BREAK ERROR
END SUB

SUB Trace (lvl AS INTEGER, who$)
    IF tracing THEN PRINT "  "; SPACE$(lvl * 2); who$; "  at: "; MID$(src$, p)
END SUB

' Expr = Term { (+|-) Term }
FUNCTION ParseExpr# (lvl AS INTEGER)
    DIM v AS DOUBLE, op$
    Trace lvl, "Expr"
    v = ParseTerm#(lvl + 1)
    DO WHILE errMsg$ = ""
        op$ = Peek$
        IF op$ <> "+" AND op$ <> "-" THEN EXIT DO
        p = p + 1                         ' use up the operator
        IF op$ = "+" THEN v = v + ParseTerm#(lvl + 1) ELSE v = v - ParseTerm#(lvl + 1)
    LOOP
    ParseExpr# = v
END FUNCTION

' Term = Power { (*|/) Power }
FUNCTION ParseTerm# (lvl AS INTEGER)
    DIM v AS DOUBLE, op$, r AS DOUBLE
    Trace lvl, "Term"
    v = ParsePower#(lvl + 1)
    DO WHILE errMsg$ = ""
        op$ = Peek$
        IF op$ <> "*" AND op$ <> "/" THEN EXIT DO
        p = p + 1
        r = ParsePower#(lvl + 1)
        IF op$ = "*" THEN
            v = v * r
        ELSEIF r = 0 THEN
            Fail "division by zero"
        ELSE
            v = v / r
        END IF
    LOOP
    ParseTerm# = v
END FUNCTION

' Power = Factor [ ^ Power ]   (recursing on the RIGHT makes
' 2^3^2 = 2^(3^2) = 512, the way mathematicians read it)
FUNCTION ParsePower# (lvl AS INTEGER)
    DIM v AS DOUBLE, e AS DOUBLE
    Trace lvl, "Power"
    v = ParseFactor#(lvl + 1)
    IF errMsg$ = "" AND Peek$ = "^" THEN
        p = p + 1
        e = ParsePower#(lvl + 1)
        IF v < 0 AND e <> INT(e) THEN
            Fail "negative number to a fractional power"
        ELSEIF v = 0 AND e < 0 THEN
            Fail "zero to a negative power"
        ELSEIF errMsg$ = "" THEN
            v = v ^ e
        END IF
    END IF
    ParsePower# = v
END FUNCTION

' Factor = number | ( Expr ) | - Factor
FUNCTION ParseFactor# (lvl AS INTEGER)
    DIM ch$, start AS INTEGER
    Trace lvl, "Factor"
    ch$ = Peek$                           ' <<< BREAK FACTOR
    IF ch$ = "(" THEN
        p = p + 1
        ParseFactor# = ParseExpr#(lvl + 1)   ' the circle closes here!
        IF errMsg$ = "" THEN
            IF Peek$ = ")" THEN p = p + 1 ELSE Fail "missing )"
        END IF
    ELSEIF ch$ = "-" THEN
        p = p + 1
        ParseFactor# = -ParseFactor#(lvl + 1)  ' unary minus
    ELSEIF (ch$ >= "0" AND ch$ <= "9") OR ch$ = "." THEN
        start = p
        DO WHILE INSTR("0123456789.", MID$(src$, p, 1)) > 0 AND p <= LEN(src$)
            p = p + 1
        LOOP
        ParseFactor# = VAL(MID$(src$, start, p - start))
    ELSEIF ch$ = "" THEN
        Fail "expression ends too soon"
    ELSE
        Fail "expected a number or ("
    END IF
END FUNCTION
