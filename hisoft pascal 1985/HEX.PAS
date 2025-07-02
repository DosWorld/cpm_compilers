FUNCTION upper(c:CHAR):CHAR;
BEGIN
 IF c IN ['a'..'z'] THEN c:=CHR(ORD(c)-ORD('a')+ORD('A'));
 upper:=c
END;

PROCEDURE DUMP(VAR f:TEXT;start,finish:INTEGER);
{writes a hexadecimal & ASCII dump of memory
 from start to finish to file f}
CONST bytesperline=16;
         {for screens of width of 72 or more}
VAR i,cur:INTEGER;
    ch:CHAR;
BEGIN
 cur:=start;
 WHILE cur<finish DO
  BEGIN
   WRITE(f,cur:4:H);
   FOR i:=cur TO cur+bytesperline-1 DO
      WRITE(f,' ',ORD(PEEK(i,CHAR)):2:H);
   WRITE(f,' ':3);
   FOR i:=cur TO cur+bytesperline-1 DO
    BEGIN 
     ch:=PEEK(i,CHAR);
     IF ch>CHR(127) THEN ch:=CHR(ORD(ch)-128);
     IF ch<' ' THEN ch:='.';
     WRITE(f,ch)
    END;
   cur:=cur+bytesperline;
   WRITELN(f)
  END
END;

FUNCTION READHEX(VAR f:TEXT):INTEGER;
{Reads a hex number from the file f}
VAR res,i:INTEGER;
BEGIN
 res:=0;i:=0;
 WHILE NOT(f^ IN ['0'..'9','A'..'F']) DO GET(f);
 REPEAT
  res:=res*16+i;
  IF f^ IN ['0'..'9'] THEN i:=ORD(f^)-ORD('0') ELSE
  IF f^ IN ['A'..'F'] THEN i:=ORD(f^)-ORD('A')+10 ELSE
  IF f^ IN ['a'..'f'] THEN i:=ORD(f^)-ORD('a')+10 ELSE
  i:=-1;
  IF i<>-1 THEN GET(f)
UNTIL i=-1;
 READHEX:=res
END;
E
  IF f^ IN ['a'..'f'] THEN i:=ORD(f^)-ORD('a')+10 ELSE
  i:=-1;
  IF i<>-1 THE