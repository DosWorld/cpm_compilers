;****************************************
;					*
;   Runtime Library for Q/C Compiler	*
;	      Version 1.0		*
;					*
;		08/14/81		*
;****************************************
;
;Fetch a single byte from the address in HL and sign extend
;	into HL
ccgc:	MOV	A,M
;Put the accum into HL and sign extend thru H
ccsxt:	MOV	L,A
	RLC
	SBB	A
	MOV	H,A
	RET
;Fetch a full 16 bit integer from the address in HL into HL
ccg:	MOV	A,M
	INX	H
	MOV	H,M
	MOV	L,A
	RET
;Store a 16 bit integer in HL at the address on top of the stack
ccp:	POP	B
	POP	D
	PUSH	B
	MOV	A,L
	STAX	D
	INX	D
	MOV	A,H
	STAX	D
	RET
;Inclusive OR HL and DE into HL
ccpo:	POP	B
	POP	D
	PUSH	B
cco:	MOV	A,L
	ORA	E
	MOV	L,A
	MOV	A,H
	ORA	D
	MOV	H,A
	RET
;Exclusive OR HL and DE into HL
ccpx:	POP	B
	POP	D
	PUSH	B
ccx:	MOV	A,L
	XRA	E
	MOV	L,A
	MOV	A,H
	XRA	D
	MOV	H,A
	RET
;AND HL and DE into HL
ccpa:	POP	B
	POP	D
	PUSH	B
cca:	MOV	A,L
	ANA	E
	MOV	L,A
	MOV	A,H
	ANA	D
	MOV	H,A
	RET
;
;All of the following compare routines return with:
;	if condition = TRUE	HL = 1 and Z flag is reset
;	if condition = FALSE	HL = 0 and Z flag is set
;
;Test DE == HL
ccpe:	POP	B
	POP	D
	PUSH	B
cce:	CALL	ccucmp
	JNZ	ccfalse
	ORA	L	;reset Z to signal TRUE
	RET
;Test DE != HL
ccpne:	POP	B
	POP	D
	PUSH	B
ccne:	CALL	ccucmp
	RNZ		;Z reset means DE != HL
	DCR	L	;set HL = 0
	RET
;Test DE >  HL (signed)
ccpgt:	POP	B
	POP	D
	PUSH	B
ccgt:	XCHG
	JMP	cclt
;Test DE < HL (signed)
ccplt:	POP	B
	POP	D
	PUSH	B
cclt:	CALL	cccmp
	JNC	ccfalse ;carry reset means DE >= HL
	ORA	L	;reset Z to signal TRUE
	RET
;Test DE <= HL (signed)
ccple:	POP	B
	POP	D
	PUSH	B
ccle:	XCHG
	JMP	ccge
;Test DE >= HL (signed)
ccpge:	POP	B
	POP	D
	PUSH	B
ccge:	CALL	cccmp
	JC	ccfalse ;carry set means DE < HL
	ORA	L	;reset Z to signal TRUE
	RET
;Test if DE > HL (unsigned)
ccpugt: POP	B
	POP	D
	PUSH	B
ccugt:	XCHG
	JMP	ccult
;Test if DE < HL (unsigned)
ccpult: POP	B
	POP	D
	PUSH	B
ccult:	CALL	ccucmp
	JNC	ccfalse ;carry reset means DC >= HL
	ORA	L	;reset Z to signal TRUE
	RET
;Test if DE <= HL (unsigned)
ccpule: POP	B
	POP	D
	PUSH	B
ccule:	XCHG
	JMP	ccuge
;Test if DE >= HL (unsigned)
ccpuge: POP	B
	POP	D
	PUSH	B
ccuge:	CALL	ccucmp
	JC	ccfalse ;carry set means DE < HL
	ORA	L
	RET
;All comparison routines arrive here if FALSE
ccfalse: DCR	L	;set HL = 0 and set Z flag
	RET
;
;Common routine to compare DE and HL.
;
;For a signed compare the positive and negative numbers
;are first mapped into unsigned numbers by doing an
;exclusive or of the sign bit with one. This allows us
;to do an unsigned compare and still get the correct result.
;The mapping looks like this:
;
;	-32768 (0x8000) --> 0	  (0x0000)
;	-32767 (0x8001) --> 1	  (0x0001)
;	 .....
;	    -1 (0xFFFF) --> 32767 (0x7FFF)
;	     0 (0x0000) --> 32768 (0x8000)
;	     1 (0x0001) --> 32769 (0x8001)
;	 .....
;	 32766 (0x7FFE) --> 65534 (0xFFFE)
;	 32767 (0x7FFF) --> 65535 (0xFFFF)
;
;The comparison sets the following conditions:
;	Carry reflects the ordering (set means DE < HL)
;	Zero set means equality
;
cccmp:	MOV	A,D	;map signed numbers into unsigned
	XRI	80H
	MOV	D,A
	MOV	A,H
	XRI	80H
	MOV	H,A
ccucmp: MOV	A,D	;do unsigned compare
	CMP	H
	JNZ	ccucm1
	MOV	A,E
	CMP	L
ccucm1: LXI	H,1	;preset TRUE condition
	RET
;
;Shift DE arithmetically right by HL and return in HL
ccpasr: POP	B
	POP	D
	PUSH	B
ccasr:	XCHG
ccasr1: DCR	E
	RM
	MOV	A,H
	RAL
	MOV	A,H
	RAR
	MOV	H,A
	MOV	A,L
	RAR
	MOV	L,A
	JMP	ccasr1
;Shift DE arithmetically left by HL and return in HL
ccpasl: POP	B
	POP	D
	PUSH	B
ccasl:	XCHG
ccasl1: DCR	E
	RM
	DAD	H
	JMP	ccasl1
;Subtract HL from DE and return in HL
ccps:	POP	B
	POP	D
	PUSH	B
ccs:	MOV	A,E
	SUB	L
	MOV	L,A
	MOV	A,D
	SBB	H
	MOV	H,A
	RET
;Form the two's complement of HL
ccneg:	CALL	cccom
	INX	H
	RET
;Form the one's complement of HL
cccom:	MOV	A,H
	CMA
	MOV	H,A
	MOV	A,L
	CMA
	MOV	L,A
	RET
;Form logical not of HL
ccn:	MOV	A,H
	ORA	L
	JZ	ccnot1
	XRA	A	;set Z to indicate FALSE
	MOV	H,A	;set HL=0 to indicate FALSE
	MOV	L,A
	RET
ccnot1: INR	L	;set HL=1 and reset Z to indicate TRUE
	RET
;Multiply DE by HL and return in HL
ccpmult: POP	 B
	POP	D
	PUSH	B
ccmult: MOV	B,H
	MOV	C,L
	LXI	H,0
ccmul1: MOV	A,C
	RRC
	JNC	ccmul2
	DAD	D
ccmul2: XRA	A
	MOV	A,B
	RAR
	MOV	B,A
	MOV	A,C
	RAR
	MOV	C,A
	ORA	B
	RZ
	XRA	A
	MOV	A,E
	RAL
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	ORA	E
	RZ
	JMP	ccmul1
;Divide DE by HL and return quotient in HL, remainder in DE
ccpdiv: POP	B
	POP	D
	PUSH	B
ccdiv:	MOV	A,H	;check for division by zero
	ORA	L
	JNZ	ccdiv0
	MOV	E,L	;force remainder to zero
	MOV	D,H
	RET
ccdiv0: MOV	B,H
	MOV	C,L
	MOV	A,D
	XRA	B
	PUSH	PSW
	MOV	A,D
	ORA	A
	CM	ccdeneg
	MOV	A,B
	ORA	A
	CM	ccbcneg
	MVI	A,16
	PUSH	PSW
	XCHG
	LXI	D,0
ccdiv1: DAD	H
	CALL	ccrdel
	JZ	ccdiv2
	CALL	cccmpbcde
	JM	ccdiv2
	MOV	A,L
	ORI	1
	MOV	L,A
	MOV	A,E
	SUB	C
	MOV	E,A
	MOV	A,D
	SBB	B
	MOV	D,A
ccdiv2: POP	PSW
	DCR	A
	JZ	ccdiv3
	PUSH	PSW
	JMP	ccdiv1
ccdiv3: POP	PSW
	RP
	CALL	ccdeneg
	XCHG
	CALL	ccdeneg
	XCHG
	RET
;Negate the integer in DE (internal routine for ccdiv)
ccdeneg: MOV	A,D
	CMA
	MOV	D,A
	MOV	A,E
	CMA
	MOV	E,A
	INX	D
	RET
;Negate the integer in BC (internal routine for ccdiv)
ccbcneg: MOV	A,B
	CMA
	MOV	B,A
	MOV	A,C
	CMA
	MOV	C,A
	INX	B
	RET
;Rotate DE left one bit (internal routine for ccdiv)
ccrdel: MOV	A,E
	RAL
	MOV	E,A
	MOV	A,D
	RAL
	MOV	D,A
	ORA	E
	RET
;Compare BC to DE (internal routine for ccdiv)
cccmpbcde: MOV	A,E
	SUB	C
	MOV	A,D
	SBB	B
	RET
;Select the appropriate case for a switch statement
ccsw:	XCHG		;save val of expression in DE
	POP	H	;get address of arg list
	MOV	C,M	;load no. of cases in C
	INX	H	;ignore high order byte of count
ccsw1:	DCR	C	;count down cases
	JM	ccsw3	;no more cases -- goto default
	INX	H	;val of expr == case val?
	MOV	A,M
	CMP	E
	INX	H
	JNZ	ccsw2	;no, goto next case
	MOV	A,M
	CMP	D
	JZ	ccsw3	;yes, goto matching label
ccsw2:	INX	H	;skip label for this case
	INX	H
	JMP	ccsw1	;go try next case
ccsw3:	INX	H	;get address of this case label
	MOV	A,M
	INX	H
	MOV	H,M
	MOV	L,A
	PCHL		;go there
;
;Function to make any CP/M system call
;bdos(c, de)
;char c; /* c -> C */
;int de; /* de -> DE */
bdos:	POP	H	;unstack return address
	POP	D	;load DE
	POP	B	;load BC
	PUSH	B	;put
	PUSH	D	; args and
	PUSH	H	; return address back on stack
	JMP	5H
;
;Define special storage area for C register variables
;
ccr1:	DS	2
ccr2:	DS	2
ccr3:	DS	2
ccr4:	DS	2
ccr5:	DS	2
