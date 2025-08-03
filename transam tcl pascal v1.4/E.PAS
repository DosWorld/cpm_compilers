PROGRAM E;

CONST
   DIGITS = 200;

TYPE
    ARRAYTYPE = ARRAY[ 0..DIGITS ] OF INTEGER;

VAR
    HIGH, N, X, D, VAL : INTEGER;
    A : ARRAYTYPE;

BEGIN
    HIGH := DIGITS;
    X := 0;

    N := HIGH - 1;
    REPEAT
        A[ N ] := 1;
        N := N - 1;
    UNTIL 1 = N;

    A[ 1 ] := 2;
    A[ 0 ] := 0;

    REPEAT
        HIGH := HIGH - 1;
        N := HIGH;
        REPEAT
            D := X DIV N;
            A[ N ] := X - ( D * N );
            N := N - 1;
            X := 10 * A[ N ] + D;
        UNTIL N = 0;

        WRITE( X : 0 );
    UNTIL 9 = HIGH;

    WRITELN;
    WRITELN( 'done' );
END.

