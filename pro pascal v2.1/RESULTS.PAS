PROGRAM results (input);

  CONST maxevents = 8;      {maximum events for one entrant}
        colwidth = 5;       {column width on tabulation}

  TYPE  competitor = 100..999;      {range of entrants' numbers}
        score = 0..100;     {possible scores for one event}

  VAR   thiscomp, winner: competitor;
        eventscore: score;  totalscore: integer;
        eventcount: 0..maxevents;
        average, winningav: real;
        listing: text;      {output file for tabulation}

  BEGIN
    winningav := 0;
    assign (listing, 'RESULTS.PRN');  rewrite (listing);

        {process input and produce listing}
    WHILE NOT eof (input) DO
      BEGIN 	{read competitor number}
        read (thiscomp);
        write (listing, thiscomp:5, ' ':3);

        eventcount := 0;  totalscore := 0;
           {now his scores until end-of-line}
        WHILE NOT eoln (input) DO
          BEGIN
            read (eventscore);
            write (listing, eventscore:colwidth);
            totalscore := totalscore + eventscore;
            eventcount := eventcount + 1;
          END     {of processing one result};

            {space across to totals column}
        IF eventcount < maxevents THEN
          write (listing, ' ': (maxevents-eventcount)*colwidth);
            {calculate & print average}
        IF eventcount = 0 THEN average := 0
        ELSE average := totalscore / eventcount;
        writeln (listing, totalscore:8, average:6:2);
            {is average greater than current winner ?}
        IF (eventcount >= 5) AND (average > winningav) THEN
          BEGIN
            winner := thiscomp;    {best so far}
            winningav := average;
          END;
        readln ;
      END     {of processing one competitor};

            {at end of input, print winner}
    writeln (listing);  writeln (listing);   {blank lines}
    IF winningav > 0 THEN
      writeln (listing, '    Winner is number', winner:5,
                        '  with average', winningav:6:2)
    ELSE writeln (listing, '    No entrant qualified as winner');

  END.
