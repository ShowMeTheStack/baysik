' ============================================================
' TITLE:    Palindrome Checker
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, palindromes, strings, UCASE$, early exit
' SUMMARY:  Checks whether a phrase reads the same backwards by comparing the outer letters and recursing on the middle.
' ------------------------------------------------------------
' WHAT IT DOES
'   A palindrome reads the same forwards and backwards: RACECAR,
'   "Never odd or even", "A man, a plan, a canal: Panama".
'   First the phrase is cleaned (only letters/digits kept, all
'   uppercase).  Then IsPal looks at the first and last characters:
'     - different?  Not a palindrome, stop right away.
'     - the same?   Throw them away and check the middle.
'   A string of 0 or 1 characters is always a palindrome.
'   Instead of chopping the string, we pass two indexes lo and hi
'   that move toward each other - that avoids making new strings.
'
' HOW TO USE
'   Type a phrase.  Empty line runs a few built-in examples and quits.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK in IsPal.  Enter  RACECAR.
'   2. Add WATCH expressions:   MID$(s$, lo, 1)    MID$(s$, hi, 1)
'      They show the two letters being compared at every level.
'   3. Watch lo go up and hi go down in each new stack frame.
'   4. Now try  RACECAT.  The very first comparison fails - the call
'      stack never gets deeper than 1.  Early exit in action.
'   5. Try a CONDITIONAL breakpoint:  lo >= hi   - it stops only at
'      the bottom of a successful check.
'
' CONCEPTS YOU WILL LEARN
'   * Recursing with index parameters instead of new strings
'   * Cleaning input with ASC/CHR$/UCASE$
'   * Short-circuit: stop recursing as soon as the answer is known
'
' THINGS TO TRY
'   * Count how many calls each phrase needed.
'   * Make a version that finds the longest palindrome inside a
'     sentence.
' ============================================================
DECLARE FUNCTION IsPal% (s$, lo AS INTEGER, hi AS INTEGER)
DECLARE FUNCTION Clean$ (s$)
DECLARE SUB Test (phrase$)

CLS
PRINT "RECURSIVE PALINDROME CHECKER"
PRINT
DO
    LINE INPUT "Phrase (Enter alone = examples + quit): "; p$
    IF p$ = "" THEN EXIT DO
    Test p$
LOOP

PRINT
PRINT "Some examples:"
Test "Racecar"
Test "Never odd or even"
Test "A man, a plan, a canal: Panama!"
Test "Recursion"
Test "Was it a car or a cat I saw?"
END

SUB Test (phrase$)
    c$ = Clean$(phrase$)
    IF IsPal%(c$, 1, LEN(c$)) THEN
        PRINT "  YES  "; phrase$; "   ("; c$; ")"
    ELSE
        PRINT "  no   "; phrase$; "   ("; c$; ")"
    END IF
END SUB

' Keep only A-Z and 0-9, converted to upper case.
FUNCTION Clean$ (s$)
    DIM out$, i AS INTEGER, ch$
    out$ = ""
    FOR i = 1 TO LEN(s$)
        ch$ = UCASE$(MID$(s$, i, 1))
        IF (ch$ >= "A" AND ch$ <= "Z") OR (ch$ >= "0" AND ch$ <= "9") THEN
            out$ = out$ + ch$
        END IF
    NEXT i
    Clean$ = out$
END FUNCTION

' Is the part of s$ from position lo to hi a palindrome?
FUNCTION IsPal% (s$, lo AS INTEGER, hi AS INTEGER)
    IF lo >= hi THEN                    ' <<< BREAK
        IsPal% = -1                     ' 0 or 1 chars left: TRUE (-1)
    ELSEIF MID$(s$, lo, 1) <> MID$(s$, hi, 1) THEN
        IsPal% = 0                      ' mismatch: FALSE, stop now
    ELSE
        IsPal% = IsPal%(s$, lo + 1, hi - 1)   ' outer pair OK: check middle
    END IF
END FUNCTION
