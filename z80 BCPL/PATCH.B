GET "LIBHDR"
GET "RANDHDR"

LET START() BE
$( LET BUFF = VEC BLOCKSIZE
   LET FCB = ?
   WRITES("BCPL Loader patch program.*n*n")

   FCB :=  UPDATEBLOCKFILE("LOADB.COM")
   IF ~FCB  DO
      $( WRITES("Couldn't open LOADB.COM*n*n")
         FINISH
      $)

   READBLOCK(FCB, BUFF, 0)

   WRITEF("Current size of global vector is %n words.*n*
          *Input new size (or <cr> to leave):", BUFF!2)
   IF RDCH() NE '*N' THEN
     $( UNRDCH()
        BUFF!2 := READN()
     $)

   WRITEF("Current stack size is %n words.*n*
          *Input new size (or <cr>): ", BUFF!3)
   IF RDCH() NE '*N' THEN
     $( UNRDCH()
        BUFF!3 := READN()
     $)
   
   WRITEBLOCK(FCB, BUFF, 0)

   TEST CLOSEBLOCKFILE(FCB) THEN  WRITES("*nDone.*n*n")
                            ELSE  WRITES("*nError closing file.*n*n")

$)
