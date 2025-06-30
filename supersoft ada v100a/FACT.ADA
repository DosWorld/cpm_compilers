procedure FACT is

number : integer;

function FACTORIAL (A : in integer) return integer is
	begin					--compute factorial of A
		if A = 0 then
			return 1;		-- 0! = 1
		elsif A = 1 then
			return 1;		-- 1! = 1
		else
			return A*FACTORIAL(A-1);     -- n! = n * (n-1)!
		end if;
	end FACTORIAL;

begin
	loop
		put("Input an integer between 0 and 7: ");
		get(number);
		if number >= 0 and number < 8 then
			put(factorial(number));
		elsif number < 0 then
			put("Factorial of negative number is undefined");
		elsif number < 18 then
			put("Overflow for this value: ");
			put(factorial(number));
		else
			put("Number is too large for factorial");
		end if;
		newline;
	end loop;
end FACT;
		put(factorial(number));
		else
			put("