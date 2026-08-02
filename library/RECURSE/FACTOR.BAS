' ============================================================
' TITLE:    Factorial in the Debugger
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     recursion, factorial, call stack, breakpoints, debugger
' SUMMARY:  The classic first recursive function, with a guided tour of the call stack as it winds up and unwinds.
' ------------------------------------------------------------
' WHAT IT DOES
'   Computes N! (N factorial = 1 * 2 * 3 * ... * N) twice: once with
'   a plain FOR loop and once with a recursive FUNCTION that calls
'   itself.  Each recursive call prints an indented "enter" line and
'   an indented "return" line so you can SEE the calls nest and then
'   come back out, even without the debugger.
'
' HOW TO USE
'   Type a number from 0 to 12 and press Enter (0 or blank quits).
'
'   DEBUGGER TOUR (do this at least once!)
'   1. Click in the gutter to put a BREAKPOINT on the line marked
'      <<< BREAK HERE inside FUNCTION Fact.
'   2. Run and type 5.  The program pauses with n = 5.
'   3. Open the CALL STACK panel.  Press Continue (or Step Into)
'      a few times.  Each time a NEW frame appears: Fact(5), Fact(4),
'      Fact(3) ...  Click on each frame: every one has its OWN
'      private copy of n and result.  That is the secret of recursion.
'   4. When n reaches 1 the stack is at its deepest (5 Fact frames).
'      Remove the breakpoint and use STEP OUT repeatedly: watch each
'      frame return its value to the one below it.
'   5. Add a WATCH expression:  depth   (a SHARED counter).  It goes
'      up as you go in and down as you come back out.
'
' CONCEPTS YOU WILL LEARN
'   * A recursive function = a base case + a call to itself on a
'     smaller problem
'   * Every call gets its own stack frame with its own locals
'   * "Winding" (calls going in) vs "unwinding" (returns coming out)
'
' THINGS TO TRY
'   * Change the base case to  IF n = 0  - does it still work? Why?
'   * Remove the base case entirely (save first!).  What error do you
'     get, and what does the call stack look like when it happens?
'   * Try 13: an INTEGER overflows, so we use LONG.  Try 13 with
'     LONG, then change result& to result# (DOUBLE) for bigger N.
' ============================================================
DECLARE FUNCTION Fact& (n AS INTEGER)
DECLARE FUNCTION FactLoop& (n AS INTEGER)

' depth is SHARED so every call of Fact can see and change it.
' It tells us how many Fact frames are on the call stack right now.
DIM SHARED depth AS INTEGER

CLS
PRINT "FACTORIAL - recursion vs. a loop"
PRINT "================================="
PRINT

DO
    INPUT "Enter N (1 to 12, 0 to quit)"; n%
    IF n% <= 0 THEN EXIT DO
    IF n% > 12 THEN
        ' 13! = 6,227,020,800 which is bigger than a LONG can hold.
        PRINT "Please keep N at 12 or less (13! overflows a LONG)."
    ELSE
        PRINT
        PRINT "Loop version:      "; n%; "! ="; FactLoop&(n%)
        PRINT
        PRINT "Recursive version, call by call:"
        depth = 0
        answer& = Fact&(n%)
        PRINT "Recursive answer:  "; n%; "! ="; answer&
        PRINT
    END IF
LOOP
PRINT "Bye!"
END

' ------------------------------------------------------------
' Fact - the recursive version.
'   n! = n * (n-1)!     and the BASE CASE is 1! = 1 (and 0! = 1)
' ------------------------------------------------------------
FUNCTION Fact& (n AS INTEGER)
    DIM result AS LONG          ' a LOCAL: each call has its own one
    depth = depth + 1           ' one more frame on the stack

    ' Print SPACE$ so deeper calls are indented further to the right.
    PRINT SPACE$(depth * 2); "enter Fact("; LTRIM$(STR$(n)); ")"

    IF n <= 1 THEN              ' <<< BREAK HERE (look at n, depth)
        ' BASE CASE: we know the answer without recursing.
        ' Without this the function would call itself forever.
        result = 1
    ELSE
        ' RECURSIVE CASE: trust that Fact(n-1) works, then do one
        ' more multiplication.  This call PAUSES the current frame
        ' until the inner call comes back with its answer.
        result = n * Fact&(n - 1)
    END IF

    PRINT SPACE$(depth * 2); "return"; result; "from Fact("; LTRIM$(STR$(n)); ")"
    depth = depth - 1           ' this frame is about to disappear
    Fact& = result
END FUNCTION

' ------------------------------------------------------------
' FactLoop - the same answer with no recursion at all.
' Put a breakpoint here too and compare: the call stack only ever
' has ONE FactLoop frame; the loop variable i does all the work.
' ------------------------------------------------------------
FUNCTION FactLoop& (n AS INTEGER)
    DIM total AS LONG, i AS INTEGER
    total = 1
    FOR i = 2 TO n
        total = total * i
    NEXT i
    FactLoop& = total
END FUNCTION
