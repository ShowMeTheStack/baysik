' ============================================================
' TITLE:    Command History Ring
' CATEGORY: Data Structures
' LEVEL:    Intermediate
' TAGS:     ring buffer, circular buffer, history, INKEY$, line editor
' SUMMARY:  A tiny command prompt that remembers your last 8 commands in a ring buffer - press Up and Down to recall them.
' ------------------------------------------------------------
' WHAT IT DOES
'   Shells and chat apps remember what you typed so you can press
'   the Up arrow to get it back. They only keep the LAST few lines,
'   and the simplest way to do that is a RING BUFFER: a fixed array
'   where the newest entry overwrites the oldest one once it is
'   full. No shifting, no growing - just an index that wraps round.
'
'   This program is a toy command prompt with its own line editor
'   (built from INKEY$). The ring is drawn on the right so you can
'   see each slot, where the newest entry is, and which entry Up/Down
'   is currently pointing at.
'
' HOW TO USE
'   Type a command and press Enter. Try:
'     HELP   ECHO hello   ADD 3 4   TIME   HISTORY   CLEAR   EXIT
'   Up / Down arrows browse the history. Backspace edits.
'   Esc (or EXIT) quits.
'
' CONCEPTS YOU WILL LEARN
'   * Ring buffer with "newest" index and a count (max = size)
'   * Converting "k steps back from newest" into an array slot
'   * Reading special keys (arrows) from INKEY$
'   * A simple command parser with INSTR and SELECT CASE
'
' THINGS TO TRY
'   * Skip storing a command that repeats the previous one
'   * Add "!3" to re-run the 3rd most recent command
' ============================================================

DEFINT A-Z
DECLARE SUB Remember (c$)
DECLARE FUNCTION Recall$ (back AS INTEGER)
DECLARE SUB DrawRing (browse AS INTEGER)
DECLARE SUB Out1 (t$)

CONST RSIZE = 8
DIM SHARED ring$(0 TO RSIZE - 1)
DIM SHARED newest, count        ' newest = slot of the latest command
DIM SHARED outRow               ' next line in the output area
newest = RSIZE - 1              ' so the first command lands in slot 0

CLS
COLOR 15: PRINT "MINI SHELL with a ring-buffer history (type HELP)": COLOR 7
outRow = 3
DO
    ' ---------- read one line with our own editor --------------
    ed$ = "": browse = 0      ' browse = how many steps back (0 = new line)
    DO
        DrawRing browse
        LOCATE 22, 1: PRINT "> "; ed$; "_"; SPACE$(70 - LEN(ed$));
        DO: k$ = INKEY$: LOOP WHILE k$ = ""
        IF LEN(k$) = 2 THEN
            code = ASC(RIGHT$(k$, 1))
            IF code = 72 AND browse < count THEN        ' Up arrow
                browse = browse + 1: ed$ = Recall$(browse)
            ELSEIF code = 80 AND browse > 0 THEN        ' Down arrow
                browse = browse - 1
                IF browse = 0 THEN ed$ = "" ELSE ed$ = Recall$(browse)
            END IF
        ELSEIF k$ = CHR$(8) THEN
            IF LEN(ed$) THEN ed$ = LEFT$(ed$, LEN(ed$) - 1)
        ELSEIF k$ = CHR$(27) THEN
            ed$ = "EXIT": EXIT DO
        ELSEIF k$ = CHR$(13) THEN
            EXIT DO
        ELSEIF k$ >= " " AND LEN(ed$) < 50 THEN
            ed$ = ed$ + k$
        END IF
    LOOP

    ' ---------- run the command ----------------------------------
    cmd$ = LTRIM$(RTRIM$(ed$))
    IF cmd$ = "" THEN cmd$ = " "
    IF cmd$ <> " " THEN Remember cmd$
    Out1 "> " + cmd$
    sp = INSTR(cmd$ + " ", " ")
    verb$ = UCASE$(LEFT$(cmd$, sp - 1))
    arg$ = LTRIM$(MID$(cmd$, sp + 1))
    SELECT CASE verb$
    CASE "HELP"
        Out1 "  Commands: HELP ECHO ADD TIME HISTORY CLEAR EXIT"
    CASE "ECHO"
        Out1 "  " + arg$
    CASE "ADD"
        sp2 = INSTR(arg$, " ")
        IF sp2 = 0 THEN
            Out1 "  usage: ADD 3 4"
        ELSE
            Out1 "  =" + STR$(VAL(arg$) + VAL(MID$(arg$, sp2 + 1)))
        END IF
    CASE "TIME"
        Out1 "  It is " + TIME$ + " on " + DATE$
    CASE "HISTORY"
        ' Oldest first: count-1 steps back ... down to 0 steps back
        FOR b = count TO 1 STEP -1
            Out1 "  " + STR$(count - b + 1) + "  " + Recall$(b)
        NEXT b
    CASE "CLEAR"
        FOR i = 3 TO 20: LOCATE i, 1: PRINT SPACE$(44); : NEXT i
        outRow = 3
    CASE "EXIT"
        EXIT DO
    CASE ""
    CASE ELSE
        Out1 "  Unknown command: " + verb$
    END SELECT
LOOP
CLS
PRINT "Bye! Your last"; count; "commands were kept in a ring of"; RSIZE
END

' DrawRing: show all slots. N marks the newest entry; the arrow
' marks the one Up/Down is showing.
SUB DrawRing (browse AS INTEGER)
    LOCATE 2, 50: PRINT "RING BUFFER  count="; count; " "
    FOR i = 0 TO RSIZE - 1
        LOCATE 4 + i, 50
        mark$ = "  "
        IF count > 0 AND i = newest THEN mark$ = "N "
        IF browse > 0 THEN
            IF i = (newest - (browse - 1) + RSIZE) MOD RSIZE THEN mark$ = "->"
        END IF
        PRINT mark$; "["; LTRIM$(STR$(i)); "] "; LEFT$(ring$(i) + SPACE$(20), 20);
    NEXT i
    LOCATE 13, 50: PRINT "N  = newest slot"
    LOCATE 14, 50: PRINT "-> = recalled by Up/Down"
    LOCATE 15, 50: PRINT "When full, the oldest is"
    LOCATE 16, 50: PRINT "overwritten next."
END SUB

' Out1: print a line in the output area (left side), scrolling
' by clearing when it reaches the bottom.
SUB Out1 (t$)
    IF outRow > 20 THEN
        FOR i = 3 TO 20: LOCATE i, 1: PRINT SPACE$(46); : NEXT i
        outRow = 3
    END IF
    LOCATE outRow, 1: PRINT LEFT$(t$, 46);
    outRow = outRow + 1
END SUB

' Recall$: the command "back" steps ago (1 = most recent).
' Step back from newest, adding RSIZE so MOD never sees a negative.
FUNCTION Recall$ (back AS INTEGER)
    Recall$ = ring$((newest - (back - 1) + RSIZE) MOD RSIZE)
END FUNCTION

' Remember: advance newest (wrapping) and store the command there.
' If the ring was full this overwrites the oldest command.
SUB Remember (c$)
    newest = (newest + 1) MOD RSIZE
    ring$(newest) = c$
    IF count < RSIZE THEN count = count + 1
END SUB
