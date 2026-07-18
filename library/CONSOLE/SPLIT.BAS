' ============================================================
' TITLE:    Split-Screen Chat Bot
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     view print, scrolling, chat bot, strings, instr
' SUMMARY:  A keyword-matching chat bot whose conversation scrolls in one window while the title bar and input line stay put, thanks to VIEW PRINT.
' ------------------------------------------------------------
' WHAT IT DOES
'   The screen is split into three parts:
'     * a title/status bar at the top that never moves,
'     * a conversation window that scrolls like a chat app,
'     * an input line at the bottom where you type.
'   VIEW PRINT sets which rows PRINT is allowed to use and scroll,
'   so the different parts do not disturb each other.  The bot,
'   "BYTE", answers by looking for keywords in what you type.
'
' HOW TO USE
'   Type a message and press Enter.  Try: hello, your name, joke,
'   time, help, colour, computer...  Type BYE (or Q) to leave.
'
' CONCEPTS YOU WILL LEARN
'   * VIEW PRINT top TO bottom to make a text "viewport"
'   * CLS 2 clears only the viewport
'   * How printing on the last row scrolls only that region
'   * Simple keyword matching with INSTR (the idea behind ELIZA)
'
' THINGS TO TRY
'   * Add new keywords and answers to the DATA list.
'   * Let the bot remember your name if you say "my name is ...".
'   * Add a second viewport on the right showing a list of topics.
' ============================================================

DEFINT A-Z
DECLARE SUB Say (who$, txt$)
DECLARE SUB TopBar ()

DIM SHARED msgs
CONST LOGTOP = 3, LOGBOT = 21

' Load the keyword -> answer list.  "|" separates several answers;
' the bot picks one at random so it doesn't repeat itself too much.
DIM SHARED kw$(1 TO 30), ans$(1 TO 30), nKeys
DO
    READ k$, a$
    IF k$ = "*" THEN EXIT DO
    nKeys = nKeys + 1: kw$(nKeys) = k$: ans$(nKeys) = a$
LOOP

RANDOMIZE TIMER
SCREEN 0: WIDTH 80, 25
VIEW PRINT                  ' the whole screen, to start
COLOR 7, 0: CLS
TopBar
' a divider line above the input area
COLOR 8: LOCATE 22, 1: PRINT STRING$(80, 196);

Say "BYTE", "Hello! I am BYTE, a tiny chat bot. Type HELP if you are stuck."

DO
    ' ---- the input area: rows 23..24 ----
    VIEW PRINT 23 TO 24
    COLOR 15, 0: CLS 2                      ' clear just these rows
    LOCATE 23, 1
    LINE INPUT "You> "; t$
    u$ = UCASE$(LTRIM$(RTRIM$(t$)))
    IF u$ = "" THEN u$ = " "

    Say "You", t$
    IF u$ = "BYE" OR u$ = "Q" OR u$ = "QUIT" THEN
        Say "BYTE", "Goodbye! Come back and chat any time."
        EXIT DO
    END IF

    ' ---- find a reply ----
    reply$ = ""
    ' A few answers are computed instead of stored.
    IF INSTR(u$, "TIME") THEN reply$ = "My clock says " + TIME$ + "."
    IF INSTR(u$, "DATE") OR INSTR(u$, "DAY") THEN reply$ = "Today is " + DATE$ + "."
    IF reply$ = "" THEN
        FOR i = 1 TO nKeys
            ' Search for a space + keyword, so keywords only match at the
            ' START of a word ("HI" matches "HI" and "HIYA" but not "THIS").
            IF INSTR(" " + u$, " " + kw$(i)) THEN
                ' choose one of the "|"-separated answers at random
                a$ = ans$(i) + "|"
                n = 0
                FOR j = 1 TO LEN(a$)
                    IF MID$(a$, j, 1) = "|" THEN n = n + 1
                NEXT j
                pick = INT(RND * n) + 1
                ' walk to the pick-th answer
                p = 1
                FOR j = 1 TO pick - 1
                    p = INSTR(p, a$, "|") + 1
                NEXT j
                reply$ = MID$(a$, p, INSTR(p, a$, "|") - p)
                EXIT FOR
            END IF
        NEXT i
    END IF
    IF reply$ = "" THEN
        SELECT CASE INT(RND * 3)
            CASE 0: reply$ = "Interesting! Tell me more."
            CASE 1: reply$ = "Hmm, I only understand a few words. Try HELP."
            CASE 2: reply$ = "Why do you say " + CHR$(34) + t$ + CHR$(34) + "?"
        END SELECT
    END IF
    Say "BYTE", reply$
LOOP

VIEW PRINT
LOCATE 25, 1: COLOR 8: PRINT "Press any key...";
k$ = INPUT$(1)
COLOR 7, 0: CLS
END

' keyword (in capitals), answers separated by |
DATA "HELLO","Hi there!|Hello, human!|Greetings, programmer."
DATA "HI","Hi! How are you today?|Hey!"
DATA "HELP","Try asking about: my name, a joke, the time, colours, computers."
DATA "NAME","My name is BYTE. Eight bits, one personality."
DATA "JOKE","Why do programmers mix up Halloween and Christmas? OCT 31 = DEC 25!|There are 10 kinds of people: those who know binary and those who don't."
DATA "COLOR","My favourite colour is 14 - bright yellow.|I like blue backgrounds, like the QBasic editor."
DATA "COLOUR","My favourite colour is 14 - bright yellow."
DATA "COMPUTER","I live inside one! It is cosy in here.|Computers just follow instructions very, very fast."
DATA "BASIC","BASIC means Beginner's All-purpose Symbolic Instruction Code."
DATA "HOW ARE YOU","I'm running at full speed, thanks!"
DATA "SAD","Oh no. Here is a smiley for you: :-)"
DATA "LOVE","Aww. I love well-commented code."
DATA "GAME","Games are great! Have you tried the others in this library?"
DATA "THANK","You're welcome!"
DATA "*","*"

' Add a message to the conversation window.  The trick: switch the
' viewport to the log rows, LOCATE the bottom row and PRINT.  When
' PRINT finishes a line on the LAST row of a viewport, only that
' viewport scrolls up - the title and input line stay where they are.
SUB Say (who$, txt$)
    VIEW PRINT LOGTOP TO LOGBOT
    LOCATE LOGBOT, 1
    IF who$ = "You" THEN COLOR 11 ELSE COLOR 14
    PRINT who$; ": ";
    COLOR 7
    ' simple wrap so long answers don't get cut off at column 80
    s$ = txt$
    w = 80 - LEN(who$) - 3
    DO WHILE LEN(s$) > w
        PRINT LEFT$(s$, w)
        PRINT SPACE$(LEN(who$) + 2);
        s$ = MID$(s$, w + 1)
    LOOP
    PRINT s$
    msgs = msgs + 1
    VIEW PRINT                        ' full screen again for TopBar
    TopBar
END SUB

SUB TopBar
    COLOR 15, 1
    LOCATE 1, 1: PRINT SPACE$(80);
    LOCATE 1, 3: PRINT "CHAT WITH BYTE";
    LOCATE 1, 50: PRINT USING "Messages: ###   "; msgs;
    PRINT LEFT$(TIME$, 5);
    COLOR 7, 0
END SUB
