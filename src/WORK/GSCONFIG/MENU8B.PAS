{$I DEFINES.INC}
UNIT MENU8B;


INTERFACE


PROCEDURE DoFreqEvents;
PROCEDURE DoExitEvents;
PROCEDURE DoDropEvents;
PROCEDURE DoPollEvents;
PROCEDURE DoSendEvents;
PROCEDURE DoMailEvents;
PROCEDURE DoCallRouting;
PROCEDURE DoLockoutRecord;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Dispatch,Valid,Misc,BsAkas;


PROCEDURE EditExitEvent(Number: Longint);
VAR  WhichOne : Byte;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
     RESET(FExitEvent);
     SEEK(FExitEvent,Number-1);
     READ(FExitEvent,ExitEvent);
     CLOSE(FExitEvent);
     DrawWindow(8,6,73,21,'EDIT EXIT EVENT',True);
     AddObject(29,8,1,40,ExitEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(ExitEvent.Time),True);
     AddObject(29,10,2,3,_String(ExitEvent.Errorlevel),True);
     AddObject(29,11,6,3,FromBoolean(ExitEvent.Active),True);
     AddObject(29,12,6,3,FromBoolean(ExitEvent.Days[1]),True);
     AddObject(29,13,6,3,FromBoolean(ExitEvent.Days[2]),True);
     AddObject(29,14,6,3,FromBoolean(ExitEvent.Days[3]),True);
     AddObject(29,15,6,3,FromBoolean(ExitEvent.Days[4]),True);
     AddObject(29,16,6,3,FromBoolean(ExitEvent.Days[5]),True);
     AddObject(29,17,6,3,FromBoolean(ExitEvent.Days[6]),True);
     AddObject(29,18,6,3,FromBoolean(ExitEvent.Days[7]),True);
     AddButton(55,19,' QUIT ',True,1,16);
     AddButton(63,19,' RESET ',True,1,19);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Event Time');
     GotoXY(10,10); WRITE('       Errorlevel');
     GotoXY(10,11); WRITE('           Active');
     GotoXY(10,12); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,13); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,14); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,15); WRITE('      Ã Wednesday');
     GotoXY(10,16); WRITE('      ÃÄ Thursday');
     GotoXY(10,17); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,18); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     REPEAT
           WhichOne := DoObjects;
           IF WhichOne=2 THEN
           BEGIN
                ExitEvent.LastMonth := 0;
                ExitEvent.LastDay   := 0;
                ExitEvent.LastYear  := 0;
           END;
     UNTIL WhichOne=1;
     ClearObjects;
     ClearButtons;
     ExitEvent.Description := Objects^[1].Stuff;
     ExitEvent.Time        := ReturnTime(Objects^[2].Stuff);
     ExitEvent.Errorlevel  := Numeric(Objects^[3].Stuff,ByteInteger);
     ExitEvent.Active      := ToBoolean(Objects^[4].Stuff);
     ExitEvent.Days[1]     := ToBoolean(Objects^[5].Stuff);
     ExitEvent.Days[2]     := ToBoolean(Objects^[6].Stuff);
     ExitEvent.Days[3]     := ToBoolean(Objects^[7].Stuff);
     ExitEvent.Days[4]     := ToBoolean(Objects^[8].Stuff);
     ExitEvent.Days[5]     := ToBoolean(Objects^[9].Stuff);
     ExitEvent.Days[6]     := ToBoolean(Objects^[10].Stuff);
     ExitEvent.Days[7]     := ToBoolean(Objects^[11].Stuff);
     ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
     RESET(FExitEvent);
     SEEK(FExitEvent,Number-1);
     WRITE(FExitEvent,ExitEvent);
     CLOSE(FExitEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteExitEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode),SizeOf(ExitEvent),Number);
END;


PROCEDURE AddExitEvent;
BEGIN
     FillChar(ExitEvent,SizeOf(ExitEvent),0);
     ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
     {$I-}RESET(FExitEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FExitEvent)
                      ELSE SEEK(FExitEvent,FileSize(FExitEvent));
     WRITE(FExitEvent,ExitEvent);
     CLOSE(FExitEvent);
END;


PROCEDURE InsertExitEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(ExitEvent,SizeOf(ExitEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FExitEvent2,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
          RENAME(FExitEvent2,BaseDirectory+'\DATA\EVENTSE.BAK');
          ASSIGN(FExitEvent2,BaseDirectory+'\DATA\EVENTSE.BAK');
          ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
          RESET(FExitEvent2);
          REWRITE(FExitEvent);
          Counting := 0;
          REPEAT
                READ(FExitEvent2,ExitEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FExitEvent,ExitEvent);
                WRITE(FExitEvent,ExitEvent2);
          UNTIL EOF(FExitEvent2);
          CLOSE(FExitEvent);
          CLOSE(FExitEvent2);
          ERASE(FExitEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
          REWRITE(FExitEvent);
          WRITE(FExitEvent,ExitEvent);
          CLOSE(FExitEvent);
     END;
END;


PROCEDURE DoExitEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
          RESET(FExitEvent);
          REPEAT
                Read(FExitEvent,ExitEvent);
                PickListFile.A := ExitEvent.Description;
                IF ExitEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FExitEvent);
          CLOSE(FExitEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
     {$I-}
     RESET(FExitEvent);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FExitEvent);
          CLOSE(FExitEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - ERRORLEVEL EXIT - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditExitEvent(PickItem);
                     ASSIGN(FExitEvent,BaseDirectory+'\DATA\EVENTSE.'+_String(CurrentNode));
                     RESET(FExitEvent);
                     PickListItems := FileSize(FExitEvent);
                     CLOSE(FExitEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteExitEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddExitEvent;
                          EditExitEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertExitEvent(PickItem);
                          EditExitEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddExitEvent;
                     EditExitEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditDropEvent(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
     RESET(FDropEvent);
     SEEK(FDropEvent,Number-1);
     READ(FDropEvent,DropEvent);
     CLOSE(FDropEvent);
     DrawWindow(8,6,73,21,'EDIT BUSY EVENT',True);
     AddObject(29,8,1,40,DropEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(DropEvent.StartTime),True);
     AddObject(29,10,3,4,TimeStrng(DropEvent.EndTime),True);
     AddObject(29,11,6,3,FromBoolean(DropEvent.Active),True);
     AddObject(29,12,6,3,FromBoolean(DropEvent.Days[1]),True);
     AddObject(29,13,6,3,FromBoolean(DropEvent.Days[2]),True);
     AddObject(29,14,6,3,FromBoolean(DropEvent.Days[3]),True);
     AddObject(29,15,6,3,FromBoolean(DropEvent.Days[4]),True);
     AddObject(29,16,6,3,FromBoolean(DropEvent.Days[5]),True);
     AddObject(29,17,6,3,FromBoolean(DropEvent.Days[6]),True);
     AddObject(29,18,6,3,FromBoolean(DropEvent.Days[7]),True);
     AddButton(63,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Start Time');
     GotoXY(10,10); WRITE('         End Time');
     GotoXY(10,11); WRITE('           Active');
     GotoXY(10,12); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,13); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,14); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,15); WRITE('      Ã Wednesday');
     GotoXY(10,16); WRITE('      ÃÄ Thursday');
     GotoXY(10,17); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,18); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     DropEvent.Description := Objects^[1].Stuff;
     DropEvent.StartTime   := ReturnTime(Objects^[2].Stuff);
     DropEvent.EndTime     := ReturnTime(Objects^[3].Stuff);
     DropEvent.Active      := ToBoolean(Objects^[4].Stuff);
     DropEvent.Days[1]     := ToBoolean(Objects^[5].Stuff);
     DropEvent.Days[2]     := ToBoolean(Objects^[6].Stuff);
     DropEvent.Days[3]     := ToBoolean(Objects^[7].Stuff);
     DropEvent.Days[4]     := ToBoolean(Objects^[8].Stuff);
     DropEvent.Days[5]     := ToBoolean(Objects^[9].Stuff);
     DropEvent.Days[6]     := ToBoolean(Objects^[10].Stuff);
     DropEvent.Days[7]     := ToBoolean(Objects^[11].Stuff);
     ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
     RESET(FDropEvent);
     SEEK(FDropEvent,Number-1);
     WRITE(FDropEvent,DropEvent);
     CLOSE(FDropEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteDropEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode),SizeOf(DropEvent),Number);
END;


PROCEDURE AddDropEvent;
BEGIN
     FillChar(DropEvent,SizeOf(DropEvent),0);
     ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
     {$I-}RESET(FDropEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FDropEvent)
                      ELSE SEEK(FDropEvent,FileSize(FDropEvent));
     WRITE(FDropEvent,DropEvent);
     CLOSE(FDropEvent);
END;


PROCEDURE InsertDropEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(DropEvent,SizeOf(DropEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FDropEvent2,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
          RENAME(FDropEvent2,BaseDirectory+'\DATA\EVENTSB.BAK');
          ASSIGN(FDropEvent2,BaseDirectory+'\DATA\EVENTSB.BAK');
          ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
          RESET(FDropEvent2);
          REWRITE(FDropEvent);
          Counting := 0;
          REPEAT
                READ(FDropEvent2,DropEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FDropEvent,DropEvent);
                WRITE(FDropEvent,DropEvent2);
          UNTIL EOF(FDropEvent2);
          CLOSE(FDropEvent);
          CLOSE(FDropEvent2);
          ERASE(FDropEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
          REWRITE(FDropEvent);
          WRITE(FDropEvent,DropEvent);
          CLOSE(FDropEvent);
     END;
END;


PROCEDURE DoDropEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
          RESET(FDropEvent);
          REPEAT
                Read(FDropEvent,DropEvent);
                PickListFile.A := DropEvent.Description;
                IF DropEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FDropEvent);
          CLOSE(FDropEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
     {$I-}
     RESET(FDropEvent);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FDropEvent);
          CLOSE(FDropEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - MAILER NODE BUSY - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditDropEvent(PickItem);
                     ASSIGN(FDropEvent,BaseDirectory+'\DATA\EVENTSB.'+_String(CurrentNode));
                     RESET(FDropEvent);
                     PickListItems := FileSize(FDropEvent);
                     CLOSE(FDropEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteDropEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddDropEvent;
                          EditDropEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertDropEvent(PickItem);
                          EditDropEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddDropEvent;
                     EditDropEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditPollEvent(Number: Longint);
VAR  WhichOne : Byte;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
     RESET(FPollEvent);
     SEEK(FPollEvent,Number-1);
     READ(FPollEvent,PollEvent);
     CLOSE(FPollEvent);
     DrawWindow(8,6,73,21,'EDIT POLL EVENT',True);
     AddObject(29,8,1,40,PollEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(PollEvent.StartTime),True);
     AddObject(29,10,3,4,TimeStrng(PollEvent.EndTime),True);
     AddObject(29,11,1,20,AddressToString(PollEvent.CallAddress),True);
     AddObject(29,12,6,3,FromBoolean(PollEvent.Active),True);
     AddObject(29,13,6,3,FromBoolean(PollEvent.Days[1]),True);
     AddObject(29,14,6,3,FromBoolean(PollEvent.Days[2]),True);
     AddObject(29,15,6,3,FromBoolean(PollEvent.Days[3]),True);
     AddObject(29,16,6,3,FromBoolean(PollEvent.Days[4]),True);
     AddObject(29,17,6,3,FromBoolean(PollEvent.Days[5]),True);
     AddObject(29,18,6,3,FromBoolean(PollEvent.Days[6]),True);
     AddObject(29,19,6,3,FromBoolean(PollEvent.Days[7]),True);
     AddButton(55,19,' QUIT ',True,1,16);
     AddButton(63,19,' RESET ',True,1,19);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Start Time');
     GotoXY(10,10); WRITE('         End Time');
     GotoXY(10,11); WRITE('     Call Address');
     GotoXY(10,12); WRITE('           Active');
     GotoXY(10,13); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,14); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,15); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,16); WRITE('      Ã Wednesday');
     GotoXY(10,17); WRITE('      ÃÄ Thursday');
     GotoXY(10,18); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,19); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     REPEAT
           WhichOne := DoObjects;
           IF WhichOne=2 THEN
           BEGIN
                PollEvent.LastMonth := 0;
                PollEvent.LastDay   := 0;
                PollEvent.LastYear  := 0;
           END;
     UNTIL WhichOne=1;
     ClearObjects;
     ClearButtons;
     PollEvent.Description := Objects^[1].Stuff;
     PollEvent.StartTime   := ReturnTime(Objects^[2].Stuff);
     PollEvent.EndTime     := ReturnTime(Objects^[3].Stuff);
     StringToAddress(Objects^[4].Stuff,PollEvent.CallAddress);
     PollEvent.Active      := ToBoolean(Objects^[5].Stuff);
     PollEvent.Days[1]     := ToBoolean(Objects^[6].Stuff);
     PollEvent.Days[2]     := ToBoolean(Objects^[7].Stuff);
     PollEvent.Days[3]     := ToBoolean(Objects^[8].Stuff);
     PollEvent.Days[4]     := ToBoolean(Objects^[9].Stuff);
     PollEvent.Days[5]     := ToBoolean(Objects^[10].Stuff);
     PollEvent.Days[6]     := ToBoolean(Objects^[11].Stuff);
     PollEvent.Days[7]     := ToBoolean(Objects^[12].Stuff);
     ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
     RESET(FPollEvent);
     SEEK(FPollEvent,Number-1);
     WRITE(FPollEvent,PollEvent);
     CLOSE(FPollEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeletePollEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode),SizeOf(PollEvent),Number);
END;


PROCEDURE AddPollEvent;
BEGIN
     FillChar(PollEvent,SizeOf(PollEvent),0);
     ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
     {$I-}RESET(FPollEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FPollEvent)
                      ELSE SEEK(FPollEvent,FileSize(FPollEvent));
     WRITE(FPollEvent,PollEvent);
     CLOSE(FPollEvent);
END;


PROCEDURE InsertPollEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(PollEvent,SizeOf(PollEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FPollEvent2,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
          RENAME(FPollEvent2,BaseDirectory+'\DATA\EVENTSP.BAK');
          ASSIGN(FPollEvent2,BaseDirectory+'\DATA\EVENTSP.BAK');
          ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
          RESET(FPollEvent2);
          REWRITE(FPollEvent);
          Counting := 0;
          REPEAT
                READ(FPollEvent2,PollEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FPollEvent,PollEvent);
                WRITE(FPollEvent,PollEvent2);
          UNTIL EOF(FPollEvent2);
          CLOSE(FPollEvent);
          CLOSE(FPollEvent2);
          ERASE(FPollEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
          REWRITE(FPollEvent);
          WRITE(FPollEvent,PollEvent);
          CLOSE(FPollEvent);
     END;
END;


PROCEDURE DoPollEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
          RESET(FPollEvent);
          REPEAT
                Read(FPollEvent,PollEvent);
                PickListFile.A := PollEvent.Description;
                IF PollEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FPollEvent);
          CLOSE(FPollEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
     {$I-}
     RESET(FPollEvent);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FPollEvent);
          CLOSE(FPollEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - POLL ANOTHER NODE - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditPollEvent(PickItem);
                     ASSIGN(FPollEvent,BaseDirectory+'\DATA\EVENTSP.'+_String(CurrentNode));
                     RESET(FPollEvent);
                     PickListItems := FileSize(FPollEvent);
                     CLOSE(FPollEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeletePollEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddPollEvent;
                          EditPollEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertPollEvent(PickItem);
                          EditPollEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddPollEvent;
                     EditPollEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditMailEvent(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
     RESET(FMailEvent);
     SEEK(FMailEvent,Number-1);
     READ(FMailEvent,MailEvent);
     CLOSE(FMailEvent);
     DrawWindow(8,6,73,21,'EDIT MAIL-ONLY EVENT',True);
     AddObject(29,8,1,40,MailEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(MailEvent.StartTime),True);
     AddObject(29,10,3,4,TimeStrng(MailEvent.EndTime),True);
     AddObject(29,11,6,3,FromBoolean(MailEvent.Active),True);
     AddObject(29,12,6,3,FromBoolean(MailEvent.Days[1]),True);
     AddObject(29,13,6,3,FromBoolean(MailEvent.Days[2]),True);
     AddObject(29,14,6,3,FromBoolean(MailEvent.Days[3]),True);
     AddObject(29,15,6,3,FromBoolean(MailEvent.Days[4]),True);
     AddObject(29,16,6,3,FromBoolean(MailEvent.Days[5]),True);
     AddObject(29,17,6,3,FromBoolean(MailEvent.Days[6]),True);
     AddObject(29,18,6,3,FromBoolean(MailEvent.Days[7]),True);
     AddButton(63,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Start Time');
     GotoXY(10,10); WRITE('         End Time');
     GotoXY(10,11); WRITE('           Active');
     GotoXY(10,12); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,13); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,14); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,15); WRITE('      Ã Wednesday');
     GotoXY(10,16); WRITE('      ÃÄ Thursday');
     GotoXY(10,17); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,18); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     MailEvent.Description := Objects^[1].Stuff;
     MailEvent.StartTime   := ReturnTime(Objects^[2].Stuff);
     MailEvent.EndTime     := ReturnTime(Objects^[3].Stuff);
     MailEvent.Active      := ToBoolean(Objects^[4].Stuff);
     MailEvent.Days[1]     := ToBoolean(Objects^[5].Stuff);
     MailEvent.Days[2]     := ToBoolean(Objects^[6].Stuff);
     MailEvent.Days[3]     := ToBoolean(Objects^[7].Stuff);
     MailEvent.Days[4]     := ToBoolean(Objects^[8].Stuff);
     MailEvent.Days[5]     := ToBoolean(Objects^[9].Stuff);
     MailEvent.Days[6]     := ToBoolean(Objects^[10].Stuff);
     MailEvent.Days[7]     := ToBoolean(Objects^[11].Stuff);
     ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
     RESET(FMailEvent);
     SEEK(FMailEvent,Number-1);
     WRITE(FMailEvent,MailEvent);
     CLOSE(FMailEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteMailEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode),SizeOf(MailEvent),Number);
END;


PROCEDURE AddMailEvent;
BEGIN
     FillChar(MailEvent,SizeOf(MailEvent),0);
     ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
     {$I-}RESET(FMailEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FMailEvent)
                      ELSE SEEK(FMailEvent,FileSize(FMailEvent));
     WRITE(FMailEvent,MailEvent);
     CLOSE(FMailEvent);
END;


PROCEDURE InsertMailEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(MailEvent,SizeOf(MailEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FMailEvent2,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
          RENAME(FMailEvent2,BaseDirectory+'\DATA\EVENTSM.BAK');
          ASSIGN(FMailEvent2,BaseDirectory+'\DATA\EVENTSM.BAK');
          ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
          RESET(FMailEvent2);
          REWRITE(FMailEvent);
          Counting := 0;
          REPEAT
                READ(FMailEvent2,MailEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FMailEvent,MailEvent);
                WRITE(FMailEvent,MailEvent2);
          UNTIL EOF(FMailEvent2);
          CLOSE(FMailEvent);
          CLOSE(FMailEvent2);
          ERASE(FMailEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
          REWRITE(FMailEvent);
          WRITE(FMailEvent,MailEvent);
          CLOSE(FMailEvent);
     END;
END;


PROCEDURE DoMailEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
          RESET(FMailEvent);
          REPEAT
                Read(FMailEvent,MailEvent);
                PickListFile.A := MailEvent.Description;
                IF MailEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FMailEvent);
          CLOSE(FMailEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
     {$I-}
     RESET(FMailEvent);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FMailEvent);
          CLOSE(FMailEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - MAIL-ONLY - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditMailEvent(PickItem);
                     ASSIGN(FMailEvent,BaseDirectory+'\DATA\EVENTSM.'+_String(CurrentNode));
                     RESET(FMailEvent);
                     PickListItems := FileSize(FMailEvent);
                     CLOSE(FMailEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteMailEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddMailEvent;
                          EditMailEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertMailEvent(PickItem);
                          EditMailEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddMailEvent;
                     EditMailEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditCallRouting(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
     RESET(FCallRouting);
     SEEK(FCallRouting,Number-1);
     READ(FCallRouting,CallRouting);
     CLOSE(FCallRouting);
     DrawWindow(8,8,70,15,'EDIT SGMAIL CALL ROUTING ENTRY',True);
     AddObject(28,10,1,20,CallRouting.SourceAddr,True);
     AddObject(28,11,1,20,AddressToString(CallRouting.DestAddr),True);
     AddButton(60,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(11,10); WRITE(' Routed Node(s)');
     GotoXY(11,11); WRITE('   Send-To Node');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     CallRouting.SourceAddr := _UpperCase(Objects^[1].Stuff);
     StringToAddress(Objects^[2].Stuff,CallRouting.DestAddr);
     ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
     RESET(FCallRouting);
     SEEK(FCallRouting,Number-1);
     WRITE(FCallRouting,CallRouting);
     CLOSE(FCallRouting);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteCallRouting(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\ROUTE.DAT',SizeOf(CallRouting),Number);
END;


PROCEDURE AddCallRouting;
BEGIN
     FillChar(CallRouting,SizeOf(CallRouting),0);
     ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
     {$I-}RESET(FCallRouting);{$I+}
     IF (IOResult<>0) THEN REWRITE(FCallRouting)
                      ELSE SEEK(FCallRouting,FileSize(FCallRouting));
     WRITE(FCallRouting,CallRouting);
     CLOSE(FCallRouting);
END;


PROCEDURE InsertCallRouting(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(CallRouting,SizeOf(CallRouting),0);
     IF _FileExists(BaseDirectory+'\DATA\ROUTE.DAT') THEN
     BEGIN
          ASSIGN(FCallRouting2,BaseDirectory+'\DATA\ROUTE.DAT');
          RENAME(FCallRouting2,BaseDirectory+'\DATA\ROUTE.BAK');
          ASSIGN(FCallRouting2,BaseDirectory+'\DATA\ROUTE.BAK');
          ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
          RESET(FCallRouting2);
          REWRITE(FCallRouting);
          Counting := 0;
          REPEAT
                READ(FCallRouting2,CallRouting2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FCallRouting,CallRouting);
                WRITE(FCallRouting,CallRouting2);
          UNTIL EOF(FCallRouting2);
          CLOSE(FCallRouting);
          CLOSE(FCallRouting2);
          ERASE(FCallRouting2);
     END
     ELSE
     BEGIN
          ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
          REWRITE(FCallRouting);
          WRITE(FCallRouting,CallRouting);
          CLOSE(FCallRouting);
     END;
END;


PROCEDURE DoCallRouting;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
          RESET(FCallRouting);
          REPEAT
                Read(FCallRouting,CallRouting);
                PickListFile.A := _PadRight(CallRouting.SourceAddr,22)+AddressToString(CallRouting.DestAddr);
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FCallRouting);
          CLOSE(FCallRouting);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
     {$I-}RESET(FCallRouting);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FCallRouting);
          CLOSE(FCallRouting);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Routed Node(s)        Send-To Node',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL CALL ROUTING CONFIGURATION');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditCallRouting(PickItem);
                     ASSIGN(FCallRouting,BaseDirectory+'\DATA\ROUTE.DAT');
                     RESET(FCallRouting);
                     PickListItems := FileSize(FCallRouting);
                     CLOSE(FCallRouting);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteCallRouting(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddCallRouting;
                          EditCallRouting(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertCallRouting(PickItem);
                          EditCallRouting(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddCallRouting;
                     EditCallRouting(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditSendEvent(Number: Longint);
VAR  WhichOne : Byte;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
     RESET(FSendEvent);
     SEEK(FSendEvent,Number-1);
     READ(FSendEvent,SendEvent);
     CLOSE(FSendEvent);
     DrawWindow(8,6,73,21,'EDIT SEND EVENT',True);
     AddObject(29,8,1,40,SendEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(SendEvent.StartTime),True);
     AddObject(29,10,3,4,TimeStrng(SendEvent.EndTime),True);
     AddObject(29,11,1,20,AddressToString(SendEvent.CallAddress),True);
     AddObject(29,12,6,3,FromBoolean(SendEvent.Active),True);
     AddObject(29,13,6,3,FromBoolean(SendEvent.Days[1]),True);
     AddObject(29,14,6,3,FromBoolean(SendEvent.Days[2]),True);
     AddObject(29,15,6,3,FromBoolean(SendEvent.Days[3]),True);
     AddObject(29,16,6,3,FromBoolean(SendEvent.Days[4]),True);
     AddObject(29,17,6,3,FromBoolean(SendEvent.Days[5]),True);
     AddObject(29,18,6,3,FromBoolean(SendEvent.Days[6]),True);
     AddObject(29,19,6,3,FromBoolean(SendEvent.Days[7]),True);
     AddButton(55,19,' QUIT ',True,1,16);
     AddButton(63,19,' RESET ',True,1,19);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Start Time');
     GotoXY(10,10); WRITE('         End Time');
     GotoXY(10,11); WRITE('     Call Address');
     GotoXY(10,12); WRITE('           Active');
     GotoXY(10,13); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,14); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,15); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,16); WRITE('      Ã Wednesday');
     GotoXY(10,17); WRITE('      ÃÄ Thursday');
     GotoXY(10,18); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,19); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     REPEAT
           WhichOne := DoObjects;
           IF WhichOne=2 THEN
           BEGIN
                SendEvent.LastMonth := 0;
                SendEvent.LastDay   := 0;
                SendEvent.LastYear  := 0;
           END;
     UNTIL WhichOne=1;
     ClearObjects;
     ClearButtons;
     SendEvent.Description := Objects^[1].Stuff;
     SendEvent.StartTime   := ReturnTime(Objects^[2].Stuff);
     SendEvent.EndTime     := ReturnTime(Objects^[3].Stuff);
     StringToAddress(Objects^[4].Stuff,SendEvent.CallAddress);
     SendEvent.Active      := ToBoolean(Objects^[5].Stuff);
     SendEvent.Days[1]     := ToBoolean(Objects^[6].Stuff);
     SendEvent.Days[2]     := ToBoolean(Objects^[7].Stuff);
     SendEvent.Days[3]     := ToBoolean(Objects^[8].Stuff);
     SendEvent.Days[4]     := ToBoolean(Objects^[9].Stuff);
     SendEvent.Days[5]     := ToBoolean(Objects^[10].Stuff);
     SendEvent.Days[6]     := ToBoolean(Objects^[11].Stuff);
     SendEvent.Days[7]     := ToBoolean(Objects^[12].Stuff);
     ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
     RESET(FSendEvent);
     SEEK(FSendEvent,Number-1);
     WRITE(FSendEvent,SendEvent);
     CLOSE(FSendEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteSendEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode),SizeOf(SendEvent),Number);
END;


PROCEDURE AddSendEvent;
BEGIN
     FillChar(SendEvent,SizeOf(SendEvent),0);
     ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
     {$I-}RESET(FSendEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FSendEvent)
                      ELSE SEEK(FSendEvent,FileSize(FSendEvent));
     WRITE(FSendEvent,SendEvent);
     CLOSE(FSendEvent);
END;


PROCEDURE InsertSendEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(SendEvent,SizeOf(SendEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FSendEvent2,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
          RENAME(FSendEvent2,BaseDirectory+'\DATA\EVENTSS.BAK');
          ASSIGN(FSendEvent2,BaseDirectory+'\DATA\EVENTSS.BAK');
          ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
          RESET(FSendEvent2);
          REWRITE(FSendEvent);
          Counting := 0;
          REPEAT
                READ(FSendEvent2,SendEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FSendEvent,SendEvent);
                WRITE(FSendEvent,SendEvent2);
          UNTIL EOF(FSendEvent2);
          CLOSE(FSendEvent);
          CLOSE(FSendEvent2);
          ERASE(FSendEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
          REWRITE(FSendEvent);
          WRITE(FSendEvent,SendEvent);
          CLOSE(FSendEvent);
     END;
END;


PROCEDURE DoSendEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
          RESET(FSendEvent);
          REPEAT
                Read(FSendEvent,SendEvent);
                PickListFile.A := SendEvent.Description;
                IF SendEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FSendEvent);
          CLOSE(FSendEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
     {$I-}
     RESET(FSendEvent);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FSendEvent);
          CLOSE(FSendEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - SEND MAIL (UNHOLD) - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditSendEvent(PickItem);
                     ASSIGN(FSendEvent,BaseDirectory+'\DATA\EVENTSS.'+_String(CurrentNode));
                     RESET(FSendEvent);
                     PickListItems := FileSize(FSendEvent);
                     CLOSE(FSendEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteSendEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddSendEvent;
                          EditSendEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertSendEvent(PickItem);
                          EditSendEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddSendEvent;
                     EditSendEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditLockoutRecord(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
     RESET(FLockoutRecord);
     SEEK(FLockoutRecord,Number-1);
     READ(FLockoutRecord,LockoutRecord);
     CLOSE(FLockoutRecord);
     DrawWindow(19,9,65,16,'EDIT LOCKOUT RECORD',True);
     AddObject(30,11,1,30,LockoutRecord.PhoneName,True);
     AddObject(30,12,1,30,LockoutRecord.PhoneNumber,True);
     AddButton(55,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(21,11); WRITE('   Name');
     GotoXY(21,12); WRITE(' Number');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     LockoutRecord.PhoneName   := _UpperCase(Objects^[1].Stuff);
     LockoutRecord.PhoneNumber := _UpperCase(Objects^[2].Stuff);
     ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
     RESET(FLockoutRecord);
     SEEK(FLockoutRecord,Number-1);
     WRITE(FLockoutRecord,LockoutRecord);
     CLOSE(FLockoutRecord);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteLockoutRecord(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\LOCKOUT.DAT',SizeOf(LockoutRecord),Number);
END;


PROCEDURE AddLockoutRecord;
BEGIN
     FillChar(LockoutRecord,SizeOf(LockoutRecord),0);
     ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
     {$I-}RESET(FLockoutRecord);{$I+}
     IF (IOResult<>0) THEN REWRITE(FLockoutRecord)
                      ELSE SEEK(FLockoutRecord,FileSize(FLockoutRecord));
     WRITE(FLockoutRecord,LockoutRecord);
     CLOSE(FLockoutRecord);
END;


PROCEDURE InsertLockoutRecord(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(LockoutRecord,SizeOf(LockoutRecord),0);
     IF _FileExists(BaseDirectory+'\DATA\LOCKOUT.DAT') THEN
     BEGIN
          ASSIGN(FLockoutRecord2,BaseDirectory+'\DATA\LOCKOUT.DAT');
          RENAME(FLockoutRecord2,BaseDirectory+'\DATA\LOCKOUT.BAK');
          ASSIGN(FLockoutRecord2,BaseDirectory+'\DATA\LOCKOUT.BAK');
          ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
          RESET(FLockoutRecord2);
          REWRITE(FLockoutRecord);
          Counting := 0;
          REPEAT
                READ(FLockoutRecord2,LockoutRecord2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FLockoutRecord,LockoutRecord);
                WRITE(FLockoutRecord,LockoutRecord2);
          UNTIL EOF(FLockoutRecord2);
          CLOSE(FLockoutRecord);
          CLOSE(FLockoutRecord2);
          ERASE(FLockoutRecord2);
     END
     ELSE
     BEGIN
          ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
          REWRITE(FLockoutRecord);
          WRITE(FLockoutRecord,LockoutRecord);
          CLOSE(FLockoutRecord);
     END;
END;


PROCEDURE DoLockoutRecord;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
          RESET(FLockoutRecord);
          REPEAT
                READ(FLockoutRecord,LockoutRecord);
                PickListFile.A := _PadRight(LockoutRecord.PhoneName,25)+LockoutRecord.PhoneNumber;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FLockoutRecord);
          CLOSE(FLockoutRecord);
     END;

BEGIN
     _SaveWindow(WorkDir+'\LOCKOUT.SCR');
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
     {$I-}RESET(FLockoutRecord);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FLockoutRecord);
          CLOSE(FLockoutRecord);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' User Name                Phone Number',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('EDIT CID LOCKOUT NAMES/NUMBERS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditLockoutRecord(PickItem);
                     ASSIGN(FLockoutRecord,BaseDirectory+'\DATA\LOCKOUT.DAT');
                     RESET(FLockoutRecord);
                     PickListItems := FileSize(FLockoutRecord);
                     CLOSE(FLockoutRecord);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteLockoutRecord(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddLockoutRecord;
                          EditLockoutRecord(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertLockoutRecord(PickItem);
                          EditLockoutRecord(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddLockoutRecord;
                     EditLockoutRecord(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     LoadWindow(WorkDir+'\LOCKOUT.SCR');
END;


PROCEDURE EditFreqEvent(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
     RESET(FFreqEvent);
     SEEK(FFreqEvent,Number-1);
     READ(FFreqEvent,FreqEvent);
     CLOSE(FFreqEvent);
     DrawWindow(8,6,73,21,'EDIT NO FILE REQUESTS EVENT',True);
     AddObject(29,8,1,40,FreqEvent.Description,True);
     AddObject(29,9,3,4,TimeStrng(FreqEvent.StartTime),True);
     AddObject(29,10,3,4,TimeStrng(FreqEvent.EndTime),True);
     AddObject(29,11,6,3,FromBoolean(FreqEvent.Active),True);
     AddObject(29,12,6,3,FromBoolean(FreqEvent.Days[1]),True);
     AddObject(29,13,6,3,FromBoolean(FreqEvent.Days[2]),True);
     AddObject(29,14,6,3,FromBoolean(FreqEvent.Days[3]),True);
     AddObject(29,15,6,3,FromBoolean(FreqEvent.Days[4]),True);
     AddObject(29,16,6,3,FromBoolean(FreqEvent.Days[5]),True);
     AddObject(29,17,6,3,FromBoolean(FreqEvent.Days[6]),True);
     AddObject(29,18,6,3,FromBoolean(FreqEvent.Days[7]),True);
     AddButton(63,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,8);  WRITE('      Description');
     GotoXY(10,9);  WRITE('       Start Time');
     GotoXY(10,10); WRITE('         End Time');
     GotoXY(10,11); WRITE('           Active');
     GotoXY(10,12); WRITE('Days ÄÂÄÄÄ Sunday');
     GotoXY(10,13); WRITE('      ÃÄÄÄ Monday');
     GotoXY(10,14); WRITE('      ÃÄÄ Tuesday');
     GotoXY(10,15); WRITE('      Ã Wednesday');
     GotoXY(10,16); WRITE('      ÃÄ Thursday');
     GotoXY(10,17); WRITE('      ÃÄÄÄ Friday');
     GotoXY(10,18); WRITE('      ÀÄ Saturday');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     FreqEvent.Description := Objects^[1].Stuff;
     FreqEvent.StartTime   := ReturnTime(Objects^[2].Stuff);
     FreqEvent.EndTime     := ReturnTime(Objects^[3].Stuff);
     FreqEvent.Active      := ToBoolean(Objects^[4].Stuff);
     FreqEvent.Days[1]     := ToBoolean(Objects^[5].Stuff);
     FreqEvent.Days[2]     := ToBoolean(Objects^[6].Stuff);
     FreqEvent.Days[3]     := ToBoolean(Objects^[7].Stuff);
     FreqEvent.Days[4]     := ToBoolean(Objects^[8].Stuff);
     FreqEvent.Days[5]     := ToBoolean(Objects^[9].Stuff);
     FreqEvent.Days[6]     := ToBoolean(Objects^[10].Stuff);
     FreqEvent.Days[7]     := ToBoolean(Objects^[11].Stuff);
     ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
     RESET(FFreqEvent);
     SEEK(FFreqEvent,Number-1);
     WRITE(FFreqEvent,FreqEvent);
     CLOSE(FFreqEvent);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteFreqEvent(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode),SizeOf(FreqEvent),Number);
END;


PROCEDURE AddFreqEvent;
BEGIN
     FillChar(FreqEvent,SizeOf(FreqEvent),0);
     ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
     {$I-}RESET(FFreqEvent);{$I+}
     IF (IOResult<>0) THEN REWRITE(FFreqEvent)
                      ELSE SEEK(FFreqEvent,FileSize(FFreqEvent));
     WRITE(FFreqEvent,FreqEvent);
     CLOSE(FFreqEvent);
END;


PROCEDURE InsertFreqEvent(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(FreqEvent,SizeOf(FreqEvent),0);
     IF _FileExists(BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FFreqEvent2,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
          RENAME(FFreqEvent2,BaseDirectory+'\DATA\EVENTSF.BAK');
          ASSIGN(FFreqEvent2,BaseDirectory+'\DATA\EVENTSF.BAK');
          ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
          RESET(FFreqEvent2);
          REWRITE(FFreqEvent);
          Counting := 0;
          REPEAT
                READ(FFreqEvent2,FreqEvent2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FFreqEvent,FreqEvent);
                WRITE(FFreqEvent,FreqEvent2);
          UNTIL EOF(FFreqEvent2);
          CLOSE(FFreqEvent);
          CLOSE(FFreqEvent2);
          ERASE(FFreqEvent2);
     END
     ELSE
     BEGIN
          ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
          REWRITE(FFreqEvent);
          WRITE(FFreqEvent,FreqEvent);
          CLOSE(FFreqEvent);
     END;
END;


PROCEDURE DoFreqEvents;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
          RESET(FFreqEvent);
          REPEAT
                Read(FFreqEvent,FreqEvent);
                PickListFile.A := FreqEvent.Description;
                IF FreqEvent.Active THEN PickListFile.B := 'Yes'
                                    ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FFreqEvent);
          CLOSE(FFreqEvent);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
     {$I-}RESET(FFreqEvent);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FFreqEvent);
          CLOSE(FFreqEvent);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Event Description',41);
     PickList_B_Title := 'Active    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('SGMAIL EVENTS - NO FILE REQUESTS - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditFreqEvent(PickItem);
                     ASSIGN(FFreqEvent,BaseDirectory+'\DATA\EVENTSF.'+_String(CurrentNode));
                     RESET(FFreqEvent);
                     PickListItems := FileSize(FFreqEvent);
                     CLOSE(FFreqEvent);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteFreqEvent(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddFreqEvent;
                          EditFreqEvent(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertFreqEvent(PickItem);
                          EditFreqEvent(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddFreqEvent;
                     EditFreqEvent(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


END.