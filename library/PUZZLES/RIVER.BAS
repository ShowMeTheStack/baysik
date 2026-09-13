' ============================================================
' TITLE:    River Crossing: Wolf, Goat and Cabbage
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     game, river crossing, bits, bfs, hints
' SUMMARY:  Ferry a wolf, a goat and a cabbage across the river without anything getting eaten - with a hint button.
' ------------------------------------------------------------
' WHAT IT DOES
'   A farmer must cross a river with a wolf, a goat and a cabbage.
'   The boat only holds the farmer and ONE passenger.
'     * Left alone, the wolf eats the goat.
'     * Left alone, the goat eats the cabbage.
'   This puzzle is over 1000 years old (Alcuin of York, around 800 AD).
'
'   The whole situation fits in 4 bits - one per character - telling
'   which bank each is on (0 = left, 1 = right).  So there are only
'   16 possible states, and the hint button runs a tiny breadth-first
'   search to find the best next move from wherever you are.
'
' HOW TO USE
'   W = take the wolf, G = take the goat, C = take the cabbage,
'   F = farmer crosses alone, H = hint, R = restart, Q / Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * Packing several true/false facts into one integer with bits
'   * Testing bits with AND, flipping them with XOR
'   * Safety rules as a FUNCTION
'   * Breadth-first search on a tiny state graph
'
' THINGS TO TRY
'   * There are exactly two shortest solutions (7 crossings).  Find
'     both!
'   * Add a fourth item, e.g. a dog that chases the wolf...
' ============================================================
DECLARE FUNCTION Safe% (s AS INTEGER)
DECLARE FUNCTION Hint% (s AS INTEGER)
DECLARE SUB Scene ()
DEFINT A-Z

' Bit values for each character.  A 1 bit means "on the right bank".
CONST FARMER = 1, WOLF = 2, GOAT = 4, CABBAGE = 8
DIM SHARED state, moves, msg$
DIM SHARED nm$(3)
nm$(0) = "Farmer": nm$(1) = "Wolf": nm$(2) = "Goat": nm$(3) = "Cabbage"

restart:
state = 0: moves = 0
msg$ = "Get everyone to the right bank.  W/G/C = take a passenger, F = go alone."
CLS
DO
    Scene
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    take = -1
    SELECT CASE k$
        CASE "F": take = 0
        CASE "W": take = WOLF
        CASE "G": take = GOAT
        CASE "C": take = CABBAGE
        CASE "H"
            h = Hint%(state)
            IF h = 0 THEN
                msg$ = "Hint: the farmer should cross alone."
            ELSEIF h > 0 THEN
                FOR i = 1 TO 3
                    IF h = 2 ^ i THEN msg$ = "Hint: take the " + nm$(i) + " across."
                NEXT
            ELSE
                msg$ = "No hint needed!"
            END IF
        CASE "R": GOTO restart
        CASE "Q", CHR$(27): EXIT DO
    END SELECT

    IF take >= 0 THEN
        ' A passenger must be on the SAME side as the farmer.
        farmerSide = state AND FARMER
        IF take > 0 AND ((state AND take) <> 0) <> (farmerSide <> 0) THEN
            msg$ = "That one is on the other bank!"
        ELSE
            ' XOR flips the bits: the farmer (and passenger) change bank.
            state = state XOR FARMER XOR take
            moves = moves + 1
            msg$ = ""
            IF NOT Safe%(state) THEN
                Scene
                LOCATE 18, 4: COLOR 12
                ' Which rule was broken?  (Same test as in Safe%.)
                w = (state AND WOLF) <> 0
                g = (state AND GOAT) <> 0
                f = (state AND FARMER) <> 0
                IF w = g AND f <> g THEN
                    PRINT "Oh no!  The wolf ate the goat!"
                ELSE
                    PRINT "Oh no!  The goat ate the cabbage!"
                END IF
                COLOR 7
                LOCATE 20, 4: PRINT "Press R to restart or Q to quit."
                DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
                IF k$ = "R" THEN GOTO restart
                EXIT DO
            END IF
            IF state = 15 THEN
                Scene
                LOCATE 18, 4: COLOR 10
                PRINT "Everybody made it across in"; moves; "crossings!"
                IF moves = 7 THEN PRINT "   That's the shortest possible - perfect!" ELSE PRINT "   (It can be done in 7.)"
                COLOR 7
                LOCATE 21, 4: PRINT "Press R to play again or Q to quit."
                DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = "R" OR k$ = "Q" OR k$ = CHR$(27)
                IF k$ = "R" THEN GOTO restart
                EXIT DO
            END IF
        END IF
    END IF
LOOP
CLS
END

FUNCTION Hint% (s AS INTEGER)
    ' BFS backwards would also work; here we BFS forwards from s and
    ' remember the FIRST move that led to each state.
    DIM firstMove(15), seen(15), q(15)
    IF s = 15 THEN Hint% = -1: EXIT FUNCTION
    head = 0: tail = 1: q(0) = s: seen(s) = -1
    DO WHILE head < tail
        cur = q(head): head = head + 1
        FOR i = 0 TO 3                   ' i = 0 alone, else bit 2^i
            IF i = 0 THEN t = 0 ELSE t = 2 ^ i
            ' Passenger must be beside the farmer.
            ok = -1
            IF t > 0 THEN ok = (((cur AND t) <> 0) = ((cur AND FARMER) <> 0))
            IF ok THEN
                nx = cur XOR FARMER XOR t
                IF Safe%(nx) AND NOT seen(nx) THEN
                    seen(nx) = -1
                    IF cur = s THEN firstMove(nx) = t ELSE firstMove(nx) = firstMove(cur)
                    IF nx = 15 THEN Hint% = firstMove(nx): EXIT FUNCTION
                    q(tail) = nx: tail = tail + 1
                END IF
            END IF
        NEXT
    LOOP
    Hint% = -1
END FUNCTION

FUNCTION Safe% (s AS INTEGER)
    ' Danger happens on the bank WITHOUT the farmer.
    f = (s AND FARMER) <> 0
    w = (s AND WOLF) <> 0
    g = (s AND GOAT) <> 0
    c = (s AND CABBAGE) <> 0
    Safe% = -1
    IF w = g AND f <> g THEN Safe% = 0       ' wolf + goat alone
    IF g = c AND f <> g THEN Safe% = 0       ' goat + cabbage alone
END FUNCTION

SUB Scene
    ' Left bank | river | right bank.  Each character is printed on the
    ' bank given by its bit.
    LOCATE 2, 4: COLOR 14: PRINT "WOLF, GOAT AND CABBAGE": COLOR 7
    FOR i = 0 TO 3
        bitv = 2 ^ i
        LOCATE 5 + i * 2, 4
        IF (state AND bitv) = 0 THEN
            COLOR 10: PRINT LEFT$(nm$(i) + SPACE$(10), 10);
        ELSE
            PRINT SPACE$(10);
        END IF
        COLOR 9: PRINT " |~~~~~~~~~~~~~~~~~~~~| ";
        IF (state AND bitv) <> 0 THEN
            COLOR 10: PRINT LEFT$(nm$(i) + SPACE$(10), 10);
        ELSE
            PRINT SPACE$(10);
        END IF
        COLOR 7
    NEXT
    ' The boat is always with the farmer.
    LOCATE 13, 4: PRINT SPACE$(50)
    COLOR 6
    IF state AND FARMER THEN LOCATE 13, 31 ELSE LOCATE 13, 16
    PRINT "\_boat_/"
    COLOR 7
    LOCATE 15, 4: PRINT "Crossings:"; moves
    LOCATE 16, 4: PRINT LEFT$(msg$ + SPACE$(75), 75)
    LOCATE 23, 4: PRINT "W/G/C = take passenger   F = alone   H = hint   R = restart   Q = quit";
END SUB
