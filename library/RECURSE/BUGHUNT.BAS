' ============================================================
' TITLE:    Bug Hunt: Fix Three Broken Routines
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     debugging, bugs, off-by-one, infinite recursion, scope, SHARED, exercise
' SUMMARY:  A deliberately buggy program with three classic mistakes - use breakpoints and watches to find and fix them.
' ------------------------------------------------------------
' WHAT IT DOES
'   This program is BROKEN ON PURPOSE.  It runs three small tests and
'   prints what each one SHOULD print next to what it actually gets:
'     Test 1  SumList    - adds up the numbers in an array
'     Test 2  CountDown  - a recursive countdown from 6 to 1
'     Test 3  AddScore   - keeps a running total of game scores
'   Each test has exactly ONE bug.  Your job: find it using the
'   debugger, fix it, and run again until all three say PASS.
'   No peeking at the spoilers at the very bottom of the file until
'   you have really tried!
'
' HOW TO USE
'   Run it.  Read the PASS/FAIL report.  Then go bug hunting.
'
'   DEBUGGER HINTS (one per bug)
'   Test 1: Put a breakpoint on the line marked <<< HINT 1 and WATCH
'           i  and  nums(i).  Count how many times it stops.  Is
'           every number visited?
'   Test 2: CountDown should stop at 1, but a SAFETY GUARD (the
'           calls counter) had to rescue it.  Break on <<< HINT 2 and
'           look at the CALL STACK.  What is n in each frame?  Does
'           n ever equal the value the base case is waiting for?
'           (Without the guard this would recurse until the stack
'           overflows.  Guards like this are a good habit while
'           debugging recursion!)
'   Test 3: Break on <<< HINT 3.  Look at  total  in the Variables
'           panel, then look at the main program's total.  Are they
'           the same variable?  Use a WATCH on  total  and step into
'           AddScore - watch what happens to it when you go in and
'           come back out.
'
' CONCEPTS YOU WILL LEARN
'   * Off-by-one errors in loop bounds
'   * Base cases that can be skipped over (and guarding against it)
'   * Variable scope: local vs SHARED
'   * Writing self-checking tests (expected vs actual)
'
' THINGS TO TRY
'   * After fixing, add a fourth test of your own with a bug for a
'     friend to find.
' ============================================================
DECLARE FUNCTION SumList% (count AS INTEGER)
DECLARE SUB CountDown (n AS INTEGER)
DECLARE SUB AddScore (points AS INTEGER)
DECLARE SUB Report (testName$, expected$, actual$)

DIM SHARED nums(1 TO 5) AS INTEGER
DIM SHARED shout$          ' text CountDown builds up
DIM SHARED calls AS INTEGER
DIM total AS INTEGER       ' running score total (main program)

CLS
PRINT "BUG HUNT - three tests, three bugs.  Make them all PASS!"
PRINT

' ---------------- Test 1: sum of an array ----------------------
FOR i% = 1 TO 5: READ nums(i%): NEXT i%
DATA 10, 20, 30, 40, 50
Report "1 SumList", "150", LTRIM$(STR$(SumList%(5)))

' ---------------- Test 2: recursive countdown -----------------
shout$ = "": calls = 0
CountDown 6
Report "2 CountDown", "6 5 4 3 2 1 LIFTOFF", RTRIM$(shout$)

' ---------------- Test 3: running score total -----------------
total = 0
AddScore 10
AddScore 25
AddScore 7
Report "3 AddScore", "42", LTRIM$(STR$(total))

PRINT
PRINT "Hints are in the header.  Spoilers are at the bottom of the file."
END

SUB Report (testName$, expected$, actual$)
    IF expected$ = actual$ THEN r$ = "PASS" ELSE r$ = "FAIL"
    PRINT r$; "  Test "; testName$
    PRINT "        expected: "; expected$
    PRINT "        actual:   "; actual$
END SUB

' Add up nums(1) .. nums(count).
FUNCTION SumList% (count AS INTEGER)
    DIM s AS INTEGER, i AS INTEGER
    FOR i = 1 TO count - 1
        s = s + nums(i)              ' <<< HINT 1
    NEXT i
    SumList% = s
END FUNCTION

' Count down from n to 1, then say LIFTOFF.
SUB CountDown (n AS INTEGER)
    calls = calls + 1
    IF calls > 12 THEN                ' safety guard against runaway recursion
        shout$ = shout$ + "...(guard stopped runaway recursion!)"
        EXIT SUB
    END IF
    IF n = 1 THEN                     ' <<< HINT 2
        shout$ = shout$ + "1 LIFTOFF"
        EXIT SUB
    END IF
    shout$ = shout$ + LTRIM$(STR$(n)) + " "
    CountDown n - 2
END SUB

' Add some points to the total score.
SUB AddScore (points AS INTEGER)
    total = total + points            ' <<< HINT 3
END SUB

' ==============================================================
'
'
'
'                 S P O I L E R S   B E L O W
'
'
'
' ==============================================================
' BUG 1 (off-by-one):  FOR i = 1 TO count - 1  stops one item early,
'   so the last number (50) is never added and the sum is 100.
'   FIX:  FOR i = 1 TO count
'
' BUG 2 (base case skipped):  CountDown n - 2  goes 6, 4, 2, 0, -2,
'   -4 ... it jumps right over n = 1, so the base case never fires
'   and the recursion would go on until the stack overflows.  Only
'   the guard saves it.  FIX:  CountDown n - 1
'   LESSON: a base case written as "n = 1" is fragile; "n <= 1" is
'   safer because it also catches values that jump past it.
'
' BUG 3 (scope):  total  in the main program is NOT shared, so inside
'   AddScore  total  is a brand-new LOCAL variable that starts at 0
'   every call and vanishes when the SUB ends.  The main total stays
'   0.  The debugger shows two different "total"s in two frames.
'   FIX:  change  DIM total AS INTEGER  to  DIM SHARED total AS INTEGER
'   (or pass it in:  SUB AddScore (tot AS INTEGER, points AS INTEGER) )
' ==============================================================
