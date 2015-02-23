{$I DEFINES.INC}
UNIT ChangeFG;


INTERFACE


PROCEDURE ChangeFileGroup;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Pick,MiscStr,Screens,GotKeys,_Mouse,
     TagArea,KeyInput,ToggMsg,FilHeadr,Gunshot,FilGroup;


PROCEDURE ChangeFileGroup;
VAR  count      : word;
     OuttaHere  : Boolean;
     C          : Char;
     FFileSubs2 : File Of _FileSub_Record;
BEGIN
     Count := 0;
     ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
     ASSIGN(FFileSubs2,NODE_Directory+'\FFFFFFFF.FFF');
     REWRITE(FFileSubs2);
     RESET(FFileSubs);
     REPEAT
           READ(FFileSubs,FileSubs);
           IF GotAccessToSomeFileAreas(FileSubs.Sub_Num) THEN
           BEGIN
                INC(Count);
                WRITE(FFileSubs2,FileSubs);
           END;
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);
     CLOSE(FFileSubs2);
     IF Count=0 THEN Exit;
     IF DisplayGraphicFile('FGROUPS',False,True,True) THEN
     BEGIN
          NewPickList(True);
          PickInfo.Current := 0;
          Count := 0;
          ChangeMouse(BusyMouse);
          ASSIGN(FFileSubs,NODE_Directory+'\FFFFFFFF.FFF');
          RESET(FFileSubs);
          REPEAT
                READ(FFileSubs,FileSubs);
                INC(Count);
                AddToPickList(FileSubs.Sub_Name,Count,True);
          UNTIL EOF(FFileSubs);
          CLOSE(FFileSubs);
          ChangeMouse(DefaultMouse);
          HideTheMouse;
          BeginPickList;
          SetUpPickList;
          ShowTheMouse;
          OuttaHere := False;
          REPEAT
                c := GetKeyPress;
                CASE Ord(C) OF
                13:  BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                               ASSIGN(FFileSubs,NODE_Directory+'\FFFFFFFF.FFF');
                               RESET(FFileSubs);
                               SEEK(FFileSubs,PickInfo.Current-1);
                               READ(FFileSubs,FileSubs);
                               CLOSE(FFileSubs);
                               Header(FileSubs.Sub_Num,1,True);
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
