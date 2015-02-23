{$I DEFINES.INC}
UNIT Process;


INTERFACE


USES Gunshot;


FUNCTION  LoadTheTic: Boolean;
FUNCTION  LoadTheLink(InAddress: AddrType; DoPw: Boolean): Boolean;
FUNCTION  LoadTheArea: Boolean;
FUNCTION  PurgeThisArea(InString: String): Boolean;
FUNCTION  LoadSub(Index: Word): Boolean;
FUNCTION  ZeroPadded(Number: Word): String;
FUNCTION  IsOurNode(InAddress: AddrType): Boolean;
FUNCTION  GetNetAddress(Num: Word): Boolean;
FUNCTION  GetNetOrigin(Num: Word): String;
FUNCTION  PathTime: String;
PROCEDURE PackOutboundTics;
PROCEDURE WriteNodeFile;
PROCEDURE CopyToWork;
PROCEDURE DearcArchive;
PROCEDURE VirusCheck;
PROCEDURE ExtFILE_IDDIZ;
PROCEDURE RearcArchive;
PROCEDURE AddToDatabase;
PROCEDURE MoveToBadPath;
PROCEDURE CleanUp;


IMPLEMENTATION


USES Globals,BsString,BsAkas,LogFile,BsFile,ApMisc,AreaSort,TicName,
     FastW1,BigCopy,BsExec,Dos,BsCrc,Status,Version,MkMisc,MsgWrite,
     BsTime,BsVideo,KeyCheck;


PROCEDURE MakeWrappedDesc;
VAR  AllDone     : Boolean;
     Loop2       : Word;
     Good        : Boolean;
     LastSpace   : Word;
     Start       : Word;
     Temp        : String;
     Loop        : Word;
     Msg_Text    : String;
     OrigDesc    : String;
BEGIN
     OrigDesc := TicFile.OneDescription+#255;
     FillChar(WrappedDesc,SizeOf(WrappedDesc),0);
     NumWrappedDesc := 1;
     Loop           := 0;
     AllDone        := False;
     Msg_Text       := '';
     REPEAT
       INC(Loop);
       IF OrigDesc[Loop]=#255 THEN
       BEGIN
         IF NumWrappedDesc<=18 THEN WrappedDesc[NumWrappedDesc] := Msg_Text;
         AllDone := True;
       END
       ELSE
       BEGIN
         Loop2     := Loop;
         Good      := False;
         LastSpace := Loop;
         Start     := Loop;
         Temp      := '';
         REPEAT
           Temp := Temp+OrigDesc[Loop2];
           IF LENGTH(Temp)<=45 THEN
           BEGIN
             IF OrigDesc[Loop2]=#32 THEN LastSpace := Loop2;
           END;
           CASE Ord(OrigDesc[Loop2]) OF
           255: BEGIN
                  Delete(Temp,Length(Temp),1);
                  Msg_Text := Temp;
                  IF NumWrappedDesc<=18 THEN
                  BEGIN
                    WrappedDesc[NumWrappedDesc] := Msg_Text;
                    INC(NumWrappedDesc);
                  END;
                  Msg_Text := '';
                  AllDone  := True;
                  Good     := True;
                  Loop     := Loop2;
                END;
           ELSE BEGIN
                  IF LENGTH(Temp)>45 THEN
                  BEGIN
                    Temp := '';
                    FOR Loop2 := Start TO LastSpace DO Temp := Temp+OrigDesc[Loop2];
                    Loop := LastSpace;
                    Good := True;
                    Msg_Text := Temp;
                    IF NumWrappedDesc<=18 THEN
                    BEGIN
                      WrappedDesc[NumWrappedDesc] := Msg_Text;
                      INC(NumWrappedDesc);
                    END;
                    Msg_Text := '';
                  END;
                END;
           END;
           INC(Loop2);
         UNTIL Good;
       END;
     UNTIL AllDone;
     FOR Loop2 := 1 TO 18 DO
     BEGIN
       WrappedDesc[Loop2] := _RemoveLeftSpaces(WrappedDesc[Loop2]);
       WrappedDesc[Loop2] := _RemoveRightSpaces(WrappedDesc[Loop2]);
     END;
     WHILE WrappedDesc[NumWrappedDesc]='' DO DEC(NumWrappedDesc);
END;


FUNCTION LoadSub(Index: Word): Boolean;
VAR  GotIt : Boolean;
BEGIN
     GotIt := False;
     ASSIGN(FFileSubs,BaseDirectory+'\DATA\FILEAREA.SUB');
     {$I-}RESET(FFileSubs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FFileSubs,FileSubs);
         IF FileSubs.Sub_Num=Index THEN GotIt := True;
       UNTIL ((EOF(FFileSubs)) OR (GotIt));
       CLOSE(FFileSubs);
     END;
     LoadSub := GotIt;
END;


FUNCTION ZeroPadded(Number: Word): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := _String(Number);
     FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
     ZeroPadded := Temp;
END;


FUNCTION LoadTheLink(InAddress: AddrType; DoPw: Boolean): Boolean;
VAR  GotIt : Boolean;
BEGIN
     GotIt := False;
     ASSIGN(FLinkGroups,BaseDirectory+'\DATA\LINKGRPS.DAT');
     ASSIGN(FLinksInfo,BaseDirectory+'\DATA\LINKS.DAT');
     RESET(FLinkGroups);
     RESET(FLinksInfo);
     REPEAT
       READ(FLinksInfo,LinksInfo);
       READ(FLinkGroups,LinkGroups);
       IF AkasMatch(LinksInfo.NetworkAddress,InAddress) THEN GotIt := True;
     UNTIL ((EOF(FLinksInfo)) OR (GotIt));
     CLOSE(FLinkGroups);
     CLOSE(FLinksInfo);
     IF GotIt THEN
     BEGIN
       IF DoPw THEN
       BEGIN
         IF (_UpperCase(LinksInfo.GSFileTIC)<>TicFile.Password) THEN GotIt := False;
         IF NOT(GotIt) THEN
         BEGIN
           WriteLogFile('  ! TIC password from '+AddressToString(TicFile.AkaFrom)+' is incorrect.');
           WriteLogFile('  ! Expected: "'+LinksInfo.GSFileTIC+'"  Received: "'+TicFile.Password+'".');
           MoveToBadPath;
         END;
       END;
     END
     ELSE
     BEGIN
       WriteLogFile('  ! Link not found: '+AddressToString(TicFile.AkaFrom)+'. Check your LINKS setup in GSConfig.');
       MoveToBadPath;
     END;
     LoadTheLink := GotIt;
END;


PROCEDURE GoGetFromFileBoneNa;
VAR  Temp      : String;
     TFile     : Text;
     WorkArray : Array[1..5] Of String;
     Work      : Word;
     Loop      : Word;
BEGIN
     IF FileSubs.FileBoneNa='' THEN Exit;
     IF _FileExists(FileSubs.FileBoneNa) THEN
     BEGIN
       ASSIGN(TFile,FileSubs.FileBoneNa);
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         FillChar(WorkArray,SizeOf(WorkArray),0);
         FOR Loop := 1 TO 4 DO
         BEGIN
           Temp := _RemoveLeftSpaces(Temp);
           Work := Pos(' ',Temp);
           IF (Work<>0) THEN
           BEGIN
             WorkArray[Loop] := _Mid(Temp,1,Work-1);
             Delete(Temp,1,Work);
           END;
         END;
         WorkArray[5] := _RemoveLeftSpaces(Temp);
         WorkArray[1] := _UpperCase(WorkArray[1]);
         WorkArray[2] := _UpperCase(WorkArray[2]);
         IF WorkArray[1]='AREA' THEN
         BEGIN
           IF WorkArray[2]=TicFile.AreaTag THEN
           BEGIN
             FileArea.area_name := _Mid(WorkArray[5],1,40);
             CLOSE(TFile);
             Exit;
           END;
         END;
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END;
END;


FUNCTION LoadTheArea: Boolean;
VAR  GotIt    : Boolean;
     EchoTag  : _GSFileDat_Record;
     FEchoTag : File Of _GSFileDat_Record;
     TheCrc   : String[8];
     NewId    : Word;
     Loop     : Word;
     Temp     : String;
     TFile    : Text;
LABEL           OverAgain;
BEGIN
     OverAgain:
     GotIt := False;
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileArea);
       IF _UpperCase(FileArea.Area_Tag)=TicFile.AreaTag THEN GotIt := True;
     UNTIL (EOF(FFileArea) OR GotIt);
     CLOSE(FFileArea);
     IF NOT(GotIt) THEN
     BEGIN
       IF LinksInfo.AreaCreate THEN
       BEGIN
         IF LoadSub(LinkGroups.CreateFileGroup) THEN
         BEGIN
           TheCrc := StringCRC(TicFile.AreaTag);
           NewID := 1;
           ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
           RESET(FFileArea);
           REPEAT
             READ(FFileArea,FileArea);
             IF FileArea.AreaID>NewID THEN NewID := FileArea.AreaID;
           UNTIL EOF(FFileArea);
           CLOSE(FFileArea);
           INC(NewId);
           FillChar(FileArea,SizeOf(FileArea),0);
           FOR Loop := 1 TO 10 DO FileArea.tags[Loop] := FileSubs.Tags[Loop];
           FileArea.AreaId          := NewId;
           FileArea.sub             := LinkGroups.CreateFileGroup;
           FileArea.TicConvertArcs  := FileSubs.TicConvertArcs;
           FileArea.TicDestFormat   := FileSubs.TicDestFormat;
           FileArea.TicImportDiz    := FileSubs.TicImportDiz;
           FileArea.TicReportNumber := FileSubs.TicReportNumber;
           FileArea.view_access     := FileSubs.View_Access;
           FileArea.dl_access       := FileSubs.DL_Access;
           FileArea.cd_rom          := FileSubs.CD_Rom;
           FileArea.sort            := FileSubs.Sort;
           FileArea.area_name       := TicFile.AreaTag;
           IF (TicFile.AreaDesc='')
              THEN GoGetFromFileBoneNa
              ELSE FileArea.area_name := TicFile.AreaDesc;
           FileArea.area_tag        := TicFile.AreaTag;
           FileArea.PassThrough     := FileSubs.PassThrough;
           IF FileArea.PassThrough THEN
           BEGIN
             FileArea.dos_name  := '\';
             FileArea.area_path := '\';
           END
           ELSE
           BEGIN
             FileArea.dos_name  := FileSubs.Area_Path+TheCRC+'\'+TheCRC;
             FileArea.area_path := FileSubs.Area_Path+TheCRC+'\';
             _CreatePath(FileArea.area_path);
           END;
           {Add To Main Database}
           ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
           RESET(FFileArea);
           SEEK(FFileArea,FileSize(FFileArea));
           WRITE(FFileArea,FileArea);
           CLOSE(FFileArea);
           {Add To Group Database}
           ASSIGN(FFileArea,BaseDirectory+'\DATA\FA'+ZeroPadded(FileArea.Sub)+'.DAT');
           {$I-}RESET(FFileArea);{$I+}
           IF IOResult=0 THEN SEEK(FFileArea,FileSize(FFileArea))
                         ELSE REWRITE(FFileArea);
           WRITE(FFileArea,FileArea);
           CLOSE(FFileArea);
           {Announce It}
           Temp := 'Auto-Created Area:  '+_PadRight(TicFile.AreaTag,20)+'Node: '+AddressToString(LinksInfo.NetworkAddress);
           WriteLogFile('  $ '+'Auto-Created Area: '+TicFile.AreaTag+'  Node: '+AddressToString(LinksInfo.NetworkAddress));
           ASSIGN(TFile,BaseDirectory+'\!21\AUTOADD.TXT');
           {$I-}APPEND(TFile);{$I+}
           IF IOResult<>0 THEN REWRITE(TFile);
           WRITELN(TFile,Temp);
           CLOSE(TFile);
           {Connect The Node That Sent It}
           EchoTag.AreaId := NewId;
           EchoTag.Aka    := LinksInfo.NetworkAddress;
           ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
           {$I-}RESET(FEchoTag);{$I+}
           IF IOResult<>0 THEN REWRITE(FEchoTag);
           SEEK(FEchoTag,FileSize(FEchoTag));
           WRITE(FEchoTag,EchoTag);
           CLOSE(FEchoTag);
           GOTO OverAgain;
         END
         ELSE
         BEGIN
           WriteLogFile('  ! File sub group #'+_String(LinkGroups.CreateFileGroup)+' not configured! Run GSConfig.');
           MoveToBadPath;
         END;
       END
       ELSE
       BEGIN
         WriteLogFile('  ! Area '+TicFile.AreaTag+' not found.');
         WriteLogFile('  ! Link '+AddressToString(LinksInfo.NetworkAddress)+' does not have auto-create access.');
         MoveToBadPath;
       END;
     END
     ELSE
     BEGIN
       GotIt := False;
       ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
       {$I-}RESET(FEchoTag);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FEchoTag,EchoTag);
           IF EchoTag.AreaID=FileArea.AreaID THEN
           BEGIN
             IF AkasMatch(EchoTag.Aka,TicFile.AkaFrom) THEN
             BEGIN
               GotIt := True;
             END;
           END;
         UNTIL ((EOF(FEchoTag)) OR (GotIt));
         CLOSE(FEchoTag);
       END;
       IF NOT(FileArea.PassThrough) THEN _CreatePath(FileArea.area_path);
       IF NOT(GotIt) THEN
       BEGIN
         WriteLogFile('  ! Link '+AddressToString(TicFile.AkaFrom)+' not connected to area: '+FileArea.Area_Tag+'.');
         MoveToBadPath;
       END;
     END;
     LoadTheArea := GotIt;
END;


FUNCTION LoadTheTic: Boolean;
VAR  TFile   : Text;
     Temp    : String;
     Temp2   : String;
     Okey    : Boolean;
     FSize   : Longint;
     Loop    : Word;
BEGIN
     Okey := True;
     FillChar(TicFile,SizeOf(TicFile),0);
     TicFile.OneDescription := 'No description';
     ASSIGN(TFile,Mailer.Inbound+CurrentTicFile);
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READLN(TFile,Temp);
         Temp2 := _UpperCase(Temp);
         IF Pos('PW ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,3);
           TicFile.Password := _UpperCase(_Mid(Temp2,1,8));
         END
         ELSE IF Pos('AREA ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,5);
           TicFile.AreaTag := _UpperCase(_Mid(Temp2,1,12));
         END
         ELSE IF Pos('FROM ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,5);
           StringToAddress(_Mid(Temp2,1,20),TicFile.AkaFrom);
         END
         ELSE IF Pos('ORIGIN ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,7);
           StringToAddress(_Mid(Temp2,1,20),TicFile.Origin);
         END
         ELSE IF Pos('FILE ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,5);
           TicFile.FileName := _UpperCase(_Mid(Temp2,1,12));
         END
         ELSE IF Pos('CRC ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,4);
           TicFile.Crc := _UpperCase(_Mid(Temp2,1,8));
         END
         ELSE IF Pos('REPLACES ',Temp2)=1 THEN
         BEGIN
           Delete(Temp2,1,9);
           TicFile.Replaces := _UpperCase(_Mid(Temp2,1,12));
         END
         ELSE IF Pos('DESC ',Temp2)=1 THEN
         BEGIN
           IF TicFile.OneDescription='No description' THEN
           BEGIN
             Delete(Temp,1,5);
             TicFile.OneDescription := _RemoveLeftSpaces(Temp);
           END;
         END
         ELSE IF Pos('AREADESC ',Temp2)=1 THEN
         BEGIN
           Delete(Temp,1,9);
           TicFile.AreaDesc := _Mid(Temp,1,40);
         END
         ELSE IF Pos('LDESC ',Temp2)=1 THEN
         BEGIN
           Delete(Temp,1,6);
           IF (TicFile.LNumDesc<18) THEN
           BEGIN
             INC(TicFile.LNumDesc);
             TicFile.LDescription[TicFile.LNumDesc] := _Mid(Temp,1,45);
           END;
         END;
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END
     ELSE Okey := False;
     OriginalArcName := TicFile.FileName;
     {Check and make sure we have all we need}
     IF TicFile.FileName='' THEN Okey := False;
     IF TicFile.AreaTag='' THEN Okey := False;
     IF TicFile.AkaFrom.Zone=0 THEN
     BEGIN
       IF TicFile.AkaFrom.Net=0 THEN
       BEGIN
         IF TicFile.AkaFrom.Node=0 THEN
         BEGIN
           IF TicFile.AkaFrom.Point=0 THEN
           BEGIN
             Okey := False;
           END;
         END;
       END;
     END;
     IF TicFile.Crc='' THEN Okey := False;
     FSize := _FileSize(Mailer.Inbound+TicFile.FileName);
     INC(RunningInFiles);
     INC(RunningInbound,FSize);
     WriteLogFile('Process TIC.....: '+CurrentTicFile);
     IF Okey THEN
     BEGIN
       MakeWrappedDesc;
       IF NumWrappedDesc=0 THEN
       BEGIN
         WrappedDesc[1] := 'No description';
         NumWrappedDesc := 1;
       END;
       WriteLogFile(' Ã Aka From.....: '+AddressToString(TicFile.AkaFrom));
       WriteLogFile(' Ã File Echo....: '+TicFile.AreaTag);
       WriteLogFile(' Ã File Name....: '+TicFile.FileName);
       WriteLogFile(' Ã File Size....: '+_String(FSize)+' bytes');
       WriteLogFile(' Ã File Crc.....: '+TicFile.Crc);
       IF (TicFile.Replaces<>'') THEN WriteLogFile(' Ã Replaces.....: '+TicFile.Replaces);
       IF (TicFile.LNumDesc<>0) THEN
       BEGIN
         FOR Loop := 1 TO TicFile.LNumDesc DO
         BEGIN
           IF Loop=1
             THEN WriteLogFile(' À Description..: '+TicFile.LDescription[1])
             ELSE WriteLogFile('                : '+TicFile.LDescription[Loop]);
         END;
       END
       ELSE
       BEGIN
         FOR Loop := 1 TO NumWrappedDesc DO
         BEGIN
           IF Loop=1
             THEN WriteLogFile(' À Description..: '+WrappedDesc[1])
             ELSE WriteLogFile('                : '+WrappedDesc[Loop]);
         END;
       END;
     END
     ELSE
     BEGIN
       WriteLogFile('  ! The TIC file is missing some information!');
       MoveToBadPath;
     END;
     LoadTheTic := Okey;
END;


PROCEDURE CopyToWork;
BEGIN
     _CreatePath(BaseDirectory+'\!20');
     FastWrite('Copy To Work',9,40,15);
     IF NOT(_BigCopyFile(TicFile.FileName,Mailer.Inbound,BaseDirectory+'\!20')) THEN
     BEGIN
       WriteLogFile('  ! Can''t copy '+TicFile.FileName+' to work directory. Disk full?');
       TossIsGood := False;
     END;
     FastWrite('Copy To Work',9,40,7);
     IF TossIsGood THEN FastWrite('û',9,37,14)
                   ELSE FastWrite('í',9,37,14);
END;


PROCEDURE DearcArchive;
VAR   CommandLine : String;
      PPointer    : Word;
LABEL SkipIt;
BEGIN
     DidADeArc := False;
     FastWrite('Dearc Archive',10,40,15);
     IF ((NOT(DoConverting)) OR (NOT(FileArea.TicConvertArcs))) THEN
     BEGIN
       ChDir(BaseDirectory);
       FastWrite('Dearc Archive',10,40,7);
       FastWrite('û',10,37,14);
       Exit;
     END;
     ChDir(BaseDirectory+'\!20');
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     RESET(FArcUtils);
     REPEAT
       READ(FArcUtils,ArcUtils);
       IF _GetFileExtension(TicFile.FileName)=ArcUtils.Extension THEN
       BEGIN
         CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+TicFile.FileName+' *.* >NUL';
         PPointer := DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwapMethod,BaseDirectory+'\!21');
         IF PPointer=0 THEN PPointer := DosExitCode;
         IF (PPointer<>0) THEN
         BEGIN
           WriteLogFile('  ! Packer ('+ArcUtils.Extension+') reported #'+_String(PPointer)+
                        ' on '+TicFile.FileName+'. Archive incomplete or bad.');
           TossIsGood := False;
         END;
         DidADeArc := True;
         GOTO SkipIt;
       END;
     UNTIL EOF(FArcUtils);
     SkipIt:
     CLOSE(FArcUtils);
     ChDir(BaseDirectory);
     FastWrite('Dearc Archive',10,40,7);
     IF TossIsGood THEN FastWrite('û',10,37,14)
                   ELSE FastWrite('í',10,37,14);
END;


PROCEDURE VirusCheck;
VAR  Loop        : Word;
     CommandLine : String;
     PPointer    : Word;
     ReportedCrc : String[8];
BEGIN
     FastWrite('Virus Check',11,40,15);
     IF DoCrcChecking THEN
     BEGIN
       ReportedCrc := FileCrc32(Mailer.Inbound+TicFile.FileName);
       IF (TicFile.Crc<>ReportedCrc) THEN
       BEGIN
         WriteLogFile('  ! Crc check on '+TicFile.FileName+' failed. Expected: '+TicFile.Crc+'  Actual: '+ReportedCrc);
         MoveToBadPath;
         TossIsGood := False;
       END;
     END;
     IF ScanForViruses THEN
     BEGIN
       FOR Loop:=1 TO 5 DO
       BEGIN
         IF Scanners.CommandLine[Loop]<>'' THEN
         BEGIN
           SaveScreen;
           FastW1.GotoXY(1,1);
           ChDir(BaseDirectory+'\!20');
           CommandLine := Scanners.Path[Loop]+Scanners.CommandLine[Loop]+' *.*';
           PPointer := DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwapMethod,BaseDirectory+'\!21');
           IF PPointer=0 THEN PPointer := DosExitCode;
           ChDir(BaseDirectory);
           RestoreScreen;
           IF (PPointer=Scanners.VirusExists[Loop]) THEN
           BEGIN
             WriteLogFile('  ! Scanner reported #'+_String(PPointer)+' on '+TicFile.FileName+'. Archive infected!');
             MoveToBadPath;
             TossIsGood := False;
           END;
         END;
       END;
     END;
     FastWrite('Virus Check',11,40,7);
     IF TossIsGood THEN FastWrite('û',11,37,14)
                   ELSE FastWrite('í',11,37,14);
END;


PROCEDURE ExtFILE_IDDIZ;
VAR  TFile    : Text;
     Temp     : String;
     FoundOne : Boolean;
BEGIN
     FoundOne := False;
     FastWrite('Ext FILE_ID.DIZ',12,40,15);
     IF _FileExists(BaseDirectory+'\!20\FILE_ID.DIZ') THEN
     BEGIN
       TicFile.LNumDesc := 0;
       ASSIGN(TFile,BaseDirectory+'\!20\FILE_ID.DIZ');
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         IF (TicFile.LNumDesc<18) THEN
         BEGIN
           INC(TicFile.LNumDesc);
           TicFile.LDescription[TicFile.LNumDesc] := _Mid(Temp,1,45);
         END;
       UNTIL EOF(TFile);
       CLOSE(TFile);
       FoundOne := True;
     END
     ELSE
     BEGIN
       IF _FileExists(BaseDirectory+'\!20\DESC.SDI') THEN
       BEGIN
         TicFile.LNumDesc := 0;
         ASSIGN(TFile,BaseDirectory+'\!20\DESC.SDI');
         RESET(TFile);
         REPEAT
           READLN(TFile,Temp);
           IF (TicFile.LNumDesc<18) THEN
           BEGIN
             INC(TicFile.LNumDesc);
             TicFile.LDescription[TicFile.LNumDesc] := _Mid(Temp,1,45);
           END;
         UNTIL EOF(TFile);
         CLOSE(TFile);
         FoundOne := True;
       END;
     END;
     FastWrite('Ext FILE_ID.DIZ',12,40,7);
     IF FoundOne THEN FastWrite('û',12,37,14)
                 ELSE FastWrite('í',12,37,14);
END;


PROCEDURE RearcArchive;
VAR  CommandLine : String;
     PPointer    : Word;
     GotIt       : Boolean;
BEGIN
     FastWrite('Rearc Archive',13,40,15);
     IF DidADeArc THEN
     BEGIN
       _EraseFile(BaseDirectory+'\!20\'+TicFile.FileName);
       ChDir(BaseDirectory+'\!20');
       GotIt := False;
       ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
       RESET(FArcUtils);
       REPEAT
         READ(FArcUtils,ArcUtils);
         IF FileArea.TicDestFormat=ArcUtils.Extension THEN GotIt := True;
       UNTIL ((EOF(FArcUtils)) OR (GotIt));
       CLOSE(FArcUtils);
       IF GotIt THEN
       BEGIN
         CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+_NoExtension(TicFile.FileName)+'.'+ArcUtils.Extension+' *.* >NUL';
         PPointer := DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwapMethod,BaseDirectory+'\!21');
         IF PPointer=0 THEN PPointer := DosExitCode;
         TicFile.FileName := _NoExtension(TicFile.FileName)+'.'+ArcUtils.Extension;
       END;
       ChDir(BaseDirectory);
     END;
     FastWrite('Rearc Archive',13,40,7);
     FastWrite('û',13,37,14);
END;


PROCEDURE CleanUp;
BEGIN
     _NukeDir(BaseDirectory+'\!20',False);
END;


PROCEDURE EraseFromArea(FName: String);
VAR  Loop    : Word;
     Locator : Longint;
     FoundIt : Boolean;
BEGIN
     IF _FileExists(FileArea.Dos_Name+'.FIL') THEN
     BEGIN
       ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
       RENAME(FFileDefs,FileArea.Dos_Name+'.FI$');
       ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
       RENAME(FFileDesc,FileArea.Dos_Name+'.TX$');
       Locator := 1;
       FoundIt := False;
       ASSIGN(FFileDefs2,FileArea.Dos_Name+'.FI$');
       ASSIGN(FFileDesc2,FileArea.Dos_Name+'.TX$');
       ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
       ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
       REWRITE(FFileDefs);
       REWRITE(FFileDesc);
       RESET(FFileDefs2);
       RESET(FFileDesc2);
       REPEAT
         READ(FFileDefs2,FileDefs2);
         IF (FileDefs2.File_Name<>FName) THEN
         BEGIN
           {$I-}SEEK(FFileDesc2,FileDefs2.First_Desc-1);{$I+}
           IF IOResult=0 THEN
           BEGIN
             IF NOT(EOF(FFileDesc2)) THEN
             BEGIN
               FOR Loop := 1 TO FileDefs2.Desc_Lines DO
               BEGIN
                 FileDesc.Desc := '';
                 IF NOT(EOF(FFileDesc2)) THEN READ(FFileDesc2,FileDesc);
                 WRITE(FFileDesc,FileDesc);
               END;
               FileDefs2.First_Desc := Locator;
               WRITE(FFileDefs,FileDefs2);
               INC(Locator,FileDefs2.Desc_Lines);
             END;
           END;
         END
         ELSE FoundIt := True;
       UNTIL EOF(FFileDefs2);
       CLOSE(FFileDefs2);
       CLOSE(FFileDesc2);
       CLOSE(FFileDefs);
       CLOSE(FFileDesc);
       ERASE(FFileDefs2);
       ERASE(FFileDesc2);
       IF _FileSize(FileArea.Dos_Name+'.FIL')=0 THEN ERASE(FFileDefs);
       IF _FileSize(FileArea.Dos_Name+'.TXT')=0 THEN ERASE(FFileDesc);
       IF FoundIt THEN
       BEGIN
         WriteLogFile('  > Deleting file: '+FName+' from database and hard drive.');
         _EraseFile(FileArea.Area_Path+FName);
       END;
     END;
END;


PROCEDURE AddToDatabase;
VAR  Loop      : Word;
     DirInfo   : SearchRec;
     TheId     : Word;
     GotIt     : Boolean;
     Crap      : Longint;
     TFile     : Text;
BEGIN
     FastWrite('Add To Database',14,40,15);
     {LOAD THE FILE RECORD}
     FillChar(FileDefs,SizeOf(FileDefs),0);
     FileDefs.File_Name  := TicFile.FileName;
     FileDefs.File_Size  := _FileSize(BaseDirectory+'\!20\'+TicFile.FileName);
     FileDefs.File_Date  := _FileDate(BaseDirectory+'\!20\'+TicFile.FileName);
     NewFileCrc          := FileCrc32(BaseDirectory+'\!20\'+TicFile.FileName);
     FileDefs.Uploader   := OurAppName;
     FileDefs.Added_Date := _ProperDate;
     IF NOT(FileArea.PassThrough) THEN
     BEGIN
       INC(RunningStored,FileDefs.File_Size);
       {ADD TO THE REPORTS}
       IF (FileArea.TicReportNumber<>0) THEN
       BEGIN
         ASSIGN(TFile,BaseDirectory+'\!21\'+_String(FileArea.AreaID)+'.RPT');
         {$I-}APPEND(TFile);{$I+}
         IF (IOResult<>0) THEN REWRITE(TFile);
         WRITELN(TFile,#1+_String(FileDefs.File_Size));
         IF (TicFile.LNumDesc<>0) THEN
         BEGIN
           WRITELN(TFile,_PadRight(FileDefs.File_Name,12)+
                         _PadLeft(_String(FileDefs.File_Size),9)+'  '+
                         TicFile.LDescription[1]);
           FOR Loop := 2 TO TicFile.LNumDesc DO WRITELN(TFile,'                       '+TicFile.LDescription[Loop]);
         END
         ELSE
         BEGIN
           WRITELN(TFile,_PadRight(FileDefs.File_Name,12)+
                         _PadLeft(_String(FileDefs.File_Size),9)+'  '+
                         WrappedDesc[1]);
           FOR Loop := 2 TO NumWrappedDesc DO WRITELN(TFile,'                       '+WrappedDesc[Loop]);
         END;
         CLOSE(TFile);
       END;
       {ERASE IT IF IT ALREADY EXISTS}
       EraseFromArea(TicFile.FileName);
       {GOT A REPLACES. DO IT!}
       IF (TicFile.Replaces<>'') THEN
       BEGIN
         FindFirst(FileArea.Area_Path+TicFile.Replaces,Anyfile-Directory-VolumeID,DirInfo);
         WHILE DosError=0 DO
         BEGIN
            EraseFromArea(DirInfo.Name);
            FindNext(DirInfo);
         END;
       END;
       WriteLogFile('  $ Adding file: '+TicFile.FileName+' to the database.');
       {WRITE TO THE DATABASE}
       ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
       ASSIGN(FFileDesc,FileArea.Dos_Name+'.TXT');
       {$I-}RESET(FFileDefs);{$I+}
       IF IOResult<>0 THEN REWRITE(FFileDefs);
       {$I-}RESET(FFileDesc);{$I+}
       IF IOResult<>0 THEN REWRITE(FFileDesc);
       FileDefs.First_Desc := FileSize(FFileDesc)+1;
       SEEK(FFileDefs,FileSize(FFileDefs));
       SEEK(FFileDesc,FileSize(FFileDesc));
       IF (TicFile.LNumDesc<>0) THEN
       BEGIN
         FileDefs.Desc_Lines := TicFile.LNumDesc;
         FOR Loop := 1 TO FileDefs.Desc_Lines DO
         BEGIN
           FileDesc.Desc := TicFile.LDescription[Loop];
           WRITE(FFileDesc,FileDesc);
         END;
       END
       ELSE
       BEGIN
         FileDefs.Desc_Lines := NumWrappedDesc;
         FOR Loop := 1 TO FileDefs.Desc_Lines DO
         BEGIN
           FileDesc.Desc := WrappedDesc[Loop];
           WRITE(FFileDesc,FileDesc);
         END;
       END;
       WRITE(FFileDefs,FileDefs);
       CLOSE(FFileDefs);
       CLOSE(FFileDesc);
       {RECALCULATE FILES & BYTES OF AREA}
       TheId := FileArea.AreaId;
       FileArea.Num_Files := 0;
       FileArea.Num_Bytes := 0;
       IF _FileExists(FileArea.Dos_Name+'.FIL') THEN
       BEGIN
         ASSIGN(FFileDefs,FileArea.Dos_Name+'.FIL');
         RESET(FFileDefs);
         REPEAT
           READ(FFileDefs,FileDefs2);
           INC(FileArea.Num_Files);
           INC(FileArea.Num_Bytes,FileDefs2.File_Size);
         UNTIL EOF(FFileDefs);
         CLOSE(FFileDefs);
         GotIt := False;
         Crap  := 0;
         ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
         RESET(FFileArea);
         REPEAT
           READ(FFileArea,FileArea2);
           INC(Crap);
           IF FileArea2.AreaId=TheID THEN
           BEGIN
             SEEK(FFileArea,Crap-1);
             WRITE(FFileArea,FileArea);
             GotIt := True;
           END;
         UNTIL ((EOF(FFileArea)) OR (GotIt));
         CLOSE(FFileArea);
         GotIt := False;
         Crap  := 0;
         ASSIGN(FFileArea,BaseDirectory+'\DATA\FA'+ZeroPadded(FileArea.Sub)+'.DAT');
         RESET(FFileArea);
         REPEAT
           READ(FFileArea,FileArea2);
           INC(Crap);
           IF FileArea2.AreaId=TheID THEN
           BEGIN
             SEEK(FFileArea,Crap-1);
             WRITE(FFileArea,FileArea);
             GotIt := True;
           END;
         UNTIL ((EOF(FFileArea)) OR (GotIt));
         CLOSE(FFileArea);
       END;
       {SORT THE AREA}
       SortTheFileArea(FileArea.Dos_Name,FileArea.Sort);
       {COPY THE FILE INTO THE DIRECTORY}
       _BigCopyFile(TicFile.FileName,BaseDirectory+'\!20',FileArea.Area_Path);
     END
     ELSE
     BEGIN
       {COPY THE FILE INTO THE PASSTHROUGH}
       _CreatePath(BaseDirectory+'\GSFILEP');
       _BigCopyFile(TicFile.FileName,BaseDirectory+'\!20',BaseDirectory+'\GSFILEP');
     END;
     {PACK FOR OTHER NODES}
     PackOutboundTics;
     FastWrite('Add To Database',14,40,7);
     FastWrite('û',14,37,14);
END;


PROCEDURE WriteNodeFile;
VAR  FNode     : File Of _NodeFile_Record;
     Node      : _NodeFile_Record;
BEGIN
     FillChar(Node,SizeOf(Node),0);
     Node.User     := 'GSFile';
     Node.Activity := 'Importing Network File Echoes (TIC)';
     Node.Node     := NodeNumber;
     ASSIGN(FNode,BaseDirectory+'\INTRNODE\NODE'+_String(NodeNumber)+'.$$$');
     {$I-}RESET(FNode);{$I+}
     IF IOResult<>0 THEN REWRITE(FNode);
     WRITE(FNode,Node);
     CLOSE(FNode);
END;


FUNCTION GetNetAddress(Num: Word): Boolean;
BEGIN
     ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetworkInfo)>=Num THEN
          BEGIN
               SEEK(FNetworkInfo,Num-1);
               READ(FNetworkInfo,NetworkInfo);
               GetNetAddress := True;
          END
          ELSE GetNetAddress := False;
          CLOSE(FNetworkInfo);
     END
     ELSE GetNetAddress :=  False;
END;


FUNCTION GetNetOrigin(Num: Word): String;
BEGIN
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     {$I-}RESET(FNetOrigins);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetOrigins)>=Num THEN
          BEGIN
               SEEK(FNetOrigins,Num-1);
               READ(FNetOrigins,NetOrigins);
               GetNetOrigin := NetOrigins.Net_Origin;
          END
          ELSE GetNetOrigin := '';
          CLOSE(FNetOrigins);
     END
     ELSE GetNetOrigin := '';
END;


FUNCTION PathTime: String;
CONST Days   : Array[0..6] Of String[3] = ('Sun','Mon','Tue','Wed','Thr','Fri','Sat');
CONST Months : Array[1..12] Of String[3] = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
     Temp         : String;

     FUNCTION PadIt(InWord: Word): String;
     VAR  Crap : String;
     BEGIN
          Crap := _String(InWord);
          IF LENGTH(Crap)=1 THEN Crap := '0'+Crap;
          PadIt := Crap;
     END;

BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     Temp := ' '+_String(DTToUnixDate(DT))+' '+Days[dow]+' '+Months[mm]+' '+PadIt(dd)+' ';
     Temp := Temp+PadIt(h)+':'+PadIt(m)+':'+PadIt(s)+' '+_String(yy)+' UTC'+SystemInfo.UTCSetting;
     PathTime := Temp;
END;


PROCEDURE PackOutboundTics;
VAR  EchoTag      : _GSFileDat_Record;
     EchoTag2     : _GSFileDat_Record;
     FPackEchoTag : File Of _GSFileDat_Record;
     FEchoTag     : File Of _GSFileDat_Record;
     Temp         : String;
     TFile        : Text;
     TFile2       : Text;
     WorkAka      : AddrType;
     DestNodes    : Word;
     NewCrc       : String[8];
     OutTic       : String;
     Loop         : Word;

     PROCEDURE AddSeenBy(TheAddr: AddrType);
     BEGIN
          ASSIGN(FPackEchoTag,BaseDirectory+'\!21\SBF.$$$');
          {$I-}RESET(FPackEchoTag);{$I+}
          IF IOResult=0 THEN SEEK(FPackEchoTag,FileSize(FPackEchoTag))
                        ELSE REWRITE(FPackEchoTag);
          EchoTag.Aka := TheAddr;
          EchoTag.AreaId := FileArea.AreaId;
          WRITE(FPackEchoTag,EchoTag);
          CLOSE(FPackEchoTag);
     END;

     FUNCTION AlreadyThere(TheAddr: AddrType): Boolean;
     BEGIN
          ASSIGN(FPackEchoTag,BaseDirectory+'\!21\SBF.$$$');
          {$I-}RESET(FPackEchoTag);{$I+}
          IF IOResult=0 THEN
          BEGIN
            REPEAT
              READ(FPackEchoTag,EchoTag2);
              IF AkasMatch(EchoTag2.Aka,TheAddr) THEN
              BEGIN
                AlreadyThere := True;
                CLOSE(FPackEchoTag);
                Exit;
              END;
            UNTIL EOF(FPackEchoTag);
            CLOSE(FPackEchoTag);
          END;
          AlreadyThere := False;
     END;

     PROCEDURE CollectSeenBys;
     BEGIN
          ASSIGN(TFile,Mailer.Inbound+CurrentTicFile);
          RESET(TFile);
          REPEAT
            READLN(TFile,Temp);
            Temp := _UpperCase(Temp);
            IF Pos('SEENBY ',Temp)=1 THEN
            BEGIN
              Delete(Temp,1,7);
              StringToAddress(Temp,WorkAka);
              AddSeenBy(WorkAka);
            END;
          UNTIL EOF(TFile);
          CLOSE(TFile);
     END;

     PROCEDURE MakeSeenBys;
     BEGIN
       ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
       {$I-}RESET(FEchoTag);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FEchoTag,EchoTag);
           IF EchoTag.AreaId=FileArea.AreaID THEN
           BEGIN
             IF NOT(AlreadyThere(EchoTag.Aka)) THEN
             BEGIN
               IF NOT(AkasMatch(EchoTag.Aka,TicFile.AkaFrom)) THEN
               BEGIN
                 IF LoadTheLink(EchoTag.Aka,False) THEN
                 BEGIN
                   IF NOT(LinksInfo.Paused) THEN
                   BEGIN
                     AddSeenBy(EchoTag.Aka);
                     INC(DestNodes);
                   END;
                 END;
               END;
             END;
           END;
         UNTIL EOF(FEchoTag);
         CLOSE(FEchoTag);
       END;
     END;

BEGIN
     DestNodes := 0;
     CollectSeenBys;
     MakeSeenBys;
     IF DestNodes=0 THEN
     BEGIN
       _EraseFile(BaseDirectory+'\!21\SBF.$$$');
       Exit;
     END;
     IF FileArea.PassThrough
        THEN NewCrc := FileCrc32(BaseDirectory+'\GSFILEP\'+FileDefs.File_Name)
        ELSE NewCrc := FileCrc32(FileArea.Area_Path+FileDefs.File_Name);
     ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
     RESET(FEchoTag);
     REPEAT
       READ(FEchoTag,EchoTag);
       IF EchoTag.AreaId=FileArea.AreaID THEN
       BEGIN
         IF NOT(AkasMatch(EchoTag.Aka,TicFile.AkaFrom)) THEN
         BEGIN
           IF LoadTheLink(EchoTag.Aka,False) THEN
           BEGIN
             IF LinksInfo.Paused THEN
             BEGIN
               WriteLogFile('  * Node: '+AddressToString(LinksInfo.NetworkAddress)+
                            ' is currently paused. Skipping this file.');
             END
             ELSE
             BEGIN
               IF NOT(GetNetAddress(LinksInfo.AkaToUse)) THEN
               BEGIN
                 WriteLogFile('  ! The aka you defined for '+AddressToString(LinksInfo.NetworkAddress)+
                              ' ('+_String(LinksInfo.AkaToUse)+') does not exist! Run GSConfig.');
               END
               ELSE
               BEGIN
                 OutTic := GetNextFileName;
                 ASSIGN(TFile,OutTic);
                 REWRITE(TFile);
                 WRITELN(TFile,'Area '+FileArea.Area_Tag);
                 WRITELN(TFile,'Areadesc '+FileArea.Area_Name);
                 WRITELN(TFile,'Origin '+AddressToString(TicFile.Origin));
                 WRITELN(TFile,'From '+AddressToString(NetworkInfo.Net_Address));
                 WRITELN(TFile,'File '+FileDefs.File_Name);
                 WRITELN(TFile,'Desc '+TicFile.OneDescription);
                 IF (TicFile.LNumDesc<>0) THEN
                 BEGIN
                   FOR Loop := 1 TO TicFile.LNumDesc DO
                   BEGIN
                     WRITELN(TFile,'Ldesc '+TicFile.LDescription[Loop]);
                   END;
                 END;
                 WRITELN(TFile,'Crc '+NewCrc);
                 WRITELN(TFile,'Created by '+OurAppName+' '+GunshotCopyright);
                 ASSIGN(TFile2,Mailer.Inbound+CurrentTicFile);
                 RESET(TFile2);
                 REPEAT
                   READLN(TFile2,Temp);
                   IF Pos('PATH ',_UpperCase(Temp))=1 THEN WRITELN(TFile,Temp);
                 UNTIL EOF(TFile2);
                 CLOSE(TFile2);
                 WRITELN(TFile,'Path '+AddressToString(NetworkInfo.Net_Address)+PathTime);
                 ASSIGN(FPackEchoTag,BaseDirectory+'\!21\SBF.$$$');
                 RESET(FPackEchoTag);
                 REPEAT
                   READ(FPackEchoTag,EchoTag);
                   WRITELN(TFile,'Seenby '+AddressToString(EchoTag.Aka));
                 UNTIL EOF(FPackEchoTag);
                 CLOSE(FPackEchoTag);
                 WRITELN(TFile,'Pw '+LinksInfo.GSFileTIC);
                 CLOSE(TFile);
                 IF FileArea.PassThrough THEN
                 BEGIN
                   CreateAttachment(BaseDirectory+'\GSFILEP\'+FileDefs.File_Name,OutTic);
                   WriteLogFile('  > Added TIC for node '+AddressToString(LinksInfo.NetworkAddress)+
                                '  File: '+BaseDirectory+'\GSFILEP\'+FileDefs.File_Name);
                 END
                 ELSE
                 BEGIN
                   CreateAttachment(FileArea.Area_Path+FileDefs.File_Name,OutTic);
                   WriteLogFile('  > Added TIC for node '+AddressToString(LinksInfo.NetworkAddress)+
                                '  File: '+FileArea.Area_Path+FileDefs.File_Name);
                 END;
                 INC(RunningOutTics);
               END;
             END;
           END;
         END;
       END;
     UNTIL EOF(FEchoTag);
     CLOSE(FEchoTag);
     _EraseFile(BaseDirectory+'\!21\SBF.$$$');
END;


FUNCTION IsOurNode(InAddress: AddrType): Boolean;
BEGIN
     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     RESET(FNetworkInfo);
     REPEAT
           READ(FNetworkInfo,NetworkInfo);
           IF AkasMatch(NetworkInfo.Net_Address,InAddress) THEN
           BEGIN
                CLOSE(FNetworkInfo);
                IsOurNode := True;
                Exit;
           END;
     UNTIL EOF(FNetworkInfo);
     CLOSE(FNetworkInfo);
     IsOurNode := False;
END;


PROCEDURE MoveToBadPath;
VAR  Temp1 : String;
     Temp2 : String;
BEGIN
     Temp1 := _MoveFileSafe(OriginalArcName,Mailer.Inbound,SystemInfo.BadFiles);
     Temp2 := _MoveFileSafe(CurrentTicFile,Mailer.Inbound,SystemInfo.BadFiles);
     WriteLogFile('  ! Moving '+Temp1+' to '+SystemInfo.BadFiles);
     WriteLogFile('  ! Moving '+Temp2+' to '+SystemInfo.BadFiles);
END;


FUNCTION PurgeThisArea(InString: String): Boolean;
VAR  Work        : Byte;
     FGSFileKill : File Of _GSFileKill_Record;
     GSFileKill  : _GSFileKill_Record;
BEGIN
     InString := _UpperCase(InString);
     IF _FileExists(BaseDirectory+'\DATA\GSFPURGE.DAT') THEN
     BEGIN
       ASSIGN(FGSFileKill,BaseDirectory+'\DATA\GSFPURGE.DAT');
       RESET(FGSFileKill);
       REPEAT
         READ(FGSFileKill,GSFileKill);
         GSFileKill.AreaName := _UpperCase(GSFileKill.AreaName);
         IF Pos('*',GSFileKill.AreaName)=0 THEN
         BEGIN
           IF GSFileKill.AreaName=InString THEN
           BEGIN
             PurgeThisArea := True;
             CLOSE(FGSFileKill);
             Exit;
           END;
         END
         ELSE IF (GSFileKill.AreaName[1]<>'*') THEN
         BEGIN
           Work := Pos('*',GSFileKill.AreaName);
           DEC(Work);
           GSFileKill.AreaName := _Mid(GSFileKill.AreaName,1,Work);
           IF _Mid(InString,1,Work)=GSFileKill.AreaName THEN
           BEGIN
             PurgeThisArea := True;
             CLOSE(FGSFileKill);
             Exit;
           END;
         END
         ELSE IF (GSFileKill.AreaName[1]='*') THEN
         BEGIN
           PurgeThisArea := True;
           CLOSE(FGSFileKill);
           Exit;
         END;
       UNTIL EOF(FGSFileKill);
       CLOSE(FGSFileKill);
     END;
     PurgeThisArea := False;
END;


END.
