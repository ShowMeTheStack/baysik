' ============================================================
' TITLE:    System Info: FRE, COMMAND$ and the BIOS Data Area
' CATEGORY: System, Events & Hardware
' LEVEL:    Beginner
' TAGS:     fre, command$, peek, bios data area, memory, screen modes
' SUMMARY:  A "system information" report: free memory with FRE, command-line arguments, and video facts PEEKed from the BIOS.
' ------------------------------------------------------------
' WHAT IT DOES
'   Old DOS utilities loved printing system reports.  This one shows:
'     * FRE(""), FRE(-1), FRE(-2): free string space, free far memory,
'       and free stack space - and how they change when you allocate
'       a big string or array and then free it again with ERASE.
'     * COMMAND$: whatever was typed after the program name on the DOS
'       command line (e.g.  QBASIC /RUN SYSINFO.BAS hello world).
'     * The BIOS data area at segment 0, which records the current video
'       mode (0:449), screen columns (0:44A) and last row (0:484).
'
' HOW TO USE
'   Just run it and read.  Press a key to switch screen modes during
'   the BIOS part, Esc to quit early.
'
' CONCEPTS YOU WILL LEARN
'   * FRE with its different arguments
'   * Dynamic arrays ('$DYNAMIC / REDIM) and ERASE to give memory back
'   * Splitting COMMAND$ into words
'   * PEEKing BIOS variables to ask the hardware what it is doing
'
' THINGS TO TRY
'   * Watch FRE("") while building a 20,000-character string in a loop
'   * Make your program accept options like /FAST from COMMAND$
'   * PEEK(&H410) holds the "equipment list" bits on a real PC
' ============================================================

DEFINT A-Z
'$DYNAMIC
DECLARE SUB Header (t$)

CLS
Header "MEMORY (FRE)"
q2$ = CHR$(34) + CHR$(34)            ' two quote marks, to print FRE("")
PRINT "Free string space   FRE(" + q2$ + ")  ="; FRE("")
PRINT "Largest free block  FRE(-1)  ="; FRE(-1)
PRINT "Free stack space    FRE(-2)  ="; FRE(-2)
PRINT
big$ = STRING$(20000, "x")           ' grab 20,000 bytes of string space
PRINT "After making a 20,000 character string: FRE(" + q2$ + ") ="; FRE("")
big$ = ""                            ' release it again
PRINT "After big$ = " + q2$ + ":                       FRE(" + q2$ + ") ="; FRE("")
REDIM table#(5000)                   ' 5001 DOUBLEs = about 40 KB
PRINT "After REDIM table#(5000):  FRE(-1) ="; FRE(-1)
ERASE table#                         ' dynamic arrays can be freed
PRINT "After ERASE table#:        FRE(-1) ="; FRE(-1)
PRINT "(Some BASICs report a fixed figure here - real DOS numbers move!)"

PRINT
Header "COMMAND LINE (COMMAND$)"
cl$ = COMMAND$
IF cl$ = "" THEN
    PRINT "No arguments were given.  In DOS you could type:"
    PRINT "   QBASIC /RUN SYSINFO.BAS HELLO WORLD"
    PRINT "Using a pretend command line for the demo:"
    cl$ = "HELLO WORLD /FAST"
END IF
PRINT "COMMAND$ = "; CHR$(34); cl$; CHR$(34)
' split into words at spaces
n = 0: w$ = ""
FOR i = 1 TO LEN(cl$) + 1
    c$ = MID$(cl$, i, 1)
    IF c$ = " " OR c$ = "" THEN
        IF w$ <> "" THEN
            n = n + 1
            PRINT "   word"; n; ": "; w$;
            IF LEFT$(w$, 1) = "/" THEN PRINT "   <- an option switch" ELSE PRINT
            w$ = ""
        END IF
    ELSE
        w$ = w$ + c$
    END IF
NEXT i

PRINT
PRINT "Press a key for the BIOS video report."
DO: k$ = INKEY$: LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN END

' ---- BIOS data area: ask the "hardware" what mode we are in ---------
FOR m = 1 TO 4
    SELECT CASE m
        CASE 1: SCREEN 0: WIDTH 80, 25
        CASE 2: SCREEN 0: WIDTH 40, 25
        CASE 3: SCREEN 0: WIDTH 80, 50
        CASE 4: SCREEN 13
    END SELECT
    DEF SEG = 0
    vm = PEEK(&H449): cols = PEEK(&H44A): lastRow = PEEK(&H484)
    DEF SEG
    CLS
    PRINT "BIOS video report"
    PRINT "0:449 video mode = &H"; HEX$(vm)
    PRINT "0:44A columns    ="; cols
    PRINT "0:484 rows - 1   ="; lastRow
    PRINT
    PRINT "Key = next mode, Esc = quit"
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT m
SCREEN 0: WIDTH 80, 25
PRINT "System report complete."
END

SUB Header (t$)
    COLOR 14: PRINT t$: PRINT STRING$(LEN(t$), 196): COLOR 7
END SUB
