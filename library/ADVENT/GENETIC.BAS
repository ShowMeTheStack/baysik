' ============================================================
' TITLE:    Genetic Algorithm: Evolve a Sentence
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     genetic algorithm, evolution, optimisation, random, ai
' SUMMARY:  A population of random gibberish evolves, by selection and mutation, into your sentence.
' ------------------------------------------------------------
' WHAT IT DOES
'   Start with 80 completely random strings.  Each generation:
'     FITNESS   - score every string: how many letters are right?
'     SELECTION - pick parents by "tournament": grab 3 at random,
'                 the fittest of the three gets to breed
'     CROSSOVER - the child takes the first part from mum and the
'                 rest from dad, split at a random point
'     MUTATION  - each letter has a small chance to change randomly
'     ELITISM   - the best string is copied unchanged, so the best
'                 score can never go backwards
'   Nobody tells the program HOW to spell the target - good letters
'   simply survive more often.  That is natural selection in a box.
'
' HOW TO USE
'   Type a target sentence (capital letters and spaces work best)
'   or just press Enter for the default.  Watch it evolve.
'   Any key stops early.  Afterwards: Y to run again, N to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Fitness functions and selection pressure
'   * Crossover and mutation as ways to search
'   * Why evolution is cumulative, not a lucky jackpot
'   * Swapping populations with a second "next generation" array
'
' THINGS TO TRY
'   * Set MUTRATE to 0 - does it get stuck?  Set it to 0.3?
'   * Remove the elitism line and watch the best score wobble
'   * Change the tournament size from 3 to 1 (no selection at all!)
' ============================================================

DECLARE FUNCTION Fitness% (s$)
DECLARE FUNCTION RandChar$ ()
DEFINT A-Z
CONST PSIZE = 80, MUTRATE = .02
DIM SHARED target$
DIM pop$(1 TO PSIZE), nxt$(1 TO PSIZE), fit(1 TO PSIZE)
RANDOMIZE TIMER

DO
  CLS
  COLOR 14: PRINT "GENETIC ALGORITHM - evolving a sentence": COLOR 7
  PRINT
  LINE INPUT "Target sentence (Enter = METHINKS IT IS LIKE A WEASEL): ", target$
  target$ = UCASE$(LTRIM$(RTRIM$(target$)))
  ' keep only the letters and spaces our "alphabet" can make
  t$ = ""
  FOR i = 1 TO LEN(target$)
    c$ = MID$(target$, i, 1)
    IF (c$ >= "A" AND c$ <= "Z") OR c$ = " " THEN t$ = t$ + c$
  NEXT
  target$ = LEFT$(t$, 60)
  IF LEN(target$) < 2 THEN target$ = "METHINKS IT IS LIKE A WEASEL"
  L = LEN(target$)
  PRINT "Target: "; target$; "   ("; LTRIM$(STR$(L)); " letters, 27 possible symbols each)"
  PRINT

  ' ---------- generation 0: pure random gibberish ----------
  FOR p = 1 TO PSIZE
    s$ = ""
    FOR i = 1 TO L: s$ = s$ + RandChar$: NEXT
    pop$(p) = s$
  NEXT

  gen = 0
  DO
    ' ---------- fitness of everyone ----------
    best = 1
    FOR p = 1 TO PSIZE
      fit(p) = Fitness(pop$(p))
      IF fit(p) > fit(best) THEN best = p
    NEXT
    ' show the champion of this generation
    IF gen MOD 5 = 0 OR fit(best) = L THEN
      IF CSRLIN > 22 THEN LOCATE 6, 1: FOR i = 6 TO 23: PRINT SPACE$(79): NEXT: LOCATE 6, 1
      PRINT USING "Gen ####  score ##/##  "; gen; fit(best); L;
      FOR i = 1 TO L
        ' green = letter already correct, grey = still wrong
        IF MID$(pop$(best), i, 1) = MID$(target$, i, 1) THEN COLOR 10 ELSE COLOR 8
        PRINT MID$(pop$(best), i, 1);
      NEXT
      COLOR 7: PRINT
    END IF
    IF fit(best) = L THEN EXIT DO
    IF INKEY$ <> "" THEN PRINT "(stopped)": EXIT DO

    ' ---------- build the next generation ----------
    nxt$(1) = pop$(best)                        ' elitism: keep the champion
    FOR p = 2 TO PSIZE
      ' tournament selection, twice: one for each parent
      FOR parent = 1 TO 2
        win = INT(RND * PSIZE) + 1
        FOR t = 1 TO 2
          c = INT(RND * PSIZE) + 1
          IF fit(c) > fit(win) THEN win = c
        NEXT
        IF parent = 1 THEN mum$ = pop$(win) ELSE dad$ = pop$(win)
      NEXT
      ' one-point crossover
      cut = INT(RND * (L + 1))
      child$ = LEFT$(mum$, cut) + MID$(dad$, cut + 1)
      ' mutation: rarely, a letter is replaced at random
      FOR i = 1 TO L
        IF RND < MUTRATE THEN MID$(child$, i, 1) = RandChar$
      NEXT
      nxt$(p) = child$
    NEXT
    FOR p = 1 TO PSIZE: pop$(p) = nxt$(p): NEXT
    gen = gen + 1
  LOOP

  PRINT
  IF fit(best) = L THEN COLOR 11: PRINT "Evolved in"; gen; "generations!": COLOR 7
  PRINT "(Pure luck would need about 27^"; LTRIM$(STR$(L)); " tries.)"
  PRINT "Again? (Y/N)"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "Y" OR k$ = "N" OR k$ = CHR$(27)
LOOP WHILE k$ = "Y"

' Count the letters that are already in the right place.
FUNCTION Fitness% (s$)
  f = 0
  FOR i = 1 TO LEN(s$)
    IF MID$(s$, i, 1) = MID$(target$, i, 1) THEN f = f + 1
  NEXT
  Fitness% = f
END FUNCTION

' A random symbol: one of the 26 letters or a space.
FUNCTION RandChar$
  r = INT(RND * 27)
  IF r = 26 THEN RandChar$ = " " ELSE RandChar$ = CHR$(65 + r)
END FUNCTION
