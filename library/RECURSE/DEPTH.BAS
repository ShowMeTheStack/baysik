' ============================================================
' TITLE:    Recursion Depth Explorer
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     recursion, stack depth, stack overflow, ON ERROR, FRE, debugging
' SUMMARY:  How deep can recursion go?  Probe the limit safely, see what a stack overflow looks like, and catch it with ON ERROR.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every call that has not returned yet uses a little memory on the
'   CALL STACK.  If recursion goes too deep, the stack runs out:
'   "Out of stack space" (error 7 / error 28 in QBasic).
'   This program offers three experiments:
'     1. Controlled descent - go N levels deep and come back,
'        printing a "depth gauge" at every 10th level.
'     2. Big frames vs small frames - a SUB with a large local array
'        uses much more stack per call than a SUB with one integer.
'     3. Runaway recursion - a SUB with NO base case.  ON ERROR
'        catches the crash and reports how deep it got.
'
' HOW TO USE
'   Pick an experiment from the menu (1, 2, 3) or Q to quit.
'
'   DEBUGGER TOUR
'   1. In experiment 1, set a CONDITIONAL breakpoint on <<< BREAK
'      DIVE with   level = 25   and open the CALL STACK.  Scroll to
'      the bottom: 25 Dive frames.  Click the 10th one and read its
'      level - each frame remembers its own.
'   2. While paused, change  maxLevel  in the Variables panel to
'      something smaller than the current level.  Continue.  The
'      recursion stops early - you changed the base case at runtime!
'   3. For experiment 3, put a breakpoint on <<< BREAK CAUGHT.  When
'      it hits, the runaway frames are already gone; look at
'      deepest to see how far it got.
'   4. Try the STOP statement: uncomment the STOP line in Dive.  It
'      acts like a breakpoint written in the code itself.
'
' CONCEPTS YOU WILL LEARN
'   * What the call stack physically is, and why it has a limit
'   * Local arrays make bigger stack frames
'   * Catching runtime errors with ON ERROR GOTO / RESUME
'   * STOP as a code-level breakpoint
'
' THINGS TO TRY
'   * Rewrite experiment 1 as a loop.  How deep can a LOOP go?
'     (Trick question: loops do not use the stack at all.)
'   * Find the largest depth that works with a 100-element local array.
' ============================================================
DECLARE SUB Dive (level AS INTEGER)
DECLARE SUB Runaway (level AS LONG)
DECLARE SUB BigFrame (level AS INTEGER)
DECLARE SUB SmallFrame (level AS INTEGER)

DIM SHARED maxLevel AS INTEGER
DIM SHARED deepest AS LONG       ' deepest level reached so far
DIM SHARED crashed AS INTEGER    ' set by the error handler

DO
    CLS
    PRINT "RECURSION DEPTH EXPLORER"
    PRINT
    PRINT "  1) Controlled descent to a chosen depth"
    PRINT "  2) Small stack frames vs big stack frames"
    PRINT "  3) Runaway recursion (no base case) caught by ON ERROR"
    PRINT "  Q) Quit"
    PRINT
    PRINT "Choice? ";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    PRINT k$
    PRINT
    SELECT CASE k$
    CASE "1"
        INPUT "How deep (1-200)"; maxLevel
        IF maxLevel < 1 THEN maxLevel = 1
        IF maxLevel > 200 THEN maxLevel = 200
        Dive 1
        PRINT "Back at the top. Every frame returned safely."
    CASE "2"
        PRINT "Each SmallFrame call keeps 1 integer; each BigFrame keeps 200."
        deepest = 0: SmallFrame 1
        PRINT "SmallFrame reached depth"; deepest
        deepest = 0: BigFrame 1
        PRINT "BigFrame   reached depth"; deepest
        PRINT "(Both were told to go 50 deep.  In real QBasic the big"
        PRINT " frames would run out of stack space much sooner.)"
    CASE "3"
        deepest = 0: crashed = 0
        ON ERROR GOTO StackHandler
        Runaway 1
        ON ERROR GOTO 0
        IF crashed THEN
            PRINT "Caught it!  The runaway recursion reached depth"; deepest   ' <<< BREAK CAUGHT
        ELSE
            PRINT "Runaway stopped by its safety limit at depth"; deepest
        END IF
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
    PRINT
    PRINT "Press a key...";
    DO: LOOP WHILE INKEY$ = ""
LOOP
END

' ---- error handler: jumps here on ANY runtime error -------
StackHandler:
    crashed = -1
    PRINT "Error"; ERR; "happened: ";
    IF ERR = 28 OR ERR = 7 THEN PRINT "out of stack/memory" ELSE PRINT "something else"
    ' RESUME NEXT continues after the statement that started it all
    ' (the  Runaway 1  call in the main program), throwing away every
    ' unfinished Runaway frame at once.
    RESUME NEXT

SUB Dive (level AS INTEGER)
    IF level MOD 10 = 0 THEN                 ' <<< BREAK DIVE
        PRINT USING "depth ###  "; level;
        PRINT STRING$(level \ 10, 219)
    END IF
    ' STOP                                   ' <- uncomment to pause here
    IF level < maxLevel THEN Dive level + 1  ' base case: level = maxLevel
END SUB

SUB SmallFrame (level AS INTEGER)
    DIM x AS INTEGER
    x = level
    IF level > deepest THEN deepest = level
    IF level < 50 THEN SmallFrame level + 1
END SUB

SUB BigFrame (level AS INTEGER)
    DIM big(1 TO 200) AS INTEGER     ' 400 bytes of locals per call
    big(1) = level
    IF level > deepest THEN deepest = level
    IF level < 50 THEN BigFrame level + 1
END SUB

' There is NO real base case here - only a very high safety limit so
' that an interpreter with a huge stack still stops eventually.
SUB Runaway (level AS LONG)
    deepest = level
    IF level >= 100000 THEN EXIT SUB
    Runaway level + 1
END SUB
