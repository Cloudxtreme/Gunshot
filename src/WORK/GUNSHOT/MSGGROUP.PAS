{$I DEFINES.INC}
UNIT MsgGroup;


INTERFACE


PROCEDURE NextMessageGroup;
PROCEDURE PreviousMessageGroup;
FUNCTION  GotAccessToSomeMsgAreas(TheSub: Word): Boolean;


IMPLEMENTATION


USES Globals,MsgHeadr,Shotgun,MiscStr,GotKeys;


PROCEDURE NextMessageGroup;
VAR  TheOne  : Longint;
BEGIN
     TheOne := 999999;
     ASSIGN(FMessageSubs,DATA_Directory+'\MSGAREA.SUB');
     RESET(FMessageSubs);
     REPEAT
           READ(FMessageSubs,MessageSubs);
           IF ((MessageSubs.Sub_Num>CurrentMessageSub) AND (MessageSubs.Sub_Num<TheOne)) THEN
           BEGIN
                IF GotAccessToSomeMsgAreas(MessageSubs.Sub_Num) THEN TheOne := MessageSubs.Sub_Num;
           END;
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);
     IF ((TheOne<>999999) AND (TheOne<>CurrentMessageSub)) THEN
     BEGIN
          CurrentMessageSub := TheOne;
          Header2(CurrentMessageSub,1,True);
     END
     ELSE Header2(CurrentMessageSub,CurrentMessageArea,True);
END;


PROCEDURE PreviousMessageGroup;
VAR  TheOne  : Longint;
BEGIN
     TheOne := 0;
     ASSIGN(FMessageSubs,DATA_Directory+'\MSGAREA.SUB');
     RESET(FMessageSubs);
     REPEAT
           READ(FMessageSubs,MessageSubs);
           IF ((MessageSubs.Sub_Num<CurrentMessageSub) AND (MessageSubs.Sub_Num>TheOne)) THEN
           BEGIN
                IF GotAccessToSomeMsgAreas(MessageSubs.Sub_Num) THEN TheOne := MessageSubs.Sub_Num;
           END;
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);
     IF ((TheOne<>0) AND (TheOne<>CurrentMessageSub)) THEN
     BEGIN
          CurrentMessageSub := TheOne;
          Header2(CurrentMessageSub,1,True);
     END
     ELSE Header2(CurrentMessageSub,CurrentMessageArea,True);
END;


FUNCTION GotAccessToSomeMsgAreas(TheSub: Word): Boolean;
VAR  _FMsgArea : File Of _MessageArea_Record;
     _MsgArea  : _MessageArea_Record;
BEGIN
     ASSIGN(_FMsgArea,DATA_Directory+'\MA'+ZeroPadded(TheSub)+'.DAT');
     {$I-}RESET(_FMsgArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(_FMsgArea,_MsgArea);
                IF ((UserRecord.Security>=_MsgArea.Read_Access) AND GotTheKeys(UserRecord.Tags,_MsgArea.Tags)) THEN
                BEGIN
                     CLOSE(_FMsgArea);
                     GotAccessToSomeMsgAreas := True;
                     Exit;
                END;
          UNTIL EOF(_FMsgArea);
          CLOSE(_FMsgArea);
     END;
     GotAccessToSomeMsgAreas := False;
END;


END.