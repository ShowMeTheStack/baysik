' ============================================================
' TITLE:    Typing Race
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     typing, strings, timer, inkey, animation, text mode
' SUMMARY:  Type a sentence as fast as you can while your car races a computer rival.
' ------------------------------------------------------------
' WHAT IT DOES
'   A sentence appears on screen.  As you type it correctly, your car
'   moves along the track.  A computer car drives at a steady speed
'   that you choose.  Typos turn red and must be fixed with Backspace
'   before you can go on.  At the finish you see your speed in words
'   per minute (WPM) and your accuracy.
'
' HOW TO USE
'   Pick the rival's speed (1-4), then just start typing.
'   Backspace fixes a mistake.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Comparing typed characters with a target string
'   * Measuring elapsed time with TIMER while still reading keys
'   * WPM: (characters / 5) / minutes - the standard typing measure
'   * Moving simple text "sprites" along a track
'
' THINGS TO TRY
'   * Add your own sentences to the DATA lines
'   * Save the best WPM to a file
'   * Add a third car that drives at your previous best speed
' ============================================================

DEFINT A-Z
DATA 8
DATA "the quick brown fox jumps over the lazy dog"
DATA "practice makes perfect so keep on typing every day"
DATA "a journey of a thousand miles begins with a single step"
DATA "computers do exactly what you tell them to do"
DATA "the early bird catches the worm but the second mouse gets the cheese"
DATA "every program starts with a single line of code"
DATA "rockets need fuel and a very careful countdown"
DATA "basic was made so that everyone could learn to program"
READ count
DIM sentence$(1 TO count)
FOR i = 1 TO count: READ sentence$(i): NEXT
DIM t0 AS SINGLE, elapsed AS SINGLE, cpuPos AS SINGLE, cpuSpeed AS SINGLE

CONST TRACK = 60                     ' length of the track in columns
RANDOMIZE TIMER

DO
  CLS
  COLOR 14: PRINT : PRINT "   T Y P I N G   R A C E": COLOR 7
  PRINT
  PRINT "   Choose your rival:"
  PRINT "     1 = Learner driver   (20 WPM)"
  PRINT "     2 = Club racer       (35 WPM)"
  PRINT "     3 = Champion         (50 WPM)"
  PRINT "     4 = Typing robot     (70 WPM)"
  DO
    k$ = INKEY$
    IF k$ = CHR$(27) THEN GOTO Quit
  LOOP UNTIL k$ >= "1" AND k$ <= "4"
  wpmRival = VAL(MID$("20355070", VAL(k$) * 2 - 1, 2))

  target$ = sentence$(INT(RND * count) + 1)
  L = LEN(target$)
  ' the rival's speed in characters per second: WPM * 5 chars / 60 s
  cpuSpeed = wpmRival * 5 / 60

  CLS
  COLOR 14: LOCATE 2, 4: PRINT "TYPING RACE  vs"; wpmRival; "WPM rival": COLOR 7
  LOCATE 4, 4: PRINT "Type this:"
  LOCATE 5, 4: COLOR 15: PRINT target$: COLOR 7
  ' the race track
  LOCATE 10, 4: PRINT STRING$(TRACK + 6, 196)
  LOCATE 13, 4: PRINT STRING$(TRACK + 6, 196)
  LOCATE 16, 4: PRINT STRING$(TRACK + 6, 196)
  FOR r = 11 TO 15: LOCATE r, TRACK + 9: COLOR 15: PRINT CHR$(177); : NEXT   ' finish line
  COLOR 7
  LOCATE 18, 4: PRINT "Get ready..."
  FOR c = 3 TO 1 STEP -1
    LOCATE 18, 17: PRINT c; : SOUND 440, 3
    t0 = TIMER: DO: LOOP WHILE TIMER < t0 + 1 AND TIMER >= t0
  NEXT
  LOCATE 18, 4: PRINT "GO!            ": SOUND 880, 6
  DO WHILE INKEY$ <> "": LOOP

  typed$ = ""                ' what you have typed so far (may contain errors)
  good = 0                   ' how many leading characters are correct
  strokes = 0: errors = 0
  t0 = TIMER
  winner = 0

  DO
    elapsed = TIMER - t0
    IF elapsed < 0 THEN elapsed = elapsed + 86400
    ' ---- the rival moves at a steady speed ----
    cpuPos = cpuSpeed * elapsed
    IF cpuPos >= L AND winner = 0 THEN winner = 2

    ' ---- read keys ----
    k$ = INKEY$
    IF k$ = CHR$(27) THEN GOTO Quit
    IF k$ = CHR$(8) AND LEN(typed$) > 0 THEN
      typed$ = LEFT$(typed$, LEN(typed$) - 1)
    ELSEIF LEN(k$) = 1 AND k$ >= " " AND LEN(typed$) < L THEN
      typed$ = typed$ + k$
      strokes = strokes + 1
      IF k$ <> MID$(target$, LEN(typed$), 1) THEN errors = errors + 1: SOUND 150, .5
    END IF
    ' how much of what was typed is correct from the start?
    good = 0
    FOR i = 1 TO LEN(typed$)
      IF MID$(typed$, i, 1) <> MID$(target$, i, 1) THEN EXIT FOR
      good = i
    NEXT

    ' ---- show the typed text: correct in green, wrong in red ----
    LOCATE 7, 4
    COLOR 10: PRINT LEFT$(typed$, good);
    COLOR 15, 4: PRINT MID$(typed$, good + 1);
    COLOR 7, 0: PRINT "_ ";

    ' ---- move the cars ----
    youX = 5 + good * TRACK \ L
    cpuX = 5 + INT(cpuPos * TRACK / L): IF cpuX > TRACK + 5 THEN cpuX = TRACK + 5
    LOCATE 11, 4: PRINT SPACE$(TRACK + 5); : LOCATE 11, youX: COLOR 11: PRINT "YOU>"; : COLOR 7
    LOCATE 14, 4: PRINT SPACE$(TRACK + 5); : LOCATE 14, cpuX: COLOR 12: PRINT "CPU>"; : COLOR 7

    IF good = L THEN
      IF winner = 0 THEN winner = 1
      EXIT DO
    END IF
  LOOP

  ' ---- results ----
  IF elapsed < .1 THEN elapsed = .1      ' (avoid dividing by zero)
  wpm = (L / 5) / (elapsed / 60)
  IF strokes > 0 THEN acc = (strokes - errors) * 100 \ strokes ELSE acc = 0
  LOCATE 18, 4
  IF winner = 1 THEN
    COLOR 10: PRINT "YOU WIN THE RACE!": PLAY "MB T180 L8 CEG>C"
  ELSE
    COLOR 12: PRINT "The rival got there first.": PLAY "MB T120 L8 EDC"
  END IF
  COLOR 7
  LOCATE 19, 4: PRINT USING "Time: ##.# s   Speed: ### WPM   Accuracy: ###%"; elapsed; wpm; acc
  LOCATE 21, 4: PRINT "Race again? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"

Quit:
COLOR 7, 0: CLS
PRINT "Keep practising!"
END
