' ============================================================
' TITLE:    Connect Four
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     board game, ai, graphics, circle, paint, arrays
' SUMMARY:  Drop discs into a 7x6 grid and get four in a row before the computer does.
' ------------------------------------------------------------
' WHAT IT DOES
'   A colourful Connect Four board in VGA graphics.  You play red,
'   the computer plays yellow.  Discs fall to the lowest free slot of
'   the chosen column with a little animation.  The computer uses a
'   few simple rules instead of a deep search:
'     1. If it can win right now, it does.
'     2. If you could win next move, it blocks you.
'     3. It avoids moves that let you win straight after.
'     4. Otherwise it scores each column, liking the centre and
'        lines of its own discs.
'
' HOW TO USE
'   Left / Right arrows choose a column (or press 1-7 directly).
'   Space, Enter or Down arrow drops your disc.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * A 2-D array as a game board, with gravity
'   * Checking four-in-a-row in four directions with step vectors
'   * A rule-based AI ("try a move, check it, undo it")
'   * CIRCLE and PAINT to draw filled discs
'
' THINGS TO TRY
'   * Let the AI look two moves ahead
'   * Turn it into a two-player game
'   * Highlight the winning four discs
' ============================================================

DECLARE FUNCTION Wins% (p%)
DECLARE FUNCTION DropRow% (c%)
DECLARE FUNCTION AIMove% ()
DECLARE FUNCTION LineScore% (p%)
DECLARE SUB DrawDisc (r%, c%, colr%)
DECLARE SUB DrawBoard ()

DEFINT A-Z
CONST NR = 6, NC = 7              ' rows and columns
CONST CELL = 22                   ' size of one cell in pixels
CONST BX = 83, BY = 8              ' top-left corner of the board
CONST HUMAN = 1, CPU = 2
DIM SHARED g(1 TO NR, 1 TO NC)    ' 0 empty, 1 human, 2 computer
' four directions to look for lines: right, down, down-right, down-left
DIM SHARED dr(1 TO 4), dc(1 TO 4)
DATA 0,1, 1,0, 1,1, 1,-1
FOR i = 1 TO 4: READ dr(i), dc(i): NEXT

RANDOMIZE TIMER
SCREEN 13

NewGame:
ERASE g
DrawBoard
col = 4: moves = 0

DO
  ' ================= HUMAN TURN =================
  LOCATE 25, 1: PRINT "Your turn: arrows + Space     ";
  DO
    ' show a red disc floating above the selected column
    DrawDisc 0, col, 4
    DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
    DrawDisc 0, col, 0                    ' erase it before moving
    IF k$ = CHR$(27) THEN GOTO Quit
    k = 0: IF LEN(k$) = 2 THEN k = ASC(RIGHT$(k$, 1))
    IF k = 75 AND col > 1 THEN col = col - 1
    IF k = 77 AND col < NC THEN col = col + 1
    IF k$ >= "1" AND k$ <= "7" THEN col = VAL(k$)
    drop = (k$ = " " OR k$ = CHR$(13) OR k = 80 OR (k$ >= "1" AND k$ <= "7"))
    IF drop AND DropRow(col) = 0 THEN SOUND 100, 2: drop = 0   ' column full
  LOOP UNTIL drop
  GOSUB Animate
  g(r, col) = HUMAN: moves = moves + 1
  IF Wins(HUMAN) THEN msg$ = "YOU WIN!": GOTO GameOver
  IF moves = NR * NC THEN msg$ = "IT'S A DRAW": GOTO GameOver

  ' ================= COMPUTER TURN =================
  LOCATE 25, 1: PRINT "Computer is thinking...       ";
  t! = TIMER: DO: LOOP WHILE TIMER < t! + .4 AND TIMER >= t!   ' short pause
  saveCol = col
  col = AIMove
  disc = 14: GOSUB Animate: disc = 0
  g(r, col) = CPU: moves = moves + 1
  col = saveCol
  IF Wins(CPU) THEN msg$ = "COMPUTER WINS": GOTO GameOver
  IF moves = NR * NC THEN msg$ = "IT'S A DRAW": GOTO GameOver
LOOP

GameOver:
LOCATE 25, 1: PRINT msg$; " - Y = again, Esc = quit";
IF LEFT$(msg$, 3) = "YOU" THEN PLAY "MB T180 L8 CEG>C" ELSE PLAY "MB T120 L8 EC<A"
DO
  k$ = UCASE$(INKEY$)
  IF k$ = "Y" THEN GOTO NewGame
LOOP UNTIL k$ = CHR$(27) OR k$ = "N"

Quit:
SCREEN 0: WIDTH 80
PRINT "Thanks for playing Connect Four!"
END

' ---- make a disc fall down column col; sets r to its final row ----
Animate:
  r = DropRow(col)
  IF disc = 0 THEN c2 = 4 ELSE c2 = disc   ' red for you, yellow for CPU
  FOR rr = 1 TO r
    DrawDisc rr, col, c2
    SOUND 1000 - rr * 100, .3
    t! = TIMER: DO: LOOP WHILE TIMER < t! + .04 AND TIMER >= t!
    IF rr < r THEN DrawDisc rr, col, 0
  NEXT
RETURN

FUNCTION AIMove%
  ' Rule 1: win if possible.   Rule 2: block the human's win.
  FOR who = CPU TO HUMAN STEP -1
    FOR c = 1 TO NC
      r = DropRow(c)
      IF r THEN
        g(r, c) = who
        w = Wins(who)
        g(r, c) = 0
        IF w THEN AIMove = c: EXIT FUNCTION
      END IF
    NEXT
  NEXT
  ' Rules 3 and 4: score every legal column
  best = -32000
  FOR c = 1 TO NC
    r = DropRow(c)
    IF r THEN
      g(r, c) = CPU
      s = LineScore(CPU) - LineScore(HUMAN) + (4 - ABS(4 - c)) * 3
      ' would this move let the human drop a winner on top of it?
      IF r > 1 THEN
        g(r - 1, c) = HUMAN
        IF Wins(HUMAN) THEN s = s - 1000
        g(r - 1, c) = 0
      END IF
      g(r, c) = 0
      s = s + INT(RND * 3)                 ' a pinch of variety
      IF s > best THEN best = s: bestC = c
    END IF
  NEXT
  AIMove = bestC
END FUNCTION

SUB DrawBoard
  CLS
  LOCATE 1, 1: PRINT "CONNECT"; : LOCATE 2, 1: PRINT "FOUR"
  ' blue board with black holes
  LINE (BX - 4, BY + CELL - 4)-(BX + NC * CELL + 3, BY + (NR + 1) * CELL + 3), 1, BF
  FOR r = 1 TO NR
    FOR c = 1 TO NC
      DrawDisc r, c, 0
    NEXT
  NEXT
  FOR c = 1 TO NC                          ' column numbers under the board
    LOCATE 22, (BX + (c - 1) * CELL + CELL \ 2) \ 8 + 1: PRINT LTRIM$(STR$(c));
  NEXT
END SUB

SUB DrawDisc (r, c, colr)
  ' row 0 is the "hover" slot above the board
  x = BX + (c - 1) * CELL + CELL \ 2
  y = BY + r * CELL + CELL \ 2
  CIRCLE (x, y), CELL \ 2 - 3, colr
  PAINT (x, y), colr, colr
  IF colr = 0 AND r > 0 THEN CIRCLE (x, y), CELL \ 2 - 3, 9  ' rim of an empty hole
END SUB

FUNCTION DropRow% (c)
  ' The lowest empty row in column c, or 0 if the column is full
  FOR r = NR TO 1 STEP -1
    IF g(r, c) = 0 THEN DropRow = r: EXIT FUNCTION
  NEXT
  DropRow = 0
END FUNCTION

FUNCTION LineScore% (p)
  ' Counts "promising" windows of 4 cells that hold only p's discs:
  ' 2 discs = 2 points, 3 discs = 10 points.
  total = 0
  FOR r = 1 TO NR
    FOR c = 1 TO NC
      FOR d = 1 TO 4
        er = r + 3 * dr(d): ec = c + 3 * dc(d)     ' end of the window
        IF er >= 1 AND er <= NR AND ec >= 1 AND ec <= NC THEN
          mine = 0: theirs = 0
          FOR i = 0 TO 3
            v = g(r + i * dr(d), c + i * dc(d))
            IF v = p THEN mine = mine + 1 ELSE IF v <> 0 THEN theirs = theirs + 1
          NEXT
          IF theirs = 0 THEN
            IF mine = 2 THEN total = total + 2
            IF mine = 3 THEN total = total + 10
          END IF
        END IF
      NEXT
    NEXT
  NEXT
  LineScore = total
END FUNCTION

FUNCTION Wins% (p)
  ' True if player p has four in a row anywhere.
  ' From every cell we walk 3 more steps in each direction.
  FOR r = 1 TO NR
    FOR c = 1 TO NC
      IF g(r, c) = p THEN
        FOR d = 1 TO 4
          n = 1
          FOR i = 1 TO 3
            rr = r + i * dr(d): cc = c + i * dc(d)
            IF rr < 1 OR rr > NR OR cc < 1 OR cc > NC THEN EXIT FOR
            IF g(rr, cc) <> p THEN EXIT FOR
            n = n + 1
          NEXT
          IF n = 4 THEN Wins = -1: EXIT FUNCTION
        NEXT
      END IF
    NEXT
  NEXT
  Wins = 0
END FUNCTION
