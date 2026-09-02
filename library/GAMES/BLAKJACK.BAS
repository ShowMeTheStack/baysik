' ============================================================
' TITLE:    Blackjack 21
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     cards, casino, shuffle, arrays, betting
' SUMMARY:  Bet chips and try to beat the dealer's hand without going over 21.
' ------------------------------------------------------------
' WHAT IT DOES
'   A full single-deck game of Blackjack.  You start with 100 chips.
'   Cards 2-10 count face value, J/Q/K count 10, and an Ace counts 11
'   unless that would bust you, then it counts 1.  The dealer must
'   draw until reaching 17 or more.  A two-card 21 ("Blackjack")
'   pays 3 to 2.  The deck is reshuffled when it runs low.
'
' HOW TO USE
'   Type your bet and press Enter (0 or Esc to leave the table).
'   Then:  H = Hit (take a card)   S = Stand   D = Double down
'   (double your bet, take exactly one more card).
'
' CONCEPTS YOU WILL LEARN
'   * Representing a deck as numbers 0-51 (rank = n MOD 13, suit = n \ 13)
'   * The Fisher-Yates shuffle
'   * Counting soft aces correctly
'   * Drawing small "cards" with box characters
'
' THINGS TO TRY
'   * Add "split" for pairs
'   * Use several decks (a "shoe") like real casinos
'   * Show the running card count to practise card counting
' ============================================================

DECLARE SUB Shuffle ()
DECLARE FUNCTION Deal% ()
DECLARE FUNCTION HandValue% (who%)
DECLARE SUB ShowHand (who%, row%, hideFirst%)

DEFINT A-Z
CONST YOU = 1, DEALER = 2
DIM SHARED deck(0 TO 51), nextCard
' hand(who, i) is card i held by YOU or the DEALER; cnt(who) = how many
DIM SHARED hand(1 TO 2, 1 TO 12), cnt(1 TO 2)

RANDOMIZE TIMER
Shuffle
chips = 100

DO
  CLS
  COLOR 14: PRINT "  B L A C K J A C K": COLOR 7
  PRINT
  PRINT "  You have"; chips; "chips."
  IF chips <= 0 THEN PRINT "  You're broke! The house always wins...": EXIT DO
  ' LINE INPUT accepts anything; VAL turns junk into 0, so no errors
  LOCATE 5, 3: PRINT "Your bet (1 -"; chips; ", 0 to quit): ";
  LINE INPUT "", b$
  bet = VAL(b$)
  IF bet <= 0 THEN EXIT DO
  IF bet > chips THEN bet = chips

  IF nextCard > 40 THEN Shuffle: LOCATE 6, 3: PRINT "(Shuffling the deck...)"
  cnt(YOU) = 2: cnt(DEALER) = 2
  hand(YOU, 1) = Deal: hand(DEALER, 1) = Deal
  hand(YOU, 2) = Deal: hand(DEALER, 2) = Deal

  ' ---- player's turn ----
  result$ = ""
  first = -1                      ' doubling is only allowed on the first move
  DO
    LOCATE 8, 3: PRINT "Dealer:"
    ShowHand DEALER, 9, -1  ' dealer's first card stays face down
    LOCATE 15, 3: PRINT "You:"; HandValue(YOU); "  "
    ShowHand YOU, 16, 0
    IF HandValue(YOU) = 21 AND cnt(YOU) = 2 THEN result$ = "BJ": EXIT DO
    IF HandValue(YOU) > 21 THEN result$ = "BUST": EXIT DO
    LOCATE 22, 3: PRINT "H = Hit   S = Stand";
    IF first AND chips >= bet * 2 THEN PRINT "   D = Double";
    PRINT SPACE$(20);
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    IF k$ = CHR$(27) THEN k$ = "S"
    IF k$ = "H" THEN cnt(YOU) = cnt(YOU) + 1: hand(YOU, cnt(YOU)) = Deal: SOUND 1200, .5: first = 0
    IF k$ = "D" AND first AND chips >= bet * 2 THEN
      bet = bet * 2
      cnt(YOU) = cnt(YOU) + 1: hand(YOU, cnt(YOU)) = Deal: SOUND 1200, .5
      IF HandValue(YOU) > 21 THEN result$ = "BUST"
      EXIT DO
    END IF
    IF cnt(YOU) = 12 THEN EXIT DO       ' (can't happen without busting, but safe)
  LOOP UNTIL k$ = "S"

  ' ---- dealer's turn: must hit below 17 ----
  IF result$ = "" THEN
    DO WHILE HandValue(DEALER) < 17
      cnt(DEALER) = cnt(DEALER) + 1: hand(DEALER, cnt(DEALER)) = Deal
    LOOP
  END IF

  ' ---- reveal and settle ----
  LOCATE 8, 3: PRINT "Dealer:"; HandValue(DEALER); "  "
  ShowHand DEALER, 9, 0
  LOCATE 15, 3: PRINT "You:"; HandValue(YOU); "  "
  ShowHand YOU, 16, 0
  pv = HandValue(YOU): dv = HandValue(DEALER)
  dealerBJ = (dv = 21 AND cnt(DEALER) = 2)
  LOCATE 22, 3: PRINT SPACE$(60); : LOCATE 22, 3
  COLOR 15
  IF result$ = "BUST" THEN
    PRINT "Bust! You lose"; bet; "chips."; : chips = chips - bet
  ELSEIF result$ = "BJ" AND NOT dealerBJ THEN
    PRINT "BLACKJACK! You win"; bet * 3 \ 2; "chips."; : chips = chips + bet * 3 \ 2
  ELSEIF dv > 21 THEN
    PRINT "Dealer busts - you win"; bet; "chips!"; : chips = chips + bet
  ELSEIF pv > dv THEN
    PRINT "You win"; bet; "chips!"; : chips = chips + bet
  ELSEIF pv < dv THEN
    PRINT "Dealer wins. You lose"; bet; "chips."; : chips = chips - bet
  ELSE
    PRINT "Push (a tie) - your bet comes back.";
  END IF
  COLOR 7
  SOUND 600, 1
  LOCATE 24, 3: PRINT "Press any key...";
  DO: k$ = INKEY$: LOOP UNTIL k$ <> ""
LOOP

PRINT
PRINT "  You leave the table with"; chips; "chips."
END

FUNCTION Deal%
  ' Take the next card off the top of the shuffled deck
  Deal = deck(nextCard)
  nextCard = nextCard + 1
END FUNCTION

FUNCTION HandValue% (who)
  ' Add the cards, counting every Ace as 11 at first.
  ' While over 21 and an Ace is still counted as 11, make it 1 instead.
  total = 0: aces = 0
  FOR i = 1 TO cnt(who)
    rank = hand(who, i) MOD 13 + 1          ' 1 = Ace ... 13 = King
    IF rank = 1 THEN
      total = total + 11: aces = aces + 1
    ELSEIF rank >= 10 THEN
      total = total + 10
    ELSE
      total = total + rank
    END IF
  NEXT
  DO WHILE total > 21 AND aces > 0
    total = total - 10: aces = aces - 1
  LOOP
  HandValue = total
END FUNCTION

SUB ShowHand (who, row, hideFirst)
  ' Draw each card as a little 5-wide box: rank on top, suit below.
  ' Suits use the PC's card symbols: CHR$(3) heart, 4 diamond, 5 club, 6 spade.
  ranks$ = "A 2 3 4 5 6 7 8 9 10J Q K "
  FOR i = 1 TO cnt(who)
    x = 3 + (i - 1) * 7
    rank = hand(who, i) MOD 13: suit = hand(who, i) \ 13
    IF i = 1 AND hideFirst THEN
      r$ = CHR$(177) + CHR$(177): s$ = CHR$(177)
      COLOR 9
    ELSE
      r$ = MID$(ranks$, rank * 2 + 1, 2): s$ = CHR$(3 + suit)
      IF suit < 2 THEN COLOR 12, 7 ELSE COLOR 0, 7   ' red or black ink
    END IF
    LOCATE row, x: PRINT r$; "   ";
    LOCATE row + 1, x: PRINT "  "; s$; "  ";
    LOCATE row + 2, x: PRINT "   "; r$;
    COLOR 7, 0
  NEXT
  LOCATE row + 3, 3: PRINT SPACE$(60);
END SUB

SUB Shuffle
  ' Fisher-Yates: walk from the end, swapping each card with a random
  ' card at or before it.  Every order is equally likely.
  FOR i = 0 TO 51: deck(i) = i: NEXT
  FOR i = 51 TO 1 STEP -1
    j = INT(RND * (i + 1))
    SWAP deck(i), deck(j)
  NEXT
  nextCard = 0
END SUB
