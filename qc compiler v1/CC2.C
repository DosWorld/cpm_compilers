/********************************************************/
/*							*/
/*		C Compiler Version 1.0			*/
/*			(Part 2)			*/
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
/*	Compound statement		*/
/*					*/
/* Allow any number of statements to	*/
/*	fall between the "{}".		*/
compound()
	{
	++ncmp; 		/* start new level */
	while (!match("}")) {
		if(eof)
			return;
		else
			statement();
		}
	--ncmp; 		/* close this level */
	}

/*					*/
/*	Statement parser		*/
/*					*/
/* Called whenever syntax requires a	*/
/* statement. This routine determines	*/
/* the type of statement and calls the	*/
/* appropriate function to evaluate	*/
/* the statement.			*/

statement()
	{
	if(ch()==0 && eof) return;
	chklabel();		/* check for a statement label */
	if(match("{"))
		compound();
	else if(amatch("if"))
		doif();
	else if(amatch("while"))
		dowhile();
	else if(amatch("for"))
		dofor();
	else if(amatch("return"))
		doreturn();
	else if(amatch("break"))
		{dobreak(); ns();}
	else if(amatch("continue"))
		{docont(); ns();}
	else if(amatch("switch"))
		doswitch();
	else if(amatch("do"))
		{dodowhile(); ns();}
	else if(amatch("else"))
		error("else not matched with if");
	else if(amatch("case") || amatch("default")) {
		error("No active switch statement");
		match(":");	/* strip colon if present */
		}
	else if(amatch("goto"))
		{dogoto(); ns();}
	else if(match(";"))
		;		/* null statement */
	else if(match("#asm"))
		doasm();
	else			/* It must be an expression */
		{expression(); ns();}
	}
/*					*/
/*	Check for a statement label	*/
/*					*/
chklabel()
	{
	register char *ptr, labname[NAMESIZE];
	register int i;
	blanks();
	if (!isalpha(ch()))	/* name must start with an alpha */
		return 0;
	if (astreq(lptr, "default", 7))
		return 0;	/* ignore switch default case label */
	ptr = lptr;		/* start at current parse line position */
	i = 0;
	while (isalnum(*ptr)) { /* copy symbol name */
		if(i < NAMEMAX)
			labname[i++] = *ptr++;
		else
			++ptr;	/* skip rest of long name */
		}
	labname[i] = '\0';
	while (isspace(*ptr))	/* ignore blanks after name */
		++ptr;
	if (*ptr != ':')	/* is it a label? */
		return 0;	/* only if it is followed by a colon */
	linelabel(addlabel(labname, LABEL)); /* define & prt */
	lptr = ++ptr;		/* move parse line ptr past label */
	chklabel();		/* check for additional labels */
	return TRUE;
	}
/*					*/
/*	Semicolon enforcer		*/
/*					*/
/* Called whenever syntax requires a semicolon */
ns()
	{
	if(!match(";"))
		error("Missing semicolon");
	}
/*					*/
/*		"if" statement		*/
/*					*/
doif()
	{
	auto lab1, lab2;
	testexp();		/* evaluate expression */
	jumpfalse(lab1=getlabel()); /* & branch false */
	statement();		/* if true, do a statement */
	if(!amatch("else"))   { /* if...else? */
		linelabel(lab1); /* no, just print false label */
		return; 	/* and exit */
		}
	/* an "if...else" statement */
	jump(lab2=getlabel());	/* jump around false code */
	linelabel(lab1);	/* print false label */
	statement();		/* and do "else" clause */
	linelabel(lab2);	/* print true label */
	}
/*					*/
/*	"while" statement		*/
/*					*/
dowhile()
	{
	int q[SWQSIZE]; 	/* allocate local queue */
	q[LOOP]=getlabel();	/* looping label */
	q[EXIT]=getlabel();	/* exit label for "break" */
	addswq(q);		/* add entry to queue */
	linelabel(q[LOOP]);	/* loop label */
	testexp();		/* evaluate condition */
	jumpfalse(q[EXIT]);	/* & exit if false */
	statement();		/* else, do loop body */
	jump(q[LOOP]);		/* loop to condition test */
	linelabel(q[EXIT]);	/* exit label */
	delswq();		/* delete queue entry */
	}
/*					*/
/*	"for" statement"		*/
/*					*/
dofor()
	{
	auto int q[SWQSIZE], lab1, lab2;
	needpunc("(");		/* look for opening parenthesis */
	q[EXIT] = getlabel();	/* exit label for "break" */
	if(!match(";")) {	/* check for null initialization */
		expression();	/* do initialization */
		ns();
		}
	if(match(";"))		/* check for null condition */
		lab1 = 0;
	else {
		linelabel(lab1 = getlabel());
		expression();	/* check condition */
		ns();
		jumpfalse(q[EXIT]);
		}
	if(match(")"))		/* check for null increment */
		if(lab1)	/* see if there was an cond expr */
			q[LOOP] = lab1; /* if so, loop back there */
		else
			linelabel(q[LOOP] = getlabel());
	else {			/* there is an increment expression */
		jump(lab2=getlabel()); /* do body after condition */
		linelabel(q[LOOP]=getlabel()); /* loop to here */
		expression();	/* evaluate increment expression */
		needpunc(")");	/* look for closing parenthesis */
		if(lab1)
			jump(lab1); /* there was a cond - check it */
		linelabel(lab2);
		}
	addswq(q);		/* add entry to queue */
	statement();		/* do body of for loop */
	jump(q[LOOP]);		/* loop to label */
	linelabel(q[EXIT]);	/* exit label */
	delswq();		/* delete queue entry */
	}
/*					*/
/*	"do while" statement		*/
/*					*/
dodowhile()
	{
	int lab, q[SWQSIZE];
	q[LOOP] = getlabel();	/* looping label */
	q[EXIT] = getlabel();	/* exit label for "break" */
	addswq(q);		/* add entry to queue */
	linelabel(lab=getlabel()); /* go thru here at least once */
	statement();		/* do loop body */
	if(!match("while"))
		error("Missing while in dowhile");
	linelabel(q[LOOP]);	/* loop label */
	testexp();		/* evaluate condition */
	jumptrue(lab);		/* & loop if true */
	linelabel(q[EXIT]);	/* exit label */
	delswq();		/* delete queue entry */
	}
/*					*/
/*	"return" statement		*/
/*					*/
doreturn()
	{
	if(!endst()) {		/* if not end of statement... */
		expression();	/* eval return expression */
		swapneeded = TRUE; /* record that HL contains val */
		}
	ns();			/* check for ending semicolon */
	blanks();		/* see what comes next */
	if(ch() != '}' || ncmp > 1) {	/* not end of function */
		if(!retlab)	/* is there a return label? */
			retlab = getlabel(); /* no, get one */
		jump(retlab);
		}
	}
/*					*/
/*	"break" statement		*/
/*					*/
dobreak()
	{
	int *ptr;
	if(ptr = getswq())	/* any switches or loops open? */
		jump(ptr[EXIT]); /* jump to exit label */
	else
		error("No active switches or loops");
	}
/*					*/
/*	"continue" statement		*/
/*					*/
docont()
	{
	int *ptr;
	if((ptr=getswq()) && ptr[LOOP]) { /* any loops open? */
		jump(ptr[LOOP]); /* jump to loop label	*/
		return;
		}
	error("No active loop statement");
	}
/*					*/
/*	"switch" statement		*/
/*					*/
doswitch()
	{
	register ncases, *ptr;
	auto skiplab, defaultlab, q[SWQSIZE];

	testexp();		/* evaluate expression in parentheses */
	jump(skiplab=getlabel()); /* skip body of switch */
	q[EXIT] = getlabel();	/* exit label for "break" */
	/* if we're in a loop, copy loop label for continue */
	q[LOOP] = (ptr=getswq()) ? ptr[LOOP]: 0;
	addswq(q);		/* add entry to switch/loop queue */
	defaultlab = ncases = 0; /* no default or cases yet */
	if (match("{")) {	/* is body a compound statement? */
		++ncmp; 	/* bump compound statement counter */
		while (!match("}")) {
			if (eof) return;
			ncases += docase(&defaultlab);
			}
		--ncmp; 	/* close this level */
		}
	else			/* switch body is a simple statement */
		ncases += docase(&defaultlab);
	jump(q[EXIT]);		/* skip over lib call & its args */
	linelabel(skiplab);
	callib("sw", NOPOP);	/* call library switch routine */
	defword();		/* build arg list for lib routine */
	outdec(ncases); 	/* tell it number of cases */
	nl();
	while (ncases--) {	/* arg list entry for each case */
		if ((ptr = delcase()) == NULL)
			break;
		defword();	/* value which selects this case */
		outdec(ptr[CASEVALUE]);
		outbyte(',');	/* now, label for this case */
		printlabel(ptr[CASELABEL]);
		nl();
		}
	defword();		/* arg list ends with default case label */
	printlabel(defaultlab ? defaultlab: q[EXIT]);
	nl();
	linelabel(q[EXIT]);	/* "break" statements arrive here */
	delswq(q);		/* remove entry from switch/loop queue */
	}
/*					*/
/*	Evaluate a switch case		*/
/*					*/
docase(defaultlab)
int *defaultlab;	/* default case label */
	{
	int ncases, entry[CASESIZE];

	ncases = 0;
	for(;;) {	/* eval all cases/labels before statement */
	    if (amatch("case")) {
		if (constexp(&entry[CASEVALUE])) {
			++ncases;
			linelabel(entry[CASELABEL] = getlabel());
			addcase(entry);
			}
		else
			error("Case value must be a constant\
 expression");
		needpunc(":");
		}
	    else if (amatch("default")) {
		needpunc(":");
		if (*defaultlab) /* is there a default case already? */
			error("Multiple default cases");
		else
			linelabel(*defaultlab = getlabel());
		}
	    else if (chklabel()) /* labels can be mixed in */
		;		/* chklabel does all the work */
	    else		/* it's not a case, default or a label */
		break;
	    }
	statement();		/* process the statement */
	return ncases;
	}
/*					*/
/*	"goto" statement		*/
/*					*/
dogoto()
	{
	char labelname[NAMESIZE];
	if(!symname(labelname))
		illname();
	else
		jump(addlabel(labelname, 0));
	}
/*					*/
/*	"asm" pseudo statement		*/
/*					*/
/* Pass assembly language statements	*/
/*	through the compiler		*/
doasm()
	{
	cmode = FALSE;		/* set flag to show this is not C */
	if(midline)		/* if we're in the middle of a line...*/
		nl();		/* end it */
	for(;;) {
		inline();	/* get next line */
		if(streq(line, "#endasm") || eof)
			break;
		if (ch() == '#' && match("#include"))
			doinclude();
		outstr(line);
		nl();
		}
	kill(); 		/* clear #endasm line */
	cmode = TRUE;		/* back in C mode */
	}
