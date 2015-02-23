{$I DEFINES.INC}
UNIT MultNode;


INTERFACE


PROCEDURE ShowOnlineUsers;
PROCEDURE PageAnotherUser;
PROCEDURE CheckIntrNode;


IMPLEMENTATION


USES BsLog,Screens,KeyInput,Globals,_Mouse,BsMulti,
     Dos,SBuffer,_Pick,Gr2_Bp,BsFile,BsString;


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
          DisplayGraphicFile('URPAGED',True,True,True);
          Get_Enter;
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
VAR  OuttaHere    : Boolean;
     Temp         : String;
     c            : char;
BEGIN
     bsWriteLog('Browsing online users',False);
     AssembleNodeUsers;
     IF DisplayGraphicFile('PAGEUSER',False,True,True) THEN
     BEGIN
          NewPickList(False);
          PickInfo.Current := 0;
          ASSIGN(FNodeF,NODE_Directory+'\ONLINE.$$$');
          RESET(FNodeF);
          REPEAT
                READ(FNodeF,NodeF);
                Temp := '  '+_PadRight(_String(NodeF.Node),8);
                CASE Names.PageUser OF
                0:   Temp := Temp+_PadRight(NodeF.User,30);
                1:   IF NodeF.Alias=''
                        THEN Temp := Temp+_PadRight(NodeF.User,30)
                        ELSE Temp := Temp+_PadRight(NodeF.Alias,30);
                END;
                Temp := Temp+NodeF.Activity;
                AddToPickList(Temp,0,False);
          UNTIL EOF(FNodeF);
          CLOSE(FNodeF);
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13,
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
END;


PROCEDURE PageAnotherUser;
VAR  PageNode   : Word;
     Loop       : Word;
     Code       : Integer;
BEGIN
     bsWriteLog('Paging another user',False);
     System_Prompt('',121);
     Get_Enter;
     IF Fields^[1].Text<>'' THEN
     BEGIN
          VAL(Fields^[1].Text,PageNode,Code);
          IF _FileExists(INTR_Directory+'\NODE'+_String(PageNode)+'.$$$') THEN
          BEGIN
               ASSIGN(FNodeF,INTR_Directory+'\NODE'+_String(PageNode)+'.$$$');
               RESET(FNodeF);
               READ(FNodeF,NodeF);
               CLOSE(FNodeF);
               IF ((NodeF.Available=False) OR (NodeF.PageFlag=0)) THEN
               BEGIN
                    System_Prompt('',178);
                    _Delay(2000);
               END
               ELSE
               BEGIN
                    System_Prompt('',122);
                    Get_Enter;
                    PageUser.UserName   := UserRecord.Name;
                    PageUser.UserAlias  := UserRecord.Alias;
                    PageUser.Message    := Fields^[1].Text;
                    PageUser.LineNumber := NodeNumber;
                    ASSIGN(FPageUser,Gunshot_Directory+'\NODE'+_String(PageNode)+'\PAGE.NOW');
                    REWRITE(FPageUser);
                    WRITE(FPageUser,PageUser);
                    CLOSE(FPageUser);
                    System_Prompt(_String(PageNode),124);
                    _Delay(2000);
               END;
          END
          ELSE
          BEGIN
               System_Prompt('',123);
               Get_Enter;
          END;
     END;
END;


END.
