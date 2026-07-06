DEFINT A-Z
FOR i = 1 TO 10 STEP 3: PRINT i;: NEXT i: PRINT
FOR i = 3 TO 1 STEP -1: PRINT i;: NEXT: PRINT
FOR i = 5 TO 1: PRINT "never": NEXT
x = 0
DO WHILE x < 3: x = x + 1: LOOP: PRINT "x="; x
DO: x = x - 1: LOOP UNTIL x = 0: PRINT "x="; x
WHILE x < 2: x = x + 1: WEND: PRINT "x="; x
IF x = 2 THEN PRINT "two" ELSE PRINT "not two"
IF x > 5 THEN
  PRINT "big"
ELSEIF x > 1 THEN
  PRINT "medium"
ELSE
  PRINT "small"
END IF
FOR k = 1 TO 4
  SELECT CASE k
    CASE 1: PRINT "one";
    CASE 2, 3: PRINT "two-three";
    CASE IS > 3: PRINT "big";
  END SELECT
NEXT
PRINT
s$ = "m"
SELECT CASE s$
  CASE "a" TO "f": PRINT "early"
  CASE ELSE: PRINT "late"
END SELECT
GOSUB 100
ON 2 GOSUB 200, 300
ON 3 GOTO 200, 300, 400
PRINT "skipped"
400 PRINT "at 400"
FOR i = 1 TO 10
  IF i = 4 THEN EXIT FOR
NEXT
PRINT "exit at"; i
DO
  n = n + 1
  IF n = 7 THEN EXIT DO
LOOP
PRINT "n="; n
END
100 PRINT "sub100": RETURN
200 PRINT "sub200": RETURN
300 PRINT "sub300": RETURN
