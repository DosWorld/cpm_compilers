PROGRAM FACT;

VAR result : INTEGER;

{ enable local variables for recursion }
{$S+ }

FUNCTION factorial( x : INTEGER ) : INTEGER;
    VAR r : INTEGER;
BEGIN
    IF ( x = 0 ) THEN
    BEGIN
        r := 0
    END
    ELSE
    BEGIN
        IF ( x = 1 ) THEN
            r := 1
        ELSE
            r := factorial( x - 1 ) * x;
    END;

    factorial := r;
END;

BEGIN
    result := factorial( 5 );
    WRITELN( 'result should be 120: ', result );
    WRITELN( 'done' );
END.


