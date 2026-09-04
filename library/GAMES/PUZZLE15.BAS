' ============================================================
' TITLE:    Fifteen Puzzle
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     puzzle, sliding tiles, arrays, text mode
' SUMMARY:  Slide numbered tiles around a 4x4 frame until they are back in order.
' ------------------------------------------------------------
' WHAT IT DOES
'   The classic sliding puzzle from the 1870s.  Fifteen numbered
'   tiles sit in a 4x4 frame with one empty space.  Slide tiles into
'   the space to put them back in order 1-15 with the gap at the
'   bottom right.  The puzzle is mixed up by making hundreds of
'   random LEGAL moves, so it can always be solved.  (Half of all
'   random arrangements are impossible - try swapping 14 and 15!)
'
' HOW TO USE
'   Arrow keys slide a tile INTO the empty space from that side,
'   e.g. Left arrow moves the tile to the right of the gap leftwards.
'   N = new puzzle, Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Keeping track of where the empty square is
'   * Shuffling by random legal moves (guarantees solvability)
'   * Checking a win by comparing every cell with its target
'   * Drawing boxes with the PC's line-drawing characters
'
' THINGS TO TRY
'   * Make a 3x3 (8-puzzle) or 5x5 (24-puzzle) version
'   * Use letters to spell a message instead of numbers
'   * Save the best (fewest moves) result to a file
' ============================================================

DEFINT A-Z
CONST SZ = 4
DIM tile(1 TO SZ, 1 TO SZ)           ' 0 = the empty space

RANDOMIZE TIMER

NewPuzzle:
  ' ---- start solved ----
  n = 1
  FOR r = 1 TO SZ: FOR c = 1 TO SZ
    tile(r, c) = n: n = n + 1
  NEXT: NEXT
  tile(SZ, SZ) = 0: er = SZ: ec = SZ     ' empty row / column

  ' ---- shuffle with 400 random slides ----
  FOR i = 1 TO 400
    slideDir = INT(RND * 4)
    GOSUB Slide
  NEXT
  moves = 0
  t0! = TIMER
  CLS
  COLOR 14: LOCATE 2, 32: PRINT "FIFTEEN PUZZLE": COLOR 7
  LOCATE 21, 20: PRINT "Arrows slide tiles    N = new    Esc = quit"

DO
  GOSUB DrawBoard
  ' ---- solved?  every tile must equal its position number ----
  solved = -1
  FOR r = 1 TO SZ: FOR c = 1 TO SZ
    want = (r - 1) * SZ + c: IF want = SZ * SZ THEN want = 0
    IF tile(r, c) <> want THEN solved = 0
  NEXT: NEXT
  IF solved AND moves > 0 THEN EXIT DO

  DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
  IF k$ = CHR$(27) THEN GOTO Quit
  IF UCASE$(k$) = "N" THEN GOTO NewPuzzle
  slideDir = -1
  IF LEN(k$) = 2 THEN
    SELECT CASE ASC(RIGHT$(k$, 1))
      CASE 72: slideDir = 0      ' up: the tile BELOW the gap moves up
      CASE 80: slideDir = 1      ' down: the tile ABOVE moves down
      CASE 75: slideDir = 2      ' left: the tile to the RIGHT moves left
      CASE 77: slideDir = 3      ' right: the tile to the LEFT moves right
    END SELECT
  END IF
  IF slideDir >= 0 THEN
    oldR = er: oldC = ec
    GOSUB Slide
    IF er <> oldR OR ec <> oldC THEN moves = moves + 1: SOUND 600, .3 ELSE SOUND 100, .5
  END IF
LOOP

secs = TIMER - t0!
LOCATE 18, 22: COLOR 10
PRINT "SOLVED in"; moves; "moves and"; secs; "seconds!"
COLOR 7
PLAY "MB T180 L8 CDEFG>C"
LOCATE 19, 26: PRINT "N = new puzzle, Esc = quit"
DO
  k$ = UCASE$(INKEY$)
  IF k$ = "N" THEN GOTO NewPuzzle
LOOP UNTIL k$ = CHR$(27)

Quit:
CLS
PRINT "Thanks for puzzling!"
END

' ---- move a tile into the gap.  slideDir: 0 up, 1 down, 2 left, 3 right ----
Slide:
  sr = er: sc = ec                       ' which tile will move?
  SELECT CASE slideDir
    CASE 0: sr = er + 1
    CASE 1: sr = er - 1
    CASE 2: sc = ec + 1
    CASE 3: sc = ec - 1
  END SELECT
  IF sr >= 1 AND sr <= SZ AND sc >= 1 AND sc <= SZ THEN
    tile(er, ec) = tile(sr, sc)          ' the tile slides into the gap...
    tile(sr, sc) = 0                     ' ...and leaves a new gap behind
    er = sr: ec = sc
  END IF
RETURN

' ---- draw the frame and tiles ----
DrawBoard:
  FOR r = 1 TO SZ
    FOR c = 1 TO SZ
      x = 26 + (c - 1) * 7: y = 4 + (r - 1) * 3
      IF tile(r, c) = 0 THEN
        COLOR 7, 0
        LOCATE y, x: PRINT "      ";
        LOCATE y + 1, x: PRINT "      ";
        LOCATE y + 2, x: PRINT "      ";
      ELSE
        ' tiles already in the right place are shown in green
        IF tile(r, c) = (r - 1) * SZ + c THEN COLOR 15, 2 ELSE COLOR 15, 1
        LOCATE y, x: PRINT CHR$(218); STRING$(4, 196); CHR$(191);
        LOCATE y + 1, x: PRINT CHR$(179); : PRINT USING "### "; tile(r, c); : PRINT CHR$(179);
        LOCATE y + 2, x: PRINT CHR$(192); STRING$(4, 196); CHR$(217);
      END IF
    NEXT
  NEXT
  COLOR 7, 0
  LOCATE 17, 30: PRINT "Moves:"; moves; "  "
RETURN
