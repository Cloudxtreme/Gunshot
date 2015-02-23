{$I DEFINES.INC}
UNIT ViewArc;


INTERFACE


PROCEDURE view_archive(work_path,work_file: string);


IMPLEMENTATION


USES ANSIMisc,Globals,Archiver,BsLog,Screens,Execute,ViewTFil,ExtDos,BsFile;


PROCEDURE view_archive(work_path,work_file: string);
VAR  arc_type    : String;
     Dest_Path   : String;
     AllDone     : Boolean;
     CommandLine : String;
     LBuffer     : Array[1..8192] Of Byte;
     BadFile     : Boolean;
     FFile       : File;
     BytesRead   : Word;
     Loop        : Word;
LABEL              SkipIn;
BEGIN
     SendCrLf(2);
     system_prompt('',51,false,False);
     Dest_Path  := SCAN_Directory;
     arc_type   := _GetFileExtension(work_path+work_file);
     IF Arc_Type<>'' THEN
     BEGIN
          AllDone := False;
          Chdir(Dest_Path);
          ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
          RESET(FArcUtils);
          REPEAT
                READ(FArcUtils,ArcUtils);
                IF arc_type=ArcUtils.Extension THEN
                BEGIN
                     AllDone := True;
                     CommandLine := ArcDefs.ArcPath+ArcUtils.ViewArc+' '+work_path+work_file+' >ARC1.$$$';
                     ExecuteDosCommand(CommandLine);
                     CleanArc(SCAN_Directory+'\ARC1.$$$',Arc_Type);
                     bsWriteLog('Viewing archive contents of: '+work_file,False);
                     view_text_file(SCAN_Directory+'\ARC1.$$$','VIEWING ARCHIVE: '+work_file);
                END;
          UNTIL ((EOF(FArcUtils)) OR (AllDone));
          CLOSE(FArcUtils);
          Chdir(Gunshot_Directory);
          IF NOT(AllDone) THEN GOTO SkipIn;
     END
     ELSE
     BEGIN
          SkipIn:
          BadFile := False;
          ASSIGN(FFile,work_path+work_file);
          RESET(FFile,1);
          REPEAT
                BLOCKREAD(FFile,LBuffer,SizeOf(LBuffer),BytesRead);
                FOR Loop := 1 TO BytesRead DO IF LBuffer[Loop]=0 THEN BadFile := True;
          UNTIL ((EOF(FFile)) OR (BadFile));
          CLOSE(FFile);
          IF NOT(BadFile) THEN
          BEGIN
               bsWriteLog('Viewing text file: '+work_file,False);
               view_text_file(work_path+work_file,'VIEWING TEXT FILE: '+work_file);
          END;
     END;
     clear_scan_dir;
END;


END.
