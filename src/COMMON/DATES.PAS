{$I DEFINES.INC}
UNIT Dates;


INTERFACE


FUNCTION TranslateDate1(InString: String): String;


IMPLEMENTATION


USES Globals,BsString;


FUNCTION TranslateDate1(InString: String): String;
VAR  T1,T2,T3 : String[4];
     C        : Char;

     PROCEDURE DoSetup;
     BEGIN
          C  := InString[3];
          T1 := _Mid(InString,1,2);
          T2 := _Mid(InString,4,5);
          T3 := _Mid(InString,7,10);
     END;

BEGIN
     CASE System_Info.DateFormat OF
     1:   BEGIN {MM/DD/YYYY}
          END;
     2:   BEGIN {DD/MM/YYYY}
            DoSetup;
            InString := T2+C+T1+C+T3;
          END;
     3:   BEGIN {YYYY/MM/DD}
            DoSetup;
            InString := T3+C+T1+C+T2;
          END;
     END;
     TranslateDate1 := InString;
END;


END.
