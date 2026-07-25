' ============================================================
' TITLE:    Palindrome Checker
' CATEGORY: Strings & Text Processing
' LEVEL:    Beginner
' TAGS:     strings, palindromes, MID$, UCASE$, loops
' SUMMARY:  Tells you whether a word or sentence reads the same forwards and backwards.
' ------------------------------------------------------------
' WHAT IT DOES
'   A palindrome is text that reads the same in both directions,
'   like "RACECAR" or "A man, a plan, a canal: Panama!".  Real
'   sentence palindromes only work if we ignore spaces, commas and
'   capital letters, so this program first "cleans" the text down
'   to just letters and digits, then compares it from both ends
'   towards the middle.  It starts with a few famous examples and
'   then lets you test your own.
'
' HOW TO USE
'   Type any word or sentence and press Enter.
'   Press Enter on an empty line (or type Q) to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Walking through a string one character at a time with MID$
'   * UCASE$ to ignore the difference between "a" and "A"
'   * The "two pointers" technique: one from the left, one from the right
'   * Writing reusable FUNCTIONs that return strings and numbers
'
' THINGS TO TRY
'   * Make it also report the LONGEST palindrome hidden inside the text
'   * Check whole-word palindromes: "Fall leaves after leaves fall"
'   * Add more famous palindromes to the DATA lines
' ============================================================

DECLARE FUNCTION CleanText$ (s$)
DECLARE FUNCTION IsPalindrome% (s$)

CLS
COLOR 14
PRINT "PALINDROME CHECKER"
COLOR 7
PRINT "A palindrome reads the same forwards and backwards."
PRINT "(We ignore spaces, punctuation and capital letters.)"
PRINT

' ---- Part 1: run through some built-in examples -------------
PRINT "Some examples:"
RESTORE Examples
DO
    READ sample$
    IF sample$ = "*" THEN EXIT DO      ' "*" marks the end of the list
    PRINT "  "; LEFT$(sample$ + SPACE$(36), 36);
    IF IsPalindrome%(sample$) THEN
        COLOR 10: PRINT "YES"
    ELSE
        COLOR 12: PRINT "no"
    END IF
    COLOR 7
LOOP
PRINT

' ---- Part 2: let the user try their own ---------------------
DO
    LINE INPUT "Your text (Enter = quit): "; t$
    IF t$ = "" OR UCASE$(t$) = "Q" THEN EXIT DO
    c$ = CleanText$(t$)
    IF c$ = "" THEN
        PRINT "  There are no letters or digits in that!"
    ELSE
        PRINT "  Cleaned up: "; c$
        IF IsPalindrome%(t$) THEN
            COLOR 10: PRINT "  Yes - that is a palindrome!"
        ELSE
            COLOR 12: PRINT "  No - not a palindrome."
        END IF
        COLOR 7
    END IF
    PRINT
LOOP
PRINT "Goodbye!"
END

Examples:
DATA "racecar", "hello", "Was it a car or a cat I saw?"
DATA "A man, a plan, a canal: Panama!", "Never odd or even"
DATA "BASIC", "12321", "Step on no pets", "*"

' ------------------------------------------------------------
' CleanText$: keep only A-Z and 0-9, in upper case.
' We look at each character in turn.  UCASE$ turns "a" into "A",
' so after that we only need to test one range of letters.
' ------------------------------------------------------------
FUNCTION CleanText$ (s$)
    out$ = ""
    FOR i = 1 TO LEN(s$)
        ch$ = UCASE$(MID$(s$, i, 1))          ' i-th character
        IF (ch$ >= "A" AND ch$ <= "Z") OR (ch$ >= "0" AND ch$ <= "9") THEN
            out$ = out$ + ch$                  ' keep it
        END IF
    NEXT i
    CleanText$ = out$
END FUNCTION

' ------------------------------------------------------------
' IsPalindrome%: returns -1 (true) or 0 (false).
' Two pointers: L starts at the first letter, R at the last.
' If they ever point at different letters, it is not a
' palindrome.  Otherwise move both inward until they meet.
' This only needs LEN/2 comparisons - no reversed copy needed.
' ------------------------------------------------------------
FUNCTION IsPalindrome% (s$)
    c$ = CleanText$(s$)
    L = 1
    R = LEN(c$)
    IsPalindrome% = -1                 ' assume yes until proven wrong
    DO WHILE L < R
        IF MID$(c$, L, 1) <> MID$(c$, R, 1) THEN
            IsPalindrome% = 0
            EXIT FUNCTION
        END IF
        L = L + 1
        R = R - 1
    LOOP
END FUNCTION
