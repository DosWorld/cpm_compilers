/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 5)			*/
/*							*/
/*     Copyright (c) 1981 Quality Computer Systems	*/
/*							*/
/*			10/30/81			*/
/********************************************************/

/* Note: Uncomment the following lines if you are using M80
#include "qstdio.h"
#include "cstddef.h"
#include "cglbdecl.c"
*/

/*					*/
/*	This is the code generation	*/
/*	section of the compiler 	*/
/*					*/

/* Begin a comment line for the assembler */
comment()
	{
	if (midline)
		nl();
	outbyte(';');
	}
/* Print all assembler info before any code is generated */
header()
	{
	outstr(";Quality Computer Systems C Compiler\n");
	}
/* Generate code to be done before main() */
shell() {
	if(codeflag != 'm') /* no ORG for M80 code */
		ol("ORG\t100H");
	ol("LHLD\t6H");
	ol("SPHL");		/* start stack just below CP/M BDOS */
	if(codeflag == 'm') {	/* get addr of top of program */
		ol("LHLD\t$MEMRY");
		ol("SHLD\tccfree");
		}
	callib("shell",NOPOP);
	if(codeflag == 'm') {	/* for M80 define top of prog addr */
		outstr("$MEMRY:: DW\t0\n");
		outstr("ccfree:: DW\t0\n");
		}
	}
/* Print any assembler stuff needed after all code */
trailer()
	{
	static int n, c, *fprunlib;
	if(codeflag == 'm') {		/* For M80 declare externals */
		for (cptr = STARTGLB; cptr < glbptr; cptr += SYMSIZ) {
			if (cptr[STORAGE] == CEXTERN) {
				ot("EXT");
				ol(cptr+NAME);
				}
			}
		for (n = 1; n <= MAXREG; ++n) { /* Declare registers */
			ot("EXT\t");
			prtreg(n);
			nl();
			}
		ot("END");		/* M80 requirement */
		if(mainflag)		/* tell M80 where to start */
			ot("103H");
		nl();
		}
	else if (mainflag) {	/* copy runtime lib for ASM/MAC */
		if ((fprunlib=fopen("crunlib.lib", "r")) == NULL &&
		    (fprunlib=fopen("a:crunlib.lib", "r")) == NULL)
			cantopen("CRUNLIB.LIB");
		while ((c = getc(fprunlib)) != EOF)
			outbyte(c);
		/* locate end of prog for lib funcs */
		outstr("ccfree:\tDW\t$+2\n");
		}
	}
/* Get the value of op in the primary register */
rvalp(op)
int op[];
	{
	if (op[0] && op[1]) {	/* prim reg has addr of op */
		indirect(op[1]);
		return;
		}
	if (pregflag)		/* does primary reg already have value */
		cpush();	/* if so, save it */
	else			/* else, remember that it does now */
		pregflag = TRUE;
	if (op[0] == 0) {	/* is it a constant? */
		pimmed();
		outdec(op[1]);
		nl();
		}
	else			/* it's a variable */
		load(op);
	}
/* Get the value of op in the primary register, */
/*	and save its address if it's on stack.	*/
rvalpsav(op)
int op[];
	{
	register char *sym;
	if(op[1]) {		/* is the addr of op already in prim reg? */
		cpush();	/* if so, save it */
		indirect(op[1]); /* load op */
		return;
		}
	if(pregflag)		/* does primary reg already have a value? */
		cpush();	/* if so, save it */
	else			/* if not, remember that it does now */
		pregflag = TRUE;
	sym = op[0];		/* point to symbol table entry */
	if(sym[STORAGE]==CAUTO) { /* can't use load because */
		getaddr(sym);		/* we must */
		cpush();		/* save address */
		indirect(op[1] =	/* load sym into preg & set type */
			(sym[IDENT] != POINTER) ? sym[TYPE]:
				(sym[TYPE] == CINT ? PTRTOINT: PTRTOCHAR));
		}
	else
		load(op);
	}
/* Get the value of op using the secondary register.	*/
/*	The argument commut tells whether op is the	*/
/*	right operand of a commutative or noncommutative*/
/*	operator. Return POP if the primary reigster	*/
/*	was used in evaluating op because the binary	*/
/*	operator will eventually have to pop the left	*/
/*	operand off the stack.				*/
rvals(op, commut)
int op[], commut;
	{
	if (op[0] == 0) {	/* is it a constant? */
		if (commut)
			simmed();
		else {		/* for noncommutative operators */
			swap(); /* put left operand in secondary reg */
			pimmed(); /* and load constant in primary reg */
			}
		outdec(op[1]);
		nl();
		}
	else {			/* it's a variable */
		if(op[1]) {	/* primary reg has address of op */
			indirect(op[1]); /* op[1] is TYPE */
			return POP;
			}
		else {		/* save prim reg & load op in prim reg */
			swap();
			load(op);
			}
		}
	return NOPOP;
	}
/* Load the variable pointed to by op into the primary reg */
load(op)
int op[];
	{
	register char *sym;
	sym = op[0];
	if (sym[IDENT] == FUNCTION || sym[IDENT] == ARRAY)
		getaddr(sym);		/* func & array refs by addr */
	else if (sym[STORAGE] == CAUTO) { /* is symbol on stack? */
		getaddr(sym);		/* load indirect thru preg...*/
		indirect(op[1] =	/* and set type */
			(sym[IDENT] != POINTER) ? sym[TYPE]:
				(sym[TYPE] == CINT ? PTRTOINT: PTRTOCHAR));
		}
	else	/* variable in fixed memory location */
		getmem(sym);
	}
/* Load the address of the specified symbol */
/*	into the primary register */
getaddr(sym)
char *sym;
	{
	pimmed();
	if (sym[STORAGE] == CAUTO) {
		outdec(getint(&sym[INFO]) - spcc);
		if(fullist) {	/* prt extra .asm info? */
			ot(";");
			outstr(sym+NAME);
			}
		nl();
		ol("DAD\tSP");
		}
	else
		prtsymname(sym);
	}
/* Load the specified object type indirect through the */
/*	primary register into the primary register */
indirect(typeobj)
char typeobj;
	{
	if (typeobj == CCHAR)
		callib("gc",NOPOP);
	else		/* all other types in Q/C V1.0 are 2 bytes */
		callib("g",NOPOP);
	}
/* Load the variable pointed to by sym into the */
/*	primary register */
getmem(sym)
char *sym;
	{
	if (sym[TYPE] == CCHAR && sym[IDENT] != POINTER) {
		ot("LDA\t");
		prtsymname(sym);
		callib("sxt",NOPOP);
		}
	else {
		ot("LHLD\t");
		prtsymname(sym);
		}
	}
/* Store the value pointed to by op */
store(op)
int op[];
	{
	if (op[1])
		putstk(op[1]);		/* store on stack */
	else
		putmem(op[0]);		/* store in memory */
	}
/* Store the specified object type in the primary register */
/*	at the address on the top of the stack */
putstk(typeobj)
char typeobj;
	{
	if (typeobj == CCHAR) {
		popsreg();
		ol("MOV\tA,L");
		ol("STAX\tD");
		}
	else		/* all other types in Q/C V1.0 are 2 bytes */
		callib("",POP);
	}
/* Store the primary register into the specified */
/*	memory location */
putmem(sym)
char *sym;
	{
	if (sym[TYPE] == CCHAR && sym[IDENT] != POINTER) {
		ol("MOV\tA,L");
		ot("STA\t");
		}
	else
		ot("SHLD\t");
	prtsymname(sym);
	}
/* Print the external or internal symbol name as appropriate */
prtsymname(sym)
char *sym;
	{
	int *label;
	label = sym + INFO;
	switch (sym[STORAGE]) {
	case CEXTDEF: case CEXTERN:
		outstr(sym + NAME);
		break;
	case CREG:
		prtreg(*label);
		goto prtname;
	case CSTATIC:
		printlabel(*label);
	prtname:
		if(fullist) {	/* prt extra .asm info? */
			ot(";");
			outstr(sym + NAME);
			}
		}
	nl();
	}
/* Get the value of register n into primary register */
getreg(n)
int n;
	{
	ot("LHLD\t");
	prtreg(n);
	nl();
	}
/* Put the value in primary register into register n */
putreg(n)
int n;
	{
	ot("SHLD\t");
	prtreg(n);
	nl();
	}
/* Print register n designation */
prtreg(n)
int n;
	{
	outstr("ccr");
	outdec(n);
	}
/* Swap the primary and secondary registers */
swap()
	{
	ol("XCHG");
	}
/* Print the partial instruction to get an immediate */
/*	value into the primary register */
pimmed()
	{ot("LXI\tH,");}
/* Print the partial instruction to get an immediate */
/*	value into the secondary register */
simmed()
	{ot("LXI\tD,");}
/* Push the primary register onto the stack */
cpush()
	{
	ol("PUSH\tH");
	spcc -= 2;
	}
/* Pop the top of the stack into the primary register */
poppreg()
	{
	ol("POP\tH");
	spcc += 2;
	}
/* Pop the top of the stack into the secondary register */
popsreg()
	{
	ol("POP\tD");
	spcc += 2;
	}
/* Swap the primary register and the top of the stack */
swapstk()
	{ol("XTHL");}
/* Call the specified library routine */
callib(sname,pop)
char *sname;
int pop;
	{
	ot("CALL\tcc");
	if(pop == POP) {
		outbyte('p');	/* call pop version */
		spcc += 2;	/* account for pop in lib routine */
		}
	outstr(sname);
	if(codeflag == 'm')	/* make external for M80 */
		outstr("##");
	nl();
	}
/* Call the specified subroutine name */
ccall(sname)
char *sname;
	{
	ot("CALL\t");
	outstr(sname);
	nl();
	}
/* Return from subroutine */
cret()
	{
	ol("RET");
	}
/* Perform subroutine call to value on top of stack */
callstk()
	{
	pimmed();
	outstr("$+5");
	nl();
	swapstk();
	ol("PCHL");
	spcc += 2;
	}
/* Jump to specified internal label number */
jump(label)
int label;
	{
	ot("JMP\t");
	printlabel(label);
	nl();
	}
/* Test the primary register and jump if true to label */
jumptrue(label)
int label;
	{
	if(!testdone) { /* did we just test (e.g. cceq)? */
		ol("MOV\tA,H");
		ol("ORA\tL");
		}
	ot("JNZ\t");
	printlabel(label);
	nl();
	}
/* Test the primary register and jump if false to label */
jumpfalse(label)
int label;
	{
	if(!testdone) {
		ol("MOV\tA,H");
		ol("ORA\tL");
		}
	ot("JZ\t");
	printlabel(label);
	nl();
	}
/* Set the primary register to 1 */
set1()
	{
	ol("LXI\tH,1");
	}
/* print pseudo-op to define a byte */
defbyte()
	{ot("DB\t");}
/* print pseudo-op to define storage */
defstorage()
	{ot("DS\t");}
/* print pseudo-op to define a word */
defword()
	{ot("DW\t");}
/* modify the stack pointer by the amount requested */
modstk(k)
int k;
	{
	register int newsp;
	newsp = spcc + k;
	switch (k) {		/* special case for 6 or less */
	case 6:
		popwreg();
	case 4:
		popwreg();
	case 2:
		popwreg();
		return newsp;
	case 5:
		popwreg();
	case 3:
		popwreg();
	case 1:
		ol("INX\tSP");
	case 0:
		return newsp;
	case -6:
		pushwreg();
	case -4:
		pushwreg();
	case -2:
		pushwreg();
		return newsp;
	case -5:
		pushwreg();
	case -3:
		pushwreg();
	case -1:
		ol("DCX\tSP");
		return newsp;
		}
	if(swapneeded) { /* do we need to preserve HL? */
		swapneeded=0;
		swapending=1;
		swap();
		}
	pimmed(); outdec(k); nl();
	ol("DAD\tSP");
	ol("SPHL");
	if(swapending) {
		swapending=0;
		swap(); /* HL was saved; restore it */
		}
	return newsp;
	}
/* Pop the top of the stack into the work register */
popwreg()
	{
	ol("POP\tB");
	}
/* Push the work register onto the top of the stack */
pushwreg()
	{
	ol("PUSH\tB");
	}
/* generate code to add rop to lop which is in primary reg */
doadd(lop, rtype, rop)
int lop[], rtype, rop[];
	{
	register int n, pop, lptrtype, rptrtype;
	lptrtype = ptrtype(lop);
	rptrtype = ptrtype(rop);
	if (rtype == CONSTANT) {
		n = rop[1];
		if (lptrtype == PTRTOINT) /* if adding to a ptrtoint */
			n <<= 1;	/* double the amt */
		switch (n) {		/* special handling of */
		case 3: cinc(); 	/* small constants */
		case 2: cinc();
		case 1: cinc();
		case 0: return;
			}
		simmed();		/* load constant in secondary reg */
		outdec(n);
		nl();
		cadd(NOPOP);		/* both ops in registers */
		return;
		}
	if (lptrtype && rptrtype)
		ptrerr();	/* ptr + ptr is illegal */
	if (rtype) {		/* amt to add (rop) needs to be loaded */
		if (rptrtype == PTRTOINT)
			doublereg(); /* lop + ptr-to-int so double lop */
		pop = rvals(rop, COMMUT); /* load using secondary reg */
		}
	else			/* amt to add is an expression in preg */
		if (rptrtype == PTRTOINT) {
			cadd(POP); /* it's lop + ptr-to-int so */
			pop = NOPOP; /* double lop by adding twice */
			}
		else
			pop = POP;
	if (lptrtype == PTRTOINT) /* if it's ptr-to-int + rop */
		doublereg();	/* double rop */
	cadd(pop);		/* rvals decided if POP needed */
	if (rptrtype)
		lop[0] = rop[0]; /* save ptr type for other operators */
	}
/* generate code to subtract rop from lop which is in primary reg */
dosub(lop, rtype, rop)
int lop[], rtype, rop[];
	{
	register int n, pop, lptrtype, rptrtype;
	lptrtype = ptrtype(lop);
	rptrtype = ptrtype(rop);
	if (rtype == CONSTANT) {
		n = rop[1];
		if (lptrtype==PTRTOINT) /* if subtracting from ptrtoint */
			n <<= 1;	/* double the amt */
		switch (n) {		/* special handling of */
		case 3: cdec(); 	/* small constants */
		case 2: cdec();
		case 1: cdec();
		case 0: return;
			}
		simmed();		/* load constant in secondary reg */
		outdec(-n);		/* do lop + (-rop) */
		nl();
		cadd(NOPOP);		/* both ops in registers */
		return;
		}
	if (rptrtype && lptrtype != rptrtype) /* ptr must be */
		ptrerr();		/* subtracted from a like ptr */
	if (rtype)
		pop = rvals(rop, NONCOMMUT); /* load using secondary reg */
	else
		pop = POP;		/* rop is an expression in preg */
	if (lptrtype == PTRTOINT && !rptrtype)
		doublereg();		/* double rop for ptrtoint - scalar */
	csub(pop);			/* rvals decided if POP needed */
	if (rptrtype == PTRTOINT) {	/* ptrtoint - ptrtoint */
		swap(); 		/* put diff in secondary reg */
		set1(); 		/* divide diff by 2 by */
		casr(NOPOP);		/* shifting right 1 */
		}
	}
/* double the primary register */
doublereg()
	{ol("DAD\tH");}
/* add the primary and secondary registers */
/*	(result in primary) */
cadd(pop)
int pop;
	{
	if(pop==POP) popsreg();
	ol("DAD\tD");
	}
/* subtract the primary register from the secondary */
/*	(results in primary) */
csub(pop)
int pop;
	{callib("s",pop);}
/* multiply the primary and secondary registers */
/*	(result in primary) */
cmult(pop)
int pop;
	{callib("mult",pop);}
/* divide the secondary register by the primary */
/*	(quotient in primary, remainder in secondary) */
cdiv(pop)
int pop;
	{callib("div",pop);}
/* compute remainder (mod) of secondary register */
/*	divided by the primary */
/*	(remainder in primary, quotient in secondary */
cmod(pop)
int pop;
	{
	cdiv(pop);
	swap();
	}
/* inclusive 'or' the primary and secondary register */
/*	(result in primary) */
cor(pop)
int pop;
	{callib("o",pop);}
/* exclusive 'or' the primary and secondary register */
/*	(result in primary) */
cxor(pop)
int pop;
	{callib("x",pop);}
/* and the primary and secondary register */
/*	(result in primary) */
cand(pop)
int pop;
	{callib("a",pop);}
/* arithmetic right shift the secondary register number */
/*	of times in primary (results in primary */
casr(pop)
int pop;
	{callib("asr",pop);}
/* arithmetic left shift the secondary register number */
/*	of times in primary (results in primary */
casl(pop)
int pop;
	{callib("asl",pop);}
/* form two's complement of primary register */
cneg()
	{callib("neg",NOPOP);}
/* form one's complement of primary register */
ccom()
	{callib("com",NOPOP);}
/* form logical not of primary register and set */
/*	HL and Z flag to indicate TRUE/FALSE */
cnot()
	{
	callib("n",NOPOP);
	testdone = TRUE;
	}
/* increment the primary register */
cinc()
	{ol("INX\tH");}
/* decrement the primary register */
cdec()
	{ol("DCX\tH");}

/* The following are the conditional operators.  They	*/
/* compare the secondary register against the primary	*/
/* and set the primary register = 1 if the condition is */
/* true.  Otherwise they clear the primary register.	*/
/* Furthermore, the Z flag is reset if the test is TRUE.*/
/* Otherwise, the Z flag is set.			*/

/* test for equal */
ceq(pop)
int pop;
	{
	callib("e",pop);
	testdone = TRUE;
	}
/* test for not equal */
cne(pop)
int pop;
	{
	callib("ne",pop);
	testdone = TRUE;
	}
/* test for less than (signed) */
clt(pop)
int pop;
	{
	callib("lt",pop);
	testdone = TRUE;
	}
/* test for less than of equal (signed) */
cle(pop)
int pop;
	{
	callib("le",pop);
	testdone = TRUE;
	}
/* test for greater than (signed) */
cgt(pop)
int pop;
	{
	callib("gt",pop);
	testdone = TRUE;
	}
/* test for greater than or equal (signed) */
cge(pop)
int pop;
	{
	callib("ge",pop);
	testdone = TRUE;
	}
/* test for less than (unsigned) */
cult(pop)
int pop;
	{
	callib("ult",pop);
	testdone = TRUE;
	}
/* test for less than or equal (unsigned) */
cule(pop)
int pop;
	{
	callib("ule",pop);
	testdone = TRUE;
	}
/* test for greater than (unsigned) */
cugt(pop)
int pop;
	{
	callib("ugt",pop);
	testdone = TRUE;
	}
/* test for greater than or equal (unsigned) */
cuge(pop)
int pop;
	{
	callib("uge",pop);
	testdone = TRUE;
	}
