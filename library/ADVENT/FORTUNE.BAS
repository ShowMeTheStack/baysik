' ============================================================
' TITLE:    Fortune Cookie & Poem Machine
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     text generation, random, templates, word lists, poetry
' SUMMARY:  Cracks open random fortune cookies and writes little poems from word lists.
' ------------------------------------------------------------
' WHAT IT DOES
'   Computers can "write" by filling in TEMPLATES with random words.
'   A fortune template looks like:
'       "A [adjective] [thing] will [action] [when]."
'   Each [slot] is filled from its own word list, so even small lists
'   make thousands of combinations.  The poem maker uses the same
'   trick, with a different template for every line, to build a
'   short three-line poem in the style of a haiku.
'   Your lucky numbers are drawn without repeats.
'
' HOW TO USE
'   F = crack a fortune cookie,  P = write a poem,  Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Template filling with string concatenation
'   * Picking a random item from an array
'   * Drawing numbers with no repeats (a "used" array)
'   * Combinatorics: 8 x 8 x 8 x 8 = 4096 different fortunes
'
' THINGS TO TRY
'   * Add more words - how many fortunes are possible now?
'   * Write a template for a limerick
'   * Make the poem rhyme by choosing end words from a rhyme list
' ============================================================

DECLARE FUNCTION Pick$ (which%)
DEFINT A-Z
CONST NL = 8, NW = 8               ' 8 word lists, 8 words in each
DIM SHARED words$(1 TO NL, 1 TO NW)
DIM used(1 TO 49)
' list 1: adjectives           list 2: things
' list 3: actions              list 4: times
' list 5: nature nouns         list 6: poem verbs
' list 7: colours              list 8: feelings
DATA golden,mysterious,tiny,forgotten,cheerful,ancient,shiny,unexpected
DATA letter,friend,door,idea,cat,journey,song,gift
DATA find you,change your luck,make you laugh,arrive by surprise,open new paths,bring good news,teach you something,follow you home
DATA before the next full moon,on a rainy Tuesday,when you least expect it,very soon,after a long walk,this week,in a dream,by the end of summer
DATA river,mountain,moon,pine tree,sparrow,cloud,ocean,frog
DATA whispers,dreams,sleeps,dances,waits,sings,drifts,glows
DATA silver,green,amber,blue,scarlet,grey,violet,white
DATA quiet,lonely,happy,sleepy,brave,gentle,hungry,patient
FOR l = 1 TO NL: FOR w = 1 TO NW: READ words$(l, w): NEXT w, l

RANDOMIZE TIMER
CLS
COLOR 14: PRINT "FORTUNE COOKIE & POEM MACHINE": COLOR 7
PRINT "F = fortune cookie   P = poem   Esc = quit"
DO
  DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
  SELECT CASE k$
    CASE "F"
      ' ---- choose one of three fortune templates ----
      SELECT CASE INT(RND * 3)
        CASE 0: f$ = "A " + Pick$(1) + " " + Pick$(2) + " will " + Pick$(3) + " " + Pick$(4) + "."
        CASE 1: f$ = "Look for the " + Pick$(1) + " " + Pick$(2) + ". It will " + Pick$(3) + "."
        CASE 2: f$ = "Be " + Pick$(8) + ": a " + Pick$(2) + " will " + Pick$(3) + " " + Pick$(4) + "."
      END SELECT
      ' ---- six lucky numbers from 1 to 49, no repeats ----
      ' used(n) remembers which numbers are already drawn.
      FOR n = 1 TO 49: used(n) = 0: NEXT
      lucky$ = ""
      FOR i = 1 TO 6
        DO: n = INT(RND * 49) + 1: LOOP WHILE used(n)   ' drawn already? again!
        used(n) = 1
        lucky$ = lucky$ + STR$(n)
      NEXT
      ' ---- split a long fortune into two lines at a space ----
      line1$ = f$: line2$ = ""
      IF LEN(f$) > 52 THEN
        cut = 52
        DO WHILE MID$(f$, cut, 1) <> " ": cut = cut - 1: LOOP
        line1$ = LEFT$(f$, cut - 1): line2$ = MID$(f$, cut + 1)
      END IF
      ' ---- draw the paper slip, 56 characters wide ----
      PRINT
      COLOR 6: PRINT "   "; CHR$(218); STRING$(56, 196); CHR$(191)
      FOR i = 1 TO 3
        IF i = 1 THEN t$ = line1$: c = 15
        IF i = 2 THEN t$ = line2$: c = 15
        IF i = 3 THEN t$ = "Lucky numbers:" + lucky$: c = 3
        IF t$ <> "" THEN
          COLOR 6: PRINT "   "; CHR$(179);
          COLOR c: PRINT "  "; t$; SPACE$(54 - LEN(t$));
          COLOR 6: PRINT CHR$(179)
        END IF
      NEXT
      PRINT "   "; CHR$(192); STRING$(56, 196); CHR$(217)
      COLOR 7
    CASE "P"
      ' ---- a three-line poem, one template per line ----
      PRINT
      COLOR 11
      PRINT "      the "; Pick$(7); " "; Pick$(5)
      PRINT "      "; Pick$(6); " above the "; Pick$(8); " "; Pick$(5)
      PRINT "      "; Pick$(1); " and "; Pick$(8)
      COLOR 7
    CASE CHR$(27), "Q"
      EXIT DO
  END SELECT
LOOP
PRINT "May your cookies always be fortunate!"

' Return a random word from word list number "which".
FUNCTION Pick$ (which)
  Pick$ = words$(which, INT(RND * NW) + 1)
END FUNCTION
