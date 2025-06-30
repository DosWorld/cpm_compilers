BEGIN
    INTEGER hi, n, x, d, z;
    INTEGER ARRAY a[0:200];

    hi := 200;
    x := 0;

    FOR n := hi - 1 STEP -1 UNTIL 1 DO BEGIN
        a[ n ]:=1;
    END;
    
    a[ 1 ] := 2;
    a[ 0 ] := 0;
    
    FOR hi := 200 STEP -1 UNTIL 10 DO BEGIN
        FOR n := hi-1 STEP -1 UNTIL 1 DO BEGIN
            a[ n ] := x MOD n;
            x := 10 * a[ n - 1 ] + x % n;
        END;
        write(1,x)
    END;
    
    text(1,"*Ndone*N");
    ioc(22)
END
FINISH

