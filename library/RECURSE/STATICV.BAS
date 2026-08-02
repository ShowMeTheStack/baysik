' ============================================================
' TITLE:    STATIC vs Local Variables
' CATEGORY: Recursion & Debugging
' LEVEL:    Intermediate
' TAGS:     STATIC, local variables, scope, lifetime, recursion, debugger
' SUMMARY:  Side-by-side counters show how STATIC variables survive between calls - and why that breaks recursion.
' ------------------------------------------------------------
' WHAT IT DOES
'   A normal (local) variable inside a SUB is created fresh, set to
'   0, every time the SUB is called, and destroyed when it returns.
'   A STATIC variable is created once and KEEPS its value between
'   calls - it is like a private global that only one SUB can see.
'   Part 1: two "ticket machines" called 5 times each.
'   Part 2: a STATIC variable used as a call counter and a
'           "first time only" flag.
'   Part 3: the danger zone - a recursive SUB that uses a STATIC
'           variable.  All recursive frames share the SAME one, so a
'           deeper call overwrites the value the shallower call still
'           needed.
'
' HOW TO USE
'   Just run it and read each part.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK LOCAL and <<< BREAK STATIC.  Each stop,
'      look at the variable in the Variables panel.  The local one is
'      always 0 when you arrive; the static one remembers.
'   2. In part 3 break on <<< BREAK SUMDOWN.  Open the CALL STACK and
'      click between SumLocal frames: every frame has its own here.
'      Then do the same in SumStatic: every frame shows the SAME
'      value for here, because there is only one of it.
'   3. EDIT the static count in the Variables panel while paused
'      (e.g. set it to 100) and continue - the next ticket number
'      follows your edit.
'
' CONCEPTS YOU WILL LEARN
'   * Lifetime (how long a variable lives) vs scope (who can see it)
'   * The STATIC statement and SUB ... STATIC
'   * Why recursive procedures should use local variables
'
' THINGS TO TRY
'   * Change "SUB Ticket2" to "SUB Ticket2 STATIC" - that makes ALL its
'     variables static.  What changes?
'   * Write a FUNCTION NextId% that returns 1, 2, 3 ... on each call.
' ============================================================
DECLARE SUB TicketLocal ()
DECLARE SUB TicketStatic ()
DECLARE SUB Greeter (who$)
DECLARE FUNCTION SumLocal% (n AS INTEGER)
DECLARE FUNCTION SumStatic% (n AS INTEGER)

CLS
PRINT "PART 1: two ticket machines, called 5 times each"
PRINT "  local  machine: ";
FOR k% = 1 TO 5: TicketLocal: NEXT k%
PRINT
PRINT "  STATIC machine: ";
FOR k% = 1 TO 5: TicketStatic: NEXT k%
PRINT
PRINT

PRINT "PART 2: a STATIC 'first time' flag and call counter"
Greeter "Ada"
Greeter "Grace"
Greeter "Linus"
PRINT

PRINT "PART 3: recursion with a local vs a STATIC variable"
PRINT "  Sum 1..5 should be 15."
PRINT "  using a local :"; SumLocal%(5)
PRINT "  using a STATIC:"; SumStatic%(5)
PRINT
PRINT "In SumStatic every level shares ONE 'here', so by the time the"
PRINT "outer calls use it, the innermost call has set it to 0."
END

SUB TicketLocal
    DIM count AS INTEGER          ' fresh 0 on EVERY call
    count = count + 1             ' <<< BREAK LOCAL
    PRINT count;
END SUB

SUB TicketStatic
    STATIC count AS INTEGER       ' made once, kept between calls
    count = count + 1             ' <<< BREAK STATIC
    PRINT count;
END SUB

SUB Greeter (who$)
    STATIC calls AS INTEGER, metBefore AS INTEGER
    calls = calls + 1
    IF NOT metBefore THEN
        PRINT "  Hello "; who$; ", you are my very first visitor!"
        metBefore = -1
    ELSE
        PRINT "  Hi "; who$; ", you are visitor number"; calls
    END IF
END SUB

FUNCTION SumLocal% (n AS INTEGER)
    DIM here AS INTEGER           ' every frame gets its own
    here = n
    IF n = 0 THEN SumLocal% = 0: EXIT FUNCTION
    SumLocal% = SumLocal%(n - 1) + here
END FUNCTION

FUNCTION SumStatic% (n AS INTEGER)
    STATIC here AS INTEGER        ' ONE copy shared by all frames!
    here = n                      ' <<< BREAK SUMDOWN
    IF n = 0 THEN SumStatic% = 0: EXIT FUNCTION
    ' The recursive call runs first and changes  here  on its way
    ' down, all the way to 0...
    SumStatic% = SumStatic%(n - 1) + here
    ' ...so EVERY frame adds 0 instead of its own n.  Result: 0.
END FUNCTION
