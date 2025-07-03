GET "COMPHDR"

STATIC $( A=?; B=?; C=? $)

LET START() BE
$( LET I = ?
   IF INPUT() = CON THEN SELECTINPUT(FINDINPUT("BCPL.OUT"))
   BINARYINPUT(TRUE)
   $( IF INTKEY() FINISH
      I := RDCH()
      TEST I=S.SECTION THEN
         $( LET CH = RDCH()
            WRITES("Section ")
            UNTIL CH = 0 DO
            $( WRCH(CH)
               CH := RDCH()
            $)
         $)
      ELSE TEST I=S.NEEDS THEN
         $( LET CH = RDCH()
            WRITES("Needs ")
            UNLESS CH = 0 DO
               $( WRCH(CH + ('A'-1))
                  WRCH(':')
               $)
            FOR K = 1 TO 11 DO
               $( CH := RDCH()
                  UNLESS CH = ' ' DO WRCH(CH)
                  IF K = 8 WRCH('.')
               $)
         $)
      ELSE TEST I=S.GLOBSYM | I=S.LABSYM THEN
         $( LET CH=?
            RDW()
            CH := RDCH()
            WRITES(I=S.GLOBSYM -> "Global ", "Label ")
            WRITEF("%N = ", A)
            UNTIL CH = 0 DO
            $( WRCH(CH)
               CH := RDCH()
            $)
         $)
      ELSE    
         $( LET S = STR(I)
            WRITEF(S, A, B, C)
         $)
      NEWLINE()
   $) REPEATUNTIL (I = S.ENDFILE) | (I = ENDSTREAMCH)
$)

AND RDW() BE
$( LET L = RDCH()
   LET H = RDCH()
   A := L | (H << 8)
$)

AND RDB() BE 
$( A := RDCH() $)

AND RDE() BE
$( B := RDCH()
   A := "+"
   IF B > 127 THEN 
     $( A := "-"
        B := 256 - B 
     $)
$)
 
AND RDB1() BE
$( C := RDCH() $)

AND STR(I) = VALOF SWITCHON I INTO
$( CASE S.ENDFILE:                       RESULTIS "ENDFILE"
   CASE S.STARTFILE:                     RESULTIS "STARTFILE"
   CASE S.STARTSECT:                     RESULTIS "STARTSECTION"
   CASE S.LABDEF:        RDW();          RESULTIS "LABEL %N"    
   CASE S.NEWLAB:        RDW();          RESULTIS "NEWLAB %N"
   CASE S.GORG:          RDW();          RESULTIS "SETGLOBAL %N"
   CASE S.WALIGN:                        RESULTIS "ALIGN"
   CASE S.SUBHB:                         RESULTIS "SBC HL,BC"
   CASE S.INCIX:                         RESULTIS "INC IX"
   CASE S.LIMB:	         RDB();          RESULTIS "LD B,0%X2H"
   CASE S.LIMDE:	 RDW();          RESULTIS "LD DE,0%X4H"
   CASE S.LIMBC:	 RDW();          RESULTIS "LD BC,0%X4H"
   CASE S.LIMHL:	 RDW();          RESULTIS "LD HL,0%X4H"
   CASE S.RTAP:	                         RESULTIS "RST 008H [RTAP]"
   CASE S.LIMIY:	 RDW()           RESULTIS "LD IY,0%X4H"
   CASE S.GOTO:	                         RESULTIS "JP GOTO"
   CASE S.ADDHH:                         RESULTIS "ADD HL,HL"
   CASE S.PLUS:	                         RESULTIS "ADD HL,DE"
   CASE S.DECIX:	                 RESULTIS "DEC IX"   
   CASE S.RET:	                         RESULTIS "RET"      
   CASE S.FINISH:	                 RESULTIS "JP FINISH"
   CASE S.ADDIYSP:	                 RESULTIS "ADD IY,SP"
   CASE S.ORA:	                         RESULTIS "OR A" 
   CASE S.ORH:	                         RESULTIS "OR H" 
   CASE S.MINUS:	                 RESULTIS "SBC HL,DE" 
   CASE S.LDAL:                          RESULTIS "LD A,L"    
   CASE S.JPZ:            RDW();         RESULTIS "JP Z,L%N"  
   CASE S.JPNZ:	          RDW();         RESULTIS "JP NZ,L%N"         
   CASE S.JPC:	          RDW();         RESULTIS "JP C,L%N" 
   CASE S.JPNC:	          RDW();         RESULTIS "JP NC,L%N"
   CASE S.JPPO:	          RDW();         RESULTIS "JP PO,L%N"
   CASE S.JPPE:	          RDW();         RESULTIS "JP PE,L%N"
   CASE S.SWITCHON:                      RESULTIS "CALL SWITCH"
   CASE S.DB:             RDB();         RESULTIS "DB 0%X2H" 
   CASE S.DW:	          RDW();         RESULTIS "DW 0%X4H" 
   CASE S.DWLAB:	  RDW();         RESULTIS "DW L%N"   
   CASE S.PUSHHL:	                 RESULTIS "PUSH HL"  
   CASE S.POPHL:	                 RESULTIS "POP HL"   
   CASE S.PUSHDE:                        RESULTIS "PUSH DE"  
   CASE S.POPDE:	                 RESULTIS "POP DE"   
   CASE S.NEG:	                         RESULTIS "CALL NEG" 
   CASE S.ABS:	                         RESULTIS "CALL ABS" 
   CASE S.NOT:	                         RESULTIS "CALL NOT" 
   CASE S.RV:	                         RESULTIS "RST 018H [RV]"  
   CASE S.JPLAB:          RDW();         RESULTIS "JP L%N"   
   CASE S.LDLIX:	  RDE();         RESULTIS "LD L,(IX%S%N)"
   CASE S.STLIX:	  RDE();         RESULTIS "LD (IX%S%N),L"
   CASE S.LDHIX:	  RDE();         RESULTIS "LD H,(IX%S%N)"
   CASE S.STHIX:	  RDE();         RESULTIS "LD (IX%S%N),H"
   CASE S.LDEIX:	  RDE();         RESULTIS "LD E,(IX%S%N)"
   CASE S.LDDIX:	  RDE();         RESULTIS "LD D,(IX%S%N)"
   CASE S.LDHLGLB:        RDW();         RESULTIS "LD HL,(GLOB %N)"
   CASE S.STHLGLB:        RDW();         RESULTIS "LD (GLOB %N),HL"
   CASE S.LDDEGLB:        RDW();         RESULTIS "LD DE,(GLOB %N)"
   CASE S.LDHLLAB:        RDW();         RESULTIS "LD HL,(L%N)"
   CASE S.STHLLAB:        RDW();         RESULTIS "LD (L%N),HL"
   CASE S.LDDELAB:        RDW();         RESULTIS "LD DE,(L%N)"
   CASE S.BYTEAP:                        RESULTIS "CALL GETBYTE"
   CASE S.DIV:                           RESULTIS "CALL DIV"
   CASE S.REM:	                         RESULTIS "CALL REM"
   CASE S.MULT:	                         RESULTIS "CALL MULT"
   CASE S.LS:                            RESULTIS "CALL LESS"
   CASE S.GR:	                         RESULTIS "CALL GREATER"
   CASE S.LE:	                         RESULTIS "CALL LESSEQ" 
   CASE S.GE:	                         RESULTIS "CALL GREATEQ"
   CASE S.EQ:	                         RESULTIS "CALL EQUALS" 
   CASE S.NE:	                         RESULTIS "CALL NEQ"    
   CASE S.LSHIFT:                        RESULTIS "CALL LSHIFT" 
   CASE S.RSHIFT:                        RESULTIS "CALL RSHIFT" 
   CASE S.LOGAND:	                 RESULTIS "CALL LOGAND" 
   CASE S.LOGOR:                         RESULTIS "CALL LOGOR"  
   CASE S.EQV:	                         RESULTIS "CALL EQV"    
   CASE S.NEQV:	                         RESULTIS "CALL NEQV"   
   CASE S.LOCADDR:                       RESULTIS "CALL LOCADDR"
   CASE S.GLBADDR:        RDW();         RESULTIS "LD HL,GLOB %N"
   CASE S.LABADDR:        RDW();         RESULTIS "LD HL,L%N/2"
   CASE S.LABDEADR:       RDW();         RESULTIS "LD DE,L%N/2"
   CASE S.EXCHG:	                 RESULTIS "EX DE,HL"   
   CASE S.STBYTE:	                 RESULTIS "LD (HL),E"  
   CASE S.STIND:	                 RESULTIS "RST 020H [STIND]" 
   CASE S.INCHL:                         RESULTIS "INC HL"
   CASE S.DECHL:	                 RESULTIS "DEC HL"
   CASE S.INCDE:	                 RESULTIS "INC DE"
   CASE S.DECDE:                         RESULTIS "DEC DE"
   CASE S.SUBHH:                         RESULTIS "SBC HL,HL"
   CASE S.JPP:	          RDW();         RESULTIS "JP P,L%N"
   CASE S.JPM:	          RDW();         RESULTIS "JP M,L%N"
   CASE S.LDSPIY:                        RESULTIS "LD SP,IY"
   CASE S.SRTAP:                         RESULTIS "RST 010H [SRTAP]"
   CASE S.TWODIV:                        RESULTIS "CALL TWODIV"
   CASE S.ADDIXBC:                       RESULTIS "ADD IX,BC"
   CASE S.LDAGLB:         RDW();         RESULTIS "LD A,(GLOB %N)"
   CASE S.LDALAB:         RDW();         RESULTIS "LD A,(L%N)"
   CASE S.LIMA:           RDB();         RESULTIS "LD A,0%X2H"
   CASE S.LDAIX:          RDE();         RESULTIS "LD A,(IX%S%N)"
   CASE S.STBYTEA:                       RESULTIS "LD (HL),A"
   CASE S.STBYTIM:        RDB();         RESULTIS "LD (HL),0%X2H"
   CASE S.STIXIM:         RDE(); RDB1(); RESULTIS "LD (IX%S%N),0%X2H"
   CASE S.LDBYTE:                        RESULTIS "LD L,(HL)"
   CASE S.LDHIM:          RDB();         RESULTIS "LD H,0%X2H"
   CASE S.INCLOC:         RDE();         RESULTIS "INC (IX%S%N)"
   CASE S.SKIP:                          RESULTIS "JR NZ,$+5"
   CASE S.SKIPZ:                         RESULTIS "JR Z,$+3"
   CASE S.VEC:                           RESULTIS "CALL VECTOR"
   CASE S.OFLV:                          RESULTIS "CALL OFLV"
   CASE S.OFRV:                          RESULTIS "CALL OFRV"
   CASE S.ADDHB:                         RESULTIS "ADD HL,BC"
   CASE S.DECA:                          RESULTIS "DEC A"
   CASE S.ORIX:           RDE();         RESULTIS "OR (IX%S%N)"
   CASE S.SUBA:           RDB();         RESULTIS "SUB 0%X2H"
   CASE S.BIT:     RDB(); B := (A>>3)&7
                   A := A>>6
                   TEST A=1 THEN A:="BIT"
              ELSE TEST A=2 THEN A:="RES"
              ELSE               A:="SET"
                                         RESULTIS "%S %N,(HL)"
   DEFAULT:               A := I;        RESULTIS "----UNKNOWN----(%N)"
$) 
  
