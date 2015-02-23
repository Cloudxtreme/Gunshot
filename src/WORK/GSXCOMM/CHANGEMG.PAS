{$I DEFINES.INC}
UNIT ChangeMG;


INTERFACE


PROCEDURE ChangeMessageGroup;


IMPLEMENTATION


USES Globals,MiscStr,Screens,GotKeys,TagArea,Gfx,
     KeyInput,ToggMsg,MsgHeadr,Gunshot,MsgGroup;


PROCEDURE ChangeMessageGroup;
VAR  count         : word;
     OuttaHere     : Boolean;
     C             : Char;
     FMessageSubs2 : File Of _MessageSub_Record;
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
     IF DisplayGraphicFile('MGROUPS',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count := 0;
          ASSIGN(FMessageSubs,NODE_Directory+'\MMMMMMMM.MMM');
          RESET(FMessageSubs);
          REPEAT
                READ(FMessageSubs,MessageSubs);
                INC(Count);
                AddToPickList(MessageSubs.Sub_Name,Count,True);
          UNTIL EOF(FMessageSubs);
          CLOSE(FMessageSubs);
          BeginPickList;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13:  BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                               ASSIGN(FMessageSubs,NODE_Directory+'\MMMMMMMM.MMM');
                               RESET(FMessageSubs);
                               SEEK(FMessageSubs,PickInfo.Current-1);
                               READ(FMessageSubs,MessageSubs);
                               CLOSE(FMessageSubs);
                               Header2(MessageSubs.Sub_Num,1,True);
                          END;
                          OuttaHere := True;
                     END;
                27:  OuttaHere := True;
                END;
          UNTIL OuttaHere;
          KillPickList;
     END;
END;


END.