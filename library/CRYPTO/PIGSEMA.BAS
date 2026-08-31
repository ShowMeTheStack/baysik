' ============================================================
' TITLE:    Pigpen & Semaphore Drawing Board
' CATEGORY: Codes & Cryptography
' LEVEL:    Intermediate
' TAGS:     pigpen, semaphore, graphics, SCREEN 12, LINE, CIRCLE, SIN, COS
' SUMMARY:  Draws your message in the Freemasons' pigpen cipher or as flag-waving semaphore signallers.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two "picture alphabets", drawn with BASIC graphics:
'
'   PIGPEN CIPHER (1700s; used by the Freemasons, and in the American
'   Civil War by prisoners).  Letters are written into two
'   noughts-and-crosses grids and two X shapes; the second grid and
'   X get a dot:
'
'        A | B | C      J.| K.| L.        \ S /       \ W. /
'       ---+---+---    ---+---+---      T  X  U     X.  X  .Y
'        D | E | F      M.| N.| O.        / V \       / Z. \
'       ---+---+---    ---+---+---
'        G | H | I      P.| Q.| R.
'
'   Each letter is drawn as the SHAPE OF THE PEN (the lines around
'   its cell).  E is a full square, A is just a corner (_|).
'
'   FLAG SEMAPHORE (1866 for ships; based on the 1790s Chappe
'   tower telegraph in France).  A signaller holds two flags; each
'   arm points in one of 8 directions, 45 degrees apart.  Letters
'   go round in "circles": A-G keep one arm down and move the other
'   all the way round, H-N keep one arm at the A position, etc.
'   Here the figures are drawn as seen by the person READING them.
'
' HOW TO USE
'   P = pigpen,  S = semaphore,  K = key chart for the current mode
'   T = type a new message,  Q or Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Drawing glyphs from rules instead of storing pictures
'   * Integer division and MOD to turn an index into row/column
'   * Pointing in a direction with SIN and COS (8 directions)
'   * Packing a table into a string of digit pairs
'
' THINGS TO TRY
'   * Invent your own pigpen layout (put the letters in different cells)
'   * Animate the semaphore figure moving its arms between letters
'   * Add the semaphore "numerals" sign (arms at C and G... look it up!)
' ============================================================

DECLARE SUB Pigpen (L%, x%, y%, s%)
DECLARE SUB Semaphore (L%, cx%, cy%)
DECLARE SUB ShowMessage (m$, mode%)
DECLARE SUB ShowKey (mode%)

' Semaphore arm directions for A..Z as digit pairs.
' 0=down 1=down-left 2=left 3=up-left 4=up 5=up-right 6=right 7=down-right
DIM SHARED sem$
sem$ = "01020304050607121346141516172324252627343547565736" + "67"
CONST PI = 3.14159265#

SCREEN 12
mode% = 0                          ' 0 = pigpen, 1 = semaphore
msg$ = "MEET ME AT MIDNIGHT"
showChart = 1
DO
    CLS
    COLOR 14
    IF mode% = 0 THEN PRINT " PIGPEN CIPHER" ELSE PRINT " FLAG SEMAPHORE"
    IF showChart THEN ShowKey mode% ELSE ShowMessage msg$, mode%
    COLOR 7
    LOCATE 30, 2: PRINT "P=pigpen  S=semaphore  K=key chart  T=type message  Q=quit";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    SELECT CASE k$
    CASE "Q", CHR$(27): EXIT DO
    CASE "P": mode% = 0: showChart = 0
    CASE "S": mode% = 1: showChart = 0
    CASE "K": showChart = 1
    CASE "T"
        LOCATE 30, 1: PRINT SPACE$(79);
        LOCATE 30, 2: LINE INPUT "Message: "; t$
        IF t$ <> "" THEN msg$ = UCASE$(LEFT$(t$, 60))
        showChart = 0
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

' ------------------------------------------------------------
' Pigpen: draw letter L% (0=A .. 25=Z) in a box of size s% with
' top-left corner (x%, y%).
'   Grid letters A-R (0-17): cell = L MOD 9 gives the position in
'   the 3x3 grid, row = cell \ 3, col = cell MOD 3.  A cell has a
'   wall on each side that faces ANOTHER cell: top wall if it is
'   not in the top row, left wall if not in the left column, etc.
'   X letters S-Z (18-25): one of four V-shaped wedges.
'   Letters J-R and W-Z also get a dot.
' ------------------------------------------------------------
SUB Pigpen (L%, x%, y%, s%)
    h = s% \ 2: c = 15
    IF L% < 18 THEN
        cell = L% MOD 9
        r = cell \ 3: k = cell MOD 3
        IF r > 0 THEN LINE (x%, y%)-(x% + s%, y%), c
        IF r < 2 THEN LINE (x%, y% + s%)-(x% + s%, y% + s%), c
        IF k > 0 THEN LINE (x%, y%)-(x%, y% + s%), c
        IF k < 2 THEN LINE (x% + s%, y%)-(x% + s%, y% + s%), c
        dx = h: dy = h
        dotted = (L% >= 9)
    ELSE
        w = (L% - 18) MOD 4
        SELECT CASE w
        CASE 0  ' top wedge: a V
            LINE (x%, y%)-(x% + h, y% + s%), c: LINE -(x% + s%, y%), c
            dx = h: dy = s% \ 3
        CASE 1  ' left wedge: >
            LINE (x%, y%)-(x% + s%, y% + h), c: LINE -(x%, y% + s%), c
            dx = s% \ 3: dy = h
        CASE 2  ' right wedge: <
            LINE (x% + s%, y%)-(x%, y% + h), c: LINE -(x% + s%, y% + s%), c
            dx = s% - s% \ 3: dy = h
        CASE 3  ' bottom wedge: an upside-down V
            LINE (x%, y% + s%)-(x% + h, y%), c: LINE -(x% + s%, y% + s%), c
            dx = h: dy = s% - s% \ 3
        END SELECT
        dotted = (L% >= 22)
    END IF
    IF dotted THEN
        CIRCLE (x% + dx, y% + dy), 3, 12
        PAINT (x% + dx, y% + dy), 12, 12
    END IF
END SUB

' ------------------------------------------------------------
' Semaphore: a stick figure centred at (cx%, cy%) holding two
' flags.  Direction d becomes an angle a = d * 45 degrees measured
' from "straight down", turning clockwise as seen by the viewer:
'     dx = -SIN(a),  dy = COS(a)     (screen y grows downwards)
' d=0 -> (0, 1) down,  d=2 -> (-1, 0) left,  d=4 -> (0, -1) up.
' ------------------------------------------------------------
SUB Semaphore (L%, cx%, cy%)
    ' Body: head, trunk, legs.
    CIRCLE (cx%, cy% - 20), 6, 14
    LINE (cx%, cy% - 14)-(cx%, cy% + 10), 14
    LINE (cx%, cy% + 10)-(cx% - 7, cy% + 26), 14
    LINE (cx%, cy% + 10)-(cx% + 7, cy% + 26), 14
    IF L% < 0 OR L% > 25 THEN EXIT SUB      ' space: arms resting
    FOR arm = 1 TO 2
        d = VAL(MID$(sem$, L% * 2 + arm, 1))
        a# = d * 45 * PI / 180
        ex = cx% - SIN(a#) * 24: ey = (cy% - 8) + COS(a#) * 24
        LINE (cx%, cy% - 8)-(ex, ey), 15
        ' The flag: a small square split red / yellow diagonally,
        ' like real semaphore flags.
        fx = cx% - SIN(a#) * 30: fy = (cy% - 8) + COS(a#) * 30
        LINE (fx - 5, fy - 5)-(fx + 5, fy + 5), 12, BF
        FOR t = 0 TO 10
            LINE (fx - 5 + t, fy - 5 + t)-(fx + 5, fy - 5 + t), 14
        NEXT t
    NEXT arm
END SUB

' ------------------------------------------------------------
' ShowKey: all 26 letters with their symbols, 9 per row.
' ------------------------------------------------------------
SUB ShowKey (mode%)
    COLOR 7: LOCATE 2, 2: PRINT "Key chart - every letter of the alphabet:"
    FOR L% = 0 TO 25
        col = L% MOD 9: row = L% \ 9
        x% = 30 + col * 68: y% = 70 + row * 130
        IF mode% = 0 THEN
            Pigpen L%, x% + 10, y% + 10, 34
        ELSE
            Semaphore L%, x% + 27, y% + 40
        END IF
        COLOR 11: LOCATE (y% + 90) \ 16 + 1, (x% + 27) \ 8 + 1: PRINT CHR$(65 + L%);
    NEXT L%
END SUB

' ------------------------------------------------------------
' ShowMessage: draw the message, wrapping into rows.  Letters
' are labelled underneath so you can check your reading.
' ------------------------------------------------------------
SUB ShowMessage (m$, mode%)
    COLOR 7: LOCATE 2, 2: PRINT "Message: "; m$
    IF mode% = 0 THEN stepX = 44: stepY = 80 ELSE stepX = 64: stepY = 112
    x% = 20: y% = 60
    FOR i = 1 TO LEN(m$)
        ch$ = MID$(m$, i, 1)
        L% = ASC(ch$) - 65
        IF L% >= 0 AND L% <= 25 THEN
            IF mode% = 0 THEN Pigpen L%, x%, y%, 30 ELSE Semaphore L%, x% + 25, y% + 40
            COLOR 11
            IF mode% = 0 THEN LOCATE (y% + 40) \ 16 + 1, (x% + 15) \ 8 + 1 ELSE LOCATE (y% + 92) \ 16 + 1, (x% + 25) \ 8 + 1
            PRINT ch$;
        END IF
        ' Spaces still take room, so words stay apart.
        IF L% >= 0 AND L% <= 25 OR ch$ = " " THEN x% = x% + stepX
        ' Word wrap: after a space, measure the next word.  If it
        ' would run off the right edge, start a new row now.
        IF ch$ = " " THEN
            nextSp = INSTR(i + 1, m$ + " ", " ")
            IF x% + (nextSp - i - 1) * stepX > 630 THEN x% = 20: y% = y% + stepY
        END IF
        IF x% > 600 THEN x% = 20: y% = y% + stepY
        ' Stop when the next row would not fit above the menu line.
        IF y% + stepY > 470 THEN EXIT FOR
    NEXT i
END SUB
