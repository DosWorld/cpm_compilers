/************************************************/
/*						*/
/*	 Utility Library for C Compiler 	*/
/* Copyright (c) 1981 Quality Computer Systems	*/
/*						*/
/*		   10/25/81			*/
/************************************************/

/* Note: Uncomment the next line if you are using M80
#include "qstdio.h"
*/

/* index - find the first occurrence of a given character */

index(s, c)
char *s, c;
	{
	while (*s) {
		if (*s == c)
			return s;
		++s;
		}
	return NULL;
	}

/* printf - formatted print routine */
/*	call sequence: printf(format, arg1, ..., argn, nargs) */

printf(nargs)
int nargs;
	{
	register char s[7], *fmt;
	register int c, *arg;
	arg = &nargs;
	fmt = *(arg + nargs);
	arg += (nargs - 1);
	while (c = *fmt++) {
		if (c != '%') { 	/* print ordinary characters */
			putchar(c);
			continue;
			}
		switch (c = *fmt++) {
		case '\0':		/* early end of format */
			return;
		case 'c':		/* print a single character */
			putchar(*arg--);
			continue;
		case 's':		/* print a string */
			fputs(*arg--, stdout);
			continue;
		case 'x':		/* print a hex number */
			fputs(itoh(*arg--, s), stdout);
			continue;
		case 'd':		/* print a decimal number */
			fputs(itoa(*arg--, s), stdout);
			continue;
		default:		/* not a format; just print c */
			putchar(c);
			continue;
			}
		}
	}

/* itoh - convert an integer to a hexidecimal string */

itoh(n, s)
int n;
char s[];
	{
	register int h, i;
	i = 4;
	s[4] = '\0';
	while (i--) {
		h = n & 15;
		s[i] = h + ((h < 10) ? '0' : 'A' - 10);
		n >>= 4;
		}
	return s;
	}

/* itoa - convert an integer to a decimal string */

itoa(n,s)
char *s;
int n;
	{
	register c, sign;
	register char *p, *q;
	if (n == -32768)	/* largest negative number */
		return strcpy(s, "-32768");
	if ((sign = n) < 0)
		n = -n;
	p = q = s;
	do {			/* generate digits in reverse order */
		*p++ = n % 10 + '0';
		} while ((n /= 10) > 0);
	if(sign < 0)
		*p++ = '-';
	*p-- = '\0';
	while (q < p) { 	/* now, reverse digits */
		c = *q;
		*q++ = *p;
		*p-- = c;
		}
	return s;
	}

/* atoi - convert an ASCII decimal string to integer */

atoi(s)
char *s;
	{
	register int n, sign;
	while (isspace(*s))
		++s;
	sign = 1;
	if (*s == '-' || *s == '+')
		sign = (*s++ == '+') ? 1 : -1;
	n = 0;
	while (isdigit(*s))
		n = n * 10 + *s++ - '0';
	return (sign * n);
	}

/* strlen - find the length of a string */

strlen(s)
char *s;
	{
	register int k;
	k = 0;
	while (*s++)
		++k;
	return k;
	}

/* strcat - add second string to end of first string */

strcat(a, b)
char *a, *b;
	{
	register char *p;
	p = a;
	while (*p)		/* find end of first string */
		++p;
	strcpy(p, b);		/* copy 2nd string at end of 1st */
	return a;
	}

/* strcpy - copy second string into first string */

strcpy(a, b)
char *a, *b;
	{
	register char *p;
	p = a;
	while (*p++ = *b++)	/* copy 2nd string into 1st */
		;
	return a;
	}

/* strcmp - compare two strings */

strcmp(s1, s2)
char *s1, *s2;
	{
	while (*s1 == *s2) {
		if (*s1 == '\0')
			return 0;	/* they're equal to the end */
		++s1; ++ s2;
		}
	return (*s1 - *s2);
	}

/* isdigit - return TRUE if character is a decimal digit */

isdigit(c)
char c;
	{
	return (c >= '0' && c <= '9');
	}

/* isupper - return TRUE if character is upper case letter */
isupper(c)
char c;
	{
	return (c >= 'A' && c <= 'Z');
	}

/* islower - return TRUE if character is lower case letter */

islower(c)
char c;
	{
	return (c >= 'a' && c <= 'z');
	}

/* chupper - convert a lower case letter to upper case */

chupper(c)
char c;
	{
	return (islower(c) ? c - 'a' + 'A' : c);
	}

/* chlower - convert an upper case letter to lower case */

chlower(c)
char c;
	{
	return (isupper(c) ? c - 'A' + 'a' : c);
	}

/* toupper - return upper case form of c even if c is not a letter */

toupper(c)
char c;
	{
	return (c - 'a' + 'A');
	}

/* tolower - return lower case form of c even if c is not a letter */

tolower(c)
char c;
	{
	return (c - 'A' + 'a');
	}

/* isalpha - return TRUE if character is a letter */

isalpha(c)
char c;
	{
	return (isupper(c) || islower(c));
	}

/* isalnum - return TRUE if character is a letter or a number */

isalnum(c)
char c;
	{return (isalpha(c) || isdigit(c));}

/* isspace - return TRUE if character is white space */

isspace(c)
char c;
	{
	return (c == ' ' || c == '\t' || c == '\n'
		|| c == '\r' || c == '\f');
	}

/* min - find the minimum of two quantities */

min(i, j)
int i, j;
	{
	return (i < j) ? i : j;
	}

/* max - find the maximum of two quantities */

max(i, j)
int i, j;
	{
	return (i > j) ? i : j;
	}
