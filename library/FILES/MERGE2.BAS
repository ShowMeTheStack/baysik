' ============================================================
' TITLE:    Merging Two Sorted Files
' CATEGORY: File I/O
' LEVEL:    Intermediate
' TAGS:     files, merge, sorting, algorithms, sequential
' SUMMARY:  Merge two alphabetical guest lists into one sorted file, reading each file only once.
' ------------------------------------------------------------
' WHAT IT DOES
'   Two classes each have a sorted list of pupils going on a trip.
'   To make one combined, sorted list we do NOT load everything and
'   sort again. Instead we read both files side by side and always
'   write whichever current name comes first - the "merge" step at
'   the heart of merge sort. It works for files far bigger than
'   memory, because only two names are held at any moment.
'   Names in BOTH lists are written once and reported as duplicates.
'   An animated view shows the two "read heads" moving.
'
' HOW TO USE
'   Press a key to step through the merge (or hold one down).
'   Press F at any time to finish at full speed.
'
' CONCEPTS YOU WILL LEARN
'   * Reading two sequential files in step
'   * A "look-ahead" variable for each file plus an end-flag
'   * The merge algorithm and why it is O(n)
'   * Removing duplicates while merging
'
' THINGS TO TRY
'   * Merge three files at once.
'   * Instead of removing duplicates, write them to DUPES.TXT.
' ============================================================

DECLARE SUB ReadNext (fileNo%, v$, done%)

' ---- create the two sorted input files -------------------------
OPEN "CLASS_A.TXT" FOR OUTPUT AS #1
FOR i = 1 TO 8: READ n$: PRINT #1, n$: NEXT
CLOSE #1
OPEN "CLASS_B.TXT" FOR OUTPUT AS #1
FOR i = 1 TO 7: READ n$: PRINT #1, n$: NEXT
CLOSE #1

CLS
PRINT "MERGE TWO SORTED FILES      (any key = one step, F = finish)"
PRINT
PRINT "CLASS_A.TXT", "CLASS_B.TXT", "TRIP.TXT (merged)"
PRINT STRING$(60, "-")

OPEN "CLASS_A.TXT" FOR INPUT AS #1
OPEN "CLASS_B.TXT" FOR INPUT AS #2
OPEN "TRIP.TXT" FOR OUTPUT AS #3

' Prime the pumps: read the first name from each file.
ReadNext 1, a$, doneA%
ReadNext 2, b$, doneB%
written = 0: dupes = 0: fast = 0: row = 5

DO WHILE NOT (doneA% AND doneB%)
    ' Pick which one to write. When one file is finished we just
    ' copy the rest of the other one.
    IF doneB% THEN
        pick = 1
    ELSEIF doneA% THEN
        pick = 2
    ELSEIF UCASE$(a$) < UCASE$(b$) THEN
        pick = 1
    ELSEIF UCASE$(a$) > UCASE$(b$) THEN
        pick = 2
    ELSE
        pick = 3                      ' same name in both lists
    END IF

    SELECT CASE pick
    CASE 1: w$ = a$
    CASE 2: w$ = b$
    CASE 3: w$ = a$: dupes = dupes + 1
    END SELECT
    PRINT #3, w$
    written = written + 1

    ' Show what is happening on this step.
    IF row < 23 THEN
        LOCATE row, 1
        IF doneA% THEN PRINT "(end)"; ELSE PRINT a$;
        LOCATE row, 15
        IF doneB% THEN PRINT "(end)"; ELSE PRINT b$;
        LOCATE row, 29: COLOR 14: PRINT "-> "; w$; : COLOR 7
        IF pick = 3 THEN PRINT "  (in both - written once)";
        row = row + 1
    END IF
    IF NOT fast THEN
        k$ = INPUT$(1)
        IF UCASE$(k$) = "F" THEN fast = -1
        IF k$ = CHR$(27) THEN EXIT DO
    END IF

    ' Advance whichever file(s) we used.
    IF pick = 1 OR pick = 3 THEN ReadNext 1, a$, doneA%
    IF pick = 2 OR pick = 3 THEN ReadNext 2, b$, doneB%
LOOP
CLOSE #1, #2, #3

LOCATE 23, 1
PRINT "Wrote"; written; "names to TRIP.TXT,"; dupes; "duplicate(s) removed."
PRINT "Press a key to view TRIP.TXT.";
k$ = INPUT$(1)
CLS
PRINT "TRIP.TXT:"
OPEN "TRIP.TXT" FOR INPUT AS #1
i = 0
DO WHILE NOT EOF(1)
    LINE INPUT #1, n$: i = i + 1
    PRINT USING "##. &"; i; n$
LOOP
CLOSE #1
END

' Class A (sorted)
DATA Aisha, Ben, Chloe, Dev, Ella, Jack, Mia, Zoe
' Class B (sorted)
DATA Amir, Ben, Freya, Hugo, Mia, Noah, Tom

' Read the next line from a file, or set done% when it runs out.
' Keeping a "current value" for each file is called look-ahead.
SUB ReadNext (fileNo%, v$, done%)
    IF EOF(fileNo%) THEN
        done% = -1: v$ = ""
    ELSE
        LINE INPUT #fileNo%, v$
        done% = 0
    END IF
END SUB
