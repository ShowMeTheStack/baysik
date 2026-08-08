' ============================================================
' TITLE:    Mail Merge
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, mail merge, templates, CSV, string replace
' SUMMARY:  Combine a letter template containing {placeholders} with a CSV list of people to produce personalised letters.
' ------------------------------------------------------------
' WHAT IT DOES
'   Word processors have a "mail merge" feature: you write one letter
'   with gaps like {FIRST} and {AMOUNT}, and a list of people, and it
'   writes one personal letter for each person. This program:
'     1. writes LETTER.TPL (the template) and MEMBERS.CSV (the list)
'     2. reads the CSV header to learn the field names
'     3. for each person, replaces every {FIELD} in the template
'     4. writes all letters into LETTERS.TXT, separated by page breaks
'   Then you can page through the finished letters.
'
' HOW TO USE
'   Run it; press a key to see each letter, Esc to stop.
'
' CONCEPTS YOU WILL LEARN
'   * Keeping the template and data in separate files
'   * Using a CSV header row to name the fields
'   * Search-and-replace with INSTR, LEFT$ and MID$
'   * Conditional text: {IF_LATE}...{END} blocks
'   * CHR$(12) form-feed as a page separator
'
' THINGS TO TRY
'   * Add an {AGE} column and a sentence that uses it.
'   * Write each letter to its own file: LETTER1.TXT, LETTER2.TXT...
' ============================================================

DECLARE FUNCTION Replace$ (s$, find$, repl$)
DECLARE SUB SplitCSV (l$, f$(), n)

DIM fieldName$(1 TO 20), value$(1 TO 20)
DIM tpl$(1 TO 100)

' ---- 1. create the template and the data ----------------------
OPEN "LETTER.TPL" FOR OUTPUT AS #1
PRINT #1, "                                  Riverside Chess Club"
PRINT #1, "                                  {DATE}"
PRINT #1, ""
PRINT #1, "Dear {FIRST},"
PRINT #1, ""
PRINT #1, "Thank you for being a member of the club since {SINCE}."
PRINT #1, "Your membership fee for next season is {AMOUNT} pounds."
PRINT #1, "{IF_LATE}"
PRINT #1, "Our records show that last season's fee is still unpaid."
PRINT #1, "Please pay it before the next tournament, {FIRST}."
PRINT #1, "{END}"
PRINT #1, "We look forward to seeing you, and your rating of {RATING},"
PRINT #1, "at the board!"
PRINT #1, ""
PRINT #1, "Yours sincerely,"
PRINT #1, "The Secretary"
CLOSE #1

OPEN "MEMBERS.CSV" FOR OUTPUT AS #1
PRINT #1, "FIRST,LAST,SINCE,AMOUNT,RATING,LATE"
PRINT #1, "Magnus,Berg,2015,40,1850,N"
PRINT #1, "Judit,Polgar,2019,40,1720,Y"
PRINT #1, "Hikaru,Tanaka,2022,25,1400,N"
PRINT #1, "Anna,Ushenina,2010,30,1980,Y"
CLOSE #1

' ---- 2. read the template into memory --------------------------
nT = 0
OPEN "LETTER.TPL" FOR INPUT AS #1
DO WHILE NOT EOF(1)
    nT = nT + 1: LINE INPUT #1, tpl$(nT)
LOOP
CLOSE #1

' ---- 3. merge ----------------------------------------------------
OPEN "MEMBERS.CSV" FOR INPUT AS #1
OPEN "LETTERS.TXT" FOR OUTPUT AS #2
LINE INPUT #1, h$
SplitCSV h$, fieldName$(), nF          ' header row = field names
letters = 0
DO WHILE NOT EOF(1)
    LINE INPUT #1, l$
    IF LEN(l$) > 0 THEN
        SplitCSV l$, value$(), nV
        letters = letters + 1
        IF letters > 1 THEN PRINT #2, CHR$(12)  ' form feed = new page
        ' Is this person late paying? (look up the LATE column)
        late = 0
        FOR f = 1 TO nF
            IF fieldName$(f) = "LATE" AND UCASE$(value$(f)) = "Y" THEN late = -1
        NEXT
        skipping = 0
        FOR t = 1 TO nT
            txt$ = tpl$(t)
            ' Conditional block markers are never printed themselves.
            IF txt$ = "{IF_LATE}" THEN
                skipping = NOT late
            ELSEIF txt$ = "{END}" THEN
                skipping = 0
            ELSEIF NOT skipping THEN
                ' Replace each {FIELD} with this person's value.
                FOR f = 1 TO nF
                    txt$ = Replace$(txt$, "{" + fieldName$(f) + "}", value$(f))
                NEXT
                txt$ = Replace$(txt$, "{DATE}", DATE$)
                PRINT #2, txt$
            END IF
        NEXT
    END IF
LOOP
CLOSE #1, #2

' ---- 4. show the result, one letter per screen ------------------
CLS
PRINT "Merged"; letters; "letters into LETTERS.TXT. Press a key for each, Esc stops."
k$ = INPUT$(1)
OPEN "LETTERS.TXT" FOR INPUT AS #1
n = 1
CLS : COLOR 14: PRINT "--- letter"; n; "---": COLOR 7
DO WHILE NOT EOF(1) AND k$ <> CHR$(27)
    LINE INPUT #1, l$
    IF l$ = CHR$(12) THEN
        PRINT : PRINT "(key for next letter)"
        k$ = INPUT$(1)
        n = n + 1
        CLS : COLOR 14: PRINT "--- letter"; n; "---": COLOR 7
    ELSE
        PRINT l$
    END IF
LOOP
CLOSE #1
PRINT : PRINT "All done."
END

' Replace every occurrence of find$ in s$ with repl$.
' We continue searching AFTER the inserted text, so a replacement
' that contains find$ cannot cause an endless loop.
FUNCTION Replace$ (s$, find$, repl$)
    r$ = s$: p = INSTR(r$, find$)
    DO WHILE p > 0
        r$ = LEFT$(r$, p - 1) + repl$ + MID$(r$, p + LEN(find$))
        p = INSTR(p + LEN(repl$), r$, find$)
    LOOP
    Replace$ = r$
END FUNCTION

' Simple CSV split (no quoted fields needed here).
SUB SplitCSV (l$, f$(), n)
    n = 0: start = 1
    DO
        c = INSTR(start, l$, ",")
        n = n + 1
        IF c = 0 THEN f$(n) = MID$(l$, start): EXIT DO
        f$(n) = MID$(l$, start, c - start)
        start = c + 1
    LOOP
END SUB
