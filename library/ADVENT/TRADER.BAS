' ============================================================
' TITLE:    Spice Route Trader
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Beginner
' TAGS:     trading, economy, random events, arrays, strategy
' SUMMARY:  Buy low, sell high across four ports in 30 days - if the pirates let you.
' ------------------------------------------------------------
' WHAT IT DOES
'   You captain a small ship with 100 gold and room for 50 crates.
'   Four ports each sell pepper, silk and tea at their own prices,
'   and prices drift every day.  Sailing to another port takes a
'   day and may bring a random event: pirates, storms, a festival
'   that sends prices sky-high, or a lucky find in the sea.
'   After 30 days your gold is your score.
'
' HOW TO USE
'   At each port choose:  B = buy,  S = sell,  T = travel,
'   Q = quit early.  Then answer the questions with numbers.
'
' CONCEPTS YOU WILL LEARN
'   * Two-dimensional arrays: price(port, good)
'   * Random walks: prices that drift up and down
'   * Random events picked with SELECT CASE on a dice roll
'   * Checking input so the player can't cheat (or crash it!)
'
' THINGS TO TRY
'   * Add a fifth port or a fourth good
'   * Let the player buy cannons to fight off pirates
'   * Add a bank that pays interest on gold left there
' ============================================================

DEFINT A-Z
CONST NPORT = 4, NGOOD = 3, HOLD = 50, DAYS = 30
DIM port$(1 TO NPORT), good$(1 TO NGOOD)
DIM usual(1 TO NPORT, 1 TO NGOOD), price(1 TO NPORT, 1 TO NGOOD)
DIM cargo(1 TO NGOOD)

DATA Zanzibar,Calicut,Malacca,Canton
DATA Pepper,Silk,Tea
FOR i = 1 TO NPORT: READ port$(i): NEXT
FOR i = 1 TO NGOOD: READ good$(i): NEXT
' Typical prices: each port is cheap for one thing, dear for another.
'        Pepper Silk  Tea
DATA     12,    60,   30
DATA      6,    55,   35
DATA     14,    40,   25
DATA     18,    30,   12
FOR p = 1 TO NPORT: FOR g = 1 TO NGOOD
  READ usual(p, g): price(p, g) = usual(p, g)
NEXT g, p

RANDOMIZE TIMER
gold = 100: here = 1: day = 1

DO
  ' ---------------- the port screen ----------------
  CLS
  COLOR 14: PRINT "SPICE ROUTE TRADER";: COLOR 7
  PRINT "     Day"; day; "of"; DAYS; "   Port: "; port$(here)
  used = 0
  FOR g = 1 TO NGOOD: used = used + cargo(g): NEXT
  PRINT "Gold:"; gold; "   Hold:"; used; "/"; HOLD
  PRINT
  PRINT "Goods     Price here   You carry"
  FOR g = 1 TO NGOOD
    PRINT USING "\      \    ####        ###"; good$(g); price(here, g); cargo(g)
  NEXT
  PRINT
  PRINT "B)uy   S)ell   T)ravel   Q)uit"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> "" AND INSTR("BSTQ" + CHR$(27), k$) > 0

  SELECT CASE k$
    CASE "B", "S"
      PRINT "Which good? (1 Pepper, 2 Silk, 3 Tea) ";
      LINE INPUT a$: g = VAL(a$)
      IF g >= 1 AND g <= NGOOD THEN
        IF k$ = "B" THEN
          ' the most you can buy: limited by gold AND by free space
          most = gold \ price(here, g)
          IF most > HOLD - used THEN most = HOLD - used
          PRINT "How many? (max"; most; ") ";
          LINE INPUT a$: n = VAL(a$)
          IF n > 0 AND n <= most THEN
            gold = gold - n * price(here, g): cargo(g) = cargo(g) + n
          END IF
        ELSE
          PRINT "How many? (you have"; cargo(g); ") ";
          LINE INPUT a$: n = VAL(a$)
          IF n > 0 AND n <= cargo(g) THEN
            gold = gold + n * price(here, g): cargo(g) = cargo(g) - n
          END IF
        END IF
      END IF
    CASE "T"
      PRINT "Sail to: ";
      FOR p = 1 TO NPORT
        IF p <> here THEN PRINT p; port$(p); " ";
      NEXT
      PRINT
      LINE INPUT "Port number? ", a$: p = VAL(a$)
      IF p >= 1 AND p <= NPORT AND p <> here THEN
        here = p: day = day + 1
        GOSUB NewDay
      END IF
    CASE ELSE
      day = DAYS + 1
  END SELECT
LOOP UNTIL day > DAYS

' ---------------- final score ----------------
CLS
' unsold cargo is worth half the base price - sell before the end!
worth = 0
FOR g = 1 TO NGOOD: worth = worth + cargo(g) * usual(here, g) \ 2: NEXT
PRINT "Your voyage is over."
PRINT "Gold:"; gold; "  + cargo sold cheaply:"; worth
PRINT "FINAL FORTUNE:"; gold + worth
SELECT CASE gold + worth
  CASE IS < 100: PRINT "You lost money. Perhaps farming suits you better."
  CASE IS < 400: PRINT "A modest profit. Respectable!"
  CASE IS < 1000: PRINT "A fine merchant! Your name is known in every port."
  CASE ELSE: PRINT "LEGENDARY TRADER! Songs will be sung about you."
END SELECT
END

' ---------------- one day passes at sea ----------------
NewDay:
  ' every price drifts randomly by up to 20%, but is pulled gently
  ' back toward its usual (usual) value so it never runs away.
  FOR p = 1 TO NPORT
    FOR g = 1 TO NGOOD
      change! = (RND - .5) * .4
      pull! = (usual(p, g) - price(p, g)) * .2
      price(p, g) = price(p, g) * (1 + change!) + pull!
      IF price(p, g) < 2 THEN price(p, g) = 2
    NEXT
  NEXT
  ' a random event?  roll a 10-sided die
  PRINT
  COLOR 11
  SELECT CASE INT(RND * 10) + 1
    CASE 1
      ' pirates steal a third of each cargo
      PRINT "PIRATES! They board your ship and take a third of your cargo."
      FOR g = 1 TO NGOOD: cargo(g) = cargo(g) - cargo(g) \ 3: NEXT
    CASE 2
      PRINT "A STORM! You throw 5 crates overboard to stay afloat."
      lost = 5
      FOR g = NGOOD TO 1 STEP -1
        WHILE cargo(g) > 0 AND lost > 0: cargo(g) = cargo(g) - 1: lost = lost - 1: WEND
      NEXT
    CASE 3
      g = INT(RND * NGOOD) + 1
      PRINT "FESTIVAL in "; port$(here); "! Everyone wants "; good$(g); " - price doubled!"
      price(here, g) = price(here, g) * 2
    CASE 4
      f = INT(RND * 40) + 10
      PRINT "You fish a floating chest out of the sea:"; f; "gold!"
      gold = gold + f
    CASE ELSE
      PRINT "Smooth sailing to "; port$(here); "."
  END SELECT
  COLOR 7
  PRINT "Press any key..."
  DO: LOOP WHILE INKEY$ = ""
RETURN
