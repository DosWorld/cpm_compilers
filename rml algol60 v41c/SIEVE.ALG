BEGIN
    INTEGER o, limit, i, k, count, prime;
    INTEGER ARRAY flags[0:8190];

    limit := 8190;

    FOR o := 1 STEP 1 UNTIL 10 DO BEGIN
        FOR i := 0 STEP 1 UNTIL limit DO BEGIN
            flags[i] := 1;
        END;

        count := 0;
        FOR i := 0 STEP 1 UNTIL limit DO BEGIN
            IF flags[i] = 1 THEN
            BEGIN
                prime := i + i + 3;
                IF prime < limit THEN BEGIN
                    FOR k := (i + prime) STEP prime UNTIL limit DO BEGIN
                        flags[k] := 0;
                    END;
                END;
                count := count + 1;
            END;
        END;
    END;

    write(1,count);
    text(1," primes*N");
    ioc(22);
END
FINISH
