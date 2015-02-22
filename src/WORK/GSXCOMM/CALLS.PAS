{$I DEFINES.INC}
UNIT Calls;


INTERFACE


PROCEDURE generate_last_callers;
PROCEDURE get_call_totals;


IMPLEMENTATION


USES Globals,BsString,BsFile,Time,BsTime;


PROCEDURE generate_last_callers;
VAR  loop       : Word;
     loop2      : Word;
     IsHeThere  : Boolean;
     HeIsWhere  : Byte;
BEGIN
     FillChar(callers,SizeOf(callers),chr(0));
     callers[0].name  := UserRecord.name;
     callers[0].alias := UserRecord.alias;
     callers[0].city  := UserRecord.city;
     IF (UserRecord.prov<>'') THEN callers[0].city := callers[0].city+', '+UserRecord.prov;
     callers[0].baud  := BAUDString;
     IF _FileExists(DATA_Directory+'\LASTCALL.DAT') THEN
     BEGIN
          ASSIGN(FCallers,DATA_Directory+'\LASTCALL.DAT');
          RESET(FCallers);
          FOR loop := 1 TO 10 DO READ(FCallers,callers[loop]);
          CLOSE(FCallers);
          IsHeThere := False;
          HeIsWhere := 0;
          FOR Loop := 1 TO 10 DO
          BEGIN
               IF (_UpperCase(Callers[Loop].name)=_UpperCase(Callers[0].name)) THEN
               BEGIN
                    HeIsWhere := Loop;
                    IsHeThere := True;
               END;
          END;
          IF IsHeThere THEN
          BEGIN
               Loop2 := 1;
               FOR Loop := 1 TO 10 DO
               BEGIN
                    IF Loop<>HeIsWhere THEN
                    BEGIN
                         Callers[Loop2] := Callers[Loop];
                         INC(Loop2);
                    END;
               END;
               FOR Loop := 10 DOWNTO 2 DO
                   Callers[Loop] := Callers[Loop-1];
               Callers[1] := Callers[0];
          END
          ELSE
          BEGIN
               FOR Loop := 10 DOWNTO 2 DO
                   Callers[Loop] := Callers[Loop-1];
               Callers[1] := Callers[0];
          END;
          ASSIGN(FCallers,DATA_Directory+'\LASTCALL.DAT');
          REWRITE(FCallers);
          FOR loop := 1 TO 10 DO WRITE(FCallers,callers[loop]);
          CLOSE(FCallers);
     END
     ELSE
     BEGIN
          Callers[1] := Callers[0];
          ASSIGN(FCallers,DATA_Directory+'\LASTCALL.DAT');
          REWRITE(FCallers);
          FOR loop := 1 TO 10 DO WRITE(FCallers,callers[loop]);
          CLOSE(FCallers);
     END;
END;


PROCEDURE get_call_totals;
BEGIN
     ASSIGN(Ftotals,DATA_Directory+'\SYSCALLS.DAT');
     {$I-}
     RESET(Ftotals);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READ(Ftotals,totals);
          CLOSE(FTotals);
          IF totals.date_today<>_ProperDateNoTime THEN
          BEGIN
               totals.date_today  := _ProperDateNoTime;
               totals.today_calls := 1;
          END
          ELSE INC(totals.today_calls);
          INC(totals.total_calls);
          REWRITE(Ftotals);
          WRITE(FTotals,totals);
          CLOSE(Ftotals);
     END
     ELSE
     BEGIN
          totals.date_today  := _ProperDateNoTime;
          totals.total_calls := 1;
          totals.today_calls := 1;
          REWRITE(Ftotals);
          WRITE(FTotals,totals);
          CLOSE(Ftotals);
     END;
END;


END.