' ============================================================
' TITLE:    Shape Morphing
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     morphing, interpolation, easing, polygons, tweening
' SUMMARY:  A circle melts into a square, then a triangle, a star, a hexagon and a heart, with smooth eased "tweening".
' ------------------------------------------------------------
' WHAT IT DOES
'   Every shape is described by the SAME number of points (60),
'   going round the outline in the same direction.  To morph
'   from shape A to shape B, each point slides in a straight
'   line from its spot on A to the matching spot on B:
'       p = a + (b - a) * t      with t going from 0 to 1
'   This is called linear interpolation ("lerp") or tweening.
'   An easing curve makes t start slow, speed up, and slow down
'   again, so the morph looks natural instead of robotic.
'
' HOW TO USE
'   Watch the shapes flow into each other.
'   SPACE  skip to the next shape      E  toggle easing on/off
'   Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * Linear interpolation between two lists of points
'   * Easing: t' = t * t * (3 - 2 * t)  ("smoothstep")
'   * Building polygons by spacing points evenly along edges
'   * Parametric curves (the heart formula)
'   * Double-buffered drawing with two SCREEN 9 pages
'
' THINGS TO TRY
'   * Add a new shape: a pentagon or an arrow (add a DATA line)
'   * Morph two shapes at the same time, side by side
' ============================================================
DEFINT A-Z
DECLARE SUB MakeShape (s, px() AS SINGLE, py() AS SINGLE)

CONST NP = 60                     ' points per shape
CONST NSHAPES = 6
CONST PI = 3.14159
DIM SHARED shapeName$(NSHAPES)
DIM ax(NP) AS SINGLE, ay(NP) AS SINGLE   ' "from" shape
DIM bx(NP) AS SINGLE, by(NP) AS SINGLE   ' "to" shape
DIM cx(NP), cy(NP)                       ' current, in screen pixels

FOR i = 1 TO NSHAPES: READ shapeName$(i): NEXT
DATA "circle", "square", "triangle", "star", "hexagon", "heart"

SCREEN 9
from = 1: dest = 2
MakeShape from, ax(), ay()
MakeShape dest, bx(), by()
fr = 0: ease = -1: page = 0
CONST MORPHF = 70, HOLDF = 45      ' frames to morph / to rest

DO
    ' ---- work out t, 0..1, for this frame ------------------
    IF fr < MORPHF THEN t! = fr / MORPHF ELSE t! = 1
    IF ease THEN t! = t! * t! * (3 - 2 * t!)   ' smoothstep easing

    ' ---- interpolate every point ---------------------------
    ' Shapes are stored in a -1..1 box; scale to pixels here.
    ' (y is scaled by 0.73 because SCREEN 9 pixels are tall.)
    FOR i = 0 TO NP - 1
        cx(i) = 320 + 140 * (ax(i) + (bx(i) - ax(i)) * t!)
        cy(i) = 175 + 140 * .73 * (ay(i) + (by(i) - ay(i)) * t!)
    NEXT

    ' ---- draw on the hidden page, then show it -------------
    SCREEN 9, , page, 1 - page
    CLS
    col = 9 + (from MOD 6)
    FOR i = 0 TO NP - 1
        j = (i + 1) MOD NP                    ' next point (wraps)
        LINE (320, 175)-(cx(i), cy(i)), 1     ' a dim "fan" to fill it
        LINE (cx(i), cy(i))-(cx(j), cy(j)), col
    NEXT
    COLOR 7: LOCATE 1, 1
    PRINT shapeName$(from); " -> "; shapeName$(dest); SPACE$(10)
    LOCATE 25, 1: PRINT "SPACE next   E easing ";
    IF ease THEN PRINT "ON ";  ELSE PRINT "OFF";
    PRINT "   Esc quit";
    SCREEN 9, , page, page
    page = 1 - page
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    ' ---- advance time; start the next morph when done ------
    fr = fr + 1
    k$ = UCASE$(INKEY$)
    IF k$ = "E" THEN ease = NOT ease
    IF fr > MORPHF + HOLDF OR k$ = " " THEN
        ' The old destination becomes the new starting shape.
        FOR i = 0 TO NP - 1: ax(i) = bx(i): ay(i) = by(i): NEXT
        from = dest
        dest = dest MOD NSHAPES + 1
        MakeShape dest, bx(), by()
        fr = 0
    END IF
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
END

' Corner lists for the straight-edged shapes (x, y in -1..1),
' listed clockwise starting from the top.
SquareData:
DATA 4, 0,-1, 1,0, 0,1, -1,0
TriData:
DATA 3, 0,-1, .87,.5, -.87,.5
StarData:
DATA 10, 0,-1, .22,-.31, .95,-.31, .36,.12, .59,.81, 0,.38, -.59,.81, -.36,.12, -.95,-.31, -.22,-.31
HexData:
DATA 6, 0,-1, .87,-.5, .87,.5, 0,1, -.87,.5, -.87,-.5

SUB MakeShape (s, px() AS SINGLE, py() AS SINGLE)
    ' Fill px(), py() with NP points around shape number s.
    SELECT CASE s
        CASE 1                                  ' circle
            FOR i = 0 TO NP - 1
                a! = i * 2 * PI / NP - PI / 2     ' start at the top
                px(i) = COS(a!): py(i) = SIN(a!)
            NEXT
            EXIT SUB
        CASE 6                                  ' heart (parametric)
            FOR i = 0 TO NP - 1
                tt! = i * 2 * PI / NP
                px(i) = 16 * SIN(tt!) ^ 3 / 17
                py(i) = -(13 * COS(tt!) - 5 * COS(2 * tt!) - 2 * COS(3 * tt!) - COS(4 * tt!)) / 17
            NEXT
            EXIT SUB
        CASE 2: RESTORE SquareData
        CASE 3: RESTORE TriData
        CASE 4: RESTORE StarData
        CASE 5: RESTORE HexData
    END SELECT
    ' Polygon: read the corners, then spread NP points evenly
    ' along the edges (NP / corners points on each edge).
    READ nc
    DIM vx(nc) AS SINGLE, vy(nc) AS SINGLE
    FOR i = 0 TO nc - 1: READ vx(i), vy(i): NEXT
    vx(nc) = vx(0): vy(nc) = vy(0)          ' close the loop
    per = NP \ nc
    FOR i = 0 TO NP - 1
        e = i \ per                           ' which edge
        f! = (i MOD per) / per                ' how far along it
        px(i) = vx(e) + (vx(e + 1) - vx(e)) * f!
        py(i) = vy(e) + (vy(e + 1) - vy(e)) * f!
    NEXT
END SUB
