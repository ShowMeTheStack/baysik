' ============================================================
' TITLE:    Murder at Ashworth Manor
' CATEGORY: Adventure, Stories & AI
' LEVEL:    Intermediate
' TAGS:     mystery, deduction, logic, random generation, clues
' SUMMARY:  A new randomly generated whodunit every game - search rooms, check alibis, accuse.
' ------------------------------------------------------------
' WHAT IT DOES
'   Lord Ashworth has been found dead.  Each game the program
'   secretly chooses WHO did it, WITH WHAT and WHERE, and then builds
'   a set of clues that are consistent with that answer:
'     * Innocent guests were in pairs, and each pair tells the same
'       story: "I was in the Library with Dr Finch."
'     * The murderer LIES, claiming to be with someone who will
'       say they were with somebody else.  Find the contradiction!
'     * Searching rooms shows which weapons are still in place - the
'       missing one is the weapon - and one room shows signs of a
'       struggle: the scene of the crime.
'   You have 12 actions before the police arrive.  Choose wisely.
'
' HOW TO USE
'   S = search a room,  I = interview a guest,  N = read notebook,
'   A = make your accusation,  Esc = give up.
'
' CONCEPTS YOU WILL LEARN
'   * Generating a puzzle from a hidden solution, so it is fair
'   * Shuffling to make random pairs
'   * Keeping a notebook (an array of strings) of discovered facts
'   * Logical deduction from contradictions
'
' THINGS TO TRY
'   * Add a sixth guest who is also a liar (but innocent!)
'   * Make some rooms locked until you find a key
'   * Give a score: fewer actions used = higher rank
' ============================================================

DECLARE SUB Note (t$)
DECLARE FUNCTION Choose% (title$, n%, kind%)
DEFINT A-Z
CONST NS = 5, NWEP = 4, NROOM = 5, ACTIONS = 12
DIM SHARED who$(1 TO NS), wep$(1 TO NWEP), room$(1 TO NROOM)
DIM wepHome(1 TO NWEP), partner(1 TO NS), alibiRoom(1 TO NS)
DIM SHARED book$(1 TO 40), nBook
DIM order(1 TO NS), searched(1 TO NROOM), asked(1 TO NS)

DATA "Colonel Gray","Dr Finch","Mrs Peacock","Lady Rose","Mr Plum"
DATA "candlestick","kitchen knife","rope","poison bottle"
DATA "Library","Kitchen","Conservatory","Ballroom","Study"
FOR i = 1 TO NS: READ who$(i): NEXT
FOR i = 1 TO NWEP: READ wep$(i): NEXT
FOR i = 1 TO NROOM: READ room$(i): NEXT
' where each weapon normally belongs
wepHome(1) = 4: wepHome(2) = 2: wepHome(3) = 3: wepHome(4) = 5
RANDOMIZE TIMER

' ================= build the hidden solution =================
killer = INT(RND * NS) + 1
weapon = INT(RND * NWEP) + 1
scene = INT(RND * NROOM) + 1

' The four innocents are shuffled, then paired: 1st+2nd, 3rd+4th.
n = 0
FOR i = 1 TO NS
  IF i <> killer THEN n = n + 1: order(n) = i
NEXT
FOR i = 4 TO 2 STEP -1
  j = INT(RND * i) + 1: SWAP order(i), order(j)
NEXT
FOR p = 1 TO 3 STEP 2
  a = order(p): b = order(p + 1)
  partner(a) = b: partner(b) = a
  ' each pair was together in some room that is NOT the crime scene
  ' (and the second pair picks a different room from the first)
  DO: r = INT(RND * NROOM) + 1: LOOP WHILE r = scene OR (p = 3 AND r = alibiRoom(order(1)))
  alibiRoom(a) = r: alibiRoom(b) = r
NEXT
' The killer's lie: "I was with <some innocent> in <their room>".
' That innocent will name a different partner - the contradiction!
partner(killer) = order(INT(RND * 4) + 1)
alibiRoom(killer) = alibiRoom(partner(killer))

' ================= play =================
remain = ACTIONS
CLS
COLOR 12: PRINT "MURDER AT ASHWORTH MANOR": COLOR 7
PRINT "Lord Ashworth lies dead. Five guests, five rooms, four possible weapons."
PRINT "The police arrive in"; ACTIONS; "actions. Find out who, with what, and where."
DO
  PRINT
  COLOR 14: PRINT "Actions left:"; remain;: COLOR 7
  PRINT "   S)earch room  I)nterview  N)otebook  A)ccuse"
  DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> "" AND INSTR("SINA" + CHR$(27), k$) > 0
  SELECT CASE k$
    CASE CHR$(27)
      PRINT "You hand the case to the police. It was "; who$(killer); "."
      END
    CASE "S"
      r = Choose("Search which room?", NROOM, 3)
      remain = remain - 1
      COLOR 11: PRINT "You search the "; room$(r); "...": COLOR 7
      IF r = scene THEN Note "The " + room$(r) + " shows signs of a struggle: the crime scene!"
      found = 0
      FOR w = 1 TO NWEP
        IF wepHome(w) = r THEN
          found = 1
          IF w = weapon THEN
            Note "The " + wep$(w) + " is MISSING from the " + room$(r) + "."
          ELSE
            Note "The " + wep$(w) + " is in its place in the " + room$(r) + ", clean."
          END IF
        END IF
      NEXT
      IF found = 0 AND r <> scene THEN Note "Nothing unusual in the " + room$(r) + "."
    CASE "I"
      s = Choose("Interview whom?", NS, 1)
      remain = remain - 1
      COLOR 11: PRINT who$(s); " says:": COLOR 7
      Note who$(s) + ": 'I was in the " + room$(alibiRoom(s)) + " with " + who$(partner(s)) + ".'"
    CASE "N"
      PRINT "---- Notebook ----"
      IF nBook = 0 THEN PRINT "(empty)"
      FOR i = 1 TO nBook: PRINT " * "; book$(i): NEXT
    CASE "A"
      EXIT DO
  END SELECT
  IF remain = 0 THEN
    COLOR 12: PRINT "The police are here! You must accuse someone NOW.": COLOR 7
    EXIT DO
  END IF
LOOP

' ================= the accusation =================
PRINT
aw = Choose("Who did it?", NS, 1)
ap = Choose("With what?", NWEP, 2)
ar = Choose("Where?", NROOM, 3)
PRINT
PRINT "You declare: "; CHR$(34); who$(aw); ", with the "; wep$(ap); ", in the "; room$(ar); "!"; CHR$(34)
PRINT
correct = 0
IF aw = killer THEN correct = correct + 1
IF ap = weapon THEN correct = correct + 1
IF ar = scene THEN correct = correct + 1
IF correct = 3 THEN
  COLOR 10: PRINT "Absolutely right! "; who$(killer); " confesses. Case closed, detective!"
ELSE
  COLOR 12: PRINT "Not quite -"; correct; "of 3 correct."
  PRINT "The truth: "; who$(killer); ", with the "; wep$(weapon); ", in the "; room$(scene); "."
END IF
COLOR 7

' Show a numbered list (kind 1 = guests, 2 = weapons, 3 = rooms)
' and return the number the player presses.
FUNCTION Choose% (title$, n, kind)
  PRINT title$
  FOR i = 1 TO n
    SELECT CASE kind
      CASE 1: t$ = who$(i)
      CASE 2: t$ = wep$(i)
      CASE ELSE: t$ = room$(i)
    END SELECT
    PRINT "  "; LTRIM$(STR$(i)); ") "; t$
  NEXT
  DO
    c = VAL(INKEY$)
  LOOP UNTIL c >= 1 AND c <= n
  Choose% = c
END FUNCTION

' Print a clue and copy it into the notebook.
SUB Note (t$)
  PRINT "  "; t$
  IF nBook < 40 THEN nBook = nBook + 1: book$(nBook) = t$
END SUB
