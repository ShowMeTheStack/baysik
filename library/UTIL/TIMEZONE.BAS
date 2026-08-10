' ============================================================
' TITLE:    World Time Zone Table
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     time, time$, utc, offsets, tables, meeting planner
' SUMMARY:  Shows the current time in cities around the world and a 24-hour meeting planner grid.
' ------------------------------------------------------------
' WHAT IT DOES
'   You tell it your own UTC offset (for example -5 for New York
'   in winter, +1 for Paris, +5.5 for India).  It reads the clock
'   with TIME$, converts it to UTC (Coordinated Universal Time),
'   and then to each city's local time.  It also tells you if the
'   other city is already "tomorrow" or still "yesterday".
'
'   Page 2 is a MEETING PLANNER: a grid of 24 hours for every
'   city, with office hours (9-17) coloured green and night time
'   dark, so you can spot an hour that suits everyone.
'
'   (Daylight-saving time is ignored to keep things simple - the
'   offsets are "standard" time.)
'
' HOW TO USE
'   Type your UTC offset first.
'   T = live time table   M = meeting planner   Q / Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Converting HH:MM:SS to minutes and back
'   * Wrapping around midnight with MOD 1440 (minutes per day)
'   * Half-hour offsets (India +5:30, Newfoundland -3:30)
'   * Colour-coded tables with COLOR and LOCATE
'
' THINGS TO TRY
'   * Add your own city to the DATA list.
'   * Add a column showing the time difference from you.
'   * Draw little clock faces with CIRCLE in a graphics mode.
' ============================================================

DECLARE FUNCTION HM$ (mins%)

CONST NCITY = 12
DIM city$(1 TO NCITY), off!(1 TO NCITY)
FOR i = 1 TO NCITY: READ city$(i), off!(i): NEXT i
DATA "Honolulu",-10, "Los Angeles",-8, "New York",-5, "Sao Paulo",-3
DATA "London",0, "Paris",1, "Cairo",2, "Moscow",3
DATA "Mumbai",5.5, "Beijing",8, "Tokyo",9, "Sydney",10

CLS
COLOR 11: PRINT "WORLD TIME ZONES": COLOR 7
PRINT
INPUT "Your UTC offset in hours (e.g. -5, 0, 5.5): ", myOff!
IF myOff! < -12 OR myOff! > 14 THEN myOff! = 0
page$ = "T"

DO
    ' ---- Work out UTC in minutes since midnight ----
    t$ = TIME$
    localMin% = VAL(LEFT$(t$, 2)) * 60 + VAL(MID$(t$, 4, 2))
    ' UTC = local - offset.  +1440 then MOD 1440 keeps it in 0..1439.
    utcMin% = (localMin% - INT(myOff! * 60) + 2880) MOD 1440

    IF page$ = "T" THEN
        CLS
        COLOR 15, 1: PRINT SPACE$(80);: LOCATE 1, 30: PRINT "WORLD CLOCK  (local "; t$; ")": COLOR 7, 0
        LOCATE 3, 10: PRINT "City            UTC offset    Local time"
        LOCATE 4, 10: PRINT STRING$(55, "-")
        FOR i = 1 TO NCITY
            ' raw = minutes in that city, may be <0 or >=1440
            raw% = utcMin% + INT(off!(i) * 60)
            ' Which DAY is it there compared with here?  Both raw% and
            ' myRaw% are minutes counted from the same UTC midnight.
            ' INT(x / 1440) gives the day number (-1, 0 or 1) - INT
            ' rounds DOWN, even for negative numbers, which is what
            ' we need here.
            myRaw% = utcMin% + INT(myOff! * 60)
            dayShift% = INT(raw% / 1440) - INT(myRaw% / 1440)
            cm% = (raw% + 2880) MOD 1440
            hour% = cm% \ 60
            ' night = before 7am or after 10pm
            IF hour% < 7 OR hour% >= 22 THEN COLOR 9 ELSE COLOR 14
            LOCATE 5 + i, 10: PRINT city$(i);
            LOCATE 5 + i, 26: PRINT USING "UTC+##.#"; off!(i);
            LOCATE 5 + i, 40: PRINT HM$(cm%);
            IF dayShift% > 0 THEN PRINT "  (tomorrow)";
            IF dayShift% < 0 THEN PRINT "  (yesterday)";
            COLOR 7
        NEXT i
        LOCATE 20, 10: PRINT "Blue = night time.   M = meeting planner   Q = quit"
    ELSEIF page$ = "M" THEN
        CLS
        COLOR 15, 1: PRINT SPACE$(80);: LOCATE 1, 25: PRINT "MEETING PLANNER (by YOUR hour)": COLOR 7, 0
        ' Header: your local hours 0..23, two characters + 1 gap each,
        ' starting at column 10, so the last one ends at column 80.
        LOCATE 3, 1: PRINT "You:";
        FOR h = 0 TO 23
            LOCATE 3, 10 + h * 3: PRINT RIGHT$(" " + LTRIM$(STR$(h)), 2);
        NEXT h
        FOR i = 1 TO NCITY
            LOCATE 4 + i, 1: PRINT LEFT$(city$(i), 8);   ' 8 letters + a gap before column 10
            FOR h = 0 TO 23
                ' that city's hour when it is h o'clock for you
                cm% = (h * 60 - INT(myOff! * 60) + INT(off!(i) * 60) + 2880) MOD 1440
                ch% = cm% \ 60
                IF ch% >= 9 AND ch% < 17 THEN
                    COLOR 0, 2               ' office hours: green
                ELSEIF ch% >= 7 AND ch% < 22 THEN
                    COLOR 0, 3               ' awake: cyan
                ELSE
                    COLOR 7, 0               ' asleep
                END IF
                LOCATE 4 + i, 10 + h * 3: PRINT RIGHT$(" " + LTRIM$(STR$(ch%)), 2);
                COLOR 7, 0
            NEXT h
        NEXT i
        LOCATE 19, 1: PRINT "Green = office hours (9-17), cyan = awake, black = asleep."
        LOCATE 20, 1: PRINT "Look for a column that is green for everyone you need!"
        LOCATE 22, 1: PRINT "T = time table   Q = quit"
    END IF

    ' Wait for a key, but refresh the table every 5 seconds.
    t0! = TIMER
    DO
        k$ = UCASE$(INKEY$)
    LOOP WHILE k$ = "" AND ABS(TIMER - t0!) < 5
    IF k$ = "T" OR k$ = "M" THEN page$ = k$
LOOP UNTIL k$ = "Q" OR k$ = CHR$(27)
CLS
END

' minutes since midnight -> "HH:MM"
FUNCTION HM$ (mins%)
    h% = mins% \ 60: m% = mins% MOD 60
    HM$ = RIGHT$("0" + LTRIM$(STR$(h%)), 2) + ":" + RIGHT$("0" + LTRIM$(STR$(m%)), 2)
END FUNCTION
