{$M 32000,0,655360}
PROGRAM ShotgunDiffApplier;

{$I DEFINES.INC}

USES Dos,Crt,FastW1,Shotgun,Version,FMode,DoAuto,BsVideo,BsString,BsFile;


PROCEDURE StartUp;
BEGIN
     AppHeader('DoDiff - Shotgun Professional Nodediff Applier');
     ProcessDiff := _UpperCase(ParamStr(1));
     ProcessList := _UpperCase(ParamStr(2));
END;


PROCEDURE GetLatestNodelist;
VAR  LastList : String[12];
     LastDate : Longint;
     DirInfo  : SearchRec;
BEGIN
     LastList := '';
     LastDate := 0;
     FindFirst('NODELIST.*',Anyfile-Directory-VolumeID,DirInfo);
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
     ProcessList := LastList;
END;


PROCEDURE GetLatestNodediff;
VAR  LastList : String[12];
     LastDate : Longint;
     DirInfo  : SearchRec;
BEGIN
     LastList := '';
     LastDate := 0;
     FindFirst('NODEDIFF.*',Anyfile-Directory-VolumeID,DirInfo);
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
     ProcessDiff := LastList;
END;


PROCEDURE CheckForAMatch;
VAR  Temp1 : String;
     Temp2 : String;
BEGIN
     Temp1 := '';
     Temp2 := '';
     ASSIGN(DiffFile,ProcessDiff);
     RESET(DiffFile);
     READLN(DiffFile,Temp1);
     CLOSE(DiffFile);
     ASSIGN(NodelistFile,ProcessList);
     RESET(NodeListFile);
     READLN(NodeListFile,Temp2);
     CLOSE(NodeListFile);
     IF (Temp1<>Temp2) THEN
     BEGIN
       TextColor(12);
       WRITELN('  NodeDiff file is out of sequence with NodeList file!');
       WRITELN;
       TextColor(7);
       Halt;
     END;
END;


PROCEDURE GetTargetName;
VAR  Ext : String;
BEGIN
     Ext := _GetFileExtension(ProcessDiff);
     TargetFileName := _NoExtension(ProcessList)+'.'+Ext;
END;


PROCEDURE Abort;
BEGIN
     CLOSE(DiffFile);
     CLOSE(NodelistFile);
     CLOSE(TargetFile);
     ERASE(TargetFile);
     Dispose(Buffer1);
     Dispose(Buffer2);
     WRITELN('Error!');
     WRITELN;
     TextColor(12);
     WRITELN('  Error during nodediff application! Possible corrupt nodediff.');
     WRITELN;
     TextColor(7);
     Halt;
END;


BEGIN
     FileMode := SetFileMode;
     StartUp;
     IF ((ProcessDiff='-AUTO') OR (ProcessList='-AUTO')) THEN
     BEGIN
       DoAutoApply;
     END
     ELSE IF ((ProcessDiff='-FORCE') OR (ProcessList='-FORCE')) THEN
     BEGIN
       GetLatestNodelist;
       GetLatestNodediff;
     END
     ELSE
     BEGIN
       IF ((ProcessDiff='') OR (ProcessList='')) THEN
       BEGIN
         WRITELN;
         WRITELN('  Syntax:       DODIFF.EXE <nodediff.xxx> <nodelist.xxx>');
         WRITELN;
         WRITELN('                    <nodediff.xxx>     NodeDiff filename');
         WRITELN('                    <nodelist.xxx>     NodeList filename');
         WRITELN;
         WRITELN('      or:       DODIFF.EXE -FORCE');
         WRITELN;
         WRITELN('                    Forces compilation of the newest nodediff to the');
         WRITELN('                    newest nodelist file (in the current directory).');
         WRITELN;
         WRITELN('      or:       DODIFF.EXE -AUTO');
         WRITELN;
         WRITELN('                    Uses DODIFF.CFG to automatically apply new nodediffs,');
         WRITELN('                    as well as remove old nodelists and run your nodelist');
         WRITELN('                    compiler(s).');
         WRITELN;
         Halt;
       END;
     END;
     IF NOT(_FileExists(ProcessList)) THEN
     BEGIN
       TextColor(12);
       WRITELN('  NodeList file: '+ProcessList+' not found!');
       WRITELN;
       TextColor(7);
       Halt;
     END;
     IF NOT(_FileExists(ProcessDiff)) THEN
     BEGIN
       TextColor(12);
       WRITELN('  NodeDiff file: '+ProcessDiff+' not found!');
       WRITELN;
       TextColor(7);
       Halt;
     END;
     CheckForAMatch;
     GetTargetName;
     WRITE('Applying '+_NoPath(ProcessDiff)+' to '+_NoPath(ProcessList)+'... ');
     New(Buffer1);
     New(Buffer2);
     ChangedNodes := 0;
     ASSIGN(DiffFile,ProcessDiff);
     ASSIGN(NodelistFile,ProcessList);
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
              MainWork := _Numeric(WorkLine);
              FOR MainLoop := 1 TO MainWork DO
              BEGIN
                INC(ChangedNodes);
                {$I-}
                READLN(DiffFile,WorkLine);
                WorkLine := WorkLine+#$0D+#$0A;
                BLOCKWRITE(TargetFile,WorkLine[1],LENGTH(WorkLine));
                {$I+}
                IF (IOResult<>0) THEN Abort;
              END;
            END;
       'C': BEGIN
              Delete(WorkLine,1,1);
              MainWork := _Numeric(WorkLine);
              FOR MainLoop := 1 TO MainWork DO
              BEGIN
                {$I-}
                READLN(NodeListFile,WorkLine);
                WorkLine := WorkLine+#$0D+#$0A;
                BLOCKWRITE(TargetFile,WorkLine[1],LENGTH(WorkLine));
                {$I+}
                IF (IOResult<>0) THEN Abort;
              END;
            END;
       'D': BEGIN
              Delete(WorkLine,1,1);
              MainWork := _Numeric(WorkLine);
              FOR MainLoop := 1 TO MainWork DO
              BEGIN
                DEC(ChangedNodes);
                {$I-}
                READLN(NodeListFile,WorkLine);
                {$I+}
                IF (IOResult<>0) THEN Abort;
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
     WRITELN;
     WRITELN('Nodes added: ',ChangedNodes);
     WRITELN;
END.