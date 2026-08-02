' ============================================================
' TITLE:    Fibonacci: Naive vs Memoized
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, fibonacci, memoization, call counter, performance
' SUMMARY:  Counts every single call to show why naive recursive Fibonacci explodes - and how a memo table tames it.
' ------------------------------------------------------------
' WHAT IT DOES
'   Fibonacci numbers: 0, 1, 1, 2, 3, 5, 8, 13 ...  each one is the
'   sum of the two before it.  The obvious recursive definition
'       Fib(n) = Fib(n-1) + Fib(n-2)
'   is beautiful but SLOW, because it recomputes the same values
'   again and again.  This program runs two versions side by side
'   and counts how many times each function gets called.
'
' HOW TO USE
'   Just run it.  A table shows N, Fib(N), the number of calls made by
'   the naive version and by the memoized version, and the time taken.
'
'   DEBUGGER TOUR
'   1. Set N = 5 (change CONST MAXN below to 5) for a small tree.
'   2. Put a CONDITIONAL breakpoint on the line marked <<< BREAK
'      in FibNaive with the condition   n = 2
'      Run.  How many times does it stop?  Each stop is a repeated,
'      wasted computation of Fib(2).
'   3. While paused, open the CALL STACK.  The chain of frames shows
'      the exact path through the "call tree" that got you here,
'      e.g. FibNaive(5) -> FibNaive(4) -> FibNaive(3) -> FibNaive(2).
'   4. WATCH naiveCalls& and memoCalls& as you continue.
'   5. In FibMemo, break on the line marked <<< MEMO HIT.  Each stop
'      is a time the memo table SAVED a whole subtree of work.
'
' CONCEPTS YOU WILL LEARN
'   * Tree recursion (a function that calls itself twice)
'   * Exponential growth: naive calls roughly multiply by 1.6 per N
'   * Memoization: remember answers in an array, look them up first
'   * Using a SHARED counter to measure an algorithm
'
' THINGS TO TRY
'   * Raise MAXN to 25.  The naive column gets very slow!
'   * Predict: naive calls for N = 20?  (It is 2*Fib(21) - 1.)
'   * Write a third version with a plain loop and two variables.
' ============================================================
DECLARE FUNCTION FibNaive& (n AS INTEGER)
DECLARE FUNCTION FibMemo& (n AS INTEGER)

CONST MAXN = 20

DIM SHARED naiveCalls AS LONG    ' how many times FibNaive ran
DIM SHARED memoCalls AS LONG     ' how many times FibMemo ran
DIM SHARED memo(0 TO 40) AS LONG ' memo(k) = Fib(k), or -1 = unknown

CLS
PRINT "  N      Fib(N)   naive calls   memo calls"
PRINT "---  ----------   -----------   ----------"

FOR n% = 0 TO MAXN
    ' --- naive: start the counter at zero, then compute ---
    naiveCalls = 0
    a& = FibNaive&(n%)

    ' --- memoized: wipe the memo table first so the comparison is fair
    FOR k% = 0 TO 40: memo(k%) = -1: NEXT k%
    memoCalls = 0
    b& = FibMemo&(n%)

    PRINT USING "###  ##########   ###########   ##########"; n%; a&; naiveCalls; memoCalls
    IF a& <> b& THEN PRINT "  ** the two versions disagree! **"
NEXT n%

PRINT
PRINT "Naive calls grow like the Fibonacci numbers themselves (fast!)."
PRINT "Memo calls grow by just 2 per step: each value is computed once."
END

' ------------------------------------------------------------
' FibNaive - straight from the math definition.
' ------------------------------------------------------------
FUNCTION FibNaive& (n AS INTEGER)
    naiveCalls = naiveCalls + 1
    IF n < 2 THEN                     ' <<< BREAK (try condition n = 2)
        FibNaive& = n                 ' base cases: Fib(0)=0, Fib(1)=1
    ELSE
        ' Two recursive calls: this is what makes a "tree".
        ' The left call finishes COMPLETELY before the right one starts
        ' - step through and watch the call stack grow and shrink.
        FibNaive& = FibNaive&(n - 1) + FibNaive&(n - 2)
    END IF
END FUNCTION

' ------------------------------------------------------------
' FibMemo - same idea, but check the notebook first.
' ------------------------------------------------------------
FUNCTION FibMemo& (n AS INTEGER)
    memoCalls = memoCalls + 1
    IF memo(n) >= 0 THEN
        FibMemo& = memo(n)            ' <<< MEMO HIT: answer already known
        EXIT FUNCTION
    END IF
    IF n < 2 THEN
        r& = n
    ELSE
        r& = FibMemo&(n - 1) + FibMemo&(n - 2)
    END IF
    memo(n) = r&                      ' write it in the notebook
    FibMemo& = r&
END FUNCTION
