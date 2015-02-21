{$I DEFINES.INC}
UNIT ListMsgs;


INTERFACE


PROCEDURE list_messages;


IMPLEMENTATION


USES Globals,MsgHeadr,JamList,MFireUp,SBuffer,Gfx,
     Screens,KeyInput,BsString,GotoMsg,Commands;


PROCEDURE list_messages;
VAR  outtahere     : boolean;
     c             : Char;
     Temp          : String;
     Str1,Str2     : String;
     Work          : Word;
     LABEL           OverAgain;
BEGIN
     Str1 := GetCommandString('MISC',1);
     Str2 := GetCommandString('MISC',2);
     Work := LENGTH(Str1);
     IF LENGTH(Str2)>Work THEN Work := LENGTH(Str2);
     INC(Work);
     Str1 := _PadRight(Str1,Work);
     Str2 := _PadRight(Str2,Work);
     SavedTop := 0;
     OverAgain:
     Header2(CurrentMessageSub,CurrentMessageArea,True);
     JamBase_FireUpMessageBase(MessageAreas.Dos_Name);
     JamBase_ListMessages;
     IF NOT(DisplayGraphicFile('LISTMSGS',False,True,True)) THEN Exit;
     NewPickList(True);
     PickInfo.Current := 0;
     ASSIGN(FMsgList,NODE_Directory+'\MSGLIST.$$$');
     {$I-}
     RESET(FMsgList);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                IF NOT(EOF(FMsgList)) THEN
                BEGIN
                     READ(FMsgList,MsgList);
                     Temp := '{'+_String(Colours.MsgListFrom)+'}'+' '+_PadRight(MsgList.MsgFrom,20)+' '+
                             '{'+_String(Colours.MsgListTo)+'}'+_PadRight(MsgList.MsgTo,20)+' '+
                             '{'+_String(Colours.MsgListSubject)+'}'+_PadRight(MsgList.MsgSubject,20)+' '+
                             '{'+_String(Colours.MsgListPrivate)+'}';
                     IF MsgList.MsgPrivate
                        THEN Temp := Temp+Str1
                        ELSE Temp := Temp+Str2;
                     AddToPickList(Temp,0,True);
                END;
          UNTIL EOF(FMsgList);
          CLOSE(FMsgList);
     END;
     IF (SavedTop<>0) THEN
     BEGIN
          IF (SavedTop<=PickInfo.NumItems) THEN PickInfo.Top := SavedTop;
     END;
     BeginPickList;
     OuttaHere := False;
     REPEAT
           c := UpCase(GetKeyPress);
           IF ((C=#27) OR (C=GetCommandKeyPress('LISTMSGS',5))) THEN
           BEGIN
                OuttaHere := True;
           END
           ELSE IF C=GetCommandKeyPress('LISTMSGS',6) THEN
           BEGIN
                IF (PickInfo.Current<>0) THEN
                BEGIN
                     SavedTop := PickInfo.Top;
                     KillPickList;
                     goto_message(PickInfo.Current);
                     GOTO OverAgain;
                END;
           END;
     UNTIL outtahere;
     KillPickList;
     SavedTop := 0;
END;


END.