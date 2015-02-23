{$I DEFINES.INC}
UNIT DoAuto;


INTERFACE


USES Gunshot;


TYPE Auto_Record    = RECORD
     NodeDiff       : String[12];
     TargetList     : String[12];
     DiffFile       : Boolean;
     CopyTo         : String[80];
     KillDiff       : Boolean;
     KillOldList    : Boolean;
     END;
TYPE MassiveBuffer  = Array[1..32000] Of Char;
VAR  Buffer1        : ^MassiveBuffer;
     Buffer2        : ^MassiveBuffer;
     ProcessList    : String;
     ProcessDiff    : String;
     DiffFile       : Text;
     NodelistFile   : Text;
     TargetFile     : File;
     TargetFileName : String;
     WorkLine       : String;
     ChangedNodes   : Integer;
     AutoInbound    : String;
     AutoNodelist   : String;
     AutoProcess    : Array[1..10] of String;
     AutoRecord     : Array[1..500] Of Auto_Record;
     AutoRecordNum  : Word;
     AutoProcessNum : Word;
     ArcDefs        : _Archiver_Record;
     ArcUtils       : _Archiver_Utilities;
     FArcDefs       : File Of _Archiver_Record;
     FArcUtils      : File Of _Archiver_Utilities;
     BaseDirectory  : String;
     WorkDirectory  : String;
     MainWork       : Longint;
     MainLoop       : Longint;


PROCEDURE DoAutoApply;


IMPLEMENTATION


USES Crt,Dos,BsExec,BsString,BsFile;


FUNCTION LoadArchivers: Boolean;
VAR  Status : Boolean;
BEGIN
     Status := True;
     ASSIGN(FArcDefs,'\GUNSHOT\DATA\ARCHIVE.DAT');
     {$I-}RESET(FArcDefs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       READ(FArcDefs,ArcDefs);
       CLOSE(FArcDefs);
     END
     ELSE Status := False;
     IF NOT(_FileExists('\GUNSHOT\DATA\ARCUTILS.DAT')) THEN Status := False;
     LoadArchivers := Status;
END;


PROCEDURE GetTheLatestNodelist(RootName: String);
VAR  LastList : String[12];
     LastDate : Longint;
     DirInfo  : SearchRec;
BEGIN
     LastList := '';
     LastDate := 0;
     FindFirst(AutoNodelist+'\'+RootName+'.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       IF _IsNumeric(_GetFileExtension(DirInfo.Name)) THEN
       BEGIN
         IF DirInfo.Time>=LastDate THEN
         BEGIN
           LastDate := DirInfo.Time;
           LastList := DirInfo.Name;
         END;
       END;
       FindNext(DirInfo);
     END;
     IF (LastList<>'') THEN ProcessList := AutoNodelist+'\'+LastList
                       ELSE ProcessList := '';
END;


FUNCTION ApplyTheDiff(NDiff,NList: String): Boolean;
VAR  Ext   : String;
     Temp1 : String;
     Temp2 : String;
     Work  : Longint;
     Loop  : Longint;
BEGIN
     Ext := _GetFileExtension(NDiff);
     TargetFileName := _NoExtension(NList)+'.'+Ext;
     WRITE('Applying '+_NoPath(NDiff)+' to '+_NoPath(NList)+'... ');
     {Check To Make Sure Diff & List Match}
     Temp1 := '';
     Temp2 := '';
     ASSIGN(DiffFile,NDiff);
     RESET(DiffFile);
     READLN(DiffFile,Temp1);
     CLOSE(DiffFile);
     ASSIGN(NodelistFile,NList);
     RESET(NodeListFile);
     READLN(NodeListFile,Temp2);
     CLOSE(NodeListFile);
     IF (Temp1<>Temp2) THEN
     BEGIN
       WRITELN('Error!');
       ApplyTheDiff := False;
       Exit;
     END;
     New(Buffer1);
     New(Buffer2);
     ChangedNodes := 0;
     ASSIGN(DiffFile,NDiff);
     ASSIGN(NodelistFile,NList);
     ASSIGN(TargetFile,TargetFileName);
     SetTextBuf(DiffFile,Buffer1^);
     SetTextBuf(NodeListFile,Buffer2^);
     RESET(DiffFile);
     RESET(NodelistFile);
     REWRITE(TargetFile,1);
     REPEAT
       READLN(DiffFile,WorkLine);
       CASE WorkLine[1] OF
       'A': BEGIN
              Delete(WorkLine,1,1);
              Work := _Numeric(WorkLine);
              FOR Loop := 1 TO Work DO
              BEGIN
                INC(ChangedNodes);
                {$I-}
                READLN(DiffFile,WorkLine);
                WorkLine := WorkLine+#$0D+#$0A;
                BLOCKWRITE(TargetFile,WorkLine[1],LENGTH(WorkLine));
                {$I+}
                IF (IOResult<>0) THEN
                BEGIN
                  CLOSE(DiffFile);
                  CLOSE(NodelistFile);
                  CLOSE(TargetFile);
                  ERASE(TargetFile);
                  Dispose(Buffer1);
                  Dispose(Buffer2);
                  WRITELN('Error!');
                  ApplyTheDiff := False;
                  Exit;
                END;
              END;
            END;
       'C': BEGIN
              Delete(WorkLine,1,1);
              Work := _Numeric(WorkLine);
              FOR Loop := 1 TO Work DO
              BEGIN
                {$I-}
                READLN(NodeListFile,WorkLine);
                WorkLine := WorkLine+#$0D+#$0A;
                BLOCKWRITE(TargetFile,WorkLine[1],LENGTH(WorkLine));
                {$I+}
                IF (IOResult<>0) THEN
                BEGIN
                  CLOSE(DiffFile);
                  CLOSE(NodelistFile);
                  CLOSE(TargetFile);
                  ERASE(TargetFile);
                  Dispose(Buffer1);
                  Dispose(Buffer2);
                  WRITELN('Error!');
                  ApplyTheDiff := False;
                  Exit;
                END;
              END;
            END;
       'D': BEGIN
              Delete(WorkLine,1,1);
              Work := _Numeric(WorkLine);
              FOR Loop := 1 TO Work DO
              BEGIN
                DEC(ChangedNodes);
                {$I-}
                READLN(NodeListFile,WorkLine);
                {$I+}
                IF (IOResult<>0) THEN
                BEGIN
                  CLOSE(DiffFile);
                  CLOSE(NodelistFile);
                  CLOSE(TargetFile);
                  ERASE(TargetFile);
                  Dispose(Buffer1);
                  Dispose(Buffer2);
                  WRITELN('Error!');
                  ApplyTheDiff := False;
                  Exit;
                END;
              END;
            END;
       ';': ; {SKIP COMMENTS}
       END;
     UNTIL EOF(DiffFile);
     CLOSE(DiffFile);
     CLOSE(NodelistFile);
     CLOSE(TargetFile);
     Dispose(Buffer1);
     Dispose(Buffer2);
     WRITELN('Done!');
     WRITELN('Nodes added: ',ChangedNodes);
     ApplyTheDiff := True;
END;


PROCEDURE DoAutoApply;
VAR  TFile        : Text;
     Temp         : String;
     DirInfo      : SearchRec;
     DirInfo2     : SearchRec;
     Loop         : Word;
     AllDone      : Boolean;
     ArcExt       : String[3];
     CommandLine  : String;
     DidSomething : Boolean;
     OrigTemp     : String;
     Crap         : Word;
BEGIN
     BaseDirectory := _GetFilePath(ParamStr(0));
     DEC(BaseDirectory[0]);
     WorkDirectory := BaseDirectory+'\!99';
     AutoRecordNum := 0;
     AutoProcessNum := 0;
     ASSIGN(TFile,'DODIFF.CFG');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READLN(TFile,Temp);
         OrigTemp := _RemoveLeftSpaces(_UpperCase(Temp));
         Temp := _RemoveSpaces(_UpperCase(Temp));
         IF _Mid(Temp,1,8)='INBOUND=' THEN
         BEGIN
           Delete(Temp,1,8);
           AutoInbound := Temp;
           IF AutoInbound[LENGTH(AutoInbound)]='\' THEN DEC(AutoInbound[0]);
         END
         ELSE IF _Mid(Temp,1,9)='NODELIST=' THEN
         BEGIN
           Delete(Temp,1,9);
           AutoNodelist := Temp;
           IF AutoNodelist[LENGTH(AutoNodelist)]='\' THEN DEC(AutoNodelist[0]);
         END
         ELSE IF _Mid(Temp,1,10)='PROCESSOR=' THEN
         BEGIN
           Delete(OrigTemp,1,9);
           OrigTemp := _RemoveLeftSpaces(OrigTemp);
           IF OrigTemp[1]='=' THEN
           BEGIN
                Delete(OrigTemp,1,1);
                OrigTemp := _RemoveLeftSpaces(OrigTemp);
                INC(AutoProcessNum);
                AutoProcess[AutoProcessNum] := OrigTemp;
           END;
         END
         ELSE IF _Mid(Temp,1,9)='NODEDIFF=' THEN
         BEGIN
           Delete(Temp,1,9);
           INC(AutoRecordNum);
           FillChar(AutoRecord[AutoRecordNum],SizeOf(AutoRecord[AutoRecordNum]),0);
           AutoRecord[AutoRecordNum].NodeDiff := _NoPath(Temp);
           REPEAT
             IF NOT(EOF(TFile)) THEN
             BEGIN
               FillChar(Temp,SizeOf(Temp),0);
               READLN(TFile,Temp);
               Temp := _RemoveSpaces(_UpperCase(Temp));
               IF _Mid(Temp,1,9)='DIFFFILE=' THEN
               BEGIN
                 Delete(Temp,1,9);
                 IF Temp[1]='Y' THEN AutoRecord[AutoRecordNum].DiffFile := True;
               END
               ELSE IF _Mid(Temp,1,11)='TARGETLIST=' THEN
               BEGIN
                 Delete(Temp,1,11);
                 AutoRecord[AutoRecordNum].TargetList := _NoPath(Temp);
               END
               ELSE IF _Mid(Temp,1,7)='COPYTO=' THEN
               BEGIN
                 Delete(Temp,1,7);
                 AutoRecord[AutoRecordNum].CopyTo := _NoPath(Temp);
               END
               ELSE IF _Mid(Temp,1,9)='KILLDIFF=' THEN
               BEGIN
                 Delete(Temp,1,9);
                 IF Temp[1]='Y' THEN AutoRecord[AutoRecordNum].KillDiff := True;
               END
               ELSE IF _Mid(Temp,1,12)='KILLOLDLIST=' THEN
               BEGIN
                 Delete(Temp,1,12);
                 IF Temp[1]='Y' THEN AutoRecord[AutoRecordNum].KillOldList := True;
               END;
             END;
           UNTIL ((Temp='ENDDIFF') OR (EOF(TFile)));
         END;
       UNTIL EOF(TFile);
       CLOSE(TFile);
       {Create Any Paths We Need}
       _CreatePath(WorkDirectory);
       _CreatePath(AutoInbound);
       _CreatePath(AutoNodelist);
       DidSomething := False;
       {Process Diffs}
       IF ((AutoRecordNum<>0) AND (LoadArchivers)) THEN
       BEGIN
         FOR Loop := 1 TO AutoRecordNum DO
         BEGIN
           FindFirst(AutoInbound+'\'+AutoRecord[Loop].NodeDiff,Anyfile-Directory-VolumeID,DirInfo);
           WHILE DosError=0 DO
           BEGIN
             WRITELN('Found nodelist archive: '+DirInfo.Name);
             DidSomething := True;
             _CopyFile(DirInfo.Name,AutoInbound,WorkDirectory);
             ChDir(WorkDirectory);
             {DeArc The Archive If It Is One}
             ArcExt := _GetArcType(WorkDirectory+'\'+DirInfo.Name);
             IF (ArcExt<>'') THEN
             BEGIN
               AllDone := False;
               ASSIGN(FArcUtils,'\GUNSHOT\DATA\ARCUTILS.DAT');
               RESET(FArcUtils);
               REPEAT
                 READ(FArcUtils,ArcUtils);
                 IF ArcExt=ArcUtils.Extension THEN
                 BEGIN
                   WRITE('Extracting from archive: '+DirInfo.Name+'...');
                   CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArcNoPath+' '+WorkDirectory+'\'+DirInfo.Name+' *.* >NUL';
                   DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,USE_ALL,BaseDirectory);
                   _EraseFile(WorkDirectory+'\'+DirInfo.Name);
                   AllDone := True;
                   WRITELN;
                 END;
               UNTIL ((EOF(FArcUtils)) OR (AllDone));
               CLOSE(FArcUtils);
             END;
             ChDir(BaseDirectory);
             {Process Da Sucker}
             IF AutoRecord[Loop].DiffFile THEN
             BEGIN
               FindFirst(WorkDirectory+'\*.*',Anyfile-Directory-VolumeID,DirInfo2);
               IF DosError=0 THEN
               BEGIN
                 GetTheLatestNodelist(_NoExtension(AutoRecord[Loop].TargetList));
                 IF ApplyTheDiff(WorkDirectory+'\'+DirInfo2.Name,ProcessList) THEN
                 BEGIN
                   IF AutoRecord[Loop].KillOldList THEN _EraseFile(ProcessList);
                   _EraseFile(WorkDirectory+'\'+DirInfo2.Name);
                 END;
               END;
             END
             ELSE
             BEGIN
               IF (AutoRecord[Loop].CopyTo<>'') THEN
               BEGIN {If We Remame The File To A New One Do This}
                 FindFirst(WorkDirectory+'\*.*',Anyfile-Directory-VolumeID,DirInfo2);
                 IF DosError=0 THEN
                 BEGIN
                   _Copy(WorkDirectory+'\'+DirInfo2.Name,AutoRecord[Loop].CopyTo);
                   _EraseFile(WorkDirectory+'\'+DirInfo2.Name);
                 END;
               END
               ELSE {Otherwise We Simply Copy It Into The Nodelist Directory}
               BEGIN
                 FindFirst(WorkDirectory+'\*.*',Anyfile-Directory-VolumeID,DirInfo2);
                 IF DosError=0 THEN
                 BEGIN
                   _CopyFile(DirInfo2.Name,WorkDirectory,AutoNodelist);
                   _EraseFile(WorkDirectory+'\'+DirInfo2.Name);
                 END;
               END;
             END;
             {Kill The Inbound Diff If Required}
             IF AutoRecord[Loop].KillDiff THEN
             BEGIN
               _EraseFile(AutoInbound+'\'+DirInfo.Name);
             END;
             {Erase The Work Directory}
             FindFirst(WorkDirectory+'\*.*',Anyfile-Directory-VolumeID,DirInfo2);
             WHILE DosError=0 DO
             BEGIN
                  _EraseFile(WorkDirectory+'\'+DirInfo2.Name);
                  FindNext(DirInfo2);
             END;
             {Get The Next One}
             FindNext(DirInfo);
           END;
         END;
       END
       ELSE
       BEGIN
         IF (AutoRecordNum<>0) THEN
         BEGIN
           TextColor(12);
           WRITELN('  Archiver data files not found!');
           WRITELN;
           TextColor(7);
         END;
       END;
       {Process Lists}
       IF ((AutoProcessNum<>0) AND (DidSomething)) THEN
       BEGIN
         ClrScr;
         FOR Loop := 1 TO AutoProcessNum DO
         BEGIN
           Temp := _GetFilePath(AutoProcess[Loop]);
           DEC(Temp[0]);
           ChDir(Temp);
           _CreatePath(Temp);
           DoExec(GetEnv('COMSPEC'),' /C '+AutoProcess[Loop],USE_ALL,BaseDirectory);
           ChDir(BaseDirectory);
         END;
       END;
       {Remove Any Paths We Created}
       _NukeDir(WorkDirectory,False);
       IF DidSomething THEN WRITELN;
     END
     ELSE
     BEGIN
       TextColor(12);
       WRITELN('  DoDiff CFG File: DODIFF.CFG not found!');
       TextColor(7);
       WRITELN;
     END;
     WRITELN('Done!');
     Halt;
END;


END.