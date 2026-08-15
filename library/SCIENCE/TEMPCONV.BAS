' ============================================================
' TITLE:    Temperature Converter and Tables
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     units, conversion, formulas, tables, print using
' SUMMARY:  Convert between Celsius, Fahrenheit and Kelvin, print neat tables, and compare famous temperatures.
' ------------------------------------------------------------
' WHAT IT DOES
'   Three temperature scales are used around the world:
'     Celsius    water freezes at 0, boils at 100
'     Fahrenheit water freezes at 32, boils at 212
'     Kelvin     starts at ABSOLUTE ZERO (-273.15 C), the coldest
'                anything can ever be.  Scientists use it.
'   The formulas:
'     F = C * 9 / 5 + 32        C = (F - 32) * 5 / 9
'     K = C + 273.15
'   The menu lets you convert one value, print a whole table, or see
'   a list of famous temperatures from the coldest to the hottest.
'
' HOW TO USE
'   Choose 1-4 from the menu, answer the questions, Q to quit.
'
' CONCEPTS YOU WILL LEARN
'   * Linear formulas and converting between units
'   * FUNCTIONs that return a value
'   * FOR ... STEP loops for tables, PRINT USING for columns
'   * Validating input (nothing is colder than absolute zero!)
'
' THINGS TO TRY
'   * At what temperature are Celsius and Fahrenheit the same?
'     (Hint: print a table from -50 to -30.)
'   * Add the Rankine scale: R = F + 459.67
'   * Add your own famous temperatures to the DATA list.
' ============================================================

DECLARE FUNCTION CtoF! (c!)
DECLARE FUNCTION FtoC! (f!)
CONST ABSZERO = -273.15

DO
    CLS
    COLOR 14: PRINT "TEMPERATURE CONVERTER": COLOR 7
    PRINT
    PRINT "  1) Convert one temperature"
    PRINT "  2) Celsius table"
    PRINT "  3) Fahrenheit table"
    PRINT "  4) Famous temperatures"
    PRINT "  Q) Quit"
    PRINT
    INPUT "Choice"; ch$
    SELECT CASE UCASE$(ch$)
        CASE "1": GOSUB ConvertOne
        CASE "2": GOSUB CTable
        CASE "3": GOSUB FTable
        CASE "4": GOSUB Famous
        CASE "Q", "": EXIT DO
    END SELECT
LOOP
PRINT "Stay cool!"
END

' ------------------------------------------------------------
ConvertOne:
    INPUT "Temperature value"; v!
    INPUT "Is that in C, F or K"; u$
    u$ = UCASE$(LEFT$(u$, 1))
    ' turn everything into Celsius first, then into the others
    SELECT CASE u$
        CASE "F": c! = FtoC!(v!)
        CASE "K": c! = v! + ABSZERO
        CASE ELSE: c! = v!
    END SELECT
    IF c! < ABSZERO THEN
        PRINT "That is colder than absolute zero - impossible!"
    ELSE
        PRINT USING "#####.## C  =  #####.## F  =  #####.## K"; c!; CtoF!(c!); c! - ABSZERO
    END IF
    GOSUB Pause
RETURN

' ------------------------------------------------------------
CTable:
    INPUT "From Celsius"; a!
    INPUT "To Celsius"; b!
    INPUT "Step"; s!
    IF s! <= 0 THEN s! = 10
    IF a! < ABSZERO THEN a! = ABSZERO
    IF (b! - a!) / s! > 200 THEN s! = (b! - a!) / 200   ' keep it short
    PRINT
    PRINT "   Celsius   Fahrenheit     Kelvin"
    PRINT "   -------   ----------     ------"
    n = 0
    FOR c! = a! TO b! STEP s!
        PRINT USING "  ####.##     ####.##     ####.##"; c!; CtoF!(c!); c! - ABSZERO
        n = n + 1
        IF n MOD 18 = 0 THEN GOSUB Pause
    NEXT
    GOSUB Pause
RETURN

' ------------------------------------------------------------
FTable:
    INPUT "From Fahrenheit"; a!
    INPUT "To Fahrenheit"; b!
    INPUT "Step"; s!
    IF s! <= 0 THEN s! = 10
    IF (b! - a!) / s! > 200 THEN s! = (b! - a!) / 200
    PRINT
    PRINT "   Fahrenheit   Celsius     Kelvin"
    PRINT "   ----------   -------     ------"
    n = 0
    FOR f! = a! TO b! STEP s!
        c! = FtoC!(f!)
        IF c! >= ABSZERO THEN
            PRINT USING "    ####.##     ####.##     ####.##"; f!; c!; c! - ABSZERO
            n = n + 1
            IF n MOD 18 = 0 THEN GOSUB Pause
        END IF
    NEXT
    GOSUB Pause
RETURN

' ------------------------------------------------------------
' Famous: read name/temperature pairs from DATA until the "END"
' marker.  RESTORE with a label lets us re-read the list each time.
' ------------------------------------------------------------
Famous:
    CLS
    PRINT "Thing" + SPACE$(24) + "Celsius   Fahrenheit       Kelvin"
    PRINT STRING$(62, "-")
    RESTORE FamousData
    DO
        READ t$, c!
        IF t$ = "END" THEN EXIT DO
        PRINT USING "\                     \ ##########.# ##########.# ##########.#"; t$; c!; CtoF!(c!); c! - ABSZERO
    LOOP
    PRINT
    PRINT "Notice: Kelvin never goes negative - that's what absolute zero means."
    GOSUB Pause
RETURN

FamousData:
DATA "Absolute zero", -273.15
DATA "Liquid helium boils", -268.93
DATA "Liquid nitrogen boils", -195.8
DATA "Coldest Antarctica", -89.2
DATA "Dry ice", -78.5
DATA "Water freezes", 0
DATA "Room temperature", 20
DATA "Human body", 37
DATA "Hottest air on Earth", 56.7
DATA "Water boils (sea lvl)", 100
DATA "Oven (pizza)", 250
DATA "Lead melts", 327.5
DATA "Candle flame", 1000
DATA "Iron melts", 1538
DATA "Surface of the Sun", 5500
DATA "Lightning bolt", 30000
DATA "Centre of the Sun", 15000000
DATA "END", 0

Pause:
    PRINT "Press any key...";
    DO: LOOP WHILE INKEY$ = ""
    PRINT
RETURN

' ------------------------------------------------------------
FUNCTION CtoF! (c!)
    ' Each Celsius degree is 9/5 of a Fahrenheit degree,
    ' and the scales are offset by 32.
    CtoF! = c! * 9 / 5 + 32
END FUNCTION

FUNCTION FtoC! (f!)
    FtoC! = (f! - 32) * 5 / 9
END FUNCTION
