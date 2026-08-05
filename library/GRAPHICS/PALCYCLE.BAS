' ============================================================
' TITLE:    Palette Cycling Tunnel
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     palette, palette using, animation, ega, screen 9
' SUMMARY:  Animates a hypnotic tunnel without redrawing a single pixel - only the PALETTE changes.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws rings of colours 1..15 once. Then, instead of moving
'   anything, it keeps changing WHICH real colour each colour
'   number shows. The rings seem to rush toward you. This trick,
'   "palette cycling", was used in many old games for water,
'   fire and waterfalls because it is extremely fast.
'
' HOW TO USE
'   Space  switch between three colour schemes
'   + / -  faster / slower
'   Q/Esc  quit
'
' CONCEPTS YOU WILL LEARN
'   * PALETTE attribute, colour  (EGA colours are 0..63)
'   * PALETTE USING array(start) to change all 16 at once
'   * EGA colour numbers: bits are  r g b R G B  (low=dark, high=bright)
'   * Rotating an array with MOD arithmetic
'
' THINGS TO TRY
'   * Invent your own 15-colour scheme in the DATA lines
'   * Draw squares instead of circles
'   * Cycle only colours 1..7 and leave 8..15 still
' ============================================================

DIM scheme%(2, 14)          ' 3 schemes x 15 colours
DIM pal%(15)                ' the live palette for PALETTE USING

' ---- Load colour schemes from DATA ----------------------------------
FOR s = 0 TO 2
    FOR i = 0 TO 14
        READ scheme%(s, i)
    NEXT i
NEXT s

SCREEN 9
CLS

' ---- Draw the tunnel ONCE -------------------------------------------
' Big circles first, small ones last, each filled. The colour
' number goes 1,2,...,15,1,2,... from the outside in.
c = 0
FOR r = 330 TO 4 STEP -7
    c = c MOD 15 + 1
    CIRCLE (320, 175), r, c
    PAINT (320, 175), c, c
NEXT r
COLOR 15
LOCATE 1, 2: PRINT "Palette cycling: nothing is being redrawn!"
LOCATE 25, 2: PRINT "Space=scheme  +/-=speed  Q=quit";

' ---- Cycle the palette -----------------------------------------------
s = 0                       ' current scheme
shift = 0                   ' how far the colours have rotated
delay! = .05
pal%(0) = 0                 ' background stays black
DO
    ' Fill pal%(1..15) with the scheme, rotated by "shift".
    FOR i = 1 TO 15
        pal%(i) = scheme%(s, (i - 1 + shift) MOD 15)
    NEXT i
    ' The text is drawn in colour 15, which is part of the tunnel,
    ' so it shimmers along with the rings.
    PALETTE USING pal%(0)   ' set all 16 attributes from the array

    shift = (shift + 1) MOD 15

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE " ": s = (s + 1) MOD 3
        CASE "+", "=": IF delay! > .01 THEN delay! = delay! - .01
        CASE "-": IF delay! < .3 THEN delay! = delay! + .01
        CASE "Q", CHR$(27): EXIT DO
    END SELECT

    t! = TIMER: DO: LOOP WHILE TIMER - t! < delay! AND TIMER >= t!
LOOP

PALETTE                     ' no arguments = restore default colours
SCREEN 0: WIDTH 80
END

' ---- Colour schemes (EGA 0..63) -------------------------------------
' EGA colour = 32*r + 16*g + 8*b + 4*R + 2*G + 1*B
' where R G B are strong and r g b are weak components.
' Scheme 0: rainbow
DATA 4, 36, 38, 6, 54, 62, 58, 2, 18, 3, 27, 1, 9, 5, 13
' Scheme 1: fire (black -> red -> yellow -> white -> back)
DATA 0, 32, 4, 36, 38, 6, 54, 62, 63, 62, 54, 6, 38, 36, 4
' Scheme 2: ice (blues and cyans)
DATA 0, 8, 1, 9, 25, 11, 27, 59, 63, 59, 27, 11, 25, 9, 1
