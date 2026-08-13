' ============================================================
' TITLE:    Mini DOS Prompt (ENVIRON, ENVIRON$, SHELL)
' CATEGORY: System, Events & Hardware
' LEVEL:    Intermediate
' TAGS:     environ, environ$, shell, dos, command interpreter, variables
' SUMMARY:  A tiny COMMAND.COM look-alike that manages environment variables and passes DIR, TYPE and friends to SHELL.
' ------------------------------------------------------------
' WHAT IT DOES
'   DOS keeps a list of "environment variables" such as PATH=C:\DOS.
'   BASIC can read and change that list:
'     ENVIRON$("PATH")   - value of one variable ("" if not set)
'     ENVIRON$(n)        - the n-th entry as "NAME=value"
'     ENVIRON "X=hello"  - set (or with "X=" remove) a variable
'   SHELL "command" runs a DOS command and then returns to BASIC.
'   This program is a mini command prompt.  It handles SET, ECHO (with
'   %VAR% expansion) and HELP itself, and hands everything else, like
'   DIR or TYPE, to SHELL.
'
' HOW TO USE
'   Try:  SET            SET NAME=Ada        ECHO Hi %NAME%!
'         DIR            TYPE README.TXT      VER     SET NAME=
'         HELP           EXIT
'
' CONCEPTS YOU WILL LEARN
'   * Reading the whole environment with ENVIRON$(n) until it is ""
'   * Changing the environment with ENVIRON
'   * Using SHELL to run external commands
'   * Writing a small command interpreter: read, split, dispatch
'
' THINGS TO TRY
'   * Make the PROMPT variable control the prompt ($P = path, $G = >)
'   * Add an ALIAS command
'   * Keep a command history and recall it with !!
' ============================================================

DEFINT A-Z
DECLARE FUNCTION Expand$ (s$)

' Make a file so DIR and TYPE have something to show.
OPEN "README.TXT" FOR OUTPUT AS #1
PRINT #1, "Welcome to Mini DOS!"
PRINT #1, "This file was written by MINIDOS.BAS."
CLOSE #1

ENVIRON "USER=Student"            ' add a couple of our own variables
ENVIRON "GREETING=Hello"

CLS
PRINT "Mini DOS  -  type HELP for commands, EXIT to quit"
PRINT
DO
    LINE INPUT "C:\> "; cmd$
    cmd$ = LTRIM$(RTRIM$(cmd$))
    sp = INSTR(cmd$, " ")
    IF sp THEN verb$ = UCASE$(LEFT$(cmd$, sp - 1)): arg$ = LTRIM$(MID$(cmd$, sp + 1)) ELSE verb$ = UCASE$(cmd$): arg$ = ""

    SELECT CASE verb$
        CASE ""                                   ' empty line
        CASE "EXIT", "QUIT", "Q"
            EXIT DO
        CASE "HELP", "?"
            PRINT "  SET              list all environment variables"
            PRINT "  SET NAME=value   set a variable    SET NAME=  removes it"
            PRINT "  ECHO text        print text, %NAME% is replaced by its value"
            PRINT "  anything else    passed to SHELL (DIR, TYPE file, VER, CD ...)"
        CASE "SET"
            IF arg$ = "" THEN
                i = 1                             ' walk the list until ""
                DO
                    e$ = ENVIRON$(i)
                    IF e$ = "" THEN EXIT DO
                    PRINT "  "; e$
                    i = i + 1
                LOOP
            ELSEIF INSTR(arg$, "=") = 0 THEN
                v$ = ENVIRON$(arg$)
                IF v$ = "" THEN PRINT "  "; UCASE$(arg$); " is not set" ELSE PRINT "  "; UCASE$(arg$); "="; v$
            ELSE
                ENVIRON arg$                      ' e.g. "NAME=Ada"
            END IF
        CASE "ECHO"
            PRINT Expand$(arg$)
        CASE ELSE
            SHELL Expand$(cmd$)                   ' let "DOS" handle it
    END SELECT
LOOP
PRINT "Goodbye, "; ENVIRON$("USER"); "."
END

' Replace every %NAME% in s$ by the value of that environment variable.
FUNCTION Expand$ (s$)
    res$ = "": p = 1
    DO
        a = INSTR(p, s$, "%")
        IF a = 0 THEN EXIT DO
        b = INSTR(a + 1, s$, "%")
        IF b = 0 THEN EXIT DO
        res$ = res$ + MID$(s$, p, a - p) + ENVIRON$(MID$(s$, a + 1, b - a - 1))
        p = b + 1
    LOOP
    Expand$ = res$ + MID$(s$, p)
END FUNCTION
