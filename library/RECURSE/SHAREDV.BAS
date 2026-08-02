' ============================================================
' TITLE:    SHARED Variables Three Ways
' CATEGORY: Recursion & Debugging
' LEVEL:    Beginner
' TAGS:     SHARED, DIM SHARED, scope, global variables, SUB, debugger
' SUMMARY:  A tiny bank account program that shows DIM SHARED, the SHARED statement, and what happens when you forget both.
' ------------------------------------------------------------
' WHAT IT DOES
'   In QBasic, a variable in the main program is NOT visible inside
'   a SUB or FUNCTION.  There are three ways to deal with that:
'     1. DIM SHARED in the main program - every procedure sees it
'        (a true global).
'     2. The SHARED statement inside ONE procedure - only that
'        procedure gets access to the main program's variable.
'     3. Pass it as a parameter - the cleanest way, no sharing.
'   A small "bank" uses all three, plus one procedure that forgets
'   and quietly works on its own private copy.
'
' HOW TO USE
'   Just run it and follow the balance after each step.
'
'   DEBUGGER TOUR
'   1. Break on <<< BREAK DEPOSIT.  In the Variables panel, balance
'      appears as a global: change it to 1000 while paused and
'      continue.  The rest of the program sees your change.
'   2. Break on <<< BREAK FEE.  This SUB uses the SHARED statement to
'      reach  fees  - which is NOT DIM SHARED.  Try adding  fees  as
'      a WATCH while paused in Deposit: it is not visible there.
'   3. Break on <<< BREAK FORGOT.  The Variables panel shows a LOCAL
'      savings of 0 inside ForgotToShare.  Step to the end of the
'      SUB and back out: the main program's savings is still 0.
'
' CONCEPTS YOU WILL LEARN
'   * DIM SHARED (global) vs SHARED statement (one procedure only)
'   * Parameters as the third, safest option
'   * How the debugger shows global and local variables separately
'
' THINGS TO TRY
'   * Fix ForgotToShare by adding  SHARED savings AS LONG  as its
'     first line (or DIM SHARED savings in the main program).
'   * Rewrite Withdraw so it RETURNS the new balance instead of
'     changing a global.  Which version is easier to test?
' ============================================================
DECLARE SUB Deposit (amount AS LONG)
DECLARE SUB Withdraw (amount AS LONG)
DECLARE SUB MonthlyFee ()
DECLARE SUB ForgotToShare (amount AS LONG)
' (Every procedure is DECLAREd so they can be called before they
'  appear in the file.)
DECLARE SUB AddInterest (bal AS LONG, pct AS INTEGER)
DECLARE SUB ShowBalance (label$)

DIM SHARED balance AS LONG   ' (1) global: every SUB can use it
DIM fees AS LONG             ' main-program only... unless a SUB says SHARED
DIM savings AS LONG          ' main-program only, and nobody says SHARED

CLS
PRINT "THE SHARED-VARIABLE BANK"
PRINT
balance = 100
ShowBalance "Opening balance"

Deposit 50
ShowBalance "After depositing 50"

Withdraw 30
ShowBalance "After withdrawing 30"

MonthlyFee
ShowBalance "After the monthly fee"
PRINT "    (fees collected so far:"; fees; ")"

savings = 0
ForgotToShare 20
ShowBalance "After moving 20 to savings"
PRINT "    (main program's savings:"; savings; " - where did the 20 go?)"

AddInterest balance, 10      ' (3) passed as a parameter
ShowBalance "After 10% interest"
END

SUB ShowBalance (label$)
    PRINT USING "  \                                       \ $#####"; label$; balance
END SUB

SUB Deposit (amount AS LONG)
    balance = balance + amount         ' <<< BREAK DEPOSIT
END SUB

SUB Withdraw (amount AS LONG)
    IF amount > balance THEN
        PRINT "  ** not enough money **"
    ELSE
        balance = balance - amount
    END IF
END SUB

SUB MonthlyFee
    SHARED fees AS LONG                ' (2) borrow the main program's fees
    balance = balance - 5              ' <<< BREAK FEE
    fees = fees + 5
END SUB

SUB ForgotToShare (amount AS LONG)
    ' Moves money from the balance into savings.  balance is global,
    ' so that part works.  But savings is only DIMmed in the main
    ' program, and this SUB has no  SHARED savings  line - so the
    ' savings below is a brand-new LOCAL variable that starts at 0
    ' and disappears when the SUB ends.  The money just vanishes!
    balance = balance - amount
    savings = savings + amount         ' <<< BREAK FORGOT (savings starts at 0!)
    PRINT "    ForgotToShare thinks savings is now"; savings
END SUB

SUB AddInterest (bal AS LONG, pct AS INTEGER)
    ' bal is the caller's variable passed BY REFERENCE, so changing
    ' it here changes  balance  in the main program.
    bal = bal + bal * pct \ 100
END SUB
