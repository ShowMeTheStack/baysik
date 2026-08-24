' ============================================================
' TITLE:    L-System Interpreter
' CATEGORY: Fractals & Generative Art
' LEVEL:    Advanced
' TAGS:     fractals, L-systems, strings, turtle graphics, stack, plants
' SUMMARY:  A tiny string-rewriting language that grows plants, curves and snowflakes from one-line rules.
' ------------------------------------------------------------
' WHAT IT DOES
'   Lindenmayer systems (L-systems) were invented by the biologist
'   Aristid Lindenmayer in 1968 to describe how plants grow.  You
'   start with a short string (the AXIOM) and a set of RULES like
'        F -> F[+F]F[-F]F
'   Each "generation" replaces every letter that has a rule by its
'   replacement, all at the same time.  The string grows very fast.
'   Then a TURTLE reads the final string as drawing commands:
'        F or G   move forward drawing a line
'        f        move forward without drawing
'        +  -     turn left / right by the angle
'        [  ]     remember / go back to a saved position (a branch!)
'        other    ignored (letters like X only steer the rewriting)
'
'   The program first walks the turtle WITHOUT drawing to find how
'   big the picture is, then scales it to fit the screen and draws.
'
' HOW TO USE
'   Choose a system from the menu (1-8).  After it is drawn, press
'   any key to return to the menu.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * String building with MID$, INSTR and concatenation
'   * A STACK (arrays + a pointer) to save and restore the turtle
'   * Two-pass drawing: measure first, then scale to fit
'   * Formal grammars - the same idea used by compilers
'
' THINGS TO TRY
'   * Add your own system to the DATA lines (and raise NSYS)
'   * Change the angle of the plant by a few degrees
'   * Make branches shorter as the stack gets deeper
' ============================================================
DECLARE FUNCTION Rewrite$ (s$)
DECLARE SUB Turtle (s$, drawIt%)

CONST NSYS = 8
CONST PI = 3.14159265#
CONST MAXLEN = 30000            ' longest string we allow to grow

' Rules are stored as one string "F=FF-F,X=F[+X]" (letter=replacement,
' separated by commas) and decoded into these arrays.
DIM SHARED ruleCh$(1 TO 5), ruleTo$(1 TO 5), nRules%
DIM SHARED turnA!, startA!
' Bounding box found in pass 1, and the scale computed from it.
DIM SHARED minX!, maxX!, minY!, maxY!, sc!, offX!, offY!
' The turtle's stack for [ and ]
DIM SHARED stX!(1 TO 100), stY!(1 TO 100), stA!(1 TO 100)

' name, axiom, rules, angle, start heading, generations
DATA "Koch island", "F-F-F-F", "F=F-F+F+FF-F-F+F", 90, 0, 2
DATA "Sierpinski arrowhead", "A", "A=B-A-B,B=A+B+A", 60, 0, 6
DATA "Dragon curve", "FX", "X=X+YF+,Y=-FX-Y", 90, 0, 10
DATA "Bushy plant", "F", "F=FF-[-F+F+F]+[+F-F-F]", 22.5, 90, 4
DATA "Fractal plant", "X", "X=F+[[X]-X]-F[-FX]+X,F=FF", 25, 80, 5
DATA "Gosper hexagon curve", "A", "A=A-B--B+A++AA+B-,B=+A-BB--B-A++A+B", 60, 0, 3
DATA "Quadratic Koch curve", "F", "F=F-F+F+F-F", 90, 0, 4
DATA "Crystal", "F+F+F+F", "F=FF+F++F+F", 90, 0, 4

SCREEN 12
DO
    ' ---- Menu ------------------------------------------------
    CLS
    COLOR 15: PRINT "L-SYSTEM INTERPRETER": PRINT
    RESTORE
    FOR i% = 1 TO NSYS
        READ nm$, ax$, rl$, an!, st!, gen%
        COLOR 11: PRINT USING "  #  "; i%;
        COLOR 7: PRINT nm$; TAB(30);
        COLOR 8: PRINT rl$
    NEXT
    PRINT: COLOR 14: PRINT "  Choose 1 -"; NSYS; "(Esc quits)"
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    IF k$ = CHR$(27) THEN EXIT DO
    choice% = VAL(k$)
    IF choice% >= 1 AND choice% <= NSYS THEN
        ' ---- Read the chosen system ----------------------------
        RESTORE
        FOR i% = 1 TO choice%: READ nm$, ax$, rl$, turnA!, startA!, gen%: NEXT
        ' Decode "F=..,X=.." into ruleCh$() / ruleTo$()
        nRules% = 0
        r$ = rl$ + ","
        DO WHILE LEN(r$) > 0
            p% = INSTR(r$, ",")
            one$ = LEFT$(r$, p% - 1): r$ = MID$(r$, p% + 1)
            nRules% = nRules% + 1
            ruleCh$(nRules%) = LEFT$(one$, 1)         ' letter before "="
            ruleTo$(nRules%) = MID$(one$, 3)           ' text after "="
        LOOP
        ' ---- Grow the string -----------------------------------
        CLS
        s$ = ax$
        FOR g% = 1 TO gen%
            s$ = Rewrite$(s$)
            COLOR 7: PRINT "generation"; g%; ":"; LEN(s$); "symbols"
        NEXT
        ' ---- Pass 1: measure.  Pass 2: draw. ---------------------
        Turtle s$, 0
        w! = maxX! - minX!: h! = maxY! - minY!
        IF w! < 1 THEN w! = 1
        IF h! < 1 THEN h! = 1
        ' Fit inside 600 x 420 pixels, keep the shape (same scale).
        sc! = 600 / w!: IF 420 / h! < sc! THEN sc! = 420 / h!
        ' Centre it: shift so the box's middle lands at (320, 250).
        offX! = 320 - (minX! + w! / 2) * sc!
        offY! = 250 + (minY! + h! / 2) * sc!
        CLS
        COLOR 15: PRINT nm$; " -"; gen%; "generations,"; LEN(s$); "symbols"
        Turtle s$, -1
        LOCATE 30, 1: PRINT "Press any key for the menu";
        DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    END IF
LOOP
SCREEN 0: WIDTH 80
END

' Applies the rules once to every character of s$.
FUNCTION Rewrite$ (s$)
    out$ = ""
    FOR i% = 1 TO LEN(s$)
        c$ = MID$(s$, i%, 1)
        rep$ = c$                        ' no rule: copy unchanged
        FOR r% = 1 TO nRules%
            IF ruleCh$(r%) = c$ THEN rep$ = ruleTo$(r%): EXIT FOR
        NEXT
        ' Strings in QBasic can be at most 32767 characters.
        IF LEN(out$) + LEN(rep$) > MAXLEN THEN EXIT FOR
        out$ = out$ + rep$
    NEXT
    Rewrite$ = out$
END FUNCTION

' Walks the turtle along s$.  drawIt% = 0: only measure the
' bounding box.  drawIt% <> 0: draw using sc!, offX!, offY!.
' The turtle uses math coordinates (y up); we flip y when drawing.
SUB Turtle (s$, drawIt%)
    x! = 0: y! = 0: a! = startA!: sp% = 0
    minX! = 0: maxX! = 0: minY! = 0: maxY! = 0
    IF drawIt% THEN PSET (offX!, offY!), POINT(offX!, offY!)
    FOR i% = 1 TO LEN(s$)
        c$ = MID$(s$, i%, 1)
        SELECT CASE c$
            CASE "F", "G", "A", "B", "f"
                ' Move one unit in direction a! (degrees).
                x! = x! + COS(a! * PI / 180)
                y! = y! + SIN(a! * PI / 180)
                IF drawIt% THEN
                    sx! = offX! + x! * sc!: sy! = offY! - y! * sc!
                    IF c$ = "f" THEN
                        ' Move without a line: PSET a pixel with the color
                        ' it already has - this only moves the "last point".
                        PSET (sx!, sy!), POINT(sx!, sy!)
                    ELSE
                        ' color slowly changes along the string
                        ' (6& makes the product a LONG - i% * 6 can be
                        ' bigger than the INTEGER limit of 32767)
                        LINE -(sx!, sy!), 9 + (i% * 6& \ LEN(s$))
                    END IF
                ELSE
                    IF x! < minX! THEN minX! = x!
                    IF x! > maxX! THEN maxX! = x!
                    IF y! < minY! THEN minY! = y!
                    IF y! > maxY! THEN maxY! = y!
                END IF
            CASE "+": a! = a! + turnA!
            CASE "-": a! = a! - turnA!
            CASE "["                        ' PUSH: save x, y, angle
                IF sp% < 100 THEN
                    sp% = sp% + 1
                    stX!(sp%) = x!: stY!(sp%) = y!: stA!(sp%) = a!
                END IF
            CASE "]"                        ' POP: jump back
                IF sp% > 0 THEN
                    x! = stX!(sp%): y! = stY!(sp%): a! = stA!(sp%)
                    sp% = sp% - 1
                    ' Move the graphics cursor without drawing.
                    IF drawIt% THEN PSET (offX! + x! * sc!, offY! - y! * sc!), POINT(offX! + x! * sc!, offY! - y! * sc!)
                END IF
        END SELECT
        IF drawIt% AND (i% AND 255) = 0 THEN
            IF INKEY$ = CHR$(27) THEN EXIT SUB
        END IF
    NEXT
END SUB
