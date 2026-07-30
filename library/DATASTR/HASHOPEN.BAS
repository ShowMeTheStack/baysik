' ============================================================
' TITLE:    Phone Book (Open Addressing Hash)
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     hash table, open addressing, linear probing, tombstones
' SUMMARY:  A phone book stored in one flat hash table using linear probing, with tombstones for deletes and a live view of every slot.
' ------------------------------------------------------------
' WHAT IT DOES
'   OPEN ADDRESSING is a hash table with no linked lists at all.
'   Every entry lives directly in the table. If the home slot
'   (given by the hash) is taken, we PROBE: try the next slot,
'   then the next, wrapping around at the end. This is called
'   LINEAR PROBING.
'
'   Deleting is tricky! If we simply emptied a slot, a later
'   search could stop early at the hole and miss entries that had
'   probed past it. So deleted slots become TOMBSTONES ("this was
'   used, keep looking") which inserts are allowed to reuse.
'
'   The table is drawn on the right. Each entry shows how far it
'   is from its home slot, so you can watch CLUSTERS form.
'
' HOW TO USE
'   A name number   add or update   e.g.  A Sam 555-1234
'   F name          find
'   D name          delete
'   R               add 8 random people
'   Q               quit
'
' CONCEPTS YOU WILL LEARN
'   * Linear probing with (slot + 1) MOD size
'   * The three slot states: EMPTY, USED, DELETED (tombstone)
'   * Why a table should not get too full (load factor)
'
' THINGS TO TRY
'   * Use quadratic probing: slot = (home + i*i) MOD size
'   * Make TSIZE 13 and fill it - what happens when it's full?
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Hash% (k$)
DECLARE FUNCTION FindSlot% (k$, probes AS INTEGER)
DECLARE SUB Show (hilite AS INTEGER)

CONST TSIZE = 19
CONST EMPTY = 0, USED = 1, DELETED = 2
TYPE Slot
    state AS INTEGER
    who AS STRING * 10
    phone AS STRING * 9
END TYPE
DIM SHARED tb(0 TO TSIZE - 1) AS Slot
DIM SHARED count

RANDOMIZE TIMER
msg$ = "Type R to add some people, or A name number."
hl = -1
DO
    Show hl
    LOCATE 22, 1: PRINT LEFT$(msg$ + SPACE$(79), 79);
    LOCATE 23, 1: PRINT SPACE$(79);
    LOCATE 23, 1: LINE INPUT "> "; c$
    c$ = LTRIM$(RTRIM$(c$))
    op$ = UCASE$(LEFT$(c$, 1))
    rest$ = LTRIM$(MID$(c$, 2))
    ' split rest$ into the name and (optional) number
    sp = INSTR(rest$, " ")
    IF sp THEN nm$ = LEFT$(rest$, sp - 1): ph$ = LTRIM$(MID$(rest$, sp + 1)) ELSE nm$ = rest$: ph$ = "?"
    nm$ = UCASE$(LEFT$(nm$, 10))
    hl = -1
    SELECT CASE op$
    CASE "A"
        IF nm$ = "" THEN
            msg$ = "Usage: A name number"
        ELSE
            GOSUB AddOne
        END IF
    CASE "F"
        s = FindSlot%(nm$, probes)
        IF s >= 0 THEN
            msg$ = RTRIM$(nm$) + ": " + tb(s).phone + "  (found in" + STR$(probes) + " probe(s))"
            hl = s
        ELSE
            msg$ = nm$ + " not found after" + STR$(probes) + " probe(s)."
        END IF
    CASE "D"
        s = FindSlot%(nm$, probes)
        IF s >= 0 THEN
            tb(s).state = DELETED          ' leave a tombstone
            count = count - 1
            msg$ = nm$ + " deleted; slot" + STR$(s) + " is now a tombstone."
            hl = s
        ELSE
            msg$ = nm$ + " not found."
        END IF
    CASE "R"
        FOR r = 1 TO 8
            IF count >= TSIZE - 1 THEN EXIT FOR
            nm$ = ""
            FOR j = 1 TO 4 + INT(RND * 3)    ' made-up names like "KOBE"
                IF j MOD 2 THEN nm$ = nm$ + MID$("BDFGKLMNPRSTVZ", INT(RND * 14) + 1, 1) ELSE nm$ = nm$ + MID$("AEIOU", INT(RND * 5) + 1, 1)
            NEXT j
            ph$ = "555-" + RIGHT$(STR$(1000 + INT(RND * 9000)), 4)
            GOSUB AddOne
        NEXT r
        msg$ = "Added random people. Notice the clusters!"
    CASE "Q", CHR$(27)
        EXIT DO
    CASE ELSE
        msg$ = "Commands: A name number / F name / D name / R / Q"
    END SELECT
LOOP
CLS : PRINT "Phone book closed."
END

' Insert or update nm$. Update if present; otherwise take the
' FIRST empty-or-tombstone slot along the probe sequence.
AddOne:
    s = FindSlot%(nm$, probes)
    IF s >= 0 THEN tb(s).phone = ph$: msg$ = nm$ + " updated.": hl = s: RETURN
    IF count >= TSIZE - 1 THEN msg$ = "Table is (nearly) full!": RETURN
    s = Hash%(nm$)
    DO WHILE tb(s).state = USED
        s = (s + 1) MOD TSIZE
    LOOP
    tb(s).state = USED: tb(s).who = nm$: tb(s).phone = ph$
    count = count + 1
    msg$ = nm$ + " stored in slot" + STR$(s) + " (home" + STR$(Hash%(nm$)) + ")"
    hl = s
    RETURN

' FindSlot%: returns the slot holding k$, or -1.
' Search stops at an EMPTY slot, but walks over tombstones.
FUNCTION FindSlot% (k$, probes AS INTEGER)
    s = Hash%(k$): probes = 0
    pad$ = LEFT$(k$ + SPACE$(10), 10)
    DO
        probes = probes + 1
        IF tb(s).state = EMPTY THEN EXIT DO
        IF tb(s).state = USED AND tb(s).who = pad$ THEN FindSlot% = s: EXIT FUNCTION
        s = (s + 1) MOD TSIZE
    LOOP UNTIL probes >= TSIZE           ' every slot checked
    FindSlot% = -1
END FUNCTION

' Hash%: sum of (position * character code), MOD table size.
FUNCTION Hash% (k$)
    DIM h AS LONG
    FOR i = 1 TO LEN(k$)
        h = (h + i * ASC(MID$(k$, i, 1))) MOD TSIZE
    NEXT i
    Hash% = h
END FUNCTION

SUB Show (hilite AS INTEGER)
    CLS
    PRINT "OPEN-ADDRESSING PHONE BOOK"
    PRINT "Linear probing in a table of"; TSIZE; "slots"
    PRINT
    PRINT "Entries:"; count
    PRINT USING "Load factor: #.##"; count / TSIZE
    PRINT
    PRINT "Legend:"
    PRINT "  .         empty slot"
    PRINT "  RIP       tombstone"
    PRINT "  +n        n steps from"
    PRINT "            its home slot"
    LOCATE 1, 40: PRINT "slot state  name       phone    "
    FOR i = 0 TO TSIZE - 1
        LOCATE 2 + i, 40
        IF i = hilite THEN COLOR 0, 7 ELSE COLOR 7, 0
        PRINT USING "## "; i;
        SELECT CASE tb(i).state
        CASE EMPTY: PRINT "  .    "; SPACE$(25);
        CASE DELETED: COLOR 8: PRINT "  RIP  "; SPACE$(25);
        CASE USED
            d = (i - Hash%(RTRIM$(tb(i).who)) + TSIZE) MOD TSIZE
            IF d = 0 THEN PRINT "  home "; ELSE PRINT USING "  +##  "; d;
            PRINT tb(i).who; " "; tb(i).phone; "      ";
        END SELECT
        COLOR 7, 0
    NEXT i
END SUB
