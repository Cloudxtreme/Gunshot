{$I DEFINES.INC}
UNIT FilGroup;


INTERFACE


PROCEDURE NextFileGroup;
PROCEDURE PreviousFileGroup;
FUNCTION  GotAccessToSomeFileAreas(TheSub: Word): Boolean;


IMPLEMENTATION


USES Globals,FilHeadr,Shotgun,MiscStr,GotKeys;


PROCEDURE NextFileGroup;
VAR  TheOne  : Longint;
BEGIN
     TheOne := 999999;
     ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
     RESET(FFileSubs);
     REPEAT
           READ(FFileSubs,FileSubs);
           IF ((FileSubs.Sub_Num>CurrentFileSub) AND (FileSubs.Sub_Num<TheOne)) THEN
           BEGIN
                IF GotAccessToSomeFileAreas(FileSubs.Sub_Num) THEN TheOne := FileSubs.Sub_Num;
           END;
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);
     IF ((TheOne<>999999) AND (TheOne<>CurrentFileSub)) THEN
     BEGIN
          CurrentFileSub := TheOne;
          Header(CurrentFileSub,1,True);
     END
     ELSE Header(CurrentFileSub,CurrentFileArea,True);
END;


PROCEDURE PreviousFileGroup;
VAR  TheOne  : Longint;
BEGIN
     TheOne := 0;
     ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
     RESET(FFileSubs);
     REPEAT
           READ(FFileSubs,FileSubs);
           IF ((FileSubs.Sub_Num<CurrentFileSub) AND (FileSubs.Sub_Num>TheOne)) THEN
           BEGIN
                IF GotAccessToSomeFileAreas(FileSubs.Sub_Num) THEN TheOne := FileSubs.Sub_Num;
           END;
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);
     IF ((TheOne<>0) AND (TheOne<>CurrentFileSub)) THEN
     BEGIN
          CurrentFileSub := TheOne;
          Header(CurrentFileSub,1,True);
     END
     ELSE Header(CurrentFileSub,CurrentFileArea,True);
END;


FUNCTION GotAccessToSomeFileAreas(TheSub: Word): Boolean;
VAR  _FFileArea : File Of _FileArea_Record;
     _FileArea  : _FileArea_Record;
BEGIN
     ASSIGN(_FFileArea,DATA_Directory+'\FA'+ZeroPadded(TheSub)+'.DAT');
     {$I-}RESET(_FFileArea);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(_FFileArea,_FileArea);
                IF ((UserRecord.Security>=_FileArea.View_Access) AND GotTheKeys(UserRecord.Tags,_FileArea.Tags)) THEN
                BEGIN
                     IF NOT(_FileArea.PassThrough) THEN
                     BEGIN
                          CLOSE(_FFileArea);
                          GotAccessToSomeFileAreas := True;
                          Exit;
                     END;
                END;
          UNTIL EOF(_FFileArea);
          CLOSE(_FFileArea);
     END;
     GotAccessToSomeFileAreas := False;
END;


END.