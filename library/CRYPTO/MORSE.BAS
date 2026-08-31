' ============================================================
' TITLE:    Morse Code Telegraph
' CATEGORY: Codes & Cryptography
' LEVEL:    Beginner
' TAGS:     morse, SOUND, telegraph, lookup table, DATA
' SUMMARY:  Turns text into beeping Morse code (with a blinking lamp) and decodes dots and dashes back into text.
' ------------------------------------------------------------
' WHAT IT DOES
'   In 1837-1844 Samuel Morse and Alfred Vail built the electric
'   telegraph.  Since a wire can only be ON or OFF, letters were sent
'   as short and long pulses: DOTS (.) and DASHES (-).  Vail counted
'   letters in a printer's type box and gave the most common letters
'   the shortest codes:  E = .   T = -   while Q = --.-
'   (The same idea as frequency analysis, used to save time!)
'
'   Morse is a CODE, not a cipher: everybody knows the table, so it
'   hides nothing.  It was used on ships until 1999 - the famous
'   distress call SOS ( ... --- ... ) was chosen because it is easy
'   to send and recognise.
'
'   TIMING RULES (in "units"):
'     dot = 1 unit, dash = 3 units
'     gap inside a letter = 1, between letters = 3, between words = 7
'
' HOW TO USE
'   1 = encode text and PLAY it (watch the lamp blink)
'   2 = decode: type dots and dashes, letters separated by spaces
'       and words by " / "    e.g.   .... ..  / - .... . .-. .
'   3 = show the whole table,   Q = quit
'   Press any key while it is playing to stop.
'
' CONCEPTS YOU WILL LEARN
'   * A lookup table loaded from DATA into an array
'   * SOUND frequency, duration (duration is in clock ticks: 18.2/sec)
'   * Searching an array to decode
'   * Splitting a string on spaces by hand
'
' THINGS TO TRY
'   * Change the speed (UNIT) and pitch (PITCH) constants
'   * Add punctuation: . is .-.-.-   ? is ..--..
'   * Make a "practice" mode that plays a random letter for you to guess
' ============================================================

DECLARE FUNCTION Encode$ (t$)
DECLARE FUNCTION Decode$ (m$)
DECLARE SUB PlayMorse (m$)
DECLARE SUB Lamp (onOff%)

CONST PITCH = 700        ' beep frequency in hertz
CONST UNIT = 1.2         ' length of a dot in clock ticks (1 tick = 1/18.2 s)

' code$(0..25) = A..Z, code$(26..35) = 0..9
DIM SHARED code$(35), stopped
FOR i = 0 TO 35: READ code$(i): NEXT i
DATA ".-","-...","-.-.","-..",".","..-.","--.","....","..",".---"
DATA "-.-",".-..","--","-.","---",".--.","--.-",".-.","...","-"
DATA "..-","...-",".--","-..-","-.--","--.."
DATA "-----",".----","..---","...--","....-"
DATA ".....","-....","--...","---..","----."

DO
    CLS
    COLOR 14: PRINT "MORSE CODE TELEGRAPH": COLOR 7
    PRINT
    PRINT "1) Encode & play   2) Decode   3) Table   Q) Quit"
    LINE INPUT "Choice: "; c$
    c$ = UCASE$(LEFT$(c$, 1))
    IF c$ = "Q" OR c$ = CHR$(27) THEN EXIT DO
    SELECT CASE c$
    CASE "1"
        LINE INPUT "Text: "; t$
        IF t$ = "" THEN t$ = "SOS"
        m$ = Encode$(t$)
        PRINT
        COLOR 11: PRINT m$: COLOR 7
        PRINT
        PRINT "Playing... (any key stops)"
        PlayMorse m$
        LOCATE 18, 1
    CASE "2"
        LINE INPUT "Morse: "; m$
        IF m$ = "" THEN m$ = ".... . .-.. .-.. --- / .-- --- .-. .-.. -.."
        COLOR 10: PRINT "Text: "; Decode$(m$): COLOR 7
    CASE "3"
        ' Print the table in 4 columns.
        PRINT
        FOR i = 0 TO 35
            IF i < 26 THEN ch$ = CHR$(65 + i) ELSE ch$ = CHR$(48 + i - 26)
            LOCATE 6 + i \ 4, 1 + (i MOD 4) * 18
            COLOR 14: PRINT ch$; " "; : COLOR 7: PRINT code$(i);
        NEXT i
        PRINT
    CASE ELSE
        PRINT "Choose 1, 2, 3 or Q."
    END SELECT
    PRINT
    PRINT "Press any key...";
    k$ = INPUT$(1)
LOOP
CLS
END

' ------------------------------------------------------------
' Encode$: look each character up.  Letters are separated by one
' space and words by " / " so the result can be decoded again.
' Characters not in the table are skipped.
' ------------------------------------------------------------
FUNCTION Encode$ (t$)
    r$ = ""
    FOR i = 1 TO LEN(t$)
        ch$ = UCASE$(MID$(t$, i, 1))
        IF ch$ = " " THEN
            IF RIGHT$(r$, 2) <> "/ " AND r$ <> "" THEN r$ = r$ + "/ "
        ELSEIF ch$ >= "A" AND ch$ <= "Z" THEN
            r$ = r$ + code$(ASC(ch$) - 65) + " "
        ELSEIF ch$ >= "0" AND ch$ <= "9" THEN
            r$ = r$ + code$(ASC(ch$) - 48 + 26) + " "
        END IF
    NEXT i
    Encode$ = RTRIM$(r$)
END FUNCTION

' ------------------------------------------------------------
' Decode$: read the Morse string symbol group by symbol group.
' A group ends at a space.  "/" means a word break.  Each group is
' searched for in the table; unknown groups become "?".
' ------------------------------------------------------------
FUNCTION Decode$ (m$)
    r$ = "": g$ = ""
    s$ = m$ + " "                       ' a final space flushes the last group
    FOR i = 1 TO LEN(s$)
        ch$ = MID$(s$, i, 1)
        IF ch$ = "." OR ch$ = "-" THEN
            g$ = g$ + ch$
        ELSEIF ch$ = "_" THEN
            g$ = g$ + "-"               ' some people type _ for dash
        ELSE
            IF g$ <> "" THEN
                found$ = "?"
                FOR k = 0 TO 35
                    IF code$(k) = g$ THEN
                        IF k < 26 THEN found$ = CHR$(65 + k) ELSE found$ = CHR$(48 + k - 26)
                        EXIT FOR
                    END IF
                NEXT k
                r$ = r$ + found$
                g$ = ""
            END IF
            IF ch$ = "/" THEN r$ = r$ + " "
        END IF
    NEXT i
    Decode$ = r$
END FUNCTION

' ------------------------------------------------------------
' PlayMorse: beep each symbol and light the lamp.  SOUND with a
' very low frequency is not allowed, so silence is made with
' SOUND 32767 (far above hearing) for the gap length.
' ------------------------------------------------------------
SUB PlayMorse (m$)
    FOR i = 1 TO LEN(m$)
        ch$ = MID$(m$, i, 1)
        LOCATE 12, 1 + (i - 1) MOD 80: COLOR 14: PRINT ch$; : COLOR 7
        SELECT CASE ch$
        CASE "."
            Lamp 1: SOUND PITCH, UNIT: Lamp 0
            SOUND 32767, UNIT                     ' 1-unit gap
        CASE "-"
            Lamp 1: SOUND PITCH, UNIT * 3: Lamp 0
            SOUND 32767, UNIT
        CASE " "
            SOUND 32767, UNIT * 2                 ' letter gap: 1 + 2 = 3
        CASE "/"
            SOUND 32767, UNIT * 2                 ' word gap: 3 + 2 + 2 = 7
        END SELECT
        IF INKEY$ <> "" THEN EXIT FOR
    NEXT i
END SUB

' ------------------------------------------------------------
' Lamp: draw a signal lamp with box characters, lit or dark.
' ------------------------------------------------------------
SUB Lamp (onOff%)
    IF onOff% THEN COLOR 14 ELSE COLOR 8
    LOCATE 15, 36: PRINT CHR$(219); CHR$(219); CHR$(219); CHR$(219); CHR$(219);
    LOCATE 16, 36: PRINT CHR$(219); CHR$(219); CHR$(219); CHR$(219); CHR$(219);
    COLOR 7
END SUB
