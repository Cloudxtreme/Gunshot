{$I DEFINES.INC}
UNIT MENU4;


INTERFACE


PROCEDURE DoMessageSubs;
PROCEDURE DoMessageAreas;
PROCEDURE DoBadLanguage;
PROCEDURE DoQWKSetup;
PROCEDURE DoAreasBBSImport;
PROCEDURE DoAreasBBSExport;
PROCEDURE DoSystemReports;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,FMode,
     Dos,Dispatch,FastW1,Valid,Misc,Shotgun,BsMulti,BsAkas,BsVideo;


PROCEDURE GlobalMessageChange(Number: Longint);
VAR  AreasDone    : Word;
     FPosition    : Longint;
     Loop         : Word;
     C            : Char;
BEGIN
     AreasDone := 0;
     FPosition := 0;
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
           READ(FMessageArea,MessageArea);
           IF MessageArea.Sub=Number THEN
           BEGIN
                INC(AreasDone);
                MessageArea.Read_Access       := MessageSubs.Read_Access;
                MessageArea.Write_Access      := MessageSubs.Write_Access;
                FOR Loop := 1 TO 10 DO MessageArea.Tags[Loop] := MessageSubs.Tags[Loop];
                MessageArea.File_Attaches     := MessageSubs.File_Attaches;
                MessageArea.File_Attaches_Sec := MessageSubs.File_Attaches_Sec;
                MessageArea.Area_Type         := MessageSubs.Area_Type;
                MessageArea.Msg_Type          := MessageSubs.Msg_Type;
                MessageArea.DoGraphics        := MessageSubs.DoGraphics;
                MessageArea.CleanLanguage     := MessageSubs.CleanLanguage;
                MessageArea.Address           := MessageSubs.Address;
                MessageArea.Origin            := MessageSubs.Origin;
                MessageArea.MaxMsgs           := MessageSubs.MaxMsgs;
                SEEK(FMessageArea,FPosition);
                WRITE(FMessageArea,MessageArea);
           END;
           INC(FPosition);
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     InfoBox('GLOBAL GROUP CHANGES','Message areas changed: '+_String(AreasDone),' ','<<Press a key>>');
     ReadKey;
     IF KeyPressed THEN C := ReadKey;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE EditMessageSub(Number: Longint);
VAR  Action : Word;
LABEL         OverAgain;

     PROCEDURE ReLoad;
     VAR  Loop : Word;
     BEGIN
          ClearObjects;
          ClearButtons;
          MessageSubs.Sub_Num     := Numeric(Objects^[1].Stuff,WordInteger);
          MessageSubs.Sub_Name    := Objects^[2].Stuff;
          MessageSubs.ScanAtLogon := ToBoolean(Objects^[3].Stuff);
          MessageSubs.Base_Type   := Toggle[4].Current;
          MessageSubs.Msg_Type    := Toggle[3].Current;
          CASE Toggle[1].Current OF
          1:   MessageSubs.Area_Type := 0;
          2:   MessageSubs.Area_Type := 9;
          3:   MessageSubs.Area_Type := 19;
          4:   MessageSubs.Area_Type := 29;
          END;
          MessageSubs.Area_Type := MessageSubs.Area_Type+Toggle[2].Current;
          FOR Loop := 1 TO 10 DO
          BEGIN
               IF Objects^[8].Stuff[Loop]='1'
                  THEN MessageSubs.Tags[Loop] := 1
                  ELSE MessageSubs.Tags[Loop] := 0;
          END;
          MessageSubs.Read_Access       := Numeric(Objects^[9].Stuff,WordInteger);
          MessageSubs.Write_Access      := Numeric(Objects^[10].Stuff,WordInteger);
          MessageSubs.Dos_Name          := ValidateIt(Objects^[11].Stuff,'PATH');
          MessageSubs.Address           := Numeric(Objects^[12].Stuff,ByteInteger);
          MessageSubs.Origin            := Numeric(Objects^[13].Stuff,ByteInteger);
          MessageSubs.BackBoneNa        := ValidateIt(Objects^[14].Stuff,'FILE');
          MessageSubs.MaxMsgs           := Numeric(Objects^[15].Stuff,WordInteger);
          MessageSubs.File_Attaches     := Numeric(Objects^[16].Stuff,ByteInteger);
          MessageSubs.File_Attaches_Sec := Numeric(Objects^[17].Stuff,WordInteger);
          MessageSubs.DoGraphics        := Numeric(Objects^[18].Stuff,ByteInteger);
          MessageSubs.CleanLanguage     := Numeric(Objects^[19].Stuff,ByteInteger);
          ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
          RESET(FMessageSubs);
          SEEK(FMessageSubs,Number-1);
          WRITE(FMessageSubs,MessageSubs);
          CLOSE(FMessageSubs);
          DoingSubChange := False;
     END;

BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs);
     SEEK(FMessageSubs,Number-1);
     READ(FMessageSubs,MessageSubs);
     CLOSE(FMessageSubs);
     DoingSubChange := True;
     Toggle[1].Flips   := 4;
     Toggle[1].Flip[1] := 'LOCAL';
     Toggle[1].Flip[2] := 'ECHO MAIL';
     Toggle[1].Flip[3] := 'NET MAIL';
     Toggle[1].Flip[4] := 'GATED UUCP MAIL';
     Toggle[2].Flips   := 3;
     Toggle[2].Flip[1] := 'PUBLIC ONLY';
     Toggle[2].Flip[2] := 'PRIVATE ONLY';
     Toggle[2].Flip[3] := 'PUBLIC/PRIVATE';
     Toggle[3].Flips   := 3;
     Toggle[3].Current := MessageSubs.Msg_Type;
     Toggle[3].Flip[1] := 'REAL NAMES ONLY';
     Toggle[3].Flip[2] := 'ALIAS NAMES ONLY';
     Toggle[3].Flip[3] := 'REAL/ALIASES';
     Toggle[4].Flips   := 3;
     Toggle[4].Current := MessageSubs.Base_Type;
     Toggle[4].Flip[1] := 'JAM';
     Toggle[4].Flip[2] := 'SQUISH';
     Toggle[4].Flip[3] := 'FIDO (*.MSG)';
     {LOCAL/ECHO/NET}
     CASE MessageSubs.Area_Type OF
     1:   Toggle[1].Current := 1;
     2:   Toggle[1].Current := 1;
     3:   Toggle[1].Current := 1;
     10:  Toggle[1].Current := 2;
     11:  Toggle[1].Current := 2;
     12:  Toggle[1].Current := 2;
     20:  Toggle[1].Current := 3;
     21:  Toggle[1].Current := 3;
     22:  Toggle[1].Current := 3;
     30:  Toggle[1].Current := 4;
     31:  Toggle[1].Current := 4;
     32:  Toggle[1].Current := 4;
     END;
     {PUBLIC/PRIVATE}
     CASE MessageSubs.Area_Type OF
     1:   Toggle[2].Current := 1;
     2:   Toggle[2].Current := 2;
     3:   Toggle[2].Current := 3;
     10:  Toggle[2].Current := 1;
     11:  Toggle[2].Current := 2;
     12:  Toggle[2].Current := 3;
     20:  Toggle[2].Current := 1;
     21:  Toggle[2].Current := 2;
     22:  Toggle[2].Current := 3;
     30:  Toggle[2].Current := 1;
     31:  Toggle[2].Current := 2;
     32:  Toggle[2].Current := 3;
     END;
     _SaveWindow(WorkDir+'\EDITGRP.SCR');
     OverAgain:
     DrawWindow(5,2,78,24,'EDIT MESSAGE SUB GROUP',True);
     AddObject(26,4,2,5,_String(MessageSubs.Sub_Num),True);
     AddObject(26,5,1,30,MessageSubs.Sub_Name,True);
     AddObject(26,6,6,3,FromBoolean(MessageSubs.ScanAtLogon),True);
     AddObject(26,10,8,20,'4',True);
     AddObject(26,11,8,20,'1',True);
     AddObject(26,12,8,20,'2',True);
     AddObject(26,13,8,20,'3',True);
     AddObject(26,14,7,10,Tags(MessageSubs.Tags),True);
     AddObject(26,15,2,5,_String(MessageSubs.Read_Access),True);
     AddObject(26,16,2,5,_String(MessageSubs.Write_Access),True);
     AddObject(26,17,1,50,MessageSubs.Dos_Name,True);
     AddObject(26,18,2,3,_String(MessageSubs.Address),True);
     AddObject(26,19,2,3,_String(MessageSubs.Origin),True);
     AddObject(26,20,1,40,MessageSubs.BackBoneNa,True);
     AddObject(71,10,2,5,_String(MessageSubs.MaxMsgs),True);
     AddObject(71,11,6,3,_String(MessageSubs.File_Attaches),True);
     AddObject(71,12,2,5,_String(MessageSubs.File_Attaches_Sec),True);
     AddObject(71,13,6,3,_String(MessageSubs.DoGraphics),True);
     AddObject(71,14,6,3,_String(MessageSubs.CleanLanguage),True);
     AddButton(49,22,' QUIT ',True,1,16);
     AddButton(57,22,' GLOBAL ',True,1,34);
     AddButton(67,22,' UPLINK ',True,1,22);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(15);
     GotoXY(8,8);   WRITE('Group Defaults');
     TextColor_BS(9);
     GotoXY(6,7);   WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(6,9);   WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(6,21);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     TextColor_BS(11);
     GotoXY(8,4);   WRITE('    Group Number');
     GotoXY(8,5);   WRITE('     Verbal Name');
     GotoXY(8,6);   WRITE('   Scan At Logon');
     GotoXY(8,10);  WRITE('   Msg Base Type');
     GotoXY(8,11);  WRITE('  Echo/Local/Net');
     GotoXY(8,12);  WRITE('  Public/Private');
     GotoXY(8,13);  WRITE('Real/Alias Names');
     GotoXY(8,14);  WRITE('       Area Tags');
     GotoXY(8,15);  WRITE('     Read Access');
     GotoXY(8,16);  WRITE('    Write Access');
     GotoXY(8,17);  WRITE(' Auto Create Dir');
     GotoXY(8,18);  WRITE('     Net Address');
     GotoXY(8,19);  WRITE('     Origin Line');
     GotoXY(8,20);  WRITE('BACKBONE.NA File');
     GotoXY(49,10); WRITE('        Max Messages');
     GotoXY(49,11); WRITE(' Allow File Attaches');
     GotoXY(49,12); WRITE('File Attach Security');
     GotoXY(49,13); WRITE('    Graphics Allowed');
     GotoXY(49,14); WRITE('     Censor Language');
     TextColor_BS(14);
     GotoXY(31,18);
     WRITE(GetNetAddress(MessageSubs.Address));
     WRITE('@'+GetNetDomain(MessageSubs.Address));
     GotoXY(31,19);
     WRITE(_Mid(GetNetOrigin(MessageSubs.Origin),1,43));
     IF LENGTH(GetNetOrigin(MessageSubs.Origin))>43 THEN WRITE(CHR(16));
     _ShowMouse;
     REPEAT
       Action := DoObjects;
       CASE Action OF
       2:   BEGIN
              Reload;
              GlobalMessageChange(MessageSubs.Sub_Num);
              GOTO OverAgain;
            END;
       3:   BEGIN
              Reload;
              DrawWindow(8,7,65,15,'UPLINK FOR THIS GROUP',True);
              AddObject(31,9,1,20,AddressToString(MessageSubs.Uplink),True);
              AddObject(31,10,1,30,MessageSubs.AreaManager,True);
              AddObject(31,11,1,30,_UpperCase(MessageSubs.YourPassword),True);
              AddObject(31,12,6,3,FromBoolean(MessageSubs.AutoRequests),True);
              AddButton(55,13,' QUIT ',True,1,16);
              DrawObjects;
              DrawButtons;
              _HideMouse;
              TextBackGround_BS(Colour.WindowBackGround);
              TextColor_BS(11);
              GotoXY(12,9);  WRITE('      Network Aka');
              GotoXY(12,10); WRITE('     Areafix Name');
              GotoXY(12,11); WRITE(' Areafix Password');
              GotoXY(12,12); WRITE('Upstream Requests');
              _ShowMouse;
              DoObjects;
              ClearObjects;
              ClearButtons;
              StringToAddress(Objects^[1].Stuff,MessageSubs.Uplink);
              MessageSubs.AreaManager  := Objects^[2].Stuff;
              MessageSubs.YourPassword := _UpperCase(Objects^[3].Stuff);
              MessageSubs.AutoRequests := ToBoolean(Objects^[4].Stuff);
              GOTO OverAgain;
            END;
       END;
     UNTIL Action=1;
     Reload;
     LoadWindow(WorkDir+'\EDITGRP.SCR');
END;


PROCEDURE AddMessageSub;
BEGIN
     FillChar(MessageSubs2,SizeOf(MessageSubs2),0);
     MessageSubs2.base_type   := 2;
     MessageSubs2.area_type   := 1;
     MessageSubs2.msg_type    := 1;
     MessageSubs2.origin      := 1;
     MessageSubs2.address     := 1;
     MessageSubs2.ScanAtLogon := True;
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs);
     SEEK(FMessageSubs,FileSize(FMessageSubs));
     WRITE(FMessageSubs,MessageSubs2);
     CLOSE(FMessageSubs);
END;


PROCEDURE InsertMessageSub(Number: Longint);
VAR  FMessageSubs2 : File Of _MessageSub_Record;
     Counting      : Longint;
BEGIN
     FillChar(MessageSubs2,SizeOf(MessageSubs2),0);
     MessageSubs2.base_type   := 2;
     MessageSubs2.area_type   := 1;
     MessageSubs2.msg_type    := 1;
     MessageSubs2.origin      := 1;
     MessageSubs2.address     := 1;
     MessageSubs2.ScanAtLogon := True;
     ASSIGN(FMessageSubs2,BaseDirectory+'\DATA\MSGAREA.SUB');
     RENAME(FMessageSubs2,BaseDirectory+'\DATA\MSGAREA.BAK');
     ASSIGN(FMessageSubs2,BaseDirectory+'\DATA\MSGAREA.BAK');
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs2);
     REWRITE(FMessageSubs);
     Counting := 0;
     REPEAT
           READ(FMessageSubs2,MessageSubs);
           INC(Counting);
           IF Counting=Number THEN WRITE(FMessageSubs,MessageSubs2);
           WRITE(FMessageSubs,MessageSubs);
     UNTIL EOF(FMessageSubs2);
     CLOSE(FMessageSubs);
     CLOSE(FMessageSubs2);
     ERASE(FMessageSubs2);
END;


PROCEDURE DeleteMessageSub(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\MSGAREA.SUB',SizeOf(MessageSubs),Number);
END;


PROCEDURE DoMessageSubs;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage := 16;
     PickItem        := 1;
     PickTop         := 1;
     CheckFile('MSGAREA.SUB');
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs);
     PickListItems := FileSize(FMessageSubs);
     CLOSE(FMessageSubs);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Sub Group Name',41);
     PickList_B_Title := 'Numeric   ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FMessageSubs,MessageSubs);
           PickListFile.A := MessageSubs.Sub_Name;
           PickListFile.B := _String(MessageSubs.Sub_Num);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);
     CLOSE(FPickListFile);
     SetUpPickList('MESSAGE CONFERENCE SUB GROUPS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditMessageSub(PickItem);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     PickListItems := FileSize(FMessageSubs);
                     CLOSE(FMessageSubs);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageSubs,MessageSubs);
                           PickListFile.A := MessageSubs.Sub_Name;
                           PickListFile.B := _String(MessageSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageSubs);
                     CLOSE(FMessageSubs);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteMessageSub(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                          RESET(FMessageSubs);
                          PickListItems := FileSize(FMessageSubs);
                          CLOSE(FMessageSubs);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                          RESET(FMessageSubs);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FMessageSubs,MessageSubs);
                                PickListFile.A := MessageSubs.Sub_Name;
                                PickListFile.B := _String(MessageSubs.Sub_Num);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FMessageSubs);
                          CLOSE(FMessageSubs);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertMessageSub(PickItem);
                     EditMessageSub(PickItem);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     PickListItems := FileSize(FMessageSubs);
                     CLOSE(FMessageSubs);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageSubs,MessageSubs);
                           PickListFile.A := MessageSubs.Sub_Name;
                           PickListFile.B := _String(MessageSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageSubs);
                     CLOSE(FMessageSubs);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddMessageSub;
                     EditMessageSub(PickListItems+1);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     PickListItems := FileSize(FMessageSubs);
                     CLOSE(FMessageSubs);
                     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
                     RESET(FMessageSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageSubs,MessageSubs);
                           PickListFile.A := MessageSubs.Sub_Name;
                           PickListFile.B := _String(MessageSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageSubs);
                     CLOSE(FMessageSubs);
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


PROCEDURE EditMessageArea(Number: Longint);
VAR  Loop         : Word;
BEGIN
     DoingMessageEdit := True;
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     SEEK(FMessageArea,Number-1);
     READ(FMessageArea,MessageArea);
     CLOSE(FMessageArea);
     Toggle[1].Flips   := 4;
     Toggle[1].Flip[1] := 'LOCAL';
     Toggle[1].Flip[2] := 'ECHO MAIL';
     Toggle[1].Flip[3] := 'NET MAIL';
     Toggle[1].Flip[4] := 'GATED UUCP MAIL';
     Toggle[2].Flips   := 3;
     Toggle[2].Flip[1] := 'PUBLIC ONLY';
     Toggle[2].Flip[2] := 'PRIVATE ONLY';
     Toggle[2].Flip[3] := 'PUBLIC/PRIVATE';
     Toggle[3].Flips   := 3;
     Toggle[3].Current := MessageArea.Msg_Type;
     Toggle[3].Flip[1] := 'REAL NAMES ONLY';
     Toggle[3].Flip[2] := 'ALIAS NAMES ONLY';
     Toggle[3].Flip[3] := 'REAL/ALIASES';
     Toggle[4].Flips   := 3;
     Toggle[4].Current := MessageArea.Base_Type;
     Toggle[4].Flip[1] := 'JAM';
     Toggle[4].Flip[2] := 'SQUISH';
     Toggle[4].Flip[3] := 'FIDO (*.MSG)';
     {LOCAL/ECHO/NET}
     CASE MessageArea.Area_Type OF
     1:   Toggle[1].Current := 1;
     2:   Toggle[1].Current := 1;
     3:   Toggle[1].Current := 1;
     10:  Toggle[1].Current := 2;
     11:  Toggle[1].Current := 2;
     12:  Toggle[1].Current := 2;
     20:  Toggle[1].Current := 3;
     21:  Toggle[1].Current := 3;
     22:  Toggle[1].Current := 3;
     30:  Toggle[1].Current := 4;
     31:  Toggle[1].Current := 4;
     32:  Toggle[1].Current := 4;
     END;
     {PUBLIC/PRIVATE}
     CASE MessageArea.Area_Type OF
     1:   Toggle[2].Current := 1;
     2:   Toggle[2].Current := 2;
     3:   Toggle[2].Current := 3;
     10:  Toggle[2].Current := 1;
     11:  Toggle[2].Current := 2;
     12:  Toggle[2].Current := 3;
     20:  Toggle[2].Current := 1;
     21:  Toggle[2].Current := 2;
     22:  Toggle[2].Current := 3;
     30:  Toggle[2].Current := 1;
     31:  Toggle[2].Current := 2;
     32:  Toggle[2].Current := 3;
     END;
     DrawWindow(6,2,75,24,'EDIT MESSAGE AREA',True);
     AddObject(23,4 ,1,40,MessageArea.Area_Name,True);
     AddObject(23,5 ,1,40,MessageArea.Area_Tag,True);
     AddObject(23,6 ,1,50,MessageArea.DOS_Name,True);
     AddObject(23,7 ,2,5 ,_String(MessageArea.Sub),True);
     AddObject(43,7 ,1,30,MessageArea.Sysop,True);
     AddObject(27,9 ,2,5 ,_String(MessageArea.Read_Access),True);
     AddObject(27,10,2,5 ,_String(MessageArea.Write_Access),True);
     AddObject(27,11,7,10,Tags(MessageArea.Tags),True);
     AddObject(64,9 ,6,3 ,_String(MessageArea.File_Attaches),True);
     AddObject(64,10,2,5 ,_String(MessageArea.File_Attaches_Sec),True);
     AddObject(27,13,8,20,'4',True);
     AddObject(27,14,8,20,'1',True);
     AddObject(27,15,8,20,'2',True);
     AddObject(27,16,8,20,'3',True);
     AddObject(68,13,6,3 ,_String(MessageArea.DoGraphics),True);
     AddObject(68,14,6,3 ,_String(MessageArea.CleanLanguage),True);
     AddObject(68,15,6,3 ,_String(MessageArea.ForcedTo),True);
     AddObject(23,18,2,3 ,_String(MessageArea.Address),True);
     AddObject(23,19,2,3 ,_String(MessageArea.Origin),True);
     AddObject(23,20,1,50,MessageArea.NodeList,True);
     AddObject(23,21,2,5,_String(MessageArea.AreaID),True);
     AddObject(23,22,2,5,_String(MessageArea.MaxMsgs),True);
     AddButton(65,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(7,8);   WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(7,12);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(7,17);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     TextColor_BS(11);
     GotoXY(8,4);   WRITE('    Area Name');
     GotoXY(8,5);   WRITE('Echo Area Tag');
     GotoXY(8,6);   WRITE('DOS Path/File');
     GotoXY(8,7);   WRITE('    Sub Group');
     GotoXY(31,7);  WRITE('Area Sysop');
     GotoXY(12,9);  WRITE('  Read Access');
     GotoXY(12,10); WRITE(' Write Access');
     GotoXY(12,11); WRITE('    Area Tags');
     GotoXY(42,9);  WRITE(' Allow File Attaches');
     GotoXY(42,10); WRITE('File Attach Security');
     GotoXY(8,18);  WRITE('  Net Address');
     GotoXY(8,19);  WRITE('  Origin Line');
     GotoXY(8,20);  WRITE(' Nodelist Dir');
     GotoXY(8,21);  WRITE('  Msg Area ID');
     GotoXY(8,22);  WRITE(' Max Messages');
     GotoXY(8 ,13); WRITE('Message Base Type');
     GotoXY(9 ,14); WRITE('  Echo/Local/Net');
     GotoXY(9 ,15); WRITE('  Public/Private');
     GotoXY(9 ,16); WRITE('Real/Alias Names');
     GotoXY(50,13); WRITE('Graphics Allowed');
     GotoXY(50,14); WRITE(' Censor Language');
     GotoXY(49,15); WRITE('Forced "TO" Field');
     TextColor_BS(14);
     GotoXY(28,18);
     WRITE(GetNetAddress(MessageArea.Address));
     WRITE('@'+GetNetDomain(MessageArea.Address));
     GotoXY(28,19);
     WRITE(_Mid(GetNetOrigin(MessageArea.Origin),1,43));
     IF LENGTH(GetNetOrigin(MessageArea.Origin))>43 THEN WRITE(CHR(16));
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     MessageArea.Area_Name         := Objects^[1].Stuff;
     MessageArea.Area_Tag          := _UpperCase(Objects^[2].Stuff);

     MessageArea.Sub               := Numeric(Objects^[4].Stuff,WordInteger);
     MessageArea.Sysop             := Objects^[5].Stuff;
     MessageArea.Read_Access       := Numeric(Objects^[6].Stuff,WordInteger);
     MessageArea.Write_Access      := Numeric(Objects^[7].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[8].Stuff[Loop]='1' THEN MessageArea.Tags[Loop] := 1
                                         ELSE MessageArea.Tags[Loop] := 0;
     END;
     MessageArea.File_Attaches     := Numeric(Objects^[9].Stuff,ByteInteger);
     MessageArea.File_Attaches_Sec := Numeric(Objects^[10].Stuff,WordInteger);
     MessageArea.Base_Type         := Toggle[4].Current;
     IF MessageArea.Base_Type=3
        THEN MessageArea.DOS_Name := ValidateIt(Objects^[3].Stuff,'PATH')
        ELSE MessageArea.DOS_Name := ValidateIt(Objects^[3].Stuff,'FILE');
     CASE Toggle[1].Current OF
     1:   MessageArea.Area_Type := 0;
     2:   MessageArea.Area_Type := 9;
     3:   MessageArea.Area_Type := 19;
     4:   MessageArea.Area_Type := 29;
     END;
     MessageArea.Area_Type         := MessageArea.Area_Type+Toggle[2].Current;
     MessageArea.Msg_Type          := Toggle[3].Current;
     MessageArea.DoGraphics        := Numeric(Objects^[15].Stuff,ByteInteger);
     MessageArea.CleanLanguage     := Numeric(Objects^[16].Stuff,ByteInteger);
     MessageArea.ForcedTo          := Numeric(Objects^[17].Stuff,ByteInteger);
     MessageArea.Address           := Numeric(Objects^[18].Stuff,ByteInteger);
     MessageArea.Origin            := Numeric(Objects^[19].Stuff,ByteInteger);
     MessageArea.NodeList          := ValidateIt(Objects^[20].Stuff,'PATH');
     MessageArea.AreaID            := Numeric(Objects^[21].Stuff,WordInteger);
     MessageArea.MaxMsgs           := Numeric(Objects^[22].Stuff,WordInteger);
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     SEEK(FMessageArea,Number-1);
     WRITE(FMessageArea,MessageArea);
     CLOSE(FMessageArea);
     LoadWindow(WorkDir+'\EDITACC.SCR');
     DoingMessageEdit := False;
END;


FUNCTION GetHighMsg: Word;
VAR  Highest : Word;
BEGIN
     Highest := 0;
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
           READ(FMessageArea,MessageArea);
           IF MessageArea.AreaID>Highest THEN
              Highest := MessageArea.AreaID;
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     GetHighMsg := Highest;
END;


PROCEDURE InsertMessageArea(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(MessageArea2,SizeOf(MessageArea2),0);
     MessageArea2.Base_Type         := 2;
     MessageArea2.Area_Type         := 1;
     MessageArea2.Msg_Type          := 1;
     MessageArea2.sub               := 1;
     MessageArea2.file_attaches_sec := 32000;
     MessageArea2.origin            := 1;
     MessageArea2.address           := 1;
     MessageArea2.AreaID            := GetHighMsg+1;
     ASSIGN(FMessageArea2,BaseDirectory+'\DATA\MA000000.DAT');
     RENAME(FMessageArea2,BaseDirectory+'\DATA\MSGAREA.BAK');
     ASSIGN(FMessageArea2,BaseDirectory+'\DATA\MSGAREA.BAK');
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea2);
     REWRITE(FMessageArea);
     Counting := 0;
     REPEAT
           READ(FMessageArea2,MessageArea);
           INC(Counting);
           IF Counting=Number THEN WRITE(FMessageArea,MessageArea2);
           WRITE(FMessageArea,MessageArea);
     UNTIL EOF(FMessageArea2);
     CLOSE(FMessageArea);
     CLOSE(FMessageArea2);
     ERASE(FMessageArea2);
END;


PROCEDURE DeleteMessageArea(Number: Longint; KillBaseFiles: Boolean);
VAR  Counting : Longint;
     DirInfo  : SearchRec;
BEGIN
     IF KillBaseFiles THEN
     BEGIN
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          SEEK(FMessageArea,Number-1);
          READ(FMessageArea,MessageArea);
          CLOSE(FMessageArea);
          CASE MessageArea.Base_Type OF
          1:   BEGIN {Jam}
                    _EraseFile(MessageArea.Dos_Name+'.JHR');
                    _EraseFile(MessageArea.Dos_Name+'.JLR');
                    _EraseFile(MessageArea.Dos_Name+'.JDT');
                    _EraseFile(MessageArea.Dos_Name+'.JDX');
               END;
          2:   BEGIN {Squish}
                    _EraseFile(MessageArea.Dos_Name+'.SQD');
                    _EraseFile(MessageArea.Dos_Name+'.SQI');
                    _EraseFile(MessageArea.Dos_Name+'.SQL');
               END;
          3:   BEGIN {Fido}
                    FindFirst(MessageArea.Dos_Name+'*.*',Anyfile-Directory-VolumeID,DirInfo);
                    WHILE DosError=0 DO
                    BEGIN
                         _EraseFile(MessageArea.Dos_Name+DirInfo.Name);
                         FindNext(DirInfo);
                    END;
               END;
          END;
     END;
     _EraseFileRecord(BaseDirectory+'\DATA\MA000000.DAT',SizeOf(MessageArea),Number);
END;


PROCEDURE AddMessageArea;
BEGIN
     FillChar(MessageArea2,SizeOf(MessageArea2),0);
     MessageArea2.AreaID            := GetHighMsg+1;
     MessageArea2.Base_Type         := 2;
     MessageArea2.Area_Type         := 1;
     MessageArea2.Msg_Type          := 1;
     MessageArea2.sub               := 1;
     MessageArea2.file_attaches_sec := 32000;
     MessageArea2.origin            := 1;
     MessageArea2.address           := 1;
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     SEEK(FMessageArea,FileSize(FMessageArea));
     WRITE(FMessageArea,MessageArea2);
     CLOSE(FMessageArea);
END;


FUNCTION ConfirmedDelete: Boolean;
VAR  C : Char;
BEGIN
     _HideMouse;
     _SaveWindow(WorkDir+'\DELCON.SCR');
     DrawWindow(25,10,57,14,'CONFIRM...',True);
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(28,12); WRITE('Delete msg base files? [Y/N]');
     _ShowMouse;
     WHILE KeyPressed DO C := ReadKey;
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := UpCase(ReadKey);
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     C := #0;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((C='Y') OR (C='N'));
     LoadWindow(WorkDir+'\DELCON.SCR');
     IF C='Y' THEN ConfirmedDelete := True
              ELSE ConfirmedDelete := False;
END;


PROCEDURE DoMessageAreas;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('MA000000.DAT');
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     PickListItems := FileSize(FMessageArea);
     CLOSE(FMessageArea);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Message Conference Name',41);
     PickList_B_Title := 'Sub Group ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     RESET(FMessageArea);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FMessageArea,MessageArea);
           PickListFile.A := MessageArea.Area_Name;
           PickListFile.B := _String(MessageArea.Sub);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     CLOSE(FPickListFile);
     SetUpPickList('MESSAGE AREA EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditMessageArea(PickItem);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     PickListItems := FileSize(FMessageArea);
                     CLOSE(FMessageArea);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageArea,MessageArea);
                           PickListFile.A := MessageArea.Area_Name;
                           PickListFile.B := _String(MessageArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageArea);
                     CLOSE(FMessageArea);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          IF ConfirmedDelete
                             THEN DeleteMessageArea(PickItem,True)
                             ELSE DeleteMessageArea(PickItem,False);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                          RESET(FMessageArea);
                          PickListItems := FileSize(FMessageArea);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FMessageArea,MessageArea);
                                PickListFile.A := MessageArea.Area_Name;
                                PickListFile.B := _String(MessageArea.Sub);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FMessageArea);
                          CLOSE(FMessageArea);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertMessageArea(PickItem);
                     EditMessageArea(PickItem);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     PickListItems := FileSize(FMessageArea);
                     CLOSE(FMessageArea);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageArea,MessageArea);
                           PickListFile.A := MessageArea.Area_Name;
                           PickListFile.B := _String(MessageArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageArea);
                     CLOSE(FMessageArea);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddMessageArea;
                     EditMessageArea(PickListItems+1);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     PickListItems := FileSize(FMessageArea);
                     CLOSE(FMessageArea);
                     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                     RESET(FMessageArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FMessageArea,MessageArea);
                           PickListFile.A := MessageArea.Area_Name;
                           PickListFile.B := _String(MessageArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FMessageArea);
                     CLOSE(FMessageArea);
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


PROCEDURE EditBadLang(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang);
     SEEK(FBadLang,Number-1);
     READ(FBadLang,BadLang);
     CLOSE(FBadLang);
     DrawWindow(35,9,78,15,'EDIT LANGUAGE',True);
     AddObject(46,11,1,30,BadLang.Phrase,True);
     AddButton(68,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(37,11); WRITE(' Phrase');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     BadLang.Phrase := _UpperCase(Objects^[1].Stuff);
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang);
     SEEK(FBadLang,Number-1);
     WRITE(FBadLang,BadLang);
     CLOSE(FBadLang);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE InsertBadLang(Number: Longint);
VAR  Counting : Longint;
BEGIN
     ASSIGN(FBadLang2,BaseDirectory+'\DATA\BADLANG.DAT');
     RENAME(FBadLang2,BaseDirectory+'\DATA\BADLANG.BAK');
     ASSIGN(FBadLang2,BaseDirectory+'\DATA\BADLANG.BAK');
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang2);
     REWRITE(FBadLang);
     Counting := 0;
     REPEAT
           READ(FBadLang2,BadLang);
           INC(Counting);
           IF Counting=Number THEN WRITE(FBadLang,BadLang2);
           WRITE(FBadLang,BadLang);
     UNTIL EOF(FBadLang2);
     CLOSE(FBadLang);
     CLOSE(FBadLang2);
     ERASE(FBadLang2);
END;


PROCEDURE DeleteBadLang(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\BADLANG.DAT',SizeOf(BadLang),Number);
END;


PROCEDURE AddBadLang;
BEGIN
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang);
     SEEK(FBadLang,FileSize(FBadLang));
     WRITE(FBadLang,BadLang2);
     CLOSE(FBadLang);
END;


PROCEDURE DoBadLanguage;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('BADLANG.DAT');
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang);
     PickListItems := FileSize(FBadLang);
     CLOSE(FBadLang);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Language To Omit',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
     RESET(FBadLang);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FBadLang,BadLang);
           PickListFile.A := BadLang.Phrase;
           PickListFile.B := '';
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FBadLang);
     CLOSE(FBadLang);
     CLOSE(FPickListFile);
     SetUpPickList('UNWANTED LANGUAGE EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditBadLang(PickItem);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     PickListItems := FileSize(FBadLang);
                     CLOSE(FBadLang);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FBadLang,BadLang);
                           PickListFile.A := BadLang.Phrase;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FBadLang);
                     CLOSE(FBadLang);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteBadLang(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                          RESET(FBadLang);
                          PickListItems := FileSize(FBadLang);
                          CLOSE(FBadLang);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                          RESET(FBadLang);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FBadLang,BadLang);
                                PickListFile.A := BadLang.Phrase;
                                PickListFile.B := '';
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FBadLang);
                          CLOSE(FBadLang);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertBadLang(PickItem);
                     EditBadLang(PickItem);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     PickListItems := FileSize(FBadLang);
                     CLOSE(FBadLang);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FBadLang,BadLang);
                           PickListFile.A := BadLang.Phrase;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FBadLang);
                     CLOSE(FBadLang);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddBadLang;
                     EditBadLang(PickListItems+1);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     PickListItems := FileSize(FBadLang);
                     CLOSE(FBadLang);
                     ASSIGN(FBadLang,BaseDirectory+'\DATA\BADLANG.DAT');
                     RESET(FBadLang);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FBadLang,BadLang);
                           PickListFile.A := BadLang.Phrase;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FBadLang);
                     CLOSE(FBadLang);
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


PROCEDURE DoQWKSetup;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     {$I-}READ(FSystem_Info,System_Info);{$I+}
     IF IOResult=0 THEN;
     CLOSE(FSystem_Info);
     IF LENGTH(System_Info.QWKWelcome)>8 THEN System_Info.QWKWelcome := 'WELCOME';
     IF LENGTH(System_Info.QWKNews)>8 THEN System_Info.QWKNews := 'NEWS';
     IF LENGTH(System_Info.QWKGoodBye)>8 THEN System_Info.QWKGoodBye := 'GOODBYE';
     DrawWindow(2,8,79,19,'QWK MAIL SETUP',True);
     AddObject(17,10,1,8,System_Info.QWKPacketName,True);
     AddObject(17,11,1,20,System_Info.QWKBBSPhone,True);
     AddObject(17,12,1,60,System_Info.QWKBBSId,True);
     AddObject(17,13,1,8,System_Info.QWKWelcome,True);
     AddObject(17,14,1,8,System_Info.QWKNews,True);
     AddObject(17,15,1,8,System_Info.QWKGoodBye,True);
     AddButton(69,17,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(4,10); WRITE('Packet Name');
     GotoXY(4,11); WRITE('BBS Phone #');
     GotoXY(4,12); WRITE('BBS Id Line');
     GotoXY(4,13); WRITE('QWK Welcome');
     GotoXY(4,14); WRITE('   QWK News');
     GotoXY(4,15); WRITE('QWK GoodBye');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.QWKPacketName := _UpperCase(Objects^[1].Stuff);
     System_Info.QWKBBSPhone   := Objects^[2].Stuff;
     System_Info.QWKBBSId      := Objects^[3].Stuff;
     System_Info.QWKWelcome    := _UpperCase(Objects^[4].Stuff);
     System_Info.QWKNews       := _UpperCase(Objects^[5].Stuff);
     System_Info.QWKGoodBye    := _UpperCase(Objects^[6].Stuff);
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


FUNCTION LoadMsgSub(TheGroup: Word): Boolean;
BEGIN
     ASSIGN(FMessageSubs,BaseDirectory+'\DATA\MSGAREA.SUB');
     RESET(FMessageSubs);
     REPEAT
           READ(FMessageSubs,MessageSubs);
           IF MessageSubs.Sub_Num=TheGroup THEN
           BEGIN
                CLOSE(FMessageSubs);
                LoadMsgSub := True;
                Exit;
           END;
     UNTIL EOF(FMessageSubs);
     CLOSE(FMessageSubs);
     LoadMsgSub := False;
END;


PROCEDURE DoAreasBBSImport;
TYPE New_Rec      = RECORD
     AreaTag      : String[40];
     END;
TYPE Big_Rec      = Array[1..500] Of New_Rec;
VAR  C            : Char;
     ImpFile      : String;
     ImpGroup     : Word;
     Temp         : String;
     AreaFile     : Text;
     PathName     : String;
     AreaTag      : String;
     BaseType     : Byte;
     Loop2        : Word;
     HighQWK      : Word;
     MessageArea3 : _MessageArea_Record;
     TxtBuffer    : Array[1..8192] Of Char;
     FNewRec      : File of New_Rec;
     NewRec       : New_Rec;
     BNewRec      : ^Big_Rec;
     FNewRecFile  : File;

     FUNCTION ProcessLine(InString: String; VAR PName,ATag: String; VAR BT: Byte): Boolean;
     VAR  Loop : Word;
          Work : Word;
     BEGIN
          IF InString[1]=';' THEN
          BEGIN
               ProcessLine := False;
               Exit;
          END
          ELSE
          BEGIN
               {GET THE PATH}
               Work := Pos(' ',InString);
               PName := _Mid(InString,1,Work-1);
               Delete(InString,1,Work-1);
               {DO THE BASE TYPE}
               IF PName[1]='$' THEN
               BEGIN
                    BT := 2;
                    Delete(PName,1,1);
               END
               ELSE IF PName[1]='!' THEN
               BEGIN
                    BT := 1;
                    Delete(PName,1,1);
               END
               ELSE BT := 3;
               {CLEAR LEADING SPACES}
               WHILE InString[1]=' ' DO Delete(InString,1,1);
               {GET THE AREA TAG}
               Work := Pos(' ',InString);
               IF Work=0 THEN ATag := _UpperCase(InString)
                         ELSE ATag := _UpperCase(_Mid(InString,1,Work-1));
          END;
          ProcessLine := True;
     END;

     PROCEDURE DumpAreaTags;
     BEGIN
          ASSIGN(FNewRec,'TMPIMP$$.$$$');
          REWRITE(FNewRec);
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
                READ(FMessageArea,MessageArea3);
                IF MessageArea3.Area_Tag<>'' THEN
                BEGIN
                     NewRec.AreaTag := MessageArea3.Area_Tag;
                     WRITE(FNewRec,NewRec);
                END;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
          CLOSE(FNewRec);
     END;

     PROCEDURE AddTheNewAreaTag(TheTag: String);
     BEGIN
          NewRec.AreaTag := TheTag;
          ASSIGN(FNewRec,'TMPIMP$$.$$$');
          RESET(FNewRec);
          SEEK(FNewRec,FileSize(FNewRec));
          WRITE(FNewRec,NewRec);
          CLOSE(FNewRec);
     END;

     FUNCTION AlreadyGotIt: Boolean;
     VAR  SSize     : Longint;
          GotIt     : Boolean;
          Work33    : Word;
          BytesRead : Word;
     BEGIN
          SSize := SizeOf(NewRec);
          GotIt := False;
          SEEK(FNewRecFile,0);
          REPEAT
                BLOCKREAD(FNewRecFile,BNewRec^,SizeOf(BNewRec^),BytesRead);
                BytesRead := Round(BytesRead/SSize);
                FOR Work33 := 1 TO BytesRead DO
                BEGIN
                     IF BNewRec^[Work33].AreaTag=AreaTag THEN GotIt := True;
                END;
          UNTIL ((EOF(FNewRecFile)) OR (GotIt));
          AlreadyGotIt := GotIt;
     END;

BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,68,16,'IMPORT AREAS.BBS',True);
     AddObject(26,11,1,40,'',True);
     AddObject(26,12,2,5,'1',True);
     AddButton(58,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('  Area File');
     GotoXY(13,12); WRITE('  Sub-Group');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     LoadWindow(WorkDir+'\EDITACC.SCR');
     ImpFile  := Objects^[1].Stuff;
     ImpGroup := Numeric(Objects^[2].Stuff,WordInteger);
     IF ImpFile<>'' THEN
     BEGIN
          IF _FileExists(ImpFile) THEN
          BEGIN
               IF LoadMsgSub(ImpGroup) THEN
               BEGIN
                    New(BNewRec);
                    HighQWK := GetHighMsg;
                    FillChar(MessageArea,SizeOf(MessageArea),0);
                    MessageArea.Sub               := ImpGroup;
                    MessageArea.Read_Access       := MessageSubs.Read_Access;
                    MessageArea.Write_Access      := MessageSubs.Write_Access;
                    MessageArea.Area_Type         := MessageSubs.Area_Type;
                    MessageArea.Msg_Type          := MessageSubs.Msg_Type;
                    MessageArea.File_Attaches     := MessageSubs.File_Attaches;
                    MessageArea.File_Attaches_Sec := MessageSubs.File_Attaches_Sec;
                    FOR Loop2 := 1 TO 10 DO MessageArea.Tags[Loop2] := MessageSubs.Tags[Loop2];
                    MessageArea.Origin            := MessageSubs.Origin;
                    MessageArea.Address           := MessageSubs.Address;
                    MessageArea.DoGraphics        := MessageSubs.DoGraphics;
                    MessageArea.CleanLanguage     := MessageSubs.CleanLanguage;
                    MessageArea.MaxMsgs           := MessageSubs.MaxMsgs;
                    _SaveWindow(WorkDir+'\EDITACC.SCR');
                    _HideMouse;
                    DrawWindow(12,10,66,14,'IMPORTING AREAS.BBS',True);
                    FastWrite('Importing:  ',12,15,31);
                    _ShowMouse;
                    DumpAreaTags;
                    ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
                    ASSIGN(FNewRecFile,'TMPIMP$$.$$$');
                    RESET(FNewRecFile,1);
                    RESET(FMessageArea);
                    ASSIGN(AreaFile,ImpFile);
                    SetTextBuf(AreaFile,TxtBuffer);
                    RESET(AreaFile);
                    REPEAT
                          READLN(AreaFile,Temp);
                          IF ProcessLine(Temp,PathName,AreaTag,BaseType) THEN
                          BEGIN
                               CASE BaseType OF
                               1:   PathName := ValidateIt(PathName,'FILE');
                               2:   PathName := ValidateIt(PathName,'FILE');
                               3:   PathName := ValidateIt(PathName,'PATH');
                               END;
                               FastWrite('Processing:  '+_PadRight(AreaTag,30),12,15,31);
                               IF NOT(AlreadyGotIt) THEN
                               BEGIN
                                    INC(HighQWK);
                                    MessageArea.area_name := AreaTag;
                                    MessageArea.area_tag  := AreaTag;
                                    MessageArea.dos_name  := PathName;
                                    MessageArea.base_type := BaseType;
                                    MessageArea.AreaID    := HighQWK;
                                    SEEK(FMessageArea,FileSize(FMessageArea));
                                    WRITE(FMessageArea,MessageArea);
                                    AddTheNewAreaTag(AreaTag);
                               END;
                          END;
                    UNTIL EOF(AreaFile);
                    CLOSE(AreaFile);
                    CLOSE(FMessageArea);
                    CLOSE(FNewRecFile);
                    ERASE(FNewRecFile);
                    LoadWindow(WorkDir+'\EDITACC.SCR');
                    Dispose(BNewRec);
               END;
          END;
     END;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(C)=0 THEN C := ReadKey;
           END;
     UNTIL NOT(KeyPressed);
END;


PROCEDURE AddReport;
BEGIN
     FillChar(Reports,SizeOf(Reports),0);
     Reports.ReportType    := 1;
     Reports.ReportNumber  := 1;
     Reports.MsgAreaNumber := 1;
     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
     {$I-}RESET(FReports);{$I+}
     IF (IOResult<>0) THEN REWRITE(FReports)
                      ELSE SEEK(FReports,FileSize(FReports));
     WRITE(FReports,Reports);
     CLOSE(FReports);
END;


PROCEDURE InsertReport(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Reports,SizeOf(Reports),0);
     Reports.ReportType    := 1;
     Reports.ReportNumber  := 1;
     Reports.MsgAreaNumber := 1;
     IF _FileExists(BaseDirectory+'\DATA\REPORTS.DAT') THEN
     BEGIN
          ASSIGN(FReports2,BaseDirectory+'\DATA\REPORTS.DAT');
          RENAME(FReports2,BaseDirectory+'\DATA\REPORTS.BAK');
          ASSIGN(FReports2,BaseDirectory+'\DATA\REPORTS.BAK');
          ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
          RESET(FReports2);
          REWRITE(FReports);
          Counting := 0;
          REPEAT
                READ(FReports2,Reports2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FReports,Reports);
                WRITE(FReports,Reports2);
          UNTIL EOF(FReports2);
          CLOSE(FReports);
          CLOSE(FReports2);
          ERASE(FReports2);
     END
     ELSE
     BEGIN
          ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
          REWRITE(FReports);
          WRITE(FReports,Reports);
          CLOSE(FReports);
     END;
END;


PROCEDURE DeleteReport(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\REPORTS.DAT',SizeOf(Reports),Number);
END;


PROCEDURE EditReport(Number: Longint);
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
     RESET(FReports);
     SEEK(FReports,Number-1);
     READ(FReports,Reports);
     CLOSE(FReports);
     Toggle[1].Flips   := 6;
     Toggle[1].Current := Reports.ReportType;
     Toggle[1].Flip[1] := 'TIC RECEIVED';
     Toggle[1].Flip[2] := 'FILE(S) UPLOADED';
     Toggle[1].Flip[3] := 'PRIVATE UPLOAD';
     Toggle[1].Flip[4] := 'NEW USER';
     Toggle[1].Flip[5] := 'FILE AREA CREATED';
     Toggle[1].Flip[6] := 'MSG AREA CREATED';
     DrawWindow(3,6,78,21,'EDIT SYSTEM REPORT',True);
     AddObject(25,8,2,5,_String(Reports.ReportNumber),True);
     AddObject(25,9,2,5,_String(Reports.MsgAreaNumber),True);
     AddObject(25,10,8,20,'1',True);
     AddObject(25,12,1,30,Reports.MsgFrom,True);
     AddObject(25,13,1,30,Reports.MsgTo,True);
     AddObject(25,14,1,50,Reports.MsgSubject,True);
     AddObject(25,16,1,50,Reports.Header,True);
     AddObject(25,17,1,50,Reports.Footer,True);
     AddButton(69,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(5,8);  WRITE('     Report Number');
     GotoXY(5,9);  WRITE('   Message Area ID');
     GotoXY(5,10); WRITE('       Report Type');
     GotoXY(5,12); WRITE(' Message 컴쩡 From');
     GotoXY(5,13); WRITE('           쳐컴 To');
     GotoXY(5,14); WRITE('           읕 Subj');
     GotoXY(5,16); WRITE('    Message Header');
     GotoXY(5,17); WRITE('    Message Footer');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Reports.ReportNumber  := Numeric(Objects^[1].Stuff,WordInteger);
     Reports.MsgAreaNumber := Numeric(Objects^[2].Stuff,WordInteger);
     Reports.ReportType    := Toggle[1].Current;
     Reports.MsgFrom       := Objects^[4].Stuff;
     Reports.MsgTo         := Objects^[5].Stuff;
     Reports.MsgSubject    := Objects^[6].Stuff;
     Reports.Header        := ValidateIt(Objects^[7].Stuff,'FILE');
     Reports.Footer        := ValidateIt(Objects^[8].Stuff,'FILE');
     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
     RESET(FReports);
     SEEK(FReports,Number-1);
     WRITE(FReports,Reports);
     CLOSE(FReports);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoSystemReports;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
     ReportName : Array[1..8] Of String[30];
BEGIN
     ReportName[1]   := 'Tic file received';
     ReportName[2]   := 'File uploaded by user';
     ReportName[3]   := 'Private upload received';
     ReportName[4]   := 'New user on the system';
     ReportName[5]   := 'File area auto-create';
     ReportName[6]   := 'Message area auto-create';
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
     {$I-}RESET(FReports);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FReports);
          CLOSE(FReports);
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
     PickList_A_Title := _PadRight(' Report Type',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN
     BEGIN
          ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
          RESET(FReports);
          REPEAT
                Read(FReports,Reports);
                PickListFile.A := ReportName[Reports.ReportType];
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FReports);
          CLOSE(FReports);
     END;
     CLOSE(FPickListFile);
     SetUpPickList('SYSTEM GENERATED REPORTS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditReport(PickItem);
                     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
                     RESET(FReports);
                     PickListItems := FileSize(FReports);
                     CLOSE(FReports);
                     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
                     RESET(FReports);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FReports,Reports);
                           PickListFile.A := ReportName[Reports.ReportType];;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FReports);
                     CLOSE(FReports);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteReport(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN
                          BEGIN
                               ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
                               RESET(FReports);
                               REPEAT
                                     Read(FReports,Reports);
                                     PickListFile.A := ReportName[Reports.ReportType];;
                                     PickListFile.B := '';
                                     WRITE(FPickListFile,PickListFile);
                               UNTIL EOF(FReports);
                               CLOSE(FReports);
                          END;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddReport;
                          EditReport(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertReport(PickItem);
                          EditReport(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
                     RESET(FReports);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FReports,Reports);
                           PickListFile.A := ReportName[Reports.ReportType];;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FReports);
                     CLOSE(FReports);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddReport;
                     EditReport(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
                     RESET(FReports);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FReports,Reports);
                           PickListFile.A := ReportName[Reports.ReportType];;
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FReports);
                     CLOSE(FReports);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoAreasBBSExport;
VAR  AreaFile     : File;
     ExpFile      : String;
     C            : Char;
     EchoTag      : _GSEchoDat_Record;
     BytesRead    : Word;
     LLen         : Word;
     Buffer       : Array[1..4192] Of Char;

     PROCEDURE AddTheString(InString: String);
     VAR  Loop : Byte;
     BEGIN
          FOR Loop := 1 TO LENGTH(InString) DO
          BEGIN
            INC(LLen);
            Buffer[LLen] := InString[Loop];
          END;
     END;

BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,68,15,'EXPORT AREAS.BBS',True);
     AddObject(26,11,1,40,BaseDirectory+'\AREAS.BBS',True);
     AddButton(58,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('  Area File');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     LoadWindow(WorkDir+'\EDITACC.SCR');
     ExpFile  := Objects^[1].Stuff;
     IF ExpFile<>'' THEN
     BEGIN
       WorkingFile.Init(32768);
       _SaveWindow(WorkDir+'\EDITACC.SCR');
       _HideMouse;
       DrawWindow(12,10,66,14,'EXPORTING AREAS.BBS',True);
       FastWrite('Exporting:  ',12,15,31);
       _ShowMouse;
       ASSIGN(AreaFile,ExpFile);
       REWRITE(AreaFile,1);
       LLen := 0; AddTheString(';'+#$0D#$0A);
       BLOCKWRITE(AreaFile,Buffer,LLen);
       LLen := 0; AddTheString('; AREAS.BBS File Created By GSConfig'+#$0D#$0A);
       BLOCKWRITE(AreaFile,Buffer,LLen);
       LLen := 0; AddTheString(';'+#$0D#$0A);
       BLOCKWRITE(AreaFile,Buffer,LLen);
       ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
       RESET(FMessageArea);
       REPEAT
         READ(FMessageArea,MessageArea);
         FastWrite('Exporting:  '+_PadRight(MessageArea.Area_Tag,30),12,15,31);
         LLen := 0;
         CASE MessageArea.Base_Type OF
         1:   AddTheString('!');
         2:   AddTheString('$');
         END;
         AddTheString(MessageArea.Dos_Name+' '+MessageArea.Area_Tag);
         IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT') THEN
         BEGIN
           WorkingFile.OpenFile(BaseDirectory+'\DATA\GSECHO.DAT',SetFileMode);
           REPEAT
             WorkingFile.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
             IF (BytesRead<>0) THEN
             BEGIN
               IF EchoTag.AreaId=MessageArea.AreaID THEN AddTheString(' '+AddressToString(EchoTag.Aka));
             END;
           UNTIL BytesRead=0;
           WorkingFile.CloseFile;
         END;
         AddTheString(#$0D#$0A);
         BLOCKWRITE(AreaFile,Buffer,LLen);
       UNTIL EOF(FMessageArea);
       CLOSE(FMessageArea);
       CLOSE(AreaFile);
       LoadWindow(WorkDir+'\EDITACC.SCR');
       WorkingFile.Done;
     END;
     WHILE KeyPressed DO ReadKey;
END;


END.