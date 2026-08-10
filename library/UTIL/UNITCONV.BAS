' ============================================================
' TITLE:    Unit Converter
' CATEGORY: Utilities & Tools
' LEVEL:    Beginner
' TAGS:     conversion, data, read, arrays, menu
' SUMMARY:  Convert length, weight, volume, speed and temperature between metric and imperial units.
' ------------------------------------------------------------
' WHAT IT DOES
'   Pick a category (length, mass, volume, speed, temperature),
'   then a "from" unit and a "to" unit, then type a value.
'   Every unit in a category is stored as a factor that converts
'   it to ONE base unit (metres, kilograms, litres, m/s).  To go
'   from unit A to unit B we multiply by A's factor (to base)
'   and divide by B's factor (from base).  That way we only need
'   one number per unit instead of a giant table of pairs.
'
'   Temperature is special because it has an OFFSET (0 C is not
'   0 F), so it is handled with formulas instead.
'
' HOW TO USE
'   Press 1-5 to pick a category, then follow the prompts.
'   Press Q or Esc at the category menu to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Storing tables in DATA statements and READing them
'   * Converting through a common base unit
'   * Two-dimensional arrays: names$(category, unit)
'   * Why temperature needs a formula, not just a factor
'
' THINGS TO TRY
'   * Add an "Area" category (m2, ft2, acre, hectare).
'   * Add Kelvin to the temperature list.
'   * Print a whole conversion table for one value.
' ============================================================

CONST NCAT = 4          ' categories that use simple factors
CONST MAXU = 6          ' max units per category

DIM catName$(1 TO NCAT), nUnits(1 TO NCAT)
DIM uName$(1 TO NCAT, 1 TO MAXU), uFactor#(1 TO NCAT, 1 TO MAXU)

' ---- Load the tables from DATA ----
' Each category: name, number of units, then (unit name, factor
' that converts ONE of this unit into the base unit).
FOR c = 1 TO NCAT
    READ catName$(c), nUnits(c)
    FOR u = 1 TO nUnits(c)
        READ uName$(c, u), uFactor#(c, u)
    NEXT u
NEXT c

DO
    CLS
    COLOR 0, 3: PRINT SPACE$(80);: LOCATE 1, 33: PRINT "UNIT CONVERTER": COLOR 7, 0
    PRINT
    FOR c = 1 TO NCAT
        PRINT USING "    #. &"; c; catName$(c)
    NEXT c
    PRINT "    5. Temperature"
    PRINT
    PRINT "   Q / Esc = quit.   Choose a category: ";
    DO: k$ = UCASE$(INKEY$): LOOP WHILE k$ = ""
    IF k$ = "Q" OR k$ = CHR$(27) THEN EXIT DO
    c = VAL(k$)
    PRINT k$: PRINT

    IF c >= 1 AND c <= NCAT THEN
        ' ---- List the units of this category ----
        FOR u = 1 TO nUnits(c)
            PRINT "     "; u; uName$(c, u)
        NEXT u
        PRINT
        INPUT "   Convert FROM unit number: ", a
        INPUT "   Convert TO   unit number: ", b
        IF a < 1 OR a > nUnits(c) OR b < 1 OR b > nUnits(c) THEN
            PRINT "   Unit number out of range."
        ELSE
            INPUT "   Value: ", v#
            ' value -> base units -> target units
            result# = v# * uFactor#(c, a) / uFactor#(c, b)
            PRINT
            PRINT "  "; v#; uName$(c, a); " ="; result#; uName$(c, b)
        END IF
    ELSEIF c = 5 THEN
        PRINT "     1. Celsius -> Fahrenheit"
        PRINT "     2. Fahrenheit -> Celsius"
        PRINT "     3. Celsius -> Kelvin"
        INPUT "   Choice: ", t
        INPUT "   Temperature: ", v#
        SELECT CASE t
            ' F = C * 9/5 + 32 : multiply (scale) AND add (offset)
            CASE 1: PRINT "  "; v#; "C ="; v# * 9 / 5 + 32; "F"
            CASE 2: PRINT "  "; v#; "F ="; (v# - 32) * 5 / 9; "C"
            CASE 3: PRINT "  "; v#; "C ="; v# + 273.15; "K"
            CASE ELSE: PRINT "   No such choice."
        END SELECT
    ELSE
        PRINT "   Please press 1 to 5."
    END IF
    PRINT
    PRINT "   Press any key..."
    DO: LOOP WHILE INKEY$ = ""
LOOP
CLS
END

' ---- Conversion tables: factor = how many BASE units in one unit ----
' Length, base = metre
DATA "Length", 6
DATA "millimetres", 0.001, "centimetres", 0.01, "metres", 1
DATA "kilometres", 1000, "inches", 0.0254, "miles", 1609.344
' Mass, base = kilogram
DATA "Mass", 5
DATA "grams", 0.001, "kilograms", 1, "ounces", 0.028349523125
DATA "pounds", 0.45359237, "stones", 6.35029318
' Volume, base = litre
DATA "Volume", 5
DATA "millilitres", 0.001, "litres", 1, "US cups", 0.2365882365
DATA "US gallons", 3.785411784, "UK gallons", 4.54609
' Speed, base = metre per second
DATA "Speed", 4
DATA "m/s", 1, "km/h", 0.2777777777777778, "mph", 0.44704, "knots", 0.5144444444444444
