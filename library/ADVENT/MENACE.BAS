' ============================================================
' TITLE:    MENACE - The Matchbox Learner
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Advanced
' TAGS:     machine learning, reinforcement learning, tic-tac-toe, ai
' SUMMARY:  A tic-tac-toe player that starts clueless and learns from rewards, like MENACE (1961).
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1961 Donald Michie built MENACE out of 304 matchboxes full of
'   coloured beads.  Every box stood for one board position; every
'   bead colour stood for one possible move.  To play, you shake the
'   box for the current position and pull out a random bead.
'   After the game:  WIN  -> add 3 beads of each colour that was used
'                    DRAW -> add 1 bead
'                    LOSS -> take away 1 bead
'   Good moves become more likely, bad ones fade away.  That is
'   REINFORCEMENT LEARNING, the same idea behind modern game AIs.
'   Here the "matchboxes" are rows of an array.  A board is turned
'   into a number 0..19682 (it is a 9-digit number in base 3) which
'   finds its box instantly.  MENACE plays X and always moves first.
'
' HOW TO USE
'   1  Play against MENACE (press 1-9 to place your O, Esc gives up)
'   2  Train it against a random player for 300 games
'   3  Peek inside the box for the empty board
'   Q  Quit
'
' CONCEPTS YOU WILL LEARN
'   * Reward and punishment as a learning rule
'   * Weighted random choice (more beads = more likely)
'   * Base-3 encoding of a board to index an array
'   * Measuring learning: watch the win/draw rate climb
'
' THINGS TO TRY
'   * Change the rewards (e.g. +1/0/-1) and see if it learns slower
'   * Train it against a perfect player instead of a random one
'   * Use the 8 board symmetries to share boxes (Michie's trick)
' ============================================================

DECLARE FUNCTION BoxFor% ()
DECLARE FUNCTION Winner% ()
DECLARE FUNCTION MenaceMove% ()
DECLARE SUB Learn (result%)
DECLARE SUB DrawBoard ()
DEFINT A-Z
CONST MAXBOX = 3000
DIM SHARED b(1 TO 9)                         ' 0 empty, 1 = X (MENACE), 2 = O
DIM SHARED boxOf(0 TO 19682)                 ' board code -> box number (0 = none yet)
DIM SHARED beads(1 TO MAXBOX, 1 TO 9), nBox
DIM SHARED histBox(1 TO 5), histMove(1 TO 5), nHist
DIM SHARED lines(1 TO 8, 1 TO 3)
DATA 1,2,3, 4,5,6, 7,8,9, 1,4,7, 2,5,8, 3,6,9, 1,5,9, 3,5,7
FOR i = 1 TO 8: FOR j = 1 TO 3: READ lines(i, j): NEXT j, i
RANDOMIZE TIMER
totW = 0: totD = 0: totL = 0

DO
  CLS
  COLOR 14: PRINT "MENACE - Machine Educable Noughts And Crosses Engine": COLOR 7
  PRINT "Boxes in use:"; nBox
  PRINT "Your record vs MENACE so far: MENACE won"; totW; " draws"; totD; " you won"; totL
  PRINT
  PRINT "1) Play   2) Train 300 games vs random   3) Peek at first box   Q) Quit"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL INSTR("123Q" + CHR$(27), k$) > 0 AND k$ <> ""
  SELECT CASE k$
    CASE "1"
      ' ---------------- a game against a human ----------------
      FOR i = 1 TO 9: b(i) = 0: NEXT
      nHist = 0: res = -1
      FOR turn = 1 TO 9
        IF turn MOD 2 = 1 THEN
          b(MenaceMove) = 1
        ELSE
          DrawBoard
          PRINT "Your move (1-9): ";
          DO
            k$ = INKEY$
            IF k$ = CHR$(27) THEN EXIT DO
            m = VAL(k$)
            ' BASIC checks EVERY part of an AND, so b(m) must only be
            ' looked at once we know m is 1..9 (b(0) would be an error).
            okMove = 0
            IF m >= 1 AND m <= 9 THEN
              IF b(m) = 0 THEN okMove = 1
            END IF
          LOOP UNTIL okMove
          IF k$ = CHR$(27) THEN res = 1: EXIT FOR      ' giving up counts as a MENACE win
          b(m) = 2
        END IF
        w = Winner
        IF w = 1 THEN res = 1: EXIT FOR
        IF w = 2 THEN res = 3: EXIT FOR
      NEXT
      IF res = -1 THEN res = 2
      DrawBoard
      SELECT CASE res
        CASE 1: PRINT "MENACE wins!": totW = totW + 1
        CASE 2: PRINT "A draw.": totD = totD + 1
        CASE 3: PRINT "You win! MENACE will remember that...": totL = totL + 1
      END SELECT
      Learn res
      PRINT "Press any key.": DO: LOOP WHILE INKEY$ = ""
    CASE "2"
      ' ---------------- self-training vs a random player ----------------
      PRINT "Training";
      w1 = 0: d1 = 0: l1 = 0
      FOR g = 1 TO 300
        FOR i = 1 TO 9: b(i) = 0: NEXT
        nHist = 0: res = 2
        FOR turn = 1 TO 9
          IF turn MOD 2 = 1 THEN
            b(MenaceMove) = 1
          ELSE
            DO: m = INT(RND * 9) + 1: LOOP UNTIL b(m) = 0
            b(m) = 2
          END IF
          w = Winner
          IF w = 1 THEN res = 1: EXIT FOR
          IF w = 2 THEN res = 3: EXIT FOR
        NEXT
        Learn res
        IF g > 200 THEN                     ' score only the last 100 games
          IF res = 1 THEN w1 = w1 + 1
          IF res = 2 THEN d1 = d1 + 1
          IF res = 3 THEN l1 = l1 + 1
        END IF
        IF g MOD 20 = 0 THEN PRINT ".";
      NEXT
      PRINT
      PRINT "Last 100 training games: won"; w1; " drew"; d1; " lost"; l1
      PRINT "(Train again and the losses should shrink.)"
      PRINT "Press any key.": DO: LOOP WHILE INKEY$ = ""
    CASE "3"
      FOR i = 1 TO 9: b(i) = 0: NEXT
      bx = BoxFor
      PRINT "Beads for each opening square (more = more likely):"
      FOR r = 0 TO 2
        FOR c = 1 TO 3: PRINT USING "#####"; beads(bx, r * 3 + c);: NEXT
        PRINT
      NEXT
      PRINT "Press any key.": DO: LOOP WHILE INKEY$ = ""
    CASE ELSE
      EXIT DO
  END SELECT
LOOP
PRINT "MENACE puts its beads away. Bye!"

' Find (or create) the matchbox for the current board.
' The board is read as a base-3 number: b(1) is the ones digit,
' b(2) the threes digit, b(3) the nines digit, and so on.
FUNCTION BoxFor%
  code& = 0: p& = 1
  FOR i = 1 TO 9
    code& = code& + b(i) * p&
    p& = p& * 3
  NEXT
  IF boxOf(code&) = 0 AND nBox < MAXBOX THEN
    nBox = nBox + 1
    boxOf(code&) = nBox
    ' Fresh boxes get beads for every empty square.  Like Michie,
    ' early positions get more beads (4) and later ones fewer.
    empties = 0
    FOR i = 1 TO 9
      IF b(i) = 0 THEN empties = empties + 1
    NEXT
    start = (empties + 1) \ 2
    FOR i = 1 TO 9
      IF b(i) = 0 THEN beads(nBox, i) = start ELSE beads(nBox, i) = 0
    NEXT
  END IF
  BoxFor% = boxOf(code&)
END FUNCTION

' Shake the box and pull out a bead: a weighted random choice.
FUNCTION MenaceMove%
  bx = BoxFor
  total = 0
  FOR i = 1 TO 9: total = total + beads(bx, i): NEXT
  IF total = 0 THEN
    ' an empty box: MENACE has learnt every move here loses.
    ' Refill it with one bead per empty square so play can go on.
    FOR i = 1 TO 9
      IF b(i) = 0 THEN beads(bx, i) = 1: total = total + 1
    NEXT
  END IF
  r = INT(RND * total) + 1               ' pick bead number r...
  FOR i = 1 TO 9
    r = r - beads(bx, i)                 ' ...and find which square owns it
    IF r <= 0 THEN EXIT FOR
  NEXT
  nHist = nHist + 1
  histBox(nHist) = bx: histMove(nHist) = i
  MenaceMove% = i
END FUNCTION

' Reward or punish every move MENACE made this game.
' result: 1 = MENACE won, 2 = draw, 3 = MENACE lost
SUB Learn (result)
  SELECT CASE result
    CASE 1: delta = 3
    CASE 2: delta = 1
    CASE ELSE: delta = -1
  END SELECT
  FOR h = 1 TO nHist
    bx = histBox(h): m = histMove(h)
    beads(bx, m) = beads(bx, m) + delta
    IF beads(bx, m) < 0 THEN beads(bx, m) = 0
    IF beads(bx, m) > 200 THEN beads(bx, m) = 200    ' keep numbers sensible
  NEXT
END SUB

' Return 1 if X has three in a row, 2 if O has, otherwise 0.
FUNCTION Winner%
  Winner% = 0
  FOR i = 1 TO 8
    a = b(lines(i, 1))
    IF a <> 0 AND a = b(lines(i, 2)) AND a = b(lines(i, 3)) THEN Winner% = a: EXIT FUNCTION
  NEXT
END FUNCTION

SUB DrawBoard
  PRINT
  FOR r = 0 TO 2
    PRINT "   ";
    FOR c = 1 TO 3
      i = r * 3 + c
      SELECT CASE b(i)
        CASE 0: COLOR 8: PRINT LTRIM$(STR$(i));
        CASE 1: COLOR 12: PRINT "X";
        CASE 2: COLOR 11: PRINT "O";
      END SELECT
      COLOR 7
      IF c < 3 THEN PRINT " | ";
    NEXT
    PRINT
    IF r < 2 THEN PRINT "   --+---+--"
  NEXT
  PRINT
END SUB
