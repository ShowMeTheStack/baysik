' ============================================================
' TITLE:    ON ERROR Detective
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     ON ERROR, RESUME, ERR, ERL, error handling, debugging, STOP, TRON
' SUMMARY:  Trigger eight classic runtime errors on purpose, catch each one with ON ERROR, and learn RESUME, RESUME NEXT and ERL.
' ------------------------------------------------------------
' WHAT IT DOES
'   Runtime errors (dividing by zero, a bad array index, a missing
'   file...) normally stop a program.  ON ERROR GOTO lets you catch
'   them: QBasic jumps to your handler, where ERR tells you which
'   error happened and ERL tells you on which numbered line.  Then:
'     RESUME          - try the same statement again (after a fix)
'     RESUME NEXT     - skip it and carry on with the next statement
'     RESUME label    - continue somewhere else
'   The program has a menu of "crash tests".  Each one deliberately
'   causes a different error, and the handler explains it.
'   Test 8 shows RESUME after FIXING the problem: it asks again for a
'   divisor until you type something that is not zero.
'
' HOW TO USE
'   Press 1-8 to run a crash test, Q to quit.
'
'   DEBUGGER TOUR
'   1. Put a breakpoint on <<< BREAK HANDLER.  Run any test.  When it
'      stops, the error has already happened - add WATCH expressions
'          ERR     ERL
'      to see the error number and line.
'   2. Comment out the ON ERROR GOTO line and run test 1 again.  Now
'      the debugger itself stops on the bad line and shows the error
'      - another way to find a bug fast.
'   3. Uncomment the STOP in test 5 to pause right before the crash
'      and inspect the array index with the Variables panel.
'   4. Type TRON in the immediate window (or add it as a line) and
'      run test 8: the trace shows the RESUME jumping back.
'
' CONCEPTS YOU WILL LEARN
'   * ON ERROR GOTO, ERR, ERL, RESUME / RESUME NEXT / RESUME label
'   * Common error codes: 2, 3, 5, 6, 9, 11, 13, 53, 62...
'   * Using line numbers so ERL can report where things went wrong
'   * Turning error handling off again with ON ERROR GOTO 0
'
' THINGS TO TRY
'   * Add a test for error 7 (out of memory) or 76 (path not found).
'   * Write the error messages to a log file in the handler.
' ============================================================
DECLARE FUNCTION ErrName$ (code AS INTEGER)

DIM arr(1 TO 5) AS INTEGER
retryMode = 0

ON ERROR GOTO Handler              ' from now on, errors go to Handler

DO
    PRINT
    PRINT "ON ERROR DETECTIVE - pick a crash test:"
    PRINT "  1 divide by zero          5 array index out of range"
    PRINT "  2 overflow                6 file not found"
    PRINT "  3 illegal function call   7 RETURN without GOSUB"
    PRINT "  4 bad DATA for READ       8 RESUME after fixing (division)"
    PRINT "  Q quit"
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    PRINT "> "; k$
    SELECT CASE k$
    CASE "1"
        a = 10: b = 0
1010    c = a / b
        PRINT "  (carried on after the error, c ="; c; ")"
    CASE "2"
        n% = 30000
1020    n% = n% * 2                 ' too big for an INTEGER (max 32767)
        PRINT "  (carried on, n% ="; n%; ")"
    CASE "3"
1030    r = SQR(-4)                 ' no real square root of -4
        PRINT "  (carried on)"
    CASE "4"
        ' READ expects a number but the DATA holds text.  QBasic reports
        ' this as error 2, "Syntax error" (the DATA item is not a number).
        RESTORE BadData
1040    READ price
        PRINT "  (carried on, price ="; price; ")"
        PRINT "  Safer: read text, then convert:  VAL("; CHR$(34); "12abc"; CHR$(34); ") ="; VAL("12abc")
    CASE "5"
        i = 7
        ' STOP                     ' <- uncomment to inspect i first
1050    arr(i) = 99                 ' arr only goes 1 TO 5
        PRINT "  (carried on)"
    CASE "6"
1060    OPEN "NOSUCH.DAT" FOR INPUT AS #1
        PRINT "  (carried on)"
    CASE "7"
1070    GOSUB NotReallyCalled       ' this one is fine...
        PRINT "  GOSUB/RETURN pair worked.  (A RETURN with no GOSUB"
        PRINT "   is error 3 - try jumping to NotReallyCalled with GOTO!)"
    CASE "8"
        retryMode = -1
        d = 0
        PRINT "  Computing 100 / d with d = 0 ..."
1080    q = 100 / d
        PRINT "  Success: 100 /"; d; "="; q
        retryMode = 0
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
ON ERROR GOTO 0                     ' error trapping OFF again
PRINT "Case closed. Bye!"
END

BadData:
DATA twelve dollars

NotReallyCalled:
    PRINT "  inside the GOSUB routine"
    RETURN

' ---------------- the error handler --------------------------
Handler:
    PRINT "  CAUGHT error"; ERR; "("; ErrName$(ERR); ") at line"; ERL   ' <<< BREAK HANDLER
    IF retryMode AND ERR = 11 THEN
        ' Fix the cause, then RESUME retries the SAME statement (1080).
        INPUT "  Enter a non-zero value for d"; d
        IF d = 0 THEN PRINT "  Still zero!"
        RESUME
    END IF
    IF ERR = 53 THEN CLOSE        ' tidy up after a failed OPEN
    RESUME NEXT                    ' skip the bad statement

FUNCTION ErrName$ (code AS INTEGER)
    SELECT CASE code
    CASE 2: ErrName$ = "Syntax error"
    CASE 3: ErrName$ = "RETURN without GOSUB"
    CASE 5: ErrName$ = "Illegal function call"
    CASE 6: ErrName$ = "Overflow"
    CASE 9: ErrName$ = "Subscript out of range"
    CASE 11: ErrName$ = "Division by zero"
    CASE 13: ErrName$ = "Type mismatch"
    CASE 53: ErrName$ = "File not found"
    CASE 62: ErrName$ = "Input past end of file"
    CASE ELSE: ErrName$ = "error number" + STR$(code)
    END SELECT
END FUNCTION
