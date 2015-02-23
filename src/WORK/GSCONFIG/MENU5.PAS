{$I DEFINES.INC}
UNIT MENU5;


INTERFACE


PROCEDURE DoFileSubs;
PROCEDURE DoFileHatch;
PROCEDURE DoFileAreas;
PROCEDURE DoProtocols;
PROCEDURE DoScannerDefs;
PROCEDURE DoArcDefs;
PROCEDURE DoArcConversions;
PROCEDURE DoCDRomManager;
PROCEDURE DoImportCDRom;
PROCEDURE DoRemoveCDRom;
PROCEDURE DoMiscFileAreas;
PROCEDURE DoExportDirs;
PROCEDURE DoCDRomDefinitions;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Hatch,
     FileMan,Import,Dos,Dispatch,FastW1,Valid,Gunshot,BsAkas;


PROCEDURE GlobalFileChange(Number: Longint);
VAR  Loop      : Word;
     AreasDone : Word;
     FPosition : Longint;
     C         : Char;
BEGIN
     AreasDone := 0;
     FPosition := 0;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea);
           IF FileArea.Sub=Number THEN
           BEGIN
                INC(AreasDone);
                FileArea.View_Access     := FileSubs.View_Access;
                FileArea.DL_Access       := FileSubs.DL_Access;
                FOR Loop := 1 TO 10 DO FileArea.Tags[Loop] := FileSubs.Tags[Loop];
                FileArea.CD_Rom          := FileSubs.CD_Rom;
                FileArea.Sort            := FileSubs.Sort;
                FileArea.TicImportDiz    := FileSubs.TicImportDiz;
                FileArea.TicConvertArcs  := FileSubs.TicConvertArcs;
                FileArea.TicDestFormat   := FileSubs.TicDestFormat;
                FileArea.TicReportNumber := FileSubs.TicReportNumber;
                SEEK(FFileArea,FPosition);
                WRITE(FFileArea,FileArea);
           END;
           INC(FPosition);
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     InfoBox('GLOBAL GROUP CHANGES','File areas changed: '+_String(AreasDone),'<<Press a key>>','');
     ReadKey;
     IF KeyPressed THEN C := ReadKey;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE EditFileSub(Number: Longint);
VAR  Action : Word;
LABEL         OverAgain;

     PROCEDURE Reload;
     VAR  Loop : Word;
     BEGIN
          ClearObjects;
          ClearButtons;
          FileSubs.Sub_Num     := Numeric(Objects^[1].Stuff,WordInteger);
          FileSubs.Sub_Name    := Objects^[2].Stuff;
          FileSubs.ScanAtLogon := ToBoolean(Objects^[3].Stuff);
          FileSubs.View_Access := Numeric(Objects^[4].Stuff,WordInteger);
          FileSubs.DL_Access   := Numeric(Objects^[5].Stuff,WordInteger);
          FOR Loop := 1 TO 10 DO
          BEGIN
               IF Objects^[6].Stuff[Loop]='1'
                  THEN FileSubs.Tags[Loop] := 1
                  ELSE FileSubs.Tags[Loop] := 0;
          END;
          FileSubs.CD_Rom          := Numeric(Objects^[7].Stuff,WordInteger);
          FileSubs.Sort            := Toggle[1].Current;
          FileSubs.TicImportDiz    := ToBoolean(Objects^[9].Stuff);
          FileSubs.TicConvertArcs  := ToBoolean(Objects^[10].Stuff);
          FileSubs.TicDestFormat   := _UpperCase(Objects^[11].Stuff);
          FileSubs.TicReportNumber := Numeric(Objects^[12].Stuff,WordInteger);
          FileSubs.Area_Path       := ValidateIt(Objects^[13].Stuff,'PATH');
          FileSubs.FileBoneNa      := ValidateIt(Objects^[14].Stuff,'FILE');
          FileSubs.PassThrough     := ToBoolean(Objects^[15].Stuff);
          ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
          RESET(FFileSubs);
          SEEK(FFileSubs,Number-1);
          WRITE(FFileSubs,FileSubs);
          CLOSE(FFileSubs);
     END;

BEGIN
     _SaveWindow(WorkDir+'\EDITGRP.SCR');
     CheckFile('ARCHIVE.DAT');
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     RESET(FFileSubs);
     SEEK(FFileSubs,Number-1);
     READ(FFileSubs,FileSubs);
     CLOSE(FFileSubs);
     OverAgain:
     Toggle[1].Flips   := 7;
     Toggle[1].Current := FileSubs.Sort;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'ALPHABETICAL (A-Z)';
     Toggle[1].Flip[3] := 'ALPHABETICAL (Z-A)';
     Toggle[1].Flip[4] := 'DATE (NEW-OLD)';
     Toggle[1].Flip[5] := 'DATE (OLD-NEW)';
     Toggle[1].Flip[6] := 'SIZE (LARGE-SMALL)';
     Toggle[1].Flip[7] := 'SIZE (SMALL-LARGE)';
     DrawWindow(5,2,78,24,'EDIT FILE SUB GROUP',True);
     AddObject(26,4,2,5,_String(FileSubs.Sub_Num),True);
     AddObject(26,5,1,30,FileSubs.Sub_Name,True);
     AddObject(26,6,6,3,FromBoolean(FileSubs.ScanAtLogon),True);
     AddObject(32,10,2,5,_String(FileSubs.View_Access),True);
     AddObject(32,11,2,5,_String(FileSubs.DL_Access),True);
     AddObject(32,12,7,10,Tags(FileSubs.Tags),True);
     AddObject(32,13,2,5,_String(FileSubs.CD_Rom),True);
     AddObject(32,14,8,20,'1',True);
     AddObject(32,15,6,3,FromBoolean(FileSubs.TicImportDiz),True);
     AddObject(32,16,6,3,FromBoolean(FileSubs.TicConvertArcs),True);
     AddObject(50,16,1,3,FileSubs.TicDestFormat,True);
     AddObject(32,17,2,5,_String(FileSubs.TicReportNumber),True);
     AddObject(32,18,1,40,FileSubs.Area_Path,True);
     AddObject(32,19,1,40,FileSubs.FileBoneNa,True);
     AddObject(32,20,6,3,FromBoolean(FileSubs.PassThrough),True);
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
     GotoXY(8,10);  WRITE('           View Access');
     GotoXY(8,11);  WRITE('             DL Access');
     GotoXY(8,12);  WRITE('             Area Tags');
     GotoXY(8,13);  WRITE('         CD Rom Number');
     GotoXY(8,14);  WRITE('        Sorting Method');
     GotoXY(8,15);  WRITE('    Import FILE_ID.DIZ');
     GotoXY(8,16);  WRITE('      Convert Archives');
     GotoXY(37,16); WRITE('Dest Format');
     GotoXY(8,17);  WRITE('New File Report Number');
     GotoXY(8,18);  WRITE('       Auto Create Dir');
     GotoXY(8,19);  WRITE('      FILEBONE.NA File');
     GotoXY(8,20);  WRITE('     Passthrough Areas');
     _ShowMouse;
     REPEAT
       Action := DoObjects;
       CASE Action OF
       2:   BEGIN
              Reload;
              GlobalFileChange(FileSubs.Sub_Num);
              GOTO OverAgain;
            END;
       3:   BEGIN
              Reload;
              DrawWindow(8,7,65,15,'UPLINK FOR THIS GROUP',True);
              AddObject(31,9,1,20,AddressToString(FileSubs.Uplink),True);
              AddObject(31,10,1,30,FileSubs.AreaManager,True);
              AddObject(31,11,1,30,_UpperCase(FileSubs.YourPassword),True);
              AddObject(31,12,6,3,FromBoolean(FileSubs.AutoRequests),True);
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
              StringToAddress(Objects^[1].Stuff,FileSubs.Uplink);
              FileSubs.AreaManager  := Objects^[2].Stuff;
              FileSubs.YourPassword := _UpperCase(Objects^[3].Stuff);
              FileSubs.AutoRequests := ToBoolean(Objects^[4].Stuff);
              GOTO OverAgain;
            END;
       END;
     UNTIL Action=1;
     ReLoad;
     LoadWindow(WorkDir+'\EDITGRP.SCR');
END;


PROCEDURE InsertFileSub(Number: Longint);
VAR  FFileSubs2 : File Of _FileSub_Record;
     Counting   : Longint;
BEGIN
     CheckFile('ARCHIVE.DAT');
     FillChar(FileSubs2,SizeOf(FileSubs2),0);
     FileSubs2.sort           := 1;
     FileSubs2.TicConvertArcs := True;
     FileSubs2.TicDestFormat  := ArcDefs.DefaultArc;
     FileSubs2.TicImportDiz   := True;
     FileSubs2.ScanAtLogon    := True;
     ASSIGN(FFileSubs2,BaseDirectory+'\DATA\FILEAREA.SUB');
     RENAME(FFileSubs2,BaseDirectory+'\DATA\FILEAREA.BAK');
     ASSIGN(FFileSubs2,BaseDirectory+'\DATA\FILEAREA.BAK');
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     RESET(FFileSubs2);
     REWRITE(FFileSubs);
     Counting := 0;
     REPEAT
           READ(FFileSubs2,FileSubs);
           INC(Counting);
           IF Counting=Number THEN WRITE(FFileSubs,FileSubs2);
           WRITE(FFileSubs,FileSubs);
     UNTIL EOF(FFileSubs2);
     CLOSE(FFileSubs);
     CLOSE(FFileSubs2);
     ERASE(FFileSubs2);
END;


PROCEDURE DeleteFileSub(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\FILEAREA.SUB',SizeOf(FileSubs),Number);
END;


PROCEDURE AddFileSub;
BEGIN
     CheckFile('ARCHIVE.DAT');
     FillChar(FileSubs2,SizeOf(FileSubs2),0);
     FileSubs2.sort           := 1;
     FileSubs2.TicConvertArcs := True;
     FileSubs2.TicDestFormat  := ArcDefs.DefaultArc;
     FileSubs2.TicImportDiz   := True;
     FileSubs2.ScanAtLogon    := True;
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     RESET(FFileSubs);
     SEEK(FFileSubs,FileSize(FFileSubs));
     WRITE(FFileSubs,FileSubs2);
     CLOSE(FFileSubs);
END;


PROCEDURE DoFileSubs;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('FILEAREA.SUB');
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     RESET(FFileSubs);
     PickListItems := FileSize(FFileSubs);
     CLOSE(FFileSubs);
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
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     RESET(FFileSubs);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FFileSubs,FileSubs);
           PickListFile.A := FileSubs.Sub_Name;
           PickListFile.B := _String(FileSubs.Sub_Num);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);
     CLOSE(FPickListFile);
     SetUpPickList('FILE AREA SUB GROUPS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditFileSub(PickItem);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     PickListItems := FileSize(FFileSubs);
                     CLOSE(FFileSubs);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileSubs,FileSubs);
                           PickListFile.A := FileSubs.Sub_Name;
                           PickListFile.B := _String(FileSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileSubs);
                     CLOSE(FFileSubs);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteFileSub(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                          RESET(FFileSubs);
                          PickListItems := FileSize(FFileSubs);
                          CLOSE(FFileSubs);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                          RESET(FFileSubs);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FFileSubs,FileSubs);
                                PickListFile.A := FileSubs.Sub_Name;
                                PickListFile.B := _String(FileSubs.Sub_Num);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FFileSubs);
                          CLOSE(FFileSubs);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertFileSub(PickItem);
                     EditFileSub(PickItem);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     PickListItems := FileSize(FFileSubs);
                     CLOSE(FFileSubs);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileSubs,FileSubs);
                           PickListFile.A := FileSubs.Sub_Name;
                           PickListFile.B := _String(FileSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileSubs);
                     CLOSE(FFileSubs);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddFileSub;
                     EditFileSub(PickListItems+1);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     PickListItems := FileSize(FFileSubs);
                     CLOSE(FFileSubs);
                     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
                     RESET(FFileSubs);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileSubs,FileSubs);
                           PickListFile.A := FileSubs.Sub_Name;
                           PickListFile.B := _String(FileSubs.Sub_Num);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileSubs);
                     CLOSE(FFileSubs);
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


PROCEDURE EditFileArea(Number: Longint);
VAR  Loop : Word;
BEGIN
     CheckFile('ARCHIVE.DAT');
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,Number-1);
     READ(FFileArea,FileArea);
     CLOSE(FFileArea);
     Toggle[1].Flips   := 7;
     Toggle[1].Current := FileArea.Sort;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'ALPHABETICAL (A-Z)';
     Toggle[1].Flip[3] := 'ALPHABETICAL (Z-A)';
     Toggle[1].Flip[4] := 'DATE (NEW-OLD)';
     Toggle[1].Flip[5] := 'DATE (OLD-NEW)';
     Toggle[1].Flip[6] := 'SIZE (LARGE-SMALL)';
     Toggle[1].Flip[7] := 'SIZE (SMALL-LARGE)';
     DrawWindow(7,3,77,24,'EDIT FILE AREA',True);
     AddObject(25,5 ,1,40,FileArea.Area_Name,True);
     AddObject(25,6 ,1,40,FileArea.Area_Path,True);
     AddObject(25,7 ,1,50,FileArea.DOS_Name,True);
     AddObject(25,9 ,2,5 ,_String(FileArea.View_Access),True);
     AddObject(25,10,2,5 ,_String(FileArea.DL_Access),True);
     AddObject(25,11,7,10,Tags(FileArea.Tags),True);
     AddObject(55,9 ,2,5 ,_String(FileArea.CD_Rom),True);
     AddObject(55,10,2,5 ,_String(FileArea.Sub),True);
     AddObject(55,11,8,20,'1',True);
     AddObject(55,12,2,5,_String(FileArea.AreaID),True);
     AddObject(35,14,1,12,FileArea.Area_Tag,True);
     AddObject(35,15,6,3,FromBoolean(FileArea.TicImportDiz),True);
     AddObject(35,16,6,3,FromBoolean(FileArea.TicConvertArcs),True);
     AddObject(35,17,1,3,FileArea.TicDestFormat,True);
     AddObject(35,18,2,5 ,_String(FileArea.TicReportNumber),True);
     AddObject(35,19,6,3,FromBoolean(FileArea.Passthrough),True);
     AddButton(67,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(9,8);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(9,13); WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(9,20); WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     TextColor_BS(11);
     GotoXY(9,5);   WRITE('     Area Name');
     GotoXY(9,6);   WRITE('     Area Path');
     GotoXY(9,7);   WRITE(' Database File');
     GotoXY(9,9);   WRITE('   View Access');
     GotoXY(9,10);  WRITE('     DL Access');
     GotoXY(9,11);  WRITE('     Area Tags');
     GotoXY(39,9);  WRITE(' CD Rom Number');
     GotoXY(39,10); WRITE('     Sub Group');
     GotoXY(39,11); WRITE('Sorting Method');
     GotoXY(39,12); WRITE('  File Area ID');
     GotoXY(10,14); WRITE('      TIC File Echo Tag');
     GotoXY(10,15); WRITE('     Import FILE_ID.DIZ');
     GotoXY(10,16); WRITE('       Convert Archives');
     GotoXY(10,17); WRITE('     Destination Format');
     GotoXY(10,18); WRITE(' New File Report Number');
     GotoXY(10,19); WRITE('       Passthrough Area');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     FileArea.Area_Name       := Objects^[1].Stuff;
     FileArea.Area_Path       := ValidateIt(Objects^[2].Stuff,'PATH');
     FileArea.DOS_Name        := ValidateIt(Objects^[3].Stuff,'FILE');
     FileArea.View_Access     := Numeric(Objects^[4].Stuff,WordInteger);
     FileArea.DL_Access       := Numeric(Objects^[5].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[6].Stuff[Loop]='1' THEN FileArea.Tags[Loop] := 1
                                        ELSE FileArea.Tags[Loop] := 0;
     END;
     FileArea.CD_Rom          := Numeric(Objects^[7].Stuff,WordInteger);
     FileArea.Sub             := Numeric(Objects^[8].Stuff,WordInteger);
     FileArea.Sort            := Toggle[1].Current;
     IF FileArea.Sort=0 THEN FileArea.Sort := 1;
     FileArea.AreaId          := Numeric(Objects^[10].Stuff,WordInteger);
     FileArea.Area_Tag        := _UpperCase(Objects^[11].Stuff);
     FileArea.TicImportDiz    := ToBoolean(Objects^[12].Stuff);
     FileArea.TicConvertArcs  := ToBoolean(Objects^[13].Stuff);
     FileArea.TicDestFormat   := _UpperCase(Objects^[14].Stuff);
     FileArea.TicReportNumber := Numeric(Objects^[15].Stuff,WordInteger);
     FileArea.Passthrough     := ToBoolean(Objects^[16].Stuff);
     _CreatePath(_GetFilePath(FileArea.DOS_Name));
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,Number-1);
     WRITE(FFileArea,FileArea);
     CLOSE(FFileArea);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


FUNCTION GetHighFile: Word;
VAR  Highest : Word;
BEGIN
     Highest := 0;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea);
           IF FileArea.AreaID>Highest THEN
              Highest := FileArea.AreaID;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     FillChar(FileArea,SizeOf(FileArea),0);
     GetHighFile := Highest;
END;


PROCEDURE InsertFileArea(Number: Longint);
VAR  Counting : Longint;
BEGIN
     CheckFile('ARCHIVE.DAT');
     FillChar(FileArea2,SizeOf(FileArea2),0);
     FileArea2.sort           := 1;
     FileArea2.AreaId         := GetHighFile+1;
     FileArea2.TicConvertArcs := True;
     FileArea2.TicDestFormat  := ArcDefs.DefaultArc;
     FileArea2.TicImportDiz   := True;
     ASSIGN(FFileArea2,BaseDirectory+'\DATA\FA000000.DAT');
     RENAME(FFileArea2,BaseDirectory+'\DATA\FILEAREA.BAK');
     ASSIGN(FFileArea2,BaseDirectory+'\DATA\FILEAREA.BAK');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea2);
     REWRITE(FFileArea);
     Counting := 0;
     REPEAT
           READ(FFileArea2,FileArea);
           INC(Counting);
           IF Counting=Number THEN WRITE(FFileArea,FileArea2);
           WRITE(FFileArea,FileArea);
     UNTIL EOF(FFileArea2);
     CLOSE(FFileArea);
     CLOSE(FFileArea2);
     ERASE(FFileArea2);
END;


PROCEDURE DeleteFileArea(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\FA000000.DAT',SizeOf(FileArea),Number);
END;


PROCEDURE AddFileArea;
BEGIN
     CheckFile('ARCHIVE.DAT');
     FillChar(FileArea2,SizeOf(FileArea2),0);
     FileArea2.sort           := 1;
     FileArea2.AreaId         := GetHighFile+1;
     FileArea2.TicConvertArcs := True;
     FileArea2.TicDestFormat  := ArcDefs.DefaultArc;
     FileArea2.TicImportDiz   := True;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,FileSize(FFileArea));
     WRITE(FFileArea,FileArea2);
     CLOSE(FFileArea);
END;


PROCEDURE DoFileAreas;
VAR  Loop        : Word;
     OuttaHere   : Boolean;
     Action      : Word;
     OldTop      : Longint;
     OldItem     : Longint;
BEGIN
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     CheckFile('FA000000.DAT');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     PickListItems := FileSize(FFileArea);
     CLOSE(FFileArea);
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := True;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' File Area Name',41);
     PickList_B_Title := 'Sub Group ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     REPEAT
           Read(FFileArea,FileArea);
           PickListFile.A := FileArea.Area_Name;
           IF FileArea.PassThrough
              THEN PickListFile.B := _String(FileArea.Sub)+' (P)'
              ELSE PickListFile.B := _String(FileArea.Sub);
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     CLOSE(FPickListFile);
     SetUpPickList('FILE AREA EDITOR');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   BEGIN                      {EDIT}
                     EditFileArea(PickItem);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     PickListItems := FileSize(FFileArea);
                     CLOSE(FFileArea);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileArea,FileArea);
                           PickListFile.A := FileArea.Area_Name;
                           IF FileArea.PassThrough
                              THEN PickListFile.B := _String(FileArea.Sub)+' (P)'
                              ELSE PickListFile.B := _String(FileArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileArea);
                     CLOSE(FFileArea);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN                      {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteFileArea(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                          RESET(FFileArea);
                          PickListItems := FileSize(FFileArea);
                          CLOSE(FFileArea);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                          RESET(FFileArea);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          REPEAT
                                Read(FFileArea,FileArea);
                                PickListFile.A := FileArea.Area_Name;
                                IF FileArea.PassThrough
                                   THEN PickListFile.B := _String(FileArea.Sub)+' (P)'
                                   ELSE PickListFile.B := _String(FileArea.Sub);
                                WRITE(FPickListFile,PickListFile);
                          UNTIL EOF(FFileArea);
                          CLOSE(FFileArea);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN                      {INSERT}
                     InsertFileArea(PickItem);
                     EditFileArea(PickItem);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     PickListItems := FileSize(FFileArea);
                     CLOSE(FFileArea);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileArea,FileArea);
                           PickListFile.A := FileArea.Area_Name;
                           IF FileArea.PassThrough
                              THEN PickListFile.B := _String(FileArea.Sub)+' (P)'
                              ELSE PickListFile.B := _String(FileArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileArea);
                     CLOSE(FFileArea);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     AddFileArea;
                     EditFileArea(PickListItems+1);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     PickListItems := FileSize(FFileArea);
                     CLOSE(FFileArea);
                     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
                     RESET(FFileArea);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FFileArea,FileArea);
                           PickListFile.A := FileArea.Area_Name;
                           IF FileArea.PassThrough
                              THEN PickListFile.B := _String(FileArea.Sub)+' (P)'
                              ELSE PickListFile.B := _String(FileArea.Sub);
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FFileArea);
                     CLOSE(FFileArea);
                     CLOSE(FPickListFile);
                     UpdatePickList;
                END;
           6:   ;
           7:   BEGIN
                     OldTop  := PickTop;
                     OldItem := PickItem;
                     DoFileDirectory(PickItem);
                END;
           45:  BEGIN                      {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     UseFileButton := False;
END;


PROCEDURE DoProtocols;
BEGIN
     CheckFile('PROTOCOL.DAT');
     ASSIGN(FProtocolInfo,BaseDirectory+'\DATA\PROTOCOL.DAT');
     RESET(FProtocolInfo);
     READ(FProtocolInfo,ProtocolInfo);
     CLOSE(FProtocolInfo);
     DrawWindow(10,7,70,17,'PROTOCOL CONFIGURATION',True);
     AddObject(35,09,6,3 ,_String(ProtocolInfo.EnableX),True);
     AddObject(35,10,6,3 ,_String(ProtocolInfo.EnableX1k),True);
     AddObject(35,11,6,3 ,_String(ProtocolInfo.EnableZ),True);
     AddObject(35,12,6,3 ,_String(ProtocolInfo.EnableY),True);
     AddObject(35,13,6,3 ,_String(ProtocolInfo.EnableYG),True);
     AddObject(63,09,1,1 ,ProtocolInfo.XKey,True);
     AddObject(63,10,1,1 ,ProtocolInfo.X1kKey,True);
     AddObject(63,11,1,1 ,ProtocolInfo.ZKey,True);
     AddObject(63,12,1,1 ,ProtocolInfo.YKey,True);
     AddObject(63,13,1,1 ,ProtocolInfo.YGKey,True);
     AddButton(60,15,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(14,9);  WRITE('Enable컫컴컴 XModem');
     GotoXY(14,10); WRITE('       쳐 1K-XModem');
     GotoXY(14,11); WRITE('       쳐컴� ZModem');
     GotoXY(14,12); WRITE('       쳐컴� YModem');
     GotoXY(14,13); WRITE('       읕� YModem-G');
     GotoXY(41,9);  WRITE('Hot Key컫컴컴 XModem');
     GotoXY(41,10); WRITE('        쳐 1K-XModem');
     GotoXY(41,11); WRITE('        쳐컴� ZModem');
     GotoXY(41,12); WRITE('        쳐컴� YModem');
     GotoXY(41,13); WRITE('        읕� YModem-G');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ProtocolInfo.EnableX     := Numeric(Objects^[1].Stuff,ByteInteger);
     ProtocolInfo.EnableX1k   := Numeric(Objects^[2].Stuff,ByteInteger);
     ProtocolInfo.EnableZ     := Numeric(Objects^[3].Stuff,ByteInteger);
     ProtocolInfo.EnableY     := Numeric(Objects^[4].Stuff,ByteInteger);
     ProtocolInfo.EnableYG    := Numeric(Objects^[5].Stuff,ByteInteger);
     ProtocolInfo.XKey        := Objects^[6].Stuff[1];
     ProtocolInfo.X1kKey      := Objects^[7].Stuff[1];
     ProtocolInfo.ZKey        := Objects^[8].Stuff[1];
     ProtocolInfo.YKey        := Objects^[9].Stuff[1];
     ProtocolInfo.YGKey       := Objects^[10].Stuff[1];
     ASSIGN(FProtocolInfo,BaseDirectory+'\DATA\PROTOCOL.DAT');
     REWRITE(FProtocolInfo);
     WRITE(FProtocolInfo,ProtocolInfo);
     CLOSE(FProtocolInfo);
END;


PROCEDURE DoScannerDefs;
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SCANNERS.DAT');
     ASSIGN(FScanners,BaseDirectory+'\DATA\SCANNERS.DAT');
     RESET(FScanners);
     {$I-}READ(FScanners,Scanners);{$I+}
     IF IOResult=0 THEN;
     CLOSE(FScanners);
     DrawWindow(1,1,80,24,'EDIT VIRUS SCANNER DEFINITIONS',False);
     AddObject(25,3 ,6,3 ,_String(Scanners.ScanUploads),True);
     AddObject(25,5 ,1,40,Scanners.Path[1],True);
     AddObject(25,6 ,1,40,Scanners.CommandLine[1],True);
     AddObject(25,7 ,2,3 ,_String(Scanners.VirusExists[1]),True);
     AddObject(25,9 ,1,40,Scanners.Path[2],True);
     AddObject(25,10,1,40,Scanners.CommandLine[2],True);
     AddObject(25,11,2,3 ,_String(Scanners.VirusExists[2]),True);
     AddObject(25,13,1,40,Scanners.Path[3],True);
     AddObject(25,14,1,40,Scanners.CommandLine[3],True);
     AddObject(25,15,2,3 ,_String(Scanners.VirusExists[3]),True);
     AddObject(25,17,1,40,Scanners.Path[4],True);
     AddObject(25,18,1,40,Scanners.CommandLine[4],True);
     AddObject(25,19,2,3 ,_String(Scanners.VirusExists[4]),True);
     AddObject(25,21,1,40,Scanners.Path[5],True);
     AddObject(25,22,1,40,Scanners.CommandLine[5],True);
     AddObject(25,23,2,3 ,_String(Scanners.VirusExists[5]),True);
     AddButton(70,22,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(9);
     GotoXY(2,4);   WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(2,8);   WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(2,12);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(2,16);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     GotoXY(2,20);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
     TextColor_BS(11);
     GotoXY(6,3);  WRITE(' Scan All Uploads');
     GotoXY(6,5);  WRITE('Scanner Directory');
     GotoXY(6,6);  WRITE('     Command Line');
     GotoXY(6,7);  WRITE(' Virus Errorlevel');
     GotoXY(6,9);  WRITE('Scanner Directory');
     GotoXY(6,10); WRITE('     Command Line');
     GotoXY(6,11); WRITE(' Virus Errorlevel');
     GotoXY(6,13); WRITE('Scanner Directory');
     GotoXY(6,14); WRITE('     Command Line');
     GotoXY(6,15); WRITE(' Virus Errorlevel');
     GotoXY(6,17); WRITE('Scanner Directory');
     GotoXY(6,18); WRITE('     Command Line');
     GotoXY(6,19); WRITE(' Virus Errorlevel');
     GotoXY(6,21); WRITE('Scanner Directory');
     GotoXY(6,22); WRITE('     Command Line');
     GotoXY(6,23); WRITE(' Virus Errorlevel');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Scanners.ScanUploads    := Numeric(Objects^[1].Stuff,ByteInteger);
     Scanners.Path[1]        := ValidateIt(Objects^[2].Stuff,'PATH');
     Scanners.CommandLine[1] := Objects^[3].Stuff;
     Scanners.VirusExists[1] := Numeric(Objects^[4].Stuff,ByteInteger);
     Scanners.Path[2]        := ValidateIt(Objects^[5].Stuff,'PATH');
     Scanners.CommandLine[2] := Objects^[6].Stuff;
     Scanners.VirusExists[2] := Numeric(Objects^[7].Stuff,ByteInteger);
     Scanners.Path[3]        := ValidateIt(Objects^[8].Stuff,'PATH');
     Scanners.CommandLine[3] := Objects^[9].Stuff;
     Scanners.VirusExists[3] := Numeric(Objects^[10].Stuff,ByteInteger);
     Scanners.Path[4]        := ValidateIt(Objects^[11].Stuff,'PATH');
     Scanners.CommandLine[4] := Objects^[12].Stuff;
     Scanners.VirusExists[4] := Numeric(Objects^[13].Stuff,ByteInteger);
     Scanners.Path[5]        := ValidateIt(Objects^[14].Stuff,'PATH');
     Scanners.CommandLine[5] := Objects^[15].Stuff;
     Scanners.VirusExists[5] := Numeric(Objects^[16].Stuff,ByteInteger);
     ASSIGN(FScanners,BaseDirectory+'\DATA\SCANNERS.DAT');
     REWRITE(FScanners);
     WRITE(FScanners,Scanners);
     CLOSE(FScanners);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoArcConversions;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('ARCHIVE.DAT');
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     DrawWindow(5,4,73,11,'ARCHIVE CONVERSION OPTIONS',True);
     AddObject(29,6,1,40,ArcDefs.ArcPath,True);
     AddObject(29,7,6,3,_String(ArcDefs.ConvertArcs),True);
     AddObject(29,8,1,3,ArcDefs.DefaultArc,True);
     AddButton(63,9,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(10,6);  WRITE(' Path To Achivers');
     GotoXY(10,7);  WRITE('Convert Archives?');
     GotoXY(10,8);  WRITE(' Target Extension');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ArcDefs.ArcPath       := ValidateIt(Objects^[1].Stuff,'PATH');
     ArcDefs.ConvertArcs   := Numeric(Objects^[2].Stuff,ByteInteger);
     ArcDefs.DefaultArc    := _UpperCase(Objects^[3].Stuff);
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     REWRITE(FArcDefs);
     WRITE(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoCDRomManager;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(8,7,72,14,'EDIT CD ROM SETTINGS',True);
     AddObject(62,9,6,3,_String(System_Info.CD_Roms),True);
     AddObject(62,10,6,3,_String(System_Info.Use_CD_Temp),True);
     AddButton(62,12,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(12,9);  WRITE('       Do You Want To Enable CD Rom Enhancements');
     GotoXY(12,10); WRITE('Copy Files From CD To Hard Drive Before Download');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.CD_Roms        := Numeric(Objects^[1].Stuff,ByteInteger);
     System_Info.Use_CD_Temp    := Numeric(Objects^[2].Stuff,ByteInteger);
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoImportCDRom;
VAR  C            : Char;
     ImpFile      : String;
     Loop         : Word;
     RomDrive     : String;
     FilesBBSType : Byte;
BEGIN
     CheckFile('ARCHIVE.DAT');
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,68,15,'IMPORT CD ROM',True);
     AddObject(26,11,1,40,'',True);
     AddButton(58,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('Script File');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     IF Objects^[1].Stuff<>'' THEN
     BEGIN
          ImpFile := Objects^[1].Stuff;
          IF _FileExists(ImpFile) THEN
          BEGIN
               FileArea.AreaID         := GetHighFile+1;
               RomDrive                := 'D';
               FileArea.sub            := 1;
               FileArea.cd_rom         := 1;
               FileArea.sort           := 1;
               FileArea.TicConvertArcs := True;
               FileArea.TicDestFormat  := ArcDefs.DefaultArc;
               FileArea.TicImportDiz   := True;
               Toggle[1].Flips   := 7;
               Toggle[1].Current := FileArea.Sort;
               Toggle[1].Flip[1] := 'NONE';
               Toggle[1].Flip[2] := 'ALPHABETICAL (A-Z)';
               Toggle[1].Flip[3] := 'ALPHABETICAL (Z-A)';
               Toggle[1].Flip[4] := 'DATE (NEW-OLD)';
               Toggle[1].Flip[5] := 'DATE (OLD-NEW)';
               Toggle[1].Flip[6] := 'SIZE (LARGE-SMALL)';
               Toggle[1].Flip[7] := 'SIZE (SMALL-LARGE)';
               Toggle[2].Flips   := 2;
               Toggle[2].Current := 1;
               Toggle[2].Flip[1] := 'MULTI LINE';
               Toggle[2].Flip[2] := 'SINGLE LINE';
               DrawWindow(8,7,77,22,'IMPORT CD ROM DEFAULTS',True);
               AddObject(25,11,1,50,FileArea.DOS_Name,True);
               AddObject(25,13,2,5 ,_String(FileArea.View_Access),True);
               AddObject(25,14,2,5 ,_String(FileArea.DL_Access),True);
               AddObject(25,15,7,10,Tags(FileArea.Tags),True);
               AddObject(55,13,2,5 ,_String(FileArea.CD_Rom),True);
               AddObject(55,14,2,5 ,_String(FileArea.Sub),True);
               AddObject(55,15,1,1 ,RomDrive,True);
               AddObject(55,16,8,20,'1',True);
               AddObject(55,17,8,20,'2',True);
               AddButton(67,20,' QUIT ',True,1,16);
               DrawObjects;
               DrawButtons;
               _HideMouse;
               TextBackGround_BS(Colour.WindowBackGround);
               TextColor_BS(9);
               GotoXY(9,12);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
               GotoXY(9,18);  WRITE('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴');
               TextColor_BS(11);
               GotoXY(9,11);  WRITE('  Database Dir');
               GotoXY(9,13);  WRITE('   View Access');
               GotoXY(9,14);  WRITE('     DL Access');
               GotoXY(9,15);  WRITE('     Area Tags');
               GotoXY(39,13); WRITE(' CD Rom Number');
               GotoXY(39,14); WRITE('     Sub Group');
               GotoXY(38,15); WRITE('CD Drive Letter');
               GotoXY(39,16); WRITE('Sorting Method');
               GotoXY(39,17); WRITE('FILES.BBS Type');
               _ShowMouse;
               DoObjects;
               ClearObjects;
               ClearButtons;
               FileArea.DOS_Name    := ValidateIt(Objects^[1].Stuff,'PATH');
               FileArea.View_Access := Numeric(Objects^[2].Stuff,WordInteger);
               FileArea.DL_Access   := Numeric(Objects^[3].Stuff,WordInteger);
               FOR Loop := 1 TO 10 DO
               BEGIN
                    IF Objects^[4].Stuff[Loop]='1' THEN FileArea.Tags[Loop] := 1
                                                   ELSE FileArea.Tags[Loop] := 0;
               END;
               FileArea.CD_Rom      := Numeric(Objects^[5].Stuff,WordInteger);
               FileArea.Sub         := Numeric(Objects^[6].Stuff,WordInteger);
               RomDrive             := _UpperCase(Objects^[7].Stuff);
               FileArea.Sort        := Toggle[1].Current;
               FilesBBSType         := Toggle[2].Current;
               _HideMouse;
               ImportCD(ImpFile,RomDrive,FilesBBSType);
               _ShowMouse;
          END;
     END;
     LoadWindow(WorkDir+'\EDITACC.SCR');
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(C)=0 THEN C := ReadKey;
           END;
     UNTIL NOT(KeyPressed);
END;


PROCEDURE DoRemoveCDRom;
VAR  Removing : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,52,13,'REMOVE CD ROM',True);
     AddObject(34,11,2,5,'',True);
     AddButton(42,11,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('CD Rom ## To Remove');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Removing := Numeric(Objects^[1].Stuff,WordInteger);
     IF Removing<>0 THEN
     BEGIN
          CheckFile('FA000000.DAT');
          ASSIGN(FFileArea2,BaseDirectory+'\DATA\FA000000.DAT');
          RENAME(FFileArea2,BaseDirectory+'\DATA\FILEAREA.BAK');
          ASSIGN(FFileArea2,BaseDirectory+'\DATA\FILEAREA.BAK');
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea2);
          REWRITE(FFileArea);
          REPEAT
                READ(FFileArea2,FileArea);
                IF FileArea.CD_Rom<>0 THEN
                BEGIN
                     IF FileArea.CD_ROM<>Removing
                        THEN WRITE(FFileArea,FileArea)
                        ELSE
                        BEGIN
                             _EraseFile(FileArea.Dos_Name+'.FIL');
                             _EraseFile(FileArea.Dos_Name+'.TXT');
                        END;
                END
                ELSE WRITE(FFileArea,FileArea);
          UNTIL EOF(FFileArea2);
          CLOSE(FFileArea2);
          CLOSE(FFileArea);
          ERASE(FFileArea2);
     END;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoMiscFileAreas;
VAR  Loop : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SYSTEM.DAT');
     CheckFile('FREQ.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     ASSIGN(FFreqs,BaseDirectory+'\DATA\FREQ.DAT');
     RESET(FFreqs);
     READ(FFreqs,Freqs);
     CLOSE(FFreqs);
     DrawWindow(13,4,74,19,'MISCELLANEOUS FILE AREA OPTIONS',True);
     AddObject(41,6,6,3,_String(System_Info.CheckDupes),True);
     AddObject(41,7,6,3,_String(System_Info.CheckDupesCD),True);
     AddObject(41,8,1,8,System_Info.FileListName,True);
     AddObject(41,10,6,3,FromBoolean(Freqs.AllowFreqs),True);
     AddObject(41,11,2,3,_String(Freqs.DaysToKeepRequests),True);
     AddObject(41,12,7,10,Tags(Freqs.Tags),True);
     AddObject(41,13,2,5,_String(Freqs.Access),True);
     AddObject(41,14,2,5,_String(Freqs.SysopMessageAreaID),True);
     AddObject(41,15,1,30,Freqs.SysopMessageTo,True);
     AddButton(65,17,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(15,6);  WRITE('      Dupe Check Uploads');
     GotoXY(15,7);  WRITE('      Dupe Check CD Roms');
     GotoXY(15,8);  WRITE(' File List Name (NO Ext)');
     GotoXY(15,10); WRITE(' Freqs 컴쩡컴컴컴 Enable');
     GotoXY(15,11); WRITE('         쳐 Days To Keep');
     GotoXY(15,12); WRITE('         쳐� Access Tags');
     GotoXY(15,13); WRITE('         쳐 Access Level');
     GotoXY(15,14); WRITE('         쳐컴 Msg AreaID');
     GotoXY(15,15); WRITE('         읕컴컴컴 Msg To');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.CheckDupes   := Numeric(Objects^[1].Stuff,ByteInteger);
     System_Info.CheckDupesCD := Numeric(Objects^[2].Stuff,ByteInteger);
     System_Info.FileListName := ValidateIt(Objects^[3].Stuff,'FILE');
     Freqs.AllowFreqs         := ToBoolean(Objects^[4].Stuff);
     Freqs.DaysToKeepRequests := Numeric(Objects^[5].Stuff,ByteInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[6].Stuff[Loop]='1' THEN Freqs.Tags[Loop] := 1
                                         ELSE Freqs.Tags[Loop] := 0;
     END;
     Freqs.Access             := Numeric(Objects^[7].Stuff,WordInteger);
     Freqs.SysopMessageAreaID := Numeric(Objects^[8].Stuff,WordInteger);
     Freqs.SysopMessageTo     := Objects^[9].Stuff;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     ASSIGN(FFreqs,BaseDirectory+'\DATA\FREQ.DAT');
     REWRITE(FFreqs);
     WRITE(FFreqs,Freqs);
     CLOSE(FFreqs);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoExportDirs;
VAR  ExportFile : Text;
     Temp       : String;
BEGIN
     CheckFile('MAILER.DAT');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     DrawWindow(10,8,70,15,'DIRECTORY EXPORT',True);
     AddObject(26,10,6,3 ,'0',True);
     AddObject(26,11,1,40,MailerInfo.DirList,True);
     AddButton(60,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(12,10); WRITE(' Include CDs');
     GotoXY(12,11); WRITE(' Export File');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     IF Objects^[2].Stuff<>'' THEN
     BEGIN
          ASSIGN(ExportFile,ValidateIt(Objects^[2].Stuff,'FILE'));
          {$I-}REWRITE(ExportFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               WRITELN(ExportFile,';                          ');
               WRITELN(ExportFile,';  Gunshot Directory Export');
               WRITELN(ExportFile,';                          ');
               CheckFile('FA000000.DAT');
               ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
               RESET(FFileArea);
               REPEAT
                     READ(FFileArea,FileArea);
                     IF FileArea.CD_Rom<>0 THEN
                     BEGIN
                          IF Objects^[1].Stuff='1' THEN
                          BEGIN
                               IF FileArea.View_Access<32000 THEN
                               BEGIN
                                    Temp := _UpperCase(FileArea.Area_Path);
                                    WRITELN(ExportFile,Temp);
                               END;
                          END;
                     END
                     ELSE IF NOT(FileArea.PassThrough) THEN
                     BEGIN
                          IF FileArea.View_Access<32000 THEN
                          BEGIN
                               Temp := _UpperCase(FileArea.Area_Path);
                               WRITELN(ExportFile,Temp);
                          END;
                     END;
               UNTIL EOF(FFileArea);
               CLOSE(FFileArea);
               CLOSE(ExportFile);
          END;
     END;
END;


PROCEDURE DoFileHatch;
TYPE The_Areas    = RECORD
     AreaNum      : Word;
     END;
VAR  Loop         : Word;
     OuttaHere    : Boolean;
     Action       : Word;
     FTheAreas    : File Of The_Areas;
     TheAreas     : The_Areas;
     WhichOne     : Byte;
BEGIN
     _SaveWindow(WorkDir+'\HATCH.SCR');
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 0;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := False;
     UseInsertButton  := False;
     UseAddButton     := False;
     UseFileButton    := False;
     UseSelectButton  := True;
     PickList_A_Title := _PadRight(' File Echo Area Description',41);
     PickList_B_Title := 'Area Tag  ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FTheAreas,WorkDir+'\HATCH.FIL');
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     REWRITE(FPickListFile);
     REWRITE(FTheAreas);
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea);
           IF (FileArea.Area_Tag<>'') THEN
           BEGIN
                INC(PickListItems);
                PickListFile.A := FileArea.Area_Name;
                PickListFile.B := FileArea.Area_Tag;
                WRITE(FPickListFile,PickListFile);
                TheAreas.AreaNum := FileArea.AreaID;
                WRITE(FTheAreas,TheAreas);
           END;
     UNTIL EOF(FFileArea);
     CLOSE(FPickListFile);
     CLOSE(FFileArea);
     CLOSE(FTheAreas);
     TheAreas.AreaNum := 0;
     SetUpPickList('HATCH A FILE INTO A FILE ECHO');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           6:   IF (PickItem<>0) THEN
                BEGIN
                     ASSIGN(FTheAreas,WorkDir+'\HATCH.FIL');
                     RESET(FTheAreas);
                     SEEK(FTheAreas,PickItem-1);
                     READ(FTheAreas,TheAreas);
                     CLOSE(FTheAreas);
                     OuttaHere := True;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     LoadWindow(WorkDir+'\HATCH.SCR');
     _EraseFile(WorkDir+'\HATCH.FIL');
     IF (TheAreas.AreaNum<>0) THEN
     BEGIN
          _SaveWindow(WorkDir+'\HATCH.SCR');
          CheckFile('MAILER.DAT');
          ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
          RESET(FMailerInfo);
          SEEK(FMailerInfo,CurrentNode-1);
          READ(FMailerInfo,MailerInfo);
          CLOSE(FMailerInfo);
          DrawWindow(5,7,75,17,'HATCH FILE - NODE#'+_String(CurrentNode),True);
          AddObject(10,10,1,60,'',True);
          AddObject(10,13,1,60,'',True);
          AddButton(55,15,' CANCEL ',True,1,46);
          AddButton(65,15,' HATCH ',True,1,35);
          DrawObjects;
          DrawButtons;
          _HideMouse;
          TextColor_BS(11);
          TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(10,9);  WRITE('Full file name with path (no wildcards!):');
          GotoXY(10,12); WRITE('Description of file:');
          _ShowMouse;
          WhichOne := DoObjects;
          ClearObjects;
          ClearButtons;
          IF WhichOne=2 THEN
          BEGIN
               IF _FileExists(Objects^[1].Stuff) THEN
               BEGIN
                    IF _FileExists(BaseDirectory+'\DATA\LINKS.DAT') THEN
                    BEGIN
                         HatchTheFile(_UpperCase(Objects^[1].Stuff),Objects^[2].Stuff,TheAreas.AreaNum);
                    END;
               END;
          END;
          LoadWindow(WorkDir+'\HATCH.SCR');
     END;
END;


PROCEDURE EditCDRoms(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
     RESET(FCDRoms);
     SEEK(FCDRoms,Number-1);
     READ(FCDRoms,CDRoms);
     CLOSE(FCDRoms);
     DrawWindow(10,8,72,16,'EDIT CD ROM DEFINITION',True);
     AddObject(28,10,1,30,CDRoms.CDName,True);
     AddObject(28,11,2,5,_String(CDRoms.CDNumber),True);
     AddObject(28,12,6,3,_String(CDRoms.CDEnabled),True);
     AddButton(62,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('    Disc Name');
     GotoXY(13,11); WRITE('CD Rom Number');
     GotoXY(13,12); WRITE('    CD Online');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     CDRoms.CDName    := Objects^[1].Stuff;
     CDRoms.CDNumber  := Numeric(Objects^[2].Stuff,WordInteger);
     CDRoms.CDEnabled := Numeric(Objects^[3].Stuff,ByteInteger);
     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
     RESET(FCDRoms);
     SEEK(FCDRoms,Number-1);
     WRITE(FCDRoms,CDRoms);
     CLOSE(FCDRoms);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteCDRoms(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\CDROMS.DAT',SizeOf(CDRoms),Number);
END;


PROCEDURE AddCDRoms;
BEGIN
     FillChar(CDRoms,SizeOf(CDRoms),0);
     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF (IOResult<>0) THEN REWRITE(FCDRoms)
                      ELSE SEEK(FCDRoms,FileSize(FCDRoms));
     WRITE(FCDRoms,CDRoms);
     CLOSE(FCDRoms);
END;


PROCEDURE InsertCDRoms(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(CDRoms,SizeOf(CDRoms),0);
     IF _FileExists(BaseDirectory+'\DATA\CDROMS.DAT') THEN
     BEGIN
          ASSIGN(FCDRoms2,BaseDirectory+'\DATA\CDROMS.DAT');
          RENAME(FCDRoms2,BaseDirectory+'\DATA\CDROMS.BAK');
          ASSIGN(FCDRoms2,BaseDirectory+'\DATA\CDROMS.BAK');
          ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
          RESET(FCDRoms2);
          REWRITE(FCDRoms);
          Counting := 0;
          REPEAT
                READ(FCDRoms2,CDRoms2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FCDRoms,CDRoms);
                WRITE(FCDRoms,CDRoms2);
          UNTIL EOF(FCDRoms2);
          CLOSE(FCDRoms);
          CLOSE(FCDRoms2);
          ERASE(FCDRoms2);
     END
     ELSE
     BEGIN
          ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
          REWRITE(FCDRoms);
          WRITE(FCDRoms,CDRoms);
          CLOSE(FCDRoms);
     END;
END;


PROCEDURE DoCDRomDefinitions;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
          RESET(FCDRoms);
          REPEAT
                Read(FCDRoms,CDRoms);
                PickListFile.A := CDRoms.CDName+'  ['+_String(CDRoms.CDNumber)+']';
                IF CDRoms.CDEnabled=1 THEN PickListFile.B := 'Yes'
                                      ELSE PickListFile.B := 'No';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FCDRoms);
          CLOSE(FCDRoms);
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
     PickList_A_Title := _PadRight(' Disc Name/Number',41);
     PickList_B_Title := 'Online    ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('COMPACT DISC TITLES');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditCDRoms(PickItem);
                     ASSIGN(FCDRoms,BaseDirectory+'\DATA\CDROMS.DAT');
                     RESET(FCDRoms);
                     PickListItems := FileSize(FCDRoms);
                     CLOSE(FCDRoms);
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
                          DeleteCDRoms(PickItem);
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
                          AddCDRoms;
                          EditCDRoms(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertCDRoms(PickItem);
                          EditCDRoms(PickItem);
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
                     AddCDRoms;
                     EditCDRoms(PickListItems+1);
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


PROCEDURE EditArcUtil(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('ARCUTILS.DAT');
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     RESET(FArcUtils);
     SEEK(FArcUtils,Number-1);
     READ(FArcUtils,ArcUtils);
     CLOSE(FArcUtils);
     DrawWindow(10,7,78,18,'EDIT ARCHIVER DEFINITIONS',True);
     AddObject(34,9,1,3 ,ArcUtils.Extension,True);
     AddObject(34,10,1,40,ArcUtils.CopyArc,True);
     AddObject(34,11,1,40,ArcUtils.MoveArc,True);
     AddObject(34,12,1,40,ArcUtils.ExtractArc,True);
     AddObject(34,13,1,40,ArcUtils.ExtractArcNoPath,True);
     AddObject(34,14,1,40,ArcUtils.ViewArc,True);
     AddButton(68,16,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(12,9);  WRITE('           Extension');
     GotoXY(12,10); WRITE('          Add To Arc');
     GotoXY(12,11); WRITE('         Move To Arc');
     GotoXY(12,12); WRITE('         Extract Arc');
     GotoXY(12,13); WRITE('Extract Arc (NoPath)');
     GotoXY(12,14); WRITE('            View Arc');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ArcUtils.Extension        := _UpperCase(Objects^[1].Stuff);
     ArcUtils.CopyArc          := Objects^[2].Stuff;
     ArcUtils.MoveArc          := Objects^[3].Stuff;
     ArcUtils.ExtractArc       := Objects^[4].Stuff;
     ArcUtils.ExtractArcNoPath := Objects^[5].Stuff;
     ArcUtils.ViewArc          := Objects^[6].Stuff;
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     RESET(FArcUtils);
     SEEK(FArcUtils,Number-1);
     WRITE(FArcUtils,ArcUtils);
     CLOSE(FArcUtils);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteArcUtil(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\ARCUTILS.DAT',SizeOf(ArcUtils),Number);
END;


PROCEDURE AddArcUtil;
BEGIN
     FillChar(ArcUtils,SizeOf(ArcUtils),0);
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     {$I-}RESET(FArcUtils);{$I+}
     IF (IOResult<>0) THEN REWRITE(FArcUtils)
                      ELSE SEEK(FArcUtils,FileSize(FArcUtils));
     WRITE(FArcUtils,ArcUtils);
     CLOSE(FArcUtils);
END;


PROCEDURE InsertArcUtil(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(ArcUtils,SizeOf(ArcUtils),0);
     IF _FileExists(BaseDirectory+'\DATA\ARCUTILS.DAT') THEN
     BEGIN
          ASSIGN(FArcUtils2,BaseDirectory+'\DATA\ARCUTILS.DAT');
          RENAME(FArcUtils2,BaseDirectory+'\DATA\ARCUTILS.BAK');
          ASSIGN(FArcUtils2,BaseDirectory+'\DATA\ARCUTILS.BAK');
          ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
          RESET(FArcUtils2);
          REWRITE(FArcUtils);
          Counting := 0;
          REPEAT
                READ(FArcUtils2,ArcUtils2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FArcUtils,ArcUtils);
                WRITE(FArcUtils,ArcUtils2);
          UNTIL EOF(FArcUtils2);
          CLOSE(FArcUtils);
          CLOSE(FArcUtils2);
          ERASE(FArcUtils2);
     END
     ELSE
     BEGIN
          ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
          REWRITE(FArcUtils);
          WRITE(FArcUtils,ArcUtils);
          CLOSE(FArcUtils);
     END;
END;


PROCEDURE DoArcDefs;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
          RESET(FArcUtils);
          REPEAT
                Read(FArcUtils,ArcUtils);
                PickListFile.A := ArcUtils.Extension;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FArcUtils);
          CLOSE(FArcUtils);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     {$I-}RESET(FArcUtils);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FArcUtils);
          CLOSE(FArcUtils);
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
     PickList_A_Title := _PadRight(' Archiver',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('ARCHIVER UTILITY DEFINITIONS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditArcUtil(PickItem);
                     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
                     RESET(FArcUtils);
                     PickListItems := FileSize(FArcUtils);
                     CLOSE(FArcUtils);
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
                          DeleteArcUtil(PickItem);
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
                          AddArcUtil;
                          EditArcUtil(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertArcUtil(PickItem);
                          EditArcUtil(PickItem);
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
                     AddArcUtil;
                     EditArcUtil(PickListItems+1);
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
