// BASIC language reference used by the Help viewer (F1).
// Each entry: [keyword, category, syntax, description, example]
(function (RC) {
  'use strict';
  const K = [
    // ---- Program flow
    ['IF', 'Program flow', 'IF condition THEN statements [ELSE statements]\nIF condition THEN\n  ...\n[ELSEIF condition THEN\n  ...]\n[ELSE\n  ...]\nEND IF', 'Runs statements only when a condition is true (non-zero). The single-line form can also jump: IF x THEN 100 is the same as IF x THEN GOTO 100.', 'IF score > 100 THEN\n    PRINT "High score!"\nELSEIF score > 50 THEN\n    PRINT "Good"\nELSE\n    PRINT "Keep trying"\nEND IF'],
    ['FOR', 'Program flow', 'FOR counter = start TO end [STEP increment]\n  ...\nNEXT [counter [, counter]...]', 'Repeats statements while counting. STEP can be negative or fractional. EXIT FOR leaves the loop early. If start is already past end, the body is skipped.', 'FOR i = 10 TO 1 STEP -1\n    PRINT i;\nNEXT i\nPRINT "Liftoff!"'],
    ['NEXT', 'Program flow', 'NEXT [counter [, counter]...]', 'Ends a FOR loop. NEXT i, j closes two loops at once (inner first).', ''],
    ['DO', 'Program flow', 'DO [{WHILE | UNTIL} condition]\n  ...\nLOOP [{WHILE | UNTIL} condition]', 'Repeats a block. Put the test at the top to maybe skip the loop, at the bottom to run at least once, or nowhere for an endless loop (leave with EXIT DO).', 'DO\n    k$ = INKEY$\nLOOP UNTIL k$ <> ""'],
    ['LOOP', 'Program flow', 'LOOP [{WHILE | UNTIL} condition]', 'Ends a DO loop.', ''],
    ['WHILE', 'Program flow', 'WHILE condition\n  ...\nWEND', 'Repeats while the condition is true (GW-BASIC style loop).', 'WHILE n < 100: n = n * 2: WEND'],
    ['WEND', 'Program flow', 'WEND', 'Ends a WHILE loop.', ''],
    ['SELECT', 'Program flow', 'SELECT CASE expression\nCASE value [, value]...\nCASE low TO high\nCASE IS > value\nCASE ELSE\nEND SELECT', 'Chooses one block based on a value. Works with numbers and strings.', 'SELECT CASE grade\n    CASE IS >= 90: PRINT "A"\n    CASE 80 TO 89: PRINT "B"\n    CASE ELSE: PRINT "Study more"\nEND SELECT'],
    ['CASE', 'Program flow', 'CASE expressionlist | CASE ELSE', 'A branch of SELECT CASE. Lists can mix values, ranges (a TO b) and comparisons (IS < x).', ''],
    ['GOTO', 'Program flow', 'GOTO {linenumber | label}', 'Jumps to another line. Labels are names followed by a colon, e.g. Again:', 'Again:\nINPUT "Again (Y/N)"; a$\nIF a$ = "Y" THEN GOTO Again'],
    ['GOSUB', 'Program flow', 'GOSUB {linenumber | label}\n...\nRETURN', 'Calls a subroutine within the same module; RETURN comes back to the statement after the GOSUB.', 'GOSUB DrawBox\nEND\nDrawBox:\n    LINE (0, 0)-(100, 50), 14, B\n    RETURN'],
    ['RETURN', 'Program flow', 'RETURN [{linenumber | label}]', 'Returns from a GOSUB (or an ON TIMER/KEY event handler). With a target, returns to that line instead.', ''],
    ['ON', 'Program flow', 'ON n GOTO line1, line2...\nON n GOSUB line1, line2...\nON ERROR GOTO line\nON {TIMER(s) | KEY(n) | PLAY(n) | STRIG(n) | PEN} GOSUB line', 'Computed jumps (n = 1 picks the first target) and event/error trapping.', 'INPUT "Level 1-3"; choice\nON choice GOSUB Easy, Medium, Hard\nEND\nEasy: PRINT "Easy mode": RETURN\nMedium: PRINT "Medium mode": RETURN\nHard: PRINT "Hard mode": RETURN'],
    ['EXIT', 'Program flow', 'EXIT {FOR | DO | SUB | FUNCTION | DEF}', 'Leaves a loop or procedure immediately.', ''],
    ['END', 'Program flow', 'END\nEND {IF | SELECT | SUB | FUNCTION | DEF | TYPE}', 'END alone stops the program and closes files. Other forms close a block.', ''],
    ['STOP', 'Program flow', 'STOP', 'Pauses the program in the debugger, like a breakpoint written in code. Press F5 to continue (CONT in the GW-BASIC console).', ''],
    ['SYSTEM', 'Program flow', 'SYSTEM', 'Ends the program (and leaves the GW-BASIC console).', ''],
    ['SLEEP', 'Program flow', 'SLEEP [seconds]', 'Waits for the given number of seconds or until a key is pressed. SLEEP alone waits for a key.', 'PRINT "Press any key": SLEEP'],
    // ---- Procedures
    ['SUB', 'Procedures', 'SUB name [(parameterlist)] [STATIC]\n  ...\nEND SUB', 'Defines a subprogram. Call it with CALL name(args) or just name args. Arguments are passed by reference, so the SUB can change the caller\'s variables; put an argument in parentheses to pass a copy. Variables are local unless SHARED.', 'SUB Greet (who$)\n    PRINT "Hello, "; who$\nEND SUB\n\nGreet "Ada"'],
    ['FUNCTION', 'Procedures', 'FUNCTION name[type] [(parameterlist)] [STATIC]\n  name = result\nEND FUNCTION', 'Defines a function that returns a value by assigning to its own name. Functions may call themselves (recursion).', 'FUNCTION Square (n)\n    Square = n * n\nEND FUNCTION\nPRINT Square(9)'],
    ['DECLARE', 'Procedures', 'DECLARE {SUB | FUNCTION} name [(parameterlist)]', 'Announces a procedure before it is used. Optional here, but QBasic adds them automatically.', ''],
    ['CALL', 'Procedures', 'CALL name [(argumentlist)]', 'Calls a SUB. CALL ABSOLUTE (machine code) is not supported in the browser.', ''],
    ['DEF', 'Procedures', 'DEF FNname[(params)] = expression\nDEF FNname[(params)]\n  FNname = expression\nEND DEF\nDEF SEG [= segment]', 'DEF FN defines a GW-BASIC style user function (name must start with FN). DEF SEG sets the memory segment for PEEK, POKE, BLOAD and BSAVE.', 'DEF FNarea(r) = 3.14159 * r ^ 2\nPRINT FNarea(2)'],
    ['SHARED', 'Procedures', 'SHARED variable [AS type] [, ...]\nDIM SHARED variable ...', 'Inside a SUB or FUNCTION, gives access to module-level variables. DIM SHARED makes a variable visible in every procedure.', ''],
    ['STATIC', 'Procedures', 'STATIC variable [, ...]\nSUB name (...) STATIC', 'Keeps a procedure\'s variables between calls.', 'SUB Counter STATIC\n    n = n + 1: PRINT "called"; n; "times"\nEND SUB'],
    ['COMMON', 'Procedures', 'COMMON [SHARED] variablelist', 'Lists variables passed to another program started with CHAIN. Both programs must list them in the same order.', ''],
    ['CHAIN', 'Procedures', 'CHAIN filespec$ [, line]', 'Runs another BASIC program, keeping open files and passing COMMON variables.', 'CHAIN "LEVEL2"'],
    ['RUN', 'Procedures', 'RUN [linenumber | filespec$]', 'Restarts the program (clearing variables), or loads and runs another program file.', ''],
    // ---- Variables
    ['DIM', 'Variables & types', 'DIM [SHARED] variable[(subscripts)] [AS type] [, ...]', 'Declares variables and arrays. Subscripts can be "upper" or "lower TO upper". Types: INTEGER, LONG, SINGLE, DOUBLE, STRING, STRING * n, or a TYPE.', 'DIM scores(1 TO 10) AS INTEGER\nDIM grid(20, 20)\nDIM nm AS STRING * 12'],
    ['REDIM', 'Variables & types', 'REDIM [PRESERVE] [SHARED] array(subscripts) [AS type]', 'Changes the size of a dynamic array. Without PRESERVE the contents are cleared.', ''],
    ['ERASE', 'Variables & types', 'ERASE array [, array]', 'Clears a static array or frees a dynamic one.', ''],
    ['CONST', 'Variables & types', 'CONST name = expression [, ...]', 'Defines a named constant that cannot change.', 'CONST PI = 3.14159, TITLE$ = "My Game"'],
    ['LET', 'Variables & types', '[LET] variable = expression', 'Assigns a value. The word LET is optional.', ''],
    ['SWAP', 'Variables & types', 'SWAP variable1, variable2', 'Exchanges the values of two variables of the same type.', 'IF a > b THEN SWAP a, b'],
    ['TYPE', 'Variables & types', 'TYPE name\n  field AS type\n  ...\nEND TYPE', 'Defines a record type that groups several fields. Use with DIM x AS name, and x.field.', 'TYPE Player\n    nm AS STRING * 10\n    hp AS INTEGER\nEND TYPE\nDIM p AS Player\np.hp = 100'],
    ['DEFINT', 'Variables & types', 'DEFINT letterrange [, ...]   (also DEFLNG, DEFSNG, DEFDBL, DEFSTR)', 'Sets the default type for variables whose names start with the given letters.', 'DEFINT A-Z'],
    ['OPTION', 'Variables & types', 'OPTION BASE {0 | 1}', 'Sets the lowest array subscript.', ''],
    ['DATA', 'Variables & types', 'DATA constant [, constant]...', 'Stores numbers and strings in the program for READ. Strings containing commas need quotes.', 'DATA 3, "Mon", "Tue", "Wed"'],
    ['READ', 'Variables & types', 'READ variable [, variable]...', 'Reads the next items from DATA statements.', 'READ n\nFOR i = 1 TO n: READ day$: PRINT day$: NEXT'],
    ['RESTORE', 'Variables & types', 'RESTORE [line | label]', 'Makes the next READ start again at the first DATA (or at the given line).', ''],
    ['CLEAR', 'Variables & types', 'CLEAR', 'Resets all variables and closes files.', ''],
    ['INTEGER', 'Variables & types', 'variable AS INTEGER  or  name%', '16-bit whole numbers from -32768 to 32767.', ''],
    ['LONG', 'Variables & types', 'variable AS LONG  or  name&', '32-bit whole numbers from -2147483648 to 2147483647.', ''],
    ['SINGLE', 'Variables & types', 'variable AS SINGLE  or  name!', 'Single-precision floating point (about 7 digits). The default type.', ''],
    ['DOUBLE', 'Variables & types', 'variable AS DOUBLE  or  name#', 'Double-precision floating point (about 16 digits).', ''],
    ['STRING', 'Variables & types', 'variable AS STRING  or  name$\nvariable AS STRING * length', 'Text. Fixed-length strings are padded with spaces and used in TYPEs and random-access files.', ''],
    // ---- Text I/O
    ['PRINT', 'Screen & keyboard', 'PRINT [expressionlist] [{; | ,}]\n? [expressionlist]', 'Shows text and numbers. ; keeps the cursor on the same line, , moves to the next 14-column zone. Use TAB(n) and SPC(n) for positioning.', 'PRINT "Name:"; TAB(12); name$\nPRINT 1, 2, 3'],
    ['USING', 'Screen & keyboard', 'PRINT USING format$; expressionlist', 'Formats output. # digit, . decimal point, , thousands, $$ dollar, ** asterisk fill, + - signs, ^^^^ exponent; & whole string, ! first char, \\  \\ fixed width. _ prints the next character literally.', 'PRINT USING "Total: $$#,###.##"; 1234.5'],
    ['INPUT', 'Screen & keyboard', 'INPUT [;] ["prompt" {; | ,}] variablelist\nINPUT #file, variablelist', 'Reads values typed by the user. A ; after the prompt adds "? ". If the wrong kind of value is typed, BASIC says "Redo from start".', 'INPUT "How old are you"; age'],
    ['LINE INPUT', 'Screen & keyboard', 'LINE INPUT [;] ["prompt";] string$\nLINE INPUT #file, string$', 'Reads a whole line of text including commas and quotes.', ''],
    ['INKEY$', 'Screen & keyboard', 'INKEY$', 'Returns the key being pressed without waiting ("" if none). Arrow and function keys return two characters: CHR$(0) + scan code (Up 72, Down 80, Left 75, Right 77).', 'DO: k$ = INKEY$: LOOP UNTIL k$ <> ""'],
    ['CLS', 'Screen & keyboard', 'CLS [{0 | 1 | 2}]', 'Clears the screen (0 = everything, 1 = graphics viewport, 2 = text viewport).', ''],
    ['LOCATE', 'Screen & keyboard', 'LOCATE [row] [, [column] [, [cursor] [, start, stop]]]', 'Moves the text cursor. Rows and columns start at 1. cursor = 1 shows the blinking cursor.', 'LOCATE 12, 35: PRINT "Center!"'],
    ['COLOR', 'Screen & keyboard', 'COLOR [foreground] [, background] [, border]', 'Sets colors. In SCREEN 0 foreground is 0-15 (+16 to blink) and background 0-7. In graphics modes it sets the drawing color (and background palette in some modes).', 'COLOR 14, 1: PRINT "Yellow on blue"'],
    ['WIDTH', 'Screen & keyboard', 'WIDTH columns [, rows]', 'Text width (40 or 80) and rows (25, 43, 50 in SCREEN 0; 30 or 60 in SCREEN 11/12).', ''],
    ['VIEW PRINT', 'Screen & keyboard', 'VIEW PRINT [top TO bottom]', 'Limits text scrolling to a range of rows.', ''],
    ['CSRLIN', 'Screen & keyboard', 'CSRLIN', 'The current cursor row.', ''],
    ['POS', 'Screen & keyboard', 'POS(0)', 'The current cursor column.', ''],
    ['TAB', 'Screen & keyboard', 'TAB(column)', 'In PRINT, moves to a column.', ''],
    ['SPC', 'Screen & keyboard', 'SPC(n)', 'In PRINT, outputs n spaces.', ''],
    ['WRITE', 'Screen & keyboard', 'WRITE [#file,] expressionlist', 'Like PRINT but separates values with commas and puts strings in quotes — handy for data files.', ''],
    ['KEY', 'Screen & keyboard', 'KEY {ON | OFF | LIST}\nKEY n, string$\nKEY(n) {ON | OFF | STOP}', 'Shows/hides the function-key line, assigns soft-key text (GW-BASIC), or turns key trapping on (with ON KEY(n) GOSUB).', ''],
    ['LPRINT', 'Screen & keyboard', 'LPRINT [USING format$;] expressionlist', 'Prints to the printer (LPT1). See the Printer panel.', ''],
    ['SCREEN', 'Graphics', 'SCREEN mode [, [colorswitch] [, [apage] [, vpage]]]\nSCREEN(row, column [, colorflag])', 'Chooses the display mode (see Screen Modes). apage/vpage select the drawing and visible pages. The SCREEN function returns the character code (or color) at a text position.', 'SCREEN 13   \' 320x200, 256 colors'],
    // ---- Graphics
    ['PSET', 'Graphics', 'PSET [STEP] (x, y) [, color]', 'Plots one pixel. STEP makes coordinates relative to the last point.', 'FOR x = 0 TO 319: PSET (x, 100 + 50 * SIN(x / 20)), 14: NEXT'],
    ['PRESET', 'Graphics', 'PRESET [STEP] (x, y) [, color]', 'Like PSET but defaults to the background color (erases).', ''],
    ['LINE', 'Graphics', 'LINE [[STEP](x1, y1)]-[STEP](x2, y2) [, [color] [, [B | BF] [, style]]]', 'Draws a line, a box (B) or a filled box (BF). style is a 16-bit dash pattern such as &HF0F0.', 'LINE (10, 10)-(100, 60), 4, BF'],
    ['CIRCLE', 'Graphics', 'CIRCLE [STEP] (x, y), radius [, [color] [, [start] [, [end] [, aspect]]]]', 'Draws circles, ellipses (aspect) and arcs (start/end in radians; negative values draw a line to the center — pie slices).', 'CIRCLE (160, 100), 50, 12, , , .5'],
    ['PAINT', 'Graphics', 'PAINT [STEP] (x, y) [, [color | tile$] [, bordercolor]]', 'Flood-fills an area up to the border color. tile$ fills with a pattern.', ''],
    ['DRAW', 'Graphics', 'DRAW commandstring$', 'A turtle-like drawing language: U D L R E F G H n (move), M x,y, B (move without drawing), N (return), C color, S scale, A/TA angle, P paint,border, X substring.', 'DRAW "C14 R50 D50 L50 U50"'],
    ['GET', 'Graphics', 'GET [STEP](x1, y1)-[STEP](x2, y2), array\nGET #file [, [record] [, variable]]', 'Copies a screen rectangle into a numeric array (for sprites), or reads a file record.', ''],
    ['PUT', 'Graphics', 'PUT [STEP](x, y), array [, {PSET | PRESET | AND | OR | XOR}]\nPUT #file [, [record] [, variable]]', 'Draws an image saved with GET (XOR by default, so PUTting twice erases), or writes a file record.', ''],
    ['VIEW', 'Graphics', 'VIEW [[SCREEN] (x1, y1)-(x2, y2) [, [color] [, border]]]', 'Sets a graphics viewport; drawing is clipped to it. Without SCREEN, coordinates are relative to the viewport corner.', ''],
    ['WINDOW', 'Graphics', 'WINDOW [[SCREEN] (x1, y1)-(x2, y2)]', 'Lets you use your own coordinate system (for example -1 to 1). Without SCREEN, y increases upwards like in math.', 'WINDOW (-10, -10)-(10, 10)'],
    ['PMAP', 'Graphics', 'PMAP(coordinate, n)', 'Converts between WINDOW and pixel coordinates (n = 0..3).', ''],
    ['POINT', 'Graphics', 'POINT(x, y)\nPOINT(n)', 'Color of a pixel, or (with one argument) the current graphics position.', ''],
    ['PALETTE', 'Graphics', 'PALETTE [attribute, color]\nPALETTE USING array(start)', 'Changes which real color an attribute shows. In SCREEN 12/13 color = 65536*blue + 256*green + red (each 0-63).', 'PALETTE 1, 63 * 65536   \' attribute 1 becomes bright blue'],
    ['PCOPY', 'Graphics', 'PCOPY sourcepage, destpage', 'Copies one video page to another (for flicker-free animation).', ''],
    // ---- Sound
    ['BEEP', 'Sound', 'BEEP', 'A short beep from the PC speaker.', ''],
    ['SOUND', 'Sound', 'SOUND frequency, duration', 'Plays a tone. frequency is in Hz (37-32767), duration in clock ticks (18.2 per second).', 'SOUND 440, 18   \' A for one second'],
    ['PLAY', 'Sound', 'PLAY commandstring$\nPLAY(n)\nPLAY {ON | OFF | STOP}', 'Plays music: notes A-G (with # + -), O octave, < >, L length, T tempo, P pause, N note number, MN/ML/MS styles, MF/MB foreground/background.', 'PLAY "T120 O3 L8 CDEFGAB>C"'],
    // ---- Strings
    ['LEFT$', 'Strings', 'LEFT$(string$, n)', 'The first n characters.', 'PRINT LEFT$("BASIC", 3)   \' BAS'],
    ['RIGHT$', 'Strings', 'RIGHT$(string$, n)', 'The last n characters.', ''],
    ['MID$', 'Strings', 'MID$(string$, start [, length])\nMID$(stringvar$, start [, length]) = replacement$', 'Part of a string; as a statement, replaces characters inside a string variable.', ''],
    ['LEN', 'Strings', 'LEN(string$ | variable)', 'Number of characters (or bytes of a variable).', ''],
    ['INSTR', 'Strings', 'INSTR([start,] string$, find$)', 'Position of find$ inside string$ (0 if not found).', ''],
    ['UCASE$', 'Strings', 'UCASE$(string$)', 'Converts to UPPER CASE.', ''],
    ['LCASE$', 'Strings', 'LCASE$(string$)', 'Converts to lower case.', ''],
    ['LTRIM$', 'Strings', 'LTRIM$(string$)', 'Removes leading spaces.', ''],
    ['RTRIM$', 'Strings', 'RTRIM$(string$)', 'Removes trailing spaces.', ''],
    ['STR$', 'Strings', 'STR$(number)', 'Number to string (with a leading space for positive numbers).', ''],
    ['VAL', 'Strings', 'VAL(string$)', 'String to number. Stops at the first character that is not part of a number.', ''],
    ['CHR$', 'Strings', 'CHR$(code)', 'The character with an ASCII/CP437 code (0-255).', 'PRINT CHR$(1); CHR$(3)   \' smiley and heart'],
    ['ASC', 'Strings', 'ASC(string$)', 'The code of the first character.', ''],
    ['STRING$', 'Strings', 'STRING$(n, code | string$)', 'A string of n copies of a character.', 'PRINT STRING$(20, "=")'],
    ['SPACE$', 'Strings', 'SPACE$(n)', 'A string of n spaces.', ''],
    ['HEX$', 'Strings', 'HEX$(number)', 'Hexadecimal text of a number.', ''],
    ['OCT$', 'Strings', 'OCT$(number)', 'Octal text of a number.', ''],
    ['LSET', 'Strings', 'LSET variable = expression', 'Left-justifies a string into a fixed-length or FIELD variable (also copies records).', ''],
    ['RSET', 'Strings', 'RSET stringvariable = expression', 'Right-justifies a string into a fixed-length or FIELD variable.', ''],
    ['MKI$', 'Strings', 'MKI$(n)  MKL$(n)  MKS$(n)  MKD$(n)\nCVI(s$)  CVL(s$)  CVS(s$)  CVD(s$)', 'Convert numbers to/from their binary string form (2, 4, 4, 8 bytes) for random-access files. MKSMBF$/CVSMBF etc. use the old GW-BASIC (Microsoft Binary Format) layout.', ''],
    ['DATE$', 'Strings', 'DATE$\nDATE$ = "mm-dd-yyyy"', "Today's date as mm-dd-yyyy.", ''],
    ['TIME$', 'Strings', 'TIME$\nTIME$ = "hh:mm:ss"', 'The current time as hh:mm:ss.', ''],
    // ---- Math
    ['ABS', 'Math', 'ABS(n)', 'Absolute value.', ''],
    ['SGN', 'Math', 'SGN(n)', '-1, 0 or 1 depending on the sign.', ''],
    ['INT', 'Math', 'INT(n)', 'Largest whole number <= n (INT(-2.5) = -3).', ''],
    ['FIX', 'Math', 'FIX(n)', 'Drops the fraction (FIX(-2.5) = -2).', ''],
    ['CINT', 'Math', 'CINT(n)  CLNG(n)  CSNG(n)  CDBL(n)', 'Convert to INTEGER (rounding), LONG, SINGLE or DOUBLE.', ''],
    ['SQR', 'Math', 'SQR(n)', 'Square root.', ''],
    ['SIN', 'Math', 'SIN(angle)  COS(angle)  TAN(angle)  ATN(n)', 'Trigonometry with angles in radians (degrees * 3.14159 / 180).', ''],
    ['EXP', 'Math', 'EXP(n)  LOG(n)', 'e to the power n, and the natural logarithm.', ''],
    ['RND', 'Math', 'RND[(n)]', 'Random number from 0 up to (not including) 1. Use INT(RND * 6) + 1 for a dice roll.', 'RANDOMIZE TIMER\nPRINT INT(RND * 6) + 1'],
    ['RANDOMIZE', 'Math', 'RANDOMIZE [seed]', 'Starts a new random sequence. RANDOMIZE TIMER gives different numbers each run.', ''],
    ['TIMER', 'Math', 'TIMER\nTIMER {ON | OFF | STOP}', 'Seconds since midnight (great for timing). With ON TIMER(n) GOSUB, runs a handler every n seconds.', 't = TIMER: DO: LOOP UNTIL TIMER - t >= 1'],
    ['MOD', 'Math', 'a MOD b', 'Remainder of integer division.', ''],
    ['AND', 'Math', 'a AND b   a OR b   a XOR b   NOT a   a EQV b   a IMP b', 'Logical (bitwise) operators. True is -1 and false is 0.', ''],
    // ---- Files
    ['OPEN', 'Files', 'OPEN file$ [FOR {INPUT | OUTPUT | APPEND | RANDOM | BINARY}] AS [#]n [LEN = reclen]\nOPEN mode$, [#]n, file$ [, reclen]', 'Opens a file on the virtual disk (C:) or a mounted folder (D:). Devices: "SCRN:", "KYBD:", "LPT1:".', 'OPEN "SCORES.TXT" FOR APPEND AS #1\nPRINT #1, name$, score\nCLOSE #1'],
    ['CLOSE', 'Files', 'CLOSE [[#]n [, [#]n]...]', 'Closes files (all of them if no numbers are given).', ''],
    ['EOF', 'Files', 'EOF(n)', 'True (-1) at the end of a file.', 'DO WHILE NOT EOF(1): LINE INPUT #1, l$: PRINT l$: LOOP'],
    ['LOF', 'Files', 'LOF(n)', 'Length of an open file in bytes.', ''],
    ['LOC', 'Files', 'LOC(n)', 'Current position (record number for RANDOM files).', ''],
    ['SEEK', 'Files', 'SEEK #n, position\nSEEK(n)', 'Sets or returns the next read/write position.', ''],
    ['FIELD', 'Files', 'FIELD #n, width AS string$ [, ...]', 'Divides a RANDOM file record buffer into named string fields (GW-BASIC style; TYPE records are easier).', ''],
    ['FREEFILE', 'Files', 'FREEFILE', 'The next unused file number.', ''],
    ['KILL', 'Files', 'KILL filespec$', 'Deletes files (wildcards allowed).', ''],
    ['NAME', 'Files', 'NAME oldname$ AS newname$', 'Renames a file.', ''],
    ['FILES', 'Files', 'FILES [filespec$]', 'Lists files in the current directory.', ''],
    ['MKDIR', 'Files', 'MKDIR path$   CHDIR path$   RMDIR path$', 'Creates, changes to, or removes a directory.', ''],
    ['BLOAD', 'Files', 'BLOAD file$ [, offset]\nBSAVE file$, offset, length', 'Loads or saves raw memory (e.g. a SCREEN 13 picture at DEF SEG = &HA000, or an array).', 'DEF SEG = &HA000: BSAVE "PIC.BSV", 0, 64000'],
    // ---- Errors & events
    ['ON ERROR', 'Errors & events', 'ON ERROR GOTO line\nON ERROR GOTO 0', 'Sends errors to your own handler instead of stopping. Use ERR and ERL to see what happened, and RESUME to continue.', 'ON ERROR GOTO Oops\nx = 1 / 0\nEND\nOops: PRINT "Error"; ERR: RESUME NEXT'],
    ['RESUME', 'Errors & events', 'RESUME [0 | NEXT | line]', 'Leaves an error handler: retry the statement, continue after it, or jump to a line.', ''],
    ['ERROR', 'Errors & events', 'ERROR n', 'Causes error number n (useful for testing handlers).', ''],
    ['ERR', 'Errors & events', 'ERR   ERL', 'The code of the last error and the line number where it happened.', ''],
    ['TRON', 'Errors & events', 'TRON   TROFF', 'Turns on/off printing of [line numbers] as each numbered line runs (GW-BASIC tracing).', ''],
    // ---- System
    ['PEEK', 'Memory & ports', 'PEEK(address)\nPOKE address, byte', 'Reads/writes memory in the DEF SEG segment. Emulated: video memory (&HB800 text, &HA000 VGA), BIOS keyboard flags (0:&H417), timer ticks, and array memory via VARSEG/VARPTR.', 'DEF SEG = &HB800: POKE 0, 65   \' an A in the corner'],
    ['INP', 'Memory & ports', 'INP(port)\nOUT port, byte\nWAIT port, and [, xor]', 'Emulated I/O ports: VGA palette &H3C7-&H3C9, retrace status &H3DA, keyboard scan code &H60, PC speaker &H42/&H43/&H61, joystick &H201.', 'OUT &H3C8, 1: OUT &H3C9, 63: OUT &H3C9, 0: OUT &H3C9, 0'],
    ['VARPTR', 'Memory & ports', 'VARPTR(variable)  VARSEG(variable)  SADD(string$)  VARPTR$(variable)', 'Addresses of variables (emulated). VARPTR$ is used with DRAW and PLAY ("X" + VARPTR$(a$)).', ''],
    ['FRE', 'Memory & ports', 'FRE(n)', 'Free memory (simulated).', ''],
    ['SHELL', 'Memory & ports', 'SHELL [command$]', 'Runs a few DOS commands (DIR, TYPE, COPY, DEL, ECHO, CD, MD, RD) against the virtual disk.', ''],
    ['ENVIRON', 'Memory & ports', 'ENVIRON "name=value"\nENVIRON$(name$ | n)', 'Sets/reads simulated environment variables.', ''],
    ['STICK', 'Memory & ports', 'STICK(n)   STRIG(n)', 'Joystick position and buttons — uses a connected gamepad.', ''],
    ['PEN', 'Memory & ports', 'PEN(n)', 'Light pen, emulated with the mouse on the output screen.', ''],
    // ---- GW-BASIC commands
    ['LIST', 'GW-BASIC commands', 'LIST [line][-[line]]', 'Shows program lines (GW-BASIC console).', ''],
    ['AUTO', 'GW-BASIC commands', 'AUTO [start][, increment]', 'Types line numbers for you. Ctrl+C (or Ctrl+Break) stops.', ''],
    ['RENUM', 'GW-BASIC commands', 'RENUM [new][, [old][, increment]]', 'Renumbers lines and updates GOTO/GOSUB references.', ''],
    ['DELETE', 'GW-BASIC commands', 'DELETE line[-line]', 'Deletes program lines.', ''],
    ['EDIT', 'GW-BASIC commands', 'EDIT line', 'Shows a line for editing on the screen.', ''],
    ['NEW', 'GW-BASIC commands', 'NEW', 'Erases the program in memory.', ''],
    ['LOAD', 'GW-BASIC commands', 'LOAD "file"[, R]   SAVE "file"   MERGE "file"', 'Loads, saves or merges a program file.', ''],
    ['CONT', 'GW-BASIC commands', 'CONT', 'Continues after STOP or Ctrl+Break.', ''],
    ['REM', 'GW-BASIC commands', "REM comment\n' comment", "Comments are ignored by BASIC. ' is a short form of REM.", ''],
    ["$INCLUDE", 'Metacommands', "' $INCLUDE: 'file.bi'", 'Inserts another source file at this point (QuickBASIC metacommand) — great for sharing declarations and procedures between programs.', ''],
    ['$DYNAMIC', 'Metacommands', "' $DYNAMIC   ' $STATIC", 'Makes later arrays dynamic (resizable) or static.', ''],
  ];

  const TOPICS = {
    'Screen modes': `<p>Pick a mode with <code>SCREEN n</code>. Text is always available, even in graphics modes.</p>
<table><tr><th>Mode</th><th>Resolution</th><th>Colors</th><th>Text</th><th>Pages</th><th>Hardware</th></tr>
<tr><td>0</td><td>text</td><td>16 fg / 8 bg</td><td>80/40 × 25/43/50</td><td>8</td><td>all</td></tr>
<tr><td>1</td><td>320×200</td><td>4 (2 palettes)</td><td>40×25</td><td>1</td><td>CGA</td></tr>
<tr><td>2</td><td>640×200</td><td>2</td><td>80×25</td><td>1</td><td>CGA</td></tr>
<tr><td>3</td><td>720×348</td><td>2</td><td>80×25</td><td>2</td><td>Hercules</td></tr>
<tr><td>7</td><td>320×200</td><td>16</td><td>40×25</td><td>8</td><td>EGA</td></tr>
<tr><td>8</td><td>640×200</td><td>16</td><td>80×25</td><td>4</td><td>EGA</td></tr>
<tr><td>9</td><td>640×350</td><td>16 of 64</td><td>80×25/43</td><td>2</td><td>EGA</td></tr>
<tr><td>10</td><td>640×350</td><td>4 grays</td><td>80×25/43</td><td>2</td><td>EGA mono</td></tr>
<tr><td>11</td><td>640×480</td><td>2</td><td>80×30/60</td><td>1</td><td>VGA</td></tr>
<tr><td>12</td><td>640×480</td><td>16 of 262144</td><td>80×30/60</td><td>1</td><td>VGA</td></tr>
<tr><td>13</td><td>320×200</td><td>256 of 262144</td><td>40×25</td><td>1</td><td>VGA</td></tr></table>
<p>Run <b>MODES.BAS</b> from the examples for a tour.</p>`,
    'Data types': `<table><tr><th>Type</th><th>Suffix</th><th>Range</th></tr>
<tr><td>INTEGER</td><td>%</td><td>-32768 to 32767</td></tr><tr><td>LONG</td><td>&amp;</td><td>-2147483648 to 2147483647</td></tr>
<tr><td>SINGLE</td><td>!</td><td>about 7 digits (default)</td></tr><tr><td>DOUBLE</td><td>#</td><td>about 16 digits</td></tr>
<tr><td>STRING</td><td>$</td><td>up to 32767 characters</td></tr><tr><td>STRING * n</td><td></td><td>fixed length n</td></tr></table>
<p><code>count%</code>, <code>count&amp;</code>, <code>count</code> and <code>count$</code> are four different variables. Use <code>DEFINT A-Z</code> to make integers the default. Numbers can be written in hex (<code>&amp;HFF</code>) and octal (<code>&amp;O17</code>).</p>`,
    'Operators': `<p>From highest to lowest priority:</p><pre>^              power
-              negation
*  /           multiply, divide
\\              integer divide
MOD            remainder
+  -           add, subtract (+ also joins strings)
=  <>  <  >  <=  >=     comparisons (true = -1, false = 0)
NOT, AND, OR, XOR, EQV, IMP     logic</pre>`,
    'Debugging': `<p>The debugger lets you pause your program and look inside it.</p><ul>
<li><b>Breakpoints:</b> click in the gutter left of a line (or press <kbd>F9</kbd>). The program pauses before that line runs. Right-click the gutter for <i>conditional</i> breakpoints like <code>i = 50</code>.</li>
<li><b>Stepping:</b> <kbd>F8</kbd> runs one statement (going into SUBs), <kbd>F10</kbd> steps over calls, <kbd>Shift+F8</kbd> finishes the current SUB, <kbd>F7</kbd> runs to the cursor.</li>
<li><b>Variables:</b> see every variable; double-click a value to change it — even inside a recursive call.</li>
<li><b>Call Stack:</b> shows which SUBs/FUNCTIONs are active, plus GOSUB returns and FOR loops. Click a frame to inspect it.</li>
<li><b>Watch:</b> expressions evaluated every time you pause; set "break on change" to stop when a value changes.</li>
<li><b>Immediate:</b> type any statement (<code>PRINT x</code>, <code>x = 10</code>) or <code>? expression</code>.</li>
<li><b>Hover</b> over a variable while paused to see its value. <b>Set Next Statement</b> moves the execution point.</li>
<li><b>History</b> lists recently executed statements; <b>Animate</b> highlights each line as it runs.</li>
<li><code>STOP</code> in your code pauses like a breakpoint; <code>TRON</code> prints line numbers as they run.</li></ul>`,
    'GW-BASIC console': `<p>View ▸ <b>GW-BASIC Classic Console</b> turns the output screen into a 1980s BASIC prompt.</p><ul>
<li>Type a line with a number (<code>10 PRINT "HI"</code>) to add it to the program; a number alone deletes that line.</li>
<li>Anything else runs immediately: <code>PRINT 2+2</code>, <code>CLS</code>, <code>SCREEN 1</code>…</li>
<li>Commands: <code>LIST</code>, <code>RUN</code>, <code>NEW</code>, <code>LOAD "NAME"</code>, <code>SAVE "NAME"</code>, <code>MERGE</code>, <code>FILES</code>, <code>AUTO</code>, <code>RENUM</code>, <code>DELETE</code>, <code>EDIT</code>, <code>CONT</code>, <code>SYSTEM</code>.</li>
<li>It is a full-screen editor: move the cursor anywhere (even onto a listed line), change it and press Enter.</li>
<li>F1–F10 type the soft keys shown on the bottom line (F2 = RUN).</li></ul><p>The program you build appears in the editor too — you can switch between both styles.</p>`,
    'Files and disks': `<p>Your programs see a DOS-style disk:</p><ul><li><b>C:</b> is a virtual disk saved in this browser (examples are in C:\\SAMPLES, your programs in C:\\MYPROGS).</li>
<li><b>D:</b> appears if you mount a folder from your computer (File ▸ Mount). You choose read-only, ask-before-writing or allow-writes.</li>
<li>Programs can only touch these drives — never anything else on your computer — and file sizes are limited.</li>
<li>Import and download files with the explorer buttons; share a whole folder as a link with File ▸ Share.</li></ul>`,
    'Limitations': `<p>Baysik aims to run GW-BASIC and QBasic programs unchanged. A few things cannot work in a browser:</p><ul>
<li><code>CALL ABSOLUTE</code>, <code>USR</code> and machine code; <code>INT 21h</code>-style DOS calls.</li>
<li>Serial ports (<code>COM1:</code>) and <code>IOCTL</code>.</li>
<li>Memory is emulated: video memory, BIOS keyboard flags, timer ticks and arrays (VARSEG/VARPTR) behave like a PC; other addresses are plain RAM.</li>
<li>Floating point uses IEEE math (like QBasic) rather than GW-BASIC's older Microsoft Binary Format, so the last digit can differ in rare cases. Use MKSMBF$/CVSMBF to read old GW-BASIC data files.</li></ul>`,
  };

  const ERROR_HINTS = {
    1: 'A NEXT was reached but no FOR loop is active. Check that every FOR has a matching NEXT with the same variable.',
    2: 'BASIC could not understand this line. Look for a missing quote, parenthesis, comma, or a misspelled keyword.',
    3: 'RETURN was reached without a GOSUB. Did the program "fall into" a subroutine? Put END before your subroutines.',
    4: 'READ ran out of DATA items. Add more DATA, or use RESTORE to start over.',
    5: 'A function got a value it cannot use, e.g. SQR(-1), LEFT$(a$, -1), or coordinates/colors out of range.',
    6: 'A number got too big for its type. INTEGER (%) stops at 32767 — try LONG (&) or SINGLE.',
    7: 'Too much memory or recursion. Is a SUB or FUNCTION calling itself forever?',
    8: 'GOTO, GOSUB or RESTORE points to a line number or label that does not exist.',
    9: 'An array index is outside its DIM range (arrays without DIM go from 0 to 10).',
    10: 'Something was declared twice, e.g. DIM on an array that already exists, or a variable name used with two different types.',
    11: 'You divided by zero. Check the divisor before dividing.',
    13: 'A string was used where a number is needed (or the other way round). String variables end with $.',
    18: 'A FN function is used but no DEF FN defines it.',
    20: 'RESUME was reached outside an error handler.',
    35: 'This SUB does not exist. Check the spelling, or create it with SUB … END SUB.',
    37: 'The number of arguments does not match the SUB or FUNCTION definition.',
    52: 'File number not open (or invalid). OPEN the file first.',
    53: 'File not found. Check the name in the Files panel; the current folder is the program\'s folder.',
    54: 'This operation does not match how the file was opened (e.g. INPUT # on a file opened FOR OUTPUT).',
    55: 'That file number (or file) is already open. CLOSE it first.',
    62: 'Tried to read past the end of the file. Check EOF(n) before reading.',
    70: 'Writing to this drive is not allowed. Mounted folders can be read-only — see File ▸ Mount.',
    73: 'This feature needs real DOS hardware and is not available in the browser.',
    76: 'The folder does not exist. Create it with MKDIR.',
  };

  RC.BASIC_HELP = { KEYWORDS: K, TOPICS, ERROR_HINTS };
})(RC);
