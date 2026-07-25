' ============================================================
' TITLE:    Simple Spell Checker
' CATEGORY: Strings & Text Processing
' LEVEL:    Intermediate
' TAGS:     spell check, binary search, edit distance, suggestions, DATA
' SUMMARY:  Checks each word of your sentence against a DATA dictionary and suggests corrections.
' ------------------------------------------------------------
' WHAT IT DOES
'   Loads a dictionary of about 250 common English words from DATA,
'   sorts it, then checks every word you type.  Words that are not
'   in the dictionary are shown in red with up to three suggestions.
'
'   Suggestions are found the way early spell checkers did it: try
'   every "one-mistake" fix of the word and see which ones are real
'   words.  The four kinds of single mistake are:
'     deletion      (helo  -> hello : a letter is missing)
'     insertion     (hellio -> hello: an extra letter)
'     substitution  (hallo -> hello : one wrong letter)
'     transposition (hlelo -> hello : two letters swapped)
'
' HOW TO USE
'   Type a sentence and press Enter.  Empty line or Q to quit.
'   Try: "the quik brown fox jumpd ovr the lazy dgo"
'
' CONCEPTS YOU WILL LEARN
'   * Sorting a word list, then BINARY SEARCH to look words up fast
'   * Generating candidate strings with LEFT$ / MID$ / CHR$ loops
'   * Avoiding duplicate suggestions
'
' THINGS TO TRY
'   * Add your own words to the dictionary DATA
'   * Allow TWO mistakes (apply the edits twice - much slower!)
'   * Rank suggestions by how common the word is
' ============================================================

DECLARE FUNCTION InDict% (w$)
DECLARE SUB Suggest (w$)
DECLARE SUB TryWord (c$)

CONST MAXD = 400
DIM SHARED dict$(MAXD), nd
DIM SHARED sug$(3), nsug
DIM badw$(20)                 ' misspelled words of the current sentence

' ---- load the dictionary ----
DO
    READ w$
    IF w$ = "*" THEN EXIT DO
    nd = nd + 1: dict$(nd) = UCASE$(w$)
LOOP
' ---- sort it (insertion sort) so binary search will work ----
FOR i = 2 TO nd
    t$ = dict$(i): j = i - 1
    DO WHILE j >= 1
        IF dict$(j) <= t$ THEN EXIT DO
        dict$(j + 1) = dict$(j): j = j - 1
    LOOP
    dict$(j + 1) = t$
NEXT i

CLS
COLOR 14: PRINT "SIMPLE SPELL CHECKER": COLOR 7
PRINT "Dictionary:"; nd; "words.  Unknown words appear in red."
DO
    PRINT
    LINE INPUT "Sentence (Enter = quit): "; s$
    IF s$ = "" OR UCASE$(s$) = "Q" THEN EXIT DO
    ' --- echo the sentence with misspellings in red ---
    PRINT "  ";
    bad = 0: w$ = ""
    FOR i = 1 TO LEN(s$) + 1
        IF i <= LEN(s$) THEN c$ = MID$(s$, i, 1) ELSE c$ = " "
        u$ = UCASE$(c$)
        IF (u$ >= "A" AND u$ <= "Z") OR c$ = "'" THEN
            w$ = w$ + c$
        ELSE
            IF w$ <> "" THEN
                IF InDict%(UCASE$(w$)) THEN
                    COLOR 10
                ELSE
                    COLOR 12
                    IF bad < 20 THEN bad = bad + 1: badw$(bad) = w$
                END IF
                PRINT w$;
                w$ = ""
            END IF
            COLOR 7
            IF i <= LEN(s$) THEN PRINT c$;
        END IF
    NEXT i
    PRINT
    ' --- suggestions ---
    IF bad = 0 THEN
        PRINT "  No spelling problems found!"
    ELSE
        FOR b = 1 TO bad
            Suggest UCASE$(badw$(b))
            PRINT "  "; badw$(b); " -> ";
            IF nsug = 0 THEN
                PRINT "(no suggestions)"
            ELSE
                FOR k = 1 TO nsug
                    PRINT LCASE$(sug$(k)); " ";
                NEXT k
                PRINT
            END IF
        NEXT b
    END IF
LOOP
PRINT "Goodbye!"
END

' about 250 common words (keep "*" last)
DATA a,about,after,again,all,also,always,am,an,and,animal,another,any,are
DATA around,as,ask,at,away,back,be,because,been,before,best,better,big,bird
DATA black,blue,book,both,boy,bring,brown,but,by,call,came,can,cat,children
DATA city,close,cold,come,could,day,did,do,does,dog,done,down,draw,each,earth
DATA eat,end,every,eye,far,fast,father,find,first,fish,five,fly,food,for
DATA found,four,fox,friend,from,fun,funny,game,gave,get,girl,give,go,good,got
DATA great,green,had,happy,has,have,he,hello,help,her,here,him,his,home
DATA house,how,i,if,in,into,is,it,jump,jumped,jumps,just,keep,kind,know
DATA large,last,laugh,lazy,learn,left,let,light,like,line,little,live,long
DATA look,made,make,many,may,me,more,mother,much,must,my,name,never,new
DATA night,no,not,now,number,of,off,old,on,once,one,only,open,or,other
DATA our,out,over,people,place,play,please,pretty,program,put,quick,quiet
DATA ran,read,red,right,round,run,said,saw,say,school,see,she,should,show
DATA sleep,small,so,some,soon,start,stop,story,take,tell,than,thank,that
DATA the,their,them,then,there,these,they,thing,think,this,three,time,to
DATA today,together,too,tree,try,two,under,up,us,use,very,walk,want,was
DATA water,way,we,well,went,were,what,when,where,which,white,who,why,will
DATA with,word,work,world,would,write,yellow,yes,you,your,*

' ------------------------------------------------------------
' InDict%: binary search.  Look at the middle word; if ours is
' smaller, throw away the top half, otherwise the bottom half.
' Each step halves the list, so 250 words need at most 8 looks.
' ------------------------------------------------------------
FUNCTION InDict% (w$)
    lo = 1: hi = nd
    DO WHILE lo <= hi
        mid = (lo + hi) \ 2
        IF dict$(mid) = w$ THEN InDict% = -1: EXIT FUNCTION
        IF dict$(mid) < w$ THEN lo = mid + 1 ELSE hi = mid - 1
    LOOP
    InDict% = 0
END FUNCTION

' ------------------------------------------------------------
' Suggest: generate every word that is ONE edit away from w$
' and keep the first three that are in the dictionary.
' ------------------------------------------------------------
SUB Suggest (w$)
    nsug = 0
    L = LEN(w$)
    ' transposition first - it is the most common typing slip
    FOR i = 1 TO L - 1
        TryWord LEFT$(w$, i - 1) + MID$(w$, i + 1, 1) + MID$(w$, i, 1) + MID$(w$, i + 2)
    NEXT i
    ' deletion: remove letter i
    FOR i = 1 TO L
        TryWord LEFT$(w$, i - 1) + MID$(w$, i + 1)
    NEXT i
    ' substitution and insertion: try every letter A..Z
    FOR c = 65 TO 90
        FOR i = 1 TO L
            TryWord LEFT$(w$, i - 1) + CHR$(c) + MID$(w$, i + 1)
        NEXT i
        FOR i = 1 TO L + 1
            TryWord LEFT$(w$, i - 1) + CHR$(c) + MID$(w$, i)
        NEXT i
    NEXT c
END SUB

' TryWord: if c$ is a real word we have not suggested yet, keep it.
SUB TryWord (c$)
    IF nsug >= 3 OR c$ = "" THEN EXIT SUB
    IF InDict%(c$) = 0 THEN EXIT SUB
    FOR k = 1 TO nsug
        IF sug$(k) = c$ THEN EXIT SUB
    NEXT k
    nsug = nsug + 1
    sug$(nsug) = c$
END SUB
