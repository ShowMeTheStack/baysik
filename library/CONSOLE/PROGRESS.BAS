' ============================================================
' TITLE:    Progress Bar Gallery
' CATEGORY: Console & Text
' LEVEL:    Beginner
' TAGS:     progress bar, animation, string$, percent, sub
' SUMMARY:  Five different text progress bars and spinners filling up side by side during a pretend "install".
' ------------------------------------------------------------
' WHAT IT DOES
'   Pretends to install a game and shows the progress in five
'   different styles you can copy into your own programs:
'     1. classic solid block bar with a percentage
'     2. smooth shaded bar using the 4 shade characters
'     3. [=====>    ] ASCII style bar
'     4. a spinner  | / - \  with a counter
'     5. a colour bar that goes red -> yellow -> green
'   Each bar runs at a different speed so you can compare them.
'
' HOW TO USE
'   Watch.  Press any key at the end to quit (Esc quits anytime).
'
' CONCEPTS YOU WILL LEARN
'   * Turning a fraction (0..1) into a number of characters
'   * STRING$ to build the filled and empty parts of a bar
'   * Integer division \ and MOD for "partial" blocks
'   * Writing a bar as a SUB you can reuse anywhere
'
' THINGS TO TRY
'   * Add an "estimated time left" display using TIMER.
'   * Make bar 2 vertical, growing up from the bottom.
' ============================================================

DECLARE SUB BlockBar (row%, col%, w%, frac!)
DECLARE SUB ShadeBar (row%, col%, w%, frac!)
DECLARE SUB AsciiBar (row%, col%, w%, frac!)
DECLARE SUB ColorBar (row%, col%, w%, frac!)

SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
COLOR 15: LOCATE 2, 25: PRINT "INSTALLING  SUPER BASIC QUEST"
COLOR 8: LOCATE 3, 25: PRINT STRING$(29, 196)

COLOR 7
LOCATE 6, 3: PRINT "1. Blocks"
LOCATE 9, 3: PRINT "2. Shades"
LOCATE 12, 3: PRINT "3. ASCII"
LOCATE 15, 3: PRINT "4. Spinner"
LOCATE 18, 3: PRINT "5. Colour"

' Some pretend file names for the "copying" message.
DIM files$(1 TO 8)
FOR i = 1 TO 8: READ files$(i): NEXT i
DATA DRAGON.SPR, CASTLE.MAP, MUSIC.MID, SWORD.SND
DATA LEVEL1.DAT, LEVEL2.DAT, HISCORE.TXT, QUEST.EXE

spin$ = "|/-\"         ' the four frames of the spinner
steps = 200
FOR s = 0 TO steps
    f! = s / steps                   ' overall progress, 0 to 1

    ' Different bars move at different speeds to look realistic.
    ' MIN-style trick: a value above 1 is clamped back down to 1.
    f2! = f! * 1.3: IF f2! > 1 THEN f2! = 1
    f3! = f! * f!                    ' starts slowly, then speeds up

    BlockBar 6, 15, 50, f!
    ShadeBar 9, 15, 50, f2!
    AsciiBar 12, 15, 50, f3!
    ColorBar 18, 15, 50, f!

    ' Spinner: pick a frame with MOD so it cycles 1,2,3,4,1,2...
    COLOR 14
    LOCATE 15, 15: PRINT MID$(spin$, (s MOD 4) + 1, 1);
    COLOR 7
    LOCATE 15, 17: PRINT USING "Copying file # of 8: \           \"; INT(f! * 7.99) + 1; files$(INT(f! * 7.99) + 1);

    ' Pause about 1/40 of a second.  Esc quits early.
    t! = TIMER
    DO WHILE TIMER - t! < .025 AND TIMER >= t!: LOOP
    IF INKEY$ = CHR$(27) THEN EXIT FOR
NEXT s

COLOR 10
LOCATE 15, 15: PRINT CHR$(251); " Done!  All 8 files copied.            "
COLOR 15: LOCATE 22, 25: PRINT "Installation complete! Press a key."
k$ = INPUT$(1)
COLOR 7, 0: CLS
END

' Bar 3:  [=========>          ]  with the arrow at the front.
SUB AsciiBar (row%, col%, w%, frac!)
    inner% = w% - 2
    n% = INT(frac! * inner%)
    IF n% >= inner% THEN
        b$ = STRING$(inner%, "=")
    ELSEIF n% = 0 THEN
        b$ = SPACE$(inner%)
    ELSE
        b$ = STRING$(n% - 1, "=") + ">" + SPACE$(inner% - n%)
    END IF
    COLOR 11
    LOCATE row%, col%: PRINT "["; b$; "]";
    LOCATE row%, col% + w% + 2: PRINT USING "###%"; frac! * 100;
END SUB

' Bar 1: solid blocks for the done part, light shade for the rest.
SUB BlockBar (row%, col%, w%, frac!)
    n% = INT(frac! * w%)                 ' how many cells are full
    COLOR 9
    LOCATE row%, col%
    PRINT STRING$(n%, 219); STRING$(w% - n%, 176);
    COLOR 15
    LOCATE row%, col% + w% + 2: PRINT USING "###%"; frac! * 100;
END SUB

' Bar 5: the colour changes with progress, like a health bar.
SUB ColorBar (row%, col%, w%, frac!)
    n% = INT(frac! * w%)
    IF frac! < .34 THEN
        c% = 12             ' red
    ELSEIF frac! < .67 THEN
        c% = 14             ' yellow
    ELSE
        c% = 10             ' green
    END IF
    COLOR c%, 0
    LOCATE row%, col%: PRINT STRING$(n%, 219);
    COLOR 8: PRINT STRING$(w% - n%, 250);   ' 250 is a small centred dot
    COLOR c%
    LOCATE row%, col% + w% + 2: PRINT USING "###%"; frac! * 100;
END SUB

' Bar 2: smoother!  Each cell can be one of 5 levels:
' empty, 176 light, 177 medium, 178 dark, 219 full.
' So the bar has w * 4 tiny steps instead of just w steps.
SUB ShadeBar (row%, col%, w%, frac!)
    total% = INT(frac! * w% * 4)        ' progress in quarter-cells
    full% = total% \ 4                   ' completely filled cells
    part% = total% MOD 4                 ' 0..3 quarters in the next cell
    b$ = STRING$(full%, 219)
    IF full% < w% THEN
        IF part% > 0 THEN b$ = b$ + CHR$(175 + part%) ELSE b$ = b$ + " "
        b$ = b$ + SPACE$(w% - full% - 1)
    END IF
    COLOR 13
    LOCATE row%, col%: PRINT b$;
    LOCATE row%, col% + w% + 2: PRINT USING "###%"; frac! * 100;
END SUB
