' ============================================================
' TITLE:    Hi-Lo Card Streak
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     cards, probability, guessing, text mode
' SUMMARY:  Guess whether the next card will be higher or lower and build the longest streak.
' ------------------------------------------------------------
' WHAT IT DOES
'   A card is turned face up.  You guess if the next card from the
'   deck will be HIGHER or LOWER (Aces are low, Kings are high).
'   Each right guess adds to your streak; a wrong guess ends it.
'   If the cards are equal it's a free pass.  The program also shows
'   the real odds of each choice, computed from the cards left in the
'   deck, so you can learn to play the percentages.
'
' HOW TO USE
'   H or Up arrow = higher,  L or Down arrow = lower.  Esc quits.
'   When the deck runs out it is reshuffled.
'
' CONCEPTS YOU WILL LEARN
'   * Counting what is left in a deck to work out probabilities
'   * Converting a card number (0-51) into rank and suit
'   * Keeping a "best so far" record
'
' THINGS TO TRY
'   * Turn the odds display off and see if your streaks get shorter
'   * Make a bet before each guess and pay out by the odds
'   * Make the computer play by always choosing the better odds
' ============================================================

DEFINT A-Z
DIM deck(0 TO 51), remain(1 TO 13)      ' remain(r) = cards of rank r still in the deck
ranks$ = "A 2 3 4 5 6 7 8 9 10J Q K "

RANDOMIZE TIMER
GOSUB Shuffle
streak = 0: best = 0
cur = deck(deckPos): deckPos = deckPos + 1
remain(cur MOD 13 + 1) = remain(cur MOD 13 + 1) - 1

DO
  ' ---- work out the odds for the next card ----
  r = cur MOD 13 + 1                 ' rank 1 (Ace) .. 13 (King)
  hi = 0: lo = 0: total = 0
  FOR i = 1 TO 13
    total = total + remain(i)
    IF i > r THEN hi = hi + remain(i)
    IF i < r THEN lo = lo + remain(i)
  NEXT

  CLS
  COLOR 14: PRINT "  H I - L O   C A R D   S T R E A K": COLOR 7
  PRINT
  PRINT "  Current streak:"; streak; "     Best:"; best
  PRINT "  Cards left in deck:"; total
  card = cur: row = 7: GOSUB DrawCard
  LOCATE 7, 20: PRINT "Will the next card be..."
  LOCATE 9, 20: PRINT "H = HIGHER  ("; : PRINT USING "###%"; hi * 100 \ total; : PRINT " chance)"
  LOCATE 10, 20: PRINT "L = LOWER   ("; : PRINT USING "###%"; lo * 100 \ total; : PRINT " chance)"
  LOCATE 11, 20: PRINT "(same rank is a free pass:"; (total - hi - lo) * 100 \ total; "%)"

  DO
    k$ = UCASE$(INKEY$)
    IF k$ = CHR$(27) THEN GOTO Quit
    IF k$ = CHR$(0) + "H" THEN k$ = "H"      ' up arrow
    IF k$ = CHR$(0) + "P" THEN k$ = "L"      ' down arrow
  LOOP UNTIL k$ = "H" OR k$ = "L"

  ' ---- turn over the next card ----
  nxt = deck(deckPos): deckPos = deckPos + 1
  n = nxt MOD 13 + 1
  remain(n) = remain(n) - 1
  card = nxt: row = 14: GOSUB DrawCard
  LOCATE 15, 20
  IF n = r THEN
    PRINT "Same rank - free pass!"
    SOUND 500, 2
  ELSEIF (n > r AND k$ = "H") OR (n < r AND k$ = "L") THEN
    streak = streak + 1
    IF streak > best THEN best = streak
    PRINT "Correct! Streak:"; streak
    SOUND 800, 1: SOUND 1200, 1
  ELSE
    PRINT "Wrong! Your streak of"; streak; "is over."
    streak = 0
    SOUND 150, 6
  END IF
  cur = nxt
  IF deckPos > 51 THEN
    LOCATE 17, 20: PRINT "Deck finished - reshuffling."
    GOSUB Shuffle
    remain(cur MOD 13 + 1) = remain(cur MOD 13 + 1) - 1   ' current card stays on the table
  END IF
  LOCATE 19, 20: PRINT "Press any key for the next card"
  DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
  IF k$ = CHR$(27) THEN EXIT DO
LOOP

Quit:
CLS
PRINT "Your best streak was"; best
END

' ---- shuffle 52 cards and reset the counts ----
Shuffle:
  FOR i = 0 TO 51: deck(i) = i: NEXT
  FOR i = 51 TO 1 STEP -1
    j = INT(RND * (i + 1)): SWAP deck(i), deck(j)
  NEXT
  FOR i = 1 TO 13: remain(i) = 4: NEXT
  deckPos = 0
RETURN

' ---- draw card number "card" as a box at screen row "row" ----
DrawCard:
  suit = card \ 13
  r$ = MID$(ranks$, (card MOD 13) * 2 + 1, 2)
  IF suit < 2 THEN fg = 12 ELSE fg = 0          ' hearts/diamonds are red
  COLOR fg, 7
  LOCATE row, 5: PRINT r$; "     ";
  LOCATE row + 1, 5: PRINT "       ";
  LOCATE row + 2, 5: PRINT "   "; CHR$(3 + suit); "   ";
  LOCATE row + 3, 5: PRINT "       ";
  LOCATE row + 4, 5: PRINT "     "; r$;
  COLOR 7, 0
RETURN
