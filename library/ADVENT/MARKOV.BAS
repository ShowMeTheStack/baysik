' ============================================================
' TITLE:    Markov Chain Story Machine
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     markov chain, text generation, probability, ai, strings
' SUMMARY:  Learns which words follow which in a story, then babbles brand-new sentences.
' ------------------------------------------------------------
' WHAT IT DOES
'   A Markov chain is the great-great-grandparent of today's AI text
'   generators.  It reads some text and only remembers one thing:
'   "after word X, these words came next".  To write, it starts with
'   a word, picks a random follower, then a follower of THAT word,
'   and so on.  Common pairs come up more often because they appear
'   more often in the list - no counting needed!
'   ORDER 1 looks at the last word only (wild and silly).
'   ORDER 2 looks at the last TWO words (more sensible, but copies
'   longer chunks of the original).
'
' HOW TO USE
'   Menu: 1 = generate with order 1, 2 = generate with order 2,
'         3 = show which words can follow a word you type,
'         4 = print the training text, Q = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Splitting text into a word array
'   * Random choice weighted by frequency (just pick a random occurrence)
'   * The "order" of a Markov model and the creativity/sense trade-off
'
' THINGS TO TRY
'   * Replace the DATA with a poem or song lyrics you like
'   * Add ORDER 3 and compare
'   * Make it stop neatly at the end of a sentence (word ending in ".")
' ============================================================

DECLARE SUB Generate (order%, howMany%)
DEFINT A-Z
CONST MAXW = 600
DIM SHARED w$(1 TO MAXW), nw

' ---- the training text: an original little tale ----
DATA "The little robot lived on a hill above the quiet town. Every morning the"
DATA "little robot rolled down the hill to the bakery. The baker gave the robot"
DATA "a warm loaf and the robot gave the baker a song. The town loved the song"
DATA "and the town loved the robot. One morning a storm came over the hill. The"
DATA "wind pushed the robot into the river and the river carried the robot far"
DATA "away from the town. The robot sang to the fish and the fish sang back. The"
DATA "river was cold but the song was warm. At last the river slowed and the"
DATA "robot rolled onto a sandy beach. A girl found the little robot and carried"
DATA "it home. She dried the robot by the fire and the robot sang her a song."
DATA "The next day the girl and the robot walked back to the town on the hill."
DATA "The baker cried and the town cheered and the robot sang the loudest song"
DATA "of all. Every morning after that the girl and the robot rolled down the"
DATA "hill to the bakery together."
DATA "*END*"

' ---- split every line into words ----
nw = 0
DO
  READ l$
  IF l$ = "*END*" THEN EXIT DO
  l$ = l$ + " "
  word$ = ""
  FOR i = 1 TO LEN(l$)
    c$ = MID$(l$, i, 1)
    IF c$ = " " THEN
      IF word$ <> "" AND nw < MAXW THEN nw = nw + 1: w$(nw) = word$
      word$ = ""
    ELSE
      word$ = word$ + c$
    END IF
  NEXT
LOOP

RANDOMIZE TIMER
CLS
COLOR 14: PRINT "MARKOV CHAIN STORY MACHINE": COLOR 7
PRINT "I have read a story of"; nw; "words."
DO
  PRINT
  PRINT "1) Babble, order 1   2) Babble, order 2   3) Followers   4) Text   Q) Quit"
  LINE INPUT "Choice: ", ch$
  ch$ = UCASE$(LEFT$(LTRIM$(ch$), 1))
  SELECT CASE ch$
    CASE "1", "2"
      PRINT : COLOR 11
      Generate VAL(ch$), 60
      COLOR 7
    CASE "3"
      LINE INPUT "Word: ", t$
      t$ = LCASE$(LTRIM$(RTRIM$(t$)))
      ' List every word that comes straight after t$ in the text.
      ' Duplicates are shown - they are what makes a follower likely.
      PRINT "After "; CHR$(34); t$; CHR$(34); " comes: ";
      n = 0
      FOR i = 1 TO nw - 1
        IF LCASE$(w$(i)) = t$ THEN
          PRINT w$(i + 1); " ";: n = n + 1
          IF POS(0) > 70 THEN PRINT
        END IF
      NEXT
      IF n = 0 THEN PRINT "(nothing - that word is not in the story)" ELSE PRINT
      IF n > 0 THEN PRINT "("; LTRIM$(STR$(n)); " choices; repeats make a word more likely)"
    CASE "4"
      FOR i = 1 TO nw
        PRINT w$(i); " ";
        IF POS(0) > 70 THEN PRINT
      NEXT
      PRINT
    CASE "Q"
      EXIT DO
  END SELECT
LOOP
PRINT "The robot waves goodbye."

' Write howMany words using a Markov chain of the given order.
SUB Generate (order, howMany)
  ' Start at the beginning of a random sentence: a word whose
  ' previous word ended with "." (or the very first word).
  DO
    s = INT(RND * (nw - 2)) + 1
  LOOP UNTIL s = 1 OR RIGHT$(w$(s - 1), 1) = "."
  a$ = w$(s): b$ = w$(s + 1)
  PRINT a$; " ";
  IF order = 2 THEN PRINT b$; " ";
  cur$ = a$
  FOR n = 1 TO howMany
    ' Count every place in the text that matches our recent words...
    cnt = 0
    FOR i = 1 TO nw - order
      IF order = 1 THEN
        IF w$(i) = cur$ THEN cnt = cnt + 1
      ELSE
        IF w$(i) = a$ AND w$(i + 1) = b$ THEN cnt = cnt + 1
      END IF
    NEXT
    IF cnt = 0 THEN EXIT FOR                   ' dead end (end of the text)
    ' ...then pick one of those places at random and take the next word.
    pick = INT(RND * cnt) + 1
    cnt = 0
    FOR i = 1 TO nw - order
      IF order = 1 THEN
        IF w$(i) = cur$ THEN cnt = cnt + 1
      ELSE
        IF w$(i) = a$ AND w$(i + 1) = b$ THEN cnt = cnt + 1
      END IF
      IF cnt = pick THEN nxt$ = w$(i + order): EXIT FOR
    NEXT
    PRINT nxt$; " ";
    IF POS(0) > 70 THEN PRINT
    cur$ = nxt$: a$ = b$: b$ = nxt$           ' slide the window along
    ' stop at a full stop once we have written a decent amount
    IF n > howMany \ 2 AND RIGHT$(nxt$, 1) = "." THEN EXIT FOR
  NEXT
  PRINT
END SUB
