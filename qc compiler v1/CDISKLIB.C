/************************************************/
/*						*/
/*	Disk I/O Library for Q/C Compiler	*/
/* Copyright (c) 1981 Quality Computer Systems	*/
/*						*/
/*		   10/26/81			*/
/************************************************/

/* Note: Uncomment the next line if you are using M80
#include "qstdio.h"
*/

/* General purpose constants */

#define OK	1	/* general purpose OK return */
#define MAXLINE 82	/* maximum size of console input line */
#define CTLC	0x3	/* CP/M ^C */

/* Library parameters */

#define MAXARG	20	/* max no. of command line arguments */
#define NFILS	5	/* max no. of files that can be opened at once */
#define IOBSIZE 6	/* size of an iob for buffered I/O */
#define FCBSIZE 37	/* size of an fcb for low-level I/O */
#define FCBFLAG 36	/* location of flag in an fcb */
#define NSECTS	4	/* no. of CP/M records to buffer */
#define SECSIZE 128	/* size of CP/M record */
#define BUFSIZE NSECTS*SECSIZE	/* buffer size for buffered I/O */

/* I/O blocks (iob's) for buffered files			*/
/*	iob[PCH]   = ptr to curr char in buffer			*/
/*	iob[FLAG]  = read/write/eof/error flag			*/
/*	iob[CNT]   = no. of chars remaining in buffer		*/
/*	iob[BASE]  = address of buffer				*/
/*	iob[UNGCH] = unget char buffer (only used if		*/
/*			file is opened for READ)		*/
/*	iob[FD]    = file descriptor (fd) for low-level I/O	*/

#define PCH	0
#define FLAG	1
#define CNT	2
#define BASE	3
#define UNGCH	4
#define FD	5

/* I/O flag masks */

#define READ	01
#define WRITE	02
#define BUF	04
#define FEOF	010
#define FERR	020

/* Miscellaneous CP/M constants */

#define CPMFCBSIZ 36
#define DBUFF	0x80
#define CPMERR	0xFF
#define CPMEOF	0x1A

/* CP/M function numbers */

#define CONIN	1
#define CONOUT	2
#define LSTOUT	5
#define CONIO	6
#define CONBUF	10
#define CPMVERS 12
#define OPENF	15
#define CLOSEF	16
#define DELETEF 19
#define READF	20
#define WRITEF	21
#define MAKEF	22
#define SETDMA	26


/* Global declarations */

int	stdin,
	stdout,
	stderr,
	stdlst,
	cciob[NFILS*IOBSIZE];	/* I/O blocks (iob) for */
				/* buffered I/O routines */
char	ccfcb[NFILS*FCBSIZE];	/* file control blocks (fcb) */
				/* for low-level I/O routines */
extern ccfree;			/* free space address */

/* Parse command line and set standard file designators */
ccshell()
	{
	static argc, argv[MAXARG], argflag, cmdcnt, i, c;
	static char *cmdline, *pargs, *ptr;
	char args[128], infil[15], outfil[15];

	cmdline = 0x80; 	/* CP/M command line at 80H */
	cmdcnt = *cmdline++;	/* first byte is length */
	pargs = args;		/* point to args */
	argc = *pargs = 	/* set command = NULL */
	infil[0] = outfil[0] =	/* no redirection of standard files */
	argflag = NULL; 	/* not in an arg to start with */
	argv[argc++] = pargs;	/* record pointer to 1st arg */
	stderr = CONOUT;	/* set standard files */
	stdlst = LSTOUT;
	while (cmdcnt--) {
		c = *cmdline++;
		switch (argflag) {
		case NULL:		/* not in an arg */
			if (isspace(c))
				continue; /* still not in an arg */
			if (argc == MAXARG) {
				fputs("Too many command line args\n", stderr);
				exit(1);
				}
			argflag = c;	/* set type of arg */
			if (c == '<')	/* redirect stdin */
				ptr = infil;
			else if (c == '>') /* redirect stdout */
				ptr = outfil;
			else {		/* just an arg */
				argv[argc++] = pargs + 1;
				if (c != '"')	/* if not a string */
					break;	/* record char */
				}
			continue;	/* skip this character */
		case '<':		/* record redirection */
		case '>':		/* file name */
			if (isspace(c))
				c = argflag = NULL; /* end of name */
			*ptr++ = c;
			continue;
		case '"':		/* in a string */
			if (c == '"')
				c = argflag = NULL; /* end of string */
			break;
		default:
			if (isspace(c))
				c = argflag = NULL; /* end of arg */
			break;
			}
		*++pargs = c;
		}
	if (argflag == '<' || argflag == '>') /* end last arg */
		*ptr = 0;		/* a redirected filename */
	else
		*++pargs = 0;		/* a normal arg */
	for (i = 0; i < NFILS; ++i)	/* set no files in use */
		cciob[i * IOBSIZE + FLAG] =
		ccfcb[i * FCBSIZE + FCBFLAG] = 0;
	if (infil[0] == 0)
		stdin = CONIN;		/* no redirection */
	else if ((stdin = fopen(infil, "r")) == NULL)
			cantopen(infil);
	if (outfil[0] == 0)
		stdout = CONOUT;	/* no redirection */
	else if (strcmp(outfil, "LST:") == 0)
		stdout = LSTOUT;	/* send to CP/M LST: device */
	else if ((stdout = fopen(outfil, "w")) == NULL)
			cantopen(outfil);
	main(argc, argv);
	exit(0);
	}

/* Print error message for bad file open and quit */

cantopen(filename)
char *filename;
	{
	fputs("Can't open: ", stderr);
	fputs(filename, stderr);
	exit(1);
	}

/* Cleanup routine - close files, etc. */

exit(error)
int error;
	{
	register int *fp, n;
	for (fp = cciob, n = 0; n < NFILS; fp += IOBSIZE, ++n)
		fclose(fp);		/* close any open files */
	if (error)
		unlink("$$$.SUB");	/* era submit file, if any */
	0();				/* reboot CP/M */
	}
/* Get a character from the standard input file (stdin) */

getchar()
	{
	return getc(stdin);
	}

/* Put a character to the standard output file (stdout) */

putchar(c)
char c;
	{
	return putc(c, stdout);
	}

/* Get a string from stdin */

gets(s)
char *s;
	{
	char *p;
	if (fgets(s, MAXLINE, stdin) == NULL)
		return NULL;
	if (p = index(s, '\n')) 	/* strip newline if present */
		*p = '\0';
	return s;
	}

/* Put a string to stdout */

puts(s)
char *s;
	{
	while(*s)
		putchar(*s++);
	if (*(s - 1) != '\n')
		putchar('\n');		/* append newline if necessary */
	}

/* Open a file for buffered I/O */

fopen(filname, mode)
char *filname, *mode;
	{
	register int *fp, n, fd;
	for (fp = cciob, n=0; n < NFILS; fp += IOBSIZE, ++n)
		if (!(fp[FLAG] & (READ | WRITE)))
			break;		/* found empty iob */
	if (n >= NFILS)
		return NULL;		/* no empty iob's */
	if (*mode == 'r')
		fd = open(filname, 0);
	else if (*mode == 'w')
		fd = creat(filname, 0);
	else
		return NULL;		/* bad mode indicator */
	if (fd == ERROR)
		return NULL;
	if (!(fp[FLAG] & BUF)) {	/* is buffer allocated? */
		if ((fp[BASE]=malloc(BUFSIZE)) == NULL)
			return NULL;
		fp[FLAG] |= BUF;	/* set buffer allocated flag */
		}
	fp[PCH] = fp[BASE];		/* curr char is first in buffer */
	fp[FLAG] |= (*mode == 'r') ? READ : WRITE;
	fp[CNT] = 0;			/* no char in buffer yet*/
	fp[UNGCH] = ERROR;		/* no unget char yet */
	fp[FD] = fd;
	return fp;
	}

/* Get a character from buffered file pointed to by fp */
/* NOTE: This version does not check for unget character */

getc(fp)
int *fp;
	{
	char *fpch;
	register int c, *rfp;
	if ((rfp = fp) == CONIN) {	/* input from console? */
		if ((c=bdos(CONIN, 0)) == '\r') /* chg CR to newline */
			bdos(CONOUT, c = '\n'); /* and echo CRLF */
		}
	else {
		if (!(rfp[FLAG] & READ) /* open for READ? */
		   || (rfp[FLAG] & FEOF)) /* hit EOF yet? */
			return EOF;
		fpch = rfp[PCH]++;	/* point to next char in buffer */
		c = (--rfp[CNT] >= 0) ? *fpch : ccfill(rfp);
		if (c == '\r')
			c = getc(rfp);	/* throw away CR */
		}
	if (c == CPMEOF || c == EOF) {
		rfp[FLAG] |= FEOF;	/* mark file as at EOF */
		return EOF;
		}
	return c;
	}

/* Put a character to the file pointed to by fp */

putc(c, fp)
char c;
int *fp;
	{
	char *fpch;
	register *rfp;
	rfp = fp;			/* load into register */
	if (c == '\n')
		putc('\r', rfp);	/* chg newline to CRLF */
	if (rfp == CONOUT || rfp == LSTOUT) { /* to CON: or LST:? */
		bdos(rfp, c);
		return c;
		}
	if (!(rfp[FLAG] & WRITE))
		return ERROR;		/* not open for WRITE */
	if (rfp[CNT] >= BUFSIZE) {	/* buffer full? */
		if (fflush(rfp) == ERROR)
			return ERROR;
		}
	++rfp[CNT];
	fpch = rfp[PCH]++;	/* record curr char & point to next */
	return (*fpch = c);
	}

/* Get a string from the file pointed to by fp */

fgets(s, maxsize, fp)
char *s;
int maxsize, *fp;
	{
	register int c, size;
	register char *ps, *q;
	ps = s;
	if (fp == CONIN) {	/* if console input use CP/M function #10 */
		*ps = maxsize;		/* set buffer size for CP/M */
		bdos(CONBUF, ps);	/* get the line from console */
		bdos(CONOUT, '\n');	/* echo LF after CR */
		size = ps[1];		/* find out how long line is */
		q = ps + 2;		/* beginning of line */
		while (size--)		/* move line to start of buffer */
			*ps++ = *q++;
		*ps = '\n';		/* append newline */
		*++ps = '\0';		/* terminate line */
		return (*s == CPMEOF) ? NULL: s;
		}
	while (--maxsize > 0 && (c = getc(fp)) != EOF)
		if ((*ps++ = c) == '\n')
			break;
	*ps = '\0';
	return ((c == EOF && ps == s) ? NULL : s);
	}

/* Put a string to the file pointed to by fp */

fputs(s, fp)
char *s;
int *fp;
	{
	register int c;
	while (c = *s++)
		putc(c, fp);
	}

/* Write the buffer for the file pointed to by fp */

fflush(fp)
int *fp;
	{
	register *rfp, nwrite;
	rfp = fp;			/* load into register */
	if (!(rfp[FLAG] & WRITE) || (rfp[FLAG] & FERR))
		return ERROR;
	nwrite = (rfp[CNT] + 127) / SECSIZE;
	rfp[CNT] = 0;			/* buffer is empty */
	if (write(rfp[FD], rfp[PCH]=rfp[BASE], nwrite) < nwrite) {
		rfp[FLAG] |= FERR;
		return ERROR;
		}
	return NULL;
	}

/* Close the file pointed to by fp */

fclose(fp)
int *fp;
	{
	if (fp[FLAG] & WRITE) { /* if it's an output file... */
		putc(CPMEOF, fp); /* write a ^Z (0x1A) and */
		fflush(fp);	/* write last buffer */
		}
	fp[FLAG] = BUF; /* clear all flags but buffer allocated */
	return close(fp[FD]);	/* free file descriptor */
	}

/* Delete the named disk file */

unlink(filname)
char *filname;
	{
	char fcb[CPMFCBSIZ];
	if (makfcb(filname,fcb) != ERROR) /* make CP/M fcb */
		return (bdos(DELETEF,fcb) == CPMERR) ? ERROR : OK;
	return ERROR;
	}

/* Internal routine to load the buffer for getc */

ccfill(fp)
int *fp;	/* pointer to iob for file */
	{
	register char *fpbuf;
	register int *fpflag, cnt;
	fpflag = &fp[FLAG];
	if (!(*fpflag & READ) || (*fpflag & (FEOF | FERR)))
		return EOF;
	cnt = read(fp[FD], fpbuf = fp[BASE], NSECTS);
	if (cnt <= 0) { 		/* did we read anything? */
		if (cnt == 0)		/* read 0 means EOF */
			*fpflag |= FEOF;
		else			/* read -1 means ERROR */
			*fpflag |= FERR;
		fp[CNT] = 0;
		return EOF;
		}
	fp[CNT] = cnt * SECSIZE - 1;	/* # chars remaining */
	fp[PCH] = fpbuf + 1;		/* point to 2nd char in buffer */
	return *fpbuf;			/* return 1st char in buffer */
	}
/* Open file filname for use specified by rwmode */

open(filname, rwmode)
char *filname;
int rwmode;
	{
	register char *fcb;
	register int fd;
	if ((fd = ccgfd()) == ERROR)	/* get next available fd */
		return ERROR;		/* max no. of files open already */
	fcb = ccgfcb(fd);		/* get fcb for file descriptor fd */
	if (makfcb(filname, fcb) == ERROR)
		return ERROR;		/* bad filename */
	if (bdos(OPENF, fcb) == CPMERR)
		return ERROR;		/* CP/M can't open filname */
	if (rwmode < 0 || rwmode > 1)
		return ERROR;		/* bad read/write mode */
	fcb[FCBFLAG] = ++rwmode;	/* flag: R=01, W=02, R/W=03 */
	return fd;
	}

/* Create a new file */

creat(filname, pmode)
char *filname;
int pmode;		/* protection mode - ignored with CP/M */
	{
	register char *fcb;
	register int fd;
	if ((fd = ccgfd()) == ERROR)	/* get next available fd */
		return ERROR;		/* max # of files open already */
	fcb = ccgfcb(fd);		/* get fcb for file descriptor fd */
	if (makfcb(filname, fcb) == ERROR)
		return ERROR;		/* bad filename */
	bdos(DELETEF, fcb);		/* delete any existing file */
	if (bdos(MAKEF, fcb) == CPMERR)
		return ERROR;		/* CP/M can't create filname */
	fcb[FCBFLAG] = WRITE;
	return fd;
	}

/* Read CP/M logical records */

read(fd, buf, n)
int fd, n;
char *buf;
	{
	register int nread;
	register char *fcb;
	ctlc(); 			/* abort run if ^C was typed */
	if ((fcb = ccgfcb(fd)) == ERROR)
		return ERROR;		/* bad fd */
	if (!(fcb[FCBFLAG] & READ))
		return ERROR;		/* file not open for read */
	if (fcb[FCBFLAG] & FEOF)
		return 0;		/* nothing read - at EOF */
	for (nread = 0; nread < n; ++nread) {
		bdos(SETDMA, buf);	/* set DMA to our buffer */
		if (bdos(READF, fcb)) { /* EOF if != zero */
			fcb[FCBFLAG] |= FEOF;
			break;
			}
		buf += SECSIZE; 	/* next sector in our buffer */
		}
	bdos(SETDMA, DBUFF);		/* reset CP/M default buffer */
	return nread;
	}

/* Write CP/M logical records */

write(fd, buf, n)
int fd, n;
char *buf;
	{
	register int nwritten;
	register char *fcb;
	ctlc(); 			/* abort run if ^C was typed */
	if ((fcb = ccgfcb(fd)) == ERROR)
		return ERROR;		/* bad fd */
	if (!(fcb[FCBFLAG] & WRITE)	/* file not open for write */
	    || (fcb[FCBFLAG] & FERR))	/* previous error */
		return ERROR;
	for (nwritten = 0; nwritten < n; ++nwritten) {
		bdos(SETDMA, buf);	/* set DMA to our buffer */
		if (bdos(WRITEF, fcb)) { /* check for error */
			fcb[FCBFLAG] |= FERR;
			break;
			}
		buf += SECSIZE; 	/* next sector in our buffer */
		}
	bdos(SETDMA, DBUFF);		/* reset CP/M default buffer */
	return nwritten;
	}

/* Close the file with file descriptor fd */

close(fd)
int fd;
	{
	register char *fcb, fcbflag;
	if ((fcb = ccgfcb(fd)) == ERROR)
		return ERROR;		/* bad fd */
	fcbflag = fcb[FCBFLAG]; 	/* save fcb flag */
	fcb[FCBFLAG] = 0;		/* mark fcb closed */
	if (fcbflag & FERR)		/* has error occurred? */
		return ERROR;
	if (fcbflag & WRITE)		/* was file open for write? */
		if (bdos(CLOSEF, fcb) == CPMERR)
			return ERROR;	/* CP/M can't close */
	return NULL;
	}

makfcb(filname, fcb)
char *filname, *fcb;
	{
	register int i, c, padchar;
	register char *rfilname, *rfcb;
	rfilname = filname;		/* save in register */
	rfcb = fcb;
	if (rfilname[1] != ':') 	/* check for drive designator */
		*rfcb++ = 0;		/* default drive */
	else {
		if (!isalpha(*rfilname)) /* drive must be alpha */
			return ERROR;
		*rfcb++ = chupper(*rfilname) - 'A' + 1;
		rfilname += 2;		/* skip drive and ':' */
		}
	padchar = ' ';		/* pad character for short file names */
	for (i=1; i<=8; ++i) {		/* copy file name to fcb */
		if ((c=chupper(*rfilname++)) == 0 || c == '.')
			break;		/* end of file name */
		if (c < ' ')		/* don't allow control chars */
			return ERROR;
		if (c == '*') { 	/* wild card character */
			padchar = '?';	/* fill rest of name with ? */
			break;
			}
		*rfcb++ = c;
		}
	for (; i<=8; ++i)		/* pad short name */
		*rfcb++ = padchar;
	if (c != 0 && c != '.') 	/* if not end of file name... */
		if ((c=*rfilname++) != 0 && c != '.')
			return ERROR;	/* next char must be end */
	if (c)				/* if more chars, get 1st */
		c = chupper(*rfilname++); /* char of file extension */
	padchar = ' ';			/* reset pad character */
	for (; i<=11; ++i) {		/* copy file extension to fcb */
		if (c == 0)		/* end of file extension */
			break;
		if (c < ' ')		/* don't allow control chars */
			return ERROR;
		if (c == '*') { 	/* wild card character */
			padchar = '?';	/* fill rest of ext with ? */
			break;
			}
		*rfcb++ = c;
		c = chupper(*rfilname++);
		}
	if ((c != 0 && i == 11) 	/* if full 11 char filename... */
		|| c == '*')		/* or ended with wild card char */
		c = *rfilname;		/* see what next char is */
	if (c != 0)
		return ERROR;		/* file name too long */
	for (; i<=11; ++i)		/* pad short extension */
		*rfcb++ = padchar;
	for (; i<CPMFCBSIZ; ++i)
		*rfcb++ = 0;		/* fill rest of fcb with zero */
	return OK;
	}

/* Internal routine to get the file control block */
/*	associated with file descriptor fd */

ccgfcb(fd)
int fd;
	{
	if (fd >= 0 && fd < NFILS)
		return (&ccfcb[fd*FCBSIZE]);
	return ERROR;
	}

/* Internal routine to get next available file descriptor */

ccgfd()
	{
	register fd;
	char *fcb;
	fd = 0;
	while ((fcb = ccgfcb(fd)) != ERROR) {
		if (fcb[FCBFLAG] == 0)
			return fd;	/* fcb not in use */
		++fd;
		}
	return ERROR;			/* all fcb's in use */
	}

/* Return a pointer to n bytes of static memory */

malloc(n)
int n;
	{
	auto char sp[1];	/* sp is on the stack , so sp = SP */
	if ((n < 0) || (ccfree + n > sp - 1000))
		return NULL;	/* neg amt or <1000 bytes free space */
	ccfree += n;		/* move free space ptr */
	return (ccfree - n);	/* beginning of allocated space */
	}

/* Check for ^C and kill the program */

ctlc()
	{
	if (bdos(CPMVERS, 0) >= 0x20 && /* CP/M Version 2.x? */
	    bdos(CONIO, 0xFF) == CTLC)	/* did user type ^C ? */
		exit(1);		/* kill run */
	/* else swallow any other character typed */
	}
