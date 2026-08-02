' ============================================================
' TITLE:    Reverse a String Recursively
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, strings, MID$, LEFT$, call stack
' SUMMARY:  Three ways to reverse text recursively, each showing a different shape of recursion in the call stack.
' ------------------------------------------------------------
' WHAT IT DOES
'   Reverses a string in three recursive styles:
'     A) "first letter goes last":   Rev(s) = Rev(rest) + first
'     B) "print on the way back":    nothing is returned at all; the
'        letters are printed AFTER the recursive call, so they come
'        out in reverse order as the stack unwinds
'     C) "split in half":            Rev(s) = Rev(right) + Rev(left)
'   All three give the same answer, but the call stacks look different.
'
' HOW TO USE
'   Type a word or sentence and press Enter.  Empty line quits.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK A.  Enter  HELLO.  Watch s get shorter:
'      HELLO, ELLO, LLO, LO, O, "".  The stack is 6 frames deep.
'   2. STEP OUT from the deepest frame and watch the result grow:
'      "", O, OL, OLL, OLLE, OLLEH.
'   3. Break on <<< BREAK B.  Notice the PRINT has not happened yet
'      when the stack is deepest - printing waits for the unwinding.
'   4. Break on <<< BREAK C.  The stack is only about 4 frames deep
'      even for long strings: splitting in half gives LOG depth.
'      Try a 30-letter sentence and compare max depth of A and C.
'
' CONCEPTS YOU WILL LEARN
'   * Work done BEFORE the recursive call happens on the way in;
'     work done AFTER it happens on the way out (reverse order)
'   * Linear depth vs. logarithmic depth recursion
'   * LEFT$, RIGHT$, MID$ string slicing
'
' THINGS TO TRY
'   * In PrintBackwards, move the PRINT above the recursive call.
'     What happens to the output?
'   * Make a version that reverses the order of WORDS, not letters.
' ============================================================
DECLARE FUNCTION RevA$ (s$)
DECLARE SUB PrintBackwards (s$)
DECLARE FUNCTION RevC$ (s$)

CLS
PRINT "RECURSIVE STRING REVERSAL"
PRINT
DO
    LINE INPUT "Text to reverse (Enter alone quits): "; t$
    IF t$ = "" THEN EXIT DO
    PRINT "A) first-goes-last : "; RevA$(t$)
    PRINT "B) print-on-return : ";
    PrintBackwards t$
    PRINT
    PRINT "C) split-in-half   : "; RevC$(t$)
    PRINT
LOOP
PRINT "Bye!"
END

' A) Take the first character off, reverse the rest, stick the
'    first character on the END.
FUNCTION RevA$ (s$)
    IF LEN(s$) <= 1 THEN                ' <<< BREAK A
        RevA$ = s$                      ' "" or one letter: already reversed
    ELSE
        RevA$ = RevA$(MID$(s$, 2)) + LEFT$(s$, 1)
    END IF
END FUNCTION

' B) Do not build anything.  Go deeper first, THEN print the first
'    letter.  The deepest frame prints first = the last letter.
SUB PrintBackwards (s$)
    IF LEN(s$) = 0 THEN EXIT SUB        ' <<< BREAK B
    PrintBackwards MID$(s$, 2)          ' go deeper first...
    PRINT LEFT$(s$, 1);                 ' ...then print on the way out
END SUB

' C) Split the string into two halves, reverse each half, and put
'    them back in swapped order.  "ABCD" -> Rev("CD") + Rev("AB").
FUNCTION RevC$ (s$)
    IF LEN(s$) <= 1 THEN                ' <<< BREAK C
        RevC$ = s$
    ELSE
        mid% = LEN(s$) \ 2
        RevC$ = RevC$(MID$(s$, mid% + 1)) + RevC$(LEFT$(s$, mid%))
    END IF
END FUNCTION
