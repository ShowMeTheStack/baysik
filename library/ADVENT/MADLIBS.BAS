' ============================================================
' TITLE:    Silly Story Maker
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     word game, templates, strings, parsing, stories
' SUMMARY:  Fill in nouns, verbs and adjectives without seeing the story - then read the silly result.
' ------------------------------------------------------------
' WHAT IT DOES
'   A word game for friends.  Each story is stored with blanks
'   written in square brackets, like  "The [ADJECTIVE] [ANIMAL] ate
'   my homework."  The program scans the story for every [...]
'   blank, asks you for a word of that kind WITHOUT showing you the
'   story, and then prints the story with your words dropped in.
'   The less sense your words make, the funnier the result!
'
' HOW TO USE
'   Pick a story by number.  Type a word for each request and press
'   Enter.  Then enjoy.  0 or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Scanning a string for markers with INSTR
'   * Building a new string piece by piece
'   * Word-wrapping long text to fit the screen
'   * Storing several templates in DATA
'
' THINGS TO TRY
'   * Write your own story template with new kinds of blanks
'   * Show your words in a different colour inside the story
'   * Save the finished story to a text file to print later
' ============================================================

DECLARE SUB WrapPrint (t$)
DEFINT A-Z
CONST NSTORY = 3
DIM title$(1 TO NSTORY), story$(1 TO NSTORY)
DIM answer$(1 TO 30)

DATA "The School Trip"
DATA "Our class went on a trip to the [PLACE]. The bus was driven by a +"
DATA "[ADJECTIVE] [ANIMAL] who kept shouting [EXCLAMATION]! When we arrived,+"
DATA " our teacher told us to [VERB] quietly, but [FRIEND'S NAME] fell into +"
DATA "a giant bucket of [FOOD]. It was the most [ADJECTIVE] day ever, and we+"
DATA " all got [NUMBER] stickers."
DATA "My Robot Butler"
DATA "For my birthday I got a robot butler called [SILLY NAME]. Every +"
DATA "morning it makes me [FOOD] and polishes my [OBJECT]. Yesterday it +"
DATA "learned to [VERB] and now it does it [NUMBER] times an hour. The +"
DATA "neighbours think it is very [ADJECTIVE], but my [ANIMAL] is terrified +"
DATA "of it."
DATA "The Dragon Who Couldn't"
DATA "Once upon a time a [COLOUR] dragon lived inside a [OBJECT]. It could +"
DATA "not breathe fire - it could only breathe [FOOD]! The other dragons +"
DATA "laughed and called it [SILLY NAME]. But one day a [ADJECTIVE] knight +"
DATA "came to [VERB] the village, and the dragon saved everyone by shouting +"
DATA "[EXCLAMATION]. From then on it was the [ADJECTIVE] hero of [PLACE]."
' Each story is split over several DATA strings (a QBasic line can only
' be 255 characters).  A string ending in "+" continues in the next one.
FOR i = 1 TO NSTORY
  READ title$(i), part$
  DO WHILE RIGHT$(part$, 1) = "+"
    story$(i) = story$(i) + LEFT$(part$, LEN(part$) - 1)
    READ part$
  LOOP
  story$(i) = story$(i) + part$
NEXT

DO
  CLS
  COLOR 14: PRINT "SILLY STORY MAKER": COLOR 7
  PRINT
  FOR i = 1 TO NSTORY: PRINT "  "; i; title$(i): NEXT
  PRINT "   0  Quit"
  PRINT
  LINE INPUT "Which story? ", a$
  a$ = UCASE$(LTRIM$(a$))
  IF a$ = "0" OR a$ = "Q" THEN EXIT DO
  s = VAL(a$)
  IF s >= 1 AND s <= NSTORY THEN
    ' ---- pass 1: ask for a word for every [blank] ----
    t$ = story$(s)
    n = 0: p = 1
    PRINT
    DO
      op = INSTR(p, t$, "[")
      IF op = 0 THEN EXIT DO
      cl = INSTR(op, t$, "]")
      kind$ = MID$(t$, op + 1, cl - op - 1)     ' the text between [ and ]
      n = n + 1
      ' "a" or "an"?  use "an" before a vowel sound
      IF INSTR("AEIOU", LEFT$(kind$, 1)) THEN art$ = "an " ELSE art$ = "a "
      DO
        PRINT "Give me "; art$; LCASE$(kind$); ": ";
        LINE INPUT answer$(n)
        answer$(n) = LTRIM$(RTRIM$(answer$(n)))
      LOOP WHILE answer$(n) = ""
      p = cl + 1
    LOOP

    ' ---- pass 2: rebuild the story with the words dropped in ----
    result$ = "": p = 1: k = 0
    DO
      op = INSTR(p, t$, "[")
      IF op = 0 THEN result$ = result$ + MID$(t$, p): EXIT DO
      cl = INSTR(op, t$, "]")
      k = k + 1
      result$ = result$ + MID$(t$, p, op - p) + UCASE$(answer$(k))
      p = cl + 1
    LOOP

    CLS
    COLOR 11: PRINT title$(s): PRINT STRING$(LEN(title$(s)), "-"): COLOR 7
    PRINT
    WrapPrint result$
    PRINT
    PRINT "Press any key for the menu..."
    DO: LOOP WHILE INKEY$ = ""
  END IF
LOOP
PRINT "The end!"

' Print text in lines of at most 70 characters, breaking at spaces.
SUB WrapPrint (t$)
  w$ = t$
  DO WHILE LEN(w$) > 70
    cut = 71
    DO WHILE MID$(w$, cut, 1) <> " " AND cut > 1: cut = cut - 1: LOOP
    IF cut = 1 THEN cut = 71                  ' one enormous word: just chop it
    PRINT "  "; LEFT$(w$, cut - 1)
    w$ = LTRIM$(MID$(w$, cut))
  LOOP
  PRINT "  "; w$
END SUB
