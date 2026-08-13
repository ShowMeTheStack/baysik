' ============================================================
' TITLE:    Tracing with TRON and TROFF
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     tron, troff, debugging, line numbers, gosub, trace
' SUMMARY:  Switch on BASIC's built-in line tracer to watch the order in which lines run, and use it to find a bug.
' ------------------------------------------------------------
' WHAT IT DOES
'   TRON ("trace on") makes BASIC print the number of every line it
'   starts, in square brackets, like [120][130][200].  TROFF switches
'   it off.  It is the oldest debugging tool there is!
'   Part 1 traces a small loop and a GOSUB so you can see the jumps.
'   Part 2 traces a program with a bug: it should find the biggest
'   number in a list but gets the wrong answer.  Read the trace to
'   see which lines run (and which never do!) - then check the hint.
'
' HOW TO USE
'   Press a key between parts.  Read the numbers in brackets: each is
'   a line that just started running.
'
' CONCEPTS YOU WILL LEARN
'   * TRON / TROFF
'   * Following program flow: loops jump BACK, GOSUB jumps away and
'     RETURN comes back
'   * Debugging by observation instead of guessing
'
' THINGS TO TRY
'   * Fix the bug in part 2 (line 540) as the hint says and trace it again
'   * Put TRON just before a tricky part of one of your own programs
'   * In the IDE, compare TRON with the step-by-step debugger
' ============================================================

10 CLS
20 PRINT "PART 1 - a loop with a GOSUB, traced"
30 PRINT "Lines 110-150 run three times; 300-310 is the subroutine."
40 PRINT
100 TRON
110 FOR I = 1 TO 3
120   PRINT "I ="; I;
130   IF I = 2 THEN GOSUB 300
140   PRINT
150 NEXT I
160 TROFF
170 PRINT
180 PRINT "Notice [300][310] only appear once - when I = 2."
190 GOSUB 900
200 GOTO 410
300 PRINT " (in the subroutine)";
310 RETURN
400 ' ---- PART 2: a buggy "find the biggest" program -----------------
410 CLS
420 PRINT "PART 2 - this should print the biggest number (42)."
430 PRINT "Data: 7, 42, 19, 3"
440 PRINT
450 TRON
500 RESTORE 800
510 BIG = 0
520 FOR K = 1 TO 4
530   READ N
540   IF N > BIG THEN 550       ' skip the update when...?
545   BIG = N                    ' remember a new biggest
550 NEXT K
560 TROFF
570 PRINT
580 PRINT "Biggest ="; BIG; " <-- wrong!"
590 PRINT
600 PRINT "Clue: search the trace for [545].  It is never there!"
610 PRINT "So line 540 ALWAYS skips the update.  Its test is backwards;"
620 PRINT "it should skip only when N is NOT bigger:"
630 PRINT "      540 IF N <= BIG THEN 550"
640 GOSUB 900
650 END
800 DATA 7, 42, 19, 3
900 PRINT : PRINT "(press a key)"
910 K$ = INKEY$: IF K$ = "" THEN 910
920 RETURN
