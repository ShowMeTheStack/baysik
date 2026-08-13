' ============================================================
' TITLE:    PC Speaker Organ (Ports &H42, &H43, &H61)
' CATEGORY: System, Events & Hardware
' LEVEL:    Advanced
' TAGS:     out, inp, pc speaker, 8253 timer, port 61h, sound, organ
' SUMMARY:  Drive the PC speaker hardware directly: program timer channel 2 and gate it on and off like an organ.
' ------------------------------------------------------------
' WHAT IT DOES
'   SOUND and PLAY hide the real hardware.  Underneath, the PC speaker
'   is driven by channel 2 of the 8253 timer chip, whose clock runs at
'   1,193,182 Hz.  You load a DIVISOR and the chip produces a square
'   wave of  1193182 / divisor  Hz:
'       OUT &H43, &HB6          ' command: channel 2, square wave,
'                               '          divisor comes low byte first
'       OUT &H42, lo : OUT &H42, hi
'   Then bits 0 and 1 of port &H61 connect the timer to the speaker:
'       OUT &H61, INP(&H61) OR 3       ' speaker ON
'       OUT &H61, INP(&H61) AND &HFC   ' speaker OFF
'   Because WE switch the sound on and off, a note can last exactly
'   as long as you hold a key (key up/down is read from port &H60).
'
' HOW TO USE
'   First a short siren plays.  Then the bottom row of letter keys is
'   an organ:  Z X C V B N M ,  = C D E F G A B C.  Hold keys to play.
'   Esc quits (the speaker is always switched off on exit).
'
' CONCEPTS YOU WILL LEARN
'   * Frequency = clock / divisor, and splitting a number into bytes
'   * Read-modify-write of a port with AND / OR so other bits survive
'   * Make/break scan codes from INP(&H60) for key-held detection
'
' THINGS TO TRY
'   * Add sharps/flats on the row above (S D G H J)
'   * Add vibrato by wobbling the divisor slightly while a key is held
'   * Make the siren go up AND down several times
' ============================================================

DEFINT A-Z
DECLARE SUB SetFreq (hz!)
DECLARE SUB SpeakerOn ()
DECLARE SUB SpeakerOff ()

DIM scan(7), hz!(7), nm$(7)
FOR i = 0 TO 7: READ scan(i), hz!(i), nm$(i): NEXT i
' scan code of Z X C V B N M , and the note frequencies (4th octave)
DATA 44,261.63,"C", 45,293.66,"D", 46,329.63,"E", 47,349.23,"F"
DATA 48,392.00,"G", 49,440.00,"A", 50,493.88,"B", 51,523.25,"C"

CLS
PRINT "PC SPEAKER - DIRECT HARDWARE ACCESS"
PRINT
PRINT "Siren: sweeping the divisor from 4000 down to 800..."
SpeakerOn
FOR d = 4000 TO 800 STEP -80
    OUT &H43, &HB6                 ' tell the timer a new divisor follows
    OUT &H42, d AND 255            ' low byte
    OUT &H42, d \ 256              ' high byte
    LOCATE 4, 1: PRINT USING "divisor #####  =  ####.# Hz"; d; 1193182 / d;
    t! = TIMER: DO WHILE TIMER = t!: LOOP     ' hold for one clock tick
NEXT d
SpeakerOff

PRINT : PRINT
PRINT "ORGAN:  Z  X  C  V  B  N  M  ,"
PRINT "        C  D  E  F  G  A  B  C     (hold keys, Esc quits)"
playing = -1
DO
    sc = INP(&H60)                 ' latest make/break code
    k$ = INKEY$                    ' keep the BIOS buffer empty
    IF k$ = CHR$(27) OR sc = 1 THEN EXIT DO

    note = -1
    FOR i = 0 TO 7
        IF sc = scan(i) THEN note = i             ' key went down
    NEXT i
    IF sc >= 128 THEN                              ' some key came up
        FOR i = 0 TO 7
            IF sc - 128 = scan(i) AND playing = i THEN note = -2
        NEXT i
    END IF

    IF note >= 0 AND note <> playing THEN
        SetFreq hz!(note)
        SpeakerOn
        playing = note
        LOCATE 10, 1: PRINT USING "Playing  & = ###.## Hz   divisor #####"; nm$(note); hz!(note); CLNG(1193182 / hz!(note));
    ELSEIF note = -2 THEN
        SpeakerOff
        playing = -1
        LOCATE 10, 1: PRINT SPACE$(50);
    END IF
LOOP
SpeakerOff                         ' NEVER leave the speaker screaming!
CLS
PRINT "Speaker off.  Bye!"
END

' Program timer channel 2 for a given frequency.
SUB SetFreq (hz!)
    d& = CLNG(1193182 / hz!)       ' divisor fits in 16 bits for hz > 18.2
    OUT &H43, &HB6
    OUT &H42, d& AND 255
    OUT &H42, d& \ 256
END SUB

' Bits 0 (timer gate) and 1 (speaker data) of port &H61 both ON.
SUB SpeakerOn
    OUT &H61, INP(&H61) OR 3
END SUB

' Clear bits 0 and 1, leave the other six bits exactly as they were.
SUB SpeakerOff
    OUT &H61, INP(&H61) AND &HFC
END SUB
