{$I DEFINES.INC}
UNIT ViewArc;


INTERFACE


PROCEDURE view_archive(work_path,work_file: string);


IMPLEMENTATION


USES Globals,Gfx,Archiver,Screens,SBuffer,KeyInput,Execute,BsString,
     BsLog,ViewTFil,BsFile,Special,ApCom,ApPort,ExtDos;


PROCEDURE view_archive(work_path,work_file: string);
VAR  LBuffer     : Array[1..8192] Of Byte;
     BytesRead   : Word;
     AllDone     : Boolean;
     BadFile     : Boolean;
     FFile       : File;
     CommandLine : String;
     arc_type    : String[80];
     Dest_Path   : String[80];
     Loop        : Word;
     C           : Char;
     Width       : Word;
     Height      : Word;
     Temp        : String[150];
     Temp4       : String[150];
     W           : Word;
     H           : Word;
LABEL              SkipIn;

     PROCEDURE SetImageWidthHeight;
     BEGIN
          W := 140;
          H := 100;
          ASSIGN(FRawFile,SGDirectory+'\IPREVIEW.SG');
          {$I-}RESET(FRawFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     READ(FRawFile,RawFile);
                     CASE RawFile.Number OF
                     23:  BEGIN
                               W := RawFile.x2-RawFile.x1+1;
                               H := RawFile.y2-RawFile.y1+1;
                          END;
                     END;
               UNTIL (EOF(FRawFile));
               CLOSE(FRawFile);
          END;
     END;

BEGIN
     Dest_Path := SCAN_Directory;
     arc_type  := _GetFileExtension(work_path+work_file);
     IF (Arc_Type<>'') THEN
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
                     system_prompt('',51);
                     CommandLine := ArcDefs.ArcPath+ArcUtils.ViewArc+' '+work_path+work_file+' >ARC1.$$$';
                     ExecuteDosCommand(CommandLine);
                     CleanArc(SCAN_Directory+'\ARC1.$$$',Arc_Type);
                     bsWriteLog('Viewing archive contents of: '+work_file,True);
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
          IF IsImage(work_path+work_file) THEN
          BEGIN
               SetImageWidthHeight;
               IF ScaleImage(work_path+work_file,Width,Height,W,H) THEN
               BEGIN
                    SendSystemFile(NODE_Directory+'\IMAGE.CMP');
                    bsWriteLog('Viewing image: '+work_file,True);
                    ClearBuffer;
                    AddToBuffer('@FILENAME',work_file+' ['+_String(Width)+'x'+_String(Height)+']');
                    FOR Loop := 1 TO 18 DO
                    BEGIN
                         Temp  := Remove_Special(FileDesc[Loop].Desc);
                         Temp4 := _String(Loop);
                         IF Length(Temp4)=1 THEN Temp4 := '0'+Temp4;
                         AddToBuffer('@DESCRIPTIONLINE'+Temp4,Temp);
                    END;
                    IF DisplayGraphicFile('IPREVIEW',True,True,True) THEN
                    BEGIN
                         PutStringTimeout(BBSPort,#255#114+'2'+#13,YappDelay);
                         AllDone := False;
                         REPEAT
                               c := Get_Menu_Selection('123',#13);
                               CASE UpCase(c) OF
                               #13: AllDone := True;
                               '1': PutStringTimeout(BBSPort,#255#114+'1'+#13,YappDelay);
                               '2': PutStringTimeout(BBSPort,#255#114+'2'+#13,YappDelay);
                               '3': PutStringTimeout(BBSPort,#255#114+'3'+#13,YappDelay);
                               END;
                         UNTIL AllDone;
                    END;
               END;
          END
          ELSE
          BEGIN
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
                    bsWriteLog('Viewing text file: '+work_file,True);
                    view_text_file(work_path+work_file,'VIEWING TEXT FILE: '+work_file);
               END;
          END;
     END;
     clear_scan_dir;
END;


END.
