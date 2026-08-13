' ============================================================
' TITLE:    Array Memory Hex Viewer
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     def seg, varseg, varptr, peek, poke, hex dump, two's complement, ieee
' SUMMARY:  Point DEF SEG at an array with VARSEG and PEEK its raw bytes to see how numbers are really stored.
' ------------------------------------------------------------
' WHAT IT DOES
'   With  DEF SEG = VARSEG(a(0))  and  PEEK(VARPTR(a(0)) + n)  you can
'   look at the actual bytes behind any numeric array.  Type a number
'   and it is stored in an INTEGER, a LONG and a SINGLE array element;
'   the program then shows each element byte by byte in hex and binary.
'   You will discover:
'     * little-endian order: the LOW byte comes first in memory
'     * two's complement: -1 is stored as FF FF
'     * a SINGLE is sign + exponent + mantissa (IEEE 754)
'   Finally it shows the opposite trick: POKEing bytes to build a
'   number without ever assigning it.
'
' HOW TO USE
'   Type a whole number (try 1, 255, 256, -1, -2, 32767, 1000000)
'   or a decimal (0.5, 3.75).  Type Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * DEF SEG = VARSEG(x(0)) and PEEK(VARPTR(x(0)) + i)
'   * Byte order, two's complement, IEEE floating point
'   * Building an INTEGER from bytes with POKE
'
' THINGS TO TRY
'   * Dump a DOUBLE array (8 bytes per element)
'   * Dump a whole 10-element array and watch the elements line up
'   * Change one byte of a SINGLE with POKE and see what number appears
' ============================================================

DEFINT A-Z
DECLARE SUB Dump (label$, seg&, off&, nBytes)
DECLARE FUNCTION Bin8$ (b)

DIM ia(3) AS INTEGER, la(3) AS LONG, sa(3) AS SINGLE

CLS
PRINT "ARRAY MEMORY HEX VIEWER"
PRINT "Memory is listed from the LOWEST address to the highest."
DO
    PRINT
    LINE INPUT "Number to store (Q quits): "; t$
    t$ = UCASE$(LTRIM$(RTRIM$(t$)))
    IF t$ = "Q" OR t$ = "" THEN EXIT DO
    v# = VAL(t$)

    ' store in each array, if it fits that type
    IF v# = INT(v#) AND v# >= -32768 AND v# <= 32767 THEN
        ia(1) = v#
        Dump "INTEGER ia(1)", VARSEG(ia(0)), VARPTR(ia(1)), 2
    ELSE
        PRINT "  (does not fit an INTEGER: whole numbers -32768..32767)"
    END IF
    IF v# = INT(v#) AND ABS(v#) <= 2147483647# THEN
        la(1) = v#
        Dump "LONG    la(1)", VARSEG(la(0)), VARPTR(la(1)), 4
    END IF
    IF ABS(v#) < 1E+38 THEN
        sa(1) = v#
        Dump "SINGLE  sa(1)", VARSEG(sa(0)), VARPTR(sa(1)), 4
        ' decode the IEEE bits of the SINGLE: top byte holds sign + exponent
        DEF SEG = VARSEG(sa(0))
        o& = VARPTR(sa(1))
        b3 = PEEK(o& + 3): b2 = PEEK(o& + 2)
        DEF SEG
        sbit = b3 \ 128                              ' bit 31
        ex = (b3 AND 127) * 2 + b2 \ 128            ' bits 30..23
        PRINT "     sign bit ="; sbit; "  exponent ="; ex;
        IF ex > 0 THEN PRINT " -> times 2 ^"; ex - 127 ELSE PRINT " (zero/tiny)"
    END IF
LOOP

' ---- the other direction: build a number from bytes with POKE ----
PRINT
PRINT "POKE demo: writing bytes &H34 and &H12 into ia(2)..."
DEF SEG = VARSEG(ia(0))
POKE VARPTR(ia(2)), &H34          ' low byte first (little-endian)
POKE VARPTR(ia(2)) + 1, &H12      ' then the high byte
DEF SEG
PRINT "ia(2) is now"; ia(2); "= &H"; HEX$(ia(2)); "   (we never assigned it!)"
END

' Print nBytes bytes starting at seg:off as hex and binary.
SUB Dump (label$, seg&, off&, nBytes)
    PRINT "  "; label$; " @ "; HEX$(seg&); ":"; HEX$(off&); "  hex:";
    DEF SEG = seg&
    FOR i = 0 TO nBytes - 1
        PRINT " "; RIGHT$("0" + HEX$(PEEK(off& + i)), 2);
    NEXT i
    PRINT
    PRINT "     binary:";
    FOR i = 0 TO nBytes - 1
        PRINT " "; Bin8$(PEEK(off& + i));
    NEXT i
    PRINT
    DEF SEG                         ' always restore the default segment
END SUB

' 8-character binary string of one byte.
FUNCTION Bin8$ (b)
    s$ = ""
    FOR bit = 7 TO 0 STEP -1
        IF b AND 2 ^ bit THEN s$ = s$ + "1" ELSE s$ = s$ + "0"
    NEXT bit
    Bin8$ = s$
END FUNCTION
