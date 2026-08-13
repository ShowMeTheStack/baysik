' ============================================================
' TITLE:    Background Music with ON PLAY
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     on play, music, background, events, animation
' SUMMARY:  Endless background music fed phrase by phrase by an ON PLAY(n) trap while a ball bounces.
' ------------------------------------------------------------
' WHAT IT DOES
'   PLAY "MB..." (Music Background) puts notes in a queue and returns
'   at once, so your program keeps running while the speaker plays.
'   The queue is small though.  ON PLAY(n) GOSUB tells BASIC: "when
'   fewer than n notes are left in the queue, call my subroutine" - a
'   perfect place to add the next phrase.  The result is endless music
'   with no gaps, while the main loop animates a bouncing ball.
'
' HOW TO USE
'   Just watch and listen.  Press M to mute/unmute (PLAY OFF / ON),
'   Esc to quit.
'
' CONCEPTS YOU WILL LEARN
'   * PLAY "MB" (background) versus "MF" (foreground)
'   * ON PLAY(n) GOSUB and PLAY ON / PLAY OFF / PLAY STOP
'   * PLAY(0): how many notes are still waiting in the queue
'   * Reading phrases in a loop from DATA with RESTORE
'
' THINGS TO TRY
'   * Write your own tune in the DATA lines (end it with "*")
'   * Change the threshold in ON PLAY(3) to 1 and listen for gaps
'   * Show the phrase number on screen as the song progresses
' ============================================================

DEFINT A-Z

SCREEN 13                       ' 320x200, 256 colours
phrase = 0: muted = 0: playing = 1

' Set the trap BEFORE the first PLAY so we never miss the low-queue event.
ON PLAY(3) GOSUB NextPhrase
PLAY ON
PLAY "MB T140 L8 O3"            ' background mode, tempo, note length, octave
GOSUB NextPhrase                ' prime the queue with the first phrase

' ---- ball animation (the "main program") ---------------------------
x = 160: y = 50: dx = 3: dy = 0
COLOR 15
LOCATE 1, 1: PRINT "ON PLAY background music"
LOCATE 25, 1: PRINT "M = mute   Esc = quit";
DO
    LINE (x - 6, y - 6)-(x + 6, y + 6), 0, BF      ' erase old ball
    dy = dy + 1                                     ' gravity
    x = x + dx: y = y + dy
    IF x < 8 OR x > 311 THEN dx = -dx: x = x + dx
    IF y > 180 THEN y = 180: dy = -14               ' bounce on the floor
    CIRCLE (x, y), 5, 32 + (phrase MOD 40)          ' colour follows the music
    PAINT (x, y), 32 + (phrase MOD 40)
    LINE (0, 187)-(319, 187), 7

    ' show how full the music queue is (PLAY(0) = notes waiting)
    LOCATE 3, 1: PRINT USING "Queue: ## notes  Phrase: ###"; PLAY(0); phrase;

    k$ = INKEY$
    IF k$ = CHR$(27) THEN EXIT DO
    IF UCASE$(k$) = "M" THEN
        muted = 1 - muted
        IF muted THEN
            PLAY OFF                    ' stop trapping; queue runs dry
        ELSE
            PLAY ON
            GOSUB NextPhrase            ' kick-start the music again
        END IF
    END IF

    t! = TIMER                          ' wait for the next clock tick:
    DO WHILE TIMER = t!: LOOP           ' TIMER changes 18.2 times a second
LOOP

PLAY OFF
SCREEN 0: WIDTH 80
PRINT "Played"; phrase; "phrases."
END

' ---- trap handler: append the next phrase of the song --------------
NextPhrase:
    READ p$
    IF p$ = "*" THEN                ' end of song: start again at the top
        RESTORE Song
        READ p$
    END IF
    PLAY p$                         ' still in MB mode, so this returns fast
    phrase = phrase + 1
RETURN

' A cheerful little tune, one phrase per DATA item.
Song:
DATA "C E G > C < G E C4"
DATA "D F A > D < A F D4"
DATA "E G B > E < B G E4"
DATA "F A > C F C < A F4"
DATA "G4 E4 C4 E4"
DATA "F8 F8 A4 G4 F4"
DATA "E8 D8 C2"
DATA "P4"
DATA "*"
