' ============================================================
' TITLE:    Error Trapping Lab (ERR, ERL, RESUME)
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     on error, err, erl, resume, line numbers, debugging
' SUMMARY:  Five experiments that cause real runtime errors and recover with RESUME, RESUME NEXT and RESUME line.
' ------------------------------------------------------------
' WHAT IT DOES
'   Without error trapping, a runtime error (divide by zero, file not
'   found ...) stops your program.  ON ERROR GOTO line installs an
'   error handler instead.  Inside the handler:
'     ERR  = the error number (11 = Division by zero, 53 = File not found)
'     ERL  = the LINE NUMBER where the error happened
'   and you leave with one of:
'     RESUME        - try the failing statement again
'     RESUME NEXT   - skip it, carry on with the next statement
'     RESUME 500    - jump to a specific line
'   This program is written GW-BASIC style with line numbers so that
'   ERL has something to report.
'
' HOW TO USE
'   Press a key after each experiment.  Esc quits early.
'
' CONCEPTS YOU WILL LEARN
'   * ON ERROR GOTO, ERR, ERL, RESUME / RESUME NEXT / RESUME n
'   * ON ERROR GOTO 0 to switch trapping off again
'   * Using a "mode" variable so one handler can serve many experiments
'
' THINGS TO TRY
'   * Add an experiment for error 9 (Subscript out of range)
'   * Print a friendly message for each ERR value with SELECT CASE
'   * Remove ON ERROR and watch the program stop with an error
' ============================================================

10 DEFINT A-Z
20 CLS
30 PRINT "ERROR TRAPPING LAB": PRINT STRING$(40, "=")
40 ON ERROR GOTO 1000           ' from now on errors jump to line 1000
50 '
100 ' ---- Experiment 1: RESUME NEXT skips the bad statement --------
110 PRINT : PRINT "1) Divide by zero, then RESUME NEXT"
120 XM = 1: A = 10: B = 0
130 C = A / B                   ' boom: error 11 on line 130
140 PRINT "   ...and we carried on to line 140.  C ="; C
150 GOSUB 900
200 ' ---- Experiment 2: RESUME retries after fixing the cause --------
210 PRINT : PRINT "2) Divide by zero, fix B in the handler, then RESUME"
220 XM = 2: A = 10: B = 0
230 C = A / B                   ' the handler sets B = 5 and retries
240 PRINT "   Retried successfully: 10 /"; B; "="; C
250 GOSUB 900
300 ' ---- Experiment 3: RESUME line jumps somewhere else ---------
310 PRINT : PRINT "3) Open a missing file, RESUME 350"
320 XM = 3
330 OPEN "NOSUCH.DAT" FOR INPUT AS #1
340 PRINT "   (this line is never reached)"
350 PRINT "   Arrived at line 350 - the 'file missing' path."
360 GOSUB 900
400 ' ---- Experiment 4: a whole list of different errors ---------
410 PRINT : PRINT "4) A list of errors, each skipped with RESUME NEXT"
420 XM = 1
430 X = SQR(-1)                 ' 5  Illegal function call
440 X = 32767: X = X + 1        ' 6  Overflow (X is an INTEGER)
450 DIM T(5): T(9) = 1          ' 9  Subscript out of range
460 S$ = MID$("ABC", 0, 1)      ' 5  again
470 GOSUB 900
500 ' ---- Experiment 5: ERROR n raises an error on purpose ---------
510 PRINT : PRINT "5) ERROR 53 raised deliberately with the ERROR statement"
520 XM = 1
530 ERROR 53
540 GOSUB 900
600 ' ---- finished --------------------------------------------------
610 ON ERROR GOTO 0             ' switch trapping off
620 PRINT : PRINT "All experiments done.  Errors caught:"; NERR
630 END
900 ' ---- subroutine: wait for a key -----------------------------------
910 PRINT "   (press a key)";
920 K$ = INKEY$: IF K$ = "" THEN 920
930 IF K$ = CHR$(27) THEN PRINT : PRINT "Quit.": END
940 PRINT : RETURN
1000 ' ==== THE ERROR HANDLER =========================================
1010 NERR = NERR + 1
1020 PRINT "   >> Trapped error"; ERR; "at line"; ERL;
1030 IF ERR = 11 THEN PRINT "(Division by zero)"
1040 IF ERR = 53 THEN PRINT "(File not found)"
1050 IF ERR = 5 THEN PRINT "(Illegal function call)"
1060 IF ERR = 6 THEN PRINT "(Overflow)"
1070 IF ERR = 9 THEN PRINT "(Subscript out of range)"
1080 IF XM = 1 THEN RESUME NEXT
1090 IF XM = 2 THEN B = 5: PRINT "   >> Setting B = 5 and retrying": RESUME
1100 IF XM = 3 THEN RESUME 350
1110 RESUME NEXT
