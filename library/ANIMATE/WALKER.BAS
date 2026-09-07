' ============================================================
' TITLE:    Walking Cycle
' CATEGORY: Animation & Sprites
' LEVEL:    Intermediate
' TAGS:     sprites, GET, PUT, walk cycle, frames, DATA
' SUMMARY:  Build eight frames of a walking stick figure with GET, then PUT them in sequence so it strolls across the screen.
' ------------------------------------------------------------
' WHAT IT DOES
'   Draws eight poses of a stick figure (legs and arms swinging)
'   and captures each one into the same big array with GET.
'   Then it plays the frames in order while sliding the figure
'   to the right, exactly how cartoons and video games animate
'   a character walking.
'
' HOW TO USE
'   Watch him walk.  Keys:
'     + / -   walk faster / slower
'     F       show the raw frames side by side (film strip)
'     Esc     quit
'
' CONCEPTS YOU WILL LEARN
'   * Storing several sprites in ONE array using offsets:
'       GET (..)-(..), spr(f * FSIZE)   and   PUT (x,y), spr(f * FSIZE)
'   * A "walk cycle": a loop of poses that repeats seamlessly
'   * The self-erasing sprite trick: the sprite box has a border
'     of background color, so drawing it 2 pixels to the right
'     wipes out the old image automatically - no flicker
'   * Reading pose angles from DATA statements
'
' THINGS TO TRY
'   * Change the DATA angles to make him march or run
'   * Make a second walker going the other way
' ============================================================
DEFINT A-Z
DECLARE SUB DrawPose (cx, cy, legA!, legB!, armA!, armB!)

CONST NFRAMES = 8
CONST W = 24, H = 46         ' sprite box is (0,0)-(W,H)
' How big must each frame's slice of the array be?  In SCREEN 13
' GET stores 4 header bytes + 1 byte per pixel.  The box is
' 25 x 47 pixels = 1175 bytes + 4 = 1179 bytes = 590 integers.
CONST FSIZE = 600            ' integers reserved per frame
CONST SKY = 53, GROUND = 6

SCREEN 13
DIM SHARED spr(NFRAMES * FSIZE)

' ---- 1. Make the frames -------------------------------------
' Each pose is four angles in degrees, measured from straight
' down: front leg, back leg, front arm, back arm.  Positive =
' swung forward.  The values follow a smooth back-and-forth
' swing, like a pendulum.
FOR f = 0 TO NFRAMES - 1
    READ legA!, legB!, armA!, armB!
    ' Clear a sky-colored box, draw the pose in it, then GET it.
    LINE (0, 0)-(W, H), SKY, BF
    DrawPose W \ 2, 9, legA!, legB!, armA!, armB!
    GET (0, 0)-(W, H), spr(f * FSIZE)
NEXT

DATA  25,-25,-20, 20
DATA  15,-15,-12, 12
DATA   0,  0,  0,  0
DATA -15, 15, 12,-12
DATA -25, 25, 20,-20
DATA -15, 15, 12,-12
DATA   0,  0,  0,  0
DATA  15,-15,-12, 12

' ---- 2. The scene -------------------------------------------
GOSUB DrawScene

' ---- 3. Walk! -----------------------------------------------
x = -W: f = 0: speed = 4
gy = 150 - H                 ' feet touch the ground at y = 150
DO
    ' Only PUT when fully on screen: PUT outside the screen is an
    ' error in QBasic.  The box's sky border erases the old frame.
    IF x >= 0 AND x <= 319 - W THEN PUT (x, gy), spr(f * FSIZE), PSET

    f = (f + 1) MOD NFRAMES   ' next pose, wrapping 7 -> 0
    x = x + 2                 ' slide forward 2 pixels per frame
    IF x > 320 THEN x = -W: LINE (294, gy)-(319, gy + H), SKY, BF

    FOR d = 1 TO speed: WAIT &H3DA, 8, 8: WAIT &H3DA, 8: NEXT

    k$ = UCASE$(INKEY$)
    IF k$ = "+" OR k$ = "=" THEN IF speed > 1 THEN speed = speed - 1
    IF k$ = "-" THEN IF speed < 12 THEN speed = speed + 1
    IF k$ = "F" THEN GOSUB FilmStrip
LOOP UNTIL k$ = CHR$(27)

SCREEN 0: WIDTH 80
END

DrawScene:
    LINE (0, 0)-(319, 150), SKY, BF          ' sky
    LINE (0, 151)-(319, 199), GROUND, BF     ' dirt
    LINE (0, 151)-(319, 153), 2, BF          ' grass edge
    CIRCLE (270, 30), 15, 14: PAINT (270, 30), 14, 14   ' sun
    COLOR 15
    LOCATE 23, 2: PRINT "+/- speed  F film strip  Esc quit";
    RETURN

FilmStrip:
    ' Show all frames next to each other so you can study the cycle.
    CLS
    LOCATE 2, 10: PRINT "The 8 frames of the walk"
    FOR i = 0 TO NFRAMES - 1
        PUT (8 + i * 38, 60), spr(i * FSIZE), PSET
        LOCATE 15, (8 + i * 38) \ 8 + 2: PRINT i;
    NEXT
    LOCATE 20, 8: PRINT "Press any key to go back"
    DO: LOOP WHILE INKEY$ = ""
    GOSUB DrawScene
    RETURN

SUB DrawPose (cx, cy, legA!, legB!, armA!, armB!)
    ' cx,cy = centre of the head.  Angles in degrees -> radians.
    CONST RAD = 3.14159 / 180
    CIRCLE (cx, cy), 5, 15                     ' head
    PAINT (cx, cy), 12, 15                     ' rosy face
    hipY = cy + 21
    LINE (cx, cy + 5)-(cx, hipY), 15           ' body
    ' Each limb: start at a joint and go a fixed length at an angle.
    ' Straight down is angle 0, so x uses SIN and y uses COS.
    LINE (cx, hipY)-(cx + 14 * SIN(legB! * RAD), hipY + 14 * COS(legB! * RAD)), 8
    LINE (cx, hipY)-(cx + 14 * SIN(legA! * RAD), hipY + 14 * COS(legA! * RAD)), 1
    LINE (cx, cy + 8)-(cx + 10 * SIN(armB! * RAD), cy + 8 + 10 * COS(armB! * RAD)), 8
    LINE (cx, cy + 8)-(cx + 10 * SIN(armA! * RAD), cy + 8 + 10 * COS(armA! * RAD)), 15
END SUB
