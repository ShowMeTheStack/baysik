' ============================================================
' TITLE:    The Riddle Sphinx
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     riddles, quiz, strings, data, shuffle
' SUMMARY:  A sphinx asks you riddles in random order - three tries each, with hints.
' ------------------------------------------------------------
' WHAT IT DOES
'   The sphinx guards the desert road.  She asks 8 riddles, picked
'   in a random order every game.  You get three guesses at each:
'   after a wrong guess she gives you a hint.  A riddle can have
'   several right answers ("TOWEL" or "A TOWEL"), which are stored
'   together in one string separated by "/" marks.
'   Answer 5 or more correctly and she lets you pass.
'
' HOW TO USE
'   Type your answer and press Enter.  Type PASS to skip a riddle,
'   or QUIT to run away.
'
' CONCEPTS YOU WILL LEARN
'   * Shuffling a list (the Fisher-Yates shuffle)
'   * Checking an answer against several allowed answers
'   * Tidying input: upper case, trim spaces, drop "A" / "AN" / "THE"
'   * Keeping score
'
' THINGS TO TRY
'   * Add your own riddles (and raise NRID)
'   * Give more points for getting it on the first try
'   * Add a timer: answer in 20 seconds or lose a life
' ============================================================

DECLARE FUNCTION Tidy$ (s$)
DEFINT A-Z
CONST NRID = 8, NEEDED = 5
DIM q$(1 TO NRID), ans$(1 TO NRID), hint$(1 TO NRID), order(1 TO NRID)

' riddle, allowed answers (separated by /), hint
DATA "What has keys but can't open locks?","PIANO/KEYBOARD","It makes music."
DATA "What gets wetter the more it dries?","TOWEL","You use it after a bath."
DATA "What has a face and two hands but no arms or legs?","CLOCK/WATCH","It tells you something every minute."
DATA "The more you take, the more you leave behind. What are they?","FOOTSTEPS/STEPS/FOOTPRINTS","Think about walking on a beach."
DATA "What can travel around the world while staying in a corner?","STAMP/POSTAGE STAMP","Look at an envelope."
DATA "What has a neck but no head?","BOTTLE","You might drink from it."
DATA "What goes up but never comes down?","AGE/YOUR AGE","It changes on your birthday."
DATA "I have cities, but no houses; forests, but no trees; water, but no fish. What am I?","MAP","Explorers carry one."
FOR i = 1 TO NRID: READ q$(i), ans$(i), hint$(i): order(i) = i: NEXT

RANDOMIZE TIMER
' ---- Fisher-Yates shuffle: swap each slot with a random earlier one ----
FOR i = NRID TO 2 STEP -1
  j = INT(RND * i) + 1
  SWAP order(i), order(j)
NEXT

CLS
COLOR 14
PRINT "        /\_/\"
PRINT "       ( o.o )   THE RIDDLE SPHINX"
PRINT "        > ^ <"
COLOR 7
PRINT "'Answer"; NEEDED; "of my"; NRID; "riddles, traveller, and you may pass.'"
score = 0

FOR r = 1 TO NRID
  k = order(r)
  PRINT
  COLOR 11: PRINT "Riddle"; r; ": "; q$(k): COLOR 7
  solved = 0
  FOR try = 1 TO 3
    LINE INPUT "Your answer: ", a$
    a$ = Tidy$(a$)
    IF a$ = "QUIT" OR a$ = "Q" THEN PRINT "You flee across the sand!": END
    IF a$ = "PASS" THEN EXIT FOR
    ' Is a$ one of the allowed answers?  Put "/" round both so that
    ' "/MAP/" is found inside "/MAP/" but "AP" is not.
    IF a$ <> "" AND INSTR("/" + ans$(k) + "/", "/" + a$ + "/") > 0 THEN
      solved = 1: EXIT FOR
    END IF
    IF try = 1 THEN PRINT "'No... here is a hint: "; hint$(k); "'"
    IF try = 2 THEN PRINT "'Wrong again. One last try.'"
  NEXT
  IF solved THEN
    score = score + 1
    COLOR 10: PRINT "'Correct!'": COLOR 7
  ELSE
    ' show the first allowed answer (everything before the first "/")
    sl = INSTR(ans$(k), "/")
    IF sl THEN first$ = LEFT$(ans$(k), sl - 1) ELSE first$ = ans$(k)
    COLOR 12: PRINT "'The answer was: "; first$; "'": COLOR 7
  END IF
NEXT

PRINT
PRINT "You answered"; score; "of"; NRID; "riddles."
IF score >= NEEDED THEN
  COLOR 10: PRINT "'Clever traveller. The road is yours.' The sphinx steps aside."
ELSE
  COLOR 12: PRINT "'Not clever enough.' The sphinx yawns and sends you home."
END IF
COLOR 7

' Clean up an answer: upper case, trimmed, without a leading
' A / AN / THE, so "a towel" and "Towel " both become "TOWEL".
FUNCTION Tidy$ (s$)
  t$ = UCASE$(LTRIM$(RTRIM$(s$)))
  IF LEFT$(t$, 2) = "A " THEN t$ = MID$(t$, 3)
  IF LEFT$(t$, 3) = "AN " THEN t$ = MID$(t$, 4)
  IF LEFT$(t$, 4) = "THE " THEN t$ = MID$(t$, 5)
  ' drop a final "?" or "!" or "."
  IF t$ <> "" THEN
    IF INSTR("?!.", RIGHT$(t$, 1)) THEN t$ = LEFT$(t$, LEN(t$) - 1)
  END IF
  Tidy$ = LTRIM$(t$)
END FUNCTION
