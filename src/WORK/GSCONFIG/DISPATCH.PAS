{$I DEFINES.INC}
UNIT Dispatch;


INTERFACE


PROCEDURE CompileMessageAreas(DoWhich: Byte; DisplayStatus: Boolean);
PROCEDURE ShutDown;
PROCEDURE MouseSpeed;


IMPLEMENTATION


USES Dos,CnfgVars,Defaults,BsMouse,Crt,BsAkas,IntrFace,Misc,Gunshot,
     BsFile,FMode,MkFFile,BsString,BsKeys,BsVideo;


PROCEDURE MouseSpeed;
BEGIN
     CheckFile('GSCONFIG.DAT');
     ASSIGN(FConfigSetup,BaseDirectory+'\DATA\GSCONFIG.DAT');
     RESET(FConfigSetup);
     READ(FConfigSetup,ConfigSetup);
     CLOSE(FConfigSetup);
     _SetPixelToMickey(ConfigSetup.Horizontal,ConfigSetup.Vertical);
END;


PROCEDURE KillOldFileAreas;
VAR  DirInfo  : SearchRec;
     FileName : String;
BEGIN
     FindFirst(BaseDirectory+'\DATA\FA0*.DAT',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          FileName := DirInfo.Name;
          IF (FileName<>'FA000000.DAT') THEN _EraseFile(BaseDirectory+'\DATA\'+FileName);
          FindNext(DirInfo);
     END;
END;


PROCEDURE KillOldMessageAreas;
VAR  DirInfo  : SearchRec;
     FileName : String;
BEGIN
     FindFirst(BaseDirectory+'\DATA\MA0*.DAT',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          FileName := DirInfo.Name;
          IF FileName<>'MA000000.DAT' THEN _EraseFile(BaseDirectory+'\DATA\'+FileName);
          FindNext(DirInfo);
     END;
END;


FUNCTION ZeroPadded(Number: Word): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := _String(Number);
     FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
     ZeroPadded := Temp;
END;


PROCEDURE PromptHole(TheThing: String);
BEGIN
     TextColor_BS(9); WRITE('   ');
     TextColor_BS(7); WRITE(TheThing);
     TextColor_BS(8); WRITE(' [ ]');
     GOTOXY(WhereX-2,WhereY);
END;


PROCEDURE DoAck;
BEGIN
     TextColor_BS(10);
     WRITELN('û');
END;


PROCEDURE CompileMessageAreas(DoWhich: Byte; DisplayStatus: Boolean);
VAR  LastSub   : Longint;
     FFile     : FFileObj;
     BytesRead : Word;
BEGIN
     FFile.Init(16384);
     CASE DoWhich OF
     1:   BEGIN
               KillOldFileAreas;
               KillOldMessageAreas;
          END;
     2:   KillOldFileAreas;
     3:   KillOldMessageAreas;
     END;
     IF DisplayStatus THEN PromptHole('Compiling message areas........');
     IF ((DoWhich=1) OR (DoWhich=3)) THEN
     BEGIN
          LastSub := 999999;
          CheckFile('MA000000.DAT');
          FFile.OpenFile(BaseDirectory+'\DATA\MA000000.DAT',SetFileMode);
          REPEAT
                FFile.BlkRead(MessageArea,SizeOf(MessageArea),BytesRead);
                IF (BytesRead<>0) THEN
                BEGIN
                     IF (MessageArea.Sub<>0) THEN
                     BEGIN
                          IF LastSub=999999 THEN
                          BEGIN
                               ASSIGN(FMessageArea2,BaseDirectory+'\DATA\MA'+ZeroPadded(MessageArea.Sub)+'.DAT');
                               REWRITE(FMessageArea2);
                               WRITE(FMessageArea2,MessageArea);
                               LastSub := MessageArea.Sub;
                          END
                          ELSE
                          BEGIN
                               IF (LastSub<>MessageArea.Sub) THEN
                               BEGIN
                                    CLOSE(FMessageArea2);
                                    LastSub := MessageArea.Sub;
                                    ASSIGN(FMessageArea2,BaseDirectory+'\DATA\MA'+ZeroPadded(MessageArea.Sub)+'.DAT');
                                    {$I-}RESET(FMessageArea2);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         SEEK(FMessageArea2,FileSize(FMessageArea2));
                                         WRITE(FMessageArea2,MessageArea);
                                    END
                                    ELSE
                                    BEGIN
                                         REWRITE(FMessageArea2);
                                         WRITE(FMessageArea2,MessageArea);
                                    END;
                               END
                               ELSE WRITE(FMessageArea2,MessageArea);
                          END;
                     END;
                END;
          UNTIL BytesRead=0;
          FFile.CloseFile;
          IF (LastSub<>999999) THEN CLOSE(FMessageArea2);
     END;
     IF DisplayStatus THEN DoAck;
     IF DisplayStatus THEN PromptHole('Compiling file areas...........');
     IF ((DoWhich=1) OR (DoWhich=2)) THEN
     BEGIN
          LastSub := 999999;
          CheckFile('FA000000.DAT');
          FFile.OpenFile(BaseDirectory+'\DATA\FA000000.DAT',SetFileMode);
          REPEAT
                FFile.BlkRead(FileArea,SizeOf(FileArea),BytesRead);
                IF (BytesRead<>0) THEN
                BEGIN
                     IF (FileArea.Sub<>0) THEN
                     BEGIN
                          IF LastSub=999999 THEN
                          BEGIN
                               ASSIGN(FFileArea2,BaseDirectory+'\DATA\FA'+ZeroPadded(FileArea.Sub)+'.DAT');
                               REWRITE(FFileArea2);
                               WRITE(FFileArea2,FileArea);
                               LastSub := FileArea.Sub;
                          END
                          ELSE
                          BEGIN
                               IF (LastSub<>FileArea.Sub) THEN
                               BEGIN
                                    CLOSE(FFileArea2);
                                    LastSub := FileArea.Sub;
                                    ASSIGN(FFileArea2,BaseDirectory+'\DATA\FA'+ZeroPadded(FileArea.Sub)+'.DAT');
                                    {$I-}RESET(FFileArea2);{$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         SEEK(FFileArea2,FileSize(FFileArea2));
                                         WRITE(FFileArea2,FileArea);
                                    END
                                    ELSE
                                    BEGIN
                                         REWRITE(FFileArea2);
                                         WRITE(FFileArea2,FileArea);
                                    END;
                               END
                               ELSE WRITE(FFileArea2,FileArea);
                          END;
                     END;
                END;
          UNTIL BytesRead=0;
          FFile.CloseFile;
          IF (LastSub<>999999) THEN CLOSE(FFileArea2);
     END;
     IF DisplayStatus THEN DoAck;
     FFile.Done;
END;


PROCEDURE ClearTaggedEchos;
VAR  EchoTag    : _GSFileDat_Record;
     MEchoTag   : _GSEchoDat_Record;
     LastNode   : AddrType;
     FFLinks    : FFileObj;
     FEchoTag   : FFileObj;
     FEchoTag2  : FFileObj;
     FBytesRead : Word;
     BytesRead  : Word;

     FUNCTION GotThisNode: Boolean;
     BEGIN
          IF AkasMatch(EchoTag.Aka,LastNode) THEN
          BEGIN
               GotThisNode := True;
               Exit;
          END;
          FFLinks.SeekFile(0);
          REPEAT
                FFLinks.BlkRead(Links,SizeOf(Links),FBytesRead);
                IF ((FBytesRead<>0) AND (AkasMatch(Links.NetworkAddress,EchoTag.Aka))) THEN
                BEGIN
                     Move(Links.NetworkAddress,LastNode,SizeOf(LastNode));
                     GotThisNode := True;
                     Exit;
                END;
          UNTIL FBytesRead=0;
          GotThisNode := False;
     END;

     FUNCTION GotThisNode2: Boolean;
     BEGIN
          IF AkasMatch(MEchoTag.Aka,LastNode) THEN
          BEGIN
               GotThisNode2 := True;
               Exit;
          END;
          FFLinks.SeekFile(0);
          REPEAT
                FFLinks.BlkRead(Links,SizeOf(Links),FBytesRead);
                IF ((FBytesRead<>0) AND (AkasMatch(Links.NetworkAddress,MEchoTag.Aka))) THEN
                BEGIN
                     Move(Links.NetworkAddress,LastNode,SizeOf(LastNode));
                     GotThisNode2 := True;
                     Exit;
                END;
          UNTIL FBytesRead=0;
          GotThisNode2 := False;
     END;

BEGIN
     IF NOT(_FileExists(BaseDirectory+'\DATA\LINKS.DAT')) THEN
     BEGIN
          _EraseFile(BaseDirectory+'\DATA\GSFILE.DAT');
          _EraseFile(BaseDirectory+'\DATA\GSECHO.DAT');
          Exit;
     END;

     FFLinks.Init(16384);
     FEchoTag.Init(16384);
     FEchoTag2.Init(16384);
     FFLinks.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);

     {GSFile Echos}
     FillChar(LastNode,SizeOf(LastNode),0);
     PromptHole('Clearing GSFile links..........');
     IF _FileExists(BaseDirectory+'\DATA\GSFILE.DAT') THEN
     BEGIN
          _RenameFile(BaseDirectory+'\DATA\GSFILE.DAT',BaseDirectory+'\DATA\GSFILE.BAK');
          FEchoTag.OpenFile(BaseDirectory+'\DATA\GSFILE.DAT',SetFileMode);
          FEchoTag2.OpenFile(BaseDirectory+'\DATA\GSFILE.BAK',SetFileMode);
          REPEAT
                FEchoTag2.BlkRead(EchoTag,SizeOf(EchoTag),BytesRead);
                IF ((BytesRead<>0) AND (GotThisNode)) THEN
                BEGIN
                     FEchoTag.BlkWrite(EchoTag,SizeOf(EchoTag));
                END;
          UNTIL BytesRead=0;
          FEchoTag.CloseFile;
          FEchoTag2.CloseFile;
          _EraseFile(BaseDirectory+'\DATA\GSFILE.BAK');
          IF _FileSize(BaseDirectory+'\DATA\GSFILE.DAT')=0 THEN _EraseFile(BaseDirectory+'\DATA\GSFILE.DAT');
     END;
     DoAck;

     {GSEcho Echos}
     FillChar(LastNode,SizeOf(LastNode),0);
     PromptHole('Clearing GSEcho links..........');
     IF _FileExists(BaseDirectory+'\DATA\GSECHO.DAT') THEN
     BEGIN
          _RenameFile(BaseDirectory+'\DATA\GSECHO.DAT',BaseDirectory+'\DATA\GSECHO.BAK');
          FEchoTag.OpenFile(BaseDirectory+'\DATA\GSECHO.DAT',SetFileMode);
          FEchoTag2.OpenFile(BaseDirectory+'\DATA\GSECHO.BAK',SetFileMode);
          REPEAT
                FEchoTag2.BlkRead(MEchoTag,SizeOf(MEchoTag),BytesRead);
                IF ((BytesRead<>0) AND (GotThisNode2)) THEN
                BEGIN
                     FEchoTag.BlkWrite(MEchoTag,SizeOf(MEchoTag));
                END;
          UNTIL BytesRead=0;
          FEchoTag.CloseFile;
          FEchoTag2.CloseFile;
          _EraseFile(BaseDirectory+'\DATA\GSECHO.BAK');
          IF _FileSize(BaseDirectory+'\DATA\GSECHO.DAT')=0 THEN _EraseFile(BaseDirectory+'\DATA\GSECHO.DAT');
     END;
     DoAck;

     FFLinks.CloseFile;
     FFLinks.Done;
     FEchoTag.Done;
     FEchoTag2.Done;
END;


PROCEDURE ClearWorkDir;
VAR  DirInfo           : SearchRec;
     uploaded_file     : string;
     crap              : file;
BEGIN
     PromptHole('Cleaning work directory........');
     _NukeDir(WorkDir,False);
     DoAck;
END;


PROCEDURE ShutDown;
BEGIN
     _HideMouse;
     _ShowCursor;
     _HighBackGrounds(False);
     TextMode(OriginalMode);
     TextColor_BS(7);
     TextBackGround_BS(0);
     ClrScr;
     TextColor_BS(15);
     TextBackground_BS(1);
     ClrEol;
     WRITELN('  Shutdown In Progress...');
     TextBackground_BS(0);
     WRITELN;
     ClearWorkDir;
     CompileMessageAreas(1,True);
     ClearTaggedEchos;
     Dispose(Objects);
     Dispose(Buttons);
     Dispose(FileInfo);
     Dispose(FileInfo2);
     Dispose(CBVSetup);
     WriteLn;
     TextColor(14); WriteLn('Exit from GSCONFIG');
     TextColor(7);
     WriteLn;
     Halt;
END;


END.