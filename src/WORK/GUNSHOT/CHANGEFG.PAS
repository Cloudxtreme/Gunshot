{$I DEFINES.INC}
UNIT ChangeFG;


INTERFACE


PROCEDURE ChangeFileGroup;


IMPLEMENTATION


USES Globals,SBuffer,Screens,MiscStr,GotKeys,BaseInfo,Gunshot,TagArea,
     ANSIMisc,KeyInput,ToggMsg,FilHeadr,Commands,FilGroup,BsString;


PROCEDURE ChangeFileGroup;
VAR  count          : word;
     exit_here      : byte;
     top            : word;
     bot            : word;
     loop           : word;
     c              : string;
     work           : word;
     pages          : byte;
     current_p      : byte;
     temp           : string;
     NumberAreas    : Byte;
     cfa_areaid     : Array[1..17] Of Word;
     cfa_area       : Array[1..17] Of String[40];
     Code           : Integer;
     P1,P2,P3,P4,P5 : Char;
     FFileSubs2     : File Of _FileSub_Record;

     FUNCTION GotIt(Num: Longint): Boolean;
     BEGIN
          ASSIGN(FFileSubs,NODE_Directory+'\FFFFFFFF.FFF');
          RESET(FFileSubs);
          REPEAT
                READ(FFileSubs,FileSubs);
                IF FileSubs.Sub_Num=Num THEN
                BEGIN
                     CLOSE(FFileSubs);
                     GotIt := True;
                     Exit;
                END;
          UNTIL EOF(FFileSubs);
          CLOSE(FFileSubs);
          GotIt := False;
     END;

BEGIN
     Count := 0;
     ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
     ASSIGN(FFileSubs2,NODE_Directory+'\FFFFFFFF.FFF');
     REWRITE(FFileSubs2);
     RESET(FFileSubs);
     REPEAT
           READ(FFileSubs,FileSubs);
           IF GotAccessToSomeFileAreas(FileSubs.Sub_Num) THEN
           BEGIN
                INC(Count);
                WRITE(FFileSubs2,FileSubs);
           END;
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);
     CLOSE(FFileSubs2);
     IF Count=0 THEN Exit;
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           ASSIGN(FFileSubs,NODE_Directory+'\FFFFFFFF.FFF');
           RESET(FFileSubs);
           SEEK(FFileSubs,(top-1));
           bot := top-1;
           NumberAreas := 0;
           FOR loop := top TO top+16 DO
           BEGIN
                IF NOT(EOF(FFileSubs)) THEN
                BEGIN
                     READ(FFileSubs,FileSubs);
                     Work := Loop-Top+1;
                     cfa_area[Work]   := FileSubs.Sub_Name;
                     cfa_areaid[Work] := FileSubs.Sub_Num;
                     INC(bot);
                     INC(NumberAreas);
                END;
           END;
           CLOSE(FFileSubs);
           ClearBuffer;
           FOR Loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF Loop<=NumberAreas THEN
                BEGIN
                     AddToBuffer('@FILEGROUPNAME'+Temp,CFA_Area[Loop]);
                     AddToBuffer('@GN'+Temp,_String(CFA_AreaID[Loop]));
                END
                ELSE
                BEGIN
                     AddToBuffer('@FILEGROUPNAME'+Temp,DontSend);
                     AddToBuffer('@GN'+Temp,DontSend);
                END;
           END;
           DisplayGraphicsFile('FGROUPS',True,True,True,True,False);
           DoCommandString('FGROUPS',1);
           DoCommandString('FGROUPS',2);
           DoCommandString('FGROUPS',3);
           DoCommandString('FGROUPS',4);
           DoCommandString('FGROUPS',5);
           system_prompt('',1,false,true);
           P1 := GetCommandKeyPress('MGROUPS',1);
           P2 := GetCommandKeyPress('MGROUPS',2);
           P3 := GetCommandKeyPress('MGROUPS',3);
           P4 := GetCommandKeyPress('MGROUPS',4);
           P5 := GetCommandKeyPress('MGROUPS',5);
           c  := GETKEYORNUMBER(P1+P2+P3+P4+P5,P1);
           IF NOT(numeric) THEN
           BEGIN
                IF c=P5 THEN
                BEGIN
                     exit_here := 1;
                END
                ELSE IF c=P1 THEN
                BEGIN
                     IF current_p<pages THEN
                     BEGIN
                          INC(current_p);
                          top := ((current_p-1)*17)+1;
                     END
                     ELSE
                     BEGIN
                          SendCrLf(1);
                          system_prompt('',187,True,False);
                          Get_Enter;
                     END;
                END
                ELSE IF ((c=P2) AND (current_p>1)) THEN
                BEGIN
                     DEC(current_p);
                     top := ((current_p-1)*17)+1;
                END
                ELSE IF c=P3 THEN
                BEGIN
                     current_p := 1;
                     top := 1;
                END
                ELSE IF c=P4 THEN
                BEGIN
                     current_p := pages;
                     top := ((current_p-1)*17)+1;
                END;
           END
           ELSE
           BEGIN
                VAL(c,work,code);
                IF GotIt(Work) THEN
                BEGIN
                     header(Work,1,True);
                     exit_here := 1;
                END;
           END;
     UNTIL (exit_here=1);
END;


END.