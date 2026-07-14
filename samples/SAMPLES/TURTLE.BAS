' TURTLE.BAS - Turtle-style drawing with the DRAW macro language
' U/D/L/R/E/F/G/H move, B = move without drawing, N = return after move,
' C = color, S = scale, TA = turn angle, M = move to x,y, P = paint
SCREEN 12
DRAW "BM320,240"
FOR i = 0 TO 35
    DRAW "C" + STR$(9 + i MOD 7) + " TA" + STR$(i * 10) + " NU120 NR40"
NEXT
' A star, step by step
DRAW "BM120,120 C14 S4"
FOR i = 1 TO 5
    DRAW "TA" + STR$((i * 144) MOD 360) + " U60"
NEXT
' A little house
DRAW "BM480,380 C10 TA0 U60 E30 F30 D60 L60 BE10 P2,10"
COLOR 15: LOCATE 29, 2: PRINT "DRAW: a whole drawing language inside BASIC!";
SLEEP
