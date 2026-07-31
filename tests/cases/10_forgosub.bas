FOR i = 1 TO 3
  GOSUB inner
  PRINT "outer"; i
NEXT i
DECLARE SUB R (n&)
ON ERROR GOTO h
R 1
END
h: PRINT "err"; ERR: RESUME done
done: END
inner:
  FOR i = 10 TO 11: NEXT i
  i = i - 9
  RETURN
SUB R (n&)
  R n& + 1
END SUB
