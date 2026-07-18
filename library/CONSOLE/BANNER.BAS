' ============================================================
' TITLE:    Big Letter Banner
' CATEGORY: Console & Text
' LEVEL:    Intermediate
' TAGS:     ascii art, fonts, data, arrays, strings
' SUMMARY:  Type a message and see it drawn in giant rainbow block letters using a hand-made 5x5 font.
' ------------------------------------------------------------
' WHAT IT DOES
'   Every letter of a "big font" is a tiny 5 x 5 picture stored in
'   DATA statements as strings of "#" and ".".  The program loads
'   the font into an array, asks you for a message, and draws it
'   with solid block characters.  Long messages wrap onto more
'   lines, and each letter gets its own rainbow colour.
'
' HOW TO USE
'   Type a message (letters, digits, space, ! ? . - and :) and press
'   Enter.  An empty message quits.
'
' CONCEPTS YOU WILL LEARN
'   * Storing pictures as text in DATA statements
'   * A 2-D lookup: font$(character, row)
'   * INSTR to find a character's position in a list
'   * Simple word-free wrapping by counting letters per line
'
' THINGS TO TRY
'   * Design lowercase letters or new symbols (add them to CHARS$).
'   * Use CHR$(177) instead of CHR$(219) for a softer look.
'   * Make each letter "drop in" from the top one at a time.
' ============================================================

DEFINT A-Z

' The characters our font knows, in the same order as the DATA.
CHARS$ = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !?.-:"
NCH = LEN(CHARS$)
DIM font$(1 TO NCH, 1 TO 5)

' Load the font: 5 strings per character.
FOR c = 1 TO NCH
    FOR r = 1 TO 5
        READ font$(c, r)
    NEXT r
NEXT c

SCREEN 0: WIDTH 80, 25

DO
    COLOR 7, 0: CLS
    COLOR 15: PRINT "BIG LETTER BANNER": COLOR 7
    PRINT "Type a message (max 48 characters), or just Enter to quit."
    LINE INPUT "> "; msg$
    msg$ = UCASE$(LEFT$(msg$, 48))   ' our font only has capitals
    IF msg$ = "" THEN EXIT DO
    CLS

    ' Each big letter is 5 blocks wide plus 1 space = 6 columns.
    ' 78 / 6 = 13 letters fit on one line.  Each banner line uses
    ' 6 text rows (5 for the letter + 1 gap).
    perLine = 13
    FOR i = 1 TO LEN(msg$)
        ch$ = MID$(msg$, i, 1)
        idx = INSTR(CHARS$, ch$)       ' where is it in our font?
        IF idx = 0 THEN idx = INSTR(CHARS$, "?")   ' unknown -> "?"

        ' Work out where letter number i goes on the screen.
        slot = (i - 1) MOD perLine          ' position across
        bline = (i - 1) \ perLine           ' which banner line
        x = 2 + slot * 6
        y = 2 + bline * 6

        ' Rainbow: cycle through bright colours 9..14.
        COLOR 9 + (i - 1) MOD 6

        FOR r = 1 TO 5
            LOCATE y + r - 1, x
            ' Turn "#" into a solid block and "." into a space.
            FOR k = 1 TO 5
                IF MID$(font$(idx, r), k, 1) = "#" THEN
                    PRINT CHR$(219);
                ELSE
                    PRINT " ";
                END IF
            NEXT k
        NEXT r
    NEXT i

    COLOR 8: LOCATE 25, 1: PRINT "Press any key for another message...";
    k$ = INPUT$(1)
LOOP
COLOR 7, 0: CLS
END

' ---- The font -------------------------------------------------
' Each group of 5 strings is one character, top row first.
' "#" = filled, "." = empty.  Squint and you can see the letters!
' A
DATA ".###.","#...#","#####","#...#","#...#"
' B
DATA "####.","#...#","####.","#...#","####."
' C
DATA ".####","#....","#....","#....",".####"
' D
DATA "####.","#...#","#...#","#...#","####."
' E
DATA "#####","#....","####.","#....","#####"
' F
DATA "#####","#....","####.","#....","#...."
' G
DATA ".####","#....","#..##","#...#",".###."
' H
DATA "#...#","#...#","#####","#...#","#...#"
' I
DATA "#####","..#..","..#..","..#..","#####"
' J
DATA "..###","...#.","...#.","#..#.",".##.."
' K
DATA "#...#","#..#.","###..","#..#.","#...#"
' L
DATA "#....","#....","#....","#....","#####"
' M
DATA "#...#","##.##","#.#.#","#...#","#...#"
' N
DATA "#...#","##..#","#.#.#","#..##","#...#"
' O
DATA ".###.","#...#","#...#","#...#",".###."
' P
DATA "####.","#...#","####.","#....","#...."
' Q
DATA ".###.","#...#","#.#.#","#..#.",".##.#"
' R
DATA "####.","#...#","####.","#..#.","#...#"
' S
DATA ".####","#....",".###.","....#","####."
' T
DATA "#####","..#..","..#..","..#..","..#.."
' U
DATA "#...#","#...#","#...#","#...#",".###."
' V
DATA "#...#","#...#","#...#",".#.#.","..#.."
' W
DATA "#...#","#...#","#.#.#","##.##","#...#"
' X
DATA "#...#",".#.#.","..#..",".#.#.","#...#"
' Y
DATA "#...#",".#.#.","..#..","..#..","..#.."
' Z
DATA "#####","...#.","..#..",".#...","#####"
' 0
DATA ".###.","#..##","#.#.#","##..#",".###."
' 1
DATA "..#..",".##..","..#..","..#..",".###."
' 2
DATA ".###.","#...#","..##.",".#...","#####"
' 3
DATA "####.","....#","..##.","....#","####."
' 4
DATA "#...#","#...#","#####","....#","....#"
' 5
DATA "#####","#....","####.","....#","####."
' 6
DATA ".###.","#....","####.","#...#",".###."
' 7
DATA "#####","...#.","..#..",".#...",".#..."
' 8
DATA ".###.","#...#",".###.","#...#",".###."
' 9
DATA ".###.","#...#",".####","....#",".###."
' space
DATA ".....",".....",".....",".....","....."
' !
DATA "..#..","..#..","..#..",".....","..#.."
' ?
DATA ".###.","#...#","..##.",".....","..#.."
' .
DATA ".....",".....",".....",".....","..#.."
' -
DATA ".....",".....",".###.",".....","....."
' :
DATA ".....","..#..",".....","..#..","....."
