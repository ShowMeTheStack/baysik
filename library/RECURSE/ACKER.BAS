' ============================================================
' TITLE:    The Ackermann Function
' CATEGORY: Recursion & Debugging
' LEVEL:    Advanced
' TAGS:     recursion, ackermann, nested recursion, growth, call counter
' SUMMARY:  A tiny function whose recursion calls itself INSIDE its own argument - and grows faster than any loop can describe.
' ------------------------------------------------------------
' WHAT IT DOES
'   The Ackermann function is famous in computer science:
'       A(0, n) = n + 1
'       A(m, 0) = A(m - 1, 1)
'       A(m, n) = A(m - 1, A(m, n - 1))      <- nested recursion!
'   The third rule calls A just to work out the ARGUMENT for another
'   call of A.  The result grows incredibly fast as m increases:
'       A(1,n) = n+2    A(2,n) = 2n+3    A(3,n) = 2^(n+3) - 3
'       A(4,2) has 19,729 digits.
'   The program prints a small table with the value, the number of
'   calls made, and the deepest the call stack reached.
'
' HOW TO USE
'   Just run it.  It stays with small values (m <= 3, n <= 4) because
'   anything bigger takes millions of calls.
'
'   DEBUGGER TOUR
'   1. Edit the main loop to compute only A(2, 1).  Break on
'      <<< BREAK.  Keep pressing Continue and look at m and n.
'      It takes 14 calls - write the (m, n) pairs down!
'   2. When paused on a rule-3 call, STEP INTO: the FIRST call made
'      is the inner one, A(m, n-1).  The outer call cannot even
'      start until the inner call has finished - just like
'      evaluating f(g(x)) in maths.
'   3. Watch  depth  and  maxDepth .  Open the CALL STACK at the
'      deepest point - many frames with m = 0 pile up on top of a
'      few with bigger m.
'
' CONCEPTS YOU WILL LEARN
'   * Nested recursion (a recursive call as an argument)
'   * Functions that are computable but not "primitive recursive"
'     (cannot be written with simple FOR loops of known length)
'   * Measuring calls and depth with SHARED counters
'
' THINGS TO TRY
'   * Check the formulas above against the table.
'   * Add a memo table for small m and n.  How much does it help?
'   * Try A(4, 0) and A(4, 1) if you are patient (A(4,1) = 65533).
' ============================================================
DECLARE FUNCTION Ack& (m AS LONG, n AS LONG)

DIM SHARED calls AS LONG, depth AS LONG, maxDepth AS LONG

CLS
PRINT "THE ACKERMANN FUNCTION A(m, n)"
PRINT
PRINT "  m  n      A(m,n)        calls   max depth"
PRINT "  -  -   ---------   ----------   ---------"
FOR m& = 0 TO 3
    FOR n& = 0 TO 4
        IF m& < 3 OR n& <= 3 THEN
            calls = 0: depth = 0: maxDepth = 0
            v& = Ack&(m&, n&)
            PRINT USING "  #  #   #########   ##########   #########"; m&; n&; v&; calls; maxDepth
        END IF
    NEXT n&
NEXT m&
PRINT
PRINT "Notice how the call count explodes when m goes from 2 to 3."
END

FUNCTION Ack& (m AS LONG, n AS LONG)
    calls = calls + 1
    depth = depth + 1
    IF depth > maxDepth THEN maxDepth = depth

    IF m = 0 THEN                       ' <<< BREAK (watch m and n)
        Ack& = n + 1                    ' rule 1
    ELSEIF n = 0 THEN
        Ack& = Ack&(m - 1, 1)           ' rule 2
    ELSE
        ' rule 3: the INNER call runs first and its answer becomes
        ' the second argument of the OUTER call.
        Ack& = Ack&(m - 1, Ack&(m, n - 1))
    END IF

    depth = depth - 1
END FUNCTION
