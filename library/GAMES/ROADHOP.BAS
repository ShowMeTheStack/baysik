' ============================================================
' TITLE:    Road Hopper
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     action, arcade, strings, scrolling, text mode, timer
' SUMMARY:  Guide a frog across a busy road and a log-filled river to reach home.
' ------------------------------------------------------------
' WHAT IT DOES
'   Lanes of traffic and floating logs scroll left and right at
'   different speeds.  Hop your frog (@) from the bottom of the screen
'   to one of the five homes at the top.  Cars squash you; on the
'   river you must stand on logs (=) - the water (~) is deadly, and
'   a log can carry you off the edge of the screen!  Fill all five
'   homes to reach the next, faster level.
'
' HOW TO USE
'   Arrow keys hop up / down / left / right.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Each lane is just an 80-character string
'   * Scrolling a string by moving its first or last character
'     to the other end (MID$, LEFT$, RIGHT$)
'   * Collision by looking at the character under the frog
'   * Different speeds using frame counters and MOD
'
' THINGS TO TRY
'   * Add a turtle lane that sometimes dives (turns into water)
'   * Add a countdown timer for each crossing
'   * Make longer or shorter logs and cars in MakeLanes
' ============================================================

DEFINT A-Z
CONST NL = 11                         ' number of moving lanes
CONST HOMEROW = 3, STARTROW = 22

DIM lane$(1 TO NL), laneRow(1 TO NL), laneDir(1 TO NL), laneSpeed(1 TO NL)
DIM river(1 TO NL), homeFull(1 TO 5)
DIM t0 AS SINGLE

' Lane table: screen row, direction (+1 right / -1 left),
' frames between moves (smaller = faster), 1 = river lane
DATA 5,-1,5,1, 6,1,4,1, 7,-1,3,1, 8,1,6,1, 9,-1,4,1
DATA 15,1,4,0, 16,-1,3,0, 17,1,6,0, 18,-1,2,0, 19,1,5,0, 20,-1,4,0
FOR i = 1 TO NL: READ laneRow(i), laneDir(i), laneSpeed(i), river(i): NEXT

RANDOMIZE TIMER
CLS
level = 1: lives = 5: score = 0
GOSUB MakeLanes

NewLevel:
  FOR i = 1 TO 5: homeFull(i) = 0: NEXT
  homes = 0

NewFrog:
  fr = STARTROW: fc = 40               ' frog row and column
  GOSUB DrawStatic

' ================= MAIN LOOP =================
DO
  t0 = TIMER
  frame = frame + 1

  ' ---- move the frog ----
  k$ = INKEY$
  IF k$ = CHR$(27) THEN GOTO Quit
  IF LEN(k$) = 2 THEN
    ' lanes are redrawn every frame, but the grass is not, so put the
    ' grass back where the frog was standing
    IF (fr >= 10 AND fr <= 14) OR fr >= 21 THEN
      LOCATE fr, fc: COLOR 2: PRINT CHR$(176); : COLOR 7
    END IF
    SELECT CASE ASC(RIGHT$(k$, 1))
      CASE 72: fr = fr - 1: score = score + 1
      CASE 80: IF fr < STARTROW THEN fr = fr + 1
      CASE 75: IF fc > 1 THEN fc = fc - 1
      CASE 77: IF fc < 80 THEN fc = fc + 1
    END SELECT
    SOUND 1200, .2
  END IF
  DO WHILE INKEY$ <> "": LOOP          ' one hop per frame, ignore extra keys

  ' ---- scroll the lanes that are due to move this frame ----
  FOR i = 1 TO NL
    ' frames between moves for this lane; higher levels are faster
    d = laneSpeed(i) + 3 - level: IF d < 1 THEN d = 1
    IF frame MOD d = 0 THEN
      IF laneDir(i) = 1 THEN
        lane$(i) = RIGHT$(lane$(i), 1) + LEFT$(lane$(i), 79)
      ELSE
        lane$(i) = MID$(lane$(i), 2) + LEFT$(lane$(i), 1)
      END IF
      ' a frog standing on a log rides along with it
      IF river(i) AND fr = laneRow(i) THEN fc = fc + laneDir(i)
    END IF
    COLOR 7: IF river(i) THEN COLOR 6, 1
    LOCATE laneRow(i), 1: PRINT lane$(i);
    COLOR 7, 0
  NEXT

  ' ---- what is under the frog? ----
  dead$ = ""
  IF fc < 1 OR fc > 80 THEN dead$ = "Swept away!"
  FOR i = 1 TO NL
    IF fr = laneRow(i) AND dead$ = "" THEN
      under$ = MID$(lane$(i), fc, 1)
      IF river(i) AND under$ <> "=" THEN dead$ = "Splash!"
      IF NOT river(i) AND under$ <> " " THEN dead$ = "Squashed!"
    END IF
  NEXT
  IF fr = HOMEROW + 1 THEN fr = HOMEROW     ' the bank row just leads home
  IF fr = HOMEROW AND dead$ = "" THEN
    ' homes are at columns 8, 24, 40, 56, 72 (3 wide)
    h = 0
    FOR i = 1 TO 5
      IF ABS(fc - (i * 16 - 8)) <= 1 THEN h = i
    NEXT
    IF h = 0 THEN
      dead$ = "Missed the home!"
    ELSEIF homeFull(h) THEN
      dead$ = "That home is taken!"
    ELSE
      homeFull(h) = -1: homes = homes + 1: score = score + 50
      PLAY "MB T200 L16 CEG"
      IF homes = 5 THEN
        score = score + 200 * level: level = level + 1
        IF level > 5 THEN level = 5
        LOCATE 12, 30: PRINT "LEVEL COMPLETE!"
        PLAY "MF T180 L8 CEG>C"
        GOTO NewLevel
      END IF
      GOTO NewFrog
    END IF
  END IF

  IF dead$ <> "" THEN
    lives = lives - 1
    IF fc >= 1 AND fc <= 80 THEN LOCATE fr, fc: COLOR 12: PRINT "X";
    LOCATE 12, 30: COLOR 12: PRINT dead$: COLOR 7
    FOR f = 400 TO 100 STEP -50: SOUND f, .7: NEXT
    t0 = TIMER: DO: LOOP WHILE TIMER < t0 + 1 AND TIMER >= t0
    IF lives = 0 THEN EXIT DO
    GOTO NewFrog
  END IF

  ' ---- draw the frog on top ----
  LOCATE fr, fc: COLOR 10: IF fr <= 9 AND fr >= 5 THEN COLOR 10, 6
  PRINT "@";
  COLOR 7, 0
  DO WHILE TIMER < t0 + .06 AND TIMER >= t0: LOOP
LOOP

LOCATE 12, 30: COLOR 14: PRINT "GAME OVER - score"; score: COLOR 7
LOCATE 13, 30: PRINT "Press Esc to exit"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
COLOR 7, 0: CLS
PRINT "Road Hopper - final score:"; score
END

' ---- build the lane strings ----
MakeLanes:
  FOR i = 1 TO NL
    s$ = ""
    DO WHILE LEN(s$) < 80
      IF river(i) THEN
        ' logs 5-10 long, water gaps 3-7 long
        s$ = s$ + STRING$(INT(RND * 6) + 5, "=") + STRING$(INT(RND * 5) + 3, "~")
      ELSE
        ' cars point the way they drive; gaps 6-14 long
        IF laneDir(i) = 1 THEN car$ = "[##>" ELSE car$ = "<##]"
        IF i MOD 3 = 0 THEN car$ = LEFT$(car$, 2) + "######" + RIGHT$(car$, 2) ' trucks
        s$ = s$ + car$ + SPACE$(INT(RND * 9) + 6)
      END IF
    LOOP
    lane$(i) = LEFT$(s$, 80)
  NEXT
RETURN

' ---- the parts of the screen that never scroll ----
DrawStatic:
  CLS
  COLOR 14: LOCATE 1, 2: PRINT "ROAD HOPPER": COLOR 7
  LOCATE 1, 20: PRINT "Level"; level; "  Frogs"; lives; "  Score"; score
  ' the far bank with five homes
  COLOR 2: LOCATE HOMEROW, 1: PRINT STRING$(80, 177);
  LOCATE HOMEROW + 1, 1: PRINT STRING$(80, 176);
  FOR i = 1 TO 5
    LOCATE HOMEROW, i * 16 - 9
    IF homeFull(i) THEN COLOR 10: PRINT " @ "; ELSE COLOR 0: PRINT "   ";
  NEXT
  ' grassy strips between the river and the road, and at the start
  COLOR 2
  FOR r = 10 TO 14: LOCATE r, 1: PRINT STRING$(80, 176); : NEXT
  FOR r = 21 TO 23: LOCATE r, 1: PRINT STRING$(80, 176); : NEXT
  COLOR 7
  LOCATE 25, 2: PRINT "Arrows hop   Esc quits";
RETURN
