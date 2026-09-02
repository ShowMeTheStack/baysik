' ============================================================
' TITLE:    Hangman
' CATEGORY: Games
' LEVEL:    Beginner
' TAGS:     word game, strings, data, text mode
' SUMMARY:  Guess the secret word one letter at a time before the gallows is finished.
' ------------------------------------------------------------
' WHAT IT DOES
'   The computer picks a secret word from a list.  Each blank shows
'   a letter you have not found yet.  Guess letters: right guesses
'   fill in the blanks, wrong guesses add a piece to the gallows
'   picture.  Six wrong guesses and the game is lost.
'
' HOW TO USE
'   Type a letter A-Z to guess it.  Letters you have already used
'   are shown so you don't repeat them.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing a word list with DATA and READ
'   * String functions: MID$, INSTR, UCASE$, LEN, STRING$
'   * Building the "revealed" word one character at a time
'   * Drawing a picture with PRINT and LOCATE in text mode
'
' THINGS TO TRY
'   * Add your own words to the DATA lines (update the count!)
'   * Add categories, or a hint for each word
'   * Allow 8 wrong guesses for younger players
' ============================================================

DEFINT A-Z

' ---- the word list: first the count, then the words ----
DATA 20
DATA COMPUTER, KEYBOARD, ELEPHANT, GIRAFFE, PYRAMID
DATA VOLCANO, PENGUIN, RAINBOW, LIBRARY, DINOSAUR
DATA PUMPKIN, ASTRONAUT, BICYCLE, CHOCOLATE, TELESCOPE
DATA OCTOPUS, LIGHTNING, TREASURE, SANDWICH, BUTTERFLY

READ count
DIM words$(1 TO count)
FOR i = 1 TO count: READ words$(i): NEXT

RANDOMIZE TIMER
wins = 0: losses = 0

DO
  secret$ = words$(INT(RND * count) + 1)
  used$ = ""                 ' every letter guessed so far
  wrong = 0                  ' number of wrong guesses

  DO
    ' ---- build the display word: letter if guessed, "_" if not ----
    shown$ = ""
    FOR i = 1 TO LEN(secret$)
      ch$ = MID$(secret$, i, 1)
      IF INSTR(used$, ch$) THEN shown$ = shown$ + ch$ + " " ELSE shown$ = shown$ + "_ "
    NEXT

    GOSUB DrawScreen
    IF INSTR(shown$, "_") = 0 THEN EXIT DO          ' no blanks left: win
    IF wrong >= 6 THEN EXIT DO                      ' gallows finished: lose

    ' ---- get one new letter ----
    LOCATE 18, 5: PRINT "Guess a letter: ";
    DO
      k$ = UCASE$(INKEY$)
      IF k$ = CHR$(27) THEN GOTO Quit
    LOOP UNTIL k$ >= "A" AND k$ <= "Z" AND LEN(k$) = 1

    IF INSTR(used$, k$) THEN
      LOCATE 20, 5: PRINT "You already tried "; k$; "!       "
      SOUND 200, 2
    ELSE
      used$ = used$ + k$
      IF INSTR(secret$, k$) THEN
        SOUND 880, 1: LOCATE 20, 5: PRINT "Yes! "; k$; " is in the word.  "
      ELSE
        wrong = wrong + 1
        SOUND 150, 3: LOCATE 20, 5: PRINT "Sorry, no "; k$; ".              "
      END IF
    END IF
    t! = TIMER: DO: LOOP WHILE TIMER < t! + .5 AND TIMER >= t!
  LOOP

  ' ---- end of round ----
  LOCATE 18, 5
  IF wrong >= 6 THEN
    losses = losses + 1
    PRINT "You lost! The word was "; secret$
    PLAY "MB T100 L4 C<B-<A"
  ELSE
    wins = wins + 1
    PRINT "You saved him! The word was "; secret$
    PLAY "MB T180 L8 CEG>C"
  END IF
  LOCATE 20, 5: PRINT "Wins:"; wins; "  Losses:"; losses; SPACE$(20)
  LOCATE 22, 5: PRINT "Play again? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"

Quit:
CLS
PRINT "Thanks for playing Hangman!"
END

' ================= draw everything =================
DrawScreen:
  CLS
  COLOR 14: LOCATE 1, 30: PRINT "H A N G M A N": COLOR 7
  ' The gallows itself is always there
  LOCATE 3, 5: PRINT " +-----+"
  LOCATE 4, 5: PRINT " |     |"
  FOR i = 5 TO 9: LOCATE i, 5: PRINT " |": NEXT
  LOCATE 10, 5: PRINT "=+======="
  ' Add one body part per wrong guess
  COLOR 12
  IF wrong >= 1 THEN LOCATE 5, 11: PRINT "O"           ' head
  IF wrong >= 2 THEN LOCATE 6, 11: PRINT "|"           ' body
  IF wrong >= 3 THEN LOCATE 6, 10: PRINT "/"           ' left arm
  IF wrong >= 4 THEN LOCATE 6, 12: PRINT "\"           ' right arm
  IF wrong >= 5 THEN LOCATE 7, 10: PRINT "/"           ' left leg
  IF wrong >= 6 THEN LOCATE 7, 12: PRINT "\"           ' right leg
  COLOR 7
  ' The word and the letters used so far
  LOCATE 5, 25: PRINT "Word:  "; : COLOR 15: PRINT shown$: COLOR 7
  LOCATE 7, 25: PRINT "Letters used: "; used$
  LOCATE 9, 25: PRINT "Wrong guesses left:"; 6 - wrong
RETURN
