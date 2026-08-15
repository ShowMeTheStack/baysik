' ============================================================
' TITLE:    Ohm's Law and Resistor Toolkit
' CATEGORY: Science & Simulation
' LEVEL:    Beginner
' TAGS:     electricity, ohm's law, circuits, resistors, calculator
' SUMMARY:  Solve V = I x R, combine resistors in series and parallel, and decode resistor colour bands.
' ------------------------------------------------------------
' WHAT IT DOES
'   Electricity in a wire is a bit like water in a pipe:
'     VOLTAGE  (V, volts)  = the push, like water pressure
'     CURRENT  (I, amps)   = how much flows, like litres per second
'     RESISTANCE (R, ohms) = how narrow the pipe is
'   Georg Ohm found in 1827 that  V = I * R.  Knowing any two, you
'   can find the third.  Power (watts) is P = V * I.
'   This toolkit has three tools:
'     1) Ohm's law solver (leave the unknown blank)
'     2) Series and parallel resistor calculator
'     3) Resistor colour-code decoder
'
' HOW TO USE
'   Pick a tool from the menu.  Press Enter on its own to leave a
'   value blank.  Q quits.
'
' CONCEPTS YOU WILL LEARN
'   * Ohm's law and electrical power
'   * Series: R = R1 + R2 + ...    Parallel: 1/R = 1/R1 + 1/R2 + ...
'   * Powers of ten in the colour code
'   * Reading text input and checking whether it is blank
'
' THINGS TO TRY
'   * A 9 V battery and a 220 ohm resistor: what current flows?
'   * Two equal resistors in parallel give half the resistance.  Check!
'   * Why does a 60 W bulb on 230 V draw only about a quarter of an amp?
' ============================================================

DIM band$(9)
FOR i = 0 TO 9: READ band$(i): NEXT
DATA BLACK, BROWN, RED, ORANGE, YELLOW, GREEN, BLUE, VIOLET, GREY, WHITE
DIM bandCol(9)
FOR i = 0 TO 9: READ bandCol(i): NEXT
DATA 0, 6, 4, 12, 14, 2, 1, 5, 8, 15

DO
    CLS
    COLOR 14: PRINT "OHM'S LAW AND RESISTOR TOOLKIT": COLOR 7
    PRINT
    PRINT "        +---[ R ]---+"
    PRINT "        |    -->I   |      V = I x R"
    PRINT "      (+) V         |      P = V x I"
    PRINT "        |           |"
    PRINT "        +-----------+"
    PRINT
    PRINT "  1) Ohm's law solver"
    PRINT "  2) Series / parallel resistors"
    PRINT "  3) Resistor colour code"
    PRINT "  Q) Quit"
    INPUT "Choice"; c$
    SELECT CASE UCASE$(c$)
        CASE "1": GOSUB OhmSolver
        CASE "2": GOSUB Combine
        CASE "3": GOSUB ColourCode
        CASE "Q", "": EXIT DO
    END SELECT
LOOP
CLS
PRINT "Resistance is futile!  Goodbye."
END

' ------------------------------------------------------------
' OhmSolver: blank inputs are unknown.  We need exactly two.
' ------------------------------------------------------------
OhmSolver:
    PRINT
    PRINT "Enter two values, leave the unknown one blank."
    LINE INPUT "Voltage V (volts): "; v$
    LINE INPUT "Current I (amps) : "; i$
    LINE INPUT "Resistance R (ohms): "; r$
    known = 0
    IF v$ <> "" THEN known = known + 1: v = VAL(v$)
    IF i$ <> "" THEN known = known + 1: i = VAL(i$)
    IF r$ <> "" THEN known = known + 1: r = VAL(r$)
    IF known <> 2 THEN
        PRINT "Please give exactly two of the three values."
    ELSEIF v$ = "" THEN
        v = i * r                       ' V = I x R
        GOSUB ShowOhm
    ELSEIF i$ = "" THEN
        IF r = 0 THEN PRINT "R = 0 is a short circuit - infinite current!" ELSE i = v / r: GOSUB ShowOhm
    ELSE
        IF i = 0 THEN PRINT "No current flows, so R could be anything (an open circuit)." ELSE r = v / i: GOSUB ShowOhm
    END IF
    GOSUB Pause
RETURN

ShowOhm:
    COLOR 15
    PRINT USING "V = ######.### volts"; v
    PRINT USING "I = ######.### amps  (#########.# mA)"; i; i * 1000
    PRINT USING "R = ######.### ohms"; r
    PRINT USING "P = ######.### watts of heat in the resistor"; v * i
    COLOR 7
RETURN

' ------------------------------------------------------------
' Combine: series adds; parallel adds the reciprocals.
' ------------------------------------------------------------
Combine:
    PRINT
    PRINT "Enter resistor values in ohms, blank line to finish."
    n = 0: series = 0: recip = 0: zero = 0
    DO
        ' (LINE INPUT's prompt must be a plain string, so PRINT it first)
        PRINT "R"; LTRIM$(STR$(n + 1)); " = ";
        LINE INPUT r$
        IF r$ = "" THEN EXIT DO
        r = VAL(r$)
        IF r < 0 THEN
            PRINT "Resistance can't be negative."
        ELSE
            n = n + 1
            series = series + r
            IF r = 0 THEN zero = 1 ELSE recip = recip + 1 / r
        END IF
    LOOP
    IF n > 0 THEN
        PRINT USING "Series total   : ###########.## ohms"; series
        IF zero THEN
            PRINT "Parallel total : 0 ohms (a zero-ohm wire shorts everything)"
        ELSE
            PRINT USING "Parallel total : ###########.## ohms"; 1 / recip
        END IF
        PRINT "(Parallel is always smaller than the smallest resistor.)"
    END IF
    GOSUB Pause
RETURN

' ------------------------------------------------------------
' ColourCode: 4-band resistors: digit, digit, multiplier, tolerance
' ------------------------------------------------------------
ColourCode:
    PRINT
    FOR b = 0 TO 9
        COLOR bandCol(b), 0: IF b = 0 THEN COLOR 0, 7
        PRINT b; band$(b); "  ";
    NEXT
    COLOR 7, 0: PRINT
    INPUT "Number for band 1 (first digit, 1-9)"; b1
    INPUT "Number for band 2 (second digit, 0-9)"; b2
    INPUT "Number for band 3 (multiplier, 0-9)"; b3
    IF b1 < 0 OR b1 > 9 OR b2 < 0 OR b2 > 9 OR b3 < 0 OR b3 > 9 THEN
        PRINT "Each band is a number from 0 to 9."
    ELSE
        ' value = (10 * first + second) * 10 ^ multiplier
        ohms# = (10 * INT(b1) + INT(b2)) * 10# ^ INT(b3)
        PRINT "Bands: "; band$(b1); " "; band$(b2); " "; band$(b3); " = ";
        COLOR 15
        IF ohms# >= 1000000 THEN
            PRINT ohms# / 1000000; "megohms"
        ELSEIF ohms# >= 1000 THEN
            PRINT ohms# / 1000; "kilohms"
        ELSE
            PRINT ohms#; "ohms"
        END IF
        COLOR 7
    END IF
    GOSUB Pause
RETURN

Pause:
    PRINT "Press any key...";
    DO: LOOP WHILE INKEY$ = ""
RETURN
