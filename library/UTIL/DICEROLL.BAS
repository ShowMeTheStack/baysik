' ============================================================
' TITLE:    Dice Notation Roller
' CATEGORY: Utilities & Tools
' LEVEL:    Intermediate
' TAGS:     parsing, random, games, strings, statistics
' SUMMARY:  Roll dice for tabletop games using notation like 2d6+3, 4d6k3 or 1d20-1+1d4.
' ------------------------------------------------------------
' WHAT IT DOES
'   Tabletop role-playing games write dice rolls in a short code:
'     2d6     roll two six-sided dice and add them
'     1d20+5  roll a twenty-sided die and add 5
'     4d6k3   roll four d6 and KEEP the highest three
'     3d8+1d6-2   several terms added together
'   This program PARSES (reads apart) that notation, rolls every
'   die, shows each individual result, and prints the total.
'   It also remembers the min, max and average possible result.
'
' HOW TO USE
'   Type a dice expression and press Enter.  Press Enter on its
'   own to re-roll the last expression.  Type Q to quit.
'   Type S followed by an expression (e.g. "S 2d6") to roll it
'   1000 times and draw a histogram of the results.
'
' CONCEPTS YOU WILL LEARN
'   * Writing a small parser: walking a string character by
'     character, collecting digits into numbers
'   * Splitting into terms at + and - signs
'   * Partial sorting to "keep the highest k" dice
'   * Probability: why 2d6 makes 7 the most common total
'
' THINGS TO TRY
'   * Add "kl" (keep lowest) for disadvantage rolls.
'   * Add exploding dice ("!"): roll again on the max value.
'   * Support multiplication like 2d6*10.
' ============================================================

DECLARE FUNCTION RollExpr% (e$, show%)
DECLARE FUNCTION ReadNum% (s$, p%)

DIM SHARED minT%, maxT%, bad%
RANDOMIZE TIMER

CLS
COLOR 14: PRINT "DICE NOTATION ROLLER": COLOR 7
PRINT "Examples: 2d6   1d20+5   4d6k3   3d8+1d6-2   d100"
PRINT "Enter = roll again,  S 2d6 = 1000-roll histogram,  Q = quit"
PRINT
last$ = "2d6"

DO
    LINE INPUT "Roll> "; e$
    e$ = LCASE$(LTRIM$(RTRIM$(e$)))
    IF e$ = "q" THEN EXIT DO
    IF e$ = "" THEN e$ = last$

    IF LEFT$(e$, 1) = "s" THEN
        ' ---- Statistics mode: roll it many times ----
        e$ = LTRIM$(MID$(e$, 2))
        t% = RollExpr%(e$, 0)          ' one test roll sets minT/maxT
        IF bad% THEN
            PRINT "  Could not understand that."
        ELSEIF maxT% - minT% > 60 THEN
            PRINT "  Range too wide to chart (max 60 different totals)."
        ELSE
            REDIM cnt%(minT% TO maxT%)
            FOR i = 1 TO 1000
                t% = RollExpr%(e$, 0)
                cnt%(t%) = cnt%(t%) + 1
            NEXT i
            ' find the biggest count so the bars fit on screen
            big% = 1
            FOR v% = minT% TO maxT%: IF cnt%(v%) > big% THEN big% = cnt%(v%)
            NEXT v%
            FOR v% = minT% TO maxT%
                PRINT USING "  ###: "; v%;
                PRINT STRING$(cnt%(v%) * 50 \ big%, 219); cnt%(v%)
            NEXT v%
            last$ = e$
        END IF
    ELSE
        t% = RollExpr%(e$, -1)
        IF bad% THEN
            PRINT "  Could not understand that. Try something like 2d6+3"
        ELSE
            COLOR 15: PRINT "  TOTAL ="; t%;: COLOR 8
            PRINT "   (range"; minT%; "to"; maxT%; "- midpoint";
            PRINT USING "###.#"; (minT% + maxT%) / 2;
            PRINT ")": COLOR 7
            last$ = e$
        END IF
    END IF
LOOP
END

' Read digits starting at position p%, return the number and
' move p% past them.  Returns -1 if there are no digits.
FUNCTION ReadNum% (s$, p%)
    v& = 0: found% = 0
    DO WHILE p% <= LEN(s$)
        c$ = MID$(s$, p%, 1)
        IF c$ < "0" OR c$ > "9" THEN EXIT DO
        v& = v& * 10 + VAL(c$)
        IF v& > 1000 THEN v& = 1000     ' keep numbers sane
        p% = p% + 1: found% = -1
    LOOP
    IF found% THEN ReadNum% = v& ELSE ReadNum% = -1
END FUNCTION

' Roll a whole expression.  If show% is true, print each die.
' Sets the shared minT%, maxT% and bad% as side effects.
FUNCTION RollExpr% (e$, show%)
    DIM d%(1 TO 100)
    total% = 0: minT% = 0: maxT% = 0: bad% = 0
    s$ = ""
    ' remove spaces so "2d6 + 3" also works
    FOR i = 1 TO LEN(e$)
        IF MID$(e$, i, 1) <> " " THEN s$ = s$ + MID$(e$, i, 1)
    NEXT i
    IF s$ = "" THEN bad% = -1: EXIT FUNCTION

    p% = 1: sign% = 1
    IF LEFT$(s$, 1) = "-" THEN sign% = -1: p% = 2
    IF LEFT$(s$, 1) = "+" THEN p% = 2

    DO
        ' ---- One term: either "NdS[kK]" or a plain number ----
        n% = ReadNum%(s$, p%)
        IF MID$(s$, p%, 1) = "d" THEN
            IF n% = -1 THEN n% = 1          ' "d20" means "1d20"
            p% = p% + 1
            sides% = ReadNum%(s$, p%)
            IF sides% < 2 OR n% < 1 OR n% > 100 THEN bad% = -1: EXIT FUNCTION
            keep% = n%
            IF MID$(s$, p%, 1) = "k" THEN
                p% = p% + 1
                keep% = ReadNum%(s$, p%)
                IF keep% < 1 OR keep% > n% THEN bad% = -1: EXIT FUNCTION
            END IF
            ' roll every die
            FOR i = 1 TO n%: d%(i) = INT(RND * sides%) + 1: NEXT i
            ' To keep the highest keep%, sort descending (a simple
            ' selection sort is plenty for a handful of dice).
            IF keep% < n% THEN
                FOR i = 1 TO n% - 1
                    FOR j = i + 1 TO n%
                        IF d%(j) > d%(i) THEN SWAP d%(i), d%(j)
                    NEXT j
                NEXT i
            END IF
            subt% = 0
            IF show% THEN PRINT "  "; LTRIM$(STR$(n%)); "d"; LTRIM$(STR$(sides%)); ": ";
            FOR i = 1 TO n%
                IF i <= keep% THEN
                    subt% = subt% + d%(i)
                    IF show% THEN PRINT LTRIM$(STR$(d%(i))); " ";
                ELSE
                    IF show% THEN PRINT "("; LTRIM$(STR$(d%(i))); ") ";   ' dropped die
                END IF
            NEXT i
            IF show% THEN PRINT "="; subt% * sign%
            total% = total% + sign% * subt%
            IF sign% > 0 THEN
                minT% = minT% + keep%: maxT% = maxT% + keep% * sides%
            ELSE
                minT% = minT% - keep% * sides%: maxT% = maxT% - keep%
            END IF
        ELSEIF n% >= 0 THEN
            ' just a number, like the "+3" in 2d6+3
            total% = total% + sign% * n%
            minT% = minT% + sign% * n%: maxT% = maxT% + sign% * n%
            IF show% THEN PRINT "  modifier "; : PRINT sign% * n%
        ELSE
            bad% = -1: EXIT FUNCTION
        END IF

        ' ---- What comes next: end, "+" or "-" ----
        IF p% > LEN(s$) THEN EXIT DO
        op$ = MID$(s$, p%, 1): p% = p% + 1
        IF op$ = "+" THEN
            sign% = 1
        ELSEIF op$ = "-" THEN
            sign% = -1
        ELSE
            bad% = -1: EXIT FUNCTION
        END IF
    LOOP
    RollExpr% = total%
END FUNCTION
