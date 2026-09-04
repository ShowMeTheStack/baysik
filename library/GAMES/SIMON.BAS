' ============================================================
' TITLE:    Simon Says Memory
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     memory, sound, arrays, graphics, timer
' SUMMARY:  Watch and listen as coloured pads light up, then repeat the ever-growing pattern.
' ------------------------------------------------------------
' WHAT IT DOES
'   Four coloured pads each have their own musical note.  The computer
'   plays a sequence, adding one more step each round.  Repeat the
'   sequence exactly using the arrow keys.  One mistake (or taking
'   longer than 4 seconds) and the game is over.  How long a sequence
'   can you remember?
'
' HOW TO USE
'   Up = green    Right = red    Down = yellow    Left = blue
'   (keys 8 / 6 / 2 / 4 on the number pad row also work)
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a growing sequence in an array
'   * SOUND frequency and duration (18.2 ticks = 1 second)
'   * Lighting a pad by redrawing it in a brighter colour
'   * Time limits with TIMER
'
' THINGS TO TRY
'   * Speed up the playback as the sequence gets longer
'   * Add a "reverse" mode: repeat the sequence backwards!
'   * Use the real Simon notes: E, C#, A and E an octave lower
' ============================================================

DEFINT A-Z
CONST MAXLEN = 100
DIM seq(1 TO MAXLEN)
DIM px(1 TO 4), py(1 TO 4), dimCol(1 TO 4), litCol(1 TO 4), note(1 TO 4)
' pad positions (top-left corners), dim colour, lit colour, note (Hz)
DATA 125,20,  2,10, 392
DATA 205,72,  4,12, 330
DATA 125,124, 6,14, 262
DATA 45,72,   1, 9, 196
FOR i = 1 TO 4: READ px(i), py(i), dimCol(i), litCol(i), note(i): NEXT

RANDOMIZE TIMER
SCREEN 13
best = 0

NewGame:
  CLS
  LOCATE 1, 15: PRINT "SIMON SAYS"
  LOCATE 25, 3: PRINT "Arrows repeat the pattern. Esc quits";
  FOR i = 1 TO 4: pad = i: isLit = 0: GOSUB DrawPad: NEXT
  length = 0
  t! = TIMER: DO: LOOP WHILE TIMER < t! + 1 AND TIMER >= t!

DO
  ' ---- add one random step and play the whole sequence ----
  length = length + 1
  seq(length) = INT(RND * 4) + 1
  LOCATE 3, 1: PRINT "Round"; length; "  "
  LOCATE 3, 30: PRINT "Best"; best
  LOCATE 23, 15: PRINT "Watch...  "
  ' playback gets quicker as the sequence grows
  speed = 8 - length \ 4: IF speed < 3 THEN speed = 3
  FOR i = 1 TO length
    pad = seq(i): GOSUB Flash
    t! = TIMER: DO: LOOP WHILE TIMER < t! + .1 AND TIMER >= t!
  NEXT
  DO WHILE INKEY$ <> "": LOOP          ' ignore keys pressed while watching

  ' ---- the player repeats it ----
  LOCATE 23, 15: PRINT "Your turn!"
  FOR i = 1 TO length
    t! = TIMER
    pad = 0
    DO
      k$ = INKEY$
      IF k$ = CHR$(27) THEN GOTO Quit
      IF LEN(k$) = 2 THEN
        SELECT CASE ASC(RIGHT$(k$, 1))
          CASE 72: pad = 1
          CASE 77: pad = 2
          CASE 80: pad = 3
          CASE 75: pad = 4
        END SELECT
      END IF
      IF k$ = "8" THEN pad = 1
      IF k$ = "6" THEN pad = 2
      IF k$ = "2" THEN pad = 3
      IF k$ = "4" THEN pad = 4
      IF TIMER - t! > 4 OR TIMER < t! THEN EXIT DO     ' too slow!
    LOOP UNTIL pad > 0
    IF pad <> seq(i) THEN EXIT DO       ' a mistake ends the game at once
    speed = 4: GOSUB Flash
  NEXT
  IF length > best THEN best = length
  t! = TIMER: DO: LOOP WHILE TIMER < t! + .6 AND TIMER >= t!
  IF length = MAXLEN THEN EXIT DO
LOOP

' ---- game over: show the pad that was expected ----
LOCATE 23, 15: PRINT "Wrong!    "
SOUND 90, 15
pad = seq(i): speed = 10: GOSUB Flash
score = length - 1
IF score > best THEN best = score
LOCATE 3, 30: PRINT "Best"; best
LOCATE 23, 1: PRINT SPACE$(40);
LOCATE 23, 6: PRINT "Wrong! You remembered"; score
LOCATE 25, 1: PRINT SPACE$(39);
LOCATE 25, 7: PRINT "Space = again, Esc = quit";
DO
  k$ = INKEY$
  IF k$ = " " THEN GOTO NewGame
LOOP UNTIL k$ = CHR$(27)

Quit:
SCREEN 0: WIDTH 80
PRINT "Best sequence:"; best
END

' ---- light up a pad, play its note, then dim it again ----
Flash:
  isLit = -1: GOSUB DrawPad
  SOUND note(pad), speed               ' duration is in clock ticks
  ' SOUND does not wait, so wait for the note to finish ourselves
  t! = TIMER: DO: LOOP WHILE TIMER < t! + speed / 18.2 AND TIMER >= t!
  isLit = 0: GOSUB DrawPad
RETURN

' ---- draw pad number "pad", lit if isLit is true ----
DrawPad:
  IF isLit THEN c = litCol(pad) ELSE c = dimCol(pad)
  LINE (px(pad), py(pad))-STEP(70, 48), c, BF
  LINE (px(pad), py(pad))-STEP(70, 48), 15, B
RETURN
