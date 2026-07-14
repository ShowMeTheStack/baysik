' HELLO.BAS - your first program!
' Press F5 to run it. Change the words and run it again.
CLS
COLOR 14
PRINT "Hello! Welcome to BASIC."
COLOR 7
PRINT
INPUT "What is your name"; name$
PRINT
FOR i = 1 TO 5
    COLOR i + 9
    PRINT "Nice to meet you, "; name$; "!"
NEXT i
COLOR 7
PRINT
PRINT "Try the Examples button for games, graphics and music."
END
