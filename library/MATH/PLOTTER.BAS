' ============================================================
' TITLE:    Function Plotter
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     graphs, parser, recursion, functions, WINDOW, zoom
' SUMMARY:  Type any formula like SIN(x)*x^2 and see its graph; zoom and pan with the keyboard.
' ------------------------------------------------------------
' WHAT IT DOES
'   You type a formula in x, for example   x^3 - 3*x   or
'   SIN(3*x) / x .  The program reads it with a small "recursive
'   descent parser" and translates it into Reverse Polish Notation
'   (RPN): a list of simple stack instructions.  x^3 - 3*x becomes
'        x  3  ^  3  x  *  -
'   Evaluating RPN is fast - push numbers, and each operator pops two
'   values and pushes the answer - so the program can calculate the
'   formula at every one of the 640 pixel columns very quickly.
'
' HOW TO USE
'   Type a formula.  Allowed:  + - * / ^  ( )  x  PI  numbers and
'   SIN COS TAN ATN SQR ABS LOG EXP INT.  Blank = a demo formula.
'   In the graph:  + / -  zoom in/out,  arrow keys (or W A S D) pan,
'   N  new formula,  Q or Esc  quit.
'
' CONCEPTS YOU WILL LEARN
'   * Grammar rules turned into recursive FUNCTIONs:
'       expr   = term   { (+|-) term }
'       term   = unary  { (*|/) unary }
'       unary  = - unary | power
'       power  = primary [ ^ unary ]     (right-associative)
'       primary= number | x | PI | name( expr ) | ( expr )
'   * Operator precedence: why 2+3*4 is 14, not 20
'   * Stack machines (RPN), like old HP calculators and the JVM
'   * WINDOW to map math coordinates to the screen
'
' THINGS TO TRY
'   * Plot SIN(x)/x near 0, or x*SIN(1/x)
'   * Add a second formula drawn in another colour
'   * Add more functions, like a parameter "a" changed with keys
' ============================================================

DECLARE SUB ParseExpr ()
DECLARE SUB ParseTerm ()
DECLARE SUB ParsePower ()
DECLARE SUB ParseUnary ()
DECLARE SUB ParsePrimary ()
DECLARE SUB Emit (op%, v#)
DECLARE SUB SkipSpaces ()
DECLARE FUNCTION Eval# (x#, ok%)

' The RPN "program":  op codes and number values.
CONST OPNUM = 1, OPX = 2, OPADD = 3, OPSUB = 4, OPMUL = 5, OPDIV = 6, OPPOW = 7, OPNEG = 8
CONST OPFN = 20                 ' 20 + function number (1..9)
DIM SHARED code(200) AS INTEGER, value(200) AS DOUBLE, ncode AS INTEGER
DIM SHARED src$, p AS INTEGER, perr AS STRING
DIM SHARED funcList$
funcList$ = "SIN COS TAN ATN SQR ABS LOG EXP INT "   ' each name 3 letters + space

DO
    ' ---------------- read and parse a formula ----------------
    SCREEN 0: WIDTH 80: CLS
    COLOR 14: PRINT "FUNCTION PLOTTER": COLOR 7
    PRINT "Examples:  x^3 - 3*x     SIN(3*x)/x     SQR(16 - x^2)     EXP(-x^2)"
    PRINT
    LINE INPUT "y = "; f$
    IF UCASE$(LTRIM$(f$)) = "Q" THEN EXIT DO
    IF LTRIM$(f$) = "" THEN f$ = "SIN(3*x) * EXP(-x^2/8) * 4"
    src$ = UCASE$(f$): p = 1: ncode = 0: perr = ""
    ParseExpr
    SkipSpaces
    IF perr = "" AND p <= LEN(src$) THEN perr = "unexpected '" + MID$(src$, p, 1) + "'"
    IF perr <> "" THEN
        COLOR 12: PRINT "Sorry: "; perr; " at position"; p: COLOR 7
        PRINT "Press a key...": k$ = INPUT$(1)
        GOTO NextFormula
    END IF
    ' Show the RPN translation - fun to see how the parser understood it.
    PRINT "RPN: ";
    FOR i = 1 TO ncode
        SELECT CASE code(i)
            CASE OPNUM: PRINT LTRIM$(STR$(value(i))); " ";
            CASE OPX: PRINT "x ";
            CASE OPADD: PRINT "+ ";
            CASE OPSUB: PRINT "- ";
            CASE OPMUL: PRINT "* ";
            CASE OPDIV: PRINT "/ ";
            CASE OPPOW: PRINT "^ ";
            CASE OPNEG: PRINT "neg ";
            CASE ELSE: PRINT MID$(funcList$, (code(i) - OPFN - 1) * 4 + 1, 3); " ";
        END SELECT
    NEXT i
    PRINT : PRINT : PRINT "Press a key to plot..."
    k$ = INPUT$(1)

    ' ---------------- plot, zoom and pan ----------------
    cx# = 0: cy# = 0: span# = 10            ' centre and half-width of view
    SCREEN 12
    DO
        x1# = cx# - span#: x2# = cx# + span#
        y1# = cy# - span# * .75: y2# = cy# + span# * .75   ' 4:3 screen
        CLS
        WINDOW (x1#, y1#)-(x2#, y2#)
        ' Grid lines at a "nice" spacing: a power of 10 near span/5.
        g# = 10 ^ INT(LOG(span# / 2) / LOG(10))
        FOR gx# = INT(x1# / g#) * g# TO x2# STEP g#
            LINE (gx#, y1#)-(gx#, y2#), 8
        NEXT gx#
        FOR gy# = INT(y1# / g#) * g# TO y2# STEP g#
            LINE (x1#, gy#)-(x2#, gy#), 8
        NEXT gy#
        LINE (x1#, 0)-(x2#, 0), 7: LINE (0, y1#)-(0, y2#), 7     ' axes
        ' The curve: one sample per pixel column.
        penDown = 0
        FOR px = 0 TO 639
            x# = x1# + (x2# - x1#) * px / 639
            y# = Eval#(x#, ok%)
            ' Lift the pen at undefined points and at huge jumps
            ' (e.g. TAN near 90 degrees) so we do not draw fake lines.
            IF ok% = 0 OR ABS(y#) > span# * 50 THEN
                penDown = 0
            ELSE
                IF penDown THEN
                    IF ABS(y# - lastY#) < span# * 2 THEN LINE -(x#, y#), 14 ELSE PSET (x#, y#), 14
                ELSE
                    PSET (x#, y#), 14
                END IF
                penDown = -1: lastY# = y#
            END IF
        NEXT px
        WINDOW                                  ' back to pixels for text
        COLOR 15: LOCATE 1, 1: PRINT "y = "; f$
        COLOR 7: LOCATE 2, 1
        PRINT USING "x: ####.### to ####.###   grid = "; x1#; x2#;
        PRINT LTRIM$(STR$(g#))
        LOCATE 30, 1: PRINT "+/- zoom   arrows/WASD pan   N new   Q quit";
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
        SELECT CASE k$
            CASE "+", "=": span# = span# / 2
            CASE "-", "_": span# = span# * 2
            CASE CHR$(0) + "K", "A": cx# = cx# - span# / 4
            CASE CHR$(0) + "M", "D": cx# = cx# + span# / 4
            CASE CHR$(0) + "H", "W": cy# = cy# + span# / 4
            CASE CHR$(0) + "P", "S": cy# = cy# - span# / 4
            CASE "N": EXIT DO
            CASE "Q", CHR$(27): SCREEN 0: WIDTH 80: END
        END SELECT
        IF span# < .001 THEN span# = .001
        IF span# > 100000 THEN span# = 100000
    LOOP
NextFormula:
LOOP
SCREEN 0: WIDTH 80
END

' Adds one instruction to the RPN program.
SUB Emit (op%, v#)
    IF ncode >= 200 THEN perr = "formula too long": EXIT SUB
    ncode = ncode + 1
    code(ncode) = op%: value(ncode) = v#
END SUB

' Runs the RPN program for one value of x.  ok% = 0 if the formula is
' undefined there (dividing by 0, SQR of a negative, LOG of 0 ...).
FUNCTION Eval# (x#, ok%)
    DIM st(50) AS DOUBLE
    sp = 0: ok% = -1
    FOR i = 1 TO ncode
        SELECT CASE code(i)
            CASE OPNUM: sp = sp + 1: st(sp) = value(i)
            CASE OPX: sp = sp + 1: st(sp) = x#
            CASE OPNEG: st(sp) = -st(sp)
            CASE OPADD TO OPPOW
                b# = st(sp): sp = sp - 1: a# = st(sp)
                SELECT CASE code(i)
                    CASE OPADD: st(sp) = a# + b#
                    CASE OPSUB: st(sp) = a# - b#
                    CASE OPMUL: st(sp) = a# * b#
                    CASE OPDIV
                        IF b# = 0 THEN ok% = 0: EXIT FUNCTION
                        st(sp) = a# / b#
                    CASE OPPOW
                        ' negative ^ fraction is not a real number
                        IF a# < 0 AND b# <> INT(b#) THEN ok% = 0: EXIT FUNCTION
                        IF a# = 0 AND b# < 0 THEN ok% = 0: EXIT FUNCTION
                        IF a# <> 0 THEN
                            IF ABS(b# * LOG(ABS(a#))) > 200 THEN ok% = 0: EXIT FUNCTION
                        END IF
                        st(sp) = a# ^ b#
                END SELECT
            CASE ELSE
                a# = st(sp)
                SELECT CASE code(i) - OPFN
                    CASE 1: st(sp) = SIN(a#)
                    CASE 2: st(sp) = COS(a#)
                    CASE 3
                        IF ABS(COS(a#)) < 1E-12 THEN ok% = 0: EXIT FUNCTION
                        st(sp) = TAN(a#)
                    CASE 4: st(sp) = ATN(a#)
                    CASE 5
                        IF a# < 0 THEN ok% = 0: EXIT FUNCTION
                        st(sp) = SQR(a#)
                    CASE 6: st(sp) = ABS(a#)
                    CASE 7
                        IF a# <= 0 THEN ok% = 0: EXIT FUNCTION
                        st(sp) = LOG(a#)
                    CASE 8
                        IF a# > 200 THEN ok% = 0: EXIT FUNCTION
                        st(sp) = EXP(a#)
                    CASE 9: st(sp) = INT(a#)
                END SELECT
        END SELECT
    NEXT i
    Eval# = st(1)
END FUNCTION

' expr = term { (+|-) term }
SUB ParseExpr
    ParseTerm
    DO
        SkipSpaces
        c$ = MID$(src$, p, 1)
        IF c$ <> "+" AND c$ <> "-" THEN EXIT DO
        p = p + 1
        ParseTerm
        IF c$ = "+" THEN Emit OPADD, 0 ELSE Emit OPSUB, 0
    LOOP
END SUB

' power = primary [ ^ unary ]   - parsing the right side with ParseUnary
' (which leads back to ParsePower) makes 2^3^2 mean 2^(3^2) = 512, as
' mathematicians expect, and allows 2^-1.
SUB ParsePower
    ParsePrimary
    SkipSpaces
    IF MID$(src$, p, 1) = "^" THEN
        p = p + 1
        ParseUnary
        Emit OPPOW, 0
    END IF
END SUB

' primary = number | X | PI | name( expr ) | ( expr )
SUB ParsePrimary
    IF perr <> "" THEN EXIT SUB
    SkipSpaces
    c$ = MID$(src$, p, 1)
    IF c$ = "" THEN perr = "formula ends too soon": EXIT SUB
    IF (c$ >= "0" AND c$ <= "9") OR c$ = "." THEN
        ' read the longest run of digits and dots, VAL converts it
        st = p
        DO WHILE INSTR("0123456789.", MID$(src$, p, 1)) > 0 AND p <= LEN(src$)
            p = p + 1
        LOOP
        Emit OPNUM, VAL(MID$(src$, st, p - st))
    ELSEIF c$ = "(" THEN
        p = p + 1
        ParseExpr
        SkipSpaces
        IF MID$(src$, p, 1) <> ")" THEN perr = "missing )": EXIT SUB
        p = p + 1
    ELSEIF MID$(src$, p, 2) = "PI" THEN
        p = p + 2
        Emit OPNUM, 4 * ATN(1#)
    ELSEIF c$ = "X" THEN
        p = p + 1
        Emit OPX, 0
    ELSE
        ' a function name: 3 letters, then a bracketed expression
        nm$ = MID$(src$, p, 3)
        k = INSTR(funcList$, nm$ + " ")
        IF k = 0 OR LEN(nm$) < 3 OR (k - 1) MOD 4 <> 0 THEN perr = "unknown name": EXIT SUB
        p = p + 3
        SkipSpaces
        IF MID$(src$, p, 1) <> "(" THEN perr = "( expected after " + nm$: EXIT SUB
        p = p + 1
        ParseExpr
        SkipSpaces
        IF MID$(src$, p, 1) <> ")" THEN perr = "missing )": EXIT SUB
        p = p + 1
        Emit OPFN + (k - 1) \ 4 + 1, 0
    END IF
END SUB

' term = unary { (*|/) unary }
SUB ParseTerm
    ParseUnary
    DO
        SkipSpaces
        c$ = MID$(src$, p, 1)
        IF c$ <> "*" AND c$ <> "/" THEN EXIT DO
        p = p + 1
        ParseUnary
        IF c$ = "*" THEN Emit OPMUL, 0 ELSE Emit OPDIV, 0
    LOOP
END SUB

' unary = - unary | power.   Because ^ is handled INSIDE power, -x^2 is
' parsed as -(x^2), which is what you want for formulas like EXP(-x^2).
SUB ParseUnary
    SkipSpaces
    IF MID$(src$, p, 1) = "-" THEN
        p = p + 1
        ParseUnary
        Emit OPNEG, 0
    ELSE
        ParsePower
    END IF
END SUB

SUB SkipSpaces
    DO WHILE MID$(src$, p, 1) = " "
        p = p + 1
    LOOP
END SUB
