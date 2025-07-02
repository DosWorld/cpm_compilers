PROGRAM figures (input,output);

      {This is a short program to illustrate random-access
       reading from a file.  A workfile is written with the
       values 'zero' to 'nineteen' in character form in the
       appropriate records;  the file is then reset, and is
       accessed to retrieve the records randomly on request.}

TYPE  string12 = string[12];

VAR   wf: FILE OF string12;

PROCEDURE writefile;

  PROCEDURE writewf (fstr: string12);
    BEGIN
      write (wf,fstr);
    END;

  BEGIN
    writewf ('zero');   writewf ('one');   writewf ('two');
    writewf ('three');  writewf ('four');  writewf ('five');
    writewf ('six');    writewf ('seven'); writewf ('eight');
    writewf ('nine');   writewf ('ten');   writewf ('eleven');
    writewf ('twelve'); writewf ('thirteen');
    writewf ('fourteen');  writewf ('fifteen');
    writewf ('sixteen');   writewf ('seventeen');
    writewf ('eighteen');  writewf ('nineteen');
  END  {writefile};

PROCEDURE access;
  VAR  num: integer;  exit: boolean;
  BEGIN
    exit := false;
    REPEAT
      write ('Which number (0 to 19) - ');  readln (num);
      IF num < 0 THEN exit := true
      ELSE
        IF num > 19 THEN writeln ('Out of range')
        ELSE
          BEGIN
            seek (wf,num);  writeln (wf^:28);
          END;
    UNTIL exit;
  END  {access};

BEGIN
  rewrite (wf);
  writefile;
  reset (wf);
  access;
END.
