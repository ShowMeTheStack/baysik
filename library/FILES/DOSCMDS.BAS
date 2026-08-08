' ============================================================
' TITLE:    Folders & Files: MKDIR, CHDIR, NAME, KILL, RMDIR
' CATEGORY: File I/O
' LEVEL:    Beginner
' TAGS:     files, directories, MKDIR, CHDIR, RMDIR, NAME, KILL, FILES
' SUMMARY:  A guided tour of the disk-management statements: make folders, move into them, rename and delete files.
' ------------------------------------------------------------
' WHAT IT DOES
'   Walks step by step through organising a "school project" on the
'   disk: it makes a PROJECT folder with two sub-folders, creates
'   files inside them, renames one, moves one into another folder
'   (NAME can do that too!), deletes some with KILL and wildcards,
'   and finally tidies everything away with RMDIR.
'   After every step it shows the result with FILES.
'
' HOW TO USE
'   Press a key after each step to continue.
'
' CONCEPTS YOU WILL LEARN
'   * MKDIR "name"   make a directory (folder)
'   * CHDIR "name"   go into it;  CHDIR ".." goes back up
'   * NAME "old" AS "new"   rename (or move) a file
'   * KILL "file"    delete a file (wildcards allowed: KILL "*.TMP")
'   * RMDIR "name"   remove an EMPTY directory
'   * Paths like DRAFTS\STORY.TXT
'
' THINGS TO TRY
'   * Try RMDIR on a folder that still has files in it. What error?
'   * Add a third sub-folder called BACKUP and copy files into it.
' ============================================================

DECLARE SUB Stepp (msg$)
DECLARE SUB MakeText (f$, t$)

CLS
' If an old PROJECT folder is left over from an earlier run, the
' MKDIR below would fail with "Path/File access error" (75).
' We ignore that one error so the tour can run again.
ON ERROR GOTO Already

Stepp "1. MKDIR " + CHR$(34) + "PROJECT" + CHR$(34) + " makes a new folder."
MKDIR "PROJECT"
FILES

Stepp "2. CHDIR " + CHR$(34) + "PROJECT" + CHR$(34) + " goes inside, and we make two sub-folders."
CHDIR "PROJECT"
MKDIR "DRAFTS"
MKDIR "FINAL"
FILES
PRINT "(Folders are shown with <DIR>.)"

Stepp "3. Create files inside DRAFTS using a path."
MakeText "DRAFTS\STORY.TXT", "Once upon a time..."
MakeText "DRAFTS\IDEAS.TXT", "Dragons? Robots? Both!"
MakeText "DRAFTS\TEMP1.TMP", "scratch"
MakeText "DRAFTS\TEMP2.TMP", "scratch"
FILES "DRAFTS\*.*"

Stepp "4. NAME renames: STORY.TXT becomes CHAPTER1.TXT."
NAME "DRAFTS\STORY.TXT" AS "DRAFTS\CHAPTER1.TXT"
FILES "DRAFTS\*.*"

Stepp "5. NAME can also MOVE a file to another folder."
NAME "DRAFTS\CHAPTER1.TXT" AS "FINAL\CHAPTER1.TXT"
PRINT "DRAFTS:": FILES "DRAFTS\*.*"
PRINT "FINAL:": FILES "FINAL\*.*"

Stepp "6. KILL with a wildcard deletes every .TMP file at once."
KILL "DRAFTS\*.TMP"
FILES "DRAFTS\*.*"

Stepp "7. Read the moved file to prove it survived the trip."
OPEN "FINAL\CHAPTER1.TXT" FOR INPUT AS #1
LINE INPUT #1, l$
CLOSE #1
PRINT "FINAL\CHAPTER1.TXT says: "; l$

Stepp "8. RMDIR only removes EMPTY folders. Watch it fail on DRAFTS..."
RMDIR "DRAFTS"
PRINT "...so we KILL the files first, then RMDIR works:"
KILL "DRAFTS\*.*"
RMDIR "DRAFTS"
FILES

Stepp "9. Clean up everything and go back up with CHDIR " + CHR$(34) + ".." + CHR$(34)
KILL "FINAL\*.*"
RMDIR "FINAL"
CHDIR ".."
RMDIR "PROJECT"
FILES
PRINT
PRINT "Tour complete - the disk is as tidy as we found it!"
END

Already:
    SELECT CASE ERR
    CASE 75                  ' folder exists, or folder not empty
        PRINT "   ** Error 75: Path/File access error (folder exists or is not empty)"
    CASE 53
        PRINT "   ** Error 53: File not found"
    CASE ELSE
        PRINT "   ** Error"; ERR
    END SELECT
    RESUME NEXT

SUB MakeText (f$, t$)
    OPEN f$ FOR OUTPUT AS #1
    PRINT #1, t$
    CLOSE #1
    PRINT "   wrote "; f$
END SUB

' Wait for a key, clear the screen and announce the next step.
' (Named Stepp because STEP is a BASIC keyword.)
SUB Stepp (msg$)
    IF CSRLIN > 2 THEN PRINT : PRINT "Press a key...": k$ = INPUT$(1)
    CLS
    COLOR 14: PRINT msg$: COLOR 7
    PRINT
END SUB
