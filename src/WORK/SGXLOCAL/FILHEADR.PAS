{$I DEFINES.INC}
UNIT FilHeadr;


INTERFACE


PROCEDURE header(Sub,Area: Word; Direction: Boolean);


IMPLEMENTATION


USES Globals,MiscStr,ErrorLog,GotKeys,CDS,Shotgun,BsString;


PROCEDURE header(Sub,Area: Word; Direction: Boolean);
VAR  count      : word;
     GotIt      : Boolean;
     Duck       : Longint;
     OldArea    : Word;
     OldSub     : Word;
     OldFarea   : _FileArea_Record;
     OldFSub    : _FileSub_Record;

     PROCEDURE MoveArea;
     BEGIN
          CASE Direction OF
          True  : BEGIN
                       INC(CurrentFileArea);
                       IF CurrentFileArea>Count THEN CurrentFileArea := 1;
                  END;
          False : BEGIN
                       DEC(CurrentFileArea);
                       IF CurrentFileArea=0 THEN CurrentFileArea := Count;
                  END;
          END;
     END;

BEGIN
     OldArea           := CurrentFileArea;
     OldSub            := CurrentFileSub;
     OldFarea          := FileAreas;
     OldFSub           := FileSubs;
     FileSubs.Sub_Num  := 0;
     FileSubs.Sub_Name := 'All Areas';
     CurrentFileArea   := Area;
     CurrentFileSub    := Sub;

     {Load in the sub}
     IF CurrentFileSub<>0 THEN
     BEGIN
          ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
          RESET(FFileSubs);
          REPEAT
                READ(FFileSubs,FileSubs);
          UNTIL ((EOF(FFileSubs)) OR (FileSubs.Sub_Num=CurrentFileSub));
          CLOSE(FFileSubs);
          {Sub does NOT exist}
          IF (FileSubs.Sub_Num<>CurrentFileSub) THEN
          BEGIN
               DoErrorLog(17,_String(CurrentFileSub));
               CurrentFileArea := OldArea;
               CurrentFileSub  := OldSub;
               FileAreas       := OldFarea;
               FileSubs        := OldFSub;
               Exit;
          END;
     END;

     {Crunch time}
     GotIt  := False;
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     Count := FileSize(FFileArea);

     {Make sure we aren't at 0 or over the number of areas}
     IF CurrentFileArea>count THEN CurrentFileArea := 1;
     IF CurrentFileArea=0 THEN CurrentFileArea := count;

     Duck := 0;
     REPEAT
           Seek(FFileArea,(CurrentFileArea-1));
           read(FFileArea,FileAreas);
           INC(Duck);
           IF GotTheKeys(UserRecord.Tags,FileAreas.Tags) THEN
           BEGIN
                IF (UserRecord.Security>=FileAreas.View_Access) THEN
                BEGIN
                     IF NOT(FileAreas.PassThrough) THEN
                     BEGIN
                          IF (FileAreas.CD_Rom<>0) THEN
                          BEGIN
                               IF IsCDToggled(FileAreas.CD_Rom)
                                  THEN GotIt := True
                                  ELSE MoveArea;
                          END
                          ELSE GotIt := True;
                     END
                     ELSE MoveArea;
                END
                ELSE MoveArea;
           END
           ELSE MoveArea;
           {No areas, so go back to the original group/area}
           IF (Duck>Count+1) THEN
           BEGIN
                DoErrorLog(18,_String(CurrentFileArea));
                CurrentFileArea := OldArea;
                CurrentFileSub  := OldSub;
                FileAreas       := OldFarea;
                FileSubs        := OldFSub;
                GotIt           := True;
           END;
     UNTIL GotIt;
     close(FFileArea);
end;


END.
