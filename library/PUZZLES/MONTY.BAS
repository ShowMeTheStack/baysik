' ============================================================
' TITLE:    Monty Hall Simulator
' CATEGORY: Puzzles & Logic
' LEVEL:    Beginner
' TAGS:     probability, simulation, random, statistics, game show
' SUMMARY:  Play the famous game-show puzzle, then run thousands of games to see why switching doors wins 2/3 of the time.
' ------------------------------------------------------------
' WHAT IT DOES
'   Behind one of three doors is a car; behind the other two, goats.
'   You pick a door.  The host (who KNOWS where the car is) opens a
'   different door that hides a goat, then asks: "Do you want to
'   switch to the other closed door?"
'
'   Most people think it's 50/50.  It isn't!  Your first pick is right
'   only 1 time in 3.  The other 2 times, the car is behind one of the
'   doors you didn't pick - and the host has kindly removed the goat
'   from those two, so switching wins.  Switching wins 2/3 of the time.
'
' HOW TO USE
'   1 = play rounds yourself (your score is kept)
'   2 = simulate many games for both strategies and compare
'   3 = simulate with MORE doors (the host opens all but one)
'   Q = quit
'
' CONCEPTS YOU WILL LEARN
'   * RND and RANDOMIZE for random experiments
'   * The "law of large numbers": more trials, closer to the truth
'   * Conditional probability, the counter-intuitive way
'   * Drawing simple bar charts with STRING$
'
' THINGS TO TRY
'   * Make a "forgetful host" who opens a random door (and sometimes
'     reveals the car).  Does switching still help?
'   * With 100 doors, what is the chance that switching wins?
' ============================================================
DECLARE SUB Bar (label$, wins&, total&)
DECLARE FUNCTION AskNum& (prompt$, lo&, hi&)
DEFINT A-Z

RANDOMIZE TIMER
DIM door$(3)
DO
    CLS
    COLOR 14: PRINT "THE MONTY HALL PROBLEM": COLOR 7
    PRINT
    PRINT "  1) Play the game"
    PRINT "  2) Simulate many games (3 doors)"
    PRINT "  3) Simulate with more doors"
    PRINT "  Q) Quit"
    LINE INPUT "  Choice: "; a$
    a$ = UCASE$(LTRIM$(a$))
    IF INSTR(a$, "Q") OR INSTR(a$, CHR$(27)) THEN EXIT DO
    SELECT CASE a$
        CASE "1"
            ' ---- Interactive rounds ----------------------------------
            DO
                CLS
                car = INT(RND * 3) + 1
                PRINT "  Three closed doors:   [ 1 ]   [ 2 ]   [ 3 ]"
                PRINT
                pick = AskNum&("  Pick a door (1-3, 0 = back to menu)", 0, 3)
                IF pick = 0 THEN EXIT DO
                ' Host opens a goat door that is neither yours nor the car.
                DO
                    opened = INT(RND * 3) + 1
                LOOP WHILE opened = pick OR opened = car
                other = 6 - pick - opened         ' 1+2+3 = 6
                PRINT
                PRINT "  The host opens door"; opened; "... it's a GOAT!"
                PRINT "  Door"; other; "is still closed."
                ' (LINE INPUT's prompt must be a plain "string", so we
                ' PRINT the changing part first and end it with ;)
                PRINT "  Switch to door"; other;
                LINE INPUT "? (Y/N) "; k$
                switched = (UCASE$(LEFT$(k$, 1)) = "Y")
                IF switched THEN final = other ELSE final = pick
                PRINT
                PRINT "  The car was behind door"; car; "."
                IF final = car THEN
                    COLOR 10: PRINT "  You WIN the car!": COLOR 7
                ELSE
                    COLOR 12: PRINT "  You win a goat. Baa!": COLOR 7
                END IF
                IF switched THEN
                    sGames = sGames + 1: IF final = car THEN sWins = sWins + 1
                ELSE
                    kGames = kGames + 1: IF final = car THEN kWins = kWins + 1
                END IF
                PRINT
                PRINT "  Your record:  switching"; sWins; "/"; sGames; "   staying"; kWins; "/"; kGames
                PRINT
                LINE INPUT "  Enter = another round, M = menu: "; k$
                IF UCASE$(LEFT$(k$, 1)) = "M" OR INSTR(UCASE$(k$), "Q") OR INSTR(k$, CHR$(27)) THEN EXIT DO
            LOOP
        CASE "2", "3"
            nDoors = 3
            IF a$ = "3" THEN nDoors = AskNum&("  How many doors (3-1000)", 3, 1000)
            games& = AskNum&("  How many games to simulate (10-100000)", 10, 100000)
            stayWins& = 0: switchWins& = 0
            PRINT
            FOR g& = 1 TO games&
                car = INT(RND * nDoors) + 1
                pick = INT(RND * nDoors) + 1
                IF nDoors = 3 THEN
                    ' Act out the show exactly: the host opens a goat
                    ' door that isn't yours, and "switch" means taking
                    ' the last closed door.
                    DO
                        opened = INT(RND * 3) + 1
                    LOOP WHILE opened = pick OR opened = car
                    other = 6 - pick - opened
                ELSE
                    ' The host opens every door except yours and ONE
                    ' other.  If you picked the car, that other door is
                    ' a random goat; otherwise it MUST be the car.
                    IF pick = car THEN
                        DO: other = INT(RND * nDoors) + 1: LOOP WHILE other = pick
                    ELSE
                        other = car
                    END IF
                END IF
                IF pick = car THEN stayWins& = stayWins& + 1
                IF other = car THEN switchWins& = switchWins& + 1
                IF g& MOD 1000 = 0 THEN LOCATE CSRLIN, 3: PRINT "games played:"; g&;
            NEXT
            PRINT
            PRINT
            Bar "Stay  ", stayWins&, games&
            Bar "Switch", switchWins&, games&
            PRINT
            PRINT "  Theory: stay wins 1/" + LTRIM$(STR$(nDoors));
            PRINT USING " = #.####, switch wins #.####"; 1 / nDoors; 1 - 1 / nDoors
        CASE ELSE
            PRINT "  Please choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    LINE INPUT "  Press Enter for the menu (Q quits) "; k$
    IF INSTR(UCASE$(k$), "Q") OR INSTR(k$, CHR$(27)) THEN EXIT DO
LOOP
CLS
END

FUNCTION AskNum& (prompt$, lo&, hi&)
    ' Ask until a number in range is typed.  Q gives back lo&.
    DO
        PRINT prompt$;
        LINE INPUT "? "; t$
        IF INSTR(UCASE$(t$), "Q") OR INSTR(t$, CHR$(27)) THEN AskNum& = lo&: EXIT FUNCTION
        v& = VAL(t$)
        IF v& >= lo& AND v& <= hi& THEN AskNum& = v&: EXIT FUNCTION
        PRINT "  Please type a number from"; lo&; "to"; hi&
    LOOP
END FUNCTION

SUB Bar (label$, wins&, total&)
    ' A 50-character bar: each # is 2% of the games.
    p! = wins& / total&
    PRINT "  "; label$; " ";
    COLOR 10: PRINT STRING$(INT(p! * 50 + .5), 219);
    COLOR 8: PRINT STRING$(50 - INT(p! * 50 + .5), 176);
    COLOR 7
    PRINT USING " ##.#%"; p! * 100
END SUB
