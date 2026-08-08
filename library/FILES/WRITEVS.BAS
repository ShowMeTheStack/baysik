' ============================================================
' TITLE:    WRITE# vs PRINT# Showdown
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, WRITE#, PRINT#, INPUT#, delimiters, quotes
' SUMMARY:  See exactly why WRITE# is safer than PRINT# when saving data you read back with INPUT#.
' ------------------------------------------------------------
' WHAT IT DOES
'   Saves the same three records twice: once with PRINT # and once
'   with WRITE #. It then shows the raw text inside each file and
'   tries to read the records back with INPUT #. The PRINT# version
'   gets confused by the comma inside "Smith, Jr." - the WRITE#
'   version does not, because WRITE# puts quotes around strings.
'
' HOW TO USE
'   Run it and read the screens. Press a key to move on.
'
' CONCEPTS YOU WILL LEARN
'   * WRITE # adds commas between items and "quotes" round strings
'   * PRINT # writes text exactly as PRINT would show it
'   * INPUT # splits data at commas and line ends
'   * Showing a file's raw contents with LINE INPUT #
'
' THINGS TO TRY
'   * Add a name with a quote mark (") in it. What breaks now?
'   * Write numbers with PRINT # using ; and , and compare spacing.
' ============================================================

DECLARE SUB ShowRaw (f$)
DECLARE SUB ReadBack (f$)

CLS
' --- 1. Save with PRINT # ------------------------------------
' We separate the fields with "," ourselves, like a beginner might.
OPEN "PRINTED.TXT" FOR OUTPUT AS #1
RESTORE People
FOR i = 1 TO 3
    READ nm$, age, city$
    PRINT #1, nm$; ","; age; ","; city$
NEXT
CLOSE #1

' --- 2. Save with WRITE # ------------------------------------
' WRITE # does the commas AND the quotes for us.
OPEN "WRITTEN.TXT" FOR OUTPUT AS #1
RESTORE People
FOR i = 1 TO 3
    READ nm$, age, city$
    WRITE #1, nm$, age, city$
NEXT
CLOSE #1

PRINT "Raw contents of PRINTED.TXT  (made with PRINT #)"
ShowRaw "PRINTED.TXT"
PRINT
PRINT "Raw contents of WRITTEN.TXT  (made with WRITE #)"
ShowRaw "WRITTEN.TXT"
PRINT
PRINT "Notice: WRITE# wrapped each string in quotes and"
PRINT "left no extra spaces around the number."
PRINT
PRINT "Press a key to read both files back with INPUT #..."
k$ = INPUT$(1)

CLS
PRINT "Reading PRINTED.TXT with INPUT #  name, age, city"
ReadBack "PRINTED.TXT"
PRINT
PRINT "Reading WRITTEN.TXT with INPUT #  name, age, city"
ReadBack "WRITTEN.TXT"
PRINT
PRINT "In PRINTED.TXT the comma in 'Smith, Jr.' split the name in"
PRINT "two, so every field after it slid into the wrong variable!"
PRINT "Rule of thumb: WRITE# for data, PRINT# for human reports."
PRINT
PRINT "Press a key to finish."
k$ = INPUT$(1)
END

People:
DATA "Ann Lee", 34, "Leeds"
DATA "Bob Smith, Jr.", 51, "Boston"
DATA "Cy Young", 27, "Austin"

' Display every line of a file exactly as stored, between | marks
' so you can see leading and trailing spaces.
SUB ShowRaw (f$)
    OPEN f$ FOR INPUT AS #2
    DO WHILE NOT EOF(2)
        LINE INPUT #2, l$
        PRINT "  |"; l$; "|"
    LOOP
    CLOSE #2
END SUB

' Try to read three records of (string, number, string).
' Mismatched data can trigger an error (e.g. "Input past end"), so we
' guard with EOF before every single read.
SUB ReadBack (f$)
    OPEN f$ FOR INPUT AS #2
    FOR r = 1 TO 3
        IF EOF(2) THEN PRINT "  (ran out of data!)": EXIT FOR
        INPUT #2, a$
        IF EOF(2) THEN PRINT "  (ran out of data!)": EXIT FOR
        ' Read the age as a string too, so a bad value cannot crash us.
        INPUT #2, b$
        IF EOF(2) THEN c$ = "???" ELSE INPUT #2, c$
        PRINT "  name=["; a$; "] age=["; b$; "] city=["; c$; "]"
    NEXT
    CLOSE #2
END SUB
