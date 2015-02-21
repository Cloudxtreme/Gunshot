{$I DEFINES.INC}
UNIT MsgHeadr;


INTERFACE


PROCEDURE header2(Sub,Area: Word; Direction: Boolean);


IMPLEMENTATION


USES Globals,ErrorLog,BsString,MiscStr,GotKeys,Shotgun;


PROCEDURE header2(Sub,Area: Word; Direction: Boolean);
VAR  count      : word;
     GotIt      : Boolean;
     Duck       : Longint;
     OldArea    : Word;
     OldSub     : Word;
     OldMarea   : _MessageArea_Record;
     OldMSub    : _MessageSub_Record;

     PROCEDURE MoveArea;
     BEGIN
          CASE Direction OF
          True  : BEGIN
                       INC(CurrentMessageArea);
                       IF CurrentMessageArea>Count THEN CurrentMessageArea := 1;
                  END;
          False : BEGIN
                       DEC(CurrentMessageArea);
                       IF CurrentMessageArea=0 THEN CurrentMessageArea := Count;
                  END;
          END;
     END;

BEGIN
     OldArea              := CurrentMessageArea;
     OldSub               := CurrentMessageSub;
     OldMarea             := MessageAreas;
     OldMSub              := MessageSubs;
     MessageSubs.Sub_Num  := 0;
     MessageSubs.Sub_Name := 'All Areas';
     CurrentMessageArea   := Area;
     CurrentMessageSub    := Sub;

     {Load in the sub}
     IF CurrentMessageSub<>0 THEN
     BEGIN
          ASSIGN(FMessageSubs,DATA_Directory+'\MSGAREA.SUB');
          RESET(FMessageSubs);
          REPEAT
                READ(FMessageSubs,MessageSubs);
          UNTIL ((EOF(FMessageSubs)) OR (MessageSubs.Sub_Num=CurrentMessageSub));
          CLOSE(FMessageSubs);
          {Sub does NOT exist}
          IF (MessageSubs.Sub_Num<>CurrentMessageSub) THEN
          BEGIN
               DoErrorLog(30,_String(CurrentMessageSub));
               CurrentMessageArea := OldArea;
               CurrentMessageSub  := OldSub;
               MessageAreas       := OldMarea;
               MessageSubs        := OldMSub;
               Exit;
          END;
     END;

     {Crunch time}
     GotIt  := False;
     ASSIGN(FMessageArea,DATA_Directory+'\MA'+ZeroPadded(CurrentMessageSub)+'.DAT');
     RESET(FMessageArea);
     Count := FileSize(FMessageArea);

     {Make sure we aren't at 0 or over the number of areas}
     IF CurrentMessageArea>count THEN CurrentMessageArea := 1;
     IF CurrentMessageArea=0 THEN CurrentMessageArea := count;

     Duck := 0;
     REPEAT
           Seek(FMessageArea,(CurrentMessageArea-1));
           read(FMessageArea,MessageAreas);
           INC(Duck);
           IF GotTheKeys(UserRecord.Tags,MessageAreas.Tags) THEN
           BEGIN
                IF UserRecord.Security>=MessageAreas.Read_Access
                   THEN GotIt := True
                   ELSE MoveArea;
           END
           ELSE MoveArea;
           {No areas, so go back to the original group/area}
           IF (Duck>Count+1) THEN
           BEGIN
                DoErrorLog(31,_String(CurrentMessageArea));
                CurrentMessageArea := OldArea;
                CurrentMessageSub  := OldSub;
                MessageAreas       := OldMarea;
                MessageSubs        := OldMSub;
                GotIt              := True;
           END;
     UNTIL GotIt;
     CLOSE(FMessageArea);
END;


END.