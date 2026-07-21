' ============================================================
' TITLE:    Giant Numbers: 100 Factorial
' CATEGORY: Mathematics
' LEVEL:    Advanced
' TAGS:     big numbers, strings, long multiplication, factorial, arbitrary precision
' SUMMARY:  Does school-style arithmetic on digit strings to compute 100!, 2^256 and huge Fibonacci numbers exactly.
' ------------------------------------------------------------
' WHAT IT DOES
'   Normal BASIC numbers run out of exact digits at about 16 digits.
'   100! (= 1 x 2 x 3 x ... x 100) has 158 digits!  To work with it
'   we store numbers as STRINGS of digits and do arithmetic the way
'   you learned at school: column by column, carrying as we go.
'     BigAdd$  - column addition with carries
'     BigMul$  - long multiplication (every digit times every digit)
'   Then we use them to compute 100!, 2^256 and the 300th
'   Fibonacci number, all exactly.
'
' HOW TO USE
'   Press a key between results.  At the end, type your own two
'   numbers (as long as you like) to multiply.  Blank line quits.
'
' CONCEPTS YOU WILL LEARN
'   * Strings as digit arrays: MID$, VAL, STR$, ASC
'   * Carrying in addition and multiplication
'   * Why 100! ends in 24 zeros (count the factors of 5!)
'
' THINGS TO TRY
'   * Write BigSub$ (subtraction with borrowing)
'   * Compute 1000! (it has 2568 digits - be patient)
'   * Add up the digits of 2^1000
' ============================================================

DECLARE FUNCTION BigAdd$ (a$, b$)
DECLARE FUNCTION BigMul$ (a$, b$)
DECLARE SUB ShowBig (label$, n$)

CLS
COLOR 14: PRINT "GIANT NUMBERS WITH STRING ARITHMETIC": COLOR 7
PRINT "Ordinary DOUBLE precision: 25! ="; 25# * 24 * 23 * 22 * 21 * 20 * 19 * 18 * 17 * 16 * 15 * 14 * 13 * 12 * 11 * 10 * 9 * 8 * 7 * 6 * 5 * 4 * 3 * 2
PRINT "...only about 16 digits are exact.  Strings can do better!"
PRINT

' ---- 100 factorial: multiply 1 x 2 x 3 x ... x 100 ----
f$ = "1"
FOR i = 2 TO 100
    f$ = BigMul$(f$, LTRIM$(STR$(i)))
NEXT i
ShowBig "100! =", f$
' Count trailing zeros: each zero needs a factor 10 = 2 x 5.  There
' are more 2s than 5s, so count 5s: 100\5 + 100\25 = 20 + 4 = 24.
z = 0
DO WHILE MID$(f$, LEN(f$) - z, 1) = "0": z = z + 1: LOOP
PRINT "It ends in"; z; "zeros (100\5 + 100\25 = 24 factors of five)."
PRINT : PRINT "Press a key...": k$ = INPUT$(1): CLS

' ---- 2^256 by repeated doubling (adding a number to itself) ----
p$ = "1"
FOR i = 1 TO 256: p$ = BigAdd$(p$, p$): NEXT i
ShowBig "2^256 =", p$
PRINT "(That is how many different 256-bit keys a computer can have.)"
PRINT

' ---- Fibonacci 300 ----
a$ = "0": b$ = "1"
FOR i = 2 TO 300
    c$ = BigAdd$(a$, b$): a$ = b$: b$ = c$
NEXT i
ShowBig "Fibonacci(300) =", b$
PRINT : PRINT "Press a key...": k$ = INPUT$(1): CLS

' ---- Your turn ----
PRINT "Multiply any two whole numbers (blank line to quit)."
DO
    LINE INPUT "First number : "; x$
    x$ = LTRIM$(RTRIM$(x$))
    IF x$ = "" THEN EXIT DO
    LINE INPUT "Second number: "; y$
    y$ = LTRIM$(RTRIM$(y$))
    ' Reject anything that is not made only of digits.
    ok = (y$ <> "")
    FOR i = 1 TO LEN(x$): IF INSTR("0123456789", MID$(x$, i, 1)) = 0 THEN ok = 0
    NEXT i
    FOR i = 1 TO LEN(y$): IF INSTR("0123456789", MID$(y$, i, 1)) = 0 THEN ok = 0
    NEXT i
    IF ok THEN ShowBig "Product =", BigMul$(x$, y$) ELSE PRINT "Digits only, please."
    PRINT
LOOP
END

' Column addition, right to left, exactly like on paper.
FUNCTION BigAdd$ (a$, b$)
    r$ = ""
    carry = 0
    i = LEN(a$): j = LEN(b$)
    DO WHILE i > 0 OR j > 0 OR carry > 0
        s = carry
        ' ASC(digit) - 48 turns the character "7" into the number 7.
        IF i > 0 THEN s = s + ASC(MID$(a$, i, 1)) - 48: i = i - 1
        IF j > 0 THEN s = s + ASC(MID$(b$, j, 1)) - 48: j = j - 1
        r$ = CHR$(48 + s MOD 10) + r$       ' write the ones digit
        carry = s \ 10                      ' carry the tens
    LOOP
    BigAdd$ = r$
END FUNCTION

' Long multiplication.  Digit i of a (from the right) times digit j of
' b lands in column i + j - 1 of the answer.  We add all those products
' into an array of columns first, then do all the carrying at the end.
FUNCTION BigMul$ (a$, b$)
    la = LEN(a$): lb = LEN(b$)
    DIM col(1 TO la + lb) AS LONG
    FOR i = 1 TO la
        da = ASC(MID$(a$, la - i + 1, 1)) - 48
        IF da > 0 THEN
            FOR j = 1 TO lb
                col(i + j - 1) = col(i + j - 1) + da * (ASC(MID$(b$, lb - j + 1, 1)) - 48)
            NEXT j
        END IF
    NEXT i
    ' Carry: each column keeps its ones digit and passes the rest left.
    r$ = ""
    carry& = 0
    FOR k = 1 TO la + lb
        t& = col(k) + carry&
        r$ = CHR$(48 + t& MOD 10) + r$
        carry& = t& \ 10
    NEXT k
    ' Remove leading zeros (but keep a single "0").
    DO WHILE LEN(r$) > 1 AND LEFT$(r$, 1) = "0": r$ = MID$(r$, 2): LOOP
    BigMul$ = r$
END FUNCTION

' Prints a big number in groups of 3 digits, wrapping long lines
' (72 characters = exactly 18 groups of "ddd,", so groups never split).
SUB ShowBig (label$, n$)
    COLOR 11: PRINT label$; " ("; LTRIM$(STR$(LEN(n$))); " digits)": COLOR 15
    ' Start with the leftover digits so groups line up with the end.
    first = LEN(n$) MOD 3: IF first = 0 THEN first = 3
    out$ = LEFT$(n$, first)
    FOR i = first + 1 TO LEN(n$) STEP 3
        out$ = out$ + "," + MID$(n$, i, 3)
    NEXT i
    DO WHILE LEN(out$) > 72
        PRINT "  "; LEFT$(out$, 72)
        out$ = MID$(out$, 73)
    LOOP
    PRINT "  "; out$
    COLOR 7
END SUB
