{$I DEFINES.INC}
UNIT FileList;


INTERFACE


PROCEDURE generate_file_list;


IMPLEMENTATION


USES BsLog,KeyInput,Globals,MiscStr,Screens,Toggle,TagArea,CDS,
     GotKeys,Time,ApTimer,Execute,Download,ChangeFA,GetArc,ExtDos,
     Dates,BsFile,BsString,BsTime;


FUNCTION generate_list(TheType: Char): Boolean;
VAR  SummaryFile       : Text;
     TotalFiles        : Longint;
     TotalKiloBytes    : Longint;
     running_files     : Longint;
     running_bytes     : Longint;
     file_list         : text;
     loop              : word;
     file_date_string  : string;
     full_lists        : boolean;
     count_lines       : word;
     list_number       : word;
     Temp              : string;
     RunIt             : Longint;
     AreaCounter       : Longint;
     Crud              : Longint;
     DidIt             : Boolean;
LABEL                    QuitSearch,SkipIt;
BEGIN
     DidIt := True;
     CASE TheType OF
     'A': bsWriteLog('Generating file list:  All file areas',False);
     'C': bsWriteLog('Generating file list:  Current file area',False);
     'T': bsWriteLog('Generating file list:  Tagged file areas',False);
     'S': bsWriteLog('Generating file list:  Selected file area',False);
     END;
     System_Prompt('',2);
     full_lists := false;
     IF Get_Yes_No THEN full_lists := true;
     System_Prompt('',3);
     count_lines    := 0;
     list_number    := 1;
     TotalFiles     := 0;
     TotalKiloBytes := 0;
     AreaCounter    := 0;
     STR(list_number,Temp);
     RunIt := 0;
     IF _FileExists(DATA_Directory+'\FILELIST.TXT') THEN
     BEGIN
          _CopyFile('FILELIST.TXT',DATA_Directory,HOLD_Directory);
          _RenameFile(HOLD_Directory+'\FILELIST.TXT',HOLD_Directory+'\FILELIST.1');
     END;
     ASSIGN(SummaryFile,HOLD_Directory+'\SUMMARY.TXT');
     REWRITE(SummaryFile);
     WRITELN(SummaryFile,'ษออออออออออออออออออออออออัอออออออออออออออออออออออออออัออออออออออออออออออออออออป');
     WRITELN(SummaryFile,'บฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ      LISTING SUMMARY      ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ');
     WRITELN(SummaryFile,'ฬออออออออออออออออออออออออฯอออออออออออออออออออออออออออฯออออออออออออออออออออออออน');
     WRITELN(SummaryFile,'บ ###   Area Name                                     Files          Bytes    บ');
     WRITELN(SummaryFile,'ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     ASSIGN(file_list,HOLD_Directory+'\FILELIST.'+Temp);
     {$I-}APPEND(file_list);{$I+}
     IF IOResult<>0 THEN REWRITE(file_list);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(ffilearea);
     StartToggle(FileSize(FFileArea));
     REPEAT
           DoToggle;
           READ(ffilearea,fileareas);
           INC(AreaCounter);
           CASE TheType OF
           'C': IF (AreaCounter<>CurrentFileArea) THEN GOTO SkipIt;
           'T': IF NOT(IsFileTagged(FileAreas.AreaId)) THEN GOTO SkipIt;
           'S': IF (AreaCounter<>CurrentFileArea) THEN GOTO SkipIt;
           END;
           IF ((fileareas.view_access<=UserRecord.security) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
           BEGIN
                IF ((FileAreas.CD_Rom<>0) AND (NOT(IsCDToggled(FileAreas.CD_Rom)))) THEN GOTO SkipIt;
                IF FileAreas.PassThrough THEN GOTO SkipIt;
                Temp := 'บ  AREA: '+_PadRight(_String(AreaCounter)+' - '+fileareas.area_name,69)+'บ';
                WRITELN(file_list,'ษอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออป');
                WRITELN(file_list,Temp);
                WRITELN(file_list,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
                count_lines := count_lines+4;
                running_files := 0;
                running_bytes := 0;
                ASSIGN(ffiledefs,fileareas.dos_name+'.FIL');
                {$I-}
                RESET(ffiledefs);
                {$I+}
                IF IOResult = 0 THEN
                BEGIN
                     IF NOT(EOF(ffiledefs)) THEN
                     BEGIN
                          ASSIGN(fFileDesc,fileareas.dos_name+'.TXT');
                          RESET(fFileDesc);
                          REPEAT
                                READ(FFileDefs,FileDefs^);
                                FOR Crud := 1 TO FileDefs^.Desc_Lines DO
                                    READ(FFileDesc,FileDesc^[Crud]);
                                INC(count_lines);
                                {FILE NAME}
                                Temp := FileDefs^.file_name;
                                FOR loop := LENGTH(Temp) TO 13 DO Temp := Temp+' ';
                                WRITE(file_list,Temp);
                                {FILE SIZE}
                                STR(FileDefs^.file_size,Temp);
                                FOR loop := LENGTH(Temp) TO 8 DO Temp := ' '+Temp;
                                WRITE(file_list,Temp);
                                {FILE DATE}
                                Temp := TranslateDate1(_UnpackedDate(FileDefs^.file_date));
                                file_date_string := ' '+Temp+' ';
                                WRITE(file_list,file_date_string);
                                INC(Running_files);
                                running_bytes := running_bytes+FileDefs^.file_size;
                                INC(TotalFiles);
                                TotalKiloBytes := TotalKiloBytes+Round(FileDefs^.file_size/102400);
                                {DO DESCRIPTIONS}
                                IF Full_Lists=False THEN FileDefs^.Desc_Lines := 1;
                                FOR loop := 1 TO FileDefs^.Desc_Lines DO
                                BEGIN
                                     IF loop=1 THEN
                                     BEGIN
                                          WRITELN(file_list,FileDesc^[Loop].Desc);
                                     END
                                     ELSE
                                     BEGIN
                                          WRITE(file_list,'                                 ');
                                          WRITELN(file_list,FileDesc^[Loop].Desc);
                                          INC(count_lines);
                                     END;
                                END;
                          UNTIL EOF(FFileDefs);
                          CLOSE(fFileDesc);
                     END
                     ELSE WRITELN(file_list,'No Files.');
                     CLOSE(FFileDefs);
                END
                ELSE WRITELN(file_list,'No Files.');
                WRITELN(File_list,'ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ');
                WRITELN(File_list,'   Total Files: '+_PadRight(_String(Running_Files),17)+'Total Bytes: '+
                        _String(Running_Bytes));
                WRITELN(file_list,'');
                WRITELN(file_list,'');
                WRITELN(SummaryFile,'บ '+_PadRight(_String(AreaCounter),6)+_PadRight(fileareas.area_name,46)+
                        _PadLeft(_String(Running_Files),5)+_PadLeft(_String(Running_Bytes),16)+'   บ');
                IF count_lines>3000 THEN
                BEGIN
                     count_lines := 0;
                     INC(list_number);
                     STR(list_number,Temp);
                     CLOSE(file_list);
                     ASSIGN(file_list,HOLD_Directory+'\FILELIST.'+Temp);
                     REWRITE(file_list);
                END;
                IF CommLookAhead=#27 THEN
                BEGIN
                     DidIt := False;
                     GOTO QuitSearch;
                END;
           END;
           SkipIt:
     UNTIL EOF(FFileArea);
     QuitSearch:
     CLOSE(FFilearea);
     CLOSE(file_list);
     WRITELN(SummaryFile,'ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     WRITELN(SummaryFile,'บ'+_PadBoth('TOTAL FILES:  '+_String(TotalFiles)+'            '+
                         'TOTAL MBYTES:  '+_String(Round(TotalKiloBytes/10)),77)+'บ');
     WRITELN(SummaryFile,'ฬอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออน');
     WRITELN(SummaryFile,'บฑฑฑฑฑฑฑฑฑฑฑฑฑฑณ'+_PadBoth('List Date: '+_GetPrettyDate,47)+'ณฑฑฑฑฑฑฑฑฑฑฑฑฑฑบ');
     WRITELN(SummaryFile,'ศอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผ');
     CLOSE(SummaryFile);

     ASSIGN(file_list,HOLD_Directory+'\FILELIST.'+_String(list_number));
     APPEND(file_list);
     RESET(SummaryFile);
     REPEAT
           READLN(SummaryFile,Temp);
           WRITELN(file_list,Temp);
     UNTIL EOF(SummaryFile);
     CLOSE(file_list);
     CLOSE(SummaryFile);
     ERASE(SummaryFile);

     EndToggle;
     generate_list := DidIt;
END;


PROCEDURE generate_file_list;
VAR  c                 : char;
     file_list         : text;
     CommandLine       : string;
     TargetArc         : Byte;
     WorkTimer         : EventTimer;
     Status            : Boolean;
     Temp              : String[3];
     Temp2             : String[3];
BEGIN
     DisplayGraphicFile('SEARCHES',False,True,True);
     c := Get_Menu_Selection('CATSQ',#0);
     NewTimerSecs(WorkTimer,1440*60);
     CASE C OF
     'C': Status := generate_list('C');
     'A': Status := generate_list('A');
     'T': Status := generate_list('T');
     'S': BEGIN
               IF Change_FArea=True
                  THEN Status := generate_list('S')
                  ELSE EXIT;
          END;
     'Q': Exit;
     END;
     IF NOT(Status) THEN
     BEGIN
          clear_hold_dir;
          Exit;
     END;
     IF (UserRecord.DefaultArchiver=0)
        THEN TargetArc := Select_Archiver
        ELSE TargetArc := UserRecord.DefaultArchiver;
     IF TargetArc=0 THEN
     BEGIN
          clear_hold_dir;
          EXIT;
     END;
     ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
     RESET(FArcUtils);
     SEEK(FArcUtils,TargetArc-1);
     READ(FArcUtils,ArcUtils);
     CLOSE(FArcUtils);
     {PLEASE WAIT... CREATING ARCHIVE: @INSERT@}
     IF (RunningMessageFL<>0) THEN
     BEGIN
          Temp2 := _String(RunningMessageFL);
          CASE LENGTH(Temp2) OF
          1:   Temp := _Mid(ArcUtils.Extension,1,2)+Temp2;
          2:   Temp := _Mid(ArcUtils.Extension,1,1)+Temp2;
          3:   Temp := Temp2;
          ELSE Temp := ArcUtils.Extension;
          END;
     END
     ELSE Temp := ArcUtils.Extension;
     INC(RunningMessageFL);
     IF System_Info.FileListName='' THEN System_Info.FileListName := 'FILELIST';
     System_Prompt(System_Info.FileListName+'.'+Temp,42);
     ChDir(HOLD_Directory);
     CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+
                    System_Info.FileListName+'.'+Temp+' *.*';
     RUN_PROGRAM(CommandLine);
     ChDir(Shotgun_Directory);
     dl_file(HOLD_Directory+'\'+System_Info.FileListName+'.'+Temp);
     _EraseFile(HOLD_Directory+'\'+System_Info.FileListName+'.'+Temp);
     IF system_info.Suspend_FList=1 THEN AdjustUsersTime(True,ElapsedTimeInSecs(WorkTimer));
END;


END.
