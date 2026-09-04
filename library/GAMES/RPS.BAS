' ============================================================
' TITLE:    Rock Paper Scissors - The Learning Machine
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     ai, machine learning, prediction, statistics, arrays
' SUMMARY:  Play Rock-Paper-Scissors against a computer that learns your habits as you play.
' ------------------------------------------------------------
' WHAT IT DOES
'   People are bad at being random.  This computer keeps a table of
'   what you played after each of your previous moves (a "Markov
'   chain").  If after Rock you usually play Paper, it expects Paper
'   next and plays Scissors to beat it.  At first it knows nothing and
'   plays randomly; the longer you play, the better it predicts you.
'   The screen shows its "brain" table so you can watch it learn.
'
' HOW TO USE
'   R = Rock    P = Paper    S = Scissors    Esc = quit
'   Rock blunts Scissors, Scissors cut Paper, Paper wraps Rock.
'
' CONCEPTS YOU WILL LEARN
'   * A tiny machine-learning model: counting what follows what
'   * 2-D array as a frequency table
'   * Using MOD to decide who wins:  (a - b + 3) MOD 3
'   * Tracking win percentages over time
'
' THINGS TO TRY
'   * Remember the last TWO moves (a 9 x 3 table) for a sharper AI
'   * Make the counts "fade" so the AI adapts when you change style
'   * Try to beat it by playing truly randomly - can you?
' ============================================================

DEFINT A-Z
' moves are numbered 0 = Rock, 1 = Paper, 2 = Scissors
DIM names$(0 TO 2)
names$(0) = "ROCK": names$(1) = "PAPER": names$(2) = "SCISSORS"
' counts(prev, nxt): how often you played nxt right after prev
DIM counts(0 TO 2, 0 TO 2)

RANDOMIZE TIMER
prev = -1                        ' no previous move yet
youWin = 0: cpuWin = 0: ties = 0: rounds = 0

DO
  ' ---------- the computer decides FIRST (no cheating!) ----------
  guess = -1
  IF prev >= 0 THEN
    ' predict your most frequent follow-up to your last move
    best = 0
    FOR m = 0 TO 2
      IF counts(prev, m) > best THEN best = counts(prev, m): guess = m
    NEXT
  END IF
  IF guess = -1 THEN
    cpu = INT(RND * 3)             ' nothing learned yet: random
  ELSE
    cpu = (guess + 1) MOD 3        ' the move that beats the predicted one
  END IF

  ' ---------- draw the screen ----------
  CLS
  COLOR 14: PRINT "  ROCK  PAPER  SCISSORS  -  the learning machine": COLOR 7
  PRINT
  PRINT "  Rounds:"; rounds; "  You:"; youWin; "  Computer:"; cpuWin; "  Ties:"; ties
  IF rounds > 0 THEN PRINT USING "  Computer win rate: ###%"; cpuWin * 100 \ rounds
  PRINT
  PRINT "  The computer's memory - what you played AFTER each move:"
  PRINT "                     next: ROCK  PAPER  SCISSORS"
  FOR p = 0 TO 2
    PRINT "  after "; names$(p); TAB(28);
    FOR m = 0 TO 2: PRINT USING "#####  "; counts(p, m); : NEXT
    IF p = prev THEN COLOR 11: PRINT " <- your last move"; : COLOR 7
    PRINT
  NEXT
  PRINT
  IF result$ <> "" THEN
    PRINT "  Last round: you "; lastYou$; ", computer "; lastCpu$
    COLOR 15: PRINT "  "; result$: COLOR 7
  END IF
  LOCATE 20, 3: PRINT "Your move:  R)ock   P)aper   S)cissors   (Esc quits)"

  ' ---------- your move ----------
  DO
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) THEN GOTO Quit
    you = INSTR("RPS", k$) - 1
  LOOP UNTIL you >= 0 AND LEN(k$) = 1

  ' ---------- who won? ----------
  ' (you - cpu + 3) MOD 3 is 0 for a tie, 1 if you win, 2 if you lose,
  ' because each move beats the one just before it in the order R, P, S.
  rounds = rounds + 1
  SELECT CASE (you - cpu + 3) MOD 3
    CASE 0: ties = ties + 1: result$ = "It's a tie.": SOUND 500, 1
    CASE 1: youWin = youWin + 1: result$ = "You win!": SOUND 900, 1: SOUND 1200, 1
    CASE 2: cpuWin = cpuWin + 1: result$ = "The computer wins.": SOUND 200, 2
  END SELECT
  lastYou$ = names$(you): lastCpu$ = names$(cpu)

  ' ---------- learn ----------
  IF prev >= 0 THEN counts(prev, you) = counts(prev, you) + 1
  prev = you
LOOP

Quit:
CLS
PRINT "Final: you"; youWin; " computer"; cpuWin; " ties"; ties
IF rounds >= 10 THEN
  IF cpuWin > youWin THEN PRINT "The machine learned your habits!" ELSE PRINT "You out-thought the machine!"
END IF
END
