' ============================================================
' TITLE:    Parallax Starfield
' CATEGORY: Animation & Sprites
' LEVEL:    Beginner
' TAGS:     parallax, scrolling, stars, arrays, PSET
' SUMMARY:  Three layers of stars scroll at different speeds to fake depth while you steer a little spaceship.
' ------------------------------------------------------------
' WHAT IT DOES
'   Far-away things seem to move slowly and nearby things move
'   fast - look out of a car window to see it.  This effect is
'   called PARALLAX.  Here every star belongs to a layer:
'     layer 1: dim, slow (far away)
'     layer 2: medium
'     layer 3: bright, fast (close)
'   Moving each layer at its own speed makes a flat screen
'   look deep.
'
' HOW TO USE
'   Up / Down arrows   steer the ship
'   + / -              fly faster / slower
'   Esc                quit
'
' CONCEPTS YOU WILL LEARN
'   * Parallel arrays: sx(i), sy(i), layer(i) describe star i
'   * Erase-then-draw animation with PSET
'   * Wrapping objects around the screen edge
'   * Reading arrow keys: INKEY$ gives CHR$(0) + a code letter
'
' THINGS TO TRY
'   * Make the stars scroll vertically instead
'   * Add a fourth layer of big "planets" drawn with CIRCLE
' ============================================================
DEFINT A-Z

CONST NSTARS = 120

DIM sx(NSTARS) AS SINGLE      ' x positions need fractions for slow layers
DIM sy(NSTARS), layer(NSTARS)
DIM col(3)                    ' color for each layer
DIM spd!(3)                   ' speed multiplier for each layer
col(1) = 8: col(2) = 7: col(3) = 15         ' dark grey, grey, white
spd!(1) = .5: spd!(2) = 1.2: spd!(3) = 2.5

SCREEN 13
RANDOMIZE TIMER

' Scatter the stars over the screen and give each a layer.
FOR i = 1 TO NSTARS
    sx(i) = RND * 320
    sy(i) = 10 + RND * 189
    layer(i) = 1 + INT(RND * 3)
NEXT

shipY = 100: oldShipY = 100
speed! = 1
COLOR 14: LOCATE 1, 1: PRINT "Arrows steer, +/- speed, Esc quits";

DO
    ' ---- move and redraw every star --------------------------
    FOR i = 1 TO NSTARS
        PSET (sx(i), sy(i)), 0                   ' erase old position
        sx(i) = sx(i) - spd!(layer(i)) * speed!  ' scroll left
        IF sx(i) < 0 THEN                        ' fell off the left...
            sx(i) = sx(i) + 320                  ' ...re-enter on the right
            sy(i) = 10 + RND * 189               ' at a new height
        END IF
        PSET (sx(i), sy(i)), col(layer(i))       ' draw new position
    NEXT

    ' ---- the ship: erase the old one, draw the new one -------
    IF shipY <> oldShipY THEN LINE (18, oldShipY - 6)-(44, oldShipY + 6), 0, BF
    ' Fill the triangle-shaped hull one row at a time: each row
    ' gets shorter the further it is from the middle (ABS(yy)).
    ' (We avoid PAINT here: a star could poke a hole in the
    ' outline and the paint would leak over the whole screen!)
    FOR yy = -5 TO 5
        LINE (20, shipY + yy)-(44 - ABS(yy) * 24 \ 5, shipY + yy), 1
    NEXT
    LINE (20, shipY - 5)-(44, shipY), 9               ' top edge
    LINE (20, shipY + 5)-(44, shipY), 9               ' bottom edge
    LINE (20, shipY - 5)-(20, shipY + 5), 9           ' back
    PSET (18, shipY), 12 + (RND > .5) * -2            ' flickering exhaust
    oldShipY = shipY

    WAIT &H3DA, 8, 8: WAIT &H3DA, 8

    ' ---- keys ------------------------------------------------
    k$ = INKEY$
    SELECT CASE k$
        CASE CHR$(0) + "H": IF shipY > 20 THEN shipY = shipY - 4   ' up arrow
        CASE CHR$(0) + "P": IF shipY < 190 THEN shipY = shipY + 4  ' down arrow
        CASE "+", "=": IF speed! < 5 THEN speed! = speed! + .5
        CASE "-": IF speed! > .5 THEN speed! = speed! - .5
    END SELECT
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
