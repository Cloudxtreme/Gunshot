{$M 64000,0,655360}
{$I DEFINES.INC}


USES Dos,Crt,FastW1,Shotgun,MkFFile,FMode,BsFile,BsExec,BsString,BsVideo,BsTime;


TYPE FileDescriptions2 = Array[1..18] Of _FileDescriptions;
VAR  SummaryFile       : FFileObj;
     TotalFiles        : Longint;
     TotalKiloBytes    : Longint;
     running_files     : Longint;
     running_bytes     : Longint;
     FileList          : FFileObj;
     loop              : word;
     count_lines       : word;
     list_number       : word;
     Temp              : string;
     AreaCounter       : Longint;
     HOLD_Directory    : String;
     BaseDirectory     : String;
     FFileArea         : FFileObj;
     FFileDesc         : FFileObj;
     FFileDefs         : FFileObj;
     FArcUtils         : File Of _Archiver_Utilities;
     FArcDefs          : File Of _Archiver_Record;
     ArcDefs           : _Archiver_Record;
     FileAreas         : _FileArea_Record;
     FileDefs          : _FileDefinitions;
     FileDesc          : FileDescriptions2;
     ArcUtils          : _Archiver_Utilities;
     SSize             : Longint;
     DoCDRoms          : Boolean;
     AccessLev         : Word;
     ArcFile           : String;
     GottaDoIt         : Boolean;
     TFile             : Text;
     BytesRead         : Word;
     FBytesRead        : Word;
     Crap              : Array[1..8192] Of Char;
     UseOneFile        : Boolean;
     Groups            : Array[1..100] Of Word;
     NumGroups         : Word;
     FoundIt           : Boolean;
     Worker            : Word;


PROCEDURE CompressTheThing;
VAR  GotIt       : Boolean;
     CommandLine : String;
BEGIN
     GotIt := False;
     ChDir(HOLD_Directory);
     ASSIGN(FArcUtils,BaseDirectory+'\DATA\ARCUTILS.DAT');
     RESET(FArcUtils);
     REPEAT
       READ(FArcUtils,ArcUtils);
       IF _GetFileExtension(ArcFile)=ArcUtils.Extension THEN GotIt := True;
     UNTIL ((EOF(FArcUtils)) OR (GotIt));
     CLOSE(FArcUtils);
     IF GotIt THEN
     BEGIN
       _EraseFile(ArcFile);
       CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+ArcFile+' *.* >NUL';
       DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,USE_ALL,BaseDirectory);
     END;
     ChDir(BaseDirectory);
END;


PROCEDURE GetCommandLine;
VAR   Work : Byte;
LABEL Help;
BEGIN
     DoCDRoms   := False;
     AccessLev  := 10;
     ArcFile    := '\ALLFILES.ZIP';
     UseOneFile := False;
     NumGroups  := 0;
     IF paramcount=0 THEN GOTO Help;
     FOR loop := 1 TO paramcount DO
     BEGIN
       Temp := _UpperCase(paramstr(loop));
       IF Temp='-DOCDROMS' THEN
       BEGIN
         DoCDRoms := True;
       END
       ELSE IF _Mid(Temp,1,7)='-ACCESS' THEN
       BEGIN
         Delete(Temp,1,7);
         AccessLev := _Numeric(Temp);
       END
       ELSE IF Temp='-ONEFILE' THEN
       BEGIN
         UseOneFile := True;
       END
       ELSE IF _Mid(Temp,1,2)='-F' THEN
       BEGIN
         Delete(Temp,1,2);
         ArcFile := Temp;
       END
       ELSE IF _Mid(Temp,1,2)='-G' THEN
       BEGIN
         Delete(Temp,1,2);
         REPEAT
           Work := Pos(',',Temp);
           IF (Work<>0) THEN
           BEGIN
             INC(NumGroups);
             Groups[NumGroups] := _Numeric(_Mid(Temp,1,Work-1));
             Delete(Temp,1,Work);
           END
           ELSE
           BEGIN
             INC(NumGroups);
             Groups[NumGroups] := _Numeric(Temp);
             Temp := '';
           END;
         UNTIL Temp='';
       END
       ELSE IF Temp='-?' THEN
       BEGIN
         Help:
         Window(1,1,80,25);
         GotoXY(1,7);
         TextColor(7);
         WriteLn('GSList Command Line Options:');
         WriteLn;
         WriteLn('      GSLIST.EXE <arg> <arg> ...');
         WriteLn;
         WriteLn('             -DOCDROMS        : Include CD Roms in the listing.');
         WriteLn('             -ONEFILE         : Create a single text file.');
         WriteLn('             -ACCESS<xxxxx>   : Maximum access level of areas to list.');
         WriteLn('             -F<filename.ext> : Destination archive (full path and filename!)');
         WriteLn('             -G<x1,x2,x3...>  : Groups to include in the list (comma seperated)');
         TextColor(7);
         Halt;
       END;
     END;
END;


PROCEDURE StartUp;
BEGIN
     AppHeader('GSList - Filelist Generator For Shotgun Professional');
     GetCommandLine;
     BaseDirectory := _UpperCase(_GetFilePath(ParamStr(0)));
     Dec(BaseDirectory[0]);
     ChDir(BaseDirectory);
     HOLD_Directory := BaseDirectory+'\!9';
     _CreatePath(HOLD_Directory);
     GotoXY(1,7);
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     {$I-}RESET(FArcDefs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       READ(FArcDefs,ArcDefs);
       CLOSE(FArcDefs);
     END;
END;


PROCEDURE WriteToList(InString: String);
BEGIN
     InString := InString+#13#10;
     FileList.BlkWrite(InString[1],LENGTH(InString));
END;


PROCEDURE WriteToSummary(InString: String);
BEGIN
     InString := InString+#13#10;
     SummaryFile.BlkWrite(InString[1],LENGTH(InString));
END;


BEGIN
     FileMode := SetFileMode;
     StartUp;
     count_lines    := 0;
     list_number    := 1;
     TotalFiles     := 0;
     TotalKiloBytes := 0;
     AreaCounter    := 0;
     SSize          := SizeOf(_FileDescriptions);
     STR(list_number,Temp);
     SummaryFile.Init(32768);
     FileList.Init(32768);
     FFileDefs.Init(32768);
     FFileDesc.Init(32768);
     FFileArea.Init(32768);
     SummaryFile.OpenFile(HOLD_Directory+'\SUMMARY.TXT',SetFileMode);
     IF UseOneFile
        THEN FileList.OpenFile(HOLD_Directory+'\FILES.LST',SetFileMode)
        ELSE FileList.OpenFile(HOLD_Directory+'\FILELIST.'+Temp,SetFileMode);
     WriteToSummary('ษออออออออออออออออออออออออัอออออออออออออออออออออออออออัออออออออออออออออออออออออป');
     WriteToSummary('บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ      LISTING SUMMARY      ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ');
     WriteToSummary('ฬออออออออออออออออออออออออฯอออออออออออออออออออออออออออฯออออออออออออออออออออออออน');
     WriteToSummary('บ ###   Area Name                                     Files          Bytes    บ');
     WriteToSummary('ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     IF _FileExists(BaseDirectory+'\DATA\FILELIST.TXT') THEN
     BEGIN
       ASSIGN(TFile,BaseDirectory+'\DATA\FILELIST.TXT');
       RESET(TFile);
       REPEAT
         READLN(TFile,Temp);
         WriteToList(Temp);
       UNTIL EOF(TFile);
       CLOSE(TFile);
     END;
     FFileArea.OpenFile(BaseDirectory+'\DATA\FA000000.DAT',SetFileMode);
     REPEAT
       FFileArea.BlkRead(FileAreas,SizeOf(FileAreas),FBytesRead);
       IF (FBytesRead<>0) THEN
       BEGIN
         INC(AreaCounter);
         FastWrite(_PadRight(FileAreas.Area_Name,40),7,1,7);
         GottaDoIt := True;
         IF ((NOT(DoCDRoms)) AND (FileAreas.CD_Rom<>0)) THEN GottaDoIt := False;
         IF (FileAreas.View_Access>AccessLev) THEN GottaDoIt := False;
         IF FileAreas.PassThrough THEN GottaDoIt := False;
         IF (NumGroups<>0) THEN
         BEGIN
           FoundIt := False;
           FOR Worker := 1 TO NumGroups DO
           BEGIN
             IF Groups[Worker]=FileAreas.Sub THEN FoundIt := True;
           END;
           IF NOT(FoundIt) THEN GottaDoIt := False;
         END;
         IF GottaDoIt THEN
         BEGIN
           IF _FileExists(fileareas.dos_name+'.FIL') THEN
           BEGIN
             Temp := 'บ  AREA: '+_PadRight(_String(AreaCounter)+' - '+fileareas.area_name,69)+'บ';
             WriteToList('ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
             WriteToList(Temp);
             WriteToList('ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
             IF NOT(UseOneFile) THEN count_lines := count_lines+4;
             running_files := 0;
             running_bytes := 0;
             FFileDefs.OpenFile(fileareas.dos_name+'.FIL',SetFileMode);
             FFileDesc.OpenFile(fileareas.dos_name+'.TXT',SetFileMode);
             REPEAT
               FFileDefs.BlkRead(FileDefs,SizeOf(FileDefs),BytesRead);
               IF (BytesRead<>0) THEN
               BEGIN
                 FFileDesc.BlkRead(FileDesc,FileDefs.Desc_Lines*SSize,BytesRead);
                 IF NOT(UseOneFile) THEN INC(count_lines);
                 Temp := _PadRight(FileDefs.file_name,13)+_PadLeft(_String(FileDefs.file_size),8)+
                         ' '+_UnpackedDate(FileDefs.file_date)+' '+FileDesc[1].Desc;
                 WriteToList(Temp);
                 INC(Running_files);
                 running_bytes := running_bytes+FileDefs.file_size;
                 INC(TotalFiles);
                 TotalKiloBytes := TotalKiloBytes+(FileDefs.file_size DIV 102400);
                 IF (FileDefs.Desc_Lines>1) THEN
                 BEGIN
                   FOR loop := 2 TO FileDefs.Desc_Lines DO
                   BEGIN
                     WriteToList('                                 '+FileDesc[Loop].Desc);
                     IF NOT(UseOneFile) THEN INC(count_lines);
                   END;
                 END;
               END;
             UNTIL BytesRead=0;
             FFileDefs.CloseFile;
             FFileDesc.CloseFile;
             WriteToList('ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
             WriteToList('   Total Files: '+_PadRight(_String(Running_Files),17)+'Total Bytes: '+_String(Running_Bytes));
             WriteToList('');
             WriteToList('');
             WriteToSummary('บ '+_PadRight(_String(AreaCounter),6)+_PadRight(fileareas.area_name,46)+
                            _PadLeft(_String(Running_Files),5)+_PadLeft(_String(Running_Bytes),16)+'   บ');
             IF ((NOT(UseOneFile)) AND (count_lines>3000)) THEN
             BEGIN
               count_lines := 0;
               INC(list_number);
               STR(list_number,Temp);
               FileList.CloseFile;
               FileList.OpenFile(HOLD_Directory+'\FILELIST.'+Temp,SetFileMode);
             END;
           END;
         END;
       END;
     UNTIL FBytesRead=0;
     WriteToSummary('ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     WriteToSummary('บ'+_PadBoth('TOTAL FILES:  '+_String(TotalFiles)+'            '+
                    'TOTAL MBYTES:  '+_String(Round(TotalKiloBytes/10)),77)+'บ');
     WriteToSummary('ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     WriteToSummary('บฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ'+_PadBoth('List Date: '+_GetPrettyDate,47)+'ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ');
     WriteToSummary('ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     FileList.CloseFile;
     FFileArea.CloseFile;
     SummaryFile.CloseFile;
     SummaryFile.OpenFile(HOLD_Directory+'\SUMMARY.TXT',SetFileMode);
     IF UseOneFile
        THEN FileList.OpenFile(HOLD_Directory+'\FILES.LST',SetFileMode)
        ELSE FileList.OpenFile(HOLD_Directory+'\FILELIST.'+_String(list_number),SetFileMode);
     FileList.SeekFile(FileList.RawSize);
     REPEAT
           SummaryFile.BlkRead(Crap,SizeOf(Crap),BytesRead);
           IF (BytesRead<>0) THEN FileList.BlkWrite(Crap,BytesRead);
     UNTIL BytesRead=0;
     FileList.CloseFile;
     SummaryFile.CloseFile;
     SummaryFile.Done;
     FileList.Done;
     FFileDefs.Done;
     FFileDesc.Done;
     FFileArea.Done;
     _EraseFile(HOLD_Directory+'\SUMMARY.TXT');
     FastWrite(_PadRight('Creating Archive File',40),7,1,7);
     CompressTheThing;
     _NukeDir(HOLD_Directory,False);
     FastWrite(_PadRight('All Done!',40),7,1,7);
     GotoXY(1,8);
END.
