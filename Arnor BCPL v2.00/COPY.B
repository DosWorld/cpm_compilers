/* This is a copy routine. Last modified 05/11/1986 */

option b-

/* Include the library */

GET "clibhdr"

LET start() BE

$(
  LET inname = VEC 20
  LET inbuff = VEC 82
  LET outname = VEC 20
  LET outbuff = VEC 82
  LET c = 0
  writes("Input file name:  ")
  reads(inname)
  IF inname%0 = 0 THEN FINISH
  newline()
  writes("Output file name: ")
  reads(outname)
  IF outname%0 = 0 THEN FINISH
  TEST findinput(inname, inbuff) THEN
  $(
    selectinput(inbuff)
    TEST findoutput(outname, outbuff) THEN
    $(
      selectoutput(outbuff)
      $(
        c := rdch()
        UNLESS c=endstreamch DO wrch(c)
      $)
      REPEATUNTIL c = endstreamch
      endwrite()
    $)
    ELSE writes("Can't open output file")
    endread()
  $)
  ELSE writes("Can't open input file")
$)
.

