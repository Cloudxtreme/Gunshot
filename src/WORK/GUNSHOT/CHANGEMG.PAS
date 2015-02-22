{$I DEFINES.INC}
UNIT ChangeMG;


INTERFACE


PROCEDURE ChangeMessageGroup;


IMPLEMENTATION


USES Globals,SBuffer,Screens,MiscStr,GotKeys,BaseInfo,MsgGroup,Shotgun,
     TagArea,ANSIMisc,KeyInput,BsString,ToggMsg,MsgHeadr,Commands;


PROCEDURE ChangeMessageGroup;
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
     FMessageSubs2  : File Of _MessageSub_Record;
     Code           : Integer;
     P1,P2,P3,P4,P5 : Char;

     FUNCTION GotIt(Num: Longint): Boolean;
     BEGIN
          ASSIGN(FMessageSubs,NODE_Directory+'\MMMMMMMM.MMM');
          RESET(FMessageSubs);
          REPEAT
                READ(FMessageSubs,MessageSubs);
                IF MessageSubs.Sub_Num=Num THEN
                BEGIN
                     CLOSE(FMessageSubs);
                     GotIt := True;
                     Exit;
                END;
          UNTIL EOF(FMessageSubs);
          CLOSE(FMessageSubs);
          GotIt := False;
     END;

BEGIN
     Count := 0;
     ASSIGN(FMessageSubs,DATA_Directory+'\MSGAREA.SUB');
     ASSIGN(FMessageSubs2,NODE_Directory+'\MMMMMMMM.MMM');
     REWRITE(FMessageSubs2);
     RESET(FMessageSubs);
     REPEAT
           READ(FMessageSubs,MessageSubs);
           IF GotAccessToSomeMsgAreas(MessageSubs.Sub_Num) THEN
           BEGIN
                INC(Count);
                WRITE(FMessageSubs2,MessageSubs);
           END;
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);
     CLOSE(FMessageSubs2);
     IF Count=0 THEN Exit;
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           ASSIGN(FMessageSubs,NODE_Directory+'\MMMMMMMM.MMM');
           RESET(FMessageSubs);
           SEEK(FMessageSubs,(top-1));
           bot := top-1;
           NumberAreas := 0;
           FOR loop := top TO top+16 DO
           BEGIN
                IF NOT(EOF(FMessageSubs)) THEN
                BEGIN
                     READ(FMessageSubs,MessageSubs);
                     Work := Loop-Top+1;
                     cfa_area[Work]   := MessageSubs.Sub_Name;
                     cfa_areaid[Work] := MessageSubs.Sub_Num;
                     INC(bot);
                     INC(NumberAreas);
                END;
           END;
           CLOSE(FMessageSubs);
           ClearBuffer;
           FOR Loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF Loop<=NumberAreas THEN
                BEGIN
                     AddToBuffer('@MESSAGEGROUPNAME'+Temp,CFA_Area[Loop]);
                     AddToBuffer('@GN'+Temp,_String(CFA_AreaID[Loop]));
                END
                ELSE
                BEGIN
                     AddToBuffer('@MESSAGEGROUPNAME'+Temp,DontSend);
                     AddToBuffer('@GN'+Temp,DontSend);
                END;
           END;
           DisplayGraphicsFile('MGROUPS',True,True,True,True,False);
           DoCommandString('MGROUPS',1);
           DoCommandString('MGROUPS',2);
           DoCommandString('MGROUPS',3);
           DoCommandString('MGROUPS',4);
           DoCommandString('MGROUPS',5);
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
                          system_prompt('',186,True,False);
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
                     header2(Work,1,True);
                     exit_here := 1;
                END;
           END;
     UNTIL (exit_here=1);
END;


END.