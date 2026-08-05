' ============================================================
' TITLE:    Dashboard Gauges
' CATEGORY: Graphics
' LEVEL:    Intermediate
' TAGS:     gauges, dials, needles, arcs, simulation, screen 9
' SUMMARY:  A car dashboard with speedometer, rev counter and fuel gauge whose needles respond as you accelerate and brake.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws three round dials with scale marks, numbers and coloured
'   warning zones (drawn as thick CIRCLE arcs). A tiny car "physics"
'   model updates speed, engine revs and fuel, and each needle is
'   moved by erasing it and drawing it again at the new angle.
'
' HOW TO USE
'   Up arrow (or W)    accelerate
'   Down arrow (or S)  brake
'   Q or Esc           quit
'   Let go and the car slowly coasts to a stop.
'
' CONCEPTS YOU WILL LEARN
'   * Mapping a value range onto an angle range (linear mapping)
'   * Arcs with CIRCLE start/end angles for coloured zones
'   * A reusable SUB that draws any dial from parameters
'   * Simple simulation: speed changes by acceleration and drag
'   * Gear changes: revs depend on speed AND the current gear
'
' THINGS TO TRY
'   * Add a temperature gauge that rises with high revs
'   * Make the needle "overshoot" and settle like a real one
'   * Add an odometer that counts kilometres travelled
' ============================================================

DECLARE SUB Dial (cx!, cy!, r!, maxv!, stepv!, redFrom!, label$)
DECLARE SUB Needle (cx!, cy!, r!, maxv!, v!, c%)
CONST PI = 3.14159265#
CONST ASP = .73                   ' SCREEN 9 pixel shape correction

SCREEN 9
CLS
COLOR 15
LOCATE 1, 30: PRINT "D A S H B O A R D"

' Three dials: speed (km/h), revs (thousands of rpm), fuel (%)
Dial 160, 150, 120, 200, 20, 160, "km/h"
Dial 440, 150, 90, 8, 1, 6.5, "rpm"
Dial 580, 270, 45, 100, 25, -1, "fuel"
LOCATE 24, 2: PRINT "Up/W = accelerate   Down/S = brake   Q = quit";

speed = 0: rpm = .8: fuel = 100: gear = 1
oldS = -1
DO
    ' ---- Keyboard -----------------------------------------------
    k$ = UCASE$(INKEY$)
    accel = 0
    SELECT CASE k$
        CASE CHR$(0) + "H", "W": accel = 1
        CASE CHR$(0) + "P", "S": accel = -1
        CASE "Q", CHR$(27): EXIT DO
    END SELECT

    ' ---- Physics ----------------------------------------------------
    IF accel = 1 AND fuel > 0 THEN
        speed = speed + 6 / gear          ' low gears pull harder
        fuel = fuel - .15
    ELSEIF accel = -1 THEN
        speed = speed - 8
    END IF
    speed = speed * .995                  ' air resistance
    IF speed > 1 THEN speed = speed - .3 ELSE speed = 0 ' friction
    IF speed > 199 THEN speed = 199
    IF fuel < 0 THEN fuel = 0
    ' Choose a gear from the speed, then revs from speed in gear.
    gear = INT(speed / 40) + 1: IF gear > 5 THEN gear = 5
    rpm = .8 + (speed - (gear - 1) * 40) / 40 * 5
    IF rpm > 7.9 THEN rpm = 7.9

    ' ---- Needles: erase old, draw new ---------------------------------
    ' Needles are shorter than the ring of numbers so that erasing
    ' them in black never rubs out a number.
    IF oldS >= 0 THEN
        Needle 160, 150, 70, 200, oldS, 0
        Needle 440, 150, 52, 8, oldR, 0
        Needle 580, 270, 35, 100, oldF, 0
    END IF
    Needle 160, 150, 70, 200, speed, 14
    Needle 440, 150, 52, 8, rpm, 14
    IF fuel < 20 THEN fc% = 12 ELSE fc% = 14
    Needle 580, 270, 35, 100, fuel, fc%
    oldS = speed: oldR = rpm: oldF = fuel

    ' Digital readouts under the dials
    LOCATE 19, 17: PRINT USING "### km/h"; speed
    LOCATE 19, 52: PRINT USING "Gear #"; gear
    IF fuel = 0 THEN LOCATE 22, 66: COLOR 12: PRINT "EMPTY!": COLOR 15

    t! = TIMER: DO: LOOP WHILE TIMER - t! < .05 AND TIMER >= t!
LOOP

SCREEN 0: WIDTH 80
END

' ---- Draw a dial face ------------------------------------------------
' The scale sweeps 270 degrees: value 0 sits at the bottom-left
' (225 deg in maths angles) and the maximum at the bottom-right
' (-45 deg). Marks every stepv; red zone from redFrom upward.
SUB Dial (cx!, cy!, r!, maxv!, stepv!, redFrom!, label$)
    CIRCLE (cx!, cy!), r! + 6, 7
    CIRCLE (cx!, cy!), r! + 2, 8
    ' Red warning zone: a thick arc from redFrom to the max.
    IF redFrom! >= 0 THEN
        ' CIRCLE draws arcs counter-clockwise from start to end,
        ' and needs angles between 0 and 2*PI.
        a1! = 315 * PI / 180                            ' end of scale (-45 deg)
        a2! = (225 - 270 * redFrom! / maxv!) * PI / 180 ' start of red zone
        IF a2! < 0 THEN a2! = a2! + 2 * PI
        FOR k = 0 TO 4
            CIRCLE (cx!, cy!), r! - k, 4, a1!, a2!
        NEXT k
    END IF
    ' Scale marks and numbers
    FOR v! = 0 TO maxv! + .001 STEP stepv!
        a! = (225 - 270 * v! / maxv!) * PI / 180
        x1! = cx! + COS(a!) * r!: y1! = cy! - SIN(a!) * r! * ASP
        x2! = cx! + COS(a!) * (r! - 10): y2! = cy! - SIN(a!) * (r! - 10) * ASP
        LINE (x1!, y1!)-(x2!, y2!), 15
        ' Numbers just inside the marks, on big dials only.
        IF r! > 60 THEN
            tx! = cx! + COS(a!) * (r! - 24): ty! = cy! - SIN(a!) * (r! - 24) * ASP
            n$ = LTRIM$(STR$(v!))
            LOCATE INT(ty! / 14) + 1, INT(tx! / 8) + 1 - LEN(n$) \ 2: PRINT n$;
        END IF
    NEXT v!
    ' The label goes at the bottom, in the gap the needle never visits.
    LOCATE INT((cy! + r! * ASP * .6) / 14) + 1, INT(cx! / 8) + 1 - LEN(label$) \ 2
    COLOR 11: PRINT label$;: COLOR 15
END SUB

' ---- Draw (or erase, with c% = 0) one needle -------------------------
SUB Needle (cx!, cy!, r!, maxv!, v!, c%)
    a! = (225 - 270 * v! / maxv!) * PI / 180
    ex! = cx! + COS(a!) * r!
    ey! = cy! - SIN(a!) * r! * ASP
    LINE (cx!, cy!)-(ex!, ey!), c%
    LINE (cx! + 1, cy!)-(ex!, ey!), c%     ' a second line = thicker
    CIRCLE (cx!, cy!), 4, 7                 ' the hub
END SUB
