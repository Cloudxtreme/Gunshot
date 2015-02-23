{$I DEFINES.INC}
UNIT MENU7;


INTERFACE


PROCEDURE DoLinkManager;
PROCEDURE DoUUCP;
PROCEDURE DoPhoneBook;
PROCEDURE DoGSFileKill;
PROCEDURE DoEditNodes;
PROCEDURE DoFaxSetup;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,BsFile,Crt,Defaults,CnfgVars,Misc,Shotgun,MkFFile,FMode,BsAkas,Valid;


FUNCTION FileEchoTagged(SystemAka: AddrType; AreaID: Word; CheckForDat: Boolean): Boolean;
VAR  EchoTag     : _GSFileDat_Record;
     BytesRead   : Word;
BEGIN
     IF CheckForDat THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\GSFILE.DAT')) THEN
          BEGIN
               FileEchoTagged := False;
               Exit;
          END;
     END;
     WorkingFile.OpenFile(BaseDirectory+'\DATA\GSFILE.DAT',SetFileMode);
     REPEAT
           WorkingFile.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
           IF (BytesRead<>0) THEN
           BEGIN
                IF EchoTag.AreaId=AreaID THEN
                BEGIN
                     IF AkasMatch(EchoTag.Aka,SystemAka) THEN
                     BEGIN
                          WorkingFile.CloseFile;
                          FileEchoTagged := True;
                          Exit;
                     END;
                END;
           END;
     UNTIL BytesRead=0;
     WorkingFile.CloseFile;
     FileEchoTagged := False;
END;


FUNCTION TagTheFileEcho(PItem: Longint): Boolean;
VAR  EchoTag   : _GSFileDat_Record;
     FEchoTag  : File Of _GSFileDat_Record;
     TheId     : Word;
BEGIN
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     RESET(FPickListFile);
     SEEK(FPickListFile,PItem-1);
     READ(FPickListFile,PickListFile);
     TheId := _Numeric(_RemoveSpaces(PickListFile.B));
     CLOSE(FPickListFile);
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT') THEN
     BEGIN
          IF NOT(FileEchoTagged(Links.NetworkAddress,TheID,False)) THEN
          BEGIN
               EchoTag.Aka    := Links.NetworkAddress;
               EchoTag.AreaID := TheId;
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
               RESET(FEchoTag);
               SEEK(FEchoTag,FileSize(FEchoTag));
               WRITE(FEchoTag,EchoTag);
               CLOSE(FEchoTag);
               TagTheFileEcho := True;
          END
          ELSE TagTheFileEcho := False;
     END
     ELSE
     BEGIN
          EchoTag.Aka    := Links.NetworkAddress;
          EchoTag.AreaID := TheId;
          ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
          REWRITE(FEchoTag);
          WRITE(FEchoTag,EchoTag);
          CLOSE(FEchoTag);
          TagTheFileEcho := True;
     END;
END;


PROCEDURE AddLink;
BEGIN
     FillChar(Links,SizeOf(Links),0);
     FillChar(LinkGroups,SizeOf(LinkGroups),0);
     LinkGroups.CreateFileGroup  := 1;
     LinkGroups.CreateMsgGroup   := 1;
     LinkGroups.FileGroups[1]    := 1;
     LinkGroups.MessageGroups[1] := 1;
     Links.AkaToUse              := 1;
     Links.NetMailStatus         := 1;
     Links.AccessLevel           := 10;
     Links.AllowPause            := True;
     Links.AllowResume           := True;
     Links.AllowRescan           := True;
     Links.AllowHelp             := True;
     Links.AllowPassword         := True;
     Links.AllowCompress         := True;
     Links.AllowList             := True;
     Links.AllowQuery            := True;
     Links.AllowUnlinked         := True;
     Links.Archiver              := 'ZIP';
     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
     {$I-}RESET(FLinks);{$I+}
     IF (IOResult<>0) THEN REWRITE(FLinks)
                      ELSE SEEK(FLinks,FileSize(FLinks));
     WRITE(FLinks,Links);
     CLOSE(FLinks);
     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
     {$I-}RESET(FLinkGroups);{$I+}
     IF (IOResult<>0) THEN REWRITE(FLinkGroups)
                      ELSE SEEK(FLinkGroups,FileSize(FLinkGroups));
     WRITE(FLinkGroups,LinkGroups);
     CLOSE(FLinkGroups);
END;


PROCEDURE InsertLink(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Links,SizeOf(Links),0);
     FillChar(LinkGroups,SizeOf(LinkGroups),0);
     LinkGroups.CreateFileGroup  := 1;
     LinkGroups.CreateMsgGroup   := 1;
     LinkGroups.FileGroups[1]    := 1;
     LinkGroups.MessageGroups[1] := 1;
     Links.AkaToUse              := 1;
     Links.NetMailStatus         := 1;
     Links.AccessLevel           := 10;
     Links.AllowPause            := True;
     Links.AllowResume           := True;
     Links.AllowRescan           := True;
     Links.AllowHelp             := True;
     Links.AllowPassword         := True;
     Links.AllowCompress         := True;
     Links.AllowList             := True;
     Links.AllowQuery            := True;
     Links.AllowUnlinked         := True;
     Links.Archiver              := 'ZIP';
     IF _FileExists(BaseDirectory+'\DATA\LINKS.DAT') THEN
     BEGIN
          ASSIGN(FLinks2,BaseDirectory+'\DATA\LINKS.DAT');
          RENAME(FLinks2,BaseDirectory+'\DATA\LINKS.BAK');
          ASSIGN(FLinks2,BaseDirectory+'\DATA\LINKS.BAK');
          ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
          RESET(FLinks2);
          REWRITE(FLinks);
          Counting := 0;
          REPEAT
                READ(FLinks2,Links2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FLinks,Links);
                WRITE(FLinks,Links2);
          UNTIL EOF(FLinks2);
          CLOSE(FLinks);
          CLOSE(FLinks2);
          ERASE(FLinks2);
     END
     ELSE
     BEGIN
          ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
          REWRITE(FLinks);
          WRITE(FLinks,Links);
          CLOSE(FLinks);
     END;
     IF _FileExists(BaseDirectory+'\DATA\LINKGRPS.DAT') THEN
     BEGIN
          ASSIGN(FLinkGroups2,BaseDirectory+'\DATA\LINKGRPS.DAT');
          RENAME(FLinkGroups2,BaseDirectory+'\DATA\LINKGRPS.BAK');
          ASSIGN(FLinkGroups2,BaseDirectory+'\DATA\LINKGRPS.BAK');
          ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
          RESET(FLinkGroups2);
          REWRITE(FLinkGroups);
          Counting := 0;
          REPEAT
                READ(FLinkGroups2,LinkGroups2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FLinkGroups,LinkGroups);
                WRITE(FLinkGroups,LinkGroups2);
          UNTIL EOF(FLinkGroups2);
          CLOSE(FLinkGroups);
          CLOSE(FLinkGroups2);
          ERASE(FLinkGroups2);
     END
     ELSE
     BEGIN
          ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
          REWRITE(FLinkGroups);
          WRITE(FLinkGroups,LinkGroups);
          CLOSE(FLinkGroups);
     END;
END;


PROCEDURE DeleteLink(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\LINKS.DAT',SizeOf(Links),Number);
     _EraseFileRecord(BaseDirectory+'\DATA\LINKGRPS.DAT',SizeOf(LinkGroups),Number);
END;


FUNCTION DeleteTheFileEcho(PItem: Longint): Boolean;
VAR  EchoTag    : _GSFileDat_Record;
     FEchoTag   : File Of _GSFileDat_Record;
     FEchoTag2  : File Of _GSFileDat_Record;
     TheId      : Word;
BEGIN
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     RESET(FPickListFile);
     SEEK(FPickListFile,PItem-1);
     READ(FPickListFile,PickListFile);
     TheId := _Numeric(_RemoveSpaces(PickListFile.B));
     CLOSE(FPickListFile);
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT') THEN
     BEGIN
          IF FileEchoTagged(Links.NetworkAddress,TheID,False) THEN
          BEGIN
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
               RENAME(FEchoTag,BaseDirectory+'\DATA\GSFILE.BAK');
               ASSIGN(FEchoTag2,BaseDirectory+'\DATA\GSFILE.BAK');
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
               REWRITE(FEchoTag);
               RESET(FEchoTag2);
               REPEAT
                     READ(FEchoTag2,EchoTag);
                     IF ((EchoTag.AreaID<>TheID) OR (NOT(AkasMatch(EchoTag.Aka,Links.NetworkAddress))))
                        THEN WRITE(FEchoTag,EchoTag);
               UNTIL EOF(FEchoTag2);
               CLOSE(FEchoTag);
               CLOSE(FEchoTag2);
               ERASE(FEchoTag2);
               IF _FileSize(BaseDirectory+'\DATA\GSFILE.DAT')=0 THEN ERASE(FEchoTag);
               DeleteTheFileEcho := True;
          END
          ELSE DeleteTheFileEcho := False;
     END
     ELSE DeleteTheFileEcho := False;
END;


PROCEDURE EditFileEchoAreas;
VAR  Loop        : Word;
     OuttaHere   : Boolean;
     Action      : Word;
     NeedToCheck : Boolean;

     FUNCTION HasAccessToThisGroup: Boolean;
     VAR  Poop : Word;
     BEGIN
          FOR Poop := 1 TO 200 DO
          BEGIN
               IF LinkGroups.FileGroups[Poop]=FileArea.Sub THEN
               BEGIN
                    HasAccessToThisGroup := True;
                    Exit;
               END;
          END;
          HasAccessToThisGroup := False;
     END;

BEGIN
     WorkingFile.Init(32768);
     _SaveWindow(WorkDir+'\FILEECHO.SCR');
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 0;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := True;
     UseInsertButton  := False;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' File Echo Area Name',41);
     PickList_B_Title := 'Area ID   ';
     PickListX        := 11;
     PickListY        := 4;
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT')
        THEN NeedToCheck := False
        ELSE NeedToCheck := True;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     REWRITE(FPickListFile);
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea);
           IF ((FileArea.Area_Tag<>'') AND (HasAccessToThisGroup)) THEN
           BEGIN
                INC(PickListItems);
                IF FileEchoTagged(Links.NetworkAddress,FileArea.AreaId,NeedToCheck)
                   THEN PickListFile.A := 'û '+FileArea.Area_Name
                   ELSE PickListFile.A := '  '+FileArea.Area_Name;
                PickListFile.B := _String(FileArea.AreaId);
                WRITE(FPickListFile,PickListFile);
           END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     CLOSE(FPickListFile);
     SetUpPickList('CONNECTED AREAS FOR: '+Links.SysopName+' ('+AddressToString(Links.NetworkAddress)+')');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickListItems>0) THEN
                BEGIN {Space Bar/Enter}
                     IF TagTheFileEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := 'û';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END
                     ELSE IF DeleteTheFileEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := ' ';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           2:   IF (PickListItems>0) THEN
                BEGIN {DELETE}
                     IF DeleteTheFileEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := ' ';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           5:   IF (PickListItems>0) THEN
                BEGIN {ADD}
                     IF TagTheFileEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := 'û';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     LoadWindow(WorkDir+'\FILEECHO.SCR');
     WorkingFile.Done;
END;


FUNCTION MessageEchoTagged(SystemAka: AddrType; AreaID: Word; CheckForDat: Boolean): Boolean;
VAR  EchoTag   : _GSEchoDat_Record;
     BytesRead : Word;
BEGIN
     IF CheckForDat THEN
     BEGIN
          IF NOT(_FileExists(BaseDirectory+'\DATA\GSECHO.DAT')) THEN
          BEGIN
               MessageEchoTagged := False;
               Exit;
          END;
     END;
     WorkingFile.OpenFile(BaseDirectory+'\DATA\GSECHO.DAT',SetFileMode);
     REPEAT
           WorkingFile.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
           IF (BytesRead<>0) THEN
           BEGIN
                IF EchoTag.AreaId=AreaID THEN
                BEGIN
                     IF AkasMatch(EchoTag.Aka,SystemAka) THEN
                     BEGIN
                          WorkingFile.CloseFile;
                          MessageEchoTagged := True;
                          Exit;
                     END;
                END;
           END;
     UNTIL BytesRead=0;
     WorkingFile.CloseFile;
     MessageEchoTagged := False;
END;


FUNCTION TagTheMessageEcho(PItem: Longint): Boolean;
VAR  EchoTag   : _GSEchoDat_Record;
     FEchoTag  : File Of _GSEchoDat_Record;
     TheId     : Word;
BEGIN
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     RESET(FPickListFile);
     SEEK(FPickListFile,PItem-1);
     READ(FPickListFile,PickListFile);
     TheId := _Numeric(_RemoveSpaces(PickListFile.B));
     CLOSE(FPickListFile);
     IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT') THEN
     BEGIN
          IF NOT(MessageEchoTagged(Links.NetworkAddress,TheID,False)) THEN
          BEGIN
               EchoTag.Aka    := Links.NetworkAddress;
               EchoTag.AreaID := TheId;
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSECHO.DAT');
               RESET(FEchoTag);
               SEEK(FEchoTag,FileSize(FEchoTag));
               WRITE(FEchoTag,EchoTag);
               CLOSE(FEchoTag);
               TagTheMessageEcho := True;
          END
          ELSE TagTheMessageEcho := False;
     END
     ELSE
     BEGIN
          EchoTag.Aka    := Links.NetworkAddress;
          EchoTag.AreaID := TheId;
          ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSECHO.DAT');
          REWRITE(FEchoTag);
          WRITE(FEchoTag,EchoTag);
          CLOSE(FEchoTag);
          TagTheMessageEcho := True;
     END;
END;


FUNCTION DeleteTheMessageEcho(PItem: Longint): Boolean;
VAR  EchoTag    : _GSEchoDat_Record;
     FEchoTag   : File Of _GSEchoDat_Record;
     FEchoTag2  : File Of _GSEchoDat_Record;
     TheId      : Word;
BEGIN
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     RESET(FPickListFile);
     SEEK(FPickListFile,PItem-1);
     READ(FPickListFile,PickListFile);
     TheId := _Numeric(_RemoveSpaces(PickListFile.B));
     CLOSE(FPickListFile);
     IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT') THEN
     BEGIN
          IF MessageEchoTagged(Links.NetworkAddress,TheID,False) THEN
          BEGIN
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSECHO.DAT');
               RENAME(FEchoTag,BaseDirectory+'\DATA\GSECHO.BAK');
               ASSIGN(FEchoTag2,BaseDirectory+'\DATA\GSECHO.BAK');
               ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSECHO.DAT');
               REWRITE(FEchoTag);
               RESET(FEchoTag2);
               REPEAT
                     READ(FEchoTag2,EchoTag);
                     IF ((EchoTag.AreaID<>TheID) OR (NOT(AkasMatch(EchoTag.Aka,Links.NetworkAddress))))
                        THEN WRITE(FEchoTag,EchoTag);
               UNTIL EOF(FEchoTag2);
               CLOSE(FEchoTag);
               CLOSE(FEchoTag2);
               ERASE(FEchoTag2);
               IF _FileSize(BaseDirectory+'\DATA\GSECHO.DAT')=0 THEN ERASE(FEchoTag);
               DeleteTheMessageEcho := True;
          END
          ELSE DeleteTheMessageEcho := False;
     END
     ELSE DeleteTheMessageEcho := False;
END;


PROCEDURE EditMessageEchoAreas;
VAR  Loop        : Word;
     OuttaHere   : Boolean;
     Action      : Word;
     NeedToCheck : Boolean;

     FUNCTION HasAccessToThisGroup: Boolean;
     VAR  Poop : Word;
     BEGIN
          FOR Poop := 1 TO 200 DO
          BEGIN
               IF LinkGroups.MessageGroups[Poop]=MessageArea.Sub THEN
               BEGIN
                    HasAccessToThisGroup := True;
                    Exit;
               END;
          END;
          HasAccessToThisGroup := False;
     END;

BEGIN
     WorkingFile.Init(32768);
     _SaveWindow(WorkDir+'\MAILECHO.SCR');
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 0;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := True;
     UseInsertButton  := False;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Mail Echo Area Name',41);
     PickList_B_Title := 'Area ID   ';
     PickListX        := 11;
     PickListY        := 4;
     IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT')
        THEN NeedToCheck := False
        ELSE NeedToCheck := True;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
     REWRITE(FPickListFile);
     RESET(FMessageArea);
     REPEAT
           READ(FMessageArea,MessageArea);
           IF ((MessageArea.Area_Tag<>'') AND (HasAccessToThisGroup)) THEN
           BEGIN
                INC(PickListItems);
                IF MessageEchoTagged(Links.NetworkAddress,MessageArea.AreaId,NeedToCheck)
                   THEN PickListFile.A := 'û '+MessageArea.Area_Name
                   ELSE PickListFile.A := '  '+MessageArea.Area_Name;
                PickListFile.B := _String(MessageArea.AreaId);
                WRITE(FPickListFile,PickListFile);
           END;
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     CLOSE(FPickListFile);
     SetUpPickList('CONNECTED ECHOES FOR: '+Links.SysopName+' ('+AddressToString(Links.NetworkAddress)+')');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickListItems>0) THEN
                BEGIN {Space Bar/Enter}
                     IF TagTheMessageEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := 'û';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END
                     ELSE IF DeleteTheMessageEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := ' ';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           2:   IF (PickListItems>0) THEN
                BEGIN {DELETE}
                     IF DeleteTheMessageEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := ' ';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           5:   IF (PickListItems>0) THEN
                BEGIN {ADD}
                     IF TagTheMessageEcho(PickItem) THEN
                     BEGIN
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          RESET(FPickListFile);
                          SEEK(FPickListFile,PickItem-1);
                          READ(FPickListFile,PickListFile);
                          PickListFile.A[1] := 'û';
                          SEEK(FPickListFile,PickItem-1);
                          WRITE(FPickListFile,PickListFile);
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     LoadWindow(WorkDir+'\MAILECHO.SCR');
     WorkingFile.Done;
END;


PROCEDURE EditFileGroups;
VAR  WhatToDo : Word;
     X        : Word;
     Y        : Word;
     Page     : Word;
LABEL           OverAgain;

     PROCEDURE DrawGroups;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          X := 16;
          Y := 4;
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               AddObject(X,Y,2,5,_String(LinkGroups.FileGroups[Which]),True);
               INC(Y);
               IF Y=24 THEN
               BEGIN
                    INC(X,12);
                    Y := 4;
               END;
          END;
     END;

     PROCEDURE Reload;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          LinkGroups.CreateFileGroup := Numeric(Objects^[1].Stuff,WordInteger);
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               LinkGroups.FileGroups[Which] := Numeric(Objects^[Loop+1].Stuff,WordInteger);
          END;
     END;

     PROCEDURE DrawGroupNumbers;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          X := 11;
          Y := 4;
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               GotoXY(X,Y); WRITE(_PadLeft(_String(Which),3));
               INC(Y);
               IF Y=24 THEN
               BEGIN
                    INC(X,12);
                    Y := 4;
               END;
          END;
     END;

BEGIN
     Page := 1;
     _SaveWindow(WorkDir+'\FILEGRPS.SCR');
     OverAgain:
     DrawWindow(1,1,80,25,'EDIT FILE GROUP ACCESS FOR '+AddressToString(Links.NetworkAddress),False);
     AddObject(16,3,2,5,_String(LinkGroups.CreateFileGroup),True);
     DrawGroups;
     AddButton(72,19,' QUIT ',True,1,16);
     AddButton(72,21,' PREV ',True,1,25);
     AddButton(72,23,' NEXT ',True,1,49);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(3,3); WRITE('Auto-Create');
     DrawGroupNumbers;
     _ShowMouse;
     REPEAT
           WhatToDo := DoObjects;
           CASE WhatToDo OF
           2:   IF (Page<>1) THEN
                BEGIN
                     Reload;
                     ClearObjects;
                     ClearButtons;
                     Page := 1;
                     GOTO OverAgain;
                END;
           3:   IF (Page<>2) THEN
                BEGIN
                     Reload;
                     ClearObjects;
                     ClearButtons;
                     Page := 2;
                     GOTO OverAgain;
                END;
           END;
     UNTIL WhatToDo=1;
     ClearObjects;
     ClearButtons;
     Reload;
     LoadWindow(WorkDir+'\FILEGRPS.SCR');
END;


PROCEDURE EditMsgGroups;
VAR  WhatToDo : Word;
     X        : Word;
     Y        : Word;
     Page     : Word;
LABEL           OverAgain;

     PROCEDURE DrawGroups;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          X := 16;
          Y := 4;
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               AddObject(X,Y,2,5,_String(LinkGroups.MessageGroups[Which]),True);
               INC(Y);
               IF Y=24 THEN
               BEGIN
                    INC(X,12);
                    Y := 4;
               END;
          END;
     END;

     PROCEDURE Reload;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          LinkGroups.CreateMsgGroup := Numeric(Objects^[1].Stuff,WordInteger);
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               LinkGroups.MessageGroups[Which] := Numeric(Objects^[Loop+1].Stuff,WordInteger);
          END;
     END;

     PROCEDURE DrawGroupNumbers;
     VAR  Loop  : Word;
          Which : Word;
     BEGIN
          X := 11;
          Y := 4;
          FOR Loop := 1 TO 100 DO
          BEGIN
               IF Page=1 THEN Which := Loop
                         ELSE Which := Loop+100;
               GotoXY(X,Y); WRITE(_PadLeft(_String(Which),3));
               INC(Y);
               IF Y=24 THEN
               BEGIN
                    INC(X,12);
                    Y := 4;
               END;
          END;
     END;

BEGIN
     Page := 1;
     _SaveWindow(WorkDir+'\MSGGRPS.SCR');
     OverAgain:
     DrawWindow(1,1,80,25,'EDIT MESSAGE GROUP ACCESS FOR '+AddressToString(Links.NetworkAddress),False);
     AddObject(16,3,2,5,_String(LinkGroups.CreateMsgGroup),True);
     DrawGroups;
     AddButton(72,19,' QUIT ',True,1,16);
     AddButton(72,21,' PREV ',True,1,25);
     AddButton(72,23,' NEXT ',True,1,49);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(3,3); WRITE('Auto-Create');
     DrawGroupNumbers;
     _ShowMouse;
     REPEAT
           WhatToDo := DoObjects;
           CASE WhatToDo OF
           2:   IF (Page<>1) THEN
                BEGIN
                     Reload;
                     ClearObjects;
                     ClearButtons;
                     Page := 1;
                     GOTO OverAgain;
                END;
           3:   IF (Page<>2) THEN
                BEGIN
                     Reload;
                     ClearObjects;
                     ClearButtons;
                     Page := 2;
                     GOTO OverAgain;
                END;
           END;
     UNTIL WhatToDo=1;
     ClearObjects;
     ClearButtons;
     Reload;
     LoadWindow(WorkDir+'\MSGGRPS.SCR');
END;


PROCEDURE EditLink(Number: Longint);
VAR  Loop         : Word;
     WhatToDo     : Word;
LABEL           AllOverAgain;

     PROCEDURE LoadBackIn;
     BEGIN
          Links.SysopName      := Objects^[1].Stuff;
          StringToAddress(Objects^[2].Stuff,Links.NetworkAddress);
          Links.AkaToUse       := Numeric(Objects^[3].Stuff,ByteInteger);
          Links.AccessLevel    := Numeric(Objects^[4].Stuff,WordInteger);
          Links.AreaCreate     := ToBoolean(Objects^[5].Stuff);
          Links.NetMailStatus  := Toggle[1].Current;
          Links.Paused         := ToBoolean(Objects^[7].Stuff);
          Links.SendNotify     := ToBoolean(Objects^[8].Stuff);
          Links.AllowPause     := ToBoolean(Objects^[9].Stuff);
          Links.AllowResume    := ToBoolean(Objects^[10].Stuff);
          Links.AllowRescan    := ToBoolean(Objects^[11].Stuff);
          Links.AllowHelp      := ToBoolean(Objects^[12].Stuff);
          Links.AllowPassword  := ToBoolean(Objects^[13].Stuff);
          Links.AllowCompress  := ToBoolean(Objects^[14].Stuff);
          Links.AllowList      := ToBoolean(Objects^[15].Stuff);
          Links.AllowQuery     := ToBoolean(Objects^[16].Stuff);
          Links.AllowUnlinked  := ToBoolean(Objects^[17].Stuff);
          Links.GSFileTIC      := _UpperCase(Objects^[18].Stuff);
          Links.GSFileAreaFix  := _UpperCase(Objects^[19].Stuff);
          Links.GSEchoPacket   := _UpperCase(Objects^[20].Stuff);
          Links.GSEchoAreaFix  := _UpperCase(Objects^[21].Stuff);
          Links.Archiver       := _UpperCase(Objects^[22].Stuff);
     END;

     PROCEDURE CleanUpTheMess;
     BEGIN
          ClearObjects;
          ClearButtons;
          LoadBackIn;
          ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
          RESET(FLinks);
          SEEK(FLinks,Number-1);
          WRITE(FLinks,Links);
          CLOSE(FLinks);
          ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
          RESET(FLinkGroups);
          SEEK(FLinkGroups,Number-1);
          WRITE(FLinkGroups,LinkGroups);
          CLOSE(FLinkGroups);
          DoingLinksEdit := False;
     END;

BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     AllOverAgain:
     DoingLinksEdit := True;
     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
     RESET(FLinks);
     SEEK(FLinks,Number-1);
     READ(FLinks,Links);
     CLOSE(FLinks);
     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
     RESET(FLinkGroups);
     SEEK(FLinkGroups,Number-1);
     READ(FLinkGroups,LinkGroups);
     CLOSE(FLinkGroups);
     Toggle[1].Flips   := 3;
     Toggle[1].Current := Links.NetMailStatus;
     Toggle[1].Flip[1] := 'NONE';
     Toggle[1].Flip[2] := 'HOLD';
     Toggle[1].Flip[3] := 'CRASH';
     DrawWindow(1,1,80,25,'EDIT UPLINK/DOWNLINK',False);
     AddObject(21,3,1,30,Links.SysopName,True);
     AddObject(21,4,1,20,AddressToString(Links.NetworkAddress),True);
     AddObject(21,5,2,3,_String(Links.AkaToUse),True);
     AddObject(21,6,2,5,_String(Links.AccessLevel),True);
     AddObject(21,8,6,3,FromBoolean(Links.AreaCreate),True);
     AddObject(21,9,8,20,'1',True);
     AddObject(21,10,6,3,FromBoolean(Links.Paused),True);
     AddObject(21,11,6,3,FromBoolean(Links.SendNotify),True);
     AddObject(21,13,6,3,FromBoolean(Links.AllowPause),True);
     AddObject(21,14,6,3,FromBoolean(Links.AllowResume),True);
     AddObject(21,15,6,3,FromBoolean(Links.AllowRescan),True);
     AddObject(21,16,6,3,FromBoolean(Links.AllowHelp),True);
     AddObject(21,17,6,3,FromBoolean(Links.AllowPassword),True);
     AddObject(44,13,6,3,FromBoolean(Links.AllowCompress),True);
     AddObject(44,14,6,3,FromBoolean(Links.AllowList),True);
     AddObject(44,15,6,3,FromBoolean(Links.AllowQuery),True);
     AddObject(44,16,6,3,FromBoolean(Links.AllowUnlinked),True);
     AddObject(21,19,1,8,Links.GSFileTIC,True);
     AddObject(44,19,1,8,Links.GSFileAreaFix,True);
     AddObject(21,20,1,8,Links.GSEchoPacket,True);
     AddObject(44,20,1,8,Links.GSEchoAreaFix,True);
     AddObject(21,21,1,3,Links.Archiver,True);
     AddButton(5,23,' QUIT ',True,1,16);
     AddButton(13,23,' FILE ECHOES ',True,1,33);
     AddButton(28,23,' MAIL ECHOES ',True,1,50);
     AddButton(43,23,' 1.FILE GROUPS ',True,1,120);
     AddButton(60,23,' 2.MSG GROUPS ',True,1,121);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(3,3);   WRITE('     Sysops Name');
     GotoXY(3,4);   WRITE(' Network Address');
     GotoXY(3,5);   WRITE(' Your AKA To Use');
     GotoXY(3,6);   WRITE('    Access Level');
     GotoXY(3,8);   WRITE('AutoCreate Areas');
     GotoXY(3,9);   WRITE('  Netmail Status');
     GotoXY(3,10);  WRITE('     Node Paused');
     GotoXY(3,11);  WRITE('     Send Notify');
     GotoXY(3,13);  WRITE(' AFixÄÄÄÄ %PAUSE');
     GotoXY(3,14);  WRITE('    ÃÄÄÄ %RESUME');
     GotoXY(3,15);  WRITE('    ÃÄÄÄ %RESCAN');
     GotoXY(3,16);  WRITE('    ÃÄÄÄÄÄ %HELP');
     GotoXY(3,17);  WRITE('    ÀÄ %PASSWORD');
     GotoXY(26,13); WRITE(' AFixÄ %COMPRESS');
     GotoXY(26,14); WRITE('    ÃÄÄÄÄÄ %LIST');
     GotoXY(26,15); WRITE('    ÃÄÄÄÄ %QUERY');
     GotoXY(26,16); WRITE('    ÀÄ %UNLINKED');
     GotoXY(3,19);  WRITE('    TIC Password');
     GotoXY(3,20);  WRITE('    PKT Password');
     GotoXY(3,21);  WRITE('        Archiver');
     GotoXY(31,19); WRITE('GSFile AFix');
     GotoXY(31,20); WRITE('GSEcho AFix');
     TextColor_BS(14);
     GotoXY(26,5);
     WRITE(GetNetAddress(Links.AkaToUse));
     WRITE('@'+GetNetDomain(Links.AkaToUse));
     _ShowMouse;
     REPEAT
           WhatToDo := DoObjects;
           CASE WhatToDo OF
           2:   BEGIN
                     CleanUpTheMess;
                     EditFileEchoAreas;
                     GOTO AllOverAgain;
                END;
           3:   BEGIN
                     CleanUpTheMess;
                     EditMessageEchoAreas;
                     GOTO AllOverAgain;
                END;
           4:   BEGIN
                     CleanUpTheMess;
                     EditFileGroups;
                     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
                     RESET(FLinkGroups);
                     SEEK(FLinkGroups,Number-1);
                     WRITE(FLinkGroups,LinkGroups);
                     CLOSE(FLinkGroups);
                     GOTO AllOverAgain;
                END;
           5:   BEGIN
                     CleanUpTheMess;
                     EditMsgGroups;
                     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
                     RESET(FLinkGroups);
                     SEEK(FLinkGroups,Number-1);
                     WRITE(FLinkGroups,LinkGroups);
                     CLOSE(FLinkGroups);
                     GOTO AllOverAgain;
                END;
           END;
     UNTIL WhatToDo=1;
     ClearObjects;
     ClearButtons;
     LoadBackIn;
     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
     RESET(FLinks);
     SEEK(FLinks,Number-1);
     WRITE(FLinks,Links);
     CLOSE(FLinks);
     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
     RESET(FLinkGroups);
     SEEK(FLinkGroups,Number-1);
     WRITE(FLinkGroups,LinkGroups);
     CLOSE(FLinkGroups);
     LoadWindow(WorkDir+'\EDITACC.SCR');
     DoingLinksEdit := False;
END;


PROCEDURE DoLinkManager;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;
BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
     {$I-}RESET(FLinks);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FLinks);
          CLOSE(FLinks);
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
     PickList_A_Title := _PadRight(' Node',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN
     BEGIN
          ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
          RESET(FLinks);
          REPEAT
                Read(FLinks,Links);
                PickListFile.A := _PadRight(Links.SysopName,25)+' '+AddressToString(Links.NetWorkAddress);
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FLinks);
          CLOSE(FLinks);
     END;
     CLOSE(FPickListFile);
     SetUpPickList('UPLINK/DOWNLINK MANAGER');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True;         {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditLink(PickItem);
                     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                     RESET(FLinks);
                     PickListItems := FileSize(FLinks);
                     CLOSE(FLinks);
                     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                     RESET(FLinks);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLinks,Links);
                           PickListFile.A := _PadRight(Links.SysopName,25)+' '+AddressToString(Links.NetWorkAddress);
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLinks);
                     CLOSE(FLinks);
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteLink(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN
                          BEGIN
                               ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                               RESET(FLinks);
                               REPEAT
                                     Read(FLinks,Links);
                                     PickListFile.A := _PadRight(Links.SysopName,25)+' '+AddressToString(Links.NetWorkAddress);
                                     PickListFile.B := '';
                                     WRITE(FPickListFile,PickListFile);
                               UNTIL EOF(FLinks);
                               CLOSE(FLinks);
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
                          AddLink;
                          EditLink(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertLink(PickItem);
                          EditLink(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                     RESET(FLinks);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLinks,Links);
                           PickListFile.A := _PadRight(Links.SysopName,25)+' '+AddressToString(Links.NetWorkAddress);
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLinks);
                     CLOSE(FLinks);
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           4:   ;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddLink;
                     EditLink(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                     RESET(FLinks);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     REPEAT
                           Read(FLinks,Links);
                           PickListFile.A := _PadRight(Links.SysopName,25)+' '+AddressToString(Links.NetWorkAddress);
                           PickListFile.B := '';
                           WRITE(FPickListFile,PickListFile);
                     UNTIL EOF(FLinks);
                     CLOSE(FLinks);
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
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


PROCEDURE DoUUCP;
BEGIN
     CheckFile('UUCP.DAT');
     ASSIGN(FUUCP,BaseDirectory+'\DATA\UUCP.DAT');
     RESET(FUUCP);
     READ(FUUCP,UUCP);
     CLOSE(FUUCP);
     DrawWindow(10,8,72,16,'FIDO/UUCP GATEWAY SETUP',True);
     AddObject(28,10,1,40,UUCP.HostName,True);
     AddObject(28,11,1,20,AddressToString(UUCP.HostAddress),True);
     AddObject(28,12,1,20,AddressToString(UUCP.YourAddress),True);
     AddButton(62,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('    Gate Name');
     GotoXY(13,11); WRITE(' Host Address');
     GotoXY(13,12); WRITE(' Your Address');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     UUCP.HostName    := Objects^[1].Stuff;
     StringToAddress(Objects^[2].Stuff,UUCP.HostAddress);
     StringToAddress(Objects^[3].Stuff,UUCP.YourAddress);
     ASSIGN(FUUCP,BaseDirectory+'\DATA\UUCP.DAT');
     REWRITE(FUUCP);
     WRITE(FUUCP,UUCP);
     CLOSE(FUUCP);
END;


PROCEDURE EditPhoneBook(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
     RESET(FPhoneBook);
     SEEK(FPhoneBook,Number-1);
     READ(FPhoneBook,PhoneBook);
     CLOSE(FPhoneBook);
     DrawWindow(10,8,72,16,'EDIT QUICK PHONEBOOK ENTRY',True);
     AddObject(28,10,1,30,PhoneBook.UserName,True);
     AddObject(28,11,1,20,AddressToString(PhoneBook.NetAddress),True);
     AddObject(28,12,1,40,PhoneBook.Description,True);
     AddButton(62,14,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('   Alias Name');
     GotoXY(13,11); WRITE('  Net Address');
     GotoXY(13,12); WRITE('    User Name');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     PhoneBook.UserName    := Objects^[1].Stuff;
     StringToAddress(Objects^[2].Stuff,PhoneBook.NetAddress);
     PhoneBook.Description := Objects^[3].Stuff;
     ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
     RESET(FPhoneBook);
     SEEK(FPhoneBook,Number-1);
     WRITE(FPhoneBook,PhoneBook);
     CLOSE(FPhoneBook);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeletePhoneBook(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\PBOOK.DAT',SizeOf(PhoneBook),Number);
END;


PROCEDURE AddPhoneBook;
BEGIN
     FillChar(PhoneBook,SizeOf(PhoneBook),0);
     ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
     {$I-}RESET(FPhoneBook);{$I+}
     IF (IOResult<>0) THEN REWRITE(FPhoneBook)
                      ELSE SEEK(FPhoneBook,FileSize(FPhoneBook));
     WRITE(FPhoneBook,PhoneBook);
     CLOSE(FPhoneBook);
END;


PROCEDURE InsertPhoneBook(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(PhoneBook,SizeOf(PhoneBook),0);
     IF _FileExists(BaseDirectory+'\DATA\PBOOK.DAT') THEN
     BEGIN
          ASSIGN(FPhoneBook2,BaseDirectory+'\DATA\PBOOK.DAT');
          RENAME(FPhoneBook2,BaseDirectory+'\DATA\PBOOK.BAK');
          ASSIGN(FPhoneBook2,BaseDirectory+'\DATA\PBOOK.BAK');
          ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
          RESET(FPhoneBook2);
          REWRITE(FPhoneBook);
          Counting := 0;
          REPEAT
                READ(FPhoneBook2,PhoneBook2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FPhoneBook,PhoneBook);
                WRITE(FPhoneBook,PhoneBook2);
          UNTIL EOF(FPhoneBook2);
          CLOSE(FPhoneBook);
          CLOSE(FPhoneBook2);
          ERASE(FPhoneBook2);
     END
     ELSE
     BEGIN
          ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
          REWRITE(FPhoneBook);
          WRITE(FPhoneBook,PhoneBook);
          CLOSE(FPhoneBook);
     END;
END;


PROCEDURE DoPhoneBook;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
          RESET(FPhoneBook);
          REPEAT
                Read(FPhoneBook,PhoneBook);
                PickListFile.A := PhoneBook.Description;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FPhoneBook);
          CLOSE(FPhoneBook);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
     {$I-}RESET(FPhoneBook);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FPhoneBook);
          CLOSE(FPhoneBook);
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
     PickList_A_Title := _PadRight(' User Name',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('QUICK PHONEBOOK CONFIGURATION');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditPhoneBook(PickItem);
                     ASSIGN(FPhoneBook,BaseDirectory+'\DATA\PBOOK.DAT');
                     RESET(FPhoneBook);
                     PickListItems := FileSize(FPhoneBook);
                     CLOSE(FPhoneBook);
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
                          DeletePhoneBook(PickItem);
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
                          AddPhoneBook;
                          EditPhoneBook(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertPhoneBook(PickItem);
                          EditPhoneBook(PickItem);
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
                     AddPhoneBook;
                     EditPhoneBook(PickListItems+1);
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


PROCEDURE EditGSFileKill(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
     RESET(FGSFileKill);
     SEEK(FGSFileKill,Number-1);
     READ(FGSFileKill,GSFileKill);
     CLOSE(FGSFileKill);
     DrawWindow(10,8,44,14,'EDIT GSFILE AUTO-PURGE ENTRY',True);
     AddObject(28,10,1,12,GSFileKill.AreaName,True);
     AddButton(34,12,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE(' TIC Area Tag');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     GSFileKill.AreaName := _UpperCase(Objects^[1].Stuff);
     ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
     RESET(FGSFileKill);
     SEEK(FGSFileKill,Number-1);
     WRITE(FGSFileKill,GSFileKill);
     CLOSE(FGSFileKill);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteGSFileKill(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\SGFPURGE.DAT',SizeOf(GSFileKill),Number);
END;


PROCEDURE AddGSFileKill;
BEGIN
     FillChar(GSFileKill,SizeOf(GSFileKill),0);
     ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
     {$I-}RESET(FGSFileKill);{$I+}
     IF (IOResult<>0) THEN REWRITE(FGSFileKill)
                      ELSE SEEK(FGSFileKill,FileSize(FGSFileKill));
     WRITE(FGSFileKill,GSFileKill);
     CLOSE(FGSFileKill);
END;


PROCEDURE InsertGSFileKill(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(GSFileKill,SizeOf(GSFileKill),0);
     IF _FileExists(BaseDirectory+'\DATA\SGFPURGE.DAT') THEN
     BEGIN
          ASSIGN(FGSFileKill2,BaseDirectory+'\DATA\SGFPURGE.DAT');
          RENAME(FGSFileKill2,BaseDirectory+'\DATA\SGFPURGE.BAK');
          ASSIGN(FGSFileKill2,BaseDirectory+'\DATA\SGFPURGE.BAK');
          ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
          RESET(FGSFileKill2);
          REWRITE(FGSFileKill);
          Counting := 0;
          REPEAT
                READ(FGSFileKill2,GSFileKill2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FGSFileKill,GSFileKill);
                WRITE(FGSFileKill,GSFileKill2);
          UNTIL EOF(FGSFileKill2);
          CLOSE(FGSFileKill);
          CLOSE(FGSFileKill2);
          ERASE(FGSFileKill2);
     END
     ELSE
     BEGIN
          ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
          REWRITE(FGSFileKill);
          WRITE(FGSFileKill,GSFileKill);
          CLOSE(FGSFileKill);
     END;
END;


PROCEDURE DoGSFileKill;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
          RESET(FGSFileKill);
          REPEAT
                Read(FGSFileKill,GSFileKill);
                PickListFile.A := GSFileKill.AreaName;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FGSFileKill);
          CLOSE(FGSFileKill);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
     {$I-}RESET(FGSFileKill);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FGSFileKill);
          CLOSE(FGSFileKill);
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
     PickList_A_Title := _PadRight(' TIC Area Tag',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('GSFILE AUTO-PURGE CONFIGURATION');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditGSFileKill(PickItem);
                     ASSIGN(FGSFileKill,BaseDirectory+'\DATA\SGFPURGE.DAT');
                     RESET(FGSFileKill);
                     PickListItems := FileSize(FGSFileKill);
                     CLOSE(FGSFileKill);
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
                          DeleteGSFileKill(PickItem);
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
                          AddGSFileKill;
                          EditGSFileKill(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertGSFileKill(PickItem);
                          EditGSFileKill(PickItem);
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
                     AddGSFileKill;
                     EditGSFileKill(PickListItems+1);
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


PROCEDURE DeleteNodeListSG(Number: Longint);
BEGIN
     _EraseFileRecord(MailerInfo.NodeList+'NODELIST.PVT',SizeOf(NodeListSG),Number);
END;


PROCEDURE AddNodeListSG;
BEGIN
     FillChar(NodeListSG,SizeOf(NodeListSG),0);
     NodeListSG.Baud          := 9600;
     NodeListSG.NodelistFlags := 'CM,XA,V32b,V42b';
     ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
     {$I-}RESET(FNodeListSG);{$I+}
     IF (IOResult<>0) THEN REWRITE(FNodeListSG)
                      ELSE SEEK(FNodeListSG,FileSize(FNodeListSG));
     WRITE(FNodeListSG,NodeListSG);
     CLOSE(FNodeListSG);
END;


PROCEDURE InsertNodeListSG(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(NodeListSG,SizeOf(NodeListSG),0);
     NodeListSG.Baud          := 9600;
     NodeListSG.NodelistFlags := 'CM,XA,V32b,V42b';
     IF _FileExists(MailerInfo.NodeList+'NODELIST.PVT') THEN
     BEGIN
          ASSIGN(FNodeListSG2,MailerInfo.NodeList+'NODELIST.PVT');
          RENAME(FNodeListSG2,MailerInfo.NodeList+'NODELIST.BAK');
          ASSIGN(FNodeListSG2,MailerInfo.NodeList+'NODELIST.BAK');
          ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
          RESET(FNodeListSG2);
          REWRITE(FNodeListSG);
          Counting := 0;
          REPEAT
                READ(FNodeListSG2,NodeListSG2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FNodeListSG,NodeListSG);
                WRITE(FNodeListSG,NodeListSG2);
          UNTIL EOF(FNodeListSG2);
          CLOSE(FNodeListSG);
          CLOSE(FNodeListSG2);
          ERASE(FNodeListSG2);
     END
     ELSE
     BEGIN
          ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
          REWRITE(FNodeListSG);
          WRITE(FNodeListSG,NodeListSG);
          CLOSE(FNodeListSG);
     END;
END;


FUNCTION NoCommas(InString: String): String;
VAR  Work : Word;
BEGIN
     REPEAT
       Work := Pos(',',InString);
       IF (Work<>0) THEN Delete(InString,Work,1);
     UNTIL Work=0;
     NoCommas := InString;
END;


PROCEDURE EditNodeListSG(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
     RESET(FNodeListSG);
     SEEK(FNodeListSG,Number-1);
     READ(FNodeListSG,NodeListSG);
     CLOSE(FNodeListSG);
     DrawWindow(5,6,70,18,'EDIT PRIVATE NODES',True);
     AddObject(26,8,1,30,NodeListSG.Sysop,True);
     AddObject(26,9,1,30,NodeListSG.System,True);
     AddObject(26,10,1,40,NodeListSG.Location,True);
     AddObject(26,11,1,20,AddressToString(NodeListSG.Aka),True);
     AddObject(26,12,1,40,NodeListSG.Phone,True);
     AddObject(26,13,2,5,_String(NodeListSG.Baud),True);
     AddObject(26,14,1,40,NodeListSG.NodelistFlags,True);
     AddButton(60,16,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(7,8);  WRITE('            Sysop');
     GotoXY(7,9);  WRITE('      System Name');
     GotoXY(7,10); WRITE('         Location');
     GotoXY(7,11); WRITE('      Network Aka');
     GotoXY(7,12); WRITE('     Phone Number');
     GotoXY(7,13); WRITE('        Baud Rate');
     GotoXY(7,14); WRITE('   Nodelist Flags');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     NodeListSG.Sysop         := NoCommas(Objects^[1].Stuff);
     NodeListSG.System        := NoCommas(Objects^[2].Stuff);
     NodeListSG.Location      := NoCommas(Objects^[3].Stuff);
     StringToAddress(Objects^[4].Stuff,NodeListSG.Aka);
     NodeListSG.Phone         := NoCommas(Objects^[5].Stuff);
     NodeListSG.Baud          := Numeric(Objects^[6].Stuff,WordInteger);
     NodeListSG.NodelistFlags := Objects^[7].Stuff;
     ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
     RESET(FNodeListSG);
     SEEK(FNodeListSG,Number-1);
     WRITE(FNodeListSG,NodeListSG);
     CLOSE(FNodeListSG);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoEditNodes;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
          RESET(FNodeListSG);
          REPEAT
                Read(FNodeListSG,NodeListSG);
                PickListFile.A := NodeListSG.System;
                PickListFile.B := AddressToString(NodeListSG.Aka);
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FNodeListSG);
          CLOSE(FNodeListSG);
     END;

BEGIN
     CheckFile('MAILER.DAT');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
     {$I-}RESET(FNodeListSG);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FNodeListSG);
          CLOSE(FNodeListSG);
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
     PickList_A_Title := _PadRight(' System Name',41);
     PickList_B_Title := ' Aka      ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('EDIT PRIVATE NODES');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditNodeListSG(PickItem);
                     ASSIGN(FNodeListSG,MailerInfo.NodeList+'NODELIST.PVT');
                     RESET(FNodeListSG);
                     PickListItems := FileSize(FNodeListSG);
                     CLOSE(FNodeListSG);
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
                          DeleteNodeListSG(PickItem);
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
                          AddNodeListSG;
                          EditNodeListSG(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertNodeListSG(PickItem);
                          EditNodeListSG(PickItem);
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
                     AddNodeListSG;
                     EditNodeListSG(PickListItems+1);
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


PROCEDURE DoFaxSetup;
BEGIN
     CheckFile('FAXCODES');
     ASSIGN(FFaxCodes,BaseDirectory+'\DATA\FAXCODES.'+_String(CurrentNode));
     RESET(FFaxCodes);
     READ(FFaxCodes,FaxCodes);
     CLOSE(FFaxCodes);
     _SaveWindow(WorkDir+'\FAXCODES.SCR');

     Toggle[1].Flips   := 3;
     Toggle[1].Current := FaxCodes.FaxSendClass;
     Toggle[1].Flip[1] := 'Class 1';
     Toggle[1].Flip[2] := 'Class 2';
     Toggle[1].Flip[3] := 'Class 2.0';
     Toggle[2].Flips   := 3;
     Toggle[2].Current := FaxCodes.FaxRecvClass;
     Toggle[2].Flip[1] := 'Class 1';
     Toggle[2].Flip[2] := 'Class 2';
     Toggle[2].Flip[3] := 'Class 2.0';
     Toggle[3].Flips   := 6;
     Toggle[3].Current := FaxCodes.FaxSendBPS;
     Toggle[3].Flip[1] := '2400';
     Toggle[3].Flip[2] := '4800';
     Toggle[3].Flip[3] := '7200';
     Toggle[3].Flip[4] := '9600';
     Toggle[3].Flip[5] := '12000';
     Toggle[3].Flip[6] := '14400';
     Toggle[4].Flips   := 6;
     Toggle[4].Current := FaxCodes.FaxRecvBPS;
     Toggle[4].Flip[1] := '2400';
     Toggle[4].Flip[2] := '4800';
     Toggle[4].Flip[3] := '7200';
     Toggle[4].Flip[4] := '9600';
     Toggle[4].Flip[5] := '12000';
     Toggle[4].Flip[6] := '14400';

     DrawWindow(2,3,79,22,'FAX CONFIGURATION - NODE #'+_String(CurrentNode),True);
     AddObject(27,5,8,20,'1',True);
     AddObject(27,6,8,20,'2',True);
     AddObject(27,7,8,20,'3',True);
     AddObject(27,8,8,20,'4',True);
     AddObject(27,9,1,30,FaxCodes.FaxSender,True);
     AddObject(27,10,1,20,FaxCodes.FaxID,True);
     AddObject(27,11,6,3,FromBoolean(FaxCodes.FaxErrorCorrection),True);
     AddObject(27,12,6,3,FromBoolean(FaxCodes.PrintFaxes),True);
     AddObject(27,13,1,30,FaxCodes.SetHardwareCompression,True);
     AddObject(27,14,1,40,FaxCodes.FaxCoverPage,True);
     AddObject(27,15,1,40,FaxCodes.FaxLogo,True);
     AddObject(4,18,1,74,FaxCodes.FaxPageHeader,True);
     AddButton(69,20,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(5,5);  WRITE('          Send Class');
     GotoXY(5,6);  WRITE('       Receive Class');
     GotoXY(5,7);  WRITE('            Send BPS');
     GotoXY(5,8);  WRITE('         Receive BPS');
     GotoXY(5,9);  WRITE('         Sender Name');
     GotoXY(5,10); WRITE('          Station ID');
     GotoXY(5,11); WRITE('    Error Correction');
     GotoXY(5,12); WRITE('Print Received Faxes');
     GotoXY(5,13); WRITE('Hardware Handshaking');
     GotoXY(5,14); WRITE('      Fax Cover Page');
     GotoXY(5,15); WRITE('    Fax Logo Graphic');
     GotoXY(4,17); WRITE('Fax Page Header:');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     FaxCodes.FaxSendClass           := Toggle[1].Current;
     FaxCodes.FaxRecvClass           := Toggle[2].Current;
     FaxCodes.FaxSendBPS             := Toggle[3].Current;
     FaxCodes.FaxRecvBPS             := Toggle[4].Current;
     FaxCodes.FaxSender              := Objects^[5].Stuff;
     FaxCodes.FaxID                  := Objects^[6].Stuff;
     FaxCodes.FaxErrorCorrection     := ToBoolean(Objects^[7].Stuff);
     FaxCodes.PrintFaxes             := ToBoolean(Objects^[8].Stuff);
     FaxCodes.SetHardwareCompression := Objects^[9].Stuff;
     FaxCodes.FaxCoverPage           := ValidateIt(Objects^[10].Stuff,'FILE');
     FaxCodes.FaxLogo                := ValidateIt(Objects^[11].Stuff,'FILE');
     FaxCodes.FaxPageHeader          := Objects^[12].Stuff;
     ASSIGN(FFaxCodes,BaseDirectory+'\DATA\FAXCODES.'+_String(CurrentNode));
     REWRITE(FFaxCodes);
     WRITE(FFaxCodes,FaxCodes);
     CLOSE(FFaxCodes);
     LoadWindow(WorkDir+'\FAXCODES.SCR');
END;


END.