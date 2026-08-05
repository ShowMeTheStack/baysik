' ============================================================
' TITLE:    DRAW Macro Language Tour
' CATEGORY: Graphics
' LEVEL:    Beginner
' TAGS:     draw, turtle, macro, angles, screen 7
' SUMMARY:  Draws a house, a star, a filled flower and a spinning pinwheel using the DRAW "turtle" mini-language.
' ------------------------------------------------------------
' WHAT IT DOES
'   DRAW takes a string of short commands - like "U10 R20 D10" -
'   and moves an invisible pen around the screen. This program
'   uses it in 320x200 16-colour EGA (SCREEN 7) to draw a house,
'   a five-pointed star, a flower made of turned petals, and an
'   animated pinwheel that keeps spinning until you press a key.
'
' HOW TO USE
'   Watch the drawing appear, then press any key to stop the
'   pinwheel and quit.
'
' CONCEPTS YOU WILL LEARN
'   * Moves: U D L R (up/down/left/right), E F G H (diagonals)
'   * M x,y (move to a point) and M+dx,+dy (relative move)
'   * B prefix = move without drawing; N prefix = return afterwards
'   * C n = colour, S n = scale, TA n = turn angle (degrees)
'   * P fill,border = PAINT from the pen position
'   * Building DRAW strings with STR$ so loops can change them
'
' THINGS TO TRY
'   * Add a chimney to the house
'   * Change the star's 144-degree turn to 135 or 150
'   * Give the pinwheel more blades (change the STEP)
' ============================================================

SCREEN 7             ' 320 x 200, 16 colours
CLS

' ---- 1. A house -------------------------------------------------
' BM moves the pen (without drawing) to an absolute position.
' Then: C14 = yellow pen; walls are a box; the roof uses the
' diagonal moves E (up-right) and F (down-right).
DRAW "BM20,90 C14 R60 U40 L60 D40"       ' walls (start bottom-left)
DRAW "BM20,50 E30 F30"                   ' roof: up-right then down-right
DRAW "BM30,90 C12 U18 R12 D18"           ' red door
DRAW "BM55,70 C11 R14 U12 L14 D12"       ' cyan window
' Fill: move inside a shape with B, then P colour,border
DRAW "BM50,45 P4,14"                     ' fill roof dark red, yellow border
LOCATE 15, 4: PRINT "House"

' ---- 2. A five-pointed star --------------------------------------
' TA sets the absolute turn angle. Each point of a star turns the
' pen by 144 degrees (720 / 5). We move "up" each time; TA rotates
' what "up" means.
DRAW "BM120,100 C10"
' TA only accepts -360..360, so we wrap the angle with MOD.
FOR i = 0 TO 4
    DRAW "TA" + STR$(-((i * 144) MOD 360)) + " U50"
NEXT i
DRAW "TA0"                               ' always reset the angle!
LOCATE 15, 15: PRINT "Star"

' ---- 3. A flower of rotated petals --------------------------------
' One petal is a closed six-sided loop that starts and ends at the
' centre:  E4 U6 H4 G4 D6 F4.  Because it returns home, we can just
' change TA and draw it again. S (scale) multiplies every distance
' by n/4, so S6 makes everything 1.5 times bigger.
petal$ = "E4 U6 H4 G4 D6 F4"
DRAW "BM250,50 S6 C13"
FOR a = 0 TO 330 STEP 30
    DRAW "TA" + STR$(a) + petal$
NEXT a
DRAW "TA0 S4"                            ' back to normal angle and scale
CIRCLE (250, 50), 4, 14: PAINT (250, 50), 14, 14
' Stem: a relative move M+0,+30 draws straight down 30 pixels.
' N in front of a move means "draw it, then come back here".
DRAW "BM250,72 C2 M+0,+30 BM250,92 NE8 NH8"
LOCATE 15, 30: PRINT "Flower"

' ---- 4. An animated pinwheel ---------------------------------------
' Each blade is a thin triangle: out 30 pixels, turn and go 20,
' then M160,150 draws a line straight back to the centre.
' We redraw the blades at a new angle each frame and erase the
' old frame by drawing it again in colour 0 (black).
LOCATE 25, 8: PRINT "Press any key to quit";
spin = 0
DO
    FOR pass = 1 TO 2                    ' pass 1 = draw, pass 2 = erase
        FOR b = 0 TO 270 STEP 90
            IF pass = 1 THEN c = 9 + b \ 90 ELSE c = 0
            ang = (spin + b) MOD 360     ' keep TA inside -360..360
            DRAW "C" + STR$(c) + " BM160,150 TA" + STR$(ang) + " U30"
            DRAW "TA" + STR$((ang + 150) MOD 360) + " U20 M160,150"
        NEXT b
        IF pass = 1 THEN
            ' pause about 1/20 second so we can see the frame
            t! = TIMER
            DO: LOOP WHILE TIMER - t! < .05 AND TIMER >= t!
        END IF
    NEXT pass
    DRAW "TA0"
    CIRCLE (160, 150), 3, 15             ' the pin in the middle
    spin = (spin + 10) MOD 360
LOOP WHILE INKEY$ = ""

SCREEN 0: WIDTH 80
END
