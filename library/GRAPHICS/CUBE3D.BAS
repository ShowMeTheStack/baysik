' ============================================================
' TITLE:    Rotating 3-D Wireframe Cube
' CATEGORY: Graphics
' LEVEL:    Advanced
' TAGS:     3d, rotation, perspective, page flipping, trigonometry, screen 7
' SUMMARY:  Spins a wireframe cube in 3-D with perspective, using hidden-page drawing for flicker-free animation.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps the 8 corners of a cube as (x, y, z) points, rotates
'   them around the X, Y and Z axes every frame, projects them
'   onto the flat screen with perspective (far things look
'   smaller) and joins them with 12 edges. Drawing happens on an
'   invisible page which is then shown all at once, so there is
'   no flicker.
'
' HOW TO USE
'   Arrow keys  change the spin speed around X and Y
'   + / -       move the cube closer / farther
'   Space       also draw the 4 long diagonals through the middle
'   Q or Esc    quit
'
' CONCEPTS YOU WILL LEARN
'   * 3-D rotation formulas using SIN and COS
'   * Perspective projection: screen x = x * d / (z + dist)
'   * TYPE to group x, y, z into one record
'   * SCREEN 7, , apage, vpage and PCOPY page flipping
'   * Edges stored as pairs of corner numbers in DATA
'
' THINGS TO TRY
'   * Add a second cube, or turn it into a house shape
'   * Colour each edge by its depth (near = bright, far = dark)
'   * Remove the perspective (use a fixed divisor) and compare
' ============================================================

TYPE Point3
    x AS SINGLE
    y AS SINGLE
    z AS SINGLE
END TYPE

DIM v(1 TO 8) AS Point3          ' the cube's corners (model)
DIM sx(1 TO 8), sy(1 TO 8)       ' projected screen positions
DIM e1(1 TO 16), e2(1 TO 16)     ' edges: from corner, to corner

' ---- Corners: every combination of -1 and +1 -------------------------
FOR i = 1 TO 8
    READ v(i).x, v(i).y, v(i).z
NEXT i
' ---- Edges (12 cube edges + 4 "star" diagonals) ----------------------
FOR i = 1 TO 16
    READ e1(i), e2(i)
NEXT i

' Angles and spin speeds (radians per frame)
ax = 0: ay = 0: az = 0
dax = .03: day = .05: daz = .01
dist = 4                          ' how far the cube is from the eye
star = 0                          ' 0 = 12 edges, -1 = 16 edges

' SCREEN 7 has 8 pages. We will DRAW on page 1 (hidden) and SHOW
' page 0. After each frame PCOPY copies page 1 onto page 0.
SCREEN 7, , 1, 0

DO
    CLS                           ' clears the hidden page only

    ' Pre-compute the sines and cosines once per frame.
    cx = COS(ax): snx = SIN(ax)
    cy = COS(ay): sny = SIN(ay)
    cz = COS(az): snz = SIN(az)

    FOR i = 1 TO 8
        x = v(i).x: y = v(i).y: z = v(i).z
        ' Rotate around the X axis (y and z change)
        y1 = y * cx - z * snx
        z1 = y * snx + z * cx
        ' Rotate around the Y axis (x and z change)
        x2 = x * cy + z1 * sny
        z2 = -x * sny + z1 * cy
        ' Rotate around the Z axis (x and y change)
        x3 = x2 * cz - y1 * snz
        y3 = x2 * snz + y1 * cz
        ' Perspective: divide by distance from the eye. The 160 is
        ' the "lens"; 0.83 corrects for SCREEN 7's tall pixels.
        p = 160 / (z2 + dist)
        sx(i) = 160 + x3 * p
        sy(i) = 100 - y3 * p * .83
    NEXT i

    ' Draw the edges
    IF star THEN n = 16 ELSE n = 12
    FOR i = 1 TO n
        IF i > 12 THEN c = 12 ELSE c = 9 + (i - 1) \ 4   ' 3 colours by edge group
        LINE (sx(e1(i)), sy(e1(i)))-(sx(e2(i)), sy(e2(i))), c
    NEXT i
    ' Dots on the corners
    FOR i = 1 TO 8
        CIRCLE (sx(i), sy(i)), 2, 15
    NEXT i

    LOCATE 1, 1: PRINT "Arrows=spin +/-=zoom"
    LOCATE 2, 1: PRINT "Space=diagonals Q=quit"

    PCOPY 1, 0                    ' show the finished frame

    ' Advance the angles; keep them small with a wrap-around.
    ax = ax + dax: ay = ay + day: az = az + daz
    IF ax > 6.2832 THEN ax = ax - 6.2832
    IF ay > 6.2832 THEN ay = ay - 6.2832
    IF az > 6.2832 THEN az = az - 6.2832

    ' Keyboard. Arrow keys arrive as CHR$(0) + a scan code.
    k$ = INKEY$
    SELECT CASE k$
        CASE CHR$(0) + "H": dax = dax - .01    ' up
        CASE CHR$(0) + "P": dax = dax + .01    ' down
        CASE CHR$(0) + "K": day = day - .01    ' left
        CASE CHR$(0) + "M": day = day + .01    ' right
        CASE "+", "=": IF dist > 2.5 THEN dist = dist - .25
        CASE "-": IF dist < 12 THEN dist = dist + .25
        CASE " ": star = NOT star
        CASE "q", "Q", CHR$(27): EXIT DO
    END SELECT

    ' About 30 frames per second at most
    t! = TIMER: DO: LOOP WHILE TIMER - t! < .03 AND TIMER >= t!
LOOP

SCREEN 0: WIDTH 80
END

' ---- Corner coordinates --------------------------------------------
'      x   y   z
DATA  -1, -1, -1
DATA   1, -1, -1
DATA   1,  1, -1
DATA  -1,  1, -1
DATA  -1, -1,  1
DATA   1, -1,  1
DATA   1,  1,  1
DATA  -1,  1,  1
' ---- Edges: back face, front face, joining edges, diagonals --------
DATA 1,2, 2,3, 3,4, 4,1
DATA 5,6, 6,7, 7,8, 8,5
DATA 1,5, 2,6, 3,7, 4,8
DATA 1,7, 2,8, 3,5, 4,6
