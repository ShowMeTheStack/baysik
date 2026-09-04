' ============================================================
' TITLE:    Five Dice (Yahtzee-lite)
' CATEGORY: Games
' LEVEL:    Advanced
' TAGS:     dice, scoring, arrays, select case, text mode
' SUMMARY:  Roll five dice up to three times a turn and fill a 13-box score card.
' ------------------------------------------------------------
' WHAT IT DOES
'   A solitaire version of the classic dice game.  Each turn you roll
'   five dice, keep the ones you like, and re-roll the rest - up to
'   three rolls in all.  Then you must score the dice in one empty
'   box of the score card.  After 13 turns the card is full.
'   Get 63+ in the top section (Ones..Sixes) for a 35-point bonus.
'
'   Boxes:  Ones..Sixes      = sum of that number
'           3 / 4 of a kind  = sum of all dice
'           Full House       = 25  (three of one + two of another)
'           Small Straight   = 30  (four in a row)
'           Large Straight   = 40  (five in a row)
'           Five of a Kind   = 50
'           Chance           = sum of all dice
'
' HOW TO USE
'   Keys 1-5 hold / release a die.  R rolls the dice that are not held.
'   S lets you score: then press the letter A-M of a free box.
'   The score each box WOULD get is shown in grey so you can compare.
'   Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Counting dice faces into a "histogram" array
'   * Detecting patterns (pairs, straights) from the counts
'   * A FUNCTION with SELECT CASE that returns a score
'   * Drawing dice faces with text characters
'
' THINGS TO TRY
'   * Add a second player
'   * Give 100 bonus points for extra Five of a Kinds
'   * Write an "advisor" that suggests which dice to hold
' ============================================================

DECLARE FUNCTION BoxScore% (box%)
DECLARE SUB DrawDie (i%, v%, held%)

DEFINT A-Z
DIM SHARED dice(1 TO 5), cnt(1 TO 6)
DIM held(1 TO 5), score(1 TO 13), used(1 TO 13)
DIM names$(1 TO 13)
DATA Ones,Twos,Threes,Fours,Fives,Sixes,3 of a Kind,4 of a Kind
DATA Full House,Small Straight,Large Straight,Five of a Kind,Chance
FOR i = 1 TO 13: READ names$(i): NEXT

RANDOMIZE TIMER

FOR turn = 1 TO 13
  FOR i = 1 TO 5: held(i) = 0: NEXT
  rolls = 0
  GOSUB RollDice

  ' ---- re-roll phase ----
  DO
    GOSUB DrawAll
    LOCATE 12, 2: PRINT "1-5 = hold / release a die"
    IF rolls < 3 THEN
      LOCATE 13, 2: PRINT "R   = roll again ("; 3 - rolls; "left)"
    ELSE
      LOCATE 13, 2: PRINT "No rolls left."
    END IF
    LOCATE 14, 2: PRINT "S   = score these dice"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = CHR$(27) THEN GOTO Quit
    IF k$ >= "1" AND k$ <= "5" THEN
      i = VAL(k$): held(i) = NOT held(i): SOUND 900, .3
    END IF
    IF k$ = "R" AND rolls < 3 THEN GOSUB RollDice
  LOOP UNTIL k$ = "S"

  ' ---- choose a box ----
  LOCATE 16, 2: COLOR 11: PRINT "Press the letter (A-M) of an"
  LOCATE 17, 2: PRINT "empty box to score it.": COLOR 7
  DO
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = CHR$(27) THEN GOTO Quit
    b = ASC(k$) - 64                  ' "A" -> 1, "B" -> 2 ...
    ok = 0
    IF b >= 1 AND b <= 13 AND LEN(k$) = 1 THEN IF used(b) = 0 THEN ok = -1
    IF NOT ok THEN SOUND 120, 1
  LOOP UNTIL ok
  score(b) = BoxScore(b): used(b) = -1
  IF score(b) > 0 THEN PLAY "MB T200 L16 CEG" ELSE SOUND 200, 2
NEXT

' ---- final total ----
turn = 13
GOSUB DrawAll
LOCATE 12, 2: PRINT "GAME OVER!  Final score:"; total
LOCATE 14, 2: PRINT "Press Esc to finish."
PLAY "MB T160 L8 CEGEC"
DO: LOOP UNTIL INKEY$ = CHR$(27)

Quit:
CLS
PRINT "Thanks for playing Five Dice!"
END

' ---- roll every die that is not held ----
RollDice:
  rolls = rolls + 1
  FOR spin = 1 TO 6                    ' a quick tumbling animation
    FOR i = 1 TO 5
      IF NOT held(i) THEN dice(i) = INT(RND * 6) + 1: DrawDie i, dice(i), 0
    NEXT
    SOUND 2000 + spin * 100, .2
    t! = TIMER: DO: LOOP WHILE TIMER < t! + .05 AND TIMER >= t!
  NEXT
  ' count how many of each face we have (used by BoxScore)
  FOR i = 1 TO 6: cnt(i) = 0: NEXT
  FOR i = 1 TO 5: cnt(dice(i)) = cnt(dice(i)) + 1: NEXT
RETURN

' ---- redraw the dice and the score card ----
DrawAll:
  CLS
  COLOR 14: LOCATE 1, 2: PRINT "FIVE DICE   turn"; turn; "of 13   roll"; rolls; "of 3": COLOR 7
  FOR i = 1 TO 5: DrawDie i, dice(i), held(i): NEXT
  upper = 0: total = 0
  FOR b = 1 TO 13
    LOCATE 9 + b - (b > 6), 42           ' (b > 6) is -1, so add a gap row
    PRINT CHR$(64 + b); ") "; names$(b); TAB(62);
    IF used(b) THEN
      COLOR 15: PRINT USING "###"; score(b): COLOR 7
      total = total + score(b)
      IF b <= 6 THEN upper = upper + score(b)
    ELSE
      COLOR 8: PRINT USING "###"; BoxScore(b): COLOR 7
    END IF
  NEXT
  bonus = 0: IF upper >= 63 THEN bonus = 35
  total = total + bonus
  LOCATE 8, 42: PRINT "Top:"; upper; "/ 63  bonus:"; bonus
  LOCATE 24, 42: COLOR 11: PRINT "TOTAL:"; total; : COLOR 7
RETURN

FUNCTION BoxScore% (box)
  ' Score the current dice for one box, using the face counts cnt().
  sum = 0: most = 0: pairs = 0: triple = 0
  FOR f = 1 TO 6
    sum = sum + f * cnt(f)
    IF cnt(f) > most THEN most = cnt(f)
    IF cnt(f) = 2 THEN pairs = -1
    IF cnt(f) = 3 THEN triple = -1
  NEXT
  ' longest run of consecutive faces that appear at least once
  inRow = 0: longest = 0
  FOR f = 1 TO 6
    IF cnt(f) > 0 THEN inRow = inRow + 1 ELSE inRow = 0
    IF inRow > longest THEN longest = inRow
  NEXT
  SELECT CASE box
    CASE 1 TO 6: BoxScore = box * cnt(box)
    CASE 7: IF most >= 3 THEN BoxScore = sum
    CASE 8: IF most >= 4 THEN BoxScore = sum
    CASE 9: IF pairs AND triple THEN BoxScore = 25
    CASE 10: IF longest >= 4 THEN BoxScore = 30
    CASE 11: IF longest = 5 THEN BoxScore = 40
    CASE 12: IF most = 5 THEN BoxScore = 50
    CASE 13: BoxScore = sum
  END SELECT
  ' (a FUNCTION that is never assigned returns 0 - that is the "no score")
END FUNCTION

SUB DrawDie (i, v, held)
  ' Each die is a 7x5 box of characters.  Pips are placed using a
  ' pattern string: 9 positions, "1" = pip, "0" = blank, read row by row.
  SELECT CASE v
    CASE 1: p$ = "000010000"
    CASE 2: p$ = "001000100"
    CASE 3: p$ = "001010100"
    CASE 4: p$ = "101000101"
    CASE 5: p$ = "101010101"
    CASE 6: p$ = "101101101"
  END SELECT
  x = 2 + (i - 1) * 8
  IF held THEN COLOR 0, 14 ELSE COLOR 0, 7
  LOCATE 3, x: PRINT "       ";
  FOR row = 0 TO 2
    LOCATE 4 + row, x: PRINT " ";
    FOR col = 0 TO 2
      IF MID$(p$, row * 3 + col + 1, 1) = "1" THEN PRINT CHR$(254); " "; ELSE PRINT "  ";
    NEXT
  NEXT
  LOCATE 7, x: PRINT "       ";
  COLOR 7, 0
  LOCATE 8, x + 2: PRINT LTRIM$(STR$(i));
  IF held THEN COLOR 14: LOCATE 9, x + 1: PRINT "HELD"; : COLOR 7 ELSE LOCATE 9, x + 1: PRINT "    ";
END SUB
