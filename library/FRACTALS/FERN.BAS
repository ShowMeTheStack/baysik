' ============================================================
' TITLE:    Barnsley Fern
' CATEGORY: Fractals & Generative Art
' LEVEL:    Beginner
' TAGS:     fractals, IFS, random, probability, affine transforms
' SUMMARY:  Four tiny formulas chosen at random paint a lifelike fern leaf, one dot at a time.
' ------------------------------------------------------------
' WHAT IT DOES
'   Michael Barnsley showed that a realistic fern can be drawn with
'   just four "affine transformations" - rules of the form
'        new x = a*x + b*y + e
'        new y = c*x + d*y + f
'   Starting from (0, 0), we pick one of the four rules at random
'   (with different probabilities), apply it, plot the point, and
'   repeat thousands of times.  This is called an Iterated Function
'   System (IFS).  Each rule maps the whole fern onto one part of
'   itself:
'     rule 1 ( 1%)  squashes everything onto the stem
'     rule 2 (85%)  makes the next smaller copy further up the leaf
'     rule 3 ( 7%)  the biggest leaflet on the left
'     rule 4 ( 7%)  the biggest leaflet on the right
'
' HOW TO USE
'   Watch the fern appear.  Esc quits.  M switches to a "mutant" fern.
'
' CONCEPTS YOU WILL LEARN
'   * Storing numbers in DATA statements and READing them into arrays
'   * Choosing randomly with weighted probabilities
'   * Affine transformations (scale, rotate, shift) as six numbers
'   * Self-similarity: each leaflet is a small copy of the whole fern
'
' THINGS TO TRY
'   * Change the 85% rule's c value from -0.04 to 0.04 (it bends!)
'   * Make all four probabilities equal - see how that changes things
'   * Color each dot by which rule produced it
' ============================================================
DEFINT I-N
DIM a(4), b(4), c(4), d(4), e(4), f(4), p(4)

SCREEN 12
RANDOMIZE TIMER
fernSet = 1

DO
    ' ---- Load the coefficients for the chosen fern ----------
    IF fernSet = 1 THEN RESTORE Barnsley ELSE RESTORE Mutant
    ' First DATA item: how many pixels one unit of the fern is.
    READ zoom!
    total! = 0
    FOR i = 1 TO 4
        READ a(i), b(i), c(i), d(i), e(i), f(i), prob!
        ' Store the RUNNING TOTAL of probabilities, e.g.
        ' .01, .86, .93, 1.00  - makes picking a rule easy (below).
        total! = total! + prob!
        p(i) = total!
    NEXT

    CLS
    COLOR 10
    IF fernSet = 1 THEN PRINT "Barnsley fern" ELSE PRINT "Mutant fern"
    LOCATE 30, 1: PRINT "M = other fern   Esc = quit";
    x! = 0: y! = 0
    k$ = ""
    FOR n& = 1 TO 60000
        ' Pick a rule: a random number 0..1 falls into one of the
        ' four slices [0,p1) [p1,p2) [p2,p3) [p3,1).
        r! = RND
        i = 1
        DO WHILE r! > p(i) AND i < 4: i = i + 1: LOOP
        nx! = a(i) * x! + b(i) * y! + e(i)
        y! = c(i) * x! + d(i) * y! + f(i)
        x! = nx!                ' (use the OLD x when computing y!)
        ' The Barnsley fern lives in -2.2 < x < 2.7 and 0 < y < 10.
        ' Scale it to the screen; y is flipped so the fern grows up.
        px = 320 + x! * zoom!
        py = 470 - y! * zoom!
        ' Color: darker green near the bottom, brighter near the tip.
        IF y! < 3 THEN col = 2 ELSE col = 10
        PSET (px, py), col
        IF (n& AND 1023) = 0 THEN
            k$ = UCASE$(INKEY$)
            IF k$ = CHR$(27) OR k$ = "M" THEN EXIT FOR
        END IF
    NEXT
    IF k$ = "" THEN
        DO: k$ = UCASE$(INKEY$): LOOP UNTIL k$ = CHR$(27) OR k$ = "M"
    END IF
    IF k$ = "M" THEN fernSet = 3 - fernSet     ' 1 <-> 2
LOOP UNTIL k$ = CHR$(27)
SCREEN 0: WIDTH 80
END

'        a      b      c      d     e     f    probability
Barnsley:
DATA 45
DATA    0,     0,     0,   .16,    0,    0,   .01
DATA  .85,   .04,  -.04,   .85,    0,  1.6,   .85
DATA  .20,  -.26,   .23,   .22,    0,  1.6,   .07
DATA -.15,   .28,   .26,   .24,    0,  .44,   .07

' A "Cyclosorus"-style mutant: thinner, more curly leaflets.
Mutant:
DATA 58
DATA    0,     0,     0,   .25,    0,  -.4,   .02
DATA  .95,  .005, -.005,   .93, -.002,  .5,   .84
DATA .035,  -.2,   .16,   .04, -.09,  .02,   .07
DATA -.04,   .2,   .16,   .04,  .083,  .12,   .07
