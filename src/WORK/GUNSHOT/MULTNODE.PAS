{$I DEFINES.INC}
UNIT MultNode;


INTERFACE


PROCEDURE ShowOnlineUsers;
PROCEDURE PageAnotherUser(OneLine: Boolean);
PROCEDURE CheckIntrNode;


IMPLEMENTATION


USES BsLog,ANSIMisc,Screens,KeyInput,BsFile,Globals,
     BsMulti,Dos,SBuffer,Commands,BsString;


PROCEDURE PageAnotherUser(OneLine: Boolean);
VAR  PageNode   : Word;
     Loop       : Word;
     Code       : Integer;
BEGIN
     bsWriteLog('Paging another user',False);
     IF OneLine THEN
     BEGIN
          FOR Loop := 1 TO 79 DO WRITECHAR(#08);
          ClrEolANSI;
     END
     ELSE SendCrLf(1);
     System_Prompt('',121,false,True);
     Get_Number(3,'',False);
     IF Input_String<>'' THEN
     BEGIN
          IF OneLine=False THEN
          BEGIN
               SendCrLf(1);
          END
          ELSE
          BEGIN
               FOR Loop := 1 TO 79 DO WRITECHAR(#08);
               ClrEolANSI;
          END;
          VAL(Input_String,PageNode,Code);
          IF _FileExists(INTR_Directory+'\NODE'+_String(PageNode)+'.$$$') THEN
          BEGIN
               ASSIGN(FNodeF,INTR_Directory+'\NODE'+_String(PageNode)+'.$$$');
               RESET(FNodeF);
               READ(FNodeF,NodeF);
               CLOSE(FNodeF);
               IF ((NodeF.Available=False) OR (NodeF.PageFlag=0)) THEN
               BEGIN
                    SendCrLf(1);
                    System_Prompt('',178,false,False);
                    _Delay(2000);
               END
               ELSE
               BEGIN
                    System_Prompt('',122,false,True);
                    Get_String(30,'',True,false,false,False);
                    PageUser.UserName   := UserRecord.Name;
                    PageUser.UserAlias  := UserRecord.Alias;
                    PageUser.Message    := Input_String;
                    PageUser.LineNumber := NodeNumber;
                    ASSIGN(FPageUser,Gunshot_Directory+'\NODE'+_String(PageNode)+'\PAGE.NOW');
                    REWRITE(FPageUser);
                    WRITE(FPageUser,PageUser);
                    CLOSE(FPageUser);
                    IF OneLine=False THEN
                    BEGIN
                         SendCrLf(2);
                    END
                    ELSE
                    BEGIN
                         FOR Loop := 1 TO 79 DO WRITECHAR(#08);
                         ClrEolANSI;
                    END;
                    System_Prompt(_String(PageNode),124,false,False);
                    _Delay(2000);
               END;
          END
          ELSE
          BEGIN
               IF OneLine=False THEN
               BEGIN
                    SendCrLf(1);
                    System_Prompt('',123,True,False);
                    Get_Enter;
               END
               ELSE
               BEGIN
                    System_Prompt('',123,False,True);
                    Get_Enter;
               END;
          END;
     END;
END;


PROCEDURE AssembleNodeUsers;
VAR  Loop    : Word;
     DirInfo : SearchRec;
BEGIN
     ASSIGN(FNodeF,NODE_Directory+'\ONLINE.$$$');
     REWRITE(FNodeF);
     FOR Loop := 1 TO 255 DO
     BEGIN
          FindFirst(INTR_Directory+'\NODE'+_String(Loop)+'.$$$',Anyfile-Directory-VolumeID,DirInfo);
          IF DosError=0 THEN
          BEGIN
               ASSIGN(FNodeF2,INTR_Directory+'\NODE'+_String(Loop)+'.$$$');
               RESET(FNodeF2);
               READ(FNodeF2,NodeF);
               CLOSE(FNodeF2);
               WRITE(FNodeF,NodeF);
          END;
     END;
     CLOSE(FNodeF);
END;


PROCEDURE ShowOnlineUsers;
VAR  exit_here      : byte;
     top            : word;
     c              : char;
     pages          : byte;
     current_p      : byte;
     working_line   : string;
     working_word   : word;
     count          : Word;
     Loop           : Word;
     Loop2          : Word;
     Loop3          : Word;
     messagefile    : text;
     Temp           : String;
     NumberUsers    : Word;
     P1,P2,P3,P4,P5 : Char;
BEGIN
     bsWriteLog('Browsing online users',False);
     AssembleNodeUsers;
     ASSIGN(FNodeF,NODE_Directory+'\ONLINE.$$$');
     RESET(FNodeF);
     count := FileSize(FNodeF);
     CLOSE(FNodeF);
     pages     := (trunc((count-1)/17))+1;
     current_p := 1;
     top       := 1;
     exit_here := 0;
     REPEAT
           NumberUsers := 0;
           ClearBuffer;
           ASSIGN(FNodeF,NODE_Directory+'\ONLINE.$$$');
           RESET(FNodeF);
           SEEK(FNodeF,Top-1);
           FOR loop := 1 TO 17 DO
           BEGIN
                Temp := _String(Loop);
                IF Length(Temp)=1 THEN Temp := '0'+Temp;
                IF NOT(EOF(FNodeF)) THEN
                BEGIN
                     READ(FNodeF,NodeF);
                     INC(NumberUsers);
                     CASE Names.PageUser OF
                     0:   AddToBuffer('@USERSNAME'+Temp,NodeF.User);
                     1:   IF NodeF.Alias=''
                             THEN AddToBuffer('@USERSNAME'+Temp,NodeF.User)
                             ELSE AddToBuffer('@USERSNAME'+Temp,NodeF.Alias);
                     END;
                     AddToBuffer('@USERSACTIVITY'+Temp,NodeF.Activity);
                     AddToBuffer('@ND'+Temp,_String(NodeF.Node));
                END
                ELSE
                BEGIN
                     AddToBuffer('@USERSACTIVITY'+Temp,DontSend);
                     AddToBuffer('@USERSNAME'+Temp,DontSend);
                     AddToBuffer('@ND'+Temp,DontSend);
                END;
           END;
           CLOSE(FNodeF);
           DisplayGraphicsFile('PAGEUSER',True,True,True,True,False);
           DoCommandString('PAGEUSER',1);
           DoCommandString('PAGEUSER',2);
           DoCommandString('PAGEUSER',3);
           DoCommandString('PAGEUSER',4);
           DoCommandString('PAGEUSER',5);
           system_prompt('',1,false,True);
           P1 := GetCommandKeyPress('PAGEUSER',1);
           P2 := GetCommandKeyPress('PAGEUSER',2);
           P3 := GetCommandKeyPress('PAGEUSER',3);
           P4 := GetCommandKeyPress('PAGEUSER',4);
           P5 := GetCommandKeyPress('PAGEUSER',5);
           c  := Get_Menu_Selection(P1+P2+P3+P4+P5,P1);
           IF c=P5 THEN
           BEGIN
                exit_here := 1;
           END
           ELSE IF ((c=P1) AND (current_p<pages)) THEN
           BEGIN
                INC(current_p);
                top := ((current_p-1)*17)+1;
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
     UNTIL (exit_here=1);
END;


PROCEDURE CheckIntrNode;
BEGIN
     IF _FileExists(NODE_Directory+'\PAGE.NOW') THEN
     BEGIN
          bsWriteLog('Responding to a page',False);
          ASSIGN(FPageUser,NODE_Directory+'\PAGE.NOW');
          RESET(FPageUser);
          READ(FPageUser,PageUser);
          CLOSE(FPageUser);
          ERASE(FPageUser);
          ClearBuffer;
          CASE Names.UrPaged OF
          0:   AddToBuffer('@USERSNAME',PageUser.UserName);
          1:   IF PageUser.UserAlias=''
                  THEN AddToBuffer('@USERSNAME',PageUser.UserName)
                  ELSE AddToBuffer('@USERSNAME',PageUser.UserAlias);
          END;
          AddToBuffer('@USERSMESSAGE',PageUser.Message);
          AddToBuffer('@NODE',_String(PageUser.LineNumber));
          DisplayGraphicsFile('URPAGED',True,True,True,True,False);
          Get_Enter;
     END;
END;


END.
