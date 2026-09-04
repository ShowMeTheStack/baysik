' ============================================================
' TITLE:    Reaction Timer
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     timer, reflexes, statistics, text mode
' SUMMARY:  Test how fast you can hit a key when the screen turns green.
' ------------------------------------------------------------
' WHAT IT DOES
'   The screen turns red and you wait... then, after a random delay,
'   it flashes GREEN.  Press Space as fast as you can!  Your reaction
'   time is measured in milliseconds.  Press too early and it's a
'   false start.  After 5 good tries you get your average, your best,
'   and a fun rating.
'
' HOW TO USE
'   Space = react / start the next try.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * TIMER returns seconds since midnight (with fractions)
'   * Random waiting times so you can't guess the moment
'   * Detecting a key pressed too early
'   * Average, minimum, and maximum of a list of numbers
'
' THINGS TO TRY
'   * Show a bar chart of all your times
'   * Make a "choice reaction" test: press the key of the colour shown
'   * Note: on a real old PC, TIMER only ticks 18.2 times a second,
'     so times were rounded to about 55 ms!
' ============================================================

DEFINT A-Z
CONST TRIES = 5
DIM times(1 TO TRIES) AS SINGLE
DIM delay AS SINGLE, t0 AS SINGLE, rt AS SINGLE

RANDOMIZE TIMER
n = 0

DO WHILE n < TRIES
  ' ---- get ready ----
  COLOR 15, 4: CLS
  LOCATE 10, 30: PRINT "R E A C T I O N"
  LOCATE 12, 26: PRINT "Wait for GREEN, then hit Space!"
  LOCATE 14, 33: PRINT "Try"; n + 1; "of"; TRIES
  DO WHILE INKEY$ <> "": LOOP               ' clear the keyboard
  delay = 1.5 + RND * 3.5                      ' 1.5 to 5 seconds
  t0 = TIMER
  early = 0
  DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN GOTO Quit
    IF k$ <> "" THEN early = -1: EXIT DO      ' pressed before green
  LOOP WHILE TIMER < t0 + delay AND TIMER >= t0

  IF early THEN
    COLOR 14, 0: CLS
    LOCATE 12, 30: PRINT "FALSE START! Too early."
    SOUND 150, 6
  ELSE
    ' ---- GO! measure until a key arrives ----
    COLOR 0, 2: CLS
    LOCATE 12, 37: PRINT "G O !"
    t0 = TIMER
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    rt = TIMER - t0
    IF rt < 0 THEN rt = rt + 86400            ' midnight safety
    IF k$ = CHR$(27) THEN GOTO Quit
    n = n + 1
    times(n) = rt
    COLOR 15, 1: CLS
    LOCATE 12, 30: PRINT USING "Your time: #### ms"; rt * 1000
    SOUND 880, 1
  END IF
  LOCATE 16, 28: PRINT "Press Space to continue"
  DO: k$ = INKEY$: LOOP UNTIL k$ = " " OR k$ = CHR$(27)
  IF k$ = CHR$(27) THEN GOTO Quit
LOOP

' ---- results ----
COLOR 7, 0: CLS
total! = 0: best! = 999: worst! = 0
PRINT : PRINT "  YOUR RESULTS": PRINT
FOR i = 1 TO TRIES
  PRINT USING "  Try #:  #### ms  "; i; times(i) * 1000;
  ' a little bar: one block per 20 ms (at most 50 blocks)
  bar = times(i) * 1000 \ 20: IF bar > 50 THEN bar = 50
  PRINT STRING$(bar, 219)
  total! = total! + times(i)
  IF times(i) < best! THEN best! = times(i)
  IF times(i) > worst! THEN worst! = times(i)
NEXT
avg! = total! / TRIES
PRINT
PRINT USING "  Average: #### ms"; avg! * 1000
PRINT USING "  Best:    #### ms"; best! * 1000
PRINT USING "  Worst:   #### ms"; worst! * 1000
PRINT
SELECT CASE avg! * 1000
  CASE IS < 200: PRINT "  Lightning fast - are you a racing driver?"
  CASE IS < 260: PRINT "  Excellent reflexes!"
  CASE IS < 330: PRINT "  Good - about average for most people."
  CASE ELSE: PRINT "  A bit sleepy today?  Try again!"
END SELECT
PLAY "MB T180 L16 CEGCEG"
PRINT : PRINT "  Press any key."
DO: LOOP UNTIL INKEY$ <> ""
END

Quit:
COLOR 7, 0: CLS
PRINT "Reaction test stopped."
END
