' ============================================================
' TITLE:    Budget Envelope Tracker
' CATEGORY: Business & Finance
' LEVEL:    Intermediate
' TAGS:     budget, sequential files, arrays, menus, PRINT USING
' SUMMARY:  Split your monthly income into spending "envelopes", record purchases and save it all to a file.
' ------------------------------------------------------------
' WHAT IT DOES
'   The envelope method is an old budgeting trick: on pay day you
'   put cash into envelopes labelled Rent, Food, Fun and so on.
'   When an envelope is empty, you stop spending on that thing!
'   This program keeps the envelopes for you. It shows how much is
'   left in each with a little gauge, lets you spend from one, move
'   money between envelopes, refill them on pay day and save
'   everything to ENVELOPE.DAT so it is there next time.
'
' HOW TO USE
'   Choose from the menu: S = spend, M = move money,
'   P = pay day (refill), A = add envelope, Q = save & quit.
'   Envelope numbers are shown on the left.
'
' CONCEPTS YOU WILL LEARN
'   * Saving and loading data with WRITE # and INPUT #
'   * ON ERROR GOTO to handle "file not found" on the first run
'   * Parallel arrays (name, budget, balance) for records
'   * Drawing simple text gauges with STRING$
'
' THINGS TO TRY
'   * Keep a history file of every purchase (OPEN ... FOR APPEND)
'   * Colour an envelope red when it is below 10% of its budget
'   * Add a "roll over" option that keeps leftovers at pay day
' ============================================================

CONST MAXENV = 12
CONST FILENAME$ = "ENVELOPE.DAT"
DIM SHARED ename$(1 TO MAXENV), budget(1 TO MAXENV), bal(1 TO MAXENV)
DIM SHARED nEnv

' ---- Load saved envelopes, or create a starter set ---------------
' If the file does not exist yet, OPEN raises error 53 ("File not
' found"). ON ERROR sends us to NoFile, where we set a flag.
fileOk = -1
ON ERROR GOTO NoFile
OPEN FILENAME$ FOR INPUT AS #1
ON ERROR GOTO 0
IF fileOk THEN
    INPUT #1, nEnv
    FOR i = 1 TO nEnv
        INPUT #1, ename$(i), budget(i), bal(i)
    NEXT i
    CLOSE #1
ELSE
    ' First run: starter envelopes from DATA, all full.
    RESTORE Starter
    READ nEnv
    FOR i = 1 TO nEnv
        READ ename$(i), budget(i)
        bal(i) = budget(i)
    NEXT i
END IF

DO
    GOSUB ShowAll
    PRINT
    PRINT "S)pend  M)ove  P)ay day  A)dd envelope  Q)uit & save"
    INPUT "Choice"; c$
    c$ = UCASE$(LEFT$(c$, 1))
    SELECT CASE c$
    CASE "S"
        INPUT "Spend from envelope #"; e
        IF e >= 1 AND e <= nEnv THEN
            INPUT "Amount $"; amt
            IF amt > bal(e) THEN
                PRINT "Not enough in "; ename$(e); "! Only";
                PRINT USING " $$#,###.##"; bal(e)
                PRINT "Press a key": k$ = INPUT$(1)
            ELSEIF amt > 0 THEN
                bal(e) = bal(e) - amt
            END IF
        END IF
    CASE "M"
        INPUT "Move FROM envelope #"; a
        INPUT "Move TO envelope #"; b
        INPUT "Amount $"; amt
        IF a >= 1 AND a <= nEnv AND b >= 1 AND b <= nEnv AND amt > 0 THEN
            IF amt > bal(a) THEN amt = bal(a)   ' can't move more than is there
            bal(a) = bal(a) - amt
            bal(b) = bal(b) + amt
        END IF
    CASE "P"
        ' Pay day: every envelope is topped back up to its budget.
        total = 0
        FOR i = 1 TO nEnv
            total = total + budget(i) - bal(i)
            bal(i) = budget(i)
        NEXT i
        PRINT USING "Pay day_! $$##,###.## put into the envelopes."; total
        PRINT "Press a key": k$ = INPUT$(1)
    CASE "A"
        IF nEnv < MAXENV THEN
            INPUT "Envelope name"; n$
            INPUT "Monthly budget $"; amt
            IF n$ <> "" AND amt > 0 THEN
                nEnv = nEnv + 1
                ename$(nEnv) = LEFT$(n$, 14)
                budget(nEnv) = amt
                bal(nEnv) = amt
            END IF
        END IF
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP

' ---- Save everything ---------------------------------------------
' WRITE # puts quotes around strings and commas between values,
' exactly the format INPUT # expects to read back.
OPEN FILENAME$ FOR OUTPUT AS #1
WRITE #1, nEnv
FOR i = 1 TO nEnv
    WRITE #1, ename$(i), budget(i), bal(i)
NEXT i
CLOSE #1
PRINT "Saved to "; FILENAME$; ". See you next time!"
END

' ------------------------------------------------------------
' ShowAll: table of envelopes with a 20-character gauge.
' The gauge shows the fraction left: full blocks for money left,
' light dots for money spent.
' ------------------------------------------------------------
ShowAll:
    CLS
    PRINT "BUDGET ENVELOPES"
    PRINT " #  Envelope          Budget       Left   Gauge"
    PRINT STRING$(68, "-")
    tb = 0: tl = 0
    FOR i = 1 TO nEnv
        IF budget(i) > 0 THEN f = bal(i) / budget(i) ELSE f = 0
        IF f > 1 THEN f = 1
        full = INT(f * 20 + .5)
        PRINT USING "## \            \ ##,###.## ##,###.##  "; i; ename$(i); budget(i); bal(i);
        ' Colour: green = healthy, yellow = getting low, red = nearly empty
        IF f > .5 THEN COLOR 10 ELSE IF f > .2 THEN COLOR 14 ELSE COLOR 12
        PRINT STRING$(full, 219); STRING$(20 - full, 250);
        COLOR 7
        PRINT USING " ###%"; f * 100
        tb = tb + budget(i): tl = tl + bal(i)
    NEXT i
    PRINT STRING$(68, "-")
    PRINT USING "   TOTAL            ##,###.## ##,###.##"; tb; tl
RETURN

NoFile:
    fileOk = 0
    RESUME NEXT

Starter:
DATA 6
DATA "Rent", 1200, "Groceries", 450, "Transport", 160
DATA "Utilities", 210, "Fun", 120, "Savings", 300
