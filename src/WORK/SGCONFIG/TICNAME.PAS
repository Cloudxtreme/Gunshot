{$I DEFINES.INC}
UNIT TicName;


INTERFACE


FUNCTION NextTicName(Path: String): String;


IMPLEMENTATION


USES Dos,BsString,BsFile;


FUNCTION ProperDate: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     PackTime(DT,WorkDate);
     ProperDate := WorkDate;
END;


FUNCTION SixDigits(InLong: Longint): String;
VAR  Work  : String;
     Work2 : String;
     LLen  : Word;
BEGIN
     Work := _String(InLong);
     LLen := LENGTH(Work);
     IF (LLen>=6) THEN
     BEGIN
          Work := _Mid(Work,LLen-5,LLen);
     END
     ELSE
     BEGIN
          FillChar(Work2,SizeOf(Work2),'0');
          Work2[0] := #6;
          Move(Work[1],Work2[6-LLen+1],LLen);
          Work := Work2;
     END;
     SixDigits := Work;
END;


FUNCTION NextTicName(Path: String): String;
VAR  Ok      : Boolean;
     TheDate : Longint;
     Temp    : String;
BEGIN
     TheDate := ProperDate;
     Ok := False;
     REPEAT
           Temp := 'TK'+SixDigits(TheDate)+'.TIC';
           IF NOT(_FileExists(Path+Temp)) THEN
           BEGIN
                NextTicName := Path+Temp;
                Exit;
           END
           ELSE INC(TheDate);
     UNTIL Ok;
END;


END.
