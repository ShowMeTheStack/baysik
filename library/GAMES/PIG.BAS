' ============================================================
' TITLE:    Pig - The Push-Your-Luck Dice Game
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     dice, strategy, probability, two-player, text mode
' SUMMARY:  Roll a die again and again to build points - but a 1 wipes out your whole turn!
' ------------------------------------------------------------
' WHAT IT DOES
'   You race the computer to 100 points.  On your turn you roll one
'   die as many times as you like, adding each roll to your turn
'   total.  When you HOLD, the turn total is banked into your score.
'   But if you roll a 1 you lose everything you built up this turn
'   and play passes to the other side.  The computer uses the famous
'   "hold at 20" strategy, but gets bolder when it is behind.
'
' HOW TO USE
'   R (or Space) = roll     H (or Enter) = hold     Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Random numbers: INT(RND * 6) + 1 gives 1..6
'   * Turn-based game loops with two players
'   * A simple strategy rule for an AI opponent
'   * Expected value: why "hold at 20" works (see the comment below)
'
' THINGS TO TRY
'   * Change the computer's limit and see who wins more often
'   * Play with two dice: a single 1 loses the turn, double 1s lose all
'   * Make it a two-human game
' ============================================================

DEFINT A-Z
CONST TARGET = 100

RANDOMIZE TIMER
you = 0: cpu = 0
player = 1                       ' 1 = you, 2 = computer

CLS
COLOR 13: PRINT "  P I G": COLOR 7
PRINT "  First to"; TARGET; "wins.  A roll of 1 loses your turn total!"
PRINT

DO
  turnTotal = 0
  IF player = 1 THEN
    ' ================= YOUR TURN =================
    PRINT : COLOR 14: PRINT "  YOUR TURN  (you"; you; " computer"; cpu; ")": COLOR 7
    DO
      PRINT "  Turn total"; turnTotal; "- R)oll or H)old? ";
      DO
        k$ = UCASE$(INKEY$)
        IF k$ = CHR$(27) THEN GOTO Quit
      LOOP UNTIL k$ = "R" OR k$ = " " OR k$ = "H" OR k$ = CHR$(13)
      IF k$ = "H" OR k$ = CHR$(13) THEN
        PRINT "hold."
        you = you + turnTotal
        EXIT DO
      END IF
      GOSUB RollDie
      IF d = 1 THEN turnTotal = 0: EXIT DO
      turnTotal = turnTotal + d
      IF you + turnTotal >= TARGET THEN you = you + turnTotal: EXIT DO
    LOOP
  ELSE
    ' ================= COMPUTER TURN =================
    PRINT : COLOR 11: PRINT "  COMPUTER'S TURN": COLOR 7
    ' Why 20?  Each roll wins on average (2+3+4+5+6)/6 = 3.33 points but
    ' risks losing the turn total with chance 1/6.  Rolling is only worth
    ' it while 3.33 > turnTotal/6, i.e. while turnTotal < 20.
    limit = 20
    IF you - cpu > 30 THEN limit = 28      ' far behind: take more risks
    IF TARGET - cpu < limit THEN limit = TARGET - cpu ' go for the win
    DO
      t! = TIMER: DO: LOOP WHILE TIMER < t! + .5 AND TIMER >= t!
      PRINT "  Computer rolls... ";
      GOSUB RollDie
      IF d = 1 THEN turnTotal = 0: EXIT DO
      turnTotal = turnTotal + d
      IF turnTotal >= limit THEN
        PRINT "  Computer holds with"; turnTotal
        cpu = cpu + turnTotal
        EXIT DO
      END IF
    LOOP
  END IF

  IF you >= TARGET OR cpu >= TARGET THEN EXIT DO
  player = 3 - player
LOOP

PRINT
IF you >= TARGET THEN
  COLOR 10: PRINT "  YOU WIN,"; you; "to"; cpu; "!": PLAY "MB T180 L8 CEG>C"
ELSE
  COLOR 12: PRINT "  The computer wins,"; cpu; "to"; you: PLAY "MB T120 L8 G E C"
END IF
COLOR 7
PRINT "  Press any key."
DO: LOOP UNTIL INKEY$ <> ""

Quit:
COLOR 7
PRINT
PRINT "  Final score - you:"; you; " computer:"; cpu
END

' ---- roll one die, show it, and react to a 1 ----
RollDie:
  d = INT(RND * 6) + 1
  PRINT "rolled a"; d;
  IF d = 1 THEN
    COLOR 12: PRINT " - PIG! Turn total lost.": COLOR 7
    SOUND 120, 5
  ELSE
    PRINT
    SOUND 400 + d * 80, 1
  END IF
RETURN
