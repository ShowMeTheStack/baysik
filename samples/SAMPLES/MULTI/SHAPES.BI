' SHAPES.BI - included by MAIN.BAS with '$INCLUDE
DECLARE FUNCTION RectArea! (w!, h!)
DECLARE FUNCTION CircleArea! (r!)
CONST PI = 3.14159

FUNCTION RectArea! (w!, h!)
    RectArea! = w! * h!
END FUNCTION

FUNCTION CircleArea! (r!)
    CircleArea! = PI * r! * r!
END FUNCTION
