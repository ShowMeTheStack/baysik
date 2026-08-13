' ============================================================
' TITLE:    BIOS Tick Counter Reaction Test
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     peek, bios, timer, ticks, 18.2 hz, reaction game
' SUMMARY:  Read the BIOS clock-tick counter at 0:046C directly and use it to time your reflexes.
' ------------------------------------------------------------
' WHAT IT DOES
'   A chip on the PC motherboard (the 8253 timer) interrupts the CPU
'   about 18.2 times per second.  Each time, the BIOS adds one to a
'   4-byte counter at memory address 0000:046C.  At midnight it goes
'   back to zero.  BASIC's TIMER function is really this counter
'   divided by 18.2!
'   The program first shows the counter ticking, then runs a reaction
'   test: wait for the screen to turn green and hit a key as fast as
'   you can.  Your time is measured in ticks (1 tick = about 55 ms).
'
' HOW TO USE
'   Press a key to start each round, then wait for GREEN and press
'   any key.  Pressing too early is a false start!  5 rounds.
'   Esc quits at any prompt.
'
' CONCEPTS YOU WILL LEARN
'   * Building a LONG from 4 bytes:  b0 + b1*256 + b2*65536 + b3*16777216
'   * Little-endian byte order (lowest byte first)
'   * The 18.2065 Hz system clock (1193182 / 65536)
'   * Comparing PEEKed ticks with TIMER
'
' THINGS TO TRY
'   * Keep a best-score table
'   * Busy-wait for exactly 1 tick and count how many loops your
'     computer manages in that time
'   * Work out what time it is from the tick count alone
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Ticks& ()
CONST TPS = 18.2065            ' ticks per second

CLS
PRINT "THE BIOS TICK COUNTER  (0000:046C)"
PRINT STRING$(50, 196)
PRINT "Watch the four bytes change.  Press any key to continue."
PRINT
PRINT "  Byte 46C  46D  46E  46F    Ticks       Ticks/18.2    TIMER"
DO
    t& = Ticks&
    DEF SEG = 0
    LOCATE 6, 8
    FOR a = &H46C TO &H46F
        PRINT USING "###  "; PEEK(a);
    NEXT a
    DEF SEG
    PRINT USING "##########   #####.##    #####.##"; t&; t& / TPS; TIMER
    k$ = INKEY$
LOOP WHILE k$ = ""
IF k$ = CHR$(27) THEN END

' ---------------- the reaction game -----------------------------------
RANDOMIZE TIMER
total& = 0: rounds = 0
FOR round = 1 TO 5
    COLOR 7, 0: CLS
    PRINT "ROUND"; round; "of 5  -  press a key when the screen turns GREEN."
    PRINT "(press a key to begin)"
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT FOR

    COLOR 15, 4: CLS
    LOCATE 12, 35: PRINT "WAIT...";
    ' wait a random 20..70 ticks (about 1 to 4 seconds)
    target& = Ticks& + 20 + INT(RND * 50)
    early = 0
    DO
        IF INKEY$ <> "" THEN early = 1: EXIT DO
    LOOP WHILE Ticks& < target& AND Ticks& >= target& - 100

    IF early THEN
        COLOR 15, 0: CLS
        PRINT "FALSE START!  You pressed too early."
    ELSE
        COLOR 0, 2: CLS
        LOCATE 12, 36: PRINT "NOW!";
        start& = Ticks&
        DO: k$ = INKEY$: LOOP WHILE k$ = "" AND Ticks& - start& < 200
        took& = Ticks& - start&
        COLOR 15, 0: CLS
        PRINT "Reaction:"; took&; "ticks ="; INT(took& / TPS * 1000); "milliseconds"
        total& = total& + took&: rounds = rounds + 1
    END IF
    PRINT : PRINT "(press a key)"
    DO: k$ = INKEY$: LOOP WHILE k$ = ""
    IF k$ = CHR$(27) THEN EXIT FOR
NEXT round

COLOR 7, 0: CLS
IF rounds > 0 THEN
    avg! = total& / rounds
    PRINT USING "Average over # rounds: ##.# ticks = #### ms"; rounds; avg!; avg! / TPS * 1000
    IF avg! < 5 THEN PRINT "Lightning reflexes!" ELSE PRINT "Keep practising!"
ELSE
    PRINT "No valid rounds played."
END IF
END

' Read the 4-byte little-endian counter at 0:046C as one LONG number.
FUNCTION Ticks&
    DEF SEG = 0
    b0& = PEEK(&H46C): b1& = PEEK(&H46D): b2& = PEEK(&H46E)
    DEF SEG
    ' (byte 46F is always 0 because a day has only 1,573,040 ticks)
    Ticks& = b0& + b1& * 256 + b2& * 65536
END FUNCTION
