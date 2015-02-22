{$I DEFINES.INC}
UNIT ListFile;


INTERFACE


PROCEDURE list_files(override: string);


IMPLEMENTATION


USES Globals,SBuffer,BsLog,Screens,ANSIMisc,Time,DLEst,Commands,BsTime,
     Special,KeyInput,FilHeadr,GotKeys,ViewArc,CDS,Freq,Dates,BsString,
     BsKeys,BsFile;


FUNCTION BytesInQueue: Longint;
VAR  Loop : Word;
     Work : Longint;
BEGIN
     Work := 0;
     IF Tagged>0 THEN
     BEGIN
          FOR loop := 1 TO tagged DO work := work+TaggedFiles[Loop].Size;
     END;
     BytesInQueue := Work;
END;


PROCEDURE RemoveFromQueue(FName: String);
VAR  loop      : word;
     TempQueue : Array[1..15] Of TaggedFileRecord;
     Active    : Word;
BEGIN
     Active := 0;
     FOR loop := 1 TO tagged DO
     BEGIN
          IF (_UpperCase(TaggedFiles[Loop].FileName)<>_UpperCase(FName)) THEN
          BEGIN
               INC(Active);
               TempQueue[Active] := TaggedFiles[Loop];
          END;
     END;
     tagged := Active;
     FOR loop := 1 TO tagged DO TaggedFiles[Loop] := TempQueue[Loop];
     FOR Loop := tagged+1 TO 15 DO
     BEGIN
          FillChar(TaggedFiles[Loop],SizeOf(TaggedFiles[Loop]),0);
     END;
END;


FUNCTION RatioClear(AddedBytes: Longint): Boolean;
VAR  UsersCalc  : Real;
     SystemCalc : Real;
BEGIN
     IF ((UserAccess.NoFileRatio=1) OR (UserAccess.byte_ratio=0)) THEN
     BEGIN
          RatioClear := True;
          Exit;
     END;
     UsersCalc  := (UserRecord.uploads/(UserRecord.dl_total+AddedBytes));
     SystemCalc := (1/UserAccess.byte_ratio);
     IF (UsersCalc>=SystemCalc) THEN RatioClear := True
                                ELSE RatioClear := False;
     IF (UserRecord.dl_total+AddedBytes<UserAccess.Ratio_Start) THEN RatioClear := True;
END;


PROCEDURE ExamineFile;
VAR  Temp  : String;
     Temp4 : String;
     Loop  : Word;
BEGIN
     ClearBuffer;
     AddToBuffer('@FILENAME',FileDefs.File_Name);
     AddToBuffer('@UPLOADEDBY',FileDefs.Uploader);
     AddToBuffer('@FILESIZ',_String(FileDefs.file_size));
     temp := TranslateDate1(_UnpackedDate(FileDefs.File_Date));
     AddToBuffer('@ARCDAT',Temp);
     temp := TranslateDate1(_UnpackedDate(FileDefs.Added_Date));
     AddToBuffer('@ONLINE',Temp);
     AddToBuffer('@DLTIME',dl_estimate(FileDefs.file_size));
     AddToBuffer('@DLDED',_String(FileDefs.dled));
     IF FileDefs.Free=0 THEN AddToBuffer('@FR',GetCommandString('MISC',2))
                         ELSE AddToBuffer('@FR',GetCommandString('MISC',1));
     IF FileAreas.CD_Rom=0 THEN AddToBuffer('@CD',GetCommandString('MISC',2))
                           ELSE AddToBuffer('@CD',GetCommandString('MISC',1));
     FOR Loop := 1 TO 18 DO
     BEGIN
          Temp  := Remove_Special(FileDesc[Loop].Desc);
          Temp4 := _String(Loop);
          IF Length(Temp4)=1 THEN Temp4 := '0'+Temp4;
          AddToBuffer('@DESCRIPTIONLINE'+Temp4,Temp);
     END;
     bsWriteLog('Examining file: '+FileDefs.File_Name,False);
     DisplayGraphicsFile('FEXAMINE',True,True,True,True,False);
     Get_Enter;
END;


PROCEDURE list_files(override: String);
TYPE Temp_Info = RECORD
     tfile_tag         : array[1..19] of string[12];
     tfile_path        : array[1..19] of string[40];
     tfile_desc        : array[1..19] of string[25];
     tfile_size        : array[1..19] of longint;
     tfile_free        : array[1..19] of boolean;
     tfile_Area        : array[1..19] of longint;
     tfile_Sub         : array[1..19] of longint;
     tarea_name        : array[1..19] of string[40];
     tcd_name          : array[1..19] of string[30];
     tcd_num           : array[1..19] of word;
     END;
TYPE pages = RECORD
     start_index       : word;
     end_index         : word;
     END;
VAR  file_at_top       : word;
     file_at_bot       : word;
     Crud              : Word;
     mark              : longint;
     SearchingFile     : word;
     File_pages        : Array[1..1] Of pages;
     FFile_Pages       : File Of pages;
     num_files         : word;
     num_bytes         : longint;
     popular_file      : string[20];
     popular_dl        : word;
     page_count        : word;
     line_count        : byte;
     top_count         : word;
     current_page      : word;
     loop              : word;
     loop2             : word;
     loop3             : word;
     actual_lines      : byte;
     temp_fname        : string[20];
     temp_fdate        : string[20];
     temp_fsize        : string[20];
     temp4             : string;
     exit_here         : byte;
     c                 : char;
     marked            : boolean;
     Good_File         : Boolean;
     workword2         : Word;
     list_files_temp   : string[80];
     last_area         : string[80];
     yy                : word;
     Options           : String[80];
     Logical           : Real;
     Temp              : ^Temp_Info;
     Code              : Integer;
     D1                : String;
     D2                : String;
     D3                : String;
     P1,P2,P3,P4       : Char;
     P5,P6,P7,P8       : Char;
LABEL                    SkipTheMark,AddTheFile;

     FUNCTION list_heading: byte;
     BEGIN
          ClearBuffer;
          AddToBuffer('@AN',_String(CurrentFileArea));
          DisplayGraphicsFile('FLISTHDR',True,True,True,True,False);
     END;

BEGIN
  New(Temp);

  IF (override='') THEN Header(CurrentFileSub,CurrentFileArea,True);

  {CLEAR VARS}
  FillChar(Temp^,SizeOf(Temp^),0);

  last_area := '';
  IF override='' THEN ASSIGN(ffiledefs,FileAreas.dos_name+'.FIL')
                 ELSE ASSIGN(ffiledefs,override+'.FIL');
  {$I-}
  RESET(ffiledefs);
  {$I+}
  IF IOResult = 0 THEN
  BEGIN
    num_files   := 0;
    num_bytes   := 0;
    popular_dl  := 0;
    line_count  := 0;
    page_count  := 1;
    top_count   := 1;
    IF NOT(EOF(ffiledefs)) THEN
    BEGIN
      ASSIGN(FFile_Pages,NODE_Directory+'\PAGES.$$$');
      REWRITE(FFile_Pages);
      REPEAT
        READ(ffiledefs,FileDefs);
        INC(num_files);
        num_bytes := num_bytes+FileDefs.file_size;
        IF num_files=1 THEN
        BEGIN
          popular_dl   := FileDefs.dled;
          popular_file := FileDefs.file_name;
        END
        ELSE
        BEGIN
          IF FileDefs.dled>popular_dl THEN
          BEGIN
            popular_dl   := FileDefs.dled;
            popular_file := FileDefs.file_name;
          END;
        END;

        IF FileDefs.Desc_Lines>UserRecord.file_lines
           THEN line_count := line_count+UserRecord.file_lines
           ELSE line_count := line_count+FileDefs.Desc_Lines;
        IF ((UserRecord.seperator=1) OR (override<>'')) THEN inc(line_count);

        IF ((line_count>19) AND (EOF(fFileDefs))) THEN
        BEGIN
          file_pages[1].start_index := top_count-1;
          file_pages[1].end_index   := num_files-2;
          WRITE(ffile_pages,file_pages[1]);
          top_count  := num_files;
          line_count := 0;
          inc(page_count);
          IF FileDefs.Desc_Lines>UserRecord.file_lines
             THEN line_count := line_count+UserRecord.file_lines
             ELSE line_count := line_count+FileDefs.Desc_Lines;
          IF ((UserRecord.seperator=1) OR (override<>'')) THEN inc(line_count);
          file_pages[1].start_index := num_files-1;
          file_pages[1].end_index   := num_files-1;
          WRITE(ffile_pages,file_pages[1]);
        END
        ELSE IF ((line_count>19) AND (NOT(EOF(fFileDefs)))) THEN
        BEGIN
          file_pages[1].start_index := top_count-1;
          file_pages[1].end_index   := num_files-2;
          WRITE(ffile_pages,file_pages[1]);
          top_count           := num_files;
          line_count          := 0;
          inc(page_count);
          IF FileDefs.Desc_Lines>UserRecord.file_lines
             THEN line_count := line_count+UserRecord.file_lines
             ELSE line_count := line_count+FileDefs.Desc_Lines;
          IF ((UserRecord.seperator=1) OR (override<>'')) THEN inc(line_count);
        END
        ELSE
        BEGIN
          IF EOF(fFileDefs) THEN
          BEGIN
            file_pages[1].start_index := top_count-1;
            file_pages[1].end_index   := num_files-1;
            WRITE(ffile_pages,file_pages[1]);
            top_count  := num_files;
            line_count := 0;
            IF FileDefs.Desc_Lines>UserRecord.file_lines
               THEN line_count := line_count+UserRecord.file_lines
               ELSE line_count := line_count+FileDefs.Desc_Lines;
            IF ((UserRecord.seperator=1) OR (override<>'')) THEN inc(line_count);
          END;
        END;
      UNTIL EOF(fFileDefs);
      CLOSE(fFileDefs);
      CLOSE(ffile_pages);

      current_page := 1;
      exit_here    := 0;

      REPEAT
        IF override='' THEN
        BEGIN
          list_heading;
          ASSIGN(ffiledesc,fileareas.dos_name+'.TXT');
          ASSIGN(fFileDefs,fileareas.dos_name+'.FIL');
          RESET(ffiledesc);
          RESET(fFileDefs);
        END
        ELSE
        BEGIN
          full_heading('File Search');
          ASSIGN(fFileDefs,override+'.FIL');
          ASSIGN(ffiledesc,override+'.TXT');
          ASSIGN(ffileindex,override+'.IDX');
          RESET(fFileDefs);
          RESET(ffileindex);
          RESET(ffiledesc);
        END;

        ASSIGN(FFile_Pages,NODE_Directory+'\PAGES.$$$');
        RESET(FFile_Pages);
        Seek(FFile_Pages,current_page-1);
        READ(FFile_Pages,File_Pages[1]);
        CLOSE(FFile_Pages);
        file_at_top := File_Pages[1].start_index;
        file_at_bot := File_Pages[1].end_index;
        Seek(fFileDefs,file_at_top);
        IF override<>'' THEN Seek(ffileindex,file_at_top);
        last_area := '';
        _HideCursor;
        FOR loop := 1 TO (file_at_bot-file_at_top+1) DO
        BEGIN
          READ(fFileDefs,FileDefs);
          Seek(fFileDesc,FileDefs.First_Desc-1);
          FOR Crud := 1 TO FileDefs.Desc_Lines DO
              READ(FFileDesc,FileDesc[Crud]);
          IF override<>'' THEN READ(ffileindex,fileindex);
          actual_lines := 0;
          IF FileDefs.Desc_Lines>UserRecord.file_lines
             THEN actual_lines := UserRecord.file_lines
             ELSE actual_lines := FileDefs.Desc_Lines;
          temp_fname       := FileDefs.file_name;
          Temp^.tfile_tag[loop]  := temp_fname;
          IF override<>'' THEN
          BEGIN
            fileareas.area_path    := fileindex.path;
            fileareas.cd_rom       := fileindex.cd_rom;
            Temp^.tfile_area[loop] := fileindex.area_num;
            Temp^.tfile_sub[loop]  := fileindex.area_sub;
            Temp^.tarea_name[loop] := fileindex.area_name;
          END;
          Temp^.tfile_path[loop] := fileareas.area_path;
          Temp^.tfile_size[loop] := FileDefs.file_size;
          IF FileDefs.free=1 THEN Temp^.tfile_free[loop] := true
                             ELSE Temp^.tfile_free[loop] := false;
          temp_fdate := TranslateDate1(_UnpackedDate(FileDefs.file_date));
          IF FileDefs.File_Size<=1024 THEN
          BEGIN {Bytes}
            STR(FileDefs.file_size,temp_fsize);
            temp_fsize := temp_fsize+'B ';
          END
          ELSE IF FileDefs.File_Size>=1024000 THEN
          BEGIN {Megs}
            Logical := FileDefs.file_size/1024000;
            STR(Logical:0:1,temp_fsize);
            temp_fsize := temp_fsize+'M ';
          END
          ELSE
          BEGIN {KBytes}
            STR(Round(FileDefs.file_size/1024),temp_fsize);
            temp_fsize := temp_fsize+'K ';
          END;
          Temp_FSize := _PadLeft(Temp_FSize,6);
          list_files_temp := Remove_Special(FileDesc[1].Desc);
          IF LENGTH(list_files_temp)>24
             THEN Temp^.tfile_desc[loop] := _Mid(list_files_temp,1,25)
             ELSE Temp^.tfile_desc[loop] := list_files_temp;
          {SEARCH AREA NAME SEPERATOR}
          IF override<>'' THEN
          BEGIN
            temp4 := ColourString(Colours.FileListSeperator)+'�'+Temp^.tarea_name[loop]+
                                  _Replicate('�',78-LENGTH(Temp^.tarea_name[loop]));
            WRITEANSI(temp4,true,True);
          END;
          {FILE INFO - NOT DESCRIPTION}
          Temp4 := ColourString(Colours.FileListNumber)+_String(Loop)+
                   ColourString(Colours.FileListBracket)+']';
          IF loop<10 THEN Temp4 := Temp4+'  '
                     ELSE Temp4 := Temp4+' ';
          Temp4 := Temp4+ColourString(Colours.FileListFileName);
          FOR loop2 := 1 TO Tagged DO
          BEGIN
            IF TaggedFiles[loop2].FileName=temp_fname THEN
            BEGIN
              Temp4 := Temp4+ColourString(Colours.FileListTaggedFile);
            END;
          END;
          Temp4 := Temp4+_PadRight(Temp_FName,12)+
                   ColourString(Colours.FileListFileSize)+
                   temp_fsize;
          IF FileDefs.added_date>UserRecord.last_logoff THEN
          BEGIN
            Temp4 := Temp4+ColourString(10)+#$08+'*';
          END;
          good_file := false;
          IF fileareas.cd_rom<>0 THEN
          BEGIN
            FillChar(CDRoms,SizeOf(CDRoms),0);
            IF IsCDOnline(fileareas.cd_rom) THEN
            BEGIN
              Temp4 := Temp4+ColourString(Colours.FileListfiledate)+temp_fdate;
              Good_File := True;
            END
            ELSE
            BEGIN
              Temp4 := Temp4+ColourString(Colours.FileListOfflineFile)+'Offline ';
              Good_File := False;
            END;
            Temp^.tcd_name[loop] := CDRoms.CDName;
            Temp^.tcd_num[loop]  := CDRoms.CDNumber;
          END
          ELSE
          BEGIN
            Temp^.tcd_name[loop] := '';
            Temp^.tcd_num[loop]  := 0;
            IF _FileExists(fileareas.area_path+FileDefs.file_name) then
            BEGIN
              Temp4 := Temp4+ColourString(Colours.FileListfiledate)+temp_fdate;
              good_file := true;
            END
            ELSE
            BEGIN
              Temp4 := Temp4+ColourString(Colours.FileListofflineFile)+'Offline ';
            END;
          END;
          Temp4 := Temp4+ColourString(Colours.FileListSeperator)+'�'+
                   ColourString(Colours.FileListDescription1)+FileDesc[1].Desc;
          WRITEANSI(temp4,True,True);
          FOR loop2 := 2 TO actual_lines DO
          BEGIN
            Temp4 := chr(27)+'[32C'+ColourString(Colours.FileListSeperator)+'�'+
                     ColourString(Colours.FileListDescriptions)+FileDesc[Loop2].Desc;
            WRITEANSI(Temp4,true,true);
          END;
          fore(Colours.FileListSeperator);
          if ((UserRecord.seperator=1) AND (override='')) THEN
          BEGIN
            IF ((loop=(file_at_bot-file_at_top+1)) AND (current_page=page_count)) THEN
            BEGIN
              IF UserRecord.IBM=1
                 THEN WRITEANSI('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴캑 ',false,false)
                 ELSE WRITEANSI('------------------------------+----------------------------------| ',false,false);
              FORE(14);
              WRITEANSI('End Area',false,false);
              FORE(Colours.FileListSeperator);
              IF UserRecord.IBM=1 THEN WRITEANSI(' 쳐',true,false)
                                  ELSE WRITEANSI(' |-',true,false);
            END
            ELSE
            BEGIN
              IF loop=(file_at_bot-file_at_top+1) THEN
              BEGIN
                IF UserRecord.IBM=1
                   THEN WRITEANSI('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴좔컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',true,false)
                   ELSE WRITEANSI('------------------------------+-----------------------------------------------',true,false);
              END
              ELSE
              BEGIN
                IF UserRecord.IBM=1
                   THEN WRITEANSI('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴탠컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴',true,false)
                   ELSE WRITEANSI('------------------------------+-----------------------------------------------',true,false);
              END;
            END;
          END;
        END;
        {END WRITE IT OUT!!!!!!}
        CLOSE(fFileDefs);
        CLOSE(ffiledesc);
        IF override<>'' THEN CLOSE(ffileindex);
        P1 := GetCommandKeyPress('FLISTHDR',1);
        P2 := GetCommandKeyPress('FLISTHDR',2);
        P3 := GetCommandKeyPress('FLISTHDR',3);
        P4 := GetCommandKeyPress('FLISTHDR',4);
        P5 := GetCommandKeyPress('FLISTHDR',5);
        P6 := GetCommandKeyPress('FLISTHDR',6);
        P7 := GetCommandKeyPress('FLISTHDR',7);
        P8 := GetCommandKeyPress('FLISTHDR',8);
        DoCommandString('FLISTHDR',1);
        DoCommandString('FLISTHDR',2);
        DoCommandString('FLISTHDR',3);
        DoCommandString('FLISTHDR',4);
        IF Override='' THEN
        BEGIN
          Options := P1+P2+P3+P4+P5+P7+P8;
          IF ((UserRecord.Security>=FileAreas.DL_Access) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
          BEGIN
            DoCommandString('FLISTHDR',6);
            Options := Options+P6;
          END;
        END
        ELSE
        BEGIN
          Options := P1+P2+P3+P4+P5+P6+P7+P8;
          DoCommandString('FLISTHDR',6);
        END;
        DoCommandString('FLISTHDR',7);
        DoCommandString('FLISTHDR',8);
        DoCommandString('FLISTHDR',5);
        SendCrLf(1);
        system_prompt('',1,false,True);
        _ShowCursor;
        REPEAT
          c := Get_Menu_Selection(Options,P1);
          IF C=P1 THEN
          BEGIN
            INC(current_page);
          END
          ELSE IF C=P2 THEN
          BEGIN
            DEC(current_page);
          END
          ELSE IF C=P5 THEN
          BEGIN
            SendCrLf(1);
            exit_here := 1;
          END
          ELSE IF C=P3 THEN
          BEGIN
            current_page := 1;
          END
          ELSE IF C=P4 THEN
          BEGIN
            current_page := page_count;
          END
          ELSE IF C=P7 THEN
          BEGIN
            SendCrLf(2);
            System_Prompt('',38,false,True);
            Get_Number(2,'',False);
            IF input_string<>'' THEN
            BEGIN
              VAL(input_string,mark,code);
              IF ((mark>0) AND (mark<(file_at_bot-file_at_top+2))) THEN
              BEGIN
                SearchingFile := file_at_top+mark-1;
                IF override='' THEN ASSIGN(fFileDefs,fileareas.dos_name+'.FIL')
                               ELSE ASSIGN(fFileDefs,override+'.FIL');
                RESET(fFileDefs);
                Seek(fFileDefs,SearchingFile);
                READ(fFileDefs,FileDefs);
                CLOSE(fFileDefs);
                FOR Crud := 1 TO 18 DO FileDesc[Crud].Desc := '';
                IF override='' THEN ASSIGN(ffiledesc,fileareas.dos_name+'.TXT')
                               ELSE ASSIGN(ffiledesc,override+'.TXT');
                RESET(ffiledesc);
                SEEK(ffiledesc,FileDefs.First_Desc-1);
                FOR Crud := 1 TO FileDefs.Desc_Lines DO
                    READ(FFileDesc,FileDesc[Crud]);
                CLOSE(ffiledesc);
                ExamineFile;
              END;
            END;
          END
          ELSE IF C=P8 THEN
          BEGIN
            SendCrLf(2);
            System_Prompt('',39,false,True);
            Get_Number(2,'',False);
            IF input_string<>'' THEN
            BEGIN
              VAL(input_string,mark,code);
              IF ((mark>0) AND (mark<(file_at_bot-file_at_top+2))) THEN
              BEGIN
                IF NOT(_FileExists(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark])) THEN
                BEGIN
                  IF ((Freqs.AllowFreqs) AND (UserRecord.Security>=Freqs.Access) AND
                     GotTheKeys(UserRecord.Tags,Freqs.Tags)) THEN
                  BEGIN
                    SendCrLf(1);
                    DisplayGraphicsFile('FREQASK',False,False,False,True,True);
                    IF Get_Yes_No THEN
                    BEGIN
                      IF (override<>'')
                         THEN RequestIt(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark],Temp^.tarea_name[mark],
                                        Temp^.tcd_name[mark],Temp^.tcd_num[mark],Temp^.tfile_sub[mark],Temp^.tfile_area[mark])
                         ELSE RequestIt(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark],FileAreas.Area_Name,
                                        Temp^.tcd_name[mark],Temp^.tcd_num[mark],CurrentFileArea,CurrentFileSub);
                    END;
                    SendCrLf(1);
                  END
                  ELSE
                  BEGIN
                    FORE(4);
                    SendCrLf(2);
                    System_Prompt('',41,true,False);
                    Get_Enter;
                  END;
                END
                ELSE View_Archive(Temp^.tfile_path[mark],Temp^.tfile_tag[mark]);
              END;
            END;
          END
          ELSE IF C=P6 THEN
          BEGIN
            SendCrLf(2);
            System_Prompt('',34,false,False);
            REPEAT
              SendCrLf(1);
              System_Prompt('',40,false,True);
              Get_Number(2,'',False);
              IF input_string<>'' THEN
              BEGIN
                VAL(input_string,mark,code);
                IF ((mark=0) OR (mark>file_at_bot-file_at_top+1)) THEN
                BEGIN
                  SendCrLf(1);
                  System_Prompt('',43,false,False);
                END
                ELSE IF NOT(_FileExists(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark])) THEN
                BEGIN
                  IF ((Freqs.AllowFreqs) AND (UserRecord.Security>=Freqs.Access) AND
                       GotTheKeys(UserRecord.Tags,Freqs.Tags)) THEN
                  BEGIN
                    SendCrLf(1);
                    DisplayGraphicsFile('FREQASK',False,False,False,True,True);
                    IF Get_Yes_No THEN
                    BEGIN
                      IF (override<>'')
                         THEN RequestIt(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark],Temp^.tarea_name[mark],
                                        Temp^.tcd_name[mark],Temp^.tcd_num[mark],Temp^.tfile_sub[mark],Temp^.tfile_area[mark])
                         ELSE RequestIt(Temp^.tfile_path[mark]+Temp^.tfile_tag[mark],FileAreas.Area_Name,
                                        Temp^.tcd_name[mark],Temp^.tcd_num[mark],CurrentFileArea,CurrentFileSub);
                    END;
                    SendCrLf(1);
                  END
                  ELSE
                  BEGIN
                    SendCrLf(1);
                    System_Prompt('',41,false,False);
                  END;
                END
                ELSE IF ((mark>0) AND (mark<(file_at_bot-file_at_top+2))) THEN
                BEGIN
                  marked := false;
                  IF tagged>0 THEN
                  BEGIN
                    FOR loop3 := 1 TO tagged DO
                    BEGIN
                      IF TaggedFiles[loop3].FileName=Temp^.tfile_tag[mark]
                         THEN marked := true;
                    END;
                  END;
                  IF NOT(marked) THEN
                  BEGIN
                    IF (Tagged<>15) THEN
                    BEGIN
                      {Add It If Its A Free File}
                      IF Temp^.tfile_free[mark] THEN GOTO AddTheFile;
                      {Check if the user has enough time left}
                      Time_For_Downloads := 0;
                      IF (tagged<>0) THEN
                      BEGIN
                        FOR loop3 := 1 TO tagged DO
                            time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles[loop3].Size);
                        time_for_downloads := time_for_downloads+DL_ESTIMATE2(Temp^.tfile_size[mark]);
                      END
                      ELSE time_for_downloads  := DL_ESTIMATE2(Temp^.tfile_size[mark]);
                      IF (time_for_downloads>AbsTimeLeft) THEN
                      BEGIN
                        SendCrLf(1);
                        System_Prompt('',44,false,False);
                        GOTO SkipTheMark;
                      END;
                      {Check if the user has enough bytes left}
                      IF (BytesInQueue+Temp^.tfile_size[mark]>
                          UserRecord.DLBytesRemaining) THEN
                      BEGIN
                        SendCrLf(1);
                        System_Prompt('',45,false,False);
                        GOTO SkipTheMark;
                      END;
                      {Check the user's ratio}
                      IF (NOT(RatioClear(BytesInQueue+Temp^.tfile_size[mark]))) THEN
                      BEGIN
                        SendCrLf(1);
                        System_Prompt('',46,false,False);
                        GOTO SkipTheMark;
                      END;
                      {Lets add it to the queue}
                      AddTheFile:
                      INC(tagged);
                      TaggedFiles[tagged].FileName    := Temp^.tfile_tag[mark];
                      TaggedFiles[tagged].FilePath    := Temp^.tfile_path[mark];
                      TaggedFiles[tagged].Size        := Temp^.tfile_size[mark];
                      TaggedFiles[tagged].FreeFile    := Temp^.tfile_free[mark];
                      TaggedFiles[tagged].Description := Temp^.tfile_desc[mark];
                      IF override='' THEN TaggedFiles[tagged].FileArea := CurrentFileArea
                                     ELSE TaggedFiles[tagged].FileArea := Temp^.tfile_area[mark];
                      IF override='' THEN TaggedFiles[tagged].FileSub  := CurrentFileSub
                                     ELSE TaggedFiles[tagged].FileSub  := Temp^.tfile_sub[mark];
                      FOR loop2 := LENGTH(input_string) TO 4 DO WRITECHAR(' ');
                      System_Prompt(TaggedFiles[tagged].FileName,47,false,False);
                      IF fileareas.cd_rom<>0 THEN TaggedFiles[Tagged].CDRom := true
                                             ELSE TaggedFiles[Tagged].CDRom := false;
                    END
                    ELSE
                    BEGIN
                      SendCrLf(1);
                      System_Prompt('',48,false,False);
                    END;
                  END
                  ELSE
                  BEGIN
                    FOR loop2 := LENGTH(input_string) TO 4 DO WRITECHAR(' ');
                    System_Prompt(Temp^.tfile_tag[mark],56,false,False);
                    RemoveFromQueue(Temp^.tfile_tag[mark]);
                  END;
                  SkipTheMark:
                END;
              END;
            UNTIL input_string='';
          END;
        UNTIL ord(c)<>0;
        IF (current_page>page_count) THEN
        BEGIN
             current_page := page_count;
             SendCrLf(2);
             system_prompt('',49,True,False);
             Get_Enter;
        END;
        IF current_page=0 THEN current_page := 1;
      UNTIL (exit_here=1);
    END
    ELSE
    BEGIN
      CLOSE(fFileDefs);
      IF override='' THEN
      BEGIN
        SendCrLf(2);
        System_Prompt('',50,true,False);
        get_enter;
      END;
    END;
  END
  ELSE
  BEGIN
    IF override='' THEN
    BEGIN
      SendCrLf(2);
      System_Prompt('',50,true,False);
      get_enter;
    END;
  END;
  Dispose(Temp);
END;


END.
