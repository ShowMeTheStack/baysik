' ============================================================
' TITLE:    Twenty Questions
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Advanced
' TAGS:     ai, information, decision making, arrays, game
' SUMMARY:  The computer picks the smartest yes/no question each turn to read your mind.
' ------------------------------------------------------------
' WHAT IT DOES
'   You think of one of 16 everyday things.  The computer has a
'   knowledge table: for each thing, a row of yes/no facts.
'   Each turn it chooses the question that splits the things it
'   still suspects as close to HALF-AND-HALF as possible.  That is
'   the best possible move: whatever you answer, about half the
'   suspects are crossed off.  16 things -> 8 -> 4 -> 2 -> 1, so it
'   usually needs only 4 or 5 questions, not 20!
'   If you are unsure, answer "?" and that question is ignored.
'   Each suspect counts its "mistakes", so one wrong answer from
'   you does not ruin the game.
'
' HOW TO USE
'   Pick one: apple banana cat dog goldfish elephant car bicycle
'   pencil book television smartphone tree sun chair pizza.
'   Answer Y, N or ? to each question.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * A knowledge base stored as strings of 1s and 0s
'   * Greedy choice: pick the most "informative" question
'   * Why halving is so powerful (binary search, 2^20 = 1,048,576)
'   * Tolerating noise by counting mismatches instead of deleting
'
' THINGS TO TRY
'   * Add a 17th thing and a 13th question (update every row!)
'   * Show the remaining suspects after each answer
'   * Make it play the other way round: YOU ask, it answers
' ============================================================

DEFINT A-Z
CONST NT = 16, NQ = 12
DIM thing$(1 TO NT), fact$(1 TO NT), q$(1 TO NQ)
DIM miss(1 TO NT), asked(1 TO NQ)

DATA "Is it alive (or was it ever alive)","Can you eat it","Is it bigger than a shoebox"
DATA "Does it use electricity","Is it an animal","Does it have wheels"
DATA "Is it usually found indoors","Is it yellow","Can you hold it in one hand"
DATA "Does it have legs","Is it made by people","Can it make a sound"
FOR i = 1 TO NQ: READ q$(i): NEXT

' Each fact string has one character per question above:
'  1 = yes, 0 = no.     question:  123456789012
DATA apple,                       110000000100
DATA banana,                      110000010100
DATA cat,                         100010100101
DATA dog,                         100010000101
DATA goldfish,                    100010111000
DATA elephant,                    101010000101
DATA car,                         001101000011
DATA bicycle,                     001001000011
DATA pencil,                      000000111010
DATA book,                        000000101010
DATA television,                  001100100011
DATA smartphone,                  000100101011
DATA tree,                        101000000000
DATA sun,                         001000010000
DATA chair,                       001000100110
DATA pizza,                       010000100010
FOR i = 1 TO NT: READ thing$(i), fact$(i): NEXT

DO
  CLS
  COLOR 14: PRINT "TWENTY QUESTIONS": COLOR 7
  PRINT "Think of one of these:"
  FOR i = 1 TO NT
    PRINT "  "; thing$(i);
    IF i MOD 8 = 0 THEN PRINT          ' 8 names per line
  NEXT
  PRINT
  FOR i = 1 TO NT: miss(i) = 0: NEXT
  FOR j = 1 TO NQ: asked(j) = 0: NEXT
  turn = 0: quit = 0

  DO
    ' ---- who are the suspects?  Those with the FEWEST mistakes ----
    best = 99
    FOR i = 1 TO NT
      IF miss(i) < best THEN best = miss(i)
    NEXT
    nLeft = 0
    FOR i = 1 TO NT
      IF miss(i) = best THEN nLeft = nLeft + 1: only = i
    NEXT
    IF nLeft = 1 THEN EXIT DO

    ' ---- choose the question that splits the suspects most evenly ----
    pick = 0: bestGap = 99
    FOR j = 1 TO NQ
      IF asked(j) = 0 THEN
        y = 0
        FOR i = 1 TO NT
          IF miss(i) = best AND MID$(fact$(i), j, 1) = "1" THEN y = y + 1
        NEXT
        gap = ABS(y - (nLeft - y))      ' 0 means a perfect 50/50 split
        IF y > 0 AND y < nLeft AND gap < bestGap THEN bestGap = gap: pick = j
      END IF
    NEXT
    IF pick = 0 THEN EXIT DO            ' no question can separate them

    asked(pick) = 1
    turn = turn + 1
    PRINT USING "Q##: "; turn;
    PRINT q$(pick); "? (Y/N/?) ";
    DO
      k$ = UCASE$(INKEY$)
    LOOP UNTIL INSTR("YN?Q", k$) > 0 AND k$ <> ""
    PRINT k$
    IF k$ = "Q" THEN quit = 1: EXIT DO
    IF k$ <> "?" THEN
      ' every thing whose fact disagrees with the answer gets a mistake
      want$ = "0": IF k$ = "Y" THEN want$ = "1"
      FOR i = 1 TO NT
        IF MID$(fact$(i), pick, 1) <> want$ THEN miss(i) = miss(i) + 1
      NEXT
    END IF
    ' count the suspects still on zero... or the fewest mistakes
    b = 99: c = 0
    FOR i = 1 TO NT
      IF miss(i) < b THEN b = miss(i)
    NEXT
    FOR i = 1 TO NT
      IF miss(i) = b THEN c = c + 1
    NEXT
    COLOR 8: PRINT "     (suspects left:"; c; ")": COLOR 7
  LOOP UNTIL turn >= 20

  IF quit THEN EXIT DO
  ' ---- make the guess: the first thing with the fewest mistakes ----
  best = 99
  FOR i = 1 TO NT
    IF miss(i) < best THEN best = miss(i): only = i
  NEXT
  PRINT
  COLOR 11: PRINT "I think it is... "; UCASE$(thing$(only)); "!": COLOR 7
  PRINT "Am I right? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = "Q"
  IF k$ = "Y" THEN PRINT "Got it in"; turn; "questions." ELSE PRINT "You stumped me! (Did you answer every question right?)"
  PRINT : PRINT "Play again? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = "Q"
LOOP WHILE k$ = "Y"
PRINT "Goodbye!"
