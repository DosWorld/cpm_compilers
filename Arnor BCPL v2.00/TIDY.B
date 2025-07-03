
/* This is a BCPL beautifier. It will turn all keywords into upper case and
   all identifiers into lower case */

// modified 30/10/1986

/* read in the standard library header */

OPTION B-

GET "clibhdr"

OPTION B+

MANIFEST
$(
  indentsize = 2
  comments = 35
$)


GLOBAL
$(
  keywords: 0
  input: 1
  output: 2
  errvec: 3
  error: 4
  lastchr: 5
  keyend: 6
$)

STATIC
$(
  indent = 0
  nldone = TRUE
  idflag = FALSE
  column = 0
$)

LET err(message) BE

$(
  newline()
  writes(message)
  newline()
  longjump(error, errvec)
$)


LET space(char) = ( char=' ' | char=9 )

LET rawchr() = VALOF

$(
  LET temp = readch(input)
  WHILE temp = 10 DO temp := readch(input)
  IF lastchr = endstreamch LOGAND temp = endstreamch THEN err("Unexpected EOF")
  lastchr := temp
  RESULTIS lastchr
$)


LET getchr() = VALOF

$(
  rawchr()
  IF 'A' <= lastchr <= 'Z' THEN lastchr := lastchr + 32
  RESULTIS lastchr
$)


LET out(character) BE

$(
  UNLESS nldone LOGOR character = 13 THEN
  $(
    nldone := TRUE
    FOR space = 1 TO indent out(' ')
  $)
  TEST character = 13 THEN
  $(
    newline()
    writech(13,output)
    writech(10,output)

    nldone := FALSE
    idflag := FALSE
    column := 0
  $)
  ELSE
  $(
    column := column + 1
    wrch(character)
    writech(character,output)
  $)
$)


LET hexval(char) = VALOF

$(
  TEST '0' <= char <= '9' THEN RESULTIS char - '0'
  ELSE TEST 'a' <= char <= 'f' THEN RESULTIS char - 'a' + 10
  ELSE RESULTIS 100
$)


LET readnum(base, first) BE

$(
  WHILE hexval(first) < base DO
  $(
    out(hexval(first) < 10 -> first, first - 32)
    first := getchr()
  $)
  idflag := 2
$)


LET stringsame(string1, string2) = VALOF

$(
  IF !string1 NE !string2 THEN RESULTIS FALSE
  FOR ptr = 1 TO !string1
  IF string1!ptr NE string2!ptr THEN RESULTIS FALSE
  RESULTIS TRUE
$)


LET sysword(word) = VALOF

$(
  LET start = keywords
  WHILE start < keyend DO
  $(
    IF stringsame(start + 1, word) THEN RESULTIS start
    start := start + start!1 + 2
  $)
  RESULTIS FALSE
$)


LET idspace() BE

$(
  IF idflag THEN out(' ')
$)


LET writeword(word) BE

$(
  LET ptr, idf = sysword(word), 1
  TEST ptr THEN
  $(
    IF !ptr LOGOR idflag THEN out(' ')
    FOR cptr = 1 TO word!0 out(word!cptr - 32)
    IF !ptr THEN
    $(
      out(' ')
      idf := 0
    $)
  $)
  ELSE
  $(
    idspace()
    FOR ptr = 1 TO word!0 DO out(word!ptr)
    idf := 2
  $)
  idflag := idf
$)


LET ident() BE

$(
  LET wordbuff = VEC 20
  LET wptr = 0
  WHILE 'a' <= lastchr <= 'z' LOGOR '0' <= lastchr <= '9' DO
  $(
    wptr := wptr + 1
    wordbuff!wptr := lastchr
    getchr()
  $)
  wordbuff!0 := wptr
  writeword(wordbuff)
$)


LET strchr() BE

$(
  TEST lastchr = '**' THEN
  $(
    out('**')
    out(rawchr())
  $)
  ELSE out(lastchr)
  rawchr()
$)


LET condnl() BE

$(
  IF nldone THEN out(13)
$)



LET punctuate() BE

$(
  LET temp = 0
  SWITCHON lastchr INTO
  $(
    CASE '$':
    condnl()
    temp := getchr()
    getchr()
    TEST temp = '(' THEN
    $(
      out('$')
      out('(')
      ident()
      indent := indent + indentsize
    $)
    ELSE
    $(
      indent := indent - indentsize
      out('$')
      out(')')
      ident()
    $)
    UNLESS lastchr = 13 THEN out(13)
    ENDCASE
    CASE ';':
    out(13)
    getchr()
    ENDCASE
    CASE '"':
    idspace()
    out('"')
    rawchr()
    UNTIL lastchr = '"' strchr()
    out('"')
    getchr()
    idflag := 2
    RETURN
    CASE '<': CASE '>':
    temp := lastchr
    getchr()
    out(' ')
    TEST lastchr = '=' LOGOR lastchr = temp THEN
    $(
      out(temp)
      out(lastchr)
      getchr()
    $)
    ELSE out(temp)
    out(' ')
    ENDCASE
    CASE ':':
    TEST getchr() = '=' THEN
    $(
      out(' ')
      out(':')
      out('=')
      out(' ')
      getchr()
    $)
    ELSE
    $(
      out(':')
      idflag := 1
      RETURN
    $)
    ENDCASE
    CASE '-':
    out(' ')
    TEST getchr() = '>' THEN
    $(
      out('-')
      out('>')
      getchr()
    $)
    ELSE out('-')
    out(' ')
    ENDCASE
    CASE '/':
    getchr()
    TEST lastchr = '**' THEN
    $(
      temp := indent
      indent := 0
      condnl()
      out('/')
      out('**')
      rawchr()
      $(
        UNTIL lastchr = '**' DO
        $(
          out(lastchr)
          rawchr()
        $)
        out('**')
        rawchr()
      $)
      REPEATUNTIL lastchr = '/'
      out('/')
      out(13)
      IF getchr() = 13 THEN getchr()
      indent := temp
    $)
    ELSE TEST lastchr = '/' THEN
    $(
      IF column > comments THEN out(13)
      FOR a = column TO comments out(' ')
      out('/')
      $(
        out(lastchr)
        rawchr()
      $)
      REPEATUNTIL lastchr = 13
      out(13)

      IF getchr() = 13 THEN getchr()
    $)
    ELSE TEST lastchr = '\' THEN
    $(
      out(' ')
      out('/')
      out('\')
      out(' ')
      getchr()
    $)
    ELSE
    $(
      out(' ')
      out('/')
      out(' ')
    $)
    ENDCASE
    CASE '\':
    getchr()
    TEST lastchr = '=' LOGOR lastchr = '/' THEN
    $(
      out(' ')
      out('\')
      out(lastchr)
      out(' ')
      getchr()
    $)
    ELSE out('\')
    ENDCASE
    CASE ')': CASE ']':
    out(lastchr)
    getchr()
    idflag := 2
    RETURN
    CASE ''':
    idspace()
    out(''')
    rawchr()

    strchr()
    out(''')
    getchr()
    idflag := 2
    RETURN
    CASE '!':
    IF idflag = 1 THEN out(' ')
    out('!')
    getchr()
    ENDCASE
    CASE '+': CASE '&': CASE '|': CASE '=': CASE '**':
    out(' ')
    out(lastchr)
    out(' ')
    getchr()
    ENDCASE
    CASE ',':
    out(lastchr)
    out(' ')
    getchr()
    ENDCASE
    DEFAULT: out(lastchr)
    getchr()
  $)
  idflag := FALSE
$)


LET beautify() BE

$(
  LET temp = 0
  WHILE (lastchr NE endstreamch) & (lastchr NE softeofch) DO
  $(
    WHILE space(lastchr) DO getchr()
    TEST 'a' <= lastchr <= 'z' THEN ident()
    ELSE TEST '0' <= lastchr <= '9' THEN
    $(
      idspace()
      readnum(10, lastchr)
    $)
    ELSE TEST lastchr = '#' THEN
    $(
      idspace()
      out('#')
      getchr()
      SWITCHON lastchr INTO
      $(
        CASE 'x': out('x')
        readnum(16, getchr())
        ENDCASE
        CASE 'b': out('b')
        readnum(2, getchr())
        ENDCASE
        CASE 'o': out('o')
        readnum(8, getchr())
        ENDCASE
        DEFAULT: readnum(8, lastchr)
      $)
    $)
    ELSE TEST lastchr = 13 THEN
    $(
      out(13)
      getchr()
    $)
    ELSE punctuate()
  $)
$)


LET files() BE
$(
  LET namein = VEC 10
  AND nameout = VEC 10
  writes("Enter the input file name:  ")
  reads(namein)
  newline()
  writes("Enter the output file name: ")
  reads(nameout)
  newline()
  UNLESS findinput(namein, input) THEN err("Can't open input")
  UNLESS findoutput(nameout, output) THEN err("Can't open output")
$)



LET readwords(string) BE

$(
  LET length, rest, lengthptr = string%0, 1, 0
  WHILE length > rest DO
  $(
    TEST string%rest = 'B' THEN
    $(
      !keyend := TRUE
      rest := rest + 1
    $)
    ELSE !keyend := FALSE
    lengthptr := keyend + 1
    keyend := keyend + 2
    !lengthptr := 0
    WHILE string%rest NE ',' DO
    $(
      !keyend := string%rest
      keyend, rest, !lengthptr := keyend + 1, rest + 1, !lengthptr + 1
    $)
    rest := rest + 1
  $)
$)


AND readsys() BE

$(
  readwords("and,be,break,by,case,do,default,Beq,Beqv,else,endcase,false,for,")
  readwords("finish,goto,Bge,Bgr,global,get,if,into,let,Blv,Ble,Bls,Blogor,Blogand,")
  readwords("loop,Blshift,manifest,Bne,not,Bneqv,or,resultis,return,Brem,Brshift,")
  readwords("Brv,repeat,repeatwhile,repeatuntil,switchon,static,to,test,true,")
  readwords("then,table,until,unless,vec,valof,while,inline,option,")
$)


LET start() BE

$(
  LET wordarray = VEC 500
  AND inbuff = VEC 82
  AND outbuff = VEC 82
  AND namein = VEC 10
  AND nameout = VEC 10
  AND lev = VEC 3
  level(lev)
  errvec, input, output := lev, inbuff, outbuff
  keywords, keyend := wordarray, wordarray
  readsys()
  files()
  getchr()
  beautify()
  error: closein(input)
  closeout(output)
  newline()
  writes("BCPL beautifier finished")
$)
.
