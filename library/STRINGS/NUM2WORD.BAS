' ============================================================
' TITLE:    Number to Words
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     numbers, words, recursion-free, groups of three, cheque writer
' SUMMARY:  Spells out any whole number in English: 123 -> "one hundred twenty-three".
' ------------------------------------------------------------
' WHAT IT DOES
'   Turns numbers into words, the way you would write them on a
'   cheque.  It works up to 999,999,999,999 (almost a trillion) and
'   handles negatives and zero.  The secret is that English names
'   numbers in GROUPS OF THREE digits:
'        12,345,678  =  12 million  345 thousand  678
'   so we only need to know how to say 0..999 and then add the
'   group name (thousand, million, billion).
'   It also shows ordinals ("twenty-first") and a cheque amount
'   with cents.
'
' HOW TO USE
'   Type a number and press Enter.  Type Q or an empty line to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Lookup tables in DATA (ones, teens, tens)
'   * Splitting a number into 3-digit groups with \ and MOD
'   * Hyphens and "and" rules in English number names
'   * DEFDBL / double precision to hold big whole numbers exactly
'
' THINGS TO TRY
'   * Add British style: "one hundred AND twenty-three"
'   * Translate to another language (Spanish, French ...)
'   * Write years the way people say them: 1984 -> nineteen eighty-four
' ============================================================

DEFDBL A-Z
DECLARE FUNCTION Say999$ (n)
DECLARE FUNCTION SayNumber$ (n)
DECLARE FUNCTION Ordinal$ (words$)

DIM SHARED ones$(19), tens$(9), groupName$(3)

' ---- lookup tables ----
FOR i = 0 TO 19: READ ones$(i): NEXT i
FOR i = 2 TO 9: READ tens$(i): NEXT i
FOR i = 0 TO 3: READ groupName$(i): NEXT i
DATA zero,one,two,three,four,five,six,seven,eight,nine,ten
DATA eleven,twelve,thirteen,fourteen,fifteen,sixteen,seventeen,eighteen,nineteen
DATA twenty,thirty,forty,fifty,sixty,seventy,eighty,ninety
DATA "",thousand,million,billion

CLS
COLOR 14: PRINT "NUMBER TO WORDS": COLOR 7
PRINT
PRINT "Some examples:"
FOR i = 1 TO 7
    READ x
    PRINT USING "  ###,###,###,###  "; x;
    COLOR 11: PRINT SayNumber$(x): COLOR 7
NEXT i
DATA 0, 7, 21, 115, 2024, 1000001, 987654321012
PRINT

DO
    LINE INPUT "Number (Enter = quit): "; a$
    IF a$ = "" OR UCASE$(a$) = "Q" THEN EXIT DO
    x = VAL(a$)
    IF ABS(x) > 999999999999# THEN
        PRINT "  Too big - please stay below one trillion."
    ELSE
        whole = FIX(x)
        cents = INT(ABS(x - whole) * 100 + .5)   ' two decimals, rounded
        w$ = SayNumber$(whole)
        COLOR 11: PRINT "  "; w$: COLOR 7
        IF whole >= 0 THEN PRINT "  Ordinal: "; Ordinal$(w$)
        ' cheque style: capital first letter, cents as a fraction
        ' (RIGHT$("0" + ...) gives two digits: 5 cents -> "05")
        IF x >= 0 THEN
            c$ = RIGHT$("0" + LTRIM$(STR$(cents)), 2)
            PRINT "  Cheque : "; UCASE$(LEFT$(w$, 1)); MID$(w$, 2);
            PRINT " dollars and "; c$; "/100"
        END IF
    END IF
    PRINT
LOOP
PRINT "Goodbye!"
END

' ------------------------------------------------------------
' Say999$: words for 0 < n < 1000.
'   hundreds digit -> "X hundred"
'   remainder < 20 -> straight from the ones$ table (teens!)
'   otherwise      -> tens word, plus "-unit" if needed
' ------------------------------------------------------------
FUNCTION Say999$ (n)
    s$ = ""
    h = n \ 100
    r = n MOD 100
    IF h > 0 THEN s$ = ones$(h) + " hundred"
    IF r > 0 THEN
        IF s$ <> "" THEN s$ = s$ + " "
        IF r < 20 THEN
            s$ = s$ + ones$(r)
        ELSE
            s$ = s$ + tens$(r \ 10)
            IF r MOD 10 > 0 THEN s$ = s$ + "-" + ones$(r MOD 10)
        END IF
    END IF
    Say999$ = s$
END FUNCTION

' ------------------------------------------------------------
' SayNumber$: peel off groups of three digits from the RIGHT.
' Group 0 = units, 1 = thousands, 2 = millions, 3 = billions.
' Each non-zero group is said with Say999$ plus its name, and
' put in front of what we have so far.
' (We use INT and subtraction instead of MOD, because MOD only
'  works on numbers that fit in a long integer.)
' ------------------------------------------------------------
FUNCTION SayNumber$ (n)
    IF n = 0 THEN SayNumber$ = "zero": EXIT FUNCTION
    m = ABS(n)
    s$ = ""
    g = 0
    DO WHILE m > 0
        grp = m - INT(m / 1000) * 1000      ' the lowest three digits
        m = INT(m / 1000)
        IF grp > 0 THEN
            part$ = Say999$(grp)
            IF g > 0 THEN part$ = part$ + " " + groupName$(g)
            IF s$ = "" THEN s$ = part$ ELSE s$ = part$ + " " + s$
        END IF
        g = g + 1
    LOOP
    IF n < 0 THEN s$ = "minus " + s$
    SayNumber$ = s$
END FUNCTION

' ------------------------------------------------------------
' Ordinal$: change the LAST word into its ordinal form.
'   one->first two->second three->third five->fifth eight->eighth
'   nine->ninth twelve->twelfth  ...ty->...tieth  others + "th"
' ------------------------------------------------------------
FUNCTION Ordinal$ (words$)
    ' find where the last word starts (after the last space or hyphen)
    p = 0
    FOR i = LEN(words$) TO 1 STEP -1
        IF MID$(words$, i, 1) = " " OR MID$(words$, i, 1) = "-" THEN p = i: EXIT FOR
    NEXT i
    head$ = LEFT$(words$, p)
    last$ = MID$(words$, p + 1)
    SELECT CASE last$
        CASE "one": last$ = "first"
        CASE "two": last$ = "second"
        CASE "three": last$ = "third"
        CASE "five": last$ = "fifth"
        CASE "eight": last$ = "eighth"
        CASE "nine": last$ = "ninth"
        CASE "twelve": last$ = "twelfth"
        CASE ELSE
            IF RIGHT$(last$, 1) = "y" THEN
                last$ = LEFT$(last$, LEN(last$) - 1) + "ieth"
            ELSE
                last$ = last$ + "th"
            END IF
    END SELECT
    Ordinal$ = head$ + last$
END FUNCTION
