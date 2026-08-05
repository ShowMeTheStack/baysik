' ============================================================
' TITLE:    Sunset Gradient Scene
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     gradient, palette, out, dac, screen 13, scenery
' SUMMARY:  Paints a smooth sunset sky, sea and mountains using custom 64-step colour gradients written to the VGA DAC.
' ------------------------------------------------------------
' WHAT IT DOES
'   Builds three smooth colour ramps by writing red/green/blue
'   values directly to the VGA hardware with OUT:
'     colours  64..127  sky   (deep purple -> orange -> yellow)
'     colours 128..191  sea   (orange glow -> dark blue)
'     colours 192..223  sun   (yellow -> white)
'   Then each screen row is drawn with the next colour in the
'   ramp. Mountains and the sun's reflection go on top. Finally
'   the sun slowly sets by fading the sky palette darker.
'
' HOW TO USE
'   Watch the sun go down. Press any key to quit at any time.
'
' CONCEPTS YOU WILL LEARN
'   * Linear interpolation: value = a + (b - a) * t, 0 <= t <= 1
'   * OUT &H3C8 / &H3C9 to define colours with 64 levels each
'   * Drawing with horizontal LINEs, one per row
'   * Fading a whole picture by rescaling the palette
'
' THINGS TO TRY
'   * Change the start/end colours to make a night or alien sky
'   * Add stars that appear as the sky darkens
'   * Make waves by drawing short wiggly lines on the sea
' ============================================================

DECLARE SUB Ramp (first%, count%, r1%, g1%, b1%, r2%, g2%, b2%, bright!)
DECLARE SUB SetSky (bright!)

SCREEN 13
CLS

SetSky 1                          ' full-brightness palette

' ---- Sky: rows 0..119, one colour per ~2 rows -------------------
FOR y = 0 TO 119
    LINE (0, y)-(319, y), 64 + y * 63 \ 119
NEXT y
' ---- Sea: rows 120..199 -----------------------------------------
FOR y = 120 TO 199
    LINE (0, y)-(319, y), 128 + (y - 120) * 63 \ 79
NEXT y

' ---- The sun: rings from big/dim to small/bright ---------------
FOR r = 30 TO 1 STEP -1
    CIRCLE (160, 100), r, 192 + (30 - r)
    PAINT (160, 100), 192 + (30 - r), 192 + (30 - r)
NEXT r
' Hide the bottom of the sun below the horizon by redrawing sea rows.
FOR y = 120 TO 140
    LINE (0, y)-(319, y), 128 + (y - 120) * 63 \ 79
NEXT y

' ---- Sun's reflection: short bright dashes on the water ---------
RANDOMIZE 7                       ' fixed seed = same picture every run
FOR y = 122 TO 190 STEP 3
    w = 30 - (y - 120) / 4 + RND * 6
    LINE (160 - w, y)-(160 + w, y), 200 + INT(RND * 10), , &HE7E7
NEXT y

' ---- Mountains: a jagged black silhouette -----------------------
' Walk left to right, nudging the height up or down at random,
' and draw a vertical line from the peak down to the horizon.
' A "valley" pushes the peaks down near the middle so the sun
' can be seen between the mountains.
h = 90
FOR x = 0 TO 319
    h = h + (RND - .5) * 4
    IF h < 78 THEN h = 78
    IF h > 105 THEN h = 105
    valley = 1 - ABS(x - 160) / 80          ' 1 in the middle, <=0 far away
    IF valley < 0 THEN valley = 0
    top = h + valley * 40
    IF top > 119 THEN top = 119
    LINE (x, top)-(x, 119), 0
NEXT x

' ---- Fade: the sky darkens slowly -------------------------------
LOCATE 25, 8: COLOR 15: PRINT "Any key quits";
FOR b! = 1 TO .15 STEP -.01
    SetSky b!
    t! = TIMER: DO: LOOP WHILE TIMER - t! < .08 AND TIMER >= t!
    IF INKEY$ <> "" THEN EXIT FOR
NEXT b!
DO: LOOP WHILE INKEY$ = ""

SCREEN 0: WIDTH 80
END

' ---- Write a smooth ramp of colours into the DAC ------------------
' Colour first% gets (r1,g1,b1); colour first%+count%-1 gets
' (r2,g2,b2); everything in between is blended. All values are
' multiplied by bright! (1 = normal, 0 = black).
SUB Ramp (first%, count%, r1%, g1%, b1%, r2%, g2%, b2%, bright!)
    OUT &H3C8, first%             ' the DAC auto-advances after B
    FOR i% = 0 TO count% - 1
        t! = i% / (count% - 1)    ' 0 at the start, 1 at the end
        OUT &H3C9, INT((r1% + (r2% - r1%) * t!) * bright!)
        OUT &H3C9, INT((g1% + (g2% - g1%) * t!) * bright!)
        OUT &H3C9, INT((b1% + (b2% - b1%) * t!) * bright!)
    NEXT i%
END SUB

' ---- All the scene's colours at a given brightness ----------------
SUB SetSky (bright!)
    ' sky top (purple) to horizon (orange), in two halves
    Ramp 64, 32, 12, 0, 24, 50, 10, 20, bright!
    Ramp 96, 32, 50, 10, 20, 63, 40, 5, bright!
    ' sea: glowing orange near the horizon to deep navy
    Ramp 128, 64, 50, 22, 10, 2, 4, 18, bright!
    ' sun: deep orange edge to near-white centre
    Ramp 192, 32, 63, 30, 0, 63, 63, 50, bright!
END SUB
