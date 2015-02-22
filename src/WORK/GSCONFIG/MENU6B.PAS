{$I DEFINES.INC}
UNIT MENU6B;


INTERFACE


PROCEDURE DoShuttle;
PROCEDURE DoGrafEdit;
PROCEDURE DoANSIEdit;
PROCEDURE DoRIPEdit;
PROCEDURE DoYappCompiler;
PROCEDURE DoNewUserANSI;
PROCEDURE DoNewUserSVGA;
PROCEDURE DoOpeningSequence;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Dos,BsExec,
     Pick,MenuOpt,Options,Dispatch,FastW1,Valid,BsKeys,BsVideo;


PROCEDURE EditShuttle(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle);
     SEEK(FShuttle,Number-1);
     READ(FShuttle,Shuttle);
     CLOSE(FShuttle);
     Toggle[1].Flips   := 8;
     Toggle[1].Current := Shuttle.Action;
     Toggle[1].Flip[1] := 'ANSI LOGON';
     Toggle[1].Flip[2] := 'TTY LOGON';
     Toggle[1].Flip[3] := 'RIP LOGON';
     Toggle[1].Flip[4] := 'SVGA LOGON';
     Toggle[1].Flip[5] := 'DOWNLOAD FILE';
     Toggle[1].Flip[6] := 'ERRORLEVEL EXIT';
     Toggle[1].Flip[7] := 'HANGUP';
     Toggle[1].Flip[8] := 'DISPLAY TEXT FILE';
     DrawWindow(20,9,78,18,'SHUTTLE LOGON',True);
     AddObject(36,11,1,1,Shuttle.KeyPress,True);
     AddObject(36,12,2,3,_String(Shuttle.ErrorLevel),True);
     AddObject(36,13,8,20,'1',True);
     AddObject(36,14,1,40,Shuttle.Text,True);
     AddButton(68,16,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(22,11); WRITE('    Keypress');
     GotoXY(22,12); WRITE('  ErrorLevel');
     GotoXY(22,13); WRITE(' Option Type');
     GotoXY(22,14); WRITE('    Filename');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Shuttle.KeyPress   := Objects^[1].Stuff[1];
     Shuttle.ErrorLevel := Numeric(Objects^[2].Stuff,ByteInteger);
     Shuttle.Action     := Toggle[1].Current;
     Shuttle.Text       := ValidateIt(Objects^[4].Stuff,'FILE');
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle);
     SEEK(FShuttle,Number-1);
     WRITE(FShuttle,Shuttle);
     CLOSE(FShuttle);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE InsertShuttle(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Shuttle2,SizeOf(Shuttle2),0);
     Shuttle2.Action := 1;
     ASSIGN(FShuttle2,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RENAME(FShuttle2,SelectedLanguage+'\LANG\SHUTTLE.BAK');
     ASSIGN(FShuttle2,SelectedLanguage+'\LANG\SHUTTLE.BAK');
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle2);
     REWRITE(FShuttle);
     Counting := 0;
     REPEAT
           READ(FShuttle2,Shuttle);
           INC(Counting);
           IF Counting=Number THEN WRITE(FShuttle,Shuttle2);
           WRITE(FShuttle,Shuttle);
     UNTIL EOF(FShuttle2);
     CLOSE(FShuttle);
     CLOSE(FShuttle2);
     ERASE(FShuttle2);
END;


PROCEDURE DeleteShuttle(Number: Longint);
BEGIN
     _EraseFileRecord(SelectedLanguage+'\LANG\SHUTTLE.DAT',SizeOf(Shuttle),Number);
END;


PROCEDURE AddShuttle;
BEGIN
     FillChar(Shuttle2,SizeOf(Shuttle2),0);
     Shuttle2.Action := 1;
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle);
     SEEK(FShuttle,FileSize(FShuttle));
     WRITE(FShuttle,Shuttle2);
     CLOSE(FShuttle);
END;


PROCEDURE DoShuttle;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('SHUTTLE.DAT');
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle);
     PickListItems := FileSize(FShuttle);
     CLOSE(FShuttle);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Menu Item',41);
     PickList_B_Title := 'Keypress  ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
     RESET(FShuttle);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FShuttle,Shuttle);
           CASE Shuttle.Action OF
           1:   PickListFile.A := 'ANSI interface logon';
           2:   PickListFile.A := 'TTY interface logon';
           3:   PickListFile.A := 'RIP interface logon';
           4:   PickListFile.A := 'SVGA interface logon';
           5:   PickListFile.A := 'Download a file';
           6:   PickListFile.A := 'Errorlevel exit';
           7:   PickListFile.A := 'Hangup';
           8:   PickListFile.A := 'Display Text File';
           ELSE PickListFile.A := '';
           END;
           PickListFile.B := Shuttle.Keypress;
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FShuttle);
     CLOSE(FShuttle);
     CLOSE(FPickListFile);
     SetUpPickList('SHUTTLE LOGON EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     EditShuttle(PickItem);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     PickListItems := FileSize(FShuttle);
                     CLOSE(FShuttle);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FShuttle,Shuttle);
                           CASE Shuttle.Action OF
                           1:   PickListFile.A := 'ANSI interface logon';
                           2:   PickListFile.A := 'TTY interface logon';
                           3:   PickListFile.A := 'RIP interface logon';
                           4:   PickListFile.A := 'SVGA interface logon';
                           5:   PickListFile.A := 'Download a file';
                           6:   PickListFile.A := 'Errorlevel exit';
                           7:   PickListFile.A := 'Hangup';
                           8:   PickListFile.A := 'Display Text File';
                           ELSE PickListFile.A := '';
                           END;
                           PickListFile.B := Shuttle.Keypress;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FShuttle);
                     CLOSE(FShuttle);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteShuttle(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                          RESET(FShuttle);
                          PickListItems := FileSize(FShuttle);
                          CLOSE(FShuttle);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                          RESET(FShuttle);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FShuttle,Shuttle);
                                CASE Shuttle.Action OF
                                1:   PickListFile.A := 'ANSI interface logon';
                                2:   PickListFile.A := 'TTY interface logon';
                                3:   PickListFile.A := 'RIP interface logon';
                                4:   PickListFile.A := 'SVGA interface logon';
                                5:   PickListFile.A := 'Download a file';
                                6:   PickListFile.A := 'Errorlevel exit';
                                7:   PickListFile.A := 'Hangup';
                                8:   PickListFile.A := 'Display Text File';
                                ELSE PickListFile.A := '';
                                END;
                                PickListFile.B := Shuttle.Keypress;
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FShuttle);
                          CLOSE(FShuttle);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     InsertShuttle(PickItem);
                     EditShuttle(PickItem);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     PickListItems := FileSize(FShuttle);
                     CLOSE(FShuttle);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FShuttle,Shuttle);
                           CASE Shuttle.Action OF
                           1:   PickListFile.A := 'ANSI interface logon';
                           2:   PickListFile.A := 'TTY interface logon';
                           3:   PickListFile.A := 'RIP interface logon';
                           4:   PickListFile.A := 'SVGA interface logon';
                           5:   PickListFile.A := 'Download a file';
                           6:   PickListFile.A := 'Errorlevel exit';
                           7:   PickListFile.A := 'Hangup';
                           8:   PickListFile.A := 'Display Text File';
                           ELSE PickListFile.A := '';
                           END;
                           PickListFile.B := Shuttle.Keypress;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FShuttle);
                     CLOSE(FShuttle);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddShuttle;
                     EditShuttle(PickListItems+1);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     PickListItems := FileSize(FShuttle);
                     CLOSE(FShuttle);
                     ASSIGN(FShuttle,SelectedLanguage+'\LANG\SHUTTLE.DAT');
                     RESET(FShuttle);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FShuttle,Shuttle);
                           CASE Shuttle.Action OF
                           1:   PickListFile.A := 'ANSI interface logon';
                           2:   PickListFile.A := 'TTY interface logon';
                           3:   PickListFile.A := 'RIP interface logon';
                           4:   PickListFile.A := 'SVGA interface logon';
                           5:   PickListFile.A := 'Download a file';
                           6:   PickListFile.A := 'Errorlevel exit';
                           7:   PickListFile.A := 'Hangup';
                           8:   PickListFile.A := 'Display Text File';
                           ELSE PickListFile.A := '';
                           END;
                           PickListFile.B := Shuttle.Keypress;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FShuttle);
                     CLOSE(FShuttle);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoGrafEdit;
BEGIN
     _SaveWindow(WorkDir+'\GEDITOR.SCR');
     _HideMouse;
     TextColor_BS(7);
     TextBackGround_BS(0);
     ClrScr;
     _ShowCursor;
     _HighBackGrounds(False);
     DoExec('GUI.EXE',SelectedLanguage+'\SG\',USE_ALL,WorkDir);
     ChDir(BaseDirectory);
     _HighBackGrounds(True);
     _HideCursor;
     LoadWindow(WorkDir+'\GEDITOR.SCR');
     _ShowMouse;
     MouseSpeed;
END;


PROCEDURE DoANSIEdit;
BEGIN
     _SaveWindow(WorkDir+'\GEDITOR.SCR');
     _HideMouse;
     TextColor_BS(7);
     TextBackGround_BS(0);
     ClrScr;
     _ShowCursor;
     _HighBackGrounds(False);
     ChDir(SelectedLanguage+'\ANSI');
     DoExec(ConfigSetup.ANSIEditor,'',USE_ALL,WorkDir);
     ChDir(BaseDirectory);
     _HighBackGrounds(True);
     _HideCursor;
     LoadWindow(WorkDir+'\GEDITOR.SCR');
     _ShowMouse;
     MouseSpeed;
END;


PROCEDURE DoRIPEdit;
BEGIN
     _SaveWindow(WorkDir+'\GEDITOR.SCR');
     _HideMouse;
     TextColor_BS(7);
     TextBackGround_BS(0);
     ClrScr;
     _ShowCursor;
     _HighBackGrounds(False);
     ChDir(SelectedLanguage+'\RIP');
     DoExec(ConfigSetup.RipEditor,'',USE_ALL,WorkDir);
     ChDir(BaseDirectory);
     _HighBackGrounds(True);
     _HideCursor;
     LoadWindow(WorkDir+'\GEDITOR.SCR');
     _ShowMouse;
     MouseSpeed;
END;


PROCEDURE DoYappCompiler;
BEGIN
     _SaveWindow(WorkDir+'\GCOMPILE.SCR');
     _HideMouse;
     DoExec(BaseDirectory+'\BIN\GCOMPILE.EXE',BaseDirectory+' '+SelectedLanguage+'\SG\*.SG',USE_ALL,WorkDir);
     LoadWindow(WorkDir+'\GCOMPILE.SCR');
     _ShowMouse;
     MouseSpeed;
     _HideCursor;
END;


PROCEDURE DeleteOpening(Number: Longint);
BEGIN
     _EraseFileRecord(SelectedLanguage+'\LANG\OPENING.DAT',SizeOf(Opening),Number);
END;


PROCEDURE InsertOpening(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Opening2,SizeOf(Opening2),0);
     Opening2.FunctionType := 1;
     ASSIGN(FOpening2,SelectedLanguage+'\LANG\Opening.DAT');
     RENAME(FOpening2,SelectedLanguage+'\LANG\Opening.BAK');
     ASSIGN(FOpening2,SelectedLanguage+'\LANG\Opening.BAK');
     ASSIGN(FOpening,SelectedLanguage+'\LANG\Opening.DAT');
     RESET(FOpening2);
     REWRITE(FOpening);
     Counting := 0;
     REPEAT
           READ(FOpening2,Opening);
           INC(Counting);
           IF Counting=Number THEN WRITE(FOpening,Opening2);
           WRITE(FOpening,Opening);
     UNTIL EOF(FOpening2);
     CLOSE(FOpening);
     CLOSE(FOpening2);
     ERASE(FOpening2);
END;


PROCEDURE AddOpening;
BEGIN
     FillChar(Opening2,SizeOf(Opening2),0);
     Opening2.FunctionType := 1;
     ASSIGN(FOpening,SelectedLanguage+'\LANG\Opening.DAT');
     RESET(FOpening);
     SEEK(FOpening,FileSize(FOpening));
     WRITE(FOpening,Opening2);
     CLOSE(FOpening);
END;


PROCEDURE EditOpening(Number: Longint);
VAR  WhichOne : Word;
     Before   : Word;
     After    : Word;

     PROCEDURE RedrawWindow;
     BEGIN
          CASE Opening.FunctionType OF
          1,8,9,10,11,12:
            BEGIN
              Opening.Forced := 1;
              Toggle[1].Flips    := 12;
              Toggle[1].Current  := Opening.FunctionType;
              Toggle[1].Flip[1]  := 'COMMENT LAST CALLER';
              Toggle[1].Flip[2]  := 'WELCOME SCREENS';
              Toggle[1].Flip[3]  := 'ONCE-ONLY SCREENS';
              Toggle[1].Flip[4]  := 'NEWS SCREENS';
              Toggle[1].Flip[5]  := 'LAST CALLERS SCREEN';
              Toggle[1].Flip[6]  := 'NEW MAIL SCAN';
              Toggle[1].Flip[7]  := 'NEW FILES SCAN';
              Toggle[1].Flip[8]  := 'CALL-BACK VERIFIER';
              Toggle[1].Flip[9]  := 'USER SPECIFIC SCREEN';
              Toggle[1].Flip[10] := 'USER ACCESS SCREEN';
              Toggle[1].Flip[11] := 'DATE SPECIFIC SCREEN';
              Toggle[1].Flip[12] := 'USER BIRTHDAY SCREEN';
              AddObject(38,11,8,20,'1',True);
              AddButton(58,14,' QUIT ',True,1,16);
              DrawObjects;
              DrawButtons;
              _HideMouse;
              TextBackGround_BS(Colour.WindowBackGround);
              TextColor_BS(11);
              GotoXY(27,11); WRITE(' Function');
              GotoXY(27,12); WRITE('                    ');
              _ShowMouse;
            END;
          ELSE
            BEGIN
              Toggle[1].Flips    := 12;
              Toggle[1].Current  := Opening.FunctionType;
              Toggle[1].Flip[1]  := 'COMMENT LAST CALLER';
              Toggle[1].Flip[2]  := 'WELCOME SCREENS';
              Toggle[1].Flip[3]  := 'ONCE-ONLY SCREENS';
              Toggle[1].Flip[4]  := 'NEWS SCREENS';
              Toggle[1].Flip[5]  := 'LAST CALLERS SCREEN';
              Toggle[1].Flip[6]  := 'NEW MAIL SCAN';
              Toggle[1].Flip[7]  := 'NEW FILES SCAN';
              Toggle[1].Flip[8]  := 'CALL-BACK VERIFIER';
              Toggle[1].Flip[9]  := 'USER SPECIFIC SCREEN';
              Toggle[1].Flip[10] := 'USER ACCESS SCREEN';
              Toggle[1].Flip[11] := 'DATE SPECIFIC SCREEN';
              Toggle[1].Flip[12] := 'USER BIRTHDAY SCREEN';
              AddObject(38,11,8,20,'1',True);
              AddObject(38,12,6,3,_String(Opening.Forced),True);
              AddButton(58,14,' QUIT ',True,1,16);
              DrawObjects;
              DrawButtons;
              _HideMouse;
              TextBackGround_BS(Colour.WindowBackGround);
              TextColor_BS(11);
              GotoXY(27,11); WRITE(' Function');
              GotoXY(27,12); WRITE('   Forced');
              _ShowMouse;
            END;
          END;
     END;

     PROCEDURE Reload;
     BEGIN
          ClearObjects;
          ClearButtons;
          Opening.FunctionType := Toggle[1].Current;
          Opening.Forced       := Numeric(Objects^[2].Stuff,ByteInteger);
          CASE Opening.FunctionType OF
          1,8,9,10,11,12: Opening.Forced := 1;
          END;
     END;

BEGIN
     DoingOpeningEdit := True;
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
     RESET(FOpening);
     SEEK(FOpening,Number-1);
     READ(FOpening,Opening);
     CLOSE(FOpening);
     DrawWindow(24,9,68,16,'POST LOGON SEQUENCE',True);
     RedrawWindow;
     REPEAT
           Before   := Toggle[1].Current;
           WhichOne := DoObjects;
           After    := Toggle[1].Current;
           IF (Before<>After) THEN
           BEGIN
                Reload;
                RedrawWindow;
           END;
     UNTIL (WhichOne<>0);
     Reload;
     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
     RESET(FOpening);
     SEEK(FOpening,Number-1);
     WRITE(FOpening,Opening);
     CLOSE(FOpening);
     LoadWindow(WorkDir+'\EDITACC.SCR');
     DoingOpeningEdit := False;
END;


PROCEDURE DoOpeningSequence;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
     WhatIsIt  : Array[1..12] Of String;
BEGIN
     WhatIsIt[1]  := 'Comment From Last Caller';
     WhatIsIt[2]  := 'Welcome Screens';
     WhatIsIt[3]  := 'Once-Only Screens';
     WhatIsIt[4]  := 'News Screens';
     WhatIsIt[5]  := 'Last Callers Screens';
     WhatIsIt[6]  := 'New Mail Scan';
     WhatIsIt[7]  := 'New Files Scan';
     WhatIsIt[8]  := 'Call-Back Verifier';
     WhatIsIt[9]  := 'User Specific Screen';
     WhatIsIt[10] := 'User Access Screen';
     WhatIsIt[11] := 'Date Specific Screen';
     WhatIsIt[12] := 'User Birthday Screen';
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('OPENING.DAT');
     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
     RESET(FOpening);
     PickListItems := FileSize(FOpening);
     CLOSE(FOpening);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Logon Function',41);
     PickList_B_Title := 'Forced    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
     RESET(FOpening);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           READ(FOpening,Opening);
           PickListFile.A := WhatIsIt[Opening.FunctionType];
           CASE Opening.Forced OF
           0:   PickListFile.B := 'No';
           1:   PickListFile.B := 'Yes';
           END;
           CASE Opening.FunctionType OF
           1,8,9,10,11,12: PickListFile.B := '';
           END;
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FOpening);
     CLOSE(FOpening);
     CLOSE(FPickListFile);
     SetUpPickList('POST LOGON SEQUENCE EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     EditOpening(PickItem);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     PickListItems := FileSize(FOpening);
                     CLOSE(FOpening);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FOpening,Opening);
                           PickListFile.A := WhatIsIt[Opening.FunctionType];
                           CASE Opening.Forced OF
                           0:   PickListFile.B := 'No';
                           1:   PickListFile.B := 'Yes';
                           END;
                           CASE Opening.FunctionType OF
                           1,8,9,10,11,12: PickListFile.B := '';
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FOpening);
                     CLOSE(FOpening);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteOpening(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                          RESET(FOpening);
                          PickListItems := FileSize(FOpening);
                          CLOSE(FOpening);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                          RESET(FOpening);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                READ(FOpening,Opening);
                                PickListFile.A := WhatIsIt[Opening.FunctionType];
                                CASE Opening.Forced OF
                                0:   PickListFile.B := 'No';
                                1:   PickListFile.B := 'Yes';
                                END;
                                CASE Opening.FunctionType OF
                                1,8,9,10,11,12: PickListFile.B := '';
                                END;
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FOpening);
                          CLOSE(FOpening);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     InsertOpening(PickItem);
                     EditOpening(PickItem);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     PickListItems := FileSize(FOpening);
                     CLOSE(FOpening);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FOpening,Opening);
                           PickListFile.A := WhatIsIt[Opening.FunctionType];
                           CASE Opening.Forced OF
                           0:   PickListFile.B := 'No';
                           1:   PickListFile.B := 'Yes';
                           END;
                           CASE Opening.FunctionType OF
                           1,8,9,10,11,12: PickListFile.B := '';
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FOpening);
                     CLOSE(FOpening);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddOpening;
                     EditOpening(PickListItems+1);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     PickListItems := FileSize(FOpening);
                     CLOSE(FOpening);
                     ASSIGN(FOpening,SelectedLanguage+'\LANG\OPENING.DAT');
                     RESET(FOpening);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FOpening,Opening);
                           PickListFile.A := WhatIsIt[Opening.FunctionType];
                           CASE Opening.Forced OF
                           0:   PickListFile.B := 'No';
                           1:   PickListFile.B := 'Yes';
                           END;
                           CASE Opening.FunctionType OF
                           1,8,9,10,11,12: PickListFile.B := '';
                           END;
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FOpening);
                     CLOSE(FOpening);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditNewUserVga(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga);
     SEEK(FNewUserVga,Number-1);
     READ(FNewUserVga,NewUserVga);
     CLOSE(FNewUserVga);
     DrawWindow(24,9,68,15,'NEW USER SEQUENCE',True);
     AddObject(56,11,1,8,NewUserVga.FileName,True);
     AddButton(58,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(26,11); WRITE('  Screen File (No Extension)');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     NewUserVga.FileName := _UpperCase(Objects^[1].Stuff);
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga);
     SEEK(FNewUserVga,Number-1);
     WRITE(FNewUserVga,NewUserVga);
     CLOSE(FNewUserVga);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteNewUserVga(Number: Longint);
BEGIN
     _EraseFileRecord(SelectedLanguage+'\LANG\NEWUSER.VGA',SizeOf(NewUserVga),Number);
END;


PROCEDURE InsertNewUserVga(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(NewUserVga2,SizeOf(NewUserVga2),0);
     ASSIGN(FNewUserVga2,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RENAME(FNewUserVga2,SelectedLanguage+'\LANG\NEWUSER.BAK');
     ASSIGN(FNewUserVga2,SelectedLanguage+'\LANG\NEWUSER.BAK');
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga2);
     REWRITE(FNewUserVga);
     Counting := 0;
     REPEAT
           READ(FNewUserVga2,NewUserVga);
           INC(Counting);
           IF Counting=Number THEN WRITE(FNewUserVga,NewUserVga2);
           WRITE(FNewUserVga,NewUserVga);
     UNTIL EOF(FNewUserVga2);
     CLOSE(FNewUserVga);
     CLOSE(FNewUserVga2);
     ERASE(FNewUserVga2);
END;


PROCEDURE AddNewUserVga;
BEGIN
     FillChar(NewUserVga2,SizeOf(NewUserVga2),0);
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga);
     SEEK(FNewUserVga,FileSize(FNewUserVga));
     WRITE(FNewUserVga,NewUserVga2);
     CLOSE(FNewUserVga);
END;


PROCEDURE DoNewUserSVGA;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('NEWUSER.VGA');
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga);
     PickListItems := FileSize(FNewUserVga);
     CLOSE(FNewUserVga);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Screen To Load',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
     RESET(FNewUserVga);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           READ(FNewUserVga,NewUserVga);
           PickListFile.A := NewUserVga.FileName;
           PickListFile.B := '';
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FNewUserVga);
     CLOSE(FNewUserVga);
     CLOSE(FPickListFile);
     SetUpPickList('NEW USER QUESTIONAIRE SEQUENCE - SVGA');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN {EDIT}
                     EditNewUserVga(PickItem);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     PickListItems := FileSize(FNewUserVga);
                     CLOSE(FNewUserVga);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FNewUserVga,NewUserVga);
                           PickListFile.A := NewUserVga.FileName;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FNewUserVga);
                     CLOSE(FNewUserVga);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteNewUserVga(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                          RESET(FNewUserVga);
                          PickListItems := FileSize(FNewUserVga);
                          CLOSE(FNewUserVga);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                          RESET(FNewUserVga);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                READ(FNewUserVga,NewUserVga);
                                PickListFile.A := NewUserVga.FileName;
                                PickListFile.B := '';
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FNewUserVga);
                          CLOSE(FNewUserVga);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     InsertNewUserVga(PickItem);
                     EditNewUserVga(PickItem);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     PickListItems := FileSize(FNewUserVga);
                     CLOSE(FNewUserVga);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FNewUserVga,NewUserVga);
                           PickListFile.A := NewUserVga.FileName;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FNewUserVga);
                     CLOSE(FNewUserVga);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddNewUserVga;
                     EditNewUserVga(PickListItems+1);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     PickListItems := FileSize(FNewUserVga);
                     CLOSE(FNewUserVga);
                     ASSIGN(FNewUserVga,SelectedLanguage+'\LANG\NEWUSER.VGA');
                     RESET(FNewUserVga);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           READ(FNewUserVga,NewUserVga);
                           PickListFile.A := NewUserVga.FileName;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FNewUserVga);
                     CLOSE(FNewUserVga);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DeleteNewUserANSI(Number: Longint);
BEGIN
     _EraseFileRecord(SelectedLanguage+'\LANG\NEWUSER.ANS',SizeOf(NewUserANSI),Number);
END;


PROCEDURE DoNewUserANSI;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
     WhatIsIt  : Array[1..18] Of String[26];

     PROCEDURE DrawIt(Cur: Word);
     VAR  Pooper : Word;
     BEGIN
          FOR Pooper := 1 TO 18 DO
          BEGIN
               IF Pooper=Cur THEN FastWrite(WhatIsIt[Pooper],3+Pooper,33,(3*16)+15)
                             ELSE FastWrite(WhatIsIt[Pooper],3+Pooper,33,(1*16)+15);
          END;
     END;

     PROCEDURE LoadItUp;
     VAR  C       : Char;
          Current : Byte;
     BEGIN
          Current := 1;
          _SaveWindow(WorkDir+'\EDITNEWU.SCR');
          DrawWindow(30,2,62,23,'QUESTIONAIRE FUNCTIONS',True);
          _HideMouse;
          InvertedBox(32,3,60,22);
          DrawIt(Current);
          _ShowMouse;
          C := #0;
          REPEAT
                IF KeyPressed THEN
                BEGIN
                     C := ReadKey;
                     IF ORD(C)=0 THEN
                     BEGIN
                          C := ReadKey;
                          CASE Ord(C) OF
                          72:  IF Current>1 THEN
                               BEGIN
                                    DEC(Current);
                                    _HideMouse;
                                    DrawIt(Current);
                                    _ShowMouse;
                               END;
                          80:  IF Current<18 THEN
                               BEGIN
                                    INC(Current);
                                    _HideMouse;
                                    DrawIt(Current);
                                    _ShowMouse;
                               END;
                          END;
                          C := #0;
                     END;
                END;
          UNTIL C=#13;
          NewUserANSI2.FunctionType := Current;
          NewUserANSI2.Required     := 1;
          NewUserANSI2.FileName     := '';
          CASE NewUserANSI2.FunctionType OF
          1:      BEGIN
                       DrawWindow(24,9,68,15,'NEW USER SEQUENCE',True);
                       AddObject(56,11,1,8,NewUserANSI2.FileName,True);
                       AddButton(58,13,' QUIT ',True,1,16);
                       DrawObjects;
                       DrawButtons;
                       _HideMouse;
                       TextBackGround_BS(Colour.WindowBackGround);
                       TextColor_BS(11);
                       GotoXY(26,11); WRITE('  Screen File (No Extension)');
                       _ShowMouse;
                       DoObjects;
                       ClearObjects;
                       ClearButtons;
                       NewUserANSI2.FileName := _UpperCase(Objects^[1].Stuff);
                  END;
          4..12,
          15..17: BEGIN
                       DrawWindow(24,9,68,15,'NEW USER SEQUENCE',True);
                       AddObject(56,11,6,3,_String(NewUserANSI2.Required),True);
                       AddButton(58,13,' QUIT ',True,1,16);
                       DrawObjects;
                       DrawButtons;
                       _HideMouse;
                       TextBackGround_BS(Colour.WindowBackGround);
                       TextColor_BS(11);
                       GotoXY(26,11); WRITE('   Is this a required entry?');
                       _ShowMouse;
                       DoObjects;
                       ClearObjects;
                       ClearButtons;
                       NewUserANSI2.Required := Numeric(Objects^[1].Stuff,ByteInteger);
                  END;
          END;
          LoadWindow(WorkDir+'\EDITNEWU.SCR');
     END;

     PROCEDURE UpdateItems;
     BEGIN
          ASSIGN(FNewUserANSI,SelectedLanguage+'\LANG\NEWUSER.ANS');
          RESET(FNewUserANSI);
          PickListItems := FileSize(FNewUserANSI);
          CLOSE(FNewUserANSI);
     END;

     PROCEDURE ReloadThePickList;
     BEGIN
          ASSIGN(FNewUserANSI,SelectedLanguage+'\LANG\NEWUSER.ANS');
          RESET(FNewUserANSI);
          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
          REWRITE(FPickListFile);
          REPEAT
                READ(FNewUserANSI,NewUserANSI);
                PickListFile.A := WhatIsIt[NewUserANSI.FunctionType];
                IF NewUserANSI.Required=1 THEN PickListFile.B := 'Yes'
                                          ELSE PickListFile.B := 'No';
                CASE NewUserANSI.FunctionType OF
                1:   PickListFile.A := ' Display File ('+NewUserANSI.FileName+')';
                2,3,13,14,18: PickListFile.B := 'Yes';
                END;
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FNewUserANSI);
          CLOSE(FNewUserANSI);
          CLOSE(FPickListFile);
     END;

     PROCEDURE InsertNewUserANSI(Number: Longint);
     VAR  Counting : Longint;
     BEGIN
          FillChar(NewUserANSI2,SizeOf(NewUserANSI2),0);
          LoadItUp;
          ASSIGN(FNewUserANSI2,SelectedLanguage+'\LANG\NEWUSER.ANS');
          RENAME(FNewUserANSI2,SelectedLanguage+'\LANG\NEWUSER.BAK');
          ASSIGN(FNewUserANSI2,SelectedLanguage+'\LANG\NEWUSER.BAK');
          ASSIGN(FNewUserANSI,SelectedLanguage+'\LANG\NEWUSER.ANS');
          RESET(FNewUserANSI2);
          REWRITE(FNewUserANSI);
          Counting := 0;
          REPEAT
                READ(FNewUserANSI2,NewUserANSI);
                INC(Counting);
                IF Counting=Number THEN WRITE(FNewUserANSI,NewUserANSI2);
                WRITE(FNewUserANSI,NewUserANSI);
          UNTIL EOF(FNewUserANSI2);
          CLOSE(FNewUserANSI);
          CLOSE(FNewUserANSI2);
          ERASE(FNewUserANSI2);
     END;

     PROCEDURE AddNewUserANSI;
     BEGIN
          FillChar(NewUserANSI2,SizeOf(NewUserANSI2),0);
          LoadItUp;
          ASSIGN(FNewUserANSI,SelectedLanguage+'\LANG\NEWUSER.ANS');
          RESET(FNewUserANSI);
          SEEK(FNewUserANSI,FileSize(FNewUserANSI));
          WRITE(FNewUserANSI,NewUserANSI2);
          CLOSE(FNewUserANSI);
     END;

BEGIN
     WhatIsIt[1]  := ' Display File             ';
     WhatIsIt[2]  := ' Get Password             ';
     WhatIsIt[3]  := ' Verify Password          ';
     WhatIsIt[4]  := ' Get Data Phone Number    ';
     WhatIsIt[5]  := ' Get Voice Phone Number   ';
     WhatIsIt[6]  := ' Get Street Address       ';
     WhatIsIt[7]  := ' Get City                 ';
     WhatIsIt[8]  := ' Get Province/State       ';
     WhatIsIt[9]  := ' Get Country              ';
     WhatIsIt[10] := ' Get Postal Code          ';
     WhatIsIt[11] := ' Get Alias                ';
     WhatIsIt[12] := ' Get Birthday             ';
     WhatIsIt[13] := ' Get Gender               ';
     WhatIsIt[14] := ' Get IBM Characters       ';
     WhatIsIt[15] := ' Get BBS Name             ';
     WhatIsIt[16] := ' Get BBS Phone Number     ';
     WhatIsIt[17] := ' Get Network Address      ';
     WhatIsIt[18] := ' Get Enter Keypress       ';
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('NEWUSER.ANS');
     UpdateItems;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Questionaire Function',41);
     PickList_B_Title := 'Forced    ';
     PickListX        := 11;
     PickListY        := 4;
     ReloadThePickList;
     SetUpPickList('NEW USER QUESTIONAIRE SEQUENCE - ANSI/RIP/TTY');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteNewUserANSI(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          UpdateItems;
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ReloadThePickList;
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     InsertNewUserANSI(PickItem);
                     UpdateItems;
                     ReloadThePickList;
                     UpdatePickList;
                END;
           5:   BEGIN {ADD}
                     AddNewUserANSI;
                     UpdateItems;
                     ReloadThePickList;
                     UpdatePickList;
                END;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


END.
