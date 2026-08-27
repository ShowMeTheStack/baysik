' ============================================================
' TITLE:    Bank Teller Queue Simulation
' CATEGORY: Business & Finance
' LEVEL:    Advanced
' TAGS:     simulation, queues, random arrivals, LOG, staffing, animation
' SUMMARY:  Simulate a bank lobby minute by minute, watch the line grow and shrink, then find the cheapest number of tellers.
' ------------------------------------------------------------
' WHAT IT DOES
'   How many tellers should a bank put on duty? Too few and the
'   line gets long and customers get angry; too many and you pay
'   people to stand around. This is a QUEUEING problem.
'   Part 1 animates one day (9:00 to 17:00): customers (people
'   shapes) arrive at random, wait in ONE shared line, and go to
'   the first free teller. Lunchtime (12-14) is extra busy.
'   Part 2 runs the whole day again, very fast and many times, for
'   1 to 6 tellers and prints a STAFFING TABLE: average wait, longest
'   line, how busy the tellers are, and the total daily cost =
'   teller wages + a "cost" for every minute customers wait.
'   The cheapest row is the best staffing level.
'
' HOW TO USE
'   Enter the number of tellers for the animated day (1-6).
'   + / - speed the animation up or down, S skips to the table.
'   Press a key at the end to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Random arrivals: exponential gaps with -LOG(RND) * mean
'   * A FIFO queue held in an array with head/tail indexes
'   * Time-step simulation, statistics and utilisation
'   * Using a simulation to make a business decision
'
' THINGS TO TRY
'   * Give each teller a lunch break between 12 and 13
'   * Use separate lines for each teller: is it better or worse?
'   * Change the waiting cost: what does a bank that values its
'     customers' time more highly decide?
' ============================================================

DECLARE SUB RunDay (nTel%, animate%, avgWait!, maxLine%, busyPct!, served%)
DECLARE FUNCTION ExpRand! (mean!)

CONST OPENMIN = 480             ' 8 hours = 480 minutes
CONST SERVICEMEAN = 4.5         ' average minutes per customer
CONST WAGE = 22                 ' teller cost per hour ($)
CONST WAITCOST = .40            ' cost per customer-minute waiting ($)
DIM SHARED speed!
RANDOMIZE TIMER

CLS
PRINT "BANK TELLER QUEUE SIMULATION"
PRINT
INPUT "Tellers on duty for the animated day (1-6)"; t%
IF t% < 1 OR t% > 6 THEN t% = 2
speed! = .05
RunDay t%, -1, aw!, ml%, bp!, sv%
LOCATE 22, 1
' (No comma straight after ### here: in PRINT USING "###," means
' "use thousands separators", so we use | as a separator instead.)
PRINT USING "Day over: ### served | avg wait ##.# min | longest line ### | busy ###%"; sv%; aw!; ml%; bp!
PRINT "Press a key for the staffing table...";
DO: LOOP WHILE INKEY$ <> ""
k$ = INPUT$(1)

' ---- Part 2: staffing table --------------------------------------------
CLS
PRINT "STAFFING ANALYSIS  (average of 20 simulated days for each row)"
PRINT
PRINT "Tellers  Avg wait  Longest line  Busy %   Wages   Wait cost   TOTAL COST"
PRINT STRING$(74, "-")
best = 0: bestCost! = 1E+30
DIM cost!(1 TO 6)
FOR t% = 1 TO 6
    sw! = 0: sm! = 0: sb! = 0: sc! = 0
    FOR rep = 1 TO 20
        RunDay t%, 0, aw!, ml%, bp!, sv%
        sw! = sw! + aw!: sm! = sm! + ml%: sb! = sb! + bp!
        ' total waiting minutes = average wait x customers served
        sc! = sc! + aw! * sv% * WAITCOST
    NEXT rep
    ' Careful: t%, WAGE and OPENMIN are all INTEGERS, and 4 * 22 * 480
    ' is bigger than 32767 -> "Overflow". Dividing first (480 / 60
    ' gives a single-precision 8) keeps every step small and safe.
    wages! = t% * WAGE * (OPENMIN / 60)
    waitC! = sc! / 20
    cost!(t%) = wages! + waitC!
    IF cost!(t%) < bestCost! THEN bestCost! = cost!(t%): best = t%
    PRINT USING "   #     ###.# m      ###.#      ###%   $$#,###  $$##,###.##  $$##,###.##"; t%; sw! / 20; sm! / 20; sb! / 20; wages!; waitC!; cost!(t%)
NEXT t%
PRINT STRING$(74, "-")
PRINT
COLOR 10
PRINT "Cheapest choice:"; best; "tellers";
PRINT USING " (total $$#,###.## per day)"; bestCost!
COLOR 7
PRINT
PRINT "Few tellers: cheap wages, but long expensive waits."
PRINT "Many tellers: short waits, but they stand around idle."
PRINT "The best number balances the two costs."
k$ = INPUT$(1)
END

' ------------------------------------------------------------
' ExpRand!: a random gap with the given average. -LOG(RND) gives
' the "exponential distribution": lots of short gaps and an
' occasional long one, just like customers walking into a bank.
' (1 - RND is used so we never take LOG(0).)
' ------------------------------------------------------------
FUNCTION ExpRand! (mean!)
    ExpRand! = -LOG(1 - RND) * mean!
END FUNCTION

' ------------------------------------------------------------
' RunDay: simulates one day in 1-minute steps.
'   nTel%     tellers on duty
'   animate%  TRUE = draw the lobby and pause each minute
' Returns average wait, longest line, % of time tellers were busy
' and number of customers served (through its parameters).
' ------------------------------------------------------------
SUB RunDay (nTel%, animate%, avgWait!, maxLine%, busyPct!, served%)
    DIM q%(0 TO 499)            ' queue of ARRIVAL TIMES (circular)
    DIM remain!(1 TO 6)           ' minutes left on each teller's customer
    head% = 0: tail% = 0: qLen% = 0
    maxLine% = 0: served% = 0: totWait! = 0: busyMin! = 0
    nextArr! = ExpRand!(3)

    IF animate% THEN
        CLS
        LOCATE 1, 1: PRINT "FIRST BASIC BANK LOBBY       +/- speed   S = skip"
        FOR t = 1 TO nTel%
            LOCATE 3, 4 + (t - 1) * 12: PRINT "Teller"; t
        NEXT t
        LOCATE 9, 1: PRINT "Line:"
    END IF

    FOR m% = 0 TO OPENMIN - 1
        ' ---- Arrivals: the gap is shorter at lunchtime -------------
        IF m% >= 180 AND m% < 300 THEN gap! = 1.6 ELSE gap! = 3.2
        DO WHILE nextArr! <= m%
            IF qLen% < 500 THEN
                q%(tail%) = m%: tail% = (tail% + 1) MOD 500: qLen% = qLen% + 1
            END IF
            nextArr! = nextArr! + ExpRand!(gap!)
        LOOP
        IF qLen% > maxLine% THEN maxLine% = qLen%

        ' ---- Free tellers call the next customer ---------------------
        FOR t = 1 TO nTel%
            IF remain!(t) <= 0 AND qLen% > 0 THEN
                arrived% = q%(head%): head% = (head% + 1) MOD 500: qLen% = qLen% - 1
                totWait! = totWait! + (m% - arrived%)
                served% = served% + 1
                remain!(t) = ExpRand!(SERVICEMEAN) + .5
            END IF
            IF remain!(t) > 0 THEN busyMin! = busyMin! + 1: remain!(t) = remain!(t) - 1
        NEXT t

        ' ---- Draw ---------------------------------------------------
        IF animate% THEN
            clock% = 9 * 60 + m%
            ' RIGHT$("0" + ...) adds a leading zero so 9:05 isn't shown as 9: 5
            LOCATE 1, 60: PRINT USING "Time ##:"; clock% \ 60;
            PRINT RIGHT$("0" + LTRIM$(STR$(clock% MOD 60)), 2);
            FOR t = 1 TO nTel%
                LOCATE 5, 4 + (t - 1) * 12
                ' CHR$(2) is a smiley face = customer being served
                IF remain!(t) > 0 THEN COLOR 14: PRINT "[ "; CHR$(2); " ]"; ELSE COLOR 8: PRINT "[   ]";
                COLOR 7
            NEXT t
            ' The line: one smiley per waiting person, max 70 shown.
            n% = qLen%: IF n% > 70 THEN n% = 70
            LOCATE 10, 1: COLOR 11: PRINT STRING$(n%, 1); SPACE$(80 - n%); : COLOR 7
            LOCATE 12, 1
            IF served% > 0 THEN aw! = totWait! / served% ELSE aw! = 0
            PRINT USING "Waiting: ###   Served: ####   Average wait: ##.# min   Longest line: ###"; qLen%; served%; aw!; maxLine%
            IF m% >= 180 AND m% < 300 THEN LOCATE 14, 1: PRINT "LUNCH RUSH!   " ELSE LOCATE 14, 1: PRINT "              "
            t0! = TIMER
            DO
                k$ = UCASE$(INKEY$)
                IF k$ = "+" THEN speed! = speed! / 2
                IF k$ = "-" AND speed! < 1 THEN speed! = speed! * 2
                IF k$ = "S" OR k$ = CHR$(27) THEN animate% = 0: EXIT DO
            LOOP WHILE TIMER - t0! < speed! AND TIMER >= t0!
        END IF
    NEXT m%
    ' Customers still waiting at closing time are served after hours;
    ' we ignore them here to keep things simple.
    IF served% > 0 THEN avgWait! = totWait! / served% ELSE avgWait! = 0
    busyPct! = busyMin! / (nTel% * OPENMIN) * 100
END SUB
