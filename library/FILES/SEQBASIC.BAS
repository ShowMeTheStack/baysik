' ============================================================
' TITLE:    Your First Text File
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, sequential, OPEN, PRINT#, INPUT#, EOF
' SUMMARY:  Write a shopping list to a file, then read it back line by line.
' ------------------------------------------------------------
' WHAT IT DOES
'   Creates a small text file called SHOPPING.TXT on the virtual
'   disk, writes a few items into it, closes it, and then opens it
'   again to read everything back and show it on the screen.
'
' HOW TO USE
'   Just run it. Press any key at the end to finish.
'
' CONCEPTS YOU WILL LEARN
'   * OPEN ... FOR OUTPUT  - create (or wipe) a file for writing
'   * PRINT #n             - write a line of text into a file
'   * CLOSE                - finish with a file so data is saved
'   * OPEN ... FOR INPUT   - open an existing file for reading
'   * LINE INPUT #n        - read one whole line back
'   * EOF(n)               - "end of file": are we out of lines?
'
' THINGS TO TRY
'   * Add more items to the DATA line and run again.
'   * Change OUTPUT to APPEND and run twice: what happens?
'   * Count the lines while reading and print the total.
' ============================================================

CLS
PRINT "=== Writing SHOPPING.TXT ==="
PRINT

' A "file number" is like a ticket: we choose #1 and use it every
' time we want to talk to this file. Numbers 1 to 255 are allowed.
' FOR OUTPUT means "make a new, empty file" (an old one is erased!).
OPEN "SHOPPING.TXT" FOR OUTPUT AS #1

' We keep the list in DATA lines so it is easy to change.
' The word "END" marks the end of the list.
DO
    READ item$
    IF item$ = "END" THEN EXIT DO
    ' PRINT #1 works just like PRINT, except the text goes into the
    ' file instead of onto the screen. Each PRINT makes one line.
    PRINT #1, item$
    PRINT "  wrote: "; item$
LOOP

' CLOSE tells BASIC we are done. Always close files you open:
' it makes sure every byte really ends up on the disk.
CLOSE #1

PRINT
PRINT "=== Reading it back ==="
PRINT

' Now open the SAME file, but FOR INPUT (reading).
OPEN "SHOPPING.TXT" FOR INPUT AS #1

n = 0
' EOF(1) becomes true (-1) once there is nothing left to read.
' Checking it BEFORE each read stops "Input past end" errors.
DO WHILE NOT EOF(1)
    ' LINE INPUT # reads a whole line, commas and all.
    LINE INPUT #1, text$
    n = n + 1
    PRINT USING "  ##. &"; n; text$
LOOP
CLOSE #1

PRINT
PRINT "The file holds"; n; "items."
PRINT "Its size on disk is";
' LOF = "length of file" in bytes. We have to open the file to ask.
OPEN "SHOPPING.TXT" FOR INPUT AS #1
PRINT LOF(1); "bytes (each line ends with 2 hidden bytes: CR+LF)."
CLOSE #1

PRINT
PRINT "Press any key..."
k$ = INPUT$(1)
END

DATA "Milk", "Bread", "Apples (green)", "Cheese, cheddar", "Eggs", "END"
