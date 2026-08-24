' ============================================================
' TITLE:    Recursive Fractal Tree
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, recursion, trigonometry, trees, random, SCREEN 12
' SUMMARY:  A branch that grows two smaller branches - repeat 11 times and you get a tree, with adjustable angle and wind.
' ------------------------------------------------------------
' WHAT IT DOES
'   A tree is made of branches, and every branch looks like a small
'   tree.  So the SUB Branch draws one line, then calls ITSELF twice
'   to draw two smaller branches tilted left and right.  Thick brown
'   trunk branches turn into thin green twigs as they get smaller.
'   A little randomness makes every tree slightly different.
'
' HOW TO USE
'   Left/Right arrows   change the angle between branches
'   Up/Down arrows      longer / shorter branches
'   W                   toggle wind (all branches lean one way)
'   R                   toggle randomness
'   Space               grow a new tree     Esc   quit
'
' CONCEPTS YOU WILL LEARN
'   * Recursion: a SUB calling itself with smaller numbers
'   * Polar to screen coordinates: x + len * COS(a), y - len * SIN(a)
'   * Degrees to radians:  radians = degrees * PI / 180
'   * Using the depth of recursion to choose thickness and color
'
' THINGS TO TRY
'   * Grow THREE branches each time instead of two
'   * Shrink the left branch less than the right one
'   * Add blossoms: a small pink CIRCLE at the end of each twig
' ============================================================
DECLARE SUB Branch (x!, y!, length!, angle!, depth%)

CONST PI = 3.14159265#
DIM SHARED spread!, shrink!, wind!, jitter%

SCREEN 12
RANDOMIZE TIMER
spread! = 25: shrink! = .72: wind! = 0: jitter% = -1   ' -1 = true, so NOT flips it to 0

DO
    CLS
    ' ground
    LINE (0, 440)-(639, 479), 6, BF
    Branch 320, 440, 110, 90, 11            ' start pointing straight up
    COLOR 15: LOCATE 1, 1
    PRINT USING "angle: ##   length: #.##   wind: ##   random: "; spread!; shrink!; wind!;
    IF jitter% THEN PRINT "on" ELSE PRINT "off"
    LOCATE 30, 1: PRINT "Arrows adjust  W wind  R random  Space new  Esc quit";
    DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    SELECT CASE k$
        CASE CHR$(0) + "K": IF spread! > 5 THEN spread! = spread! - 5
        CASE CHR$(0) + "M": IF spread! < 90 THEN spread! = spread! + 5
        CASE CHR$(0) + "H": IF shrink! < .78 THEN shrink! = shrink! + .02
        CASE CHR$(0) + "P": IF shrink! > .5 THEN shrink! = shrink! - .02
        CASE "W": IF wind! = 0 THEN wind! = 8 ELSE wind! = 0
        CASE "R": jitter% = NOT jitter%
        CASE CHR$(27): EXIT DO
    END SELECT
LOOP
SCREEN 0: WIDTH 80
END

' Draws a branch starting at (x, y), "length" pixels long, pointing
' at "angle" degrees (90 = up, 0 = right).  depth = levels left.
SUB Branch (x!, y!, length!, angle!, depth%)
    IF depth% = 0 THEN EXIT SUB             ' base case: stop growing
    a! = angle! * PI / 180                  ' degrees -> radians
    ' Screen y grows DOWNWARD, so we SUBTRACT the sine.
    x2! = x! + length! * COS(a!)
    y2! = y! - length! * SIN(a!)
    ' Old (deep) branches are brown and thick; young ones green.
    IF depth% > 4 THEN
        c% = 6                              ' brown wood
    ELSEIF depth% > 2 THEN
        c% = 2                              ' dark green
    ELSE
        c% = 10                             ' bright green leaves
    END IF
    ' Thickness: draw a few side-by-side lines for big branches.
    thick% = depth% \ 3
    FOR t% = -thick% TO thick%
        LINE (x! + t%, y!)-(x2! + t%, y2!), c%
    NEXT
    ' Randomness: wiggle the angles and lengths a little.
    IF jitter% THEN
        j1! = (RND - .5) * 20: j2! = (RND - .5) * 20
        s1! = shrink! * (.85 + RND * .3): s2! = shrink! * (.85 + RND * .3)
    ELSE
        j1! = 0: j2! = 0: s1! = shrink!: s2! = shrink!
    END IF
    ' The two children: one turned left, one turned right.
    ' Wind pushes both towards the right (smaller angle).
    Branch x2!, y2!, length! * s1!, angle! + spread! + j1! - wind!, depth% - 1
    Branch x2!, y2!, length! * s2!, angle! - spread! + j2! - wind!, depth% - 1
END SUB
