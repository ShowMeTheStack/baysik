' ============================================================
' TITLE:    Class Records Database
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     TYPE records, database, sorting, index array, searching
' SUMMARY:  An in-memory table of student records you can sort by any column, filter and summarise - using an index array so records never move.
' ------------------------------------------------------------
' WHAT IT DOES
'   A TYPE groups different fields (name, age, city, score) into
'   one RECORD, and an array of records makes a TABLE - a tiny
'   database living in memory.
'
'   Sorting a table of big records by swapping them around is
'   slow and loses the original order. Instead we sort an INDEX
'   array: idx(1) is the number of the record that comes first,
'   idx(2) the second, and so on. Only small integers get swapped.
'   Real databases use the same idea (an "index") to show one table
'   sorted many different ways.
'
' HOW TO USE
'   1 sort by name    2 sort by age    3 sort by city
'   4 sort by score   5 search by city 6 add a student
'   7 statistics      Q quit
'
' CONCEPTS YOU WILL LEARN
'   * TYPE ... END TYPE with fixed-length strings
'   * Sorting through an index array (insertion sort)
'   * A comparison function that understands several keys
'     (e.g. city, and then name for ties)
'   * Simple aggregate queries: count, average, max
'
' THINGS TO TRY
'   * Add a "grade" field computed from the score
'   * Save the table to a file with WRITE # and load it back
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Before% (a AS INTEGER, b AS INTEGER, k AS INTEGER)
DECLARE SUB SortBy (k AS INTEGER)
DECLARE SUB ShowTable (title$)

TYPE Student
    nm AS STRING * 10
    age AS INTEGER
    city AS STRING * 10
    score AS SINGLE
END TYPE
CONST MAXS = 30
DIM SHARED db(1 TO MAXS) AS Student, idx(1 TO MAXS), n

DO
    READ a$
    IF a$ = "*" THEN EXIT DO
    n = n + 1
    db(n).nm = a$
    READ db(n).age, c$, db(n).score
    db(n).city = c$
LOOP
DATA Mia, 12, Leeds, 88.5, Omar, 11, Paris, 92, Zoe, 13, Leeds, 75
DATA Liam, 12, Oslo, 81, Ava, 11, Paris, 95.5, Noah, 13, Oslo, 67
DATA Ella, 12, Leeds, 88.5, Kai, 11, Rome, 79, Ivy, 13, Rome, 90
DATA *

FOR i = 1 TO n: idx(i) = i: NEXT i     ' start in original order
title$ = "Original order"
DO
    CLS
    ShowTable title$
    PRINT
    PRINT "1 Name  2 Age  3 City  4 Score  5 Search city  6 Add  7 Stats  Q Quit"
    LINE INPUT "Choice: "; ch$
    ch$ = UCASE$(LEFT$(LTRIM$(ch$), 1))
    SELECT CASE ch$
    CASE "1": SortBy 1: title$ = "Sorted by NAME"
    CASE "2": SortBy 2: title$ = "Sorted by AGE (then name)"
    CASE "3": SortBy 3: title$ = "Sorted by CITY (then name)"
    CASE "4": SortBy 4: title$ = "Sorted by SCORE, highest first"
    CASE "5"
        LINE INPUT "City to find: "; c$
        c$ = UCASE$(LTRIM$(RTRIM$(c$)))
        PRINT
        hits = 0
        FOR i = 1 TO n
            ' compare without the padding spaces and ignoring case
            IF UCASE$(RTRIM$(db(i).city)) = c$ THEN
                PRINT "  "; db(i).nm; db(i).age; "  "; db(i).city; db(i).score
                hits = hits + 1
            END IF
        NEXT i
        PRINT hits; "match(es). Press a key...": k$ = INPUT$(1)
    CASE "6"
        IF n = MAXS THEN
            PRINT "Table full!": k$ = INPUT$(1)
        ELSE
            LINE INPUT "Name: "; a$
            IF a$ <> "" THEN
                INPUT "Age"; ag
                LINE INPUT "City: "; c$
                INPUT "Score"; sc!
                n = n + 1
                db(n).nm = a$: db(n).age = ag: db(n).city = c$: db(n).score = sc!
                idx(n) = n                 ' new record goes at the end of the view
                title$ = "Added " + a$
            END IF
        END IF
    CASE "7"
        ' Aggregate "queries" over the whole table.
        total! = 0: best = 1
        FOR i = 1 TO n
            total! = total! + db(i).score
            IF db(i).score > db(best).score THEN best = i
        NEXT i
        PRINT
        PRINT "Students:"; n
        PRINT USING "Average score: ###.##"; total! / n
        PRINT "Top student:  "; RTRIM$(db(best).nm); " with"; db(best).score
        ' Per-city averages: sort by city, then walk the groups.
        SortBy 3: title$ = "Sorted by CITY (then name)"
        PRINT "Average by city:"
        i = 1
        DO WHILE i <= n
            c$ = db(idx(i)).city: s! = 0: cnt = 0
            DO WHILE i <= n
                IF db(idx(i)).city <> c$ THEN EXIT DO
                s! = s! + db(idx(i)).score: cnt = cnt + 1: i = i + 1
            LOOP
            PRINT USING "   \        \ ##  students, average ###.#"; c$; cnt; s! / cnt
        LOOP
        PRINT "Press a key...": k$ = INPUT$(1)
    CASE "Q"
        EXIT DO
    END SELECT
LOOP
PRINT "Database closed."
END

' Before%: TRUE if record a should be listed before record b when
' sorting by key k. Ties are broken by name, so the order is
' always predictable.
FUNCTION Before% (a AS INTEGER, b AS INTEGER, k AS INTEGER)
    SELECT CASE k
    CASE 2
        IF db(a).age <> db(b).age THEN Before% = db(a).age < db(b).age: EXIT FUNCTION
    CASE 3
        IF db(a).city <> db(b).city THEN Before% = db(a).city < db(b).city: EXIT FUNCTION
    CASE 4
        IF db(a).score <> db(b).score THEN Before% = db(a).score > db(b).score: EXIT FUNCTION
    END SELECT
    Before% = db(a).nm < db(b).nm            ' key 1, or a tie
END FUNCTION

SUB ShowTable (title$)
    PRINT "STUDENT DATABASE - "; title$
    PRINT
    PRINT " view rec  name        age  city        score"
    PRINT " ---- ---  ----------  ---  ----------  -----"
    FOR i = 1 TO n
        r = idx(i)
        PRINT USING "  ##  ##  \        \  ##   \        \  ###.#"; i; r; db(r).nm; db(r).age; db(r).city; db(r).score
    NEXT i
    PRINT
    PRINT "'rec' is where the record really sits in the db() array -"
    PRINT "it never moves. Only the idx() list is re-ordered."
END SUB

' SortBy: insertion sort on the INDEX array.
' Take each entry and slide it left past every entry it should
' come before - like sorting playing cards in your hand.
SUB SortBy (k AS INTEGER)
    FOR i = 2 TO n
        cur = idx(i)
        j = i - 1
        DO WHILE j >= 1
            IF NOT Before%(cur, idx(j), k) THEN EXIT DO
            idx(j + 1) = idx(j)
            j = j - 1
        LOOP
        idx(j + 1) = cur
    NEXT i
END SUB
