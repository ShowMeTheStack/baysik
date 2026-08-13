' ============================================================
' TITLE:    Where Do Variables Live? (VARPTR, VARSEG, SADD)
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     varptr, varseg, sadd, varptr$, memory, addresses, draw, play
' SUMMARY:  Ask BASIC for the memory addresses of variables and array elements, and use VARPTR$ inside DRAW and PLAY.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every variable sits somewhere in memory.  On a PC a memory address
'   has two parts, SEGMENT:OFFSET (real address = segment*16 + offset).
'     VARSEG(v)  - the segment of variable v
'     VARPTR(v)  - the offset of variable v inside that segment
'     SADD(s$)   - the offset of the TEXT of string s$
'     VARPTR$(v) - a 3-byte "pointer string" for use inside DRAW/PLAY
'   Part 1 prints addresses of simple variables.
'   Part 2 shows that array elements sit side by side, and that the
'   gap between neighbours is exactly the size of the type:
'   INTEGER 2 bytes, LONG 4, SINGLE 4, DOUBLE 8.
'   Part 3 passes numbers into DRAW and PLAY with VARPTR$ - the old
'   GW-BASIC way to put variables into those mini-languages.
'
' HOW TO USE
'   Press a key between parts.  Esc quits.
'
' CONCEPTS YOU WILL LEARN
'   * Segment:offset addressing
'   * Type sizes, measured by subtracting addresses
'   * Arrays are contiguous ("side by side") in memory
'   * DRAW "TA=" + VARPTR$(angle)   and   PLAY "N=" + VARPTR$(note)
'
' THINGS TO TRY
'   * Measure a TYPE ... END TYPE record size the same way
'   * Check whether a 2-D array is stored row-first or column-first
'   * Note: exact addresses differ between BASIC versions and runs -
'     only the DIFFERENCES are meaningful
' ============================================================

DEFINT A-Z
DECLARE SUB WaitKey ()
DIM iA(4) AS INTEGER, lA(4) AS LONG, sA(4) AS SINGLE, dA(4) AS DOUBLE

' ---- PART 1: simple variables ------------------------------------
CLS
PRINT "PART 1 - addresses of simple variables (segment:offset)"
PRINT STRING$(60, 196)
count% = 7: big& = 100000: money! = 9.99: pi# = 3.14159265#
msg$ = "Hello"
PRINT "count%   VARSEG ="; VARSEG(count%); "  VARPTR ="; VARPTR(count%)
PRINT "big&     VARSEG ="; VARSEG(big&); "  VARPTR ="; VARPTR(big&)
PRINT "money!   VARSEG ="; VARSEG(money!); "  VARPTR ="; VARPTR(money!)
PRINT "pi#      VARSEG ="; VARSEG(pi#); "  VARPTR ="; VARPTR(pi#)
PRINT "msg$     VARPTR (descriptor) ="; VARPTR(msg$); "  SADD (text) ="; SADD(msg$)
PRINT
PRINT "A string variable is a small DESCRIPTOR (length + pointer);"
PRINT "SADD gives the address of the characters themselves."
WaitKey

' ---- PART 2: arrays are packed side by side ---------------------
CLS
PRINT "PART 2 - array elements and the size of each type"
PRINT STRING$(60, 196)
PRINT "Element    INTEGER     LONG      SINGLE     DOUBLE"
FOR i = 0 TO 4
    PRINT USING "  ##     ######    ######    ######    ######"; i; VARPTR(iA(i)); VARPTR(lA(i)); VARPTR(sA(i)); VARPTR(dA(i))
NEXT i
PRINT
PRINT "Gap between neighbours (bytes per element):"
PRINT "  INTEGER:"; VARPTR(iA(1)) - VARPTR(iA(0))
PRINT "  LONG   :"; VARPTR(lA(1)) - VARPTR(lA(0))
PRINT "  SINGLE :"; VARPTR(sA(1)) - VARPTR(sA(0))
PRINT "  DOUBLE :"; VARPTR(dA(1)) - VARPTR(dA(0))
PRINT
PRINT "Whole INTEGER array iA(0..4) uses"; VARPTR(iA(4)) - VARPTR(iA(0)) + 2; "bytes."
PRINT "Its segment is &H"; HEX$(VARSEG(iA(0))); " - see PEEKARR.BAS to read those bytes!"
WaitKey

' ---- PART 3: VARPTR$ inside DRAW and PLAY ------------------------
SCREEN 12
PRINT "PART 3 - VARPTR$ passes variables into DRAW and PLAY"
PRINT "A star drawn with DRAW " + CHR$(34) + "TA=" + CHR$(34) + " + VARPTR$(angle)"
FOR angle = 0 TO 359 STEP 10
    ' TA= turns the pen to an angle held in a variable.  Today you
    ' could also write "TA" + STR$(angle); VARPTR$ was the GW-BASIC way.
    DRAW "BM320,260 C" + STR$(9 + (angle \ 10) MOD 7) + " TA=" + VARPTR$(angle) + " U120"
NEXT angle
PRINT "Now a scale played with PLAY " + CHR$(34) + "N=" + CHR$(34) + " + VARPTR$(note)"
FOR note = 37 TO 49
    PLAY "L16 N=" + VARPTR$(note)        ' N = note number 0..84
    LOCATE 4, 1: PRINT "note number"; note
NEXT note
LOCATE 28, 1: PRINT "Press a key to finish."
WaitKey
SCREEN 0: WIDTH 80
PRINT "Done exploring memory addresses."
END

SUB WaitKey
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN SCREEN 0: WIDTH 80: END
END SUB
