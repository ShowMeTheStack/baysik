' ============================================================
' TITLE:    Unbeatable Tic-Tac-Toe
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     board game, ai, minimax, recursion, functions
' SUMMARY:  Play noughts and crosses against a computer that thinks every game through to the end.
' ------------------------------------------------------------
' WHAT IT DOES
'   You are X, the computer is O.  The computer chooses its moves
'   with the MINIMAX algorithm: it imagines every possible future
'   game, assumes you will always play your best, and picks the move
'   that works out best for it.  On "Perfect" difficulty you can
'   never win - the best you can do is a draw!  On "Easy" it
'   sometimes makes a random move instead.
'
' HOW TO USE
'   The board squares are numbered like a phone keypad turned over:
'        7 | 8 | 9
'        4 | 5 | 6
'        1 | 2 | 3
'   Press 1-9 to place your X.  After each game press Y to play
'   again (who starts alternates).  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Recursion: a FUNCTION that calls itself
'   * The minimax game-tree search with alpha-beta pruning
'   * Scoring wins faster (and losses slower) using search depth
'   * Using DATA to list the 8 winning lines
'
' THINGS TO TRY
'   * Count how many positions minimax looks at for the first move
'   * Remove the alpha-beta cut-off line and compare the position counts
'   * Change the Easy mistake chance in ComputerMove
' ============================================================

DECLARE FUNCTION Winner% ()
DECLARE FUNCTION Minimax% (player%, depth%, alpha%, beta%)
DECLARE FUNCTION ComputerMove% ()
DECLARE FUNCTION BoardFull% ()
DECLARE SUB DrawBoard ()

DEFINT A-Z
' board(1..9): 0 = empty, 1 = X (human), 2 = O (computer)
DIM SHARED board(1 TO 9), lines(1 TO 8, 1 TO 3), easy, nodes&

' The 8 ways to make three in a row (squares numbered 1-9 as above)
DATA 7,8,9, 4,5,6, 1,2,3, 7,4,1, 8,5,2, 9,6,3, 7,5,3, 9,5,1
FOR i = 1 TO 8: FOR j = 1 TO 3: READ lines(i, j): NEXT: NEXT

RANDOMIZE TIMER
humanWins = 0: cpuWins = 0: draws = 0
first = 1                                ' who moves first: 1 = human

CLS
PRINT "UNBEATABLE TIC-TAC-TOE"
PRINT
PRINT "Choose difficulty:  E = Easy    P = Perfect"
DO
  k$ = UCASE$(INKEY$)
  IF k$ = CHR$(27) THEN END
LOOP UNTIL k$ = "E" OR k$ = "P"
easy = (k$ = "E")

DO                                       ' ---- one game per pass ----
  FOR i = 1 TO 9: board(i) = 0: NEXT
  turn = first
  msg$ = ""
  DO
    DrawBoard
    LOCATE 20, 1: PRINT SPACE$(70)
    LOCATE 20, 1: PRINT msg$
    IF Winner <> 0 OR BoardFull THEN EXIT DO

    IF turn = 1 THEN
      ' ---- human turn: wait for a valid square ----
      LOCATE 18, 1: PRINT "Your move (1-9): ";
      DO
        k$ = INKEY$
        IF k$ = CHR$(27) THEN GOTO Quit
        sq = VAL(k$)
        ok = 0
        IF sq >= 1 AND sq <= 9 THEN IF board(sq) = 0 THEN ok = -1
      LOOP UNTIL ok
      board(sq) = 1
      SOUND 700, 1
      msg$ = ""
    ELSE
      LOCATE 18, 1: PRINT "Computer is thinking...    ";
      nodes& = 0
      sq = ComputerMove
      board(sq) = 2
      SOUND 400, 1
      msg$ = "Computer took square" + STR$(sq) + " after looking at" + STR$(nodes&) + " positions."
    END IF
    turn = 3 - turn                      ' switch 1 <-> 2
  LOOP

  ' ---- report the result ----
  LOCATE 18, 1: PRINT SPACE$(40)
  LOCATE 18, 1
  SELECT CASE Winner
    CASE 1: PRINT "You win! (Did you pick Easy?)": humanWins = humanWins + 1
            PLAY "MB T160 L8 CEG>C"
    CASE 2: PRINT "The computer wins.": cpuWins = cpuWins + 1
            PLAY "MB T160 L8 GEC<G"
    CASE ELSE: PRINT "A draw - well defended!": draws = draws + 1
  END SELECT
  LOCATE 22, 1
  PRINT "You:"; humanWins; "  Computer:"; cpuWins; "  Draws:"; draws
  PRINT "Play again? (Y/N) ";
  DO
    k$ = UCASE$(INKEY$)
  LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
  IF k$ <> "Y" THEN EXIT DO
  first = 3 - first                      ' take turns going first
LOOP

Quit:
CLS
PRINT "Thanks for playing!"
END

FUNCTION BoardFull%
  ' True when no empty square remains
  FOR i = 1 TO 9
    IF board(i) = 0 THEN BoardFull = 0: EXIT FUNCTION
  NEXT
  BoardFull = -1
END FUNCTION

FUNCTION ComputerMove%
  ' Try every empty square, score it with Minimax, keep the best.
  ' On Easy, 35% of the time just pick any empty square.
  IF easy AND RND < .35 THEN
    DO: sq = INT(RND * 9) + 1: LOOP UNTIL board(sq) = 0
    ComputerMove = sq
    EXIT FUNCTION
  END IF
  ' Opening book: on an empty board every move draws with perfect play,
  ' so skip the huge search (about 550,000 positions!) and take the
  ' centre or a corner.
  IF board(5) = 0 AND NOT BoardFull THEN
    empty = 0
    FOR sq = 1 TO 9: IF board(sq) = 0 THEN empty = empty + 1
    NEXT
    IF empty = 9 THEN
      ComputerMove = VAL(MID$("51379", INT(RND * 5) + 1, 1))
      EXIT FUNCTION
    END IF
  END IF
  best = -1000
  FOR sq = 1 TO 9
    IF board(sq) = 0 THEN
      board(sq) = 2                      ' try the move...
      s = Minimax(1, 1, -1000, 1000)     ' ...see how the game would go...
      board(sq) = 0                      ' ...and take it back
      ' Each root move is searched with the full window (-1000, 1000), so
      ' its score is exact; a little randomness among equally good moves
      ' keeps games varied.
      IF s > best OR (s = best AND RND < .4) THEN best = s: bestSq = sq
    END IF
  NEXT
  ComputerMove = bestSq
END FUNCTION

SUB DrawBoard
  ' Text board drawn with plain characters; numbers show free squares
  CLS
  PRINT "UNBEATABLE TIC-TAC-TOE      You = X   Computer = O"
  order$ = "789456123"                   ' screen order of the squares
  FOR row = 0 TO 2
    LOCATE 4 + row * 4, 20
    FOR col = 0 TO 2
      sq = VAL(MID$(order$, row * 3 + col + 1, 1))
      SELECT CASE board(sq)
        CASE 0: COLOR 8: PRINT "  "; LTRIM$(STR$(sq)); "  ";
        CASE 1: COLOR 14: PRINT "  X  ";
        CASE 2: COLOR 11: PRINT "  O  ";
      END SELECT
      COLOR 7
      IF col < 2 THEN PRINT CHR$(179);
    NEXT
    IF row < 2 THEN
      LOCATE 6 + row * 4, 20
      PRINT STRING$(5, 196); CHR$(197); STRING$(5, 196); CHR$(197); STRING$(5, 196)
    END IF
  NEXT
END SUB

FUNCTION Minimax% (player, depth, alpha, beta)
  ' Returns a score for the current board, seen from the computer's side:
  '   +10 - depth  computer can force a win (sooner is better)
  '   depth - 10   human can force a win  (later is better)
  '   0            best play leads to a draw
  ' "player" is whose turn it is now in this imagined game.
  '
  ' ALPHA-BETA PRUNING: alpha is the best score the computer is already
  ' sure of elsewhere in the tree, beta the best the human is sure of.
  ' Once alpha >= beta, the other side would never allow this line of
  ' play, so we can stop searching it.  The answer is the same as plain
  ' minimax but we look at far fewer positions.
  nodes& = nodes& + 1
  w = Winner
  IF w = 2 THEN Minimax = 10 - depth: EXIT FUNCTION
  IF w = 1 THEN Minimax = depth - 10: EXIT FUNCTION
  IF BoardFull THEN Minimax = 0: EXIT FUNCTION

  FOR sq = 1 TO 9
    IF board(sq) = 0 THEN
      board(sq) = player
      ' recursion: the other side replies.  QBasic passes variables BY
      ' REFERENCE, so (alpha) and (beta) are wrapped in brackets to pass
      ' copies - otherwise the deeper call would change OUR alpha and beta.
      s = Minimax(3 - player, depth + 1, (alpha), (beta))
      board(sq) = 0
      ' the computer (2) maximises the score, the human (1) minimises it
      IF player = 2 THEN
        IF s > alpha THEN alpha = s
      ELSE
        IF s < beta THEN beta = s
      END IF
      IF alpha >= beta THEN EXIT FOR      ' prune: no need to look further
    END IF
  NEXT
  IF player = 2 THEN Minimax = alpha ELSE Minimax = beta
END FUNCTION

FUNCTION Winner%
  ' 1 or 2 if that player has three in a row, otherwise 0
  FOR i = 1 TO 8
    a = board(lines(i, 1))
    IF a <> 0 THEN
      IF board(lines(i, 2)) = a AND board(lines(i, 3)) = a THEN Winner = a: EXIT FUNCTION
    END IF
  NEXT
  Winner = 0
END FUNCTION
