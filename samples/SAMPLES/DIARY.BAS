' DIARY.BAS - Keep a diary in a text file
' Concepts: OPEN ... FOR APPEND / INPUT, PRINT #, LINE INPUT #, EOF, DATE$, TIME$
CLS
PRINT "My Diary (stored in DIARY.TXT - see it in the Files panel!)"
PRINT
ON ERROR GOTO NoFile
OPEN "DIARY.TXT" FOR INPUT AS #1
PRINT "Previous entries:"
COLOR 11
DO WHILE NOT EOF(1)
    LINE INPUT #1, l$
    PRINT "  "; l$
LOOP
CLOSE #1
COLOR 7
Continue:
ON ERROR GOTO 0
PRINT
LINE INPUT "Write today's entry (Enter to skip): "; e$
IF e$ <> "" THEN
    OPEN "DIARY.TXT" FOR APPEND AS #1
    PRINT #1, DATE$; " "; LEFT$(TIME$, 5); "  "; e$
    CLOSE #1
    PRINT "Saved."
END IF
END

NoFile:
    PRINT "(no diary yet - this will be the first entry)"
    RESUME Continue
