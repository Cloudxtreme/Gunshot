{$I DEFINES.INC}
UNIT Jam;


INTERFACE


PROCEDURE PackJam;


IMPLEMENTATION


USES Globals,MkOpen,MkMsgAbs,MkGlobT,Crt,Gunshot,
     FMode,BsFile,BsString,BsVideo,Common;


FUNCTION LastAppropriateJam(LRP: Longint): Longint;
VAR  Work    : Longint;
     Loop    : Longint;
BEGIN
     Work    := 1;
     FOR Loop := 1 TO NumMsgs DO
     BEGIN
       IF Indexes[Loop]<=LRP THEN Work := Loop;
     END;
     LastAppropriateJam := Work;
END;


PROCEDURE LastReadJam;
TYPE Last_Read = RECORD
     NameCrc   : LongInt;
     UserNum   : LongInt;
     LastRead  : LongInt;
     HighRead  : LongInt;
     END;
VAR  LastRead        : Last_Read;
     FLastReadSource : File Of Last_Read;
     FLastReadDest   : File Of Last_Read;
BEGIN
     ASSIGN(FLastReadSource,BasePath+'$$GSPACK.JLR');
     {$I-}RESET(FLastReadSource);{$I+}
     IF IOResult=0 THEN
     BEGIN
       ASSIGN(FLastReadDest,MessageAreas.Dos_Name+'.JLR');
       REWRITE(FLastReadDest);
       REPEAT
         IF NOT(EOF(FLastReadSource)) THEN
         BEGIN
           READ(FLastReadSource,LastRead);
           LastRead.LastRead := LastAppropriateJam(LastRead.LastRead);
           LastRead.HighRead := LastRead.LastRead;
           WRITE(FLastReadDest,LastRead);
         END;
       UNTIL EOF(FLastReadSource);
       CLOSE(FLastReadSource);
       CLOSE(FLastReadDest);
     END;
END;


PROCEDURE PackJam;
VAR  PriorWrap : Boolean;
     TmpStr    : String;
     TmpAddr   : AddrType;
     X         : Byte;
     Y         : Byte;
     IsRcvd    : Boolean;
     IsPriv    : Boolean;
     Loop      : Word;
     EOM       : Boolean;
     TmpDate   : String;
LABEL            SkipIt,ProcessIt;
BEGIN
     BasePath := _GetFilePath(MessageAreas.Dos_Name);
     IF MessageAreas.MaxMsgs=0 THEN MessageAreas.MaxMsgs := 1000;
     IF ((OverLimit) AND (MessageAreas.Area_Type<20)) THEN
     BEGIN
       OpenOrCreateMsgArea(SourceBase,'J'+MessageAreas.Dos_Name,MessageAreas.MaxMsgs);
       IF SourceBase^.NumberOfMsgs<=MessageAreas.MaxMsgs THEN
       BEGIN
         CloseMsgArea(SourceBase);
         Exit;
       END;
       CloseMsgArea(SourceBase);
     END;
     NumMsgs := 0;
     OrigBytes := OrigBytes+_FileSize(MessageAreas.Dos_Name+'.JDT');
     OrigBytes := OrigBytes+_FileSize(MessageAreas.Dos_Name+'.JDX');
     OrigBytes := OrigBytes+_FileSize(MessageAreas.Dos_Name+'.JHR');
     OrigBytes := OrigBytes+_FileSize(MessageAreas.Dos_Name+'.JLR');
     IF _FileExists(MessageAreas.Dos_Name+'.JDT') THEN _RenameFile(MessageAreas.Dos_Name+'.JDT',BasePath+'$$GSPACK.JDT');
     IF _FileExists(MessageAreas.Dos_Name+'.JDX') THEN _RenameFile(MessageAreas.Dos_Name+'.JDX',BasePath+'$$GSPACK.JDX');
     IF _FileExists(MessageAreas.Dos_Name+'.JHR') THEN _RenameFile(MessageAreas.Dos_Name+'.JHR',BasePath+'$$GSPACK.JHR');
     IF _FileExists(MessageAreas.Dos_Name+'.JLR') THEN _RenameFile(MessageAreas.Dos_Name+'.JLR',BasePath+'$$GSPACK.JLR');
     OpenOrCreateMsgArea(SourceBase,'J'+BasePath+'$$GSPACK',MessageAreas.MaxMsgs);
     OpenOrCreateMsgArea(DestBase,'J'+MessageAreas.Dos_Name,MessageAreas.MaxMsgs);
     DestBase^.LockMsgBase;
     Temp := 'AREA: '+_PadRight(MessageAreas.Area_Name,41);           WRITE(Temp);
     Temp := 'MSGS: '+_PadRight(_String(SourceBase^.NumberOfMsgs),5); WRITE(Temp);
     Temp := 'KEEP: '+_PadRight(_String(MessageAreas.MaxMsgs),5);     WRITE(Temp);
     X := WhereX;
     Y := WhereY+8;
     CASE MessageAreas.Area_Type OF
     1..9:   DestBase^.SetMailType(mmtNormal);
     10..19: DestBase^.SetMailType(mmtEchoMail);
     20..29: DestBase^.SetMailType(mmtNetMail);
     30..39: DestBase^.SetMailType(mmtNetMail);
     END;
     SourceBase^.SeekFirst(1);
     IF NOT(SourceBase^.SeekFound) THEN SourceBase^.SeekNext;
     IF ((SourceBase^.NumberOfMsgs>MessageAreas.MaxMsgs) AND (MessageAreas.Area_Type<20)) THEN
     BEGIN
       FOR Loop := 1 TO (SourceBase^.NumberOfMsgs-MessageAreas.MaxMsgs) DO
       BEGIN
         SourceBase^.SeekNext;
       END;
     END;
     FastWrite('Wait!',Y,X,7);
     WHILE SourceBase^.SeekFound DO
     BEGIN
       {Start It Up}
       SourceBase^.MsgStartUp;
       SourceBase^.MsgTxtStartUp;
       TmpDate := SourceBase^.GetDate;
       IsRcvd  := SourceBase^.IsRcvd;
       IsPriv  := SourceBase^.IsPriv;
       IF (MessageAreas.Area_Type<20) THEN
       BEGIN
         IF ((CleanAllReceived) AND (IsRcvd)) THEN GOTO SkipIt;
         IF ((CleanPrivReceived) AND (IsRcvd) AND (IsPriv)) THEN GOTO SkipIt;
         IF OutOfDate(TmpDate) THEN GOTO SkipIt;
         IF PriorToDate(TmpDate) THEN GOTO SkipIt;
       END;
       DestBase^.StartNewMsg;
       {Message Index}
       INC(NumMsgs);
       Indexes[NumMsgs] := SourceBase^.GetMsgNum;
       {Message Header}
       SourceBase^.GetDest      (TmpAddr);
       DestBase^.SetDest        (TmpAddr);
       SourceBase^.GetOrig      (TmpAddr);
       DestBase^.SetOrig        (TmpAddr);
       DestBase^.SetFrom        (SourceBase^.GetFrom);
       DestBase^.SetTo          (SourceBase^.GetTo);
       DestBase^.SetSubj        (SourceBase^.GetSubj);
       DestBase^.SetRefer       (SourceBase^.GetRefer);
       DestBase^.SetSeeAlso     (SourceBase^.GetSeeAlso);
       DestBase^.SetDate        (TmpDate);
       DestBase^.SetTime        (SourceBase^.GetTime);
       DestBase^.SetLocal       (SourceBase^.IsLocal);
       DestBase^.SetRcvd        (IsRcvd);
       DestBase^.SetPriv        (IsPriv);
       DestBase^.SetCrash       (SourceBase^.IsCrash);
       DestBase^.SetKillSent    (SourceBase^.IsKillSent);
       DestBase^.SetSent        (SourceBase^.IsSent);
       DestBase^.SetFAttach     (SourceBase^.IsFAttach);
       DestBase^.SetFileReq     (SourceBase^.IsFileReq);
       DestBase^.SetEcho        (SourceBase^.IsEchoed);
       {Message Text}
       REPEAT
         TmpStr    := SourceBase^.GetString(80);
         PriorWrap := SourceBase^.WasWrap;
         EOM       := SourceBase^.Eom;
         IF EOM THEN
         BEGIN
           IF (_RemoveSpaces(TmpStr)<>'') THEN GOTO ProcessIt;
         END
         ELSE
         BEGIN
           ProcessIt:
           IF ((TmpStr[1]=#1) AND (NOT PriorWrap)) THEN
           BEGIN
             IF NOT(StripKludges) THEN DestBase^.DoKludgeLn(TmpStr);
           END
           ELSE IF ((Pos('SEEN-BY:',TmpStr)=1) AND (NOT PriorWrap)) THEN
           BEGIN
             IF NOT(StripKludges) THEN DestBase^.DoString(TmpStr);
           END
           ELSE
           BEGIN
             IF PriorWrap THEN DestBase^.DoString(TmpStr)
                          ELSE DestBase^.DoStringLn(TmpStr);
           END;
         END;
       UNTIL EOM;
       {Write It}
       DestBase^.WriteMsg;
       SkipIt:
       SourceBase^.SeekNext;
     END;
     Temp := _PadRight(_String(NumMsgs),5);
     FastWrite(Temp,Y,X,7);
     DestBase^.UnLockMsgBase;
     CloseMsgArea(DestBase);
     CloseMsgArea(SourceBase);
     IF IOResult=0 THEN;
     FileMode := SetFileMode;
     LastReadJam;
     INC(TotalMsgs,NumMsgs);
     _EraseFile(BasePath+'$$GSPACK.JDT');
     _EraseFile(BasePath+'$$GSPACK.JDX');
     _EraseFile(BasePath+'$$GSPACK.JHR');
     _EraseFile(BasePath+'$$GSPACK.JLR');
     DoneBytes := DoneBytes+_FileSize(MessageAreas.Dos_Name+'.JDT');
     DoneBytes := DoneBytes+_FileSize(MessageAreas.Dos_Name+'.JDX');
     DoneBytes := DoneBytes+_FileSize(MessageAreas.Dos_Name+'.JHR');
     DoneBytes := DoneBytes+_FileSize(MessageAreas.Dos_Name+'.JLR');
     WRITELN('Done!  ');
END;


END.
