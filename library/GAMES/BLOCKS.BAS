' ============================================================
' TITLE:    Falling Blocks
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     action, puzzle, rotation, arrays, timer, text mode
' SUMMARY:  Rotate and drop seven kinds of four-square pieces to complete and clear rows.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pieces made of four squares fall into a well 10 wide and 20 deep.
'   Move and rotate them so they fit together.  Every completely
'   filled row disappears and everything above drops down.  Clearing
'   several rows at once scores much more.  Every 10 rows the level
'   goes up and pieces fall faster.  The game ends when a new piece
'   has no room to appear.
'
' HOW TO USE
'   Left / Right arrows  move        Up arrow (or X)  rotate
'   Down arrow           soft drop   Space            hard drop
'   P pauses, Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Shapes stored as lists of (x, y) offsets from a centre square
'   * Rotating a point by 90 degrees:  (x, y) -> (-y, x)
'   * "Try the move, and undo it if it collides" logic
'   * Removing full rows by copying the rows above down
'   * Gravity driven by TIMER, independent of the keyboard
'
' THINGS TO TRY
'   * Add a "ghost" showing where the piece will land
'   * Add a hold-piece key
'   * Change the scores in the DATA line
' ============================================================

DECLARE FUNCTION Fits% (px%, py%)
DECLARE SUB DrawPiece (px%, py%, colr%)

DEFINT A-Z
CONST BW = 10, BH = 20               ' size of the well
CONST LX = 30, TY = 2                ' screen column / row of the well

DIM SHARED well(0 TO BW - 1, -4 TO BH - 1)  ' 0 empty, else a colour; rows above 0 are hidden
DIM SHARED cx(1 TO 4), cy(1 TO 4)   ' the falling piece's 4 squares (offsets)
DIM shapeX(1 TO 7, 1 TO 4), shapeY(1 TO 7, 1 TO 4), shapeCol(1 TO 7)
DIM oldX(1 TO 4), oldY(1 TO 4), lineScore(0 TO 4)
DIM fallTime AS SINGLE, lastFall AS SINGLE

' Seven shapes: colour, then four (x, y) offsets.  (0, 0) is the
' square the piece rotates around.  y grows DOWNWARDS on screen.
' In order: I, O (never rotates), T, S, Z, J, L
DATA 11, -1,0, 0,0, 1,0, 2,0
DATA 14,  0,0, 1,0, 0,1, 1,1
DATA 13, -1,0, 0,0, 1,0, 0,-1
DATA 10,  0,0, 1,0, -1,1, 0,1
DATA 12, -1,0, 0,0, 0,1, 1,1
DATA  9, -1,-1, -1,0, 0,0, 1,0
DATA  6,  1,-1, -1,0, 0,0, 1,0
FOR s = 1 TO 7
  READ shapeCol(s)
  FOR i = 1 TO 4: READ shapeX(s, i), shapeY(s, i): NEXT
NEXT
DATA 0, 40, 100, 300, 1200
FOR i = 0 TO 4: READ lineScore(i): NEXT

RANDOMIZE TIMER
CLS
COLOR 7
' ---- draw the well's walls ----
FOR y = 0 TO BH
  LOCATE TY + y, LX - 1: PRINT CHR$(186);
  LOCATE TY + y, LX + BW * 2: PRINT CHR$(186);
NEXT
LOCATE TY + BH, LX - 1: PRINT CHR$(200); STRING$(BW * 2, 205); CHR$(188);
FOR y = 0 TO BH - 1: LOCATE TY + y, LX: PRINT SPACE$(BW * 2); : NEXT
COLOR 14: LOCATE 2, 4: PRINT "FALLING BLOCKS": COLOR 7
LOCATE 4, 4: PRINT CHR$(27); " "; CHR$(26); "  move"
LOCATE 5, 4: PRINT CHR$(24); "    rotate"
LOCATE 6, 4: PRINT CHR$(25); "    soft drop"
LOCATE 7, 4: PRINT "Space hard drop"
LOCATE 8, 4: PRINT "P pause  Esc quit"
LOCATE 3, 56: PRINT "NEXT:"

score = 0: rows = 0: level = 1
fallTime = .8
nextShape = INT(RND * 7) + 1

' ================= one piece at a time =================
DO
  shape = nextShape
  nextShape = INT(RND * 7) + 1
  ' preview the next piece in a small box
  FOR y = 5 TO 8: LOCATE y, 56: PRINT SPACE$(10); : NEXT
  COLOR shapeCol(nextShape)
  FOR i = 1 TO 4
    LOCATE 6 + shapeY(nextShape, i), 59 + shapeX(nextShape, i) * 2: PRINT CHR$(219); CHR$(219);
  NEXT
  COLOR 7
  GOSUB ShowScore

  FOR i = 1 TO 4: cx(i) = shapeX(shape, i): cy(i) = shapeY(shape, i): NEXT
  px = BW \ 2 - 1: py = 0
  IF NOT Fits(px, py) THEN EXIT DO           ' no room: game over
  DrawPiece px, py, shapeCol(shape)
  lastFall = TIMER
  landed = 0

  DO
    k$ = INKEY$
    nx = px: ny = py
    IF k$ = CHR$(27) THEN GOTO Quit
    IF UCASE$(k$) = "P" THEN
      LOCATE 12, 4: PRINT "PAUSED - any key"
      DO: LOOP WHILE INKEY$ = ""
      LOCATE 12, 4: PRINT SPACE$(16)
      lastFall = TIMER
    END IF
    k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    IF k = 75 THEN nx = px - 1            ' left
    IF k = 77 THEN nx = px + 1            ' right
    IF k = 80 THEN ny = py + 1: score = score + 1   ' soft drop earns 1 point
    IF (k = 72 OR UCASE$(k$) = "X") AND shape <> 2 THEN GOSUB Rotate
    IF k$ = " " THEN
      ' hard drop: fall until the next row down would collide
      DrawPiece px, py, 0
      DO WHILE Fits(px, py + 1): py = py + 1: score = score + 2: LOOP
      DrawPiece px, py, shapeCol(shape)
      landed = -1
    END IF

    ' gravity: one row every fallTime seconds
    IF TIMER - lastFall >= fallTime OR TIMER < lastFall THEN
      ny = py + 1: lastFall = TIMER
    END IF

    IF NOT landed AND (nx <> px OR ny <> py) THEN
      IF Fits(nx, ny) THEN
        DrawPiece px, py, 0                 ' erase, move, redraw
        px = nx: py = ny
        DrawPiece px, py, shapeCol(shape)
      ELSEIF ny > py THEN
        landed = -1                          ' tried to go down and couldn't
      END IF
    END IF
  LOOP UNTIL landed

  ' ---- lock the piece into the well ----
  FOR i = 1 TO 4: well(px + cx(i), py + cy(i)) = shapeCol(shape): NEXT
  SOUND 220, .5
  GOSUB ClearRows
LOOP

' ---- game over ----
LOCATE 12, 4: COLOR 12: PRINT "GAME OVER": COLOR 7
LOCATE 14, 4: PRINT "Press Esc"
PLAY "MB T120 L8 E D C <B A2"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
CLS
PRINT "Falling Blocks - score:"; score; " rows:"; rows
END

' ---- rotate 90 degrees clockwise: (x, y) -> (-y, x) ----
Rotate:
  FOR i = 1 TO 4: oldX(i) = cx(i): oldY(i) = cy(i): NEXT  ' remember old shape
  DrawPiece px, py, 0
  FOR i = 1 TO 4: cx(i) = -oldY(i): cy(i) = oldX(i): NEXT
  ' "wall kick": if it doesn't fit, try nudging it sideways
  IF Fits(px, py) THEN
    ok = -1
  ELSEIF Fits(px + 1, py) THEN
    px = px + 1: ok = -1
  ELSEIF Fits(px - 1, py) THEN
    px = px - 1: ok = -1
  ELSE
    ok = 0
  END IF
  IF NOT ok THEN FOR i = 1 TO 4: cx(i) = oldX(i): cy(i) = oldY(i): NEXT
  DrawPiece px, py, shapeCol(shape)
  nx = px
RETURN

' ---- remove full rows, score them, redraw the well ----
ClearRows:
  cleared = 0
  y = BH - 1
  DO WHILE y >= 0
    full = -1
    FOR x = 0 TO BW - 1
      IF well(x, y) = 0 THEN full = 0: EXIT FOR
    NEXT
    IF full THEN
      cleared = cleared + 1
      ' copy every row above down by one
      FOR yy = y TO -3 STEP -1
        FOR x = 0 TO BW - 1: well(x, yy) = well(x, yy - 1): NEXT
      NEXT
      FOR x = 0 TO BW - 1: well(x, -4) = 0: NEXT
      ' (don't move y: the row that dropped into it must be checked too)
    ELSE
      y = y - 1
    END IF
  LOOP
  IF cleared THEN
    FOR f = 1 TO cleared: SOUND 600 + f * 200, 1: NEXT
    score = score + lineScore(cleared) * level
    rows = rows + cleared
    level = rows \ 10 + 1
    fallTime = .8 - (level - 1) * .07
    IF fallTime < .1 THEN fallTime = .1
    ' redraw the whole well from the array
    FOR y = 0 TO BH - 1
      LOCATE TY + y, LX
      FOR x = 0 TO BW - 1
        IF well(x, y) THEN COLOR well(x, y): PRINT CHR$(219); CHR$(219); ELSE PRINT "  ";
      NEXT
    NEXT
    COLOR 7
  END IF
RETURN

ShowScore:
  LOCATE 12, 56: PRINT "SCORE"; score
  LOCATE 14, 56: PRINT "ROWS "; rows
  LOCATE 16, 56: PRINT "LEVEL"; level
RETURN

SUB DrawPiece (px, py, colr)
  ' colour 0 erases.  Squares above the top of the well are not drawn.
  COLOR colr
  FOR i = 1 TO 4
    y = py + cy(i)
    IF y >= 0 THEN
      LOCATE TY + y, LX + (px + cx(i)) * 2
      IF colr THEN PRINT CHR$(219); CHR$(219); ELSE PRINT "  ";
    END IF
  NEXT
  COLOR 7
END SUB

FUNCTION Fits% (px, py)
  ' True if every square of the piece is inside the well and empty
  FOR i = 1 TO 4
    x = px + cx(i): y = py + cy(i)
    IF x < 0 OR x >= BW OR y >= BH OR y < -4 THEN Fits = 0: EXIT FUNCTION
    IF well(x, y) THEN Fits = 0: EXIT FUNCTION
  NEXT
  Fits = -1
END FUNCTION
