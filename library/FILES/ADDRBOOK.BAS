' ============================================================
' TITLE:    Address Book (Random-Access Records)
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, random, TYPE, GET, PUT, LOF, database
' SUMMARY:  A menu-driven address book that stores fixed-size TYPE records in a RANDOM file.
' ------------------------------------------------------------
' WHAT IT DOES
'   Keeps contacts in ADDRESS.DAT. Every contact is one RECORD of
'   exactly the same size, so BASIC can jump straight to record
'   number 7 without reading 1-6 first. That is "random access".
'   Deleted contacts are just marked with an empty name, and their
'   slot is reused next time you add someone.
'
' HOW TO USE
'   L list   A add   E edit   D delete   F find   Q quit
'   Record numbers are shown in the list; use them for Edit/Delete.
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE with fixed-length STRING * n fields
'   * OPEN ... FOR RANDOM ... LEN = LEN(record)
'   * PUT #n, recno, var  and  GET #n, recno, var
'   * Number of records = LOF(n) \ LEN(record)
'   * Soft-deleting and slot reuse
'
' THINGS TO TRY
'   * Add a Birthday field (remember to delete ADDRESS.DAT: the
'     record size changes!).
'   * Sort the list alphabetically before printing it.
' ============================================================

TYPE Contact
    nm    AS STRING * 20
    phone AS STRING * 14
    email AS STRING * 26
    age   AS INTEGER          ' 2 bytes
END TYPE                      ' total: 20+14+26+2 = 62 bytes

DECLARE FUNCTION RecCount% ()
DECLARE SUB ShowList ()
DECLARE SUB EnterContact (recNo%)

DIM SHARED c AS Contact
CONST DBFILE = "ADDRESS.DAT"

' RANDOM files are opened once and can be read AND written.
' LEN = tells BASIC the size of one record.
OPEN DBFILE FOR RANDOM AS #1 LEN = LEN(c)

' Brand new file? Put a few sample contacts in so there is
' something to look at.
IF RecCount% = 0 THEN
    FOR i = 1 TO 4
        READ c.nm, c.phone, c.email, c.age
        PUT #1, i, c
    NEXT
END IF

DO
    CLS
    PRINT "ADDRESS BOOK  -"; RecCount%; "slots,"; LEN(c); "bytes each,";
    PRINT LOF(1); "bytes in file"
    PRINT STRING$(79, 196)
    ShowList
    PRINT STRING$(79, 196)
    PRINT "[L]ist [A]dd [E]dit [D]elete [F]ind [Q]uit > ";
    k$ = UCASE$(INPUT$(1)): PRINT k$
    SELECT CASE k$
    CASE "A"
        ' Look for a deleted (blank) slot to reuse first.
        slot = RecCount% + 1
        FOR r = 1 TO RecCount%
            GET #1, r, c
            IF RTRIM$(c.nm) = "" THEN slot = r: EXIT FOR
        NEXT
        EnterContact INT(slot)
    CASE "E", "D"
        INPUT "Record number"; r
        IF r >= 1 AND r <= RecCount% THEN
            IF k$ = "E" THEN
                EnterContact INT(r)
            ELSE
                ' A blank record = deleted. The file does not shrink.
                c.nm = "": c.phone = "": c.email = "": c.age = 0
                PUT #1, r, c
            END IF
        ELSE
            PRINT "No such record.": SLEEP 1
        END IF
    CASE "F"
        LINE INPUT "Search for: "; s$
        s$ = UCASE$(s$): hits = 0
        IF s$ <> "" THEN
            FOR r = 1 TO RecCount%
                GET #1, r, c
                IF INSTR(UCASE$(c.nm + c.phone + c.email), s$) THEN
                    PRINT r; RTRIM$(c.nm); "  "; RTRIM$(c.phone); "  "; RTRIM$(c.email)
                    hits = hits + 1
                END IF
            NEXT
        END IF
        PRINT hits; "match(es). Press a key."
        k$ = INPUT$(1)
    CASE "Q", CHR$(27)
        EXIT DO
    END SELECT
LOOP
CLOSE #1
CLS
PRINT "Address book saved in "; DBFILE
END

DATA "Ada Lovelace", "555-0101", "ada@engine.org", 36
DATA "Grace Hopper", "555-0199", "grace@cobol.mil", 85
DATA "Alan Turing", "555-0142", "alan@bletchley.uk", 41
DATA "Katherine Johnson", "555-0177", "kj@nasa.gov", 101

' Ask for every field and store the record in slot recNo%.
' Fixed-length strings are padded with spaces (or cut short)
' automatically when you assign to them.
SUB EnterContact (recNo%)
    IF recNo% <= RecCount% THEN GET #1, recNo%, c
    PRINT "Editing record"; recNo%; "(press Enter to keep a value)"
    LINE INPUT "Name : "; t$: IF t$ <> "" THEN c.nm = t$
    LINE INPUT "Phone: "; t$: IF t$ <> "" THEN c.phone = t$
    LINE INPUT "Email: "; t$: IF t$ <> "" THEN c.email = t$
    LINE INPUT "Age  : "; t$: IF t$ <> "" THEN c.age = VAL(t$)
    IF RTRIM$(c.nm) = "" THEN PRINT "Name required - not saved.": SLEEP 1: EXIT SUB
    PUT #1, recNo%, c
END SUB

' How many record slots are in the file? Bytes / bytes-per-record.
FUNCTION RecCount%
    RecCount% = LOF(1) \ LEN(c)
END FUNCTION

SUB ShowList
    PRINT " #  Name                 Phone          Email                      Age"
    FOR r = 1 TO RecCount%
        GET #1, r, c
        IF RTRIM$(c.nm) = "" THEN
            PRINT USING "### (empty slot)"; r
        ELSE
            PRINT USING "### \                  \ \            \ \                        \ ###"; r; c.nm; c.phone; c.email; c.age
        END IF
    NEXT
END SUB
