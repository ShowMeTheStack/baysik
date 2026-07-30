' ============================================================
' TITLE:    Infix to Postfix Calculator
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     stack, shunting-yard, postfix, RPN, expression evaluation, parsing
' SUMMARY:  Converts expressions like 3+4*(2-1)^2 to postfix with Dijkstra's shunting-yard algorithm, then evaluates them with a stack, step by step.
' ------------------------------------------------------------
' WHAT IT DOES
'   We write maths in INFIX form: the operator sits IN between,
'   like 3 + 4. Computers prefer POSTFIX (also called Reverse
'   Polish Notation): 3 4 +. Postfix needs no brackets and no
'   precedence rules - just a stack.
'
'   Step 1 - SHUNTING YARD (Edsger Dijkstra, 1961): numbers go
'   straight to the output; operators wait on an OPERATOR STACK
'   until an operator with lower precedence (or a closing bracket)
'   pushes them out. A table shows every token and decision.
'
'   Step 2 - EVALUATE: read the postfix left to right. A number is
'   pushed on a VALUE STACK. An operator pops two values, applies
'   itself and pushes the result. The final value is the answer.
'
' HOW TO USE
'   Type an expression using numbers, + - * / ^ and brackets,
'   e.g.  (1+2)*3^2/4  . Blank line quits.
'
' CONCEPTS YOU WILL LEARN
'   * Two different uses of a stack in one program
'   * Operator precedence and associativity (^ is right-assoc.)
'   * Tokenising a string into numbers and symbols
'   * Error checks: mismatched brackets, missing operands
'
' THINGS TO TRY
'   * Add the MOD operator as %
'   * Support unary minus, like -3 + 5 (hint: treat it as 0 - 3)
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Prec% (op$)
DECLARE FUNCTION StackStr$ ()

CONST MAXT = 60
DIM SHARED ops$(1 TO MAXT), nops          ' operator stack
DIM tok$(1 TO MAXT), post$(1 TO MAXT)
DIM vals#(1 TO MAXT)                      ' value stack (double precision)

CLS
PRINT "INFIX -> POSTFIX -> ANSWER   (numbers, + - * / ^ and brackets)"
DO
    PRINT
    LINE INPUT "Expression (blank = quit): "; e$
    IF e$ = "" OR UCASE$(e$) = "Q" THEN EXIT DO
    bad$ = ""

    ' ---- Tokenise: split into numbers and single-char symbols ---
    nt = 0: i = 1
    DO WHILE i <= LEN(e$) AND bad$ = ""
        c$ = MID$(e$, i, 1)
        IF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN
            num$ = ""
            DO WHILE i <= LEN(e$)
                c$ = MID$(e$, i, 1)
                IF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN num$ = num$ + c$: i = i + 1 ELSE EXIT DO
            LOOP
            nt = nt + 1: tok$(nt) = num$
        ELSEIF INSTR("+-*/^()", c$) THEN
            nt = nt + 1: tok$(nt) = c$: i = i + 1
        ELSEIF c$ = " " THEN
            i = i + 1
        ELSE
            bad$ = "Unexpected character '" + c$ + "'"
        END IF
        IF nt >= MAXT THEN bad$ = "Expression too long"
    LOOP

    ' ---- Shunting yard -----------------------------------------
    IF bad$ = "" THEN
        PRINT
        PRINT "token  action                    operator stack   output"
        PRINT "-----  ------------------------  --------------   ------"
        nops = 0: np = 0: pf$ = ""
        FOR t = 1 TO nt
            tk$ = tok$(t)
            SELECT CASE tk$
            CASE "("
                nops = nops + 1: ops$(nops) = tk$: act$ = "push ("
            CASE ")"
                ' pop operators to output until the matching "("
                act$ = "pop until ("
                DO WHILE nops > 0
                    IF ops$(nops) = "(" THEN EXIT DO
                    np = np + 1: post$(np) = ops$(nops): nops = nops - 1
                    pf$ = pf$ + post$(np) + " "
                LOOP
                IF nops = 0 THEN bad$ = "Missing (": EXIT FOR
                nops = nops - 1                       ' throw away the "("
            CASE "+", "-", "*", "/", "^"
                act$ = "push " + tk$
                ' Pop operators that must be done FIRST: higher
                ' precedence, or equal precedence and left-assoc.
                ' ^ is right-associative: 2^3^2 = 2^(3^2).
                DO WHILE nops > 0
                    top$ = ops$(nops)
                    IF top$ = "(" THEN EXIT DO
                    IF Prec%(top$) > Prec%(tk$) OR (Prec%(top$) = Prec%(tk$) AND tk$ <> "^") THEN
                        np = np + 1: post$(np) = top$: nops = nops - 1
                        pf$ = pf$ + top$ + " "
                        act$ = "pop " + top$ + ", push " + tk$
                    ELSE
                        EXIT DO
                    END IF
                LOOP
                nops = nops + 1: ops$(nops) = tk$
            CASE ELSE
                act$ = "number -> output"
                np = np + 1: post$(np) = tk$: pf$ = pf$ + tk$ + " "
            END SELECT
            PRINT LEFT$(tk$ + SPACE$(7), 7); LEFT$(act$ + SPACE$(26), 26); LEFT$(StackStr$ + SPACE$(17), 17); RIGHT$(pf$, 24)
        NEXT t
        ' Anything left on the stack goes to the output.
        DO WHILE nops > 0 AND bad$ = ""
            IF ops$(nops) = "(" THEN bad$ = "Missing )": EXIT DO
            np = np + 1: post$(np) = ops$(nops): nops = nops - 1
            pf$ = pf$ + post$(np) + " "
        LOOP
    END IF

    ' ---- Evaluate the postfix with a value stack ---------------
    IF bad$ = "" THEN
        PRINT : PRINT "POSTFIX: "; pf$
        PRINT : PRINT "Evaluating:"
        nv = 0
        FOR t = 1 TO np
            p$ = post$(t)
            IF INSTR("+-*/^", p$) THEN
                IF nv < 2 THEN bad$ = "Missing a number near " + p$: EXIT FOR
                b# = vals#(nv): a# = vals#(nv - 1): nv = nv - 2
                SELECT CASE p$
                CASE "+": r# = a# + b#
                CASE "-": r# = a# - b#
                CASE "*": r# = a# * b#
                CASE "/"
                    IF b# = 0 THEN bad$ = "Division by zero": EXIT FOR
                    r# = a# / b#
                CASE "^"
                    IF a# < 0 AND b# <> INT(b#) THEN bad$ = "Bad power": EXIT FOR
                    r# = a# ^ b#
                END SELECT
                nv = nv + 1: vals#(nv) = r#
                PRINT "  "; p$; ": pop"; b#; "and"; a#; "-> push"; r#
            ELSE
                nv = nv + 1: vals#(nv) = VAL(p$)
                PRINT "  push"; vals#(nv)
            END IF
        NEXT t
        IF bad$ = "" AND nv <> 1 THEN bad$ = "Too many numbers (missing an operator?)"
        IF bad$ = "" THEN COLOR 14: PRINT : PRINT "ANSWER ="; vals#(1): COLOR 7
    END IF
    IF bad$ <> "" THEN COLOR 12: PRINT "Error: "; bad$: COLOR 7
LOOP
PRINT "Bye!"
END

' Prec%: bigger number = binds tighter.
FUNCTION Prec% (op$)
    SELECT CASE op$
    CASE "+", "-": Prec% = 1
    CASE "*", "/": Prec% = 2
    CASE "^": Prec% = 3
    CASE ELSE: Prec% = 0
    END SELECT
END FUNCTION

' StackStr$: the operator stack as text, bottom on the left.
FUNCTION StackStr$
    s$ = ""
    FOR i = 1 TO nops: s$ = s$ + ops$(i): NEXT i
    StackStr$ = s$
END FUNCTION
