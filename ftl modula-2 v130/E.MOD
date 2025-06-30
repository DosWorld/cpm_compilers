MODULE e2;

FROM Terminal IMPORT Write,WriteString,WriteLn;

CONST
   DIGITS = 200;

VAR
    high, n, x : CARDINAL;
    a : ARRAY [ 0..DIGITS ] OF CARDINAL;

PROCEDURE WriteCardinal( x : CARDINAL );
VAR
    val : ARRAY[0..63] OF CHAR;
    i, l : CARDINAL;
BEGIN
    IF ( x = 0 ) THEN
        Write( '0' );
    ELSE
        l := 0;
        REPEAT
            i := x MOD 10;
            val[ l ] := CHAR( i + 48 );
            l := l + 1;
            x := x DIV 10;
        UNTIL x = 0;
        i := l;
        REPEAT
            Write( val[ i - 1 ] );
            i := i - 1;
        UNTIL i = 0;
    END;
END WriteCardinal;

BEGIN
    high := DIGITS;
    x := 0;

    n := high - 1;
    WHILE n > 0 DO
        a[ n ] := 1;
        n := n - 1;
    END;

    a[ 1 ] := 2;
    a[ 0 ] := 0;

    WHILE high > 9 DO
        high := high - 1;
        n := high;
        WHILE 0 <> n DO
            a[ n ] := x MOD n;
            x := 10 * a[ n - 1 ] + x DIV n;
            n := n - 1;
        END;

        WriteCardinal( x );
    END;

    WriteLn;
    WriteString( 'done' );
    WriteLn;
END e2.

