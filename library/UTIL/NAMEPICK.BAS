' ============================================================
' TITLE:    Random Name Picker
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     random, arrays, shuffle, animation, classroom
' SUMMARY:  Spin a slot-machine style wheel of names, pick without repeats, or split everyone into teams.
' ------------------------------------------------------------
' WHAT IT DOES
'   Type in a list of names (or use the sample class).  Then:
'   * PICK spins through the names, slowing down like a wheel,
'     and lands on a random one.  Picked names are removed so
'     everyone gets a turn before anybody goes twice.
'   * TEAMS shuffles everybody and deals them into N teams.
'
'   The shuffle is the Fisher-Yates algorithm: walk backwards
'   through the list and swap each item with a random item at
'   or before it.  Every possible order is equally likely.
'
' HOW TO USE
'   E = enter your own names, P = pick one, T = make teams,
'   R = reset (put everyone back), Q or Esc = quit.
'
' CONCEPTS YOU WILL LEARN
'   * RND to choose a random array index
'   * Removing an item by swapping it with the last one
'   * Fisher-Yates shuffle
'   * A slowing-down animation with a growing delay
'
' THINGS TO TRY
'   * Load names from a text file.
'   * Give some names more "tickets" (weighted picking).
'   * Play a different SOUND for each name during the spin.
' ============================================================

DECLARE SUB Pause (secs!)

CONST MAXN = 40
DIM names$(1 TO MAXN), pool$(1 TO MAXN)
DIM sh$(1 TO MAXN)          ' shuffled copy used for teams
RANDOMIZE TIMER

' ---- Sample names so it works straight away ----
total = 0
DO
    READ nm$
    IF nm$ = "*" THEN EXIT DO
    total = total + 1: names$(total) = nm$
LOOP
DATA Ava,Ben,Chloe,Dev,Ella,Finn,Grace,Hiro,Isla,Jack,Kemi,Leo,*
GOSUB ResetPool

DO
    CLS
    COLOR 11: PRINT "RANDOM NAME PICKER": COLOR 7
    PRINT total; "names,"; remain; "still to be picked"
    PRINT
    PRINT "  E Enter names   P Pick   T Teams   R Reset   Q Quit"
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
        CASE "E"
            PRINT
            PRINT "Type one name per line, blank line to finish:"
            total = 0
            DO WHILE total < MAXN
                LINE INPUT "  > "; nm$
                nm$ = LTRIM$(RTRIM$(nm$))
                IF nm$ = "" THEN EXIT DO
                total = total + 1: names$(total) = nm$
            LOOP
            IF total = 0 THEN total = 1: names$(1) = "Nobody"
            GOSUB ResetPool
        CASE "P"
            IF remain = 0 THEN GOSUB ResetPool    ' everyone had a turn
            ' ---- The spinning animation ----
            ' Show random names, waiting a bit longer each time,
            ' like a wheel slowing down.
            delay! = .02
            FOR s = 1 TO 18
                i = INT(RND * remain) + 1
                LOCATE 10, 25: PRINT SPACE$(30)
                LOCATE 10, 40 - LEN(pool$(i)) \ 2: COLOR 14: PRINT pool$(i): COLOR 7
                SOUND 300 + s * 40, 1
                Pause delay!
                delay! = delay! * 1.25
            NEXT s
            ' The REAL pick is the last one shown (index i).
            LOCATE 10, 25: PRINT SPACE$(30)
            LOCATE 10, 34 - LEN(pool$(i)) \ 2: COLOR 15, 2: PRINT " >> "; pool$(i); " << ": COLOR 7, 0
            ' Remove it: copy the last name into its place, shrink.
            pool$(i) = pool$(remain): remain = remain - 1
            LOCATE 13, 25: PRINT "Press any key..."
            DO: LOOP WHILE INKEY$ = ""
        CASE "T"
            PRINT
            INPUT "  How many teams"; nt
            nt = INT(nt)
            IF nt >= 2 AND nt <= total THEN
                ' Fisher-Yates shuffle of a copy of the full list.
                FOR i = 1 TO total: sh$(i) = names$(i): NEXT i
                FOR i = total TO 2 STEP -1
                    j = INT(RND * i) + 1          ' 1..i
                    SWAP sh$(i), sh$(j)
                NEXT i
                ' Deal like cards: person i goes to team (i-1) MOD nt.
                FOR t = 0 TO nt - 1
                    PRINT "  Team"; t + 1; ": ";
                    FOR i = t + 1 TO total STEP nt
                        PRINT sh$(i); " ";
                    NEXT i
                    PRINT
                NEXT t
            ELSE
                PRINT "  Need between 2 and"; total; "teams."
            END IF
            PRINT "  Press any key..."
            DO: LOOP WHILE INKEY$ = ""
        CASE "R": GOSUB ResetPool
        CASE "Q", CHR$(27): EXIT DO
    END SELECT
LOOP
CLS
END

' Copy every name into the "still to pick" pool.
ResetPool:
    FOR i = 1 TO total: pool$(i) = names$(i): NEXT i
    remain = total
    RETURN

' Wait secs! seconds (handles TIMER passing midnight).
SUB Pause (secs!)
    t0! = TIMER
    DO
        e! = TIMER - t0!
        IF e! < 0 THEN e! = e! + 86400
    LOOP UNTIL e! >= secs!
END SUB
