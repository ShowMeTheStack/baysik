' ============================================================
' TITLE:    Text-Mode Fire
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     fire effect, video memory, poke, arrays, demoscene
' SUMMARY:  The classic demoscene fire effect, rendered with shade characters and colours straight into text video memory.
' ------------------------------------------------------------
' WHAT IT DOES
'   A grid of "heat" numbers is kept in an array.  Each frame:
'     1. the bottom row gets random hot and cold spots (the fuel),
'     2. every cell takes the AVERAGE of the cells below it, minus a
'        little cooling, so heat rises and fades,
'     3. each heat value is turned into a character + colour from a
'        small palette, from blank, through dark red shades, to
'        bright yellow and white blocks.
'   Because the heat moves upward and spreads sideways, it looks
'   remarkably like flames.  Press T to set some text on fire!
'
' HOW TO USE
'   + / -   more or less fuel        T   burning text on/off
'   Esc or Q  quit
'
' CONCEPTS YOU WILL LEARN
'   * A cellular "blur upward" rule that makes fire
'   * Mapping a number range to a palette of (char, colour) pairs
'   * Writing char + attribute bytes with POKE for speed
'   * Using one array as the "model" and the screen as the "view"
'
' THINGS TO TRY
'   * Make blue/cyan "gas" flames by changing the palette.
'   * Add wind: take the average from cells slightly to one side.
'   * Let the arrow keys move a "torch" heat spot around.
' ============================================================

DEFINT A-Z
CONST W = 80, H = 26             ' one extra hidden row at the bottom for fuel
DIM heat(0 TO W + 1, 0 TO H + 1)
CONST NPAL = 12
DIM pch(0 TO NPAL - 1), pat(0 TO NPAL - 1)

' Palette: (character, attribute) from cold to hot.
' attribute = background * 16 + foreground
FOR i = 0 TO NPAL - 1: READ pch(i), pat(i): NEXT i
DATA 32,&H00, 176,&H04, 177,&H04, 178,&H04
DATA 176,&H4C, 177,&H4C, 178,&H4C, 219,&H0C
DATA 177,&H6E, 178,&H4E, 219,&H0E, 219,&H0F

RANDOMIZE TIMER
SCREEN 0: WIDTH 80, 25
COLOR 7, 0: CLS
LOCATE , , 0
fuel = 6                         ' how hot the bottom row burns (1..9)
txt = 0                          ' burning text off
word$ = "Q B A S I C"

DO
    ' 1) Fuel: random heat along the hidden bottom row.
    FOR x = 1 TO W
        IF RND * 10 < fuel THEN heat(x, H) = 255 ELSE heat(x, H) = 0
    NEXT x
    ' Optional burning text: cells of the word are kept very hot.
    IF txt THEN
        FOR i = 1 TO LEN(word$)
            IF MID$(word$, i, 1) <> " " THEN
                xx = 40 - LEN(word$) \ 2 + i
                heat(xx, 16) = 255: heat(xx, 17) = 255
            END IF
        NEXT i
    END IF

    ' 2) Heat rises: each cell = average of 4 cells below it, cooled.
    '    Going from top to bottom means we use LAST frame's values
    '    for the rows below (they haven't been updated yet).
    FOR y = 1 TO H - 1
        FOR x = 1 TO W
            yy = y + 2: IF yy > H THEN yy = H
            s = heat(x - 1, y + 1) + heat(x, y + 1) + heat(x + 1, y + 1) + heat(x, yy)
            v = s \ 4 - 9            ' the "- 9" is the cooling
            IF v < 0 THEN v = 0
            heat(x, y) = v
        NEXT x
    NEXT y

    ' 3) Draw: heat 0..255 -> palette index 0..NPAL-1.
    DEF SEG = &HB800
    ofs = 0
    FOR y = 1 TO 25
        FOR x = 1 TO W
            p = heat(x, y) * NPAL \ 256
            POKE ofs, pch(p)
            POKE ofs + 1, pat(p)
            ofs = ofs + 2
        NEXT x
    NEXT y
    DEF SEG

    ' Burning text drawn on top, in the middle of the flames.
    IF txt THEN
        COLOR 15, 4
        LOCATE 15, 40 - LEN(word$) \ 2 + 1: PRINT word$;
    END IF
    COLOR 8, 0: LOCATE 1, 1: PRINT USING "fuel # (+/-)  T = text  Esc = quit"; fuel;

    k$ = UCASE$(INKEY$)
    SELECT CASE k$
        CASE "+", "=": IF fuel < 9 THEN fuel = fuel + 1
        CASE "-": IF fuel > 1 THEN fuel = fuel - 1
        CASE "T": txt = 1 - txt
        CASE CHR$(27), "Q": EXIT DO
    END SELECT
LOOP

COLOR 7, 0: CLS
LOCATE , , 1
END
