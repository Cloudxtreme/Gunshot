{$I DEFINES.INC}
UNIT ULScan;


INTERFACE


PROCEDURE scan_uploads;


IMPLEMENTATION


USES Dos,BsLog,Globals,Screens,Execute,KeyInput,ExtDos,BsTime,
     SBuffer,MiscStr,Time,FileAdd,Report,_Mouse,BsFile,BsString;


PROCEDURE scan_uploads;
TYPE File_Names = RECORD
     FileNames  : String[12];
     END;
VAR  DirInfo           : SearchRec;
     uploaded_file     : string[12];
     dest_path         : string;
     CommandLine       : string;
     work_it           : string;
     Good_Action       : word;
     desc_file         : text;
     desc_count        : word;
     loop              : word;
     min_added         : word;
     virus_scan        : word;
     Scrapped          : Boolean;
     crud              : Longint;
     FileExtension     : String[3];
     CurrentFile       : Word;
     FileNames         : File_Names;
     FFileNames        : File Of File_Names;
     Poop              : Word;
     IsAnArchive       : Boolean;
     TFile2            : Text;
     Temp              : String;
     LABEL               virus_found;
BEGIN
     _EraseFile(NODE_Directory+'\NEWFILES.$$$');
     bsWriteLog('Scanning uploaded file(s)',False);
     ASSIGN(FScanners,DATA_Directory+'\SCANNERS.DAT');
     RESET(FScanners);
     READ(FScanners,Scanners);
     CLOSE(FScanners);
     CurrentFile := 0;
     dest_path   := '';
     Chdir(HOLD_Directory);
     ASSIGN(FFileNames,NODE_Directory+'\UPLOADS.$$$');
     REWRITE(FFileNames);
     FindFirst('*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          uploaded_file := _UpperCase(DirInfo.Name);
          INC(CurrentFile);
          FileNames.FileNames := Uploaded_File;
          WRITE(FFileNames,FileNames);
          FindNext(DirInfo);
     END;
     CLOSE(FFileNames);
     ASSIGN(FFileNames,NODE_Directory+'\UPLOADS.$$$');
     RESET(FFileNames);
     FOR Poop := 1 TO CurrentFile DO
     BEGIN
          Scrapped := True;
          ChDir(HOLD_Directory);
          READ(FFileNames,FileNames);
          uploaded_file := FileNames.FileNames;
          bsWriteLog('    Processing file: '+uploaded_file,False);
          FileExtension := _GetFileExtension(uploaded_file);
          DisplayGraphicFile('SCANNING',False,True,True);
          {MOVE FILE FROM HOLDFILE TO SCAN_DIR}
          ChangeMouse(BusyMouse);
          _MoveFileQuick(uploaded_file,HOLD_Directory,SCAN_Directory);
          ChangeMouse(DefaultMouse);
          ChDir(SCAN_Directory);
          {UNARC THE ARCHIVE}
          System_Prompt(uploaded_file,28);
          virus_scan  := 0;
          IsAnArchive := False;
          ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
          RESET(FArcUtils);
          REPEAT
                READ(FArcUtils,ArcUtils);
                IF _GetFileExtension(uploaded_file)=ArcUtils.Extension THEN
                BEGIN
                     IsAnArchive := True;
                     IF ArcDefs.ConvertArcs=1 THEN
                     BEGIN
                          bsWriteLog('Unarchiving archive: '+uploaded_file,False);
                          CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+uploaded_file;
                          Virus_Scan  := RUN_PROGRAM(CommandLine);
                          {Move To Bad Path}
                          IF (Virus_Scan<>0) THEN
                          BEGIN
                               IF (system_info.badfiles<>'') THEN
                               BEGIN
                                    bsWriteLog(' Incomplete archive!',False);
                                    _CopyFile(uploaded_file,SCAN_Directory,system_info.badfiles);
                               END;
                          END;
                          _EraseFile(uploaded_file);
                     END
                     ELSE
                     BEGIN
                          CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+uploaded_file+' FILE_ID.DIZ';
                          RUN_PROGRAM(CommandLine);
                          CommandLine := ArcDefs.ArcPath+ArcUtils.ExtractArc+' '+uploaded_file+' DESC.SDI';
                          RUN_PROGRAM(CommandLine);
                     END;
                END;
          UNTIL EOF(FArcUtils);
          CLOSE(FArcUtils);
          IF Virus_Scan<>0 THEN
          BEGIN
               System_Prompt('',31);
               Get_Enter;
               clear_scan_dir;
               GOTO virus_found;
          END;
          Chdir(Gunshot_Directory);
          {SCAN THE ARCHIVE}
          IF Scanners.ScanUploads=1 THEN
          BEGIN
               System_Prompt(uploaded_file,29);
               FOR Loop:=1 TO 5 DO
               BEGIN
                    IF Scanners.CommandLine[Loop]<>'' THEN
                    BEGIN
                         Virus_Scan := RUN_PROGRAM(Scanners.Path[Loop]+
                                                   Scanners.CommandLine[Loop]+
                                                   ' '+SCAN_Directory+'\*.*');
                         IF virus_scan=Scanners.VirusExists[Loop] THEN
                         BEGIN
                              bsWriteLog('   Virus in archive!',False);
                              System_Prompt('',32);
                              Get_Enter;
                              clear_scan_dir;
                              GOTO virus_found;
                         END;
                    END;
               END;
          END;
          {GET THE DESCRIPTION}
          FOR Loop := 1 TO 18 DO FileDesc^[Loop].Desc := '';
          desc_count := 0;
          ChDir(SCAN_Directory);
          IF _FileExists('FILE_ID.DIZ') THEN
          BEGIN
               bsWriteLog('   Description found',False);
               ASSIGN(desc_file,'FILE_ID.DIZ');
               RESET(desc_file);
               REPEAT
                     INC(desc_count);
                     READLN(desc_file,work_it);
                     FileDesc^[desc_count].Desc := work_it;
               UNTIL ((EOF(desc_file)) OR (desc_count=18));
               CLOSE(desc_file);
          END
          ELSE IF _FileExists('DESC.SDI') THEN
          BEGIN
               bsWriteLog('   Description found',False);
               ASSIGN(desc_file,'DESC.SDI');
               RESET(desc_file);
               REPEAT
                     INC(desc_count);
                     READLN(desc_file,work_it);
                     FileDesc^[desc_count].Desc := work_it;
               UNTIL ((EOF(desc_file)) OR (desc_count=18));
               CLOSE(desc_file);
          END;
          {RE-ARC THE ARCHIVE}
          IF IsAnArchive THEN
          BEGIN
               IF ArcDefs.ConvertArcs=1 THEN
               BEGIN
                    System_Prompt(_NoExtension(uploaded_file)+'.'+ArcDefs.DefaultArc,30);
                    ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
                    RESET(FArcUtils);
                    REPEAT
                          READ(FArcUtils,ArcUtils);
                          IF ArcDefs.DefaultArc=ArcUtils.Extension THEN
                          BEGIN
                               CommandLine := ArcDefs.ArcPath+ArcUtils.MoveArc+' '+
                                              _NoExtension(uploaded_file)+'.'+ArcDefs.DefaultArc+' *.*';
                               Virus_Scan  := RUN_PROGRAM(CommandLine);
                               Uploaded_File := _NoExtension(uploaded_file)+'.'+ArcDefs.DefaultArc;
                          END;
                    UNTIL EOF(FArcUtils);
                    CLOSE(FArcUtils);
               END;
          END;
          {GET USER'S DESCRIPTION IF NONE FOUND IN ARCHIVE}
          IF desc_count=0 THEN
          BEGIN
               FillChar(Fields^,SizeOf(Fields^),0);
               System_Prompt(uploaded_file,33);
               Get_Enter;
                    IF (Fields^[10].Text<>'') THEN Desc_Count := 10
               ELSE IF (Fields^[9].Text<>'') THEN Desc_Count := 9
               ELSE IF (Fields^[8].Text<>'') THEN Desc_Count := 8
               ELSE IF (Fields^[7].Text<>'') THEN Desc_Count := 7
               ELSE IF (Fields^[6].Text<>'') THEN Desc_Count := 6
               ELSE IF (Fields^[5].Text<>'') THEN Desc_Count := 5
               ELSE IF (Fields^[4].Text<>'') THEN Desc_Count := 4
               ELSE IF (Fields^[3].Text<>'') THEN Desc_Count := 3
               ELSE IF (Fields^[2].Text<>'') THEN Desc_Count := 2
               ELSE IF (Fields^[1].Text<>'') THEN Desc_Count := 1
               ELSE Desc_Count := 0;
               IF Desc_Count=0 THEN
               BEGIN
                    Desc_Count := 1;
                    FileDesc^[1].Desc := Get_Language(35);
               END
               ELSE
               BEGIN
                    FOR Loop := 1 TO Desc_Count DO
                      FileDesc^[Loop].Desc := Fields^[Loop].Text;
               END;
          END
          ELSE System_Prompt('',36);
          {ADD FILE TO FILE DATABASE}
          FileDefs^.File_Size   := _FileSize(SCAN_Directory+'\'+uploaded_file);
          FileDefs^.file_name   := _UpperCase(uploaded_file);
          FileDefs^.file_date   := _FileDate(SCAN_Directory+'\'+uploaded_file);
          FileDefs^.Desc_Lines  := Desc_Count;
          FileDefs^.class       := 0;
          FileDefs^.free        := 0;
          FileDefs^.dled        := 0;
          FileDefs^.uploader    := user_name;
          FileDefs^.added_date  := _ProperDate;
          UserRecord.uploads    := UserRecord.uploads+FileDefs^.file_size;
          INC(UserRecord.files_uploaded);
          ChangeMouse(BusyMouse);

          ASSIGN(TFile2,NODE_Directory+'\NEWFILES.$$$');
          {$I-}APPEND(TFile2);{$I+}
          IF IOResult<>0 THEN REWRITE(TFile2);
          Temp := _PadRight(FileDefs^.file_name,13)+_PadLeft(_String(FileDefs^.File_Size),9)+'  ';
          Temp := Temp+FileDesc^[1].Desc;
          WRITELN(TFile2,Temp);
          IF (FileDefs^.Desc_Lines<>0) THEN
          BEGIN
               FOR Loop := 2 TO FileDefs^.Desc_Lines DO
               BEGIN
                    Temp := _PadRight('',24)+FileDesc^[Loop].Desc;
                    WRITELN(TFile2,Temp);
               END;
          END;
          CLOSE(TFile2);

          AddFile(SCAN_Directory,FileUploadSub,FileUploadArea);
          ChangeMouse(DefaultMouse);
          Clear_Scan_Dir;
          Chdir(Gunshot_Directory);
          Scrapped := False;
          virus_found:
     END;
     CLOSE(FFileNames);
     ERASE(FFileNames);
     IF Scrapped=False THEN
     BEGIN
          DisplayGraphicFile('ULCREDIT',False,True,True);
          Get_Enter;
     END;
     Chdir(Gunshot_Directory);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(FFileArea);
     Seek(FFileArea,(CurrentFileArea-1));
     read(FFileArea,FileAreas);
     close(FFileArea);
     DoFilesUploadedReport;
END;


END.
