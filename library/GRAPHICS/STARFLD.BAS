' ============================================================
' TITLE:    Warp Speed Starfield
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     starfield, 3d, perspective, animation, arrays, screen 13
' SUMMARY:  Flies through a field of 3-D stars that brighten as they rush past - the classic demo-scene effect.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps 150 stars, each with an x, y and depth z. Every frame
'   every star moves closer (z gets smaller). Dividing x and y by
'   z makes near stars spread out toward the edges, which gives a
'   strong feeling of flying forward. Near stars are drawn
'   brighter using the grey ramp built into SCREEN 13's palette.
'
' HOW TO USE
'   Up / Down arrows  faster / slower
'   Q or Esc          quit
'
' CONCEPTS YOU WILL LEARN
'   * Perspective: screen = centre + x / z * scale
'   * Parallel arrays holding the state of many objects
'   * Erasing only what moved (draw old position in black)
'   * The default VGA palette: colours 16..31 are a grey ramp
'   * Recycling objects that leave the screen
'
' THINGS TO TRY
'   * Draw near stars as 2 x 2 blocks
'   * Draw short streaks (LINE from old to new position)
'   * Tint the stars blue by using colours 32..55 instead
' ============================================================

CONST N = 150
DIM sx(N), sy(N), sz(N)          ' star positions in 3-D
DIM px(N), py(N)                 ' where each star was last drawn

RANDOMIZE TIMER
SCREEN 13                        ' 320 x 200, 256 colours
CLS

' ---- Create the stars at random places ---------------------------
' x and y range -1000..1000; z (depth) from 1 to 1000.
FOR i = 1 TO N
    sx(i) = RND * 2000 - 1000
    sy(i) = RND * 2000 - 1000
    sz(i) = RND * 999 + 1
    px(i) = -1                    ' -1 = "not drawn yet"
NEXT i

speed = 8
DO
    FOR i = 1 TO N
        ' Erase the star's old dot (if it had one).
        IF px(i) >= 0 THEN PSET (px(i), py(i)), 0

        ' Move the star toward us.
        sz(i) = sz(i) - speed
        IF sz(i) < 1 THEN
            ' It flew past - send it back to the far distance.
            sx(i) = RND * 2000 - 1000
            sy(i) = RND * 2000 - 1000
            sz(i) = 1000
        END IF

        ' Project 3-D -> 2-D. The 100 is a "lens" size. Because
        ' SCREEN 13 pixels are a bit tall, y uses 83 instead of 100.
        x = 160 + sx(i) / sz(i) * 100
        y = 100 + sy(i) / sz(i) * 83

        IF x < 0 OR x > 319 OR y < 0 OR y > 199 THEN
            px(i) = -1            ' off screen: nothing to draw
            sz(i) = 1000          ' recycle it next frame
            sx(i) = RND * 2000 - 1000
            sy(i) = RND * 2000 - 1000
        ELSE
            ' Brightness: far = 17 (dark grey), near = 31 (white).
            b = 31 - INT(sz(i) / 1000 * 14)
            PSET (x, y), b
            px(i) = x: py(i) = y
        END IF
    NEXT i

    LOCATE 1, 1: PRINT "Speed"; speed; " "
    k$ = INKEY$
    SELECT CASE k$
        CASE CHR$(0) + "H": IF speed < 40 THEN speed = speed + 2
        CASE CHR$(0) + "P": IF speed > 2 THEN speed = speed - 2
        CASE "q", "Q", CHR$(27): EXIT DO
    END SELECT
    ' Wait for the monitor's vertical retrace (port &H3DA bit 3)
    ' so the animation runs at a steady speed without tearing.
    WAIT &H3DA, 8
    WAIT &H3DA, 8, 8
LOOP

SCREEN 0: WIDTH 80
END
