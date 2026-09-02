' ============================================================
' TITLE:    Mastermind Code Breaker
' CATEGORY: Games
' LEVEL:    Intermediate
' TAGS:     logic, puzzle, strings, colour, text mode
' SUMMARY:  Crack a hidden code of four colours using black-and-white feedback pegs.
' ------------------------------------------------------------
' WHAT IT DOES
'   The computer hides a code of 4 colours chosen from 6 (colours may
'   repeat).  You have 10 tries to guess it.  After each guess you get
'   feedback pegs:
'     BLACK (#)  = right colour in the right place
'     WHITE (o)  = right colour but in the wrong place
'   Use logic to narrow down the possibilities!
'
' HOW TO USE
'   Each colour has a letter:  R G B Y M C
'   (Red, Green, Blue, Yellow, Magenta, Cyan).
'   Type 4 letters, e.g. RGBY.  Backspace fixes a mistake, Enter
'   submits the guess.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * The two-pass scoring trick (exact matches first, then colour counts)
'   * Arrays for counting
'   * Coloured text with COLOR and CHR$(219) block characters
'   * Writing your own line editor with INKEY$
'
' THINGS TO TRY
'   * Allow 5 pegs or 8 colours for a harder game
'   * Make the computer guess YOUR code (Knuth's algorithm is famous)
'   * Forbid repeated colours in the secret code
' ============================================================

DEFINT A-Z
CONST PEGS = 4, NCOL = 6, TRIES = 10

letters$ = "RGBYMC"              ' the colour letters, in order
DIM shade(1 TO NCOL)             ' screen colour for each letter
DATA 12, 10, 9, 14, 13, 11
FOR i = 1 TO NCOL: READ shade(i): NEXT
DIM cs(1 TO NCOL), cg(1 TO NCOL) ' colour counts (secret / guess)

RANDOMIZE TIMER

NewGame:
  secret$ = ""
  FOR i = 1 TO PEGS
    secret$ = secret$ + MID$(letters$, INT(RND * NCOL) + 1, 1)
  NEXT

  CLS
  COLOR 15: PRINT "  M A S T E R M I N D": COLOR 7
  PRINT "  Colours: ";
  FOR i = 1 TO NCOL
    COLOR shade(i): PRINT MID$(letters$, i, 1); CHR$(219); " ";
  NEXT
  COLOR 7
  PRINT "    # = right place   o = right colour"
  PRINT

  FOR try = 1 TO TRIES
    row = 4 + try * 2
    LOCATE row, 3: PRINT USING "##."; try;
    ' ---- read a guess with a tiny line editor ----
    g$ = ""
    DO
      LOCATE row, 8: PRINT g$; SPACE$(PEGS - LEN(g$)); "  ";
      LOCATE row, 8 + LEN(g$)
      DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
      IF k$ = CHR$(27) THEN GOTO Quit
      IF k$ = CHR$(8) AND LEN(g$) > 0 THEN g$ = LEFT$(g$, LEN(g$) - 1)
      IF INSTR(letters$, k$) > 0 AND LEN(k$) = 1 AND LEN(g$) < PEGS THEN g$ = g$ + k$
    LOOP UNTIL k$ = CHR$(13) AND LEN(g$) = PEGS

    ' ---- draw the guess as coloured blocks ----
    LOCATE row, 8
    FOR i = 1 TO PEGS
      c = INSTR(letters$, MID$(g$, i, 1))
      COLOR shade(c): PRINT CHR$(219); CHR$(219); " ";
    NEXT
    COLOR 7

    ' ---- score it ----
    ' Pass 1: exact matches (black pegs).
    ' Pass 2: for each colour, the smaller of "how many in the secret"
    '         and "how many in the guess" counts all colour matches;
    '         subtract the blacks to get the whites.
    black = 0
    FOR i = 1 TO NCOL: cs(i) = 0: cg(i) = 0: NEXT
    FOR i = 1 TO PEGS
      a$ = MID$(secret$, i, 1): b$ = MID$(g$, i, 1)
      IF a$ = b$ THEN black = black + 1
      cs(INSTR(letters$, a$)) = cs(INSTR(letters$, a$)) + 1
      cg(INSTR(letters$, b$)) = cg(INSTR(letters$, b$)) + 1
    NEXT
    total = 0
    FOR i = 1 TO NCOL
      IF cs(i) < cg(i) THEN total = total + cs(i) ELSE total = total + cg(i)
    NEXT
    white = total - black

    LOCATE row, 22
    COLOR 15: PRINT STRING$(black, "#");
    COLOR 7: PRINT STRING$(white, "o"); STRING$(PEGS - black - white, ".")
    IF black = PEGS THEN EXIT FOR
    SOUND 500 + black * 150, 1
  NEXT

  ' ---- reveal the code ----
  LOCATE 4, 40: PRINT "Secret code: ";
  FOR i = 1 TO PEGS
    c = INSTR(letters$, MID$(secret$, i, 1))
    COLOR shade(c): PRINT CHR$(219); CHR$(219); " ";
  NEXT
  COLOR 7
  LOCATE 6, 40
  IF black = PEGS THEN
    PRINT "Cracked in"; try; "tries!"
    PLAY "MB T200 L16 CDEFGAB>C"
  ELSE
    PRINT "Out of tries - the code wins."
    PLAY "MB T120 L8 C<G<C"
  END IF
  LOCATE 8, 40: PRINT "Play again? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
  IF k$ = "Y" THEN GOTO NewGame

Quit:
COLOR 7: CLS
PRINT "Goodbye, code breaker!"
END
