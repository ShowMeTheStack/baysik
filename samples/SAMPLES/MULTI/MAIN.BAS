' MULTI\MAIN.BAS - A program split across several files
'  * '$INCLUDE: pulls in declarations and code from SHAPES.BI
'  * CHAIN runs another program, passing COMMON variables
' $INCLUDE: 'SHAPES.BI'
COMMON SHARED player$, score%
CLS
player$ = "Ada": score% = 42
PRINT "Area of a 3x4 rectangle:"; RectArea(3, 4)
PRINT "Area of a circle, r=2:  "; CircleArea(2)
PRINT
PRINT "Now CHAINing to PART2.BAS with player$ and score%..."
SLEEP 2
CHAIN "PART2.BAS"
