{$I DEFINES.INC}
UNIT QWKMsgs;


INTERFACE


PROCEDURE JamBase_QWKMessageHeaderFirst (Number: Longint);
PROCEDURE JamBase_QWKMessageHeaderNext  (Number: Longint);
PROCEDURE JamBase_QWKMessage            (Number: Longint);
PROCEDURE JamBase_OpenQWKBase;
PROCEDURE JamBase_CloseQWKBase;
PROCEDURE JamBase_UpdateQWKPointers;


IMPLEMENTATION


USES Globals,MkMsgAbs,MkOpen,MkString,Toggle,KeyInput,BsString,
     MiscMsg,ErrorLog,MiscStr,Time,FMode,GoodLang,Special;


PROCEDURE JamBase_OpenQWKBase;
VAR  AreaType    : Char;
     MaxMsgs     : Word;
BEGIN
     HighestQWKPointer := 0;
     CASE MessageAreas.Base_Type OF
     1:  AreaType := 'J';
     2:  AreaType := 'S';
     3:  AreaType := 'F';
     END;
     QWKLastReads.Area := AreaType+CurrentMessageBase;
     IF MessageAreas.MaxMsgs=0 THEN MaxMsgs := 1000
                               ELSE MaxMsgs := MessageAreas.MaxMsgs;
     QWKLastReads.MaxMsgs := MaxMsgs;
     OpenOrCreateMsgArea(Msg,AreaType+CurrentMessageBase,MaxMsgs);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


PROCEDURE JamBase_CloseQWKBase;
BEGIN
     CloseMsgArea(Msg);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
     IF HighestQWKPointer<>0 THEN
     BEGIN
          QWKLastReads.DoPointer  := True;
          QWKLastReads.DoReceived := False;
          IF HighestQWKPointer>=UserLastReadMSG THEN
          BEGIN
               QWKLastReads.DoPointer  := True;
               QWKLastReads.Pointer    := HighestQWKPointer;
               QWKLastReads.DoReceived := False;
               WRITE(FQWKLastReads,QWKLastReads);
          END;
     END;
END;


PROCEDURE JamBase_UpdateQWKPointers;
VAR  LastPath : String[51];
     MaxMsgs  : Word;
BEGIN
     LastPath := '';
     ASSIGN(FQWKLastReads,NODE_Directory+'\QWKREAD.$$$');
     {$I-}RESET(FQWKLastReads);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF NOT(EOF(FQWKLastReads)) THEN
          BEGIN
               StartToggle(FileSize(FQWKLastReads));
               REPEAT
                     READ(FQWKLastReads,QWKLastReads);
                     DoToggle;
                     IF (LastPath<>QWKLastReads.Area) THEN
                     BEGIN
                          IF (LastPath<>'') THEN
                          BEGIN
                               CloseMsgArea(Msg);
                               IF IOResult=0 THEN;
                               FileMode := SetFileMode;
                               IF QWKLastReads.MaxMsgs=0 THEN MaxMsgs := 1000
                                                         ELSE MaxMsgs := QWKLastReads.MaxMsgs;
                               OpenOrCreateMsgArea(Msg,QWKLastReads.Area,MaxMsgs);
                          END
                          ELSE
                          BEGIN
                               IF QWKLastReads.MaxMsgs=0 THEN MaxMsgs := 1000
                                                         ELSE MaxMsgs := QWKLastReads.MaxMsgs;
                               OpenOrCreateMsgArea(Msg,QWKLastReads.Area,MaxMsgs);
                          END;
                          LastPath := QWKLastReads.Area;
                     END;
                     Msg^.SeekFirst(QWKLastReads.Pointer);
                     IF Msg^.SeekFound THEN
                     BEGIN
                          IF QWKLastReads.DoReceived THEN
                          BEGIN
                               Msg^.MsgStartUp;
                               Msg^.SetRcvd(True);
                               Msg^.ReWriteHdr;
                          END;
                          IF QWKLastReads.DoPointer THEN
                             Msg^.SetLastRead(UserRecord.Name,UserRecord.User_Number,QWKLastReads.Pointer);
                     END;
               UNTIL EOF(FQWKLastReads);
          END;
          CLOSE(FQWKLastReads);
          IF (LastPath<>'') THEN CloseMsgArea(Msg);
     END;
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
     EndToggle;
END;


PROCEDURE JamBase_QWKMessage(Number: Longint);
VAR  FastBaseTxt  : String;
     MsgText      : MessageTextLines;
     Loop         : Word;
     Loop2        : Word;
     Temp         : String;
     CharCount    : Word;
     Counter      : Word;
     Running      : Word;
BEGIN
     CurrentMessage := Number;
     FastBaseHdr.MsgSubject  := Msg^.GetSubj;
     FastBaseHdr.MsgTime     := TimeToLongint(Msg^.GetTime);
     FastBaseHdr.MsgDate     := Msg^.GetDate;
     {CREATE THE MESSAGE TEXT}
     CharCount := 1;
     Counter   := 0;
     Running   := 129;
     FillChar(QWKTextBuffer^[129],128,0);
     {#227 - Terminator}
     Msg^.MsgTxtStartUp;
     REPEAT
           MsgText.Line[1] := #32;
           MsgText.Line := Msg^.GetString(80);
           MsgText.Line := Remove_Special(MsgText.Line);
           IF MessageAreas.CleanLanguage=1 THEN MsgText.Line := Clean_Language(MsgText.Line);
           IF ((MsgText.Line[1]<>#1) AND (Pos('SEEN-BY: ',MsgText.Line)<>1)) THEN
           BEGIN
                IF MsgText.Line<>'' THEN
                BEGIN
                     FOR Loop2 := 1 TO LENGTH(MsgText.Line) DO
                     BEGIN
                          QWKTextBuffer^[Running] := MsgText.Line[Loop2];
                          INC(CharCount);
                          INC(Running);
                          IF Running>MaxMsgBuffer THEN DoErrorLog(29,'');
                          IF CharCount=129 THEN
                          BEGIN
                               INC(Counter);
                               CharCount := 1;
                               FillChar(QWKTextBuffer^[Running],128,0);
                          END;
                     END;
                END;
                QWKTextBuffer^[Running] := CHR(227);
                INC(CharCount);
                INC(Running);
                IF Running>MaxMsgBuffer THEN DoErrorLog(29,'');
                IF CharCount=129 THEN
                BEGIN
                     INC(Counter);
                     CharCount := 1;
                     FillChar(QWKTextBuffer^[Running],128,0);
                END;
           END;
     UNTIL Msg^.EOM;
     IF CharCount<>1 THEN
     BEGIN
          FillChar(QWKTextBuffer^[Running],128,0);
          INC(Counter);
     END;
     {CREATE THE MESSAGE HEADER}
     FillChar(QWKHeaders,128,#32);
     IF LENGTH(FastBaseHdr.MsgTo)>25
        THEN Move(FastBaseHdr.MsgTo[1],QWKHeaders.MsgTo[1],25)
        ELSE Move(FastBaseHdr.MsgTo[1],QWKHeaders.MsgTo[1],Length(FastBaseHdr.MsgTo));
     IF LENGTH(FastBaseHdr.MSGFrom)>25
        THEN Move(FastBaseHdr.MSGFrom[1],QWKHeaders.MSGFrom[1],25)
        ELSE Move(FastBaseHdr.MSGFrom[1],QWKHeaders.MSGFrom[1],Length(FastBaseHdr.MSGFrom));
     IF LENGTH(FastBaseHdr.MSGSubject)>25
        THEN Move(FastBaseHdr.MSGSubject[1],QWKHeaders.MSGSubj[1],25)
        ELSE Move(FastBaseHdr.MSGSubject[1],QWKHeaders.MSGSubj[1],Length(FastBaseHdr.MSGSubject));
     IF FastBaseHdr.Priv THEN
     BEGIN
          IF Number>UserLastReadMSG
             THEN QWKHeaders.MSGStatus := '+'
             ELSE QWKHeaders.MSGStatus := '*';
     END
     ELSE
     BEGIN
          IF Number>UserLastReadMSG
             THEN QWKHeaders.MSGStatus := ' '
             ELSE QWKHeaders.MSGStatus := '-';
     END;
     QWKHeaders.MSGKilled := 225;
     Temp := _PadRight(_String(Number),7);
     Move(Temp[1],QWKHeaders.MSGNumber[1],7);
     QWKHeaders.MSGReference[1] := '0';
     QWKHeaders.MSGConf := MessageAreas.AreaId;
     Temp := _PadRight(_String(Counter+1),6);
     Move(Temp[1],QWKHeaders.MSGNumText[1],6);
     Temp := _Mid(FastBaseHdr.MsgDate,1,2)+'-'+
             _Mid(FastBaseHdr.MsgDate,3,4)+'-'+
             _Mid(FastBaseHdr.MsgDate,5,6);
     Move(Temp[1],QWKHeaders.MSGDate[1],8);
     Temp := LongToStringTime(FastBaseHdr.MsgTime);
     Move(Temp[1],QWKHeaders.MSGTime[1],5);
     Move(QWKHeaders,QWKTextBuffer^[1],128);
     BlockWrite(Messages_Dat,QWKTextBuffer^[1],(Counter+1)*128);
     HighestQWKPointer := MsgIndex^[Number];
     IF IsYours THEN
     BEGIN
          QWKLastReads.DoPointer  := False;
          QWKLastReads.DoReceived := True;
          QWKLastReads.Pointer    := MsgIndex^[Number];
          WRITE(FQWKLastReads,QWKLastReads);
     END;
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


PROCEDURE JamBase_QWKMessageHeaderFirst(Number: Longint);
BEGIN
     CanKill := False;
     IsYours := False;
     CanSee  := False;
     CurrentMessage := Number;
     Msg^.SeekFirst(MsgIndex^[Number]);
     Msg^.MsgStartUp;
     FastBaseHdr.MsgFrom := Msg^.GetFrom;
     FastBaseHdr.MsgTo   := Msg^.GetTo;
     FastBaseHdr.Priv    := Msg^.IsPriv;
     FastBase_Yours;
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


PROCEDURE JamBase_QWKMessageHeaderNext(Number: Longint);
BEGIN
     CanKill := False;
     IsYours := False;
     CanSee  := False;
     CurrentMessage := Number;
     Msg^.SeekNext;
     Msg^.MsgStartUp;
     FastBaseHdr.MsgFrom := Msg^.GetFrom;
     FastBaseHdr.MsgTo   := Msg^.GetTo;
     FastBaseHdr.Priv    := Msg^.IsPriv;
     FastBase_Yours;
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
END;


END.
