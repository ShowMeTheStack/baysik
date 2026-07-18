' ============================================================
' TITLE:    Text-Mode Analog Clock
' CATEGORY: Console & Text
' LEVEL:    Advanced
' TAGS:     clock, trigonometry, sin, cos, aspect ratio, time$
' SUMMARY:  A round clock face with moving hour, minute and second hands drawn entirely out of text characters.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws a classic clock face in text mode and moves the hands in
'   real time.  The interesting problems are:
'     * Text cells are about twice as tall as they are wide, so a
'       "circle" must be twice as wide in columns as in rows.
'     * A hand is a line from the centre at some angle.  We walk
'       along it in small steps and pick a character that matches
'       the direction:  |  /  -  \
'     * The hands must be erased before they are drawn in a new
'       position, without wiping the numbers on the face.
'
' HOW TO USE
'   Watch the time go by.  Esc or Q quits.  F toggles a "fast"
'   demo mode where the clock races forward.
'
' CONCEPTS YOU WILL LEARN
'   * Angles in radians, SIN and COS to go round a circle
'   * Correcting for the aspect ratio of text cells
'   * Choosing a character from an angle
'   * Erase-then-redraw animation using saved point lists
'
' THINGS TO TRY
'   * Add tick marks for every minute between the numbers.
'   * Show a second clock for another time zone.
'   * Draw the second hand with a little circle on the end.
' ============================================================

DEFINT A-Z
DECLARE SUB Hand (angle!, length!, ch$, colr, idx)
DECLARE SUB EraseHand (idx)
DECLARE FUNCTION DirChar$ (angle!)

CONST CR = 13, CC = 40          ' centre of the clock face (row, column)
CONST RY = 11                   ' radius in rows
CONST ASPECT = 2.1              ' columns per row: cells are tall & thin
CONST PI = 3.14159265#

' Each hand remembers which cells it drew so it can erase them later.
' hr(), hc() = rows and columns of hand idx, hn(idx) = how many.
DIM SHARED hr(1 TO 3, 1 TO 40), hc(1 TO 3, 1 TO 40), hn(1 TO 3)

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
LOCATE , , 0

' ---- The face --------------------------------------------------
' Rim: a ring of dots.  Angle 0 = 12 o'clock, increasing clockwise,
' so: column = centre + SIN(a) * radius * aspect
'     row    = centre - COS(a) * radius   (rows grow DOWNwards)
COLOR 8
FOR i = 0 TO 119
    a! = i * 2 * PI / 120
    LOCATE CR - CINT(COS(a!) * (RY + 1)), CC + CINT(SIN(a!) * (RY + 1) * ASPECT)
    PRINT CHR$(250);
NEXT i
' The numbers 1..12
COLOR 14
FOR h = 1 TO 12
    a! = h * 2 * PI / 12
    n$ = LTRIM$(STR$(h))
    LOCATE CR - CINT(COS(a!) * RY), CC + CINT(SIN(a!) * RY * ASPECT) - (LEN(n$) - 1)
    PRINT n$;
NEXT h
COLOR 15: LOCATE 1, 2: PRINT "ANALOG CLOCK";
COLOR 8: LOCATE 25, 2: PRINT "F = fast mode   Esc = quit";

fast = 0: fakeSec& = 0
last$ = ""
DO
    IF fast THEN
        ' Fast mode: a pretend clock that moves 1 minute per frame.
        fakeSec& = (fakeSec& + 60) MOD 43200
        hh = fakeSec& \ 3600: mm = (fakeSec& \ 60) MOD 60: ss = fakeSec& MOD 60
        t$ = "fast"
        tm! = TIMER: DO WHILE TIMER - tm! < .05 AND TIMER >= tm!: LOOP
    ELSE
        t$ = TIME$
        hh = VAL(LEFT$(t$, 2)): mm = VAL(MID$(t$, 4, 2)): ss = VAL(RIGHT$(t$, 2))
    END IF

    IF t$ <> last$ OR fast THEN
        last$ = t$
        ' Angles (radians, clockwise from 12):
        '   second hand: 60 seconds = full circle
        '   minute hand: also moves a little with the seconds
        '   hour hand  : 12 hours = full circle, plus the minutes
        aS! = ss * 2 * PI / 60
        aM! = (mm + ss / 60) * 2 * PI / 60
        aH! = ((hh MOD 12) + mm / 60) * 2 * PI / 12

        FOR i = 1 TO 3: EraseHand i: NEXT i
        ' Draw the longest first so the shorter, thicker hands end up on top.
        Hand aS!, RY - 1.5, "", 12, 3
        Hand aM!, RY - 2.5, "", 15, 2
        Hand aH!, RY - 5, CHR$(219), 11, 1
        COLOR 14: LOCATE CR, CC: PRINT CHR$(15);  ' the centre pin (not CHR$(9): that is TAB!)

        ' Digital time too, under the face.  RIGHT$("0" + ...) adds a
        ' leading zero so 9 shows as 09.
        COLOR 7
        LOCATE 25, 60: PRINT RIGHT$("0" + LTRIM$(STR$(hh)), 2); ":"; RIGHT$("0" + LTRIM$(STR$(mm)), 2); ":"; RIGHT$("0" + LTRIM$(STR$(ss)), 2);
    END IF

    k$ = UCASE$(INKEY$)
    IF k$ = "F" THEN fast = 1 - fast: fakeSec& = CLNG(hh) * 3600 + mm * 60
    IF k$ = CHR$(27) OR k$ = "Q" THEN EXIT DO
LOOP
COLOR 7, 0: CLS
LOCATE , , 1
END

' Choose a character that looks like a line in this direction.
' We fold the angle into 0..PI (a line looks the same both ways)
' and split it into 4 sectors of 45 degrees each.
FUNCTION DirChar$ (angle!)
    a! = angle!
    DO WHILE a! >= PI: a! = a! - PI: LOOP
    sector = INT((a! + PI / 8) / (PI / 4)) MOD 4
    SELECT CASE sector
        CASE 0: DirChar$ = "|"        ' pointing up/down
        CASE 1: DirChar$ = "/"        ' up-right / down-left
        CASE 2: DirChar$ = "-"        ' left/right
        CASE 3: DirChar$ = "\"        ' down-right / up-left
    END SELECT
END FUNCTION

' Put back whatever was under hand idx: the face only has dots and
' numbers near the rim, and the hands stay inside, so a space is right.
SUB EraseHand (idx)
    FOR i = 1 TO hn(idx)
        LOCATE hr(idx, i), hc(idx, i): PRINT " ";
    NEXT i
    hn(idx) = 0
END SUB

' Draw a hand from the centre outwards.  If ch$ is "" the character
' is chosen from the direction.  We take small steps (0.5 rows) and
' only draw each cell once.
SUB Hand (angle!, length!, ch$, colr, idx)
    IF ch$ = "" THEN c$ = DirChar$(angle!) ELSE c$ = ch$
    COLOR colr
    s! = .8
    DO WHILE s! <= length!
        r = CR - CINT(COS(angle!) * s!)
        c = CC + CINT(SIN(angle!) * s! * ASPECT)
        ' skip if this is the same cell as the previous step
        dup = 0
        IF hn(idx) > 0 THEN
            IF hr(idx, hn(idx)) = r AND hc(idx, hn(idx)) = c THEN dup = 1
        END IF
        IF dup = 0 AND hn(idx) < 40 THEN
            hn(idx) = hn(idx) + 1
            hr(idx, hn(idx)) = r: hc(idx, hn(idx)) = c
            LOCATE r, c: PRINT c$;
        END IF
        s! = s! + .5
    LOOP
END SUB
