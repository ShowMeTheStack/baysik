' ============================================================
' TITLE:    Animal Guesser That Learns
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     ai, machine learning, binary tree, files, yes/no
' SUMMARY:  Think of an animal; the computer guesses, and learns a new question every time it fails.
' ------------------------------------------------------------
' WHAT IT DOES
'   The computer's knowledge is a BINARY TREE.  Inner nodes are
'   yes/no questions ("Does it live in water?"), leaves are animals.
'   To guess, it starts at the top and follows YES or NO branches
'   until it reaches an animal.  If the guess is wrong it asks you
'   for the right animal and a question that tells the two apart,
'   then grows the tree right there.  The tree is saved in the file
'   ANIMALS.DAT, so the program gets smarter every time you play -
'   even after you close it.
'
' HOW TO USE
'   Think of an animal.  Answer Y or N.  When it is stumped, type
'   your animal and a question.  At "Play again?" answer N to save
'   and quit.  Type RESET at the start prompt to forget everything.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a tree in parallel arrays (text, yes-child, no-child)
'   * "Learning" by splitting a leaf into a question + two leaves
'   * Saving and loading a data structure with WRITE # and INPUT #
'   * ON ERROR to cope with a missing file on the very first run
'
' THINGS TO TRY
'   * Print the whole tree, indented, to see what it has learnt
'   * Count how many questions the longest path needs
'   * Change the starting tree to guess fruits or famous people
' ============================================================

DECLARE FUNCTION AskYes% (q$)
DECLARE SUB SaveTree ()
DEFINT A-Z
CONST MAXN = 500
' node$(i) = question or animal;  yes(i)/no(i) = child node numbers.
' A node with yes(i) = 0 is a LEAF (an animal).
DIM SHARED node$(1 TO MAXN), yes(1 TO MAXN), no(1 TO MAXN), count

CLS
COLOR 14: PRINT "ANIMAL GUESSER": COLOR 7

' ---------- try to load what we learned last time ----------
loaded = 0
ON ERROR GOTO NoFile
OPEN "ANIMALS.DAT" FOR INPUT AS #1
INPUT #1, count
FOR i = 1 TO count
  INPUT #1, node$(i), yes(i), no(i)
NEXT
CLOSE #1
loaded = 1
AfterLoad:
ON ERROR GOTO 0

IF loaded = 0 THEN
  ' a tiny starting tree:   [Does it live in water?]
  '                           yes -> fish     no -> dog
  count = 3
  node$(1) = "Does it live in water": yes(1) = 2: no(1) = 3
  node$(2) = "fish": yes(2) = 0: no(2) = 0
  node$(3) = "dog": yes(3) = 0: no(3) = 0
  PRINT "Starting fresh - I only know 2 animals."
ELSE
  PRINT "I remember"; (count + 1) \ 2; "animals from before."
END IF

DO
  PRINT
  LINE INPUT "Think of an animal and press Enter (or type RESET / QUIT): ", c$
  c$ = UCASE$(LTRIM$(RTRIM$(c$)))
  IF c$ = "QUIT" OR c$ = "Q" THEN EXIT DO
  IF c$ = "RESET" THEN
    count = 3: no(1) = 3: yes(1) = 2
    node$(1) = "Does it live in water": node$(2) = "fish": node$(3) = "dog"
    PRINT "Memory wiped. Back to fish and dog."
  ELSE
    ' ---------- walk down the tree ----------
    n = 1
    DO WHILE yes(n) <> 0                    ' while this is a question...
      IF AskYes(node$(n) + "?") THEN n = yes(n) ELSE n = no(n)
    LOOP
    ' n is now a leaf: make the guess
    IF AskYes("Is it a " + node$(n) + "?") THEN
      COLOR 10: PRINT "I got it! Computers rule.": COLOR 7
    ELSEIF count + 2 > MAXN THEN
      PRINT "You win - and my brain is completely full!"
    ELSE
      ' ---------- learn! ----------
      PRINT "You beat me!"
      DO
        LINE INPUT "What animal were you thinking of? ", a$
        a$ = LCASE$(LTRIM$(RTRIM$(a$)))
      LOOP WHILE a$ = ""
      PRINT "Type a yes/no question that is true for a "; a$
      DO
        PRINT "but false for a "; node$(n); ": ";
        LINE INPUT q$
        q$ = LTRIM$(RTRIM$(q$))
      LOOP WHILE q$ = ""
      ' tidy the question: drop a trailing "?" and capitalise it
      IF RIGHT$(q$, 1) = "?" THEN q$ = LEFT$(q$, LEN(q$) - 1)
      q$ = UCASE$(LEFT$(q$, 1)) + MID$(q$, 2)
      ' The old leaf n becomes the QUESTION, and two new leaves hang
      ' under it: the new animal on YES, the old animal on NO.
      '      [n: dog]        becomes      [n: Does it purr]
      '                                     yes/        \no
      '                                [cat]          [dog]
      node$(count + 1) = a$: yes(count + 1) = 0: no(count + 1) = 0
      node$(count + 2) = node$(n): yes(count + 2) = 0: no(count + 2) = 0
      node$(n) = q$: yes(n) = count + 1: no(n) = count + 2
      count = count + 2
      PRINT "Thanks! Now I know"; (count + 1) \ 2; "animals."
      SaveTree
    END IF
  END IF
LOOP WHILE AskYes("Play again?")

SaveTree
PRINT "My memory is saved in ANIMALS.DAT. Bye!"
END

NoFile:
  RESUME AfterLoad

' Ask a yes/no question until the answer starts with Y or N.
FUNCTION AskYes% (q$)
  DO
    ' (LINE INPUT only accepts a fixed "literal" prompt, so we PRINT
    '  our own prompt first and end it with ; to stay on the line)
    PRINT q$; " (Y/N) ";
    LINE INPUT a$
    a$ = UCASE$(LEFT$(LTRIM$(a$), 1))
  LOOP UNTIL a$ = "Y" OR a$ = "N"
  AskYes% = (a$ = "Y")
END FUNCTION

' Write the whole tree to disk.  WRITE # puts quotes round strings
' and commas between items, which INPUT # reads back perfectly.
SUB SaveTree
  OPEN "ANIMALS.DAT" FOR OUTPUT AS #1
  WRITE #1, count
  FOR i = 1 TO count
    WRITE #1, node$(i), yes(i), no(i)
  NEXT
  CLOSE #1
END SUB
