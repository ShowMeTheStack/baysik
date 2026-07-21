' ============================================================
' TITLE:    Fraction Calculator
' CATEGORY: Mathematics
' LEVEL:    Intermediate
' TAGS:     fractions, gcd, euclid, parsing, SUB
' SUMMARY:  Adds, subtracts, multiplies and divides fractions like 3/4 + 5/6, always in lowest terms.
' ------------------------------------------------------------
' WHAT IT DOES
'   Type a sum such as   3/4 + 5/6   or   2 1/2 * 4/5  (mixed number)
'   and the calculator shows the exact answer as a reduced fraction,
'   a mixed number and a decimal.  No rounding errors - fractions are
'   kept as two whole numbers, a numerator and a denominator.
'   Reducing uses Euclid's algorithm for the Greatest Common Divisor,
'   one of the oldest algorithms in the world (about 300 BC).
'
' HOW TO USE
'   Enter:  fraction  operator  fraction   (operators + - * /)
'   Spaces around the operator are required, e.g.  1/3 - 1/2
'   Whole numbers (7) and mixed numbers (1 3/8) are fine too.
'   Enter a blank line or Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Euclid's GCD:  gcd(a, b) = gcd(b, a MOD b)
'   * Fraction rules: a/b + c/d = (ad + bc)/bd,  a/b / c/d = ad/bc
'   * Parsing text input with INSTR and MID$
'   * SUBs that return results through their parameters
'
' THINGS TO TRY
'   * Add the "^" operator for whole-number powers
'   * Use the LCM instead of b*d when adding (smaller intermediate numbers)
'   * Show each step of the working, like a teacher would
' ============================================================

DECLARE FUNCTION Gcd& (a&, b&)
DECLARE SUB Reduce (n&, d&)
DECLARE SUB ParseFrac (s$, n&, d&, ok%)
DECLARE FUNCTION FracStr$ (n&, d&)

CLS
COLOR 14: PRINT "FRACTION CALCULATOR": COLOR 7
PRINT "Examples:  3/4 + 5/6     2 1/2 * 4/5     7 / 3/8     1/3 - 1/2"
PRINT

DO
    LINE INPUT "> "; e$
    e$ = LTRIM$(RTRIM$(e$))
    IF e$ = "" OR UCASE$(e$) = "Q" THEN EXIT DO

    ' Find the operator: it is surrounded by spaces, so a "/" inside a
    ' fraction (no spaces) is not mistaken for division.
    op$ = "": p = 0
    FOR i = 2 TO LEN(e$) - 2
        c$ = MID$(e$, i, 3)
        IF c$ = " + " OR c$ = " - " OR c$ = " * " OR c$ = " / " THEN
            op$ = MID$(c$, 2, 1): p = i: EXIT FOR
        END IF
    NEXT i
    IF op$ = "" THEN
        PRINT "  Please write it like  3/4 + 5/6  (spaces around the operator)."
    ELSE
        ParseFrac LEFT$(e$, p - 1), a&, b&, ok1%
        ParseFrac MID$(e$, p + 3), c&, d&, ok2%
        IF ok1% = 0 OR ok2% = 0 THEN
            PRINT "  I could not read one of the fractions."
        ELSE
            ' The four rules of fraction arithmetic:
            SELECT CASE op$
                CASE "+": n& = a& * d& + c& * b&: m& = b& * d&
                CASE "-": n& = a& * d& - c& * b&: m& = b& * d&
                CASE "*": n& = a& * c&: m& = b& * d&
                CASE "/": n& = a& * d&: m& = b& * c&   ' flip and multiply
            END SELECT
            IF m& = 0 THEN
                PRINT "  Cannot divide by zero!"
            ELSE
                Reduce n&, m&
                COLOR 11
                PRINT "  = "; FracStr$(n&, m&);
                COLOR 7
                ' Mixed number form, e.g. 19/12 = 1 7/12
                IF ABS(n&) > m& AND m& > 1 THEN
                    w& = ABS(n&) \ m&
                    sg$ = "": IF n& < 0 THEN sg$ = "-"
                    PRINT "  = "; sg$; LTRIM$(STR$(w&)); " "; FracStr$(ABS(n&) MOD m&, m&);
                END IF
                PRINT "  ="; CSNG(n&) / m&
            END IF
        END IF
    END IF
LOOP
PRINT "Bye!"
END

' Shows n/d, or just n when the denominator is 1.
FUNCTION FracStr$ (n&, d&)
    IF d& = 1 THEN
        FracStr$ = LTRIM$(STR$(n&))
    ELSE
        FracStr$ = LTRIM$(STR$(n&)) + "/" + LTRIM$(STR$(d&))
    END IF
END FUNCTION

' Euclid's algorithm.  Any number dividing both a and b also divides
' a MOD b (what is left after taking b's out of a).  So we can keep
' replacing (a, b) with (b, a MOD b) - the numbers shrink fast -
' until b is 0.  Then a is the greatest common divisor.
FUNCTION Gcd& (a&, b&)
    x& = ABS(a&): y& = ABS(b&)
    DO WHILE y& <> 0
        t& = x& MOD y&
        x& = y&
        y& = t&
    LOOP
    Gcd& = x&
END FUNCTION

' Reads "3/4", "-3/4", "7" or "2 1/2" into numerator n& and denominator d&.
SUB ParseFrac (s$, n&, d&, ok%)
    t$ = LTRIM$(RTRIM$(s$))
    ok% = 0
    IF t$ = "" THEN EXIT SUB
    whole& = 0: neg% = 0
    IF LEFT$(t$, 1) = "-" THEN neg% = -1: t$ = MID$(t$, 2)
    sp = INSTR(t$, " ")
    IF sp > 0 THEN                      ' mixed number: "2 1/2"
        whole& = VAL(LEFT$(t$, sp - 1))
        t$ = LTRIM$(MID$(t$, sp + 1))
    END IF
    sl = INSTR(t$, "/")
    IF sl = 0 THEN
        n& = VAL(t$): d& = 1
    ELSE
        n& = VAL(LEFT$(t$, sl - 1))
        d& = VAL(MID$(t$, sl + 1))
    END IF
    IF d& = 0 THEN EXIT SUB             ' x/0 is not a number
    n& = whole& * d& + n&               ' 2 1/2 = (2*2 + 1)/2 = 5/2
    IF neg% THEN n& = -n&
    Reduce n&, d&
    ok% = -1
END SUB

' Divide top and bottom by their GCD, and keep the sign on top.
SUB Reduce (n&, d&)
    g& = Gcd&(n&, d&)
    IF g& = 0 THEN EXIT SUB
    n& = n& \ g&: d& = d& \ g&
    IF d& < 0 THEN n& = -n&: d& = -d&
END SUB
