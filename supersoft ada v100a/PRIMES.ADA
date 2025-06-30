procedure prime_factors is

k, prime : integer;
size : constant integer := 8190;
flags : array (0..size) of boolean;
count : integer;

begin
	put("10 iterations");newline;
	for iter in 1..10 loop
		count := 0;
		for i in 0..size loop
			flags(i) := true;
		end loop;
		for i in 0..size loop
			if flags(i) then
				prime := i + i + 3;
				k := i + prime;
				while k <= size loop
					flags(k) := false;
					k := k + prime;
				end loop;
				count := count + 1;
			end if;
		end loop;
	end loop;
	put(count);
	put(" primes");
	put(character(7));
	newline;

end prime_factors;
1;
			end if;
		end loop;
	