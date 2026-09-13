' ============================================================
' TITLE:    The Birthday Paradox
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     probability, simulation, graphics, statistics, random
' SUMMARY:  How many people must be in a room before two probably share a birthday? Only 23! Exact maths vs random parties.
' ------------------------------------------------------------
' WHAT IT DOES
'   With 366 people a shared birthday is certain.  But the chance
'   passes 50% with just 23 people - which surprises almost everyone.
'
'   The trick is to count the chance that everyone is DIFFERENT:
'     person 2 avoids person 1:          364/365
'     person 3 avoids persons 1 and 2:   363/365   ... and so on.
'   Multiply these together; one minus the result is the chance of
'   at least one match.  Many PAIRS of people can match: 23 people
'   make 23*22/2 = 253 pairs!
'
'   The program draws the exact curve, then throws random "parties"
'   for every group size and plots the measured results on top, so
'   you can see simulation and maths agree.
'
' HOW TO USE
'   Just watch.  Afterwards type a group size to throw one party and
'   see who shares a birthday.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Complement trick: P(match) = 1 - P(all different)
'   * Monte-Carlo simulation (estimating by random experiments)
'   * Plotting a graph with WINDOW so you can use real coordinates
'   * Using an array as a "seen it already?" checklist
'
' THINGS TO TRY
'   * How many people for a 99% chance?  (Answer: 57.)
'   * Change the calendar to 10 "days" - what's the 50% point?
' ============================================================
DECLARE FUNCTION Party% (n AS INTEGER)
DECLARE FUNCTION DateName$ (d AS INTEGER)
DEFINT A-Z

CONST MAXP = 70           ' biggest group on the graph
CONST TRIALS = 200        ' random parties per group size
DIM SHARED seen(365), bday(100)

RANDOMIZE TIMER
SCREEN 12
COLOR 15
LOCATE 1, 3: PRINT "THE BIRTHDAY PARADOX - chance that two people share a birthday"
' Graph area: x = group size 0..MAXP, y = probability 0..1.
VIEW (60, 40)-(620, 400), 0, 8
WINDOW (0, 0)-(MAXP, 1)
' Grid lines every 10 people and every 10%.
FOR x = 10 TO MAXP STEP 10: LINE (x, 0)-(x, 1), 8: NEXT
FOR i = 1 TO 9: LINE (0, i / 10)-(MAXP, i / 10), 8: NEXT
LINE (0, .5)-(MAXP, .5), 7, , &HF0F0      ' the 50% line, dashed

' ---- 1. Exact curve (yellow) ----------------------------------------
pDiff# = 1
fifty = 0
PSET (1, 0), 14
FOR n = 2 TO MAXP
    ' Person n must avoid the n-1 birthdays already used.
    pDiff# = pDiff# * (365 - (n - 1)) / 365
    LINE -(n, 1 - pDiff#), 14
    IF fifty = 0 AND 1 - pDiff# >= .5 THEN fifty = n
NEXT

VIEW: WINDOW
LOCATE 26, 9: PRINT "0";
FOR x = 10 TO MAXP STEP 10: LOCATE 26, 8 + x * 70 \ MAXP - 1: PRINT x; : NEXT
LOCATE 27, 32: PRINT "people in the room";
LOCATE 3, 2: PRINT "100%";
LOCATE 14, 3: PRINT "50%";
LOCATE 25, 4: PRINT "0%";

' ---- 2. Simulated parties (green dots) ----------------------------
VIEW (60, 40)-(620, 400): WINDOW (0, 0)-(MAXP, 1)
FOR n = 2 TO MAXP
    hits = 0
    FOR t = 1 TO TRIALS
        IF Party%(n) THEN hits = hits + 1
    NEXT
    CIRCLE (n, hits / TRIALS), .3, 10
    k$ = INKEY$
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT
' Mark the 50% point with a red ring.
CIRCLE (fifty, .5), 1.2, 12
VIEW: WINDOW
COLOR 14: LOCATE 2, 3: PRINT "Yellow = exact maths";
COLOR 10: PRINT "   Green = 200 parties each";
COLOR 12: PRINT "   Ring = 50% at"; fifty; "people";
COLOR 15

' ---- 3. Throw your own party --------------------------------------
DO
    LOCATE 29, 3: PRINT SPACE$(76);
    LOCATE 29, 3: LINE INPUT "Party size 2-100 (Q quits): "; a$
    IF INSTR(UCASE$(a$), "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    n = VAL(a$)
    IF n >= 2 AND n <= 100 THEN
        LOCATE 28, 3: PRINT SPACE$(76);
        LOCATE 28, 3
        IF Party%(n) THEN
            ' Find the first pair that matches.
            FOR i = 1 TO n
                FOR j = i + 1 TO n
                    IF bday(i) = bday(j) THEN
                        PRINT "Guests"; i; "and"; j; "both have their birthday on "; DateName$(bday(i)); "!";
                        GOTO found
                    END IF
                NEXT
            NEXT
found:
        ELSE
            PRINT "No shared birthdays among"; n; "guests this time.";
        END IF
    END IF
LOOP
SCREEN 0: WIDTH 80: CLS
END

FUNCTION DateName$ (d AS INTEGER)
    ' Turn day number 1..365 into "12 Mar" (ignoring leap years).
    ' We work on a COPY (dd) because d is passed by reference.
    m$ = "JanFebMarAprMayJunJulAugSepOctNovDec"
    lens$ = "312831303130313130313031"      ' days in each month
    dd = d: mo = 0
    DO WHILE dd > VAL(MID$(lens$, mo * 2 + 1, 2))
        dd = dd - VAL(MID$(lens$, mo * 2 + 1, 2)): mo = mo + 1
    LOOP
    DateName$ = LTRIM$(STR$(dd)) + " " + MID$(m$, mo * 3 + 1, 3)
END FUNCTION

FUNCTION Party% (n AS INTEGER)
    ' Give n guests random birthdays.  Return -1 if any two match.
    FOR d = 1 TO 365: seen(d) = 0: NEXT
    Party% = 0
    FOR i = 1 TO n
        bday(i) = INT(RND * 365) + 1
        IF seen(bday(i)) THEN Party% = -1
        seen(bday(i)) = -1
    NEXT
END FUNCTION
