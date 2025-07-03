option b-
get "clibhdr"

/* A simple full screen editor */
/* CP/M version for CP/M 2.2 and CP/M Plus */
// modified 02/12/1986

MANIFEST $( ins = TRUE ; over = FALSE ; cursleft = #xF2 ; cursright = #xF3
            cursup = #xF0 ; cursdown = #xF1 ; escape = #xFC ; ignore = #xEF
            stop = 3
            scursup = #xF4 ; scursdown = #xF5 ; scursleft = #xF6
            scursright = #xF7
            ccursup = #xF8 ; ccursdown = #xF9
            ccursleft = #xFA ; ccursright = #xFB
            copensq = 27 ; cclosesq = 29
            maxscrheight = 31
            maxchr = 22998     // can be increased for CP/M Plus only
          $)


/*
   textend points to the last character in the file which will always be a
   character 13. textptr points to the first character of the current line.
   textstart points to the start of the text space.
*/

STATIC $( insert = ins ; textend = 0 ; textptr = 0 ; textstart = 0
          x = 1 ; y = 1 ; prev = 0 ; file = 0 ; buffprint = FALSE
          linenumber = 1  ; scrheight=0  ; ver=0 $)

GLOBAL $( errvec : 0 ; errlab : 1 $)


LET bytemove(source,dest,number) BE

$(
  inline 221,102,123      // ld h,(ix+123)
  inline 221,110,122      // ld l,(ix+122)
  inline 221,86,125       // ld d,(ix+125)
  inline 221,94,124       // ld e,(ix+124)
  inline 221,70,127       // ld b,(ix+127)
  inline 221,78,126       // ld c,(ix+126)
  inline 167              // and a
  inline 237,82           // sbc hl,de
  inline 25               // add hl,de
  inline 56,4             // jr c,+4
  inline 237,176          // ldir
  inline 24,8             // jr +8
  inline 11               // dec bc
  inline 9                // add hl,bc
  inline 235              // ex de,hl
  inline 9                // add hl,bc
  inline 235              // ex de,hl
  inline 3                // inc bc
  inline 237,184          // lddr
$)

LET call(addr,af,bc,de,hl,ix) BE

$(  LET save3 = VEC 1
    bytemove(#x90, save3*2, 3)
    0%#x90 := #xC3
    0%#x91 := addr & #xFF
    0%#x92 := ( addr & #xFF00 ) >> 8

    inline #xDD,#xE5            // push ix
    inline #xDD,#x66,#x77       // ld h,(ix+119)
    inline #xDD,#x6E,#x76       // ld l,(ix+118)
    inline #x29                 // add hl,hl
    inline #x5E                 // ld e,(hl)
    inline #x23                 // inc hl
    inline #x56                 // ld d,(hl)
    inline #xD5                 // push de
    inline #xDD,#x66,#x79       // ld h,(ix+121)
    inline #xDD,#x6E,#x78       // ld l,(ix+120)
    inline #x29                 // add hl,hl
    inline #x4E                 // ld c,(hl)
    inline #x23                 // inc hl
    inline #x46                 // ld b,(hl)
    inline #xDD,#x66,#x7F       // ld h,(ix+127)
    inline #xDD,#x6E,#x7E       // ld l,(ix+126)
    inline #x29                 // add hl,hl
    inline #x5E                 // ld e,(hl)
    inline #x23                 // inc hl
    inline #x56                 // ld d,(hl)
    inline #xD5                 // push de
    inline #xDD,#x66,#x7D       // ld h,(ix+125)
    inline #xDD,#x6E,#x7C       // ld l,(ix+124)
    inline #x29                 // add hl,hl
    inline #x5E                 // ld e,(hl)
    inline #x23                 // inc hl
    inline #x56                 // ld d,(hl)
    inline #xD5                 // push de
    inline #xDD,#x66,#x7B       // ld h,(ix+123)
    inline #xDD,#x6E,#x7A       // ld l,(ix+122)
    inline #x29                 // add hl,hl
    inline #x5E                 // ld e,(hl)
    inline #x23                 // inc hl
    inline #x56                 // ld d,(hl)
    inline #xE1                 // pop hl
    inline #xDD,#xE1            // pop ix
    inline #xF1                 // pop af
    inline #xCD,#x90,#x00       // call &90
    inline #xDD,#x22,#x90,#x00  // ld (&90),ix
    inline #xDD,#xE1            // pop ix
    inline #xF5                 // push af
    inline #xE5                 // push hl
    inline #xDD,#x66,#x7B       // ld h,(ix+123)
    inline #xDD,#x6E,#x7A       // ld l,(ix+122)
    inline #x29                 // add hl,hl
    inline #x73                 // ld (hl),e
    inline #x23                 // inc hl
    inline #x72                 // ld (hl),d
    inline #xDD,#x66,#x7D       // ld h,(ix+125)
    inline #xDD,#x6E,#x7C       // ld l,(ix+124)
    inline #x29                 // add hl,hl
    inline #xD1                 // pop de
    inline #x73                 // ld (hl),e
    inline #x23                 // inc hl
    inline #x72                 // ld (hl),d
    inline #xDD,#x66,#x7F       // ld h,(ix+127)
    inline #xDD,#x6E,#x7E       // ld l,(ix+126)
    inline #x29                 // add hl,hl
    inline #xED,#x5B,#x90,#x00  // ld de,(&90)
    inline #x73                 // ld (hl),e
    inline #x23                 // inc hl
    inline #x72                 // ld (hl),d
    inline #xDD,#x66,#x79       // ld h,(ix+121)
    inline #xDD,#x6E,#x78       // ld l,(ix+120)
    inline #x29                 // add hl,hl
    inline #x71                 // ld (hl),c
    inline #x23                 // inc hl
    inline #x70                 // ld (hl),b
    inline #xDD,#x66,#x77       // ld h,(ix+119)
    inline #xDD,#x6E,#x76       // ld l,(ix+118)
    inline #x29                 // add hl,hl
    inline #xD1                 // pop de
    inline #x73                 // ld (hl),e
    inline #x23                 // inc hl
    inline #x72                 // ld (hl),d
    bytemove(save3*2, #x90, 3)
$)

LET firmware(addr,af,bc,de,hl,ix) BE

$(  LET save6 = VEC 3
    bytemove(#x80, save6*2, 6)
    0%#x80 := #xCD
    0%#x81 := 0%(0%1 + 256*0%2 + 87 +1)
    0%#x82 := 0%(0%1 + 256*0%2 + 87 +2)
    0%#x83 := addr & #xFF
    0%#x84 := ( addr & #xFF00 ) >> 8
    0%#x85 := #xC9
    call (#x80,af,bc,de,hl,ix)
    bytemove(save6*2, #x80, 6)
$)

and version() = VALOF

$(  LET c,de=12,?
    LET af,bc,hl,ix = ?,?,?,?
    bdosa(@c,@de)
    IF (de & #xFF) < #x30 THEN RESULTIS 2
    firmware(#xE3,@af,@bc,@de,@hl,@ix)
    RESULTIS 3 + ( (af & #xFF00) >> 8 )
$)

LET esccode(x) BE

$(  wrch(27) ; wrch(x)
$)


LET clearscr() BE
$(
    TEST ver=2 THEN wrch(12) ELSE esccode('E')
$)


LET tab(x,y) BE

$(

  TEST ver=2 THEN
  $(
    bdosb(6,31) ; bdosb(6,x) ; bdosb(6,y)
  $)
  ELSE
  $(
     esccode('Y') ; wrch(y+32-1) ; wrch(x+32-1)
  $)

$)


LET spaces(number) BE $( FOR a = 1 TO number DO wrch(' ') $)


LET ascii(char) BE

$(
  TEST char=13 THEN newline() ELSE wrch(char)
$)


LET curson() BE return
LET cursen() BE return
LET cursdi() BE return

LET beep() BE $( wrch(7) $)


/* This routine returns the number of characters up to and including the
   next CR */

LET linelength(from) = VALOF

$(
  LET sofar = 1
  WHILE !from NE 13 DO $( sofar := sofar + 1 ; from := from + 1 $)
  RESULTIS sofar
$)



/* This routine will print num characters of line and then fill the rest of the
   line with spaces */

AND printclr(line,num) BE

$(
  FOR a = 0 TO num-1 DO wrch(line!a)
  spaces(79-num)
$)


/* This routine will print either the whole buffer from x on or just the new
   character */

AND reprint(line,pos) BE

$(
  TEST insert THEN FOR a = pos TO line!0-1 DO wrch(line!a)
  ELSE wrch(line!pos)
$)



/* This routine will remove a character from the buffer */

AND delete(line,x) BE

$(
  TEST insert THEN
  $(
    line!0 := line!0 - 1
    FOR a = x TO line!0 DO line!a := line!(a+1)
  $)
  ELSE line!x := ' '
$)


/* This routine will insert a character into the buffer at the point given */

AND binsert(line,position,character) BE

$(
  TEST insert THEN
  $(
    FOR a = line!0 TO position BY -1 line!(a+1) := line!a
    line!position := character
    line!0 := line!0 + 1
  $)
  ELSE line!position := character
$)


AND validate(line,x) = VALOF

$(
  IF x <= line!0 THEN RESULTIS x
  tab(line!0,y)
  RESULTIS line!0
$)



/*

  The line given is in buffer in the following format

   0: length
   1- string in unpacked format followed by 13

  The routine reacts to key and takes the appropriate action

*/

AND buildbuff(buffer,key) = VALOF

$(
  tab(x,y)
  SWITCHON key INTO
  $(
    CASE 13:
      x := validate(buffer,x)
      binsert(buffer,x,13)
      wrch(13)
      printclr(buffer+1,linelength(buffer+1)-1) ; RESULTIS 13
    CASE cursleft: CASE scursleft:
      TEST x>1 THEN
        x := x - 1
      ELSE beep()
      ENDCASE
    CASE cursright: CASE scursright:
      TEST x <= buffer!0-1 THEN
        x := x + 1
      ELSE beep()
      ENDCASE
    CASE ccursleft:  x := 1 ; ENDCASE
    CASE ccursright: x := buffer!0 ; ENDCASE
    CASE scursup: CASE scursdown:
    CASE ccursup: CASE ccursdown:
    CASE copensq: CASE cclosesq:
    CASE escape: CASE stop: CASE cursup: CASE cursdown: RESULTIS key
    CASE 127:
      x := validate(buffer,x)
      IF x = 1 THEN RESULTIS 127
      x := x - 1
      tab(x,y)
      delete(buffer,x)
      reprint(buffer,x)
      IF insert THEN wrch(' ')
      ENDCASE
    DEFAULT:
      x := validate(buffer,x)
      TEST buffer!0 < 80 THEN
      $(
        binsert(buffer,x,key)
        reprint(buffer,x)
        IF insert LOGOR x<buffer!0 THEN x := x + 1
      $)
      ELSE beep()
      ENDCASE ;
    CASE ignore:
  $)
  RESULTIS FALSE
$)



/* This is the buffer edit routine */

LET buffer(line) = VALOF

$(
  LET keypress = 0
  $(
    tab(6,scrheight) ; writef("%I4",linenumber)
    tab(18,scrheight) ; writef("%I2",x)
    tab(x,y)
    cursen()
    keypress := rdch()
    cursdi()
    keypress := buildbuff(line,keypress)
  $) REPEATUNTIL keypress
  prev!y := linelength(line+1)-1
  RESULTIS keypress
$)


AND initbuff(line,from) BE

$(
  !line := 0
  $(
    !line := !line + 1
    line!(!line) := textstart%from
    from := from + 1
  $) REPEATUNTIL textstart%(from-1) = 13
$)




/* The above routines work with pointers and words. The next set of routines
   work with bytes and array indices */


LET linelength(from) = VALOF

$(
  LET sofar = 1
  WHILE textstart%from NE 13 DO $( sofar := sofar + 1 ; from := from + 1 $)
  RESULTIS sofar
$)



LET write(from,x,y) BE

$(
  tab(x,y)
  FOR a = from TO from + linelength(from) - 2 DO wrch(textstart%a)
  prev!y := linelength(from) - 1
$)


LET status() BE

$(
  tab(1,scrheight)
  TEST ver=4 THEN
    writef("Line:%I4 Column:%I2 (STOP to menu)",linenumber,x)
  ELSE
    writef("Line:%I4 Column:%I2 (ESC to menu)",linenumber,x)
$)



LET cls() BE

$(
  clearscr()
  curson() ; cursdi()
  FOR a = 1 TO scrheight-1 DO prev!a := 0
  status()
$)





/* This routine will move the text on the screen down a line and alter the
   previous array */

LET down() BE

$(
  tab(1,1) ; revlf() ; wrch(13)
  status() ; spaces(prev!(scrheight-1)-33)
  FOR a = scrheight-1 TO 2 BY -1 DO prev!a := prev!(a-1)
  prev!1 := 0
$)

AND revlf() BE
$(
  TEST ver=2 THEN
    wrch(11)
  ELSE
  $(
    esccode('I')
  $)
$)

/* This routine will move the text up one line and alter the previous array */

LET up() BE

$(
  tab(1,scrheight) ; spaces(40)
  wrch(10) ; wrch(13)
  FOR a = 1 TO scrheight-2 DO prev!a := prev!(a+1)
  prev!(scrheight-1) := 0
  status()
$)



/*
   This routine will reprint the screen from the y position and text position
   given.
*/

LET screen(from,ypos) BE

$(
  FOR y = ypos TO scrheight-1 DO
  $(
    LET l = 0
    tab(1,y)
    IF from > textend THEN $( spaces(80) ; prev!y := 0 ; BREAK $)
    l := linelength(from) - 1
    FOR a = from TO from + l - 1 DO wrch(textstart%a)
    spaces(prev!y-l)
    prev!y := l
    from := from + l + 1
  $)
$)



LET forward(ptr) = VALOF

$(
  IF ptr + linelength(ptr) > textend THEN
    $( beep() ; RESULTIS ptr $)
  ptr := ptr + linelength(ptr)
  RESULTIS ptr
$)

AND backline(ptr) = VALOF

$(
  IF ptr = 0 THEN $( beep() ; RESULTIS ptr $)
  ptr := ptr - 1
    REPEATWHILE textstart%(ptr-1) NE 13 LOGAND ptr NE 0
  RESULTIS ptr
$)


/* This routine will reconstruct the screen */

LET reconstruct(from) BE

$(
  LET tptr = from
  cls()
  FOR a = y TO 2 BY -1 DO
  $(
    TEST tptr = 0 THEN $( y := y - a + 1 ; BREAK $)
    ELSE tptr := backline(tptr)
  $)
  screen(tptr,1)
$)


LET error(message) BE

$(
  tab(1,scrheight) ; writef("%S. Hit any key to continue",message)
  beep()
  rdch()
  tab(33,scrheight) ; spaces(20) ; status()
  buffprint := TRUE
  reconstruct(textptr)
  longjump(errlab,errvec)
$)



LET makespace(at,size) BE

$(
  bytemove(textstart*2+at,textstart*2+at+size,textend-at+1)
  textend := textend + size
$)


AND closespace(at,size) BE

$(
  bytemove(textstart*2+at+size,textstart*2+at,textend-at-size+1)
  textend := textend - size
$)



AND copy(from,dest,number) BE

$(
  FOR a = 0 TO number-1 DO textstart%(dest+a) := from!a
$)


/* A buffer line is to be inserted at at */

LET linsert(line,at) BE

$(
  LET current, new = linelength(at), line!0
  TEST new-current+textend < maxchr THEN
  $(
    TEST current>new THEN closespace(at,current-new)
    ELSE IF current<new THEN makespace(at,new-current)
    copy(line+1,at,new)
  $)
  ELSE error("No room")
$)



LET getfilename(x,y,name) BE

$(
  tab(x,y) ; writes("Enter file name: ")
  cursen() ; reads(name) ; cursdi()
  newline()
$)



LET loadtext(line) = VALOF

$(
  LET name = VEC 20
  getfilename(25,19,name)
  TEST findinput(name,file) THEN
  $(
    LET char = 0
    textptr, x, y, linenumber, textend := 0, 1, 1, 1, -1
    textstart%0 := 13
    char := readch(file)
    UNTIL char = softeofch LOGOR char = endstreamch LOGOR textend = maxchr DO
    $(
      UNLESS char = 10 THEN
      $(
        textend := textend + 1
        textstart%textend := char
      $)
      char := readch(file)
    $)
    UNLESS textstart%textend = 13 DO
    $(
      textend := textend + 1
      textstart%textend := 13    
    $)
    IF textend >= maxchr THEN
    $(
      textend := textend - 1
      textstart%textend := 13
      closein(file)
      initbuff(line,0)
      error("No room")
    $)
    IF textend = -1 THEN textend := 0
    closein(file)
    RESULTIS TRUE
  $)
  ELSE
  $(
    writef("%S not found",name)
    rdch()
    RESULTIS FALSE
  $)
$)


AND savetext() = VALOF

$(
  LET name = VEC 20
  LET discerror(file) = VALOF
  $(
    writes("Disc error. Hit a key")
    rdch()
    closeout(file)
    RESULTIS FALSE
  $)
  getfilename(25,19,name)
  TEST findoutput(name,file) THEN
  $(
    FOR a = 0 TO textend DO
    $(
      UNLESS writech(textstart%a,file) THEN RESULTIS discerror(file)
      IF textstart%a = 13 THEN UNLESS writech(10,file) THEN
        RESULTIS discerror(file)
    $)
    closeout(file)
    RESULTIS TRUE
  $)
  ELSE
  $(
    writes("Cannot open ") ; writes(name)
    RESULTIS FALSE
  $)
$)


AND goline() BE

$(
  LET linenum = 0
  linenumber := 1
  tab(25,19)
  writef("Enter line number: ")
  cursen() ; linenum := readn() ; cursdi()
  textptr, x := 0, 1
  FOR count = 2 TO linenum DO
  $(
    LET optr = textptr
    textptr := forward(textptr)
    IF optr = textptr THEN BREAK
    linenumber := linenumber + 1
  $)
  y := 12
$)



/* This routine checks for a match */

AND match(from,target) = VALOF

$(
  FOR a = 1 TO target%0 DO
    IF textstart%(from+a-1) NE target%a THEN RESULTIS FALSE
  RESULTIS TRUE
$)



/* This is the find string routine */

AND findstring() BE

$(
  LET optr, ox, oy, oline = textptr, x, y, linenumber
  LET search = VEC 20
  tab(25,19)
  writef("Enter string: ")
  cursen() ; reads(search) ; cursdi()
  textptr := textptr + x - 1
  UNLESS textstart%textptr=13 THEN textptr := textptr + 1
  UNLESS textptr >= textend DO
  $(
    TEST textstart%textptr=13 THEN
      linenumber := linenumber + 1
    ELSE
    $(
      IF match(textptr,search) THEN
      $(
        optr := textptr
        WHILE textstart%(textptr-1) NE 13 LOGAND textptr NE 0 DO
          textptr := textptr - 1
        x, y := optr - textptr + 1, 12
        BREAK
      $)
    $)
    textptr := textptr + 1
    IF textptr >= textend THEN
    $(
      textptr, x, y, linenumber := optr, ox, oy, oline
      BREAK
    $)
  $) REPEAT
$)



/* This is the main menu routine */

LET menu(line) BE

$(
  LET tptr = 0
  linsert(line,textptr)
  $(
    LET key = 0
    clearscr()
    tab(32,4)  ; writes("BCPL editor")
    tab(32,5)  ; writes("-----------")
    tab(32,9)  ; writes("L: Load text")
    tab(32,10) ; writes("S: Save text")
    tab(32,11) ; writes("E: Edit text")
    tab(32,12) ; writes("G: Goto line")
    tab(32,13) ; writes("F: Find string")
    tab(32,14) ; writes("Q: Quit")
    tab(32,17) ; writes("Select option: ")
    $( cursen()
       key := rdch()
       cursdi()
    $) REPEATWHILE key = ignore
    SWITCHON key INTO
    $(
      CASE 'L': CASE 'l': wrch('L') ; IF loadtext(line) THEN BREAK ; ENDCASE
      CASE 'S': CASE 's': wrch('S') ; IF savetext() THEN BREAK ; ENDCASE
      CASE 'G': CASE 'g': wrch('G') ; goline() ; BREAK
      CASE 'F': CASE 'f': wrch('F') ; x := validate(line,x)
                                      findstring() ; BREAK
      CASE 'E': CASE 'e': wrch('E') ; BREAK
      CASE 'Q': CASE 'q': wrch('Q') ; finish
    $)
    beep()
  $) REPEAT
  reconstruct(textptr)
$)



/* This routine deals with the deletion of a CR */

LET deletel(line) BE

$(
  TEST textptr NE 0 THEN
  $(
    LET optr, tptr = textptr, backline(textptr)
    TEST linelength(tptr) + line!0 - 1 < 80 THEN
    $(
      IF line!0-linelength(textptr)+textend >= maxchr THEN error("No room")
      textstart%(textptr-1) := 0
      linsert(line,textptr-1)
      textptr := tptr
      linenumber := linenumber - 1
      x := linelength(textptr) - line!0 + 1
      TEST y = 1 THEN
      $(
        write(textptr,1,1)
      $)
      ELSE y := y - 1
    $)
    ELSE error("Line too long to join")
  $)
  ELSE error("Top of file")
$)


LET addl(line) BE

$(
  LET copy = VEC 80
  LET ptr = 1
  FOR a = 0 TO line!0 DO copy!a := line!a
  WHILE line!ptr NE 13 DO ptr := ptr + 1
  FOR a = ptr TO line!0-1 DO line!a := line!(a+1)
  line!0 := line!0 - 1
  linsert(copy,textptr)
  x, linenumber := 1, linenumber + 1
  textptr := forward(textptr)
  TEST y = scrheight-1 THEN
  $(
    up()
    write(textptr,1,scrheight-1)
  $)
  ELSE y := y + 1
$)


LET moveup() BE

$(
  UNLESS textptr = 0 THEN
  $(
    textptr := backline(textptr)
    linenumber := linenumber - 1
    TEST y = 1 THEN
    $(
      down()
      write(textptr,1,1)
    $)
    ELSE y := y - 1
  $)
$)


LET upcurs(line) BE

$(
  linsert(line,textptr)
  moveup()
$)


LET movedown() BE

$(
  LET optr = textptr
  textptr := forward(textptr)
  UNLESS textptr = optr THEN
  $(
    linenumber := linenumber + 1
    TEST y = scrheight-1 THEN
    $(
      up()
      write(textptr,1,scrheight-1)
    $)
    ELSE y := y + 1
  $)
$)



LET downcurs(line) BE

$(
  linsert(line,textptr)
  movedown()
$)



LET supcurs(line) BE

$(
  linsert(line,textptr)
  FOR a = 1 TO scrheight-4 DO
  $(
    IF textptr = 0 THEN BREAK
    moveup()
  $)
$)

LET sdowncurs(line) BE

$(
  linsert(line,textptr)
  FOR a = 1 TO scrheight-4 DO
  $(
    LET optr = textptr
    movedown()
    IF optr = textptr THEN BREAK
  $)
$)



LET top(line) BE

$(
  linsert(line,textptr)
  textptr, x, y, linenumber := 0, 1, 1, 1
  reconstruct(textptr)
$)


LET bottom(line) BE

$(
  LET optr = 0
  linsert(line,textptr)
  textptr, x, y, linenumber := 0, 1, 1, 0
  $(
    optr := textptr
    textptr := forward(textptr)
    y := y + 1
    linenumber := linenumber + 1
  $) REPEATUNTIL optr = textptr
  IF y > scrheight-1 THEN y := scrheight-1
  reconstruct(textptr)
$)


/* All lines end in 13 */
/* The edit buffer is held in unpacked format. The whole text is stored in
   packed format */

LET start() BE

$(
  LET filebuff = VEC 81
  LET previous = VEC maxscrheight-1
  LET text = VEC maxchr/2+1
  LET inbuff = VEC 81
  LET error = VEC 4
  LET copyptr, lastkey, newscreen = 0, 0, TRUE
  ver := version()
  scrheight := ver=4 -> 31, ver=3 -> 24, 25
  textptr, textend, textstart, errvec := 0, 0, text, error
  prev, file := previous, filebuff
  cls()
  textstart%0 := 13
  $(
    level(errvec)
    initbuff(inbuff,textptr)
    IF newscreen THEN screen(textptr,y)
    errlab:
    IF buffprint THEN
    $(
      tab(1,y)
      FOR a = 1 TO inbuff!0-1 DO wrch(inbuff!a) ; spaces(80-inbuff!0)
      buffprint := FALSE
    $)
    lastkey := buffer(inbuff)
    newscreen := FALSE
    SWITCHON lastkey INTO
    $(
      CASE 127: newscreen := TRUE ; deletel(inbuff) ; ENDCASE
      CASE 13: newscreen := TRUE ; addl(inbuff) ; ENDCASE
      CASE cursup: CASE scursup: upcurs(inbuff) ; ENDCASE
      CASE cursdown: CASE scursdown: downcurs(inbuff) ; ENDCASE
      CASE ccursup: supcurs(inbuff) ; ENDCASE
      CASE ccursdown: sdowncurs(inbuff) ; ENDCASE
      CASE copensq: top(inbuff) ; ENDCASE
      CASE cclosesq: bottom(inbuff) ; ENDCASE
      CASE escape: CASE stop: menu(inbuff) ; ENDCASE
    $)
  $) REPEAT
$)
.
