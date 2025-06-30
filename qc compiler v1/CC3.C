/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 3)			*/
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

/* This section is the recursive descent*/
/*	parser of C expressions.	*/
/*	heir1() thru heir15() implement */
/*	the hierarchy of operators.	*/
/*	primary() analyzes primary	*/
/*	expressions to determine their	*/
/*	type.				*/
/*					*/
expression()
	{
	int op[2];	/* op + return value from heir1-15 describe expr */
	pregflag = 0;	/* no value in primary reg for expr yet */
	if (heir1(op))
		rvalp(op);
	}
/*	sequence operator (,)	*/
heir1(op)
int op[];
	{
	register int k;
	k = heir2(op);
	while (match(",")) {
		pregflag = 0;	/* start each expr with preg empty */
		k = heir2(op);	/* staying at this level causes */
		}	/* value in preg to be right-most expression */
	return k;
	}
/*	assigment operators (=, +=, |=, etc.	*/
heir2(lop)
int lop[];
	{
	register int type, k, rop[2], commutflag;
	register char *sym;
	k = heir3(lop);
	if (match("=")) {	/* simple assignment */
		if (k != LVALUE) {
			needlval();
			return 0;
			}
		if(lop[1]) {	/* if we have an address in preg */
			cpush();	/* save it */
			pregflag = 0;	/* don't save preg again */
			}
		else {
			sym = lop[0];
			if (sym[STORAGE] == CAUTO) {
				getaddr(sym);	/* save addr of stk var */
				cpush();	/* for store & set type */
				lop[1] = (sym[IDENT]==POINTER)?
					CINT: sym[TYPE];
				pregflag = 0;	/* preg saved */
				}
			}
		if(heir2(rop))	/* staying at this level causes */
			rvalp(rop);	/* right to left evaluation */
		store(lop);
		return 0;
		}
	type = ch();		/* check for assignment operator */
	if (match("+=") || match("|=") || match("&=") ||
		match ("^=") || match("*="))
			commutflag = COMMUT;
	else if (match("-=") || match(">>=") || match("<<=") ||
		 match("/=") || match("%="))
			commutflag = NONCOMMUT;
	else
		return k;	/* it's not an assignment operator */
	if (k == LVALUE)
		rvalpsav(lop);	/* get value of var & save addr */
	else {
		needlval();
		return 0;
		}
	k = heir2(rop); 		/* evaluate right operand */
	if (type == '+')		/* now do lop op rop */
		doadd(lop, k, rop);
	else if (type == '-')
		dosub(lop, k, rop);
	else {
		if (k)		/* load right operand if necessary */
			k = rvals(rop, commutflag);
		switch (type) {
		case '|':
			cor(k);
			break;
		case '^':
			cxor(k);
			break;
		case '&':
			cand(k);
			break;
		case '>':
			casr(k);
			break;
		case '<':
			casl(k);
			break;
		case '*':
			cmult(k);
			break;
		case '/':
			cdiv(k);
			break;
		case '%':
			cmod(k);
			break;
			}
		}
	store(lop); /* store result (lop = lop op rop) */
	return 0;
	}
/* parse a conditional expression e1 ? e2 : e3 */
heir3(op1)
int op1[];
	{
	register k, e2type, e3type;
	int op2[2], lab1, lab2;
	k = heir4(op1);
	blanks();
	if (!match("?")) return k;
	if (k) rvalp(op1);	 /* load e1 in preg if necessary */
	jumpfalse(lab1=getlabel()); /* test e1 & jump if false */
	pregflag = 0;		/* start new expression with preg empty */
	if (heir2(op1)) 	/* evaluate e2 */
		rvalp(op1);	/* load e2 in preg if necessary */
	needpunc(":");		/* e2 must be followed by : */
	jump(lab2=getlabel());	/* don't evaluate e3 per language spec */
	linelabel(lab1);	/* arrive here if e1 is false */
	pregflag = 0;		/* start new expression with preg empty */
	if (heir2(op2)) 	/* evaluate e3 */
		rvalp(op2);	/* load e3 in preg if necessary */
	linelabel(lab2);	/* arrive here if e1 is true */
	/* Set type of expressions e2 and e3:	*/
	/*	ptr-to-int	= PTRTOINT + 1	*/
	/*	ptr-to-char	= PTRTOCHAR + 1 */
	/*	constant zero	= 1		*/
	/*	anything else	= 0		*/
	e2type = (k = ptrtype(op1)) ? ++k: op1[0] == 0 && op1[1] == 0;
	e3type = (k = ptrtype(op2)) ? ++k: op2[0] == 0 && op2[1] == 0;
	if ((e2type <= 1 && e3type <= 1) /* OK, neither are pointers */
	   || e2type == e3type		/* OK, both ptrs same type */
	   || e3type == 1)		/* OK, e3 is NULL */
		;			/* type expression same as e2 */
	else if (e2type == 1) { 	/* OK, e2 is NULL */
		op1[0] = op2[0];	/* set type same as e3 */
		op1[1] = op2[1];
		}
	else
		ptrerr();		/* illegal use of pointers */
	return 0;
	}
/* parse a logical OR expression (e1 || e2) */
heir4(lop)
int lop[];
	{
	register k, lab1;
	int rop[2], lab2;
	k = heir5(lop);
	blanks();
	if (!streq(lptr,"||")) return k;
	lab1 = getlabel();
	if (k) rvalp(lop);
	while (match("||")) {
		jumptrue(lab1); /* if e1 true, go set e1||e2 = 1 */
		pregflag=0;	/* start new expr with preg empty */
		if (heir5(rop)) /* evaluate e2 */
			rvalp(rop); /* load e2 into preg if necessary */
		}
	jumpfalse(lab2=getlabel()); /* if e2 false, e1||e2 is 0 */
	linelabel(lab1);	/* arrive here if true */
	set1(); 		/* set value of e1 || e2 to 1 */
	linelabel(lab2);	/* false label */
	testdone = TRUE;	/* record that we just did a test */
	return 0;
	}
/* parse a logical AND expression (e1 && e2) */
heir5(lop)
int lop[];
	{
	register k, rop[2], lab1;
	k = heir6(lop);
	blanks();
	if (!streq(lptr,"&&"))
		return k;
	lab1 = getlabel();
	if(k)		/* if lop not an expression ... */
		rvalp(lop);	/* load it into preg */
	while (match("&&")) {
		jumpfalse(lab1); /* if e1 is false, we're thru */
		pregflag = 0;	/* start new expr with preg empty */
		if(heir6(rop))	/* evaluate e2 */
			rvalp(rop);
		}
	jumpfalse(lab1);	/* if e2 is false, e1&&e2 is 0 */
	set1();
	linelabel(lab1);	/* false label */
	testdone = TRUE;
	return 0;
	}
/* bitwise inclusive OR */
heir6(lop)
int lop[];
	{
	register k, rop[2];
	k = heir7(lop);
	blanks();
	if (ch() != '|' || nch() == '|' || nch() =='=')
		return k;
	if (k)
		rvalp(lop);
	for (;;) {
		if (nch() != '|' && nch() != '=' && match("|")) {
			if (k = heir7(rop))
				k = rvals(rop, COMMUT);
			cor(k);
			}
		else return 0;
		}
	}
/* bitwise exclusive OR */
heir7(lop)
int lop[];
	{
	register k, rop[2];
	k = heir8(lop);
	blanks();
	if (ch() != '^' || nch() == '=')
		return k;
	if (k)
		rvalp(lop);
	for (;;) {
		if (nch() != '=' && match("^")) {
			if (k = heir8(rop))
				k=rvals(rop, COMMUT);
			cxor(k);
			}
		else return 0;
		}
	}
/* bitwise AND */
heir8(lop)
int lop[];
	{
	register k, rop[2];
	k = heir9(lop);
	blanks();
	if (ch() != '&' || nch() == '&' || nch() == '=')
		return k;
	if (k)
		rvalp(lop);
	for (;;) {
		if (nch() != '&' && nch() != '=' && match("&")) {
			if (k = heir9(rop))
				k = rvals(rop, COMMUT);
			cand(k);
			}
		else return 0;
		}
	}
heir9(lop)
int lop[];
	{
	register k, rop[2];
	k = heir10(lop);
	blanks();
	if (!streq(lptr, "==") && !streq(lptr,"!="))
		return k;
	if (k)
		rvalp(lop);
	for (;;) {
		if (match("==")) {		/* equality */
			if (k = heir10(rop)) {
				if (k == CONSTANT) {
					switch (rop[1]) {
					case -1:
						cinc();
						goto case0;
					case 1:
						cdec();
					case 0: case0:
						cnot();
						continue;
						}
					}
				k = rvals(rop, COMMUT);
				}
			ceq(k);
			}
		else if (match("!=")) { 	/* inequality */
			if (k = heir10(rop))
				k = rvals(rop, COMMUT);
			cne(k);
			}
		else return 0;
		}
	}
heir10(lop)
int lop[];
	{
	register k, lptrtype, rop[2];
	k = heir11(lop);
	blanks();
	if((!streq(lptr, "<") && !streq(lptr,">") &&
	    !streq(lptr,"<=") && !streq(lptr,">=")) ||
	     streq(lptr,">>") || streq(lptr,"<<"))
		return k;
	if (k)
		rvalp(lop);
	lptrtype = ptrtype(lop);
	for (;;) {
		if (match("<=")) {	/* less than or equal */
			if (k = heir11(rop))
				k = rvals(rop, NONCOMMUT);
			if (lptrtype || ptrtype(rop))
				cule(k);
			else
				cle(k);
			}
		else if (match(">=")) { /* greater than or equal */
			if (k = heir11(rop))
				k = rvals(rop, NONCOMMUT);
			if (lptrtype || ptrtype(rop))
				cuge(k);
			else
				cge(k);
			}
		else if (nch() != '<' && match("<")) {	/* less than */
			if (k = heir11(rop))
				k = rvals(rop, NONCOMMUT);
			if (lptrtype || ptrtype(rop))
				cult(k);
			else
				clt(k);
			}
		else if (nch() != '>' && match(">")) {	/* greater than */
			if (k = heir11(rop))
				k = rvals(rop, NONCOMMUT);
			if (lptrtype || ptrtype(rop))
				cugt(k);
			else
				cgt(k);
			}
		else return 0;
		lptrtype = 0;	/* lop no longer a pointer - it's 0 or 1 */
		}
	}
heir11(lop)
int lop[];
	{
	register k, rop[2];
	k = heir12(lop);
	blanks();
	if ((!streq(lptr,">>") && !streq(lptr,"<<")) ||
	      streq(lptr,">>=") || streq(lptr,"<<="))
		return k;
	if (k)
		rvalp(lop);
	for (;;) {
		if (!streq(lptr,">>=") && match(">>")) {
			if (k = heir12(rop))
				k = rvals(rop, NONCOMMUT);
			casr(k);
			}
		else if (!streq(lptr,"<<=") && match("<<")) {
			if (k = heir12(rop))
				k = rvals(rop, NONCOMMUT);
			casl(k);
			}
		else return 0;
		}
	}
heir12(lop)
int lop[];
	{
	register k, rop[2];
	k = heir13(lop);
	blanks();
	if ((ch() != '+' && ch() != '-') || nch() == '=')
		return k;
	if (k)
		rvalp(lop);
	while (nch() != '=') {
		if (match("+")) {	/* addition */
			k = heir13(rop);
			doadd(lop, k, rop);
			}
		else if (match("-")) {	/* subtraction */
			k = heir13(rop);
			dosub(lop, k, rop);
			}
		else break;
		}
	return 0;
	}
heir13(lop)
int lop[];
	{
	register k, rop[2];
	k = heir14(lop);
	blanks();
	if ((ch() != '*' && ch() != '/' && ch() != '%') || nch() == '=')
		return k;
	if (k)
		rvalp(lop);
	while (nch() != '=') {
		if (match("*")) {	/* multiplication */
			if (k = heir14(rop))
				k = rvals(rop, COMMUT);
			cmult(k);
			}
		else if (match("/")) {	/* division */
			if (k = heir14(rop))
				k = rvals(rop, NONCOMMUT);
			cdiv(k);
			}
		else if (match("%")) {	/* modulus */
			if (k = heir14(rop))
				k = rvals(rop, NONCOMMUT);
			cmod(k);
			}
		else break;
		}
	return 0;
	}
/* heir14 calls itself because unary operators */
/*	associate left to right */
heir14(op)
int op[];
	{
	register k;
	register char *sym;
	if (match("++")) {		/* pre-increment */
		if (heir14(op) != LVALUE) {
			needlval();
			return 0;
			}
		rvalpsav(op);		/* get op & sav addr if on stk */
		cinc();
		if (ptrtype(op) == PTRTOINT)
			cinc(); 	/* ptrtoint must change by 2 */
		store(op);
		return 0;
		}
	if (match("--")) {		/* pre-decrement */
		if (heir14(op) != LVALUE) {
			needlval();
			return 0;
			}
		rvalpsav(op);		/* get op & sav addr if on stk */
		cdec();
		if (ptrtype(op) == PTRTOINT)
			cdec(); 	/* ptrtoint must change by 2 */
		store(op);
		return 0;
		}
	if (ch() == '-') {		/* unary minus (negation) */
		if (decimal(&op[1])) {	/* NOTE: decimal */
			op[0] = 0;	/*	strips '-' */
			return CONSTANT;
			}
		if (heir14(op))
			rvalp(op);
		cneg();
		return 0;
		}
	if (match("*")) {		/* indirection */
		if (heir14(op))
			rvalp(op);
		if (sym = op[0])	/* it's a variable */
			op[1] = sym[TYPE];
		else {			/* it's a pointer expression */
			op[0] = 1;	/* indicate it's not a constant */
			op[1] = CINT;
			}
		return LVALUE;
		}
	if (match("!")) {		/* logical not (!exp) */
		if (heir14(op))
			rvalp(op);
		cnot();
		return 0;
		}
	if (match("~")) {		/* one's complement (~exp) */
		if (heir14(op))
			rvalp(op);
		ccom();
		return 0;
		}
	if (match("&")) {		/* address */
		k = heir14(op);
		sym = op[0];		/* ptr to symbol table entry */
		if(k != LVALUE || sym[STORAGE] == CREG) {
			error("Illegal address");
			return 0;
			}
		if (op[1] == 0) {	/* variable not loaded yet */
			if (pregflag)	/* if preg already has a value */
				cpush(); /* save it */
			else		/* remember it has a value now */
				pregflag = TRUE;
			getaddr(sym);
			}
		/* else address is already in primary register */
		/* Set type to pointer */
		op[1] = (sym[TYPE] == CINT) ? PTRTOINT: PTRTOCHAR;
		return 0;
		}
	k = heir15(op); 		/* look for a primary expression */
	if (match("++")) {		/* post-increment */
		if (k != LVALUE) {
			needlval();
			return 0;
			}
		rvalpsav(op);		/* get op & sav addr if on stk */
		cinc();
		if (ptrtype(op) == PTRTOINT) {
			cinc(); 	/* ptrtoint must change by 2 */
			store(op);
			cdec();
			}
		else
			store(op);
		cdec(); 		/* get orig val back to use */
		return 0;
		}
	if (match("--")) {		/* post-decrement */
		if (k != LVALUE) {
			needlval();
			return 0;
			}
		rvalpsav(op);		/* get op & sav addr if on stk */
		cdec();
		if (ptrtype(op) == PTRTOINT) {
			cdec(); 	/* ptrtoint must change by 2 */
			store(op);
			cinc();
			}
		else
			store(op);
		cinc(); 		/* get orig val back to use */
		return 0;
		}
	return k;
	}
heir15(op)
int op[];
	{
	register k;
	int sub[2], savpregflag;
	register char *sym;
	k = primary(op);
	sym = op[0];
	blanks();
	if ((ch() == '[') || (ch() == '(')) {	/* begin a subcript */
		for (;;) {			/* or arg expression */
		    if (match("[")) {
			if (sym == 0 || (sym[IDENT] != ARRAY
			    && sym[IDENT] != POINTER)) {
				error("Can't subscript");
				junk();
				needpunc("]");
				return 0;
				}
			rvalp(op);		/* get addr in primary reg */
			savpregflag = pregflag; /* subcript is new expr */
			k = heir1(sub); 	/* evaluate subscript */
			doadd(op, k, sub);	/* addr of array item */
			pregflag = savpregflag; /* back to prev expr */
			needpunc("]");
			op[1] = sym[TYPE];
			k = LVALUE;
			}
		    else if (match("(")) {	/* a function call */
			if (!sym) {
				if (k == CONSTANT)
					rvalp(op);
				callfunction(0); /* call (HL) */
				}
			else if (sym[IDENT] != FUNCTION) {
				rvalp(op);	/* call value */
				callfunction(0); /* of expr */
				}
			else callfunction(sym); /* call *sym */
			k = op[0] = 0;
			}
		    else break;
		    }
		}
	return k;
	}
/* Evaluate a potential primary expression */
primary(op)
int op[];
	{
	register char *sym;
	char sname[NAMESIZE];
	int num;
	register k, id;
	if (match("(")) {
		k = heir1(op);	/* start a new expression */
		needpunc(")");	/*	one level down */
		return k;
		}
	if (symname(sname)) {	/* see if next token is legal name */
		if ((sym = findloc(sname)) ||	/* is it a local? */
		   ((sym = findglb(sname)) &&	/* or a global? */
		     sym[INFO] != LOCAL)) {
			op[0] = sym;
			op[1] = 0;
			id = sym[IDENT];
			if (id == LABEL) {
				errname("Illegal use of label",sym);
				return (op[0] = 0);
				}
			return (id == VARIABLE
				|| id == POINTER) ? LVALUE : id;
			}
		blanks();
		if (ch() == '(')	/* is it a function reference? */
			op[0] = addglb(sname,FUNCTION,CINT,
						CEXTERN,LOCAL);
		else {
			errname("Undefined variable",sname);
			op[0] = 0;
			}
		return (op[1] = 0);
		}
	/* This should be a constant or a string */
	op[0] = 0;
	if (intconst(&op[1]))		/* is it an int constant... */
		return CONSTANT;
	pimmed(); /* we're going to load a value */
	if (string(&num)) {		/*	or a string? */
		printlabel(litlab);
		outbyte('+');
		outdec(num);
		}
	else {				/*	if not, it's an error */
		outbyte('0');
		error("Invalid expression");
		junk();
		}
	nl();
	return (op[1] = 0);
	}
