' ============================================================
' TITLE:    Random Circle Packing
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     generative art, geometry, distance, random, SCREEN 12
' SUMMARY:  Drop random circles that grow until they touch a neighbour, filling the screen with bubbles of every size.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick a random point.  If it is inside a circle that already
'   exists, try again.  Otherwise, find the distance to the NEAREST
'   existing circle (and to the screen edges): that is the biggest
'   radius a new circle can have without overlapping anything.
'   Draw it, and repeat.  Early circles are big; later ones squeeze
'   into the gaps and get smaller and smaller - a fractal-like
'   distribution called an "Apollonian-style" packing.
'
'   Two shapes for the area to pack: the whole screen, or a big
'   circle (so it looks like a bowl of soap bubbles).
'
' HOW TO USE
'   Space  start again        S  switch screen / circle area
'   Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * Distance between two points: SQR(dx^2 + dy^2)
'   * Distance from a point to a circle's edge: distance - radius
'   * "Rejection sampling": keep trying random points until one fits
'   * Parallel arrays to store many circles (x(), y(), r())
'
' THINGS TO TRY
'   * Set MAXR to 20 for a more even "foam"
'   * Color the circles by size instead of randomly
'   * Leave a 2-pixel gap between circles (subtract 2 from the radius)
' ============================================================
DEFINT I-N
CONST MAXC = 600            ' maximum number of circles
CONST MAXR = 90             ' biggest radius allowed
CONST MINR = 2              ' smaller than this is not worth drawing
DIM cx(MAXC), cy(MAXC), cr(MAXC)

SCREEN 12
RANDOMIZE TIMER
shape = 1                   ' 1 = whole screen, 2 = inside a big circle

DO
    CLS
    n = 0: fails = 0
    IF shape = 2 THEN CIRCLE (320, 240), 230, 8
    k$ = ""
    ' Stop after many failed tries in a row: the space is full.
    DO WHILE n < MAXC AND fails < 2000
        x! = RND * 640: y! = RND * 470
        ' Start with the largest radius the border allows.
        IF shape = 1 THEN
            best! = x!                               ' left edge
            IF 639 - x! < best! THEN best! = 639 - x! ' right edge
            IF y! < best! THEN best! = y!             ' top
            IF 469 - y! < best! THEN best! = 469 - y! ' bottom
        ELSE
            ' Inside the big circle: room = 230 - distance to centre
            best! = 230 - SQR((x! - 320) ^ 2 + (y! - 240) ^ 2)
        END IF
        IF best! > MAXR THEN best! = MAXR
        ' Now shrink it for every existing circle.
        FOR i = 1 TO n
            dx! = x! - cx(i): dy! = y! - cy(i)
            room! = SQR(dx! * dx! + dy! * dy!) - cr(i)
            IF room! < best! THEN
                best! = room!
                IF best! < MINR THEN EXIT FOR    ' no point looking further
            END IF
        NEXT
        IF best! >= MINR THEN
            ' It fits!  Store it and draw it.
            n = n + 1: fails = 0
            cx(n) = x!: cy(n) = y!: cr(n) = best! - 1   ' -1: tiny gap
            ' Color: big circles blue/cyan, small ones warm colors.
            SELECT CASE cr(n)
                CASE IS > 40: c = 1
                CASE IS > 20: c = 9
                CASE IS > 10: c = 11
                CASE IS > 5: c = 14
                CASE ELSE: c = 12
            END SELECT
            CIRCLE (cx(n), cy(n)), cr(n), c
            ' Fill bigger circles; leave a dark ring inside for depth.
            IF cr(n) > 3 THEN
                CIRCLE (cx(n), cy(n)), cr(n) * .6, c
                PAINT (cx(n), cy(n)), c, c
            END IF
        ELSE
            fails = fails + 1
        END IF
        k$ = INKEY$
        IF k$ <> "" THEN EXIT DO
    LOOP
    LOCATE 30, 1: COLOR 15
    PRINT n; "circles.  Space = again, S = shape, Esc = quit";
    DO WHILE k$ = "": k$ = UCASE$(INKEY$): LOOP
    IF UCASE$(k$) = "S" THEN shape = 3 - shape
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END
