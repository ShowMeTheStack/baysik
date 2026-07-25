' ============================================================
' TITLE:    Calculator Parser
' CATEGORY: Strings & Text Processing
' LEVEL:    Advanced
' TAGS:     recursive descent, parsing, grammar, recursion, expressions
' SUMMARY:  Evaluates typed expressions like 2*(3+4)^2 - sqr(16) with a hand-written recursive descent parser.
' ------------------------------------------------------------
' WHAT IT DOES
'   You type a maths expression as text; the program reads it
'   character by character and works out the answer, obeying the
'   usual precedence rules (brackets, then powers, then * and /,
'   then + and -).  It supports:
'       numbers  3   4.5   .25
'       + - * / ^ ( )    unary minus  -(2+3)
'       functions  sqr  abs  sin  cos  int
'       variables  ans (the previous answer)  pi
'   Errors such as "2+*3" or "(1+2" are caught and a little arrow
'   shows WHERE the problem is.
'
' HOW TO USE
'   Type an expression and press Enter.  Empty line or Q quits.
'   Try:  1+2*3   (1+2)*3   2^3^2   -3^2   sqr(2)*sqr(2)   ans/2
'
' CONCEPTS YOU WILL LEARN
'   * A GRAMMAR, written as rules that call each other:
'        expr   = term   { (+|-) term }
'        term   = unary  { (*|/) unary }
'        unary  = - unary | + unary | power
'        power  = primary [ ^ unary ]         (right-associative!)
'        primary= number | name | name(expr) | ( expr )
'   * Recursive FUNCTIONs: Expr calls Term calls ... calls Expr
'   * A shared "cursor" position into the input string
'   * Error handling without crashing (an error flag)
'
' THINGS TO TRY
'   * Add the MOD operator at the same level as * and /
'   * Add variables you can assign: x = 5
'   * Add functions with two arguments: max(3, 7)
' ============================================================

DECLARE FUNCTION Expr# ()
DECLARE FUNCTION Term# ()
DECLARE FUNCTION Power# ()
DECLARE FUNCTION Unary# ()
DECLARE FUNCTION Primary# ()
DECLARE FUNCTION NextCh$ ()
DECLARE SUB Fail (msg$)

' src$  = the text being parsed      p   = cursor (next char)
' errMsg$ = "" while all is well     ans = previous answer
DIM SHARED src$, p, errMsg$, errPos, ans#

CLS
COLOR 14: PRINT "CALCULATOR PARSER  (recursive descent)": COLOR 7
PRINT "Operators + - * / ^ ( )   functions sqr abs sin cos int   names pi ans"
PRINT
DO
    LINE INPUT "calc> "; s$
    IF s$ = "" OR UCASE$(s$) = "Q" THEN EXIT DO
    src$ = LCASE$(s$): p = 1: errMsg$ = ""
    v# = Expr#
    ' after a full expression there must be nothing left over
    IF errMsg$ = "" AND NextCh$ <> "" THEN Fail "unexpected '" + NextCh$ + "'"
    IF errMsg$ = "" THEN
        ans# = v#
        COLOR 10: PRINT "  = "; v#: COLOR 7
    ELSE
        ' the arrow lines up under the input (after "calc> ")
        COLOR 12
        PRINT SPACE$(5 + errPos); "^"
        PRINT "  Error: "; errMsg$
        COLOR 7
    END IF
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' NextCh$: skip spaces and return the next character WITHOUT
' consuming it ("" at the end of the input).
' ------------------------------------------------------------
FUNCTION NextCh$
    DO WHILE MID$(src$, p, 1) = " "
        p = p + 1
    LOOP
    NextCh$ = MID$(src$, p, 1)
END FUNCTION

' Fail: remember only the FIRST error and where it happened.
SUB Fail (msg$)
    IF errMsg$ = "" THEN errMsg$ = msg$: errPos = p
END SUB

' expr = term { (+|-) term }   -- lowest precedence
FUNCTION Expr#
    v# = Term#
    DO WHILE errMsg$ = ""
        op$ = NextCh$
        IF op$ = "+" THEN
            p = p + 1: v# = v# + Term#
        ELSEIF op$ = "-" THEN
            p = p + 1: v# = v# - Term#
        ELSE
            EXIT DO
        END IF
    LOOP
    Expr# = v#
END FUNCTION

' term = unary { (*|/) unary }
FUNCTION Term#
    v# = Unary#
    DO WHILE errMsg$ = ""
        op$ = NextCh$
        IF op$ = "*" THEN
            p = p + 1: v# = v# * Unary#
        ELSEIF op$ = "/" THEN
            p = p + 1
            d# = Unary#
            IF d# = 0 THEN Fail "division by zero": EXIT DO
            v# = v# / d#
        ELSE
            EXIT DO
        END IF
    LOOP
    Term# = v#
END FUNCTION

' ------------------------------------------------------------
' power = primary [ ^ unary ]
' The right side is parsed with Unary#, which can come back here
' to Power# again, so ^ groups to the RIGHT: 2^3^2 = 2^(3^2) = 512.
' Because unary minus sits ABOVE power in the grammar, -3^2 means
' -(3^2) = -9, exactly as QBasic itself does it.  2^-1 works too.
' ------------------------------------------------------------
FUNCTION Power#
    b# = Primary#
    IF errMsg$ = "" AND NextCh$ = "^" THEN
        p = p + 1
        e# = Unary#
        IF errMsg$ = "" THEN
            IF b# < 0 AND e# <> INT(e#) THEN
                Fail "negative number to a fractional power"
            ELSEIF b# = 0 AND e# < 0 THEN
                Fail "zero to a negative power"
            ELSE
                b# = b# ^ e#
            END IF
        END IF
    END IF
    Power# = b#
END FUNCTION

' unary = - unary | + unary | power
' (Unary# calling Unary# is recursion: "--5" is -(-(5)).)
FUNCTION Unary#
    c$ = NextCh$
    IF c$ = "-" THEN
        p = p + 1: Unary# = -Unary#
    ELSEIF c$ = "+" THEN
        p = p + 1: Unary# = Unary#
    ELSE
        Unary# = Power#
    END IF
END FUNCTION

' ------------------------------------------------------------
' primary = number | ( expr ) | name | name ( expr )
' ------------------------------------------------------------
FUNCTION Primary#
    Primary# = 0
    c$ = NextCh$
    IF c$ = "" THEN Fail "expression ended too soon": EXIT FUNCTION
    IF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN
        ' --- number: grab digits and at most one "." ---
        st = p: dots = 0
        DO
            c$ = MID$(src$, p, 1)
            IF c$ = "." THEN dots = dots + 1 ELSE IF c$ < "0" OR c$ > "9" OR c$ = "" THEN EXIT DO
            IF dots > 1 THEN Fail "too many decimal points": EXIT FUNCTION
            p = p + 1
        LOOP
        Primary# = VAL(MID$(src$, st, p - st))
    ELSEIF c$ = "(" THEN
        p = p + 1
        v# = Expr#
        IF errMsg$ <> "" THEN EXIT FUNCTION
        IF NextCh$ <> ")" THEN Fail "missing )": EXIT FUNCTION
        p = p + 1
        Primary# = v#
    ELSEIF c$ >= "a" AND c$ <= "z" THEN
        ' --- a name: read letters ---
        st = p
        DO WHILE MID$(src$, p, 1) >= "a" AND MID$(src$, p, 1) <= "z"
            p = p + 1
        LOOP
        nm$ = MID$(src$, st, p - st)
        IF nm$ = "pi" THEN Primary# = 4 * ATN(1#): EXIT FUNCTION
        IF nm$ = "ans" THEN Primary# = ans#: EXIT FUNCTION
        ' otherwise it must be a function followed by (expr)
        IF INSTR(" sqr abs sin cos int ", " " + nm$ + " ") = 0 THEN
            p = st: Fail "unknown name '" + nm$ + "'": EXIT FUNCTION
        END IF
        IF NextCh$ <> "(" THEN Fail "( expected after " + nm$: EXIT FUNCTION
        p = p + 1
        a# = Expr#
        IF errMsg$ <> "" THEN EXIT FUNCTION
        IF NextCh$ <> ")" THEN Fail "missing )": EXIT FUNCTION
        p = p + 1
        SELECT CASE nm$
            CASE "sqr"
                IF a# < 0 THEN Fail "sqr of a negative number": EXIT FUNCTION
                Primary# = SQR(a#)
            CASE "abs": Primary# = ABS(a#)
            CASE "sin": Primary# = SIN(a#)
            CASE "cos": Primary# = COS(a#)
            CASE "int": Primary# = INT(a#)
        END SELECT
    ELSE
        Fail "unexpected '" + c$ + "'"
    END IF
END FUNCTION
