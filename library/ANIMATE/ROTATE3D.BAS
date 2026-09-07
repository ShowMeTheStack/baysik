' ============================================================
' TITLE:    Rotating 3D Wireframes
' CATEGORY: Animation & Sprites
' LEVEL:    Advanced
' TAGS:     3D, rotation, perspective, wireframe, DATA, page flipping
' SUMMARY:  Spin a cube, a pyramid, an octahedron or a house in 3D with real perspective, drawn flicker-free.
' ------------------------------------------------------------
' WHAT IT DOES
'   Each object is a list of 3D corner points (vertices) and a
'   list of which corners are joined by lines (edges), read from
'   DATA.  Every frame the points are rotated around the X, Y
'   and Z axes, then projected onto the flat screen with
'   perspective (far things look smaller), and the edges are
'   drawn.  Two video pages are used so you never see a
'   half-drawn frame.
'
' HOW TO USE
'   1 cube   2 pyramid   3 octahedron   4 house
'   + / -    zoom in / out
'   SPACE    pause / resume spinning
'   Esc      quit
'
' CONCEPTS YOU WILL LEARN
'   * 3D rotation formulas, one axis at a time:
'       around Y: x' = x*cos - z*sin ;  z' = x*sin + z*cos
'   * Perspective projection: screenX = x * D / (z + distance)
'   * Describing shapes as vertex + edge lists in DATA
'   * RESTORE label to read a particular block of DATA
'   * Double buffering by alternating SCREEN 9 pages
'
' THINGS TO TRY
'   * Add your own object: a star, a letter, a spaceship
'   * Color each edge differently, or draw the vertices as dots
' ============================================================
DEFINT A-Z
DECLARE SUB LoadShape (which)

DIM SHARED vx(20) AS SINGLE, vy(20) AS SINGLE, vz(20) AS SINGLE
DIM SHARED e1(40), e2(40), nv, ne, shapeName$
DIM sx(20), sy(20)                ' projected screen points

SCREEN 9
LoadShape 1
ax! = 0: ay! = 0: az! = 0          ' current rotation angles
dist! = 6: paused = 0: page = 0

DO
    SCREEN 9, , page, 1 - page    ' draw on hidden page
    CLS

    ' Precompute sines and cosines once per frame (they are slow).
    cosX! = COS(ax!): sinX! = SIN(ax!)
    cosY! = COS(ay!): sinY! = SIN(ay!)
    cosZ! = COS(az!): sinZ! = SIN(az!)

    FOR i = 1 TO nv
        x! = vx(i): y! = vy(i): z! = vz(i)
        ' Rotate around the X axis (tilts the top towards you).
        t! = y! * cosX! - z! * sinX!: z! = y! * sinX! + z! * cosX!: y! = t!
        ' Rotate around the Y axis (spins like a turntable).
        t! = x! * cosY! - z! * sinY!: z! = x! * sinY! + z! * cosY!: x! = t!
        ' Rotate around the Z axis (rolls like a wheel).
        t! = x! * cosZ! - y! * sinZ!: y! = x! * sinZ! + y! * cosZ!: x! = t!
        ' Perspective: divide by depth.  Bigger z = further away
        ' = smaller on screen.  400 is the "lens" strength; y is
        ' squeezed by 0.73 because SCREEN 9 pixels are tall.
        f! = 400 / (z! + dist!)
        sx(i) = 320 + x! * f!
        sy(i) = 175 - y! * f! * .73
    NEXT

    FOR j = 1 TO ne
        ' Colour edges by group so the shape is easier to read.
        LINE (sx(e1(j)), sy(e1(j)))-(sx(e2(j)), sy(e2(j))), 9 + j MOD 6
    NEXT
    FOR i = 1 TO nv: CIRCLE (sx(i), sy(i)), 2, 15: NEXT

    COLOR 7
    LOCATE 1, 1: PRINT shapeName$; "   1-4 shape  +/- zoom  SPACE pause  Esc quit"

    SCREEN 9, , page, page        ' show the finished page
    page = 1 - page
    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    IF NOT paused THEN ax! = ax! + .021: ay! = ay! + .033: az! = az! + .011

    k$ = INKEY$
    SELECT CASE k$
        CASE "1" TO "4": LoadShape VAL(k$)
        CASE "+", "=": IF dist! > 3 THEN dist! = dist! - .5
        CASE "-": IF dist! < 20 THEN dist! = dist! + .5
        CASE " ": paused = NOT paused
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0, , 0, 0: WIDTH 80
END

' ---- Shape data ----------------------------------------------
' Format: name, number of vertices, then x,y,z for each vertex,
'         number of edges, then pairs of vertex numbers.
Cube:
DATA "Cube", 8
DATA -1,-1,-1,  1,-1,-1,  1,1,-1,  -1,1,-1
DATA -1,-1, 1,  1,-1, 1,  1,1, 1,  -1,1, 1
DATA 12, 1,2, 2,3, 3,4, 4,1, 5,6, 6,7, 7,8, 8,5, 1,5, 2,6, 3,7, 4,8
Pyramid:
DATA "Pyramid", 5
DATA -1,-1,-1,  1,-1,-1,  1,-1,1,  -1,-1,1,  0,1.2,0
DATA 8, 1,2, 2,3, 3,4, 4,1, 1,5, 2,5, 3,5, 4,5
Octa:
DATA "Octahedron", 6
DATA 1.4,0,0,  -1.4,0,0,  0,1.4,0,  0,-1.4,0,  0,0,1.4,  0,0,-1.4
DATA 12, 1,3, 1,4, 1,5, 1,6, 2,3, 2,4, 2,5, 2,6, 3,5, 5,4, 4,6, 6,3
House:
DATA "House", 10
DATA -1,-1,-1,  1,-1,-1,  1,.5,-1,  -1,.5,-1
DATA -1,-1, 1,  1,-1, 1,  1,.5, 1,  -1,.5, 1
DATA 0,1.4,-1,  0,1.4,1
DATA 17, 1,2, 2,3, 3,4, 4,1, 5,6, 6,7, 7,8, 8,5, 1,5, 2,6, 3,7, 4,8
DATA 4,9, 3,9, 8,10, 7,10, 9,10

SUB LoadShape (which)
    ' RESTORE makes the next READ start at the given label.
    SELECT CASE which
        CASE 1: RESTORE Cube
        CASE 2: RESTORE Pyramid
        CASE 3: RESTORE Octa
        CASE 4: RESTORE House
    END SELECT
    READ shapeName$, nv
    FOR i = 1 TO nv: READ vx(i), vy(i), vz(i): NEXT
    READ ne
    FOR i = 1 TO ne: READ e1(i), e2(i): NEXT
END SUB
