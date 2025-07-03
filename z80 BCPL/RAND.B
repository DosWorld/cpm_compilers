// Random file IO package for CPM BCPL

section "RANDOMIO"

get "libhdr"
get "randhdr"

manifest // bdos functions
$( del=19; open=15; close=16; make=22
readrand=33; writerand=34; filesize=35; setdma=26 $)

manifest // fcb offsets
$( fcbsize=18
   ex=12; s1=13; s2=14; rc=15; cr=32; r0=33; r1=34; r2=35 $)

let createblockfile(file) = valof
$( let fcb = getvec(fcbsize)
   if fcb=0 resultis 0
   parse(file, fcb) // build the fcb
   fcb%ex := 0
   fcb%s1 := 0
   fcb%s2 := 0
   fcb%rc := 0
   fcb%cr := 0
   bdos(del, fcb*bytesperword) // delete possible pre-existing file
   test (#xff & bdos(make, fcb*bytesperword)) = #xff // and make it
         then $( freevec(fcb)     // failed
                 resultis 0
              $)
         else resultis fcb
$)

let updateblockfile(file) = valof
$( let fcb = getvec(fcbsize)
   if fcb=0 resultis 0
   parse(file, fcb) // build the fcb
   fcb%ex := 0
   fcb%s1 := 0
   fcb%s2 := 0
   fcb%rc := 0
   fcb%cr := 0
   test (#xff & bdos(open, fcb*bytesperword)) = #xff // and open it
         then $( freevec(fcb)
                 resultis 0       // failed
              $)
         else resultis fcb
$)

let closeblockfile(fcb) = valof
$( let r = (#xff & bdos(close, fcb*bytesperword)) ~= #xff
   freevec(fcb)
   resultis r
$)

let readblock(fcb, buff, rec) = valof
$( bdos(setdma, buff*bytesperword)
   fcb%r2 := 0
   fcb%r1 := rec>>8
   fcb%r0 := rec
   resultis #xff & bdos(readrand, fcb*bytesperword)
$)

let writeblock(fcb, buff, rec) = valof
$( bdos(setdma, buff*bytesperword)
   fcb%r2 := 0
   fcb%r1 := rec>>8
   fcb%r0 := rec
   resultis #xff & bdos(writerand, fcb*bytesperword)
$)

let blockfilesize(fcb) = valof
$( bdos(filesize, fcb*bytesperword)
   resultis (fcb%r0)+((fcb%r1)<<8)
$)
