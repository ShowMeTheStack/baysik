ON ERROR GOTO handler
PRINT "start"
x = 1 / 0
PRINT "after div0"
ERROR 55
PRINT "after 55"
y% = 40000
PRINT "after overflow"
OPEN "nofile.txt" FOR INPUT AS #1
PRINT "end"
END
handler:
PRINT "Error"; ERR; "at line"; ERL
RESUME NEXT
