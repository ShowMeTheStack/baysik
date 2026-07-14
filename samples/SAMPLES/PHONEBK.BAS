' PHONEBK.BAS - A tiny phone book stored in a RANDOM-access file
' Concepts: TYPE records, OPEN ... FOR RANDOM, GET/PUT, LOF, SELECT CASE menu
TYPE Contact
    nm AS STRING * 20
    phone AS STRING * 14
END TYPE
DIM c AS Contact
OPEN "PHONES.DAT" FOR RANDOM AS #1 LEN = LEN(c)
DO
    count = LOF(1) \ LEN(c)
    CLS
    COLOR 14: PRINT "PHONE BOOK"; : COLOR 7: PRINT " ("; LTRIM$(STR$(count)); " entries, stored in PHONES.DAT)"
    PRINT
    PRINT "1) List   2) Add   3) Find   4) Quit"
    INPUT "Choice"; ch$
    SELECT CASE ch$
        CASE "1"
            FOR i = 1 TO count
                GET #1, i, c
                PRINT USING "### "; i; : PRINT c.nm; c.phone
            NEXT
            PRINT : PRINT "Press a key"; : SLEEP
        CASE "2"
            LINE INPUT "Name : "; n$
            LINE INPUT "Phone: "; p$
            c.nm = n$: c.phone = p$
            PUT #1, count + 1, c
        CASE "3"
            LINE INPUT "Search for: "; s$
            found = 0
            FOR i = 1 TO count
                GET #1, i, c
                IF INSTR(UCASE$(c.nm), UCASE$(s$)) THEN PRINT c.nm; c.phone: found = found + 1
            NEXT
            PRINT found; "found. Press a key"; : SLEEP
    END SELECT
LOOP UNTIL ch$ = "4"
CLOSE #1
PRINT "Goodbye!"
