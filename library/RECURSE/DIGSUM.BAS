' ============================================================
' TITLE:    Sum of Digits & Digital Root
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, digits, MOD, integer division, digital root
' SUMMARY:  Peel digits off a number one recursive call at a time, then repeat until a single digit - the digital root - remains.
' ------------------------------------------------------------
' WHAT IT DOES
'   SumDigits(4728) = 8 + SumDigits(472) = 8 + 2 + SumDigits(47) ...
'   = 4 + 7 + 2 + 8 = 21.  The last digit of any number is n MOD 10
'   and "the rest" is n \ 10.  Keep adding until you run out.
'   Then DigitalRoot keeps summing the digits of the answer until
'   only one digit is left: 4728 -> 21 -> 3.
'   Fun fact: the digital root tells you n MOD 9 (with 9 for 0),
'   which is the old "casting out nines" check for arithmetic.
'
' HOW TO USE
'   Type a whole number (up to about 2 billion).  0 quits.
'
'   DEBUGGER TOUR
'   1. Put a breakpoint on <<< BREAK in SumDigits.  Enter 4728.
'   2. Each stop: n loses its last digit.  Watch the expressions
'          n MOD 10       and       n \ 10
'      (add them as WATCH expressions - they update every step).
'   3. The CALL STACK now has a mix of functions: DigitalRoot at the
'      bottom, SumDigits frames on top.  Two different recursive
'      functions are nested inside each other!
'   4. TRON (trace on) is also handy here: type TRON before RUN or
'      add it as the first line to see each line number executed.
'
' CONCEPTS YOU WILL LEARN
'   * MOD 10 gives the last digit, \ 10 removes it
'   * Recursion that shrinks a number instead of counting down by 1
'   * A recursive function that calls a different recursive function
'
' THINGS TO TRY
'   * Write CountDigits(n) the same way (1 + CountDigits(n \ 10)).
'   * Write ReverseNumber: 4728 -> 8274.
'   * Change 10 to 2 everywhere: SumDigits now counts the 1-bits!
' ============================================================
DECLARE FUNCTION SumDigits& (n AS LONG)
DECLARE FUNCTION DigitalRoot& (n AS LONG)

CLS
PRINT "SUM OF DIGITS and DIGITAL ROOT"
PRINT
DO
    INPUT "Enter a positive whole number (0 quits)"; num&
    IF num& <= 0 THEN EXIT DO
    PRINT "Sum of digits of"; num&; "is"; SumDigits&(num&)
    PRINT "Digital root chain:"
    r& = DigitalRoot&(num&)
    PRINT "Digital root ="; r&; "   check: 1 + (n-1) MOD 9 ="; 1 + (num& - 1) MOD 9
    PRINT
LOOP
PRINT "Bye!"
END

' ------------------------------------------------------------
' SumDigits:  last digit + sum of the remaining digits
' ------------------------------------------------------------
FUNCTION SumDigits& (n AS LONG)
    IF n < 10 THEN                      ' <<< BREAK
        SumDigits& = n                  ' base case: a single digit
    ELSE
        SumDigits& = (n MOD 10) + SumDigits&(n \ 10)
    END IF
END FUNCTION

' ------------------------------------------------------------
' DigitalRoot: keep summing digits until one digit is left.
' ------------------------------------------------------------
FUNCTION DigitalRoot& (n AS LONG)
    PRINT "   "; n
    IF n < 10 THEN
        DigitalRoot& = n
    ELSE
        DigitalRoot& = DigitalRoot&(SumDigits&(n))
    END IF
END FUNCTION
