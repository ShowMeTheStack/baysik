' ============================================================
' TITLE:    Bit Array Sets
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     sets, bit arrays, AND OR XOR, sieve, bit manipulation
' SUMMARY:  Store sets of numbers 0-99 as bits packed into integers and combine them with AND, OR and XOR.
' ------------------------------------------------------------
' WHAT IT DOES
'   A set of small numbers can be stored as a row of YES/NO bits:
'   bit n is 1 if n is in the set. Sixteen bits fit in one BASIC
'   INTEGER, so a set of 0..99 needs only 7 integers (14 bytes)!
'
'   Set operations become single bitwise operators, applied to
'   each integer in turn:
'       union         A OR B        (in either)
'       intersection  A AND B       (in both)
'       difference    A AND NOT B   (in A but not B)
'       symmetric     A XOR B       (in exactly one)
'
'   We build four sets - primes (with the Sieve of Eratosthenes,
'   working directly on bits), even numbers, perfect squares and
'   Fibonacci numbers - then show every combination as 10x10 grids.
'
' HOW TO USE
'   Press any key to step through pairs of sets; Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Which word and which bit:  word = n \ 16,  bit = n MOD 16
'   * Bit masks from a lookup table (2^bit)
'   * Bit 15 is the sign bit of an INTEGER, so its mask is -32768
'   * Counting set bits ("population count")
'
' THINGS TO TRY
'   * Add a set of multiples of 3 or of numbers containing a 7
'   * Make the universe 0..255
' ============================================================

DEFINT A-Z
DECLARE SUB SetBit (s() AS INTEGER, n AS INTEGER)
DECLARE SUB ClrBit (s() AS INTEGER, n AS INTEGER)
DECLARE FUNCTION BitOn% (wd AS INTEGER, n AS INTEGER)
DECLARE SUB ShowSet (s() AS INTEGER, title$, x AS INTEGER, y AS INTEGER)
DECLARE SUB CountMembers (s() AS INTEGER, c AS INTEGER)

CONST WORDS = 7              ' 7 * 16 = 112 bits >= 100 numbers
DIM SHARED mask(0 TO 15) AS INTEGER
' mask(b) has only bit b switched on. 2^15 = 32768 does not fit
' in an INTEGER, but the bit pattern &H8000 is exactly -32768.
FOR b = 0 TO 14: mask(b) = 2 ^ b: NEXT b
mask(15) = &H8000

' Five sets (plus a scratch set for results), each 7 words.
DIM sets(1 TO 4, 0 TO WORDS - 1) AS INTEGER
DIM a(0 TO WORDS - 1), b(0 TO WORDS - 1), r(0 TO WORDS - 1)
DIM nm$(1 TO 4)
nm$(1) = "PRIMES": nm$(2) = "EVENS": nm$(3) = "SQUARES": nm$(4) = "FIBONACCI"

' ---- Primes: Sieve of Eratosthenes on a bit array -----------
' Start with every number from 2 up "in", then cross out multiples.
FOR n = 2 TO 99: SetBit a(), n: NEXT n
FOR n = 2 TO 9                      ' only need up to sqrt(99)
    IF BitOn%(a(n \ 16), n) THEN
        FOR m = n * n TO 99 STEP n: ClrBit a(), m: NEXT m
    END IF
NEXT n
FOR w = 0 TO WORDS - 1: sets(1, w) = a(w): NEXT w
' ---- Evens, squares, Fibonacci ------------------------------
FOR w = 0 TO WORDS - 1: a(w) = 0: NEXT w
FOR n = 0 TO 99 STEP 2: SetBit a(), n: NEXT n
FOR w = 0 TO WORDS - 1: sets(2, w) = a(w): a(w) = 0: NEXT w
FOR n = 0 TO 9: SetBit a(), n * n: NEXT n
FOR w = 0 TO WORDS - 1: sets(3, w) = a(w): a(w) = 0: NEXT w
f1 = 0: f2 = 1
DO WHILE f1 <= 99
    SetBit a(), f1
    t = f1 + f2: f1 = f2: f2 = t
LOOP
FOR w = 0 TO WORDS - 1: sets(4, w) = a(w): NEXT w

' ---- Show the raw words for the primes ----------------------
CLS
PRINT "The PRIME set is stored in just"; WORDS; "integers:"
FOR w = 0 TO WORDS - 1
    ' (no "&" inside the USING text - there it means "a string goes here")
    PRINT USING "  word # (numbers ### to ###) = "; w; w * 16; w * 16 + 15;
    PRINT "&H"; RIGHT$("000" + HEX$(sets(1, w)), 4); "  = ";
    ' print the 16 bits, highest first
    FOR bt = 15 TO 0 STEP -1
        IF sets(1, w) AND mask(bt) THEN PRINT "1"; ELSE PRINT "0";
    NEXT bt
    PRINT
NEXT w
PRINT : PRINT "Read each binary row right-to-left: bit 0 is the first number."
PRINT "Press a key...": k$ = INPUT$(1)

' ---- Combine every pair of sets -----------------------------
FOR i = 1 TO 3
    FOR j = i + 1 TO 4
        CLS
        FOR w = 0 TO WORDS - 1: a(w) = sets(i, w): b(w) = sets(j, w): NEXT w
        ShowSet a(), "A = " + nm$(i), 1, 1
        ShowSet b(), "B = " + nm$(j), 27, 1
        FOR w = 0 TO WORDS - 1: r(w) = a(w) OR b(w): NEXT w
        ShowSet r(), "A OR B (union)", 53, 1
        FOR w = 0 TO WORDS - 1: r(w) = a(w) AND b(w): NEXT w
        ShowSet r(), "A AND B (both)", 1, 13
        FOR w = 0 TO WORDS - 1: r(w) = a(w) AND NOT b(w): NEXT w
        ShowSet r(), "A AND NOT B", 27, 13
        FOR w = 0 TO WORDS - 1: r(w) = a(w) XOR b(w): NEXT w
        ShowSet r(), "A XOR B", 53, 13
        LOCATE 25, 1: PRINT "Press a key for the next pair (Esc quits)";
        k$ = INPUT$(1)
        IF k$ = CHR$(27) THEN END
    NEXT j
NEXT i
CLS : PRINT "That's every pair. Bits are the most compact way to store a set!"
END

'  CountMembers: how many members? Test every bit of every word.
' The answer comes back through the parameter c.
SUB CountMembers (s() AS INTEGER, c AS INTEGER)
    c = 0
    FOR w = 0 TO WORDS - 1
        FOR bt = 0 TO 15
            IF s(w) AND mask(bt) THEN c = c + 1
        NEXT bt
    NEXT w
END SUB

SUB ClrBit (s() AS INTEGER, n AS INTEGER)
    ' AND with the inverted mask switches just that one bit off.
    s(n \ 16) = s(n \ 16) AND NOT mask(n MOD 16)
END SUB

'  BitOn%: is number n present? The caller passes the one word
' that holds n (word n \ 16); we test bit n MOD 16 inside it.
FUNCTION BitOn% (wd AS INTEGER, n AS INTEGER)
    BitOn% = (wd AND mask(n MOD 16)) <> 0
END FUNCTION

SUB SetBit (s() AS INTEGER, n AS INTEGER)
    s(n \ 16) = s(n \ 16) OR mask(n MOD 16)
END SUB

' ShowSet: draw the set as a 10x10 grid of numbers 0..99.
SUB ShowSet (s() AS INTEGER, title$, x AS INTEGER, y AS INTEGER)
    LOCATE y, x: COLOR 15: PRINT LEFT$(title$, 25); : COLOR 7
    FOR row = 0 TO 9
        LOCATE y + 1 + row, x
        FOR col = 0 TO 9
            n = row * 10 + col
            IF BitOn%(s(n \ 16), n) THEN COLOR 14: PRINT CHR$(219); CHR$(219);  ELSE COLOR 8: PRINT CHR$(250); " ";
        NEXT col
    NEXT row
    COLOR 7
    CountMembers s(), c
    LOCATE y + 11, x: PRINT "members:"; c;
END SUB
