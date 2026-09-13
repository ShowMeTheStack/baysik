' ============================================================
' TITLE:    Einstein's Riddle Solver (Who Owns the Fish?)
' CATEGORY: Puzzles & Logic
' LEVEL:    Advanced
' TAGS:     logic grid, zebra puzzle, permutations, constraints, backtracking
' SUMMARY:  Solves the famous five-houses logic puzzle by trying permutations and pruning with the clues.
' ------------------------------------------------------------
' WHAT IT DOES
'   Five houses in a row, each a different colour.  In each lives a
'   person of a different nationality who drinks a different drink,
'   smokes a different brand and keeps a different pet.  Fifteen
'   clues are given (shown on screen).  Question: who owns the fish?
'
'   A computer can't "reason" like you do, but it can search smartly:
'     * Each attribute (colours, nations...) is a PERMUTATION of 5
'       values over 5 houses: 5! = 120 possibilities.
'     * All 5 attributes together: 120^5 = 24,883,200,000 cases!
'     * But we choose them one attribute at a time and test every clue
'       as soon as all the attributes it mentions are chosen.  Wrong
'       branches die early, and only a few thousand tests are needed.
'
' HOW TO USE
'   Read the clues, press a key, and watch the solver work.  The
'   final table shows everyone's house.  Esc or Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Generating all permutations (Heap-style swapping recursion)
'   * Describing clues as DATA so the solver stays general
'   * Constraint propagation by ordering: check clues ASAP
'   * Lookup tables: inverse permutations answer "where is X?"
'
' THINGS TO TRY
'   * Remove a clue: how many solutions appear now?
'   * Change the attribute order in ORDER DATA and compare the
'     number of tests.
'   * Write your own logic puzzle in the DATA lines.
' ============================================================
DECLARE SUB MakePerms (k AS INTEGER)
DECLARE SUB Search (level AS INTEGER)
DECLARE FUNCTION Find% (v$, a AS INTEGER)
DEFINT A-Z

CONST NA = 5, NH = 5          ' attributes and houses
DIM SHARED aName$(NA - 1), vName$(NA - 1, NH - 1)
DIM SHARED perm(119, NH - 1)  ' perm(p, house) = value
DIM SHARED inv(119, NH - 1)   ' inv(p, value) = house
DIM SHARED nPerm, work(NH - 1)
DIM SHARED ord(NA - 1)        ' order in which attributes are chosen
DIM SHARED lvl(NA - 1)        ' lvl(attribute) = its position in ord()
DIM SHARED cur(NA - 1)        ' chosen permutation for each attribute
' Clues: type, attr1, value1, attr2, value2 (or house number)
DIM SHARED cT$(20), cA1(20), cV1(20), cA2(20), cV2(20), cLvl(20), nClues
DIM SHARED clue$(20)
DIM SHARED nSol, tests&, best(NA - 1)

' ---- Read attribute names and values -------------------------------
FOR a = 0 TO NA - 1
    READ aName$(a)
    FOR v = 0 TO NH - 1: READ vName$(a, v): NEXT
NEXT
FOR i = 0 TO NA - 1: READ ord(i): lvl(ord(i)) = i: NEXT

' ---- Read the clues ----------------------------------------------
' Kinds:  SAME  x has y        RIGHT x is just right of y
'         NEXT  x is beside y  AT    x is in house number n
nClues = 0
DO
    READ k$
    IF k$ = "END" THEN EXIT DO
    nClues = nClues + 1
    cT$(nClues) = k$
    READ v$: cV1(nClues) = Find%(v$, a): cA1(nClues) = a
    IF k$ = "AT" THEN
        READ cV2(nClues): cA2(nClues) = cA1(nClues)
    ELSE
        READ w$: cV2(nClues) = Find%(w$, a): cA2(nClues) = a
    END IF
    READ clue$(nClues)
    ' A clue can be tested at the LATER of its two attributes' levels.
    cLvl(nClues) = lvl(cA1(nClues))
    IF lvl(cA2(nClues)) > cLvl(nClues) THEN cLvl(nClues) = lvl(cA2(nClues))
LOOP

' ---- Build the 120 permutations once -----------------------------
FOR i = 0 TO NH - 1: work(i) = i: NEXT
nPerm = 0
MakePerms 0

' ---- Show the puzzle ---------------------------------------------
CLS
COLOR 14: PRINT "EINSTEIN'S RIDDLE - the clues": COLOR 7
FOR i = 1 TO nClues
    PRINT USING "## "; i; : PRINT clue$(i)
NEXT
PRINT : COLOR 11: PRINT "Who owns the fish?   Press a key to let the computer solve it.": COLOR 7
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) OR UCASE$(k$) = "Q" THEN CLS : END

CLS
PRINT "Searching..."
t! = TIMER
Search 0
CLS
COLOR 14: PRINT "SOLUTION": COLOR 7
PRINT
PRINT SPACE$(12);
FOR h = 0 TO NH - 1: PRINT "House"; h + 1; "   "; : NEXT
PRINT
FOR a = 0 TO NA - 1
    COLOR 11: PRINT LEFT$(aName$(a) + SPACE$(12), 12); : COLOR 7
    FOR h = 0 TO NH - 1
        PRINT LEFT$(vName$(a, perm(best(a), h)) + SPACE$(11), 11);
    NEXT
    PRINT
NEXT
PRINT
' Answer the question with the inverse tables:
' which house holds the Fish, and which nation lives there?
pa = Find%("Fish", a)
h = inv(best(a), pa)
COLOR 10
PRINT "The "; vName$(0, perm(best(0), h)); " owns the fish (house " + LTRIM$(STR$(h + 1)) + ")."
COLOR 7
PRINT
PRINT "Solutions found:"; nSol; "   clue tests:"; tests&
PRINT USING "Time: ##.## seconds"; TIMER - t!
PRINT : PRINT "Press any key to quit."
DO: LOOP WHILE INKEY$ = ""
CLS
END

' Attribute name, then its 5 values.
DATA Nation, Brit, Swede, Dane, Norwegian, German
DATA Colour, Red, Green, White, Yellow, Blue
DATA Drink, Tea, Coffee, Milk, Beer, Water
DATA Smoke, PallMall, Dunhill, Blends, BlueMaster, Prince
DATA Pet, Dog, Bird, Cat, Horse, Fish
' ORDER: choose Colour, Nation, Drink, Smoke, then Pet.
DATA 1, 0, 2, 3, 4
' The 15 clues.
DATA SAME, Brit, Red, "The Brit lives in the red house."
DATA SAME, Swede, Dog, "The Swede keeps dogs as pets."
DATA SAME, Dane, Tea, "The Dane drinks tea."
DATA RIGHT, White, Green, "The green house is just left of the white house."
DATA SAME, Green, Coffee, "The green house's owner drinks coffee."
DATA SAME, PallMall, Bird, "The Pall Mall smoker keeps birds."
DATA SAME, Yellow, Dunhill, "The owner of the yellow house smokes Dunhill."
DATA AT, Milk, 2, "The man in the centre house drinks milk."
DATA AT, Norwegian, 0, "The Norwegian lives in the first house."
DATA NEXT, Blends, Cat, "The Blends smoker lives next to the cat owner."
DATA NEXT, Horse, Dunhill, "The horse owner lives next to the Dunhill smoker."
DATA SAME, BlueMaster, Beer, "The BlueMaster smoker drinks beer."
DATA SAME, German, Prince, "The German smokes Prince."
DATA NEXT, Norwegian, Blue, "The Norwegian lives next to the blue house."
DATA NEXT, Blends, Water, "The Blends smoker has a neighbour who drinks water."
DATA END

FUNCTION Find% (v$, a AS INTEGER)
    ' Look up a value name.  Returns its index and sets a = attribute.
    FOR i = 0 TO NA - 1
        FOR j = 0 TO NH - 1
            IF UCASE$(vName$(i, j)) = UCASE$(v$) THEN a = i: Find% = j: EXIT FUNCTION
        NEXT
    NEXT
    PRINT "Unknown value in DATA: "; v$: END
END FUNCTION

SUB MakePerms (k AS INTEGER)
    ' Classic recursive permutation: put each remaining value in
    ' position k, permute the rest, then swap back.
    IF k = NH THEN
        FOR h = 0 TO NH - 1
            perm(nPerm, h) = work(h)
            inv(nPerm, work(h)) = h
        NEXT
        nPerm = nPerm + 1
        EXIT SUB
    END IF
    FOR i = k TO NH - 1
        SWAP work(k), work(i)
        MakePerms k + 1
        SWAP work(k), work(i)
    NEXT
END SUB

SUB Search (level AS INTEGER)
    IF level = NA THEN
        nSol = nSol + 1
        FOR a = 0 TO NA - 1: best(a) = cur(a): NEXT
        EXIT SUB
    END IF
    a = ord(level)
    FOR p = 0 TO nPerm - 1
        cur(a) = p
        ' Test only the clues that became checkable at this level.
        ok = -1
        FOR i = 1 TO nClues
            IF cLvl(i) = level THEN
                tests& = tests& + 1
                h1 = inv(cur(cA1(i)), cV1(i))      ' house of thing 1
                SELECT CASE cT$(i)
                    CASE "SAME": ok = (h1 = inv(cur(cA2(i)), cV2(i)))
                    CASE "RIGHT": ok = (h1 = inv(cur(cA2(i)), cV2(i)) + 1)
                    CASE "NEXT": ok = (ABS(h1 - inv(cur(cA2(i)), cV2(i))) = 1)
                    CASE "AT": ok = (h1 = cV2(i))
                END SELECT
                IF NOT ok THEN EXIT FOR
            END IF
        NEXT
        IF ok THEN
            IF level = 0 THEN LOCATE 2, 1: PRINT "Trying colour pattern"; p + 1; "of 120  "
            Search level + 1
        END IF
    NEXT
END SUB
