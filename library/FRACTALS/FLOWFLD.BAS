' ============================================================
' TITLE:    Flow Field Lines
' CATEGORY: Fractals & Generative Art
' LEVEL:    Intermediate
' TAGS:     generative art, vector field, trigonometry, palette, SCREEN 13
' SUMMARY:  Hundreds of particles drift along an invisible wind made of sine waves, leaving silky colored trails.
' ------------------------------------------------------------
' WHAT IT DOES
'   A "flow field" gives every point on the screen a direction - like
'   a weather map showing which way the wind blows everywhere.
'   Here the direction (an angle) is made by mixing a few sine and
'   cosine waves with random frequencies, so it changes smoothly
'   from place to place.
'
'   Then we drop particles at random spots and let each one follow
'   the field for a while, drawing its path.  Paths that start close
'   together stay close, so the lines bundle into flowing ribbons,
'   swirls and whirlpools.  The color of a line shows its direction.
'
' HOW TO USE
'   Space = new random field      G = show the field as arrows (grid)
'   Esc = quit
'
' CONCEPTS YOU WILL LEARN
'   * Vector fields: one direction per point
'   * Following a field step by step (Euler integration):
'        x = x + COS(angle) * stepSize,  y = y + SIN(angle) * stepSize
'   * Combining waves to make smooth "noise"
'   * A circular hue palette so that angle 0 and 360 match
'
' THINGS TO TRY
'   * Make STEPLEN bigger: the lines become jagged - why?
'   * Add a whirlpool: use ATN(dy / dx) towards the centre + 90 degrees
'   * Start all particles on the left edge instead of randomly
' ============================================================
DECLARE FUNCTION Angle! (x!, y!)

CONST PI = 3.14159265#
CONST STEPLEN = 1.5         ' how far a particle moves per step
CONST NLINES = 700          ' how many particles
CONST NSTEPS = 90           ' how many steps each particle takes
' Random wave settings, chosen fresh for every new field.
DIM SHARED f1!, f2!, f3!, p1!, p2!, p3!, swirl!

SCREEN 13
RANDOMIZE TIMER
' ---- Hue palette: colors 1..120 go once around the color wheel -----
OUT &H3C8, 1
FOR i% = 0 TO 119
    h! = i% / 120 * 2 * PI
    OUT &H3C9, 32 + 31 * COS(h!)
    OUT &H3C9, 32 + 31 * COS(h! - 2.094)
    OUT &H3C9, 32 + 31 * COS(h! + 2.094)
NEXT

showGrid% = 0
DO
    ' New random wave frequencies and phases.
    f1! = .005 + RND * .02: f2! = .005 + RND * .02: f3! = .01 + RND * .02
    p1! = RND * 2 * PI: p2! = RND * 2 * PI: p3! = RND * 2 * PI
    swirl! = 1 + RND * 2
    CLS
    IF showGrid% THEN
        ' Draw a little line for the direction at every 10th pixel.
        FOR gy% = 5 TO 195 STEP 10
            FOR gx% = 5 TO 315 STEP 10
                a! = Angle!(gx% * 1!, gy% * 1!)
                LINE (gx%, gy%)-(gx% + 4 * COS(a!), gy% + 4 * SIN(a!)), 8
                PSET (gx% + 4 * COS(a!), gy% + 4 * SIN(a!)), 15
            NEXT
        NEXT
    END IF
    k$ = ""
    FOR n% = 1 TO NLINES
        x! = RND * 319: y! = RND * 199          ' stay inside 0..319, 0..199
        PSET (x!, y!), POINT(x!, y!)         ' just sets the start of LINE -
        FOR s% = 1 TO NSTEPS
            a! = Angle!(x!, y!)
            x! = x! + COS(a!) * STEPLEN
            y! = y! + SIN(a!) * STEPLEN
            ' Leaving the screen?  Stop this particle.
            IF x! < 0 OR x! > 319 OR y! < 0 OR y! > 199 THEN EXIT FOR
            ' Turn the angle into a palette color 1..120.
            c% = 1 + INT((a! / (2 * PI) - INT(a! / (2 * PI))) * 120) MOD 120
            LINE -(x!, y!), c%
        NEXT
        k$ = UCASE$(INKEY$)
        IF k$ <> "" THEN EXIT FOR
    NEXT
    IF k$ = "" THEN
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ <> ""
    END IF
    IF k$ = "G" THEN showGrid% = NOT showGrid%
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

' The direction (in radians) of the flow at point (x, y).
' Three waves mixed together: smooth, but never quite repeating.
FUNCTION Angle! (x!, y!)
    v! = SIN(x! * f1! + p1!) + COS(y! * f2! + p2!) + SIN((x! + y!) * f3! + p3!)
    ' v! is between -3 and 3; swirl! sets how many turns that makes.
    Angle! = v! * swirl!
END FUNCTION
