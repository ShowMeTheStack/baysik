' ============================================================
' TITLE:    GOSUB vs SUB: Same Job, Two Styles
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     GOSUB, RETURN, SUB, parameters, scope, call stack, GW-BASIC
' SUMMARY:  Draws the same boxes with an old-style GOSUB subroutine and a modern SUB, showing why parameters and locals matter.
' ------------------------------------------------------------
' WHAT IT DOES
'   Old GW-BASIC programs used GOSUB / RETURN: jump to a line, run
'   some code, come back.  There are no parameters - you "pass"
'   values by setting global variables before the jump - and every
'   variable is shared with the whole program.
'   QBasic added SUB and FUNCTION with real parameters and LOCAL
'   variables.  This program draws text boxes both ways and then
'   demonstrates the classic GOSUB trap: a subroutine that quietly
'   overwrites a loop variable the caller was still using.
'
' HOW TO USE
'   Just run it and compare the output of each part.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK GOSUB (inside the BoxRoutine lines).
'      Open the CALL STACK: a GOSUB shows up as a return point, but
'      there is no new set of local variables - the Variables panel
'      shows the same global bx, by, i as the main program.
'   2. Break on <<< BREAK SUB in DrawBox.  Now the CALL STACK shows
'      a real DrawBox frame, and the Variables panel shows ITS OWN
'      x, y, w, i - separate from the main program's i.
'   3. Part 3 (the trap): WATCH  i  while stepping through the
'      FOR loop.  The GOSUB changes it behind the loop's back so
'      the loop ends early.  The SUB version cannot do that.
'
' CONCEPTS YOU WILL LEARN
'   * GOSUB / RETURN and labels
'   * SUB with parameters, and local variables
'   * Why global variables make bugs: "spooky action at a distance"
'   * END must come before the GOSUB routines (otherwise the program
'     "falls into" them and hits RETURN without GOSUB)
'
' THINGS TO TRY
'   * Delete the END line and see the "RETURN without GOSUB" error.
'   * Can a GOSUB routine call itself recursively?  (Yes - but with no
'     locals, every "level" shares the same variables.  Try it!)
' ============================================================
DECLARE SUB DrawBox (x AS INTEGER, y AS INTEGER, w AS INTEGER, label$)
DECLARE SUB Stars (n AS INTEGER)
' DEFINT makes every variable without a suffix an INTEGER.  Without it
' the main program's i would be SINGLE, and  Stars i  would give
' "Parameter type mismatch" because the SUB wants an INTEGER.
DEFINT A-Z

CLS
PRINT "PART 1: three boxes drawn with GOSUB (globals bx, by, bw, bl$)"
' To "pass arguments" to a GOSUB routine we must set globals first.
bx = 2: by = 3: bw = 12: bl$ = "GOSUB 1": GOSUB BoxRoutine
bx = 16: by = 3: bw = 12: bl$ = "GOSUB 2": GOSUB BoxRoutine
bx = 30: by = 3: bw = 12: bl$ = "GOSUB 3": GOSUB BoxRoutine

LOCATE 8, 1
PRINT "PART 2: the same boxes with a SUB (real parameters)"
DrawBox 2, 10, 12, "SUB 1"
DrawBox 16, 10, 12, "SUB 2"
DrawBox 30, 10, 12, "SUB 3"

LOCATE 15, 1
PRINT "PART 3: the global-variable trap.  Each line should have 1..4 stars."
PRINT "With GOSUB:"
FOR i = 1 TO 4
    n = i
    GOSUB StarRoutine         ' this secretly uses (and changes) i !
NEXT i
PRINT "With SUB:"
FOR i = 1 TO 4
    Stars i                   ' Stars has its own private i
NEXT i
LOCATE 25, 1: PRINT "Done.";
END                           ' <- stops the program falling into the routines

' ---------- GOSUB routines live after END ----------------------
BoxRoutine:
    ' Uses globals bx, by, bw, bl$.  Also uses i - the SAME i as
    ' everywhere else in the main program.
    LOCATE by, bx: PRINT CHR$(218); STRING$(bw - 2, 196); CHR$(191)   ' <<< BREAK GOSUB
    LOCATE by + 1, bx: PRINT CHR$(179); bl$; SPACE$(bw - 2 - LEN(bl$)); CHR$(179)
    LOCATE by + 2, bx: PRINT CHR$(192); STRING$(bw - 2, 196); CHR$(217)
    RETURN

StarRoutine:
    ' Prints n stars.  The author re-used the name i for the
    ' counter here... and that i is the caller's i too!
    ' (A DO loop is used on purpose: a FOR i inside a GOSUB while the
    ' caller's FOR i is still running confuses the FOR/NEXT pairing
    ' and can even give "NEXT without FOR" in GW-BASIC.)
    PRINT "  ";
    i = 1
    DO WHILE i <= n
        PRINT "*";
        i = i + 1
    LOOP
    PRINT "   (i is now"; i; ")"
    RETURN

' ---------- SUBs ------------------------------------------------
SUB DrawBox (x AS INTEGER, y AS INTEGER, w AS INTEGER, label$)
    LOCATE y, x: PRINT CHR$(201); STRING$(w - 2, 205); CHR$(187)   ' <<< BREAK SUB
    LOCATE y + 1, x: PRINT CHR$(186); label$; SPACE$(w - 2 - LEN(label$)); CHR$(186)
    LOCATE y + 2, x: PRINT CHR$(200); STRING$(w - 2, 205); CHR$(188)
END SUB

SUB Stars (n AS INTEGER)
    DIM i AS INTEGER          ' LOCAL i: invisible to the caller
    PRINT "  ";
    FOR i = 1 TO n: PRINT "*";: NEXT i
    PRINT "   (my local i is"; i; ")"
END SUB
