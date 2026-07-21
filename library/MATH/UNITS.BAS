' ============================================================
' TITLE:    Unit Converter
' CATEGORY: Mathematics
' LEVEL:    Beginner
' TAGS:     units, measurement, conversion, DATA, menus
' SUMMARY:  Converts length, mass, volume, speed and temperature using a table of factors stored in DATA.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every unit in a group is stored with one number: how many of the
'   group's BASE unit it equals.  For length the base is the metre,
'   so  1 mile = 1609.344 m  and  1 inch = 0.0254 m.
'   To convert, go "through the base":
'        value in base   = value * factor(from)
'        value in target = value in base / factor(to)
'   That way 8 units need only 8 factors, not 8 x 8 = 64 separate
'   conversion rules.  Temperature is the exception, because the
'   scales have different zero points, so it uses formulas instead:
'        F = C * 9/5 + 32        K = C + 273.15
'
' HOW TO USE
'   Choose a category number, then the "from" unit, the "to" unit and
'   the amount.  0 goes back / quits.
'
' CONCEPTS YOU WILL LEARN
'   * Tables of data with DATA / READ / RESTORE
'   * A base unit as a "hub" to avoid lots of special cases
'   * Linear vs affine conversions (why temperature is different)
'
' THINGS TO TRY
'   * Add a category for time (seconds, minutes, hours, days, years)
'   * Add light years and astronomical units to length
'   * Print a whole conversion table, e.g. 1 to 10 miles in km
' ============================================================

DEFDBL A-Z
DIM uname$(1 TO 10), factor(1 TO 10)
DIM cat$(1 TO 5)
FOR i = 1 TO 5: READ cat$(i): NEXT i
DATA Length, Mass, Volume, Speed, Temperature

DO
    CLS
    COLOR 14: PRINT "UNIT CONVERTER": COLOR 7
    PRINT
    FOR i = 1 TO 5: PRINT "  "; i; cat$(i): NEXT i
    PRINT "   0 Quit"
    INPUT "Category"; c
    c = INT(c)
    IF c < 1 OR c > 5 THEN EXIT DO

    ' Load this category's units.  Each group in DATA ends with "*".
    SELECT CASE c
        CASE 1: RESTORE LengthData
        CASE 2: RESTORE MassData
        CASE 3: RESTORE VolumeData
        CASE 4: RESTORE SpeedData
        CASE 5: RESTORE TempData
    END SELECT
    n = 0
    DO
        READ u$
        IF u$ = "*" THEN EXIT DO
        READ f
        n = n + 1: uname$(n) = u$: factor(n) = f
    LOOP

    DO
        PRINT
        COLOR 11: PRINT cat$(c); " units:": COLOR 7
        FOR i = 1 TO n
            PRINT USING "  ## "; i;
            PRINT LEFT$(uname$(i) + SPACE$(18), 18);
            IF i MOD 3 = 0 THEN PRINT
        NEXT i
        IF n MOD 3 <> 0 THEN PRINT
        INPUT "From unit (0 = back)"; a
        IF a < 1 OR a > n THEN EXIT DO
        INPUT "To unit"; b
        IF b < 1 OR b > n THEN EXIT DO
        INPUT "Amount"; v

        IF c = 5 THEN
            ' Temperature: first convert to Celsius, then to the target.
            SELECT CASE a
                CASE 1: cel = v
                CASE 2: cel = (v - 32) * 5 / 9
                CASE 3: cel = v - 273.15
            END SELECT
            IF cel < -273.15 THEN PRINT "  That is colder than absolute zero!"
            SELECT CASE b
                CASE 1: res = cel
                CASE 2: res = cel * 9 / 5 + 32
                CASE 3: res = cel + 273.15
            END SELECT
        ELSE
            inBase = v * factor(a)            ' to the base unit
            res = inBase / factor(b)          ' from the base unit
        END IF
        COLOR 15
        PRINT "  "; CSNG(v); uname$(a); " = "; CSNG(res); uname$(b)
        COLOR 7
    LOOP
LOOP
PRINT "Bye!"
END

' name, size in base units.  Base: metre.
LengthData:
DATA millimetres, 0.001, centimetres, 0.01, metres, 1, kilometres, 1000
DATA inches, 0.0254, feet, 0.3048, yards, 0.9144, miles, 1609.344
DATA nautical miles, 1852, *
' Base: kilogram.
MassData:
DATA grams, 0.001, kilograms, 1, tonnes, 1000, ounces, 0.028349523125
DATA pounds, 0.45359237, stones, 6.35029318, *
' Base: litre.
VolumeData:
DATA millilitres, 0.001, litres, 1, cubic metres, 1000, teaspoons (US), 0.00492892
DATA cups (US), 0.2365882, pints (UK), 0.56826125, gallons (UK), 4.54609
DATA gallons (US), 3.785411784, *
' Base: metres per second.
SpeedData:
DATA m/s, 1, km/h, 0.2777777777777778, miles/hour, 0.44704, knots, 0.5144444444444444
DATA speed of sound, 343, *
' Temperature uses formulas; the numbers here are unused placeholders.
TempData:
DATA Celsius, 0, Fahrenheit, 0, Kelvin, 0, *
