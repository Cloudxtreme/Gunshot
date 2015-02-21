{$I DEFINES.INC}
UNIT DLEst;


INTERFACE


FUNCTION dl_estimate(file_size2: longint): string;
FUNCTION dl_estimate2(file_size2: longint): longint;


IMPLEMENTATION


USES Globals;


FUNCTION dl_estimate(file_size2: longint): string;
VAR  work1        : longint;
     work2        : longint;
     work3        : longint;
     work_string1 : string;
     work_string2 : string;
BEGIN
     work1 := trunc(file_size2/cps);    {TOTAL SECONDS}
     work2 := trunc(work1/60);          {NUMBER OF MINUTES}
     work3 := work1-(work2*60);         {NUMBER OF SECONDS}
     STR(work2,work_string1);
     STR(work3,work_string2);
     IF LENGTH(work_string1)=1 THEN work_string1 := '0'+work_string1;
     IF LENGTH(work_string2)=1 THEN work_string2 := '0'+work_string2;
     dl_estimate := work_string1+':'+work_string2;
END;


FUNCTION dl_estimate2(file_size2: longint): longint;
VAR  work1        : longint;
BEGIN
     work1 := trunc(file_size2/cps);    {TOTAL SECONDS}
     dl_estimate2 := work1;
END;


END.