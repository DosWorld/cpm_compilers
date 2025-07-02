Pro Pascal Version zz 2.18  -  extra remarks
--------------------------------------------


New facilities in version 2.182 for ROM applications
----------------------------------------------------

In CP/M several addresses are defined, relative to a base point  which
is in most cases zero.  Besides the BDOS entry point, the  chief  ones
are the warm boot entry (base+0), the default FCB  (base+5C)  and  the
default "DMA" address (base+80).  To  permit  these  addresses  to  be
relocated from page zero when the latter is in ROM, the library coding
has been modified to make dependencies indirect.   There  is  code  in
modules H1LIB and H2LIB - for which source is supplied -  to  set  the
normal default values, and this may be altered if required.

1. Warm boot entry:  a jump instruction in H2LIB has the  label  $BOOT
and by default jumps to the base address.

2. BDOS entry:  calls on BDOS are routed through $BDOS in H2LIB as  in
previous versions.

3. Default FCB and DMA addresses:  the external  variables  $DFCB  and
$DDMA in H1LIB are defaulted to base+5CH and base+80H.  The  remainder
of the library assumes these are RAM  areas  of  length  24H  and  80H
respectively; there is no assumption that they are adjacent.  The  FCB
space is used for decoding file or device names (in ASSIGN  etc.)  and
the DMA address is defaulted for use by CP/M and by the routine  which
implements FSTAT.  The CHAIN  procedure  assumes  that  the  transient
program area follows the DMA space.


Difference from Version zz 2.17
-------------------------------

The interface to the "dispose" routine is different in  zz  2.18  from
earlier versions.  This means that any user programs  or  pre-compiled
library modules which use dispose must be  recompiled  with  the  2.18
compiler if they are to be linked with the 2.18 PASLIB.REL.



Additional sample programs
--------------------------

This disc includes four source (.PAS) files containing  sample  Pascal
programs not listed in the manual.


1.   EASTER.PAS

As supplied, this program calculates and prints the date of Easter for
the years 1976 to 2000.  The  procedure  "dateofeaster"  contains  the
algorithm for the calculation, and  the  main  program  calls  it  and
displays the  result.   The  range  of  dates  is  determined  by  the
constants fyr and lyr at the head of the program.


2.   PRIMES.PAS

This program derives the prime numbers in  a  given  range  using  the
"sieve of Eratosthenes".  The statement in line 41 which displays  the
prime values may be commented out (by placing  comment  brackets  {  }
around it) to allow timing of the calculation.


3.   LIFE.PAS

A program to play the "game of life".  There are two points to note.

   (1). It contains a reference to the function RAND, which is in  the
   standard library but has to be declared before  use  (see   section
   9.3 in Part II of the manual).  As a consequence,  the  compilation
   does not continue automatically into the link phase, and the latter
   must be invoked separately by e.g:
       PROLINK B:LIFE,PASLIB/S

   (2). More significantly, the program makes  use  of  direct  screen
   addressing for the display.  As coded, the operations are  for  the
   Lear Siegler ADM 3A, and the procedures  "print"  at  line  49  and
   "clearscreen" at line 59 may have to be amended for other devices.


4.   FIGURES.PAS

This is a short program to illustrate  random-access  reading  from  a
file.  A workfile is written with the values 'zero' to  'nineteen'  in
character form in the appropriate records;  the file  is  then  reset,
and is accessed to retrieve the records  randomly  on  request.   Exit
from the program is by entering a negative value.



Security of discs
_________________

The Pro Pascal software is normally supplied on write-protected discs.
Do not write-permit the master copy or execute the compiler  from  it.
Copy the files from the supplied disc(s) onto one of your  own  discs.
You may then verify that the working copy is correct (see below),  and
go on to compile, link, and run your own programs as described in Part
III of the User Manual.



Checking validity of files
__________________________

The programs PROPAS, PROLINK and PROLIB (files PROPAS.COM, PROLINK.COM
and  PROLIB.COM)  incorporate  sumchecks.   If  through  transcription
errors or other causes the files are altered, the message "Bad copy of
program" is displayed when the program is invoked.

The program PCHECK is supplied to guard against copying errors in  the
other files.   It  tests  the  files  on  the  default  drive  against
information recorded within itself.  When the Pro Pascal  software  is
accommodated on one disc, simply place the copy to be  tested  on  the
default drive and invoke PCHECK.  If the software is distributed  over
two discs, they are tested separately, by (for example):

         >a:
        A>pcheck              {tests the files on A}
            .
            .                 {output from pcheck program}
            .
        A>b:
        B>a:pcheck            {tests the files on B}
            .
            .                 {output from program}
            .
        B>

      {tests the files on B}
            .
            .          