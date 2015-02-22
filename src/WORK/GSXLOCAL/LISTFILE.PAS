{$I DEFINES.INC}
UNIT ListFile;


INTERFACE


PROCEDURE list_files(override: string);


IMPLEMENTATION


USES Globals,SBuffer,BsLog,Screens,Time,DLEst,Special,KeyInput,
     FilHeadr,GotKeys,ViewArc,_Save,Gr2_Bp,_Pick,_Mouse,CDS,Freq,
     Dates,Commands,BsString,BsTime,BsFile;


FUNCTION BytesInQueue: Longint;
VAR  Loop : Word;
     Work : Longint;
BEGIN
     Work := 0;
     IF Tagged>0 THEN
     BEGIN
          FOR loop := 1 TO tagged DO work := work+TaggedFiles^[Loop].Size;
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
          IF (_UpperCase(TaggedFiles^[Loop].FileName)<>_UpperCase(FName)) THEN
          BEGIN
               INC(Active);
               TempQueue[Active] := TaggedFiles^[Loop];
          END;
     END;
     tagged := Active;
     FOR loop := 1 TO tagged DO TaggedFiles^[Loop] := TempQueue[Loop];
     FOR Loop := tagged+1 TO 15 DO
     BEGIN
          FillChar(TaggedFiles^[Loop],SizeOf(TaggedFiles^[Loop]),0);
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
     AddToBuffer('@FILENAME',FileDefs^.File_Name);
     AddToBuffer('@UPLOADEDBY',FileDefs^.Uploader);
     AddToBuffer('@FILESIZ',_String(FileDefs^.file_size));
     temp := TranslateDate1(_UnpackedDate(FileDefs^.File_Date));
     AddToBuffer('@ARCDAT',Temp);
     temp := TranslateDate1(_UnpackedDate(FileDefs^.Added_Date));
     AddToBuffer('@ONLINE',Temp);
     AddToBuffer('@DLTIME',dl_estimate(FileDefs^.file_size));
     AddToBuffer('@DLDED',_String(FileDefs^.dled));
     IF FileDefs^.Free=0 THEN AddToBuffer('@FR',GetCommandString('MISC',2))
                        ELSE AddToBuffer('@FR',GetCommandString('MISC',1));
     IF FileAreas.CD_Rom=0 THEN AddToBuffer('@CD',GetCommandString('MISC',2))
                           ELSE AddToBuffer('@CD',GetCommandString('MISC',1));
     FOR Loop := 1 TO 18 DO
     BEGIN
          Temp  := Remove_Special(FileDesc^[Loop].Desc);
          Temp4 := _String(Loop);
          IF Length(Temp4)=1 THEN Temp4 := '0'+Temp4;
          AddToBuffer('@DESCRIPTIONLINE'+Temp4,Temp);
     END;
     bsWriteLog('Examining file: '+FileDefs^.File_Name,False);
     IF DisplayGraphicFile('FEXAMINE',True,True,True) THEN Get_Enter;
END;


PROCEDURE list_files(override: String);
VAR  OuttaHere   : Boolean;
     Temp        : String;
     Temp_FSize  : String[6];
     TempFSize   : Longint;
     Temp_FName  : String[13];
     Temp_FDate  : String[10];
     GoodFile    : Boolean;
     Counter     : Word;
     Logical     : Real;
     Loop        : Word;
     Work        : Word;
     c           : Char;
     LastArea    : String;
     P5,P6,P7,P8 : Char;
LABEL              SkipTheMark,AddTheFile,SkippingPast;

     PROCEDURE RedrawHeader;
     BEGIN
          LoadCurrentWindow('FILELIST');
          ClearBuffer;
          IF Override='' THEN AddToBuffer('@HEADER','AREA:  '+FileAreas.Area_Name)
                         ELSE AddToBuffer('@HEADER','File Search');
          DisplayGraphicFile('FLISTHDR',True,True,True);
          ScreenNumber := 1;
          PickInfo.Active := True;
          HideTheMouse;
          DrawPickListLocator;
          SetUpPickList;
          ShowTheMouse;
     END;

     FUNCTION GetTheFileName(Index: Word): String;
     BEGIN
          IF override=''
             THEN ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL')
             ELSE ASSIGN(FFileDefs,override+'.FIL');
          RESET(FFileDefs);
          SEEK(FFileDefs,Index-1);
          READ(FFileDefs,FileDefs^);
          CLOSE(FFileDefs);
          Temp := _RemoveSpaces(_UpperCase(FileDefs^.File_Name));
          GetTheFileName := Temp;
     END;

     FUNCTION GetTheFileSize(Index: Word): Longint;
     BEGIN
          IF override=''
             THEN ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL')
             ELSE ASSIGN(FFileDefs,override+'.FIL');
          RESET(FFileDefs);
          SEEK(FFileDefs,Index-1);
          READ(FFileDefs,FileDefs^);
          CLOSE(FFileDefs);
          GetTheFileSize := FileDefs^.File_Size;
     END;

     FUNCTION IsFreeFile(Index: Word): Boolean;
     BEGIN
          IF override=''
             THEN ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL')
             ELSE ASSIGN(FFileDefs,override+'.FIL');
          RESET(FFileDefs);
          SEEK(FFileDefs,Index-1);
          READ(FFileDefs,FileDefs^);
          CLOSE(FFileDefs);
          IF FileDefs^.Free=1 THEN IsFreeFile := True
                             ELSE IsFreeFile := False;
     END;

     FUNCTION FileIsTagged(Index: Word): Boolean;
     VAR  Status : Boolean;
          Loop2  : Word;
     BEGIN
          Status := False;
          Temp_FName := GetTheFileName(Index);
          FOR loop2 := 1 TO tagged DO
          BEGIN
               IF _RemoveSpaces(_UpperCase(TaggedFiles^[loop2].FileName))=Temp_FName
                  THEN Status := true;
          END;
          FileIsTagged := Status;
     END;

     PROCEDURE TagFile(Index: Word);
     BEGIN
          IF override=''
             THEN ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL')
             ELSE ASSIGN(FFileDefs,override+'.FIL');
          RESET(FFileDefs);
          SEEK(FFileDefs,Index-1);
          READ(FFileDefs,FileDefs^);
          CLOSE(FFileDefs);
          IF override=''
             THEN ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT')
             ELSE ASSIGN(FFileDesc,override+'.TXT');
          RESET(FFileDesc);
          SEEK(FFileDesc,FileDefs^.First_Desc-1);
          READ(FFileDesc,FileDesc^[1]);
          CLOSE(FFileDesc);
          INC(tagged);
          TaggedFiles^[tagged].FileName    := _RemoveSpaces(_UpperCase(FileDefs^.File_Name));
          TaggedFiles^[tagged].Size        := FileDefs^.File_Size;
          TaggedFiles^[tagged].Description := _Mid(FileDesc^[1].Desc,1,25);
          CASE FileDefs^.Free OF
          1:   TaggedFiles^[tagged].FreeFile := True;
          ELSE TaggedFiles^[tagged].FreeFile := False;
          END;
          IF Override='' THEN
          BEGIN
               IF fileareas.cd_rom<>0
                  THEN TaggedFiles^[Tagged].CDRom := true
                  ELSE TaggedFiles^[Tagged].CDRom := false;
               TaggedFiles^[tagged].FilePath      := FileAreas.Area_Path;
               TaggedFiles^[tagged].FileArea      := CurrentFileArea;
               TaggedFiles^[tagged].FileSub       := CurrentFileSub
          END
          ELSE
          BEGIN
               ASSIGN(FFileIndex,override+'.IDX');
               RESET(FFileIndex);
               SEEK(FFileIndex,Index-1);
               READ(FFileIndex,FileIndex);
               CLOSE(FFileIndex);
               IF FileIndex.cd_rom<>0
                  THEN TaggedFiles^[Tagged].CDRom := true
                  ELSE TaggedFiles^[Tagged].CDRom := false;
               TaggedFiles^[tagged].FilePath      := FileIndex.Path;
               TaggedFiles^[tagged].FileArea      := FileIndex.Area_Num;
               TaggedFiles^[tagged].FileSub       := FileIndex.Area_Sub;
          END;
     END;

     PROCEDURE RequestFile(Index: Word);
     BEGIN
          IF Override='' THEN
          BEGIN
               FileIndex.cd_rom   := fileareas.cd_rom;
               FileIndex.area_num := CurrentFileArea;
               FileIndex.area_sub := CurrentFileSub;
          END
          ELSE
          BEGIN
               ASSIGN(FFileIndex,override+'.IDX');
               RESET(FFileIndex);
               SEEK(FFileIndex,Index-1);
               READ(FFileIndex,FileIndex);
               CLOSE(FFileIndex);
          END;
          IF (FileIndex.CD_Rom<>0) THEN
          BEGIN
               RequestIt(FileAreas.Area_Path+FileDefs^.File_Name,
                         FileAreas.Area_Name,GetCDName(FileIndex.CD_Rom),
                         FileIndex.CD_Rom,FileIndex.Area_Num,FileIndex.Area_Sub);
          END
          ELSE
          BEGIN
               RequestIt(FileAreas.Area_Path+FileDefs^.File_Name,
                         FileAreas.Area_Name,'',0,
                         FileIndex.Area_Num,FileIndex.Area_Sub);
          END;
     END;

     PROCEDURE ReloadTag;
     VAR  FFPickList : File Of Pick_List;
     BEGIN
          IF PickInfo.UsingDisk THEN
          BEGIN
               ASSIGN(FFPickList,NODE_Directory+'\PICK.LST');
               RESET(FFPickList);
               SEEK(FFPickList,PickInfo.Current-1);
               READ(FFPickList,PickList);
          END
          ELSE Move(HugePick^[PickInfo.Current],PickList,SizeOf(PickList));
          Work    := Pos('}',PickList.Line);
          CASE Work OF
          4:   Delete(PickList.Line,3,1);
          5:   Delete(PickList.Line,3,2);
          END;
          IF PickList.Line[1]=Chr(254) THEN
          BEGIN
               PickList.Line[1] := ' ';
               Insert(_String(Colours.FileListFileName),PickList.Line,3);
          END
          ELSE
          BEGIN
               PickList.Line[1] := Chr(254);
               Insert(_String(Colours.FileListTaggedFile),PickList.Line,3);
          END;
          IF PickInfo.UsingDisk THEN
          BEGIN
               SEEK(FFPickList,PickInfo.Current-1);
               WRITE(FFPickList,PickList);
               CLOSE(FFPickList);
          END
          ELSE Move(PickList,HugePick^[PickInfo.Current],SizeOf(PickList));
          HideTheMouse;
          SetUpPickList;
          ShowTheMouse;
     END;

BEGIN
     IF Override='' THEN Header(CurrentFileSub,CurrentFileArea,True);
     IF override=''
        THEN ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL')
        ELSE ASSIGN(FFileDefs,override+'.FIL');
     IF override=''
        THEN ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT')
        ELSE ASSIGN(FFileDesc,override+'.TXT');
     IF Override<>'' THEN ASSIGN(ffileindex,override+'.IDX');
     {$I-}
     RESET(FFileDefs);
     RESET(FFileDesc);
     IF Override<>'' THEN RESET(ffileindex);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          IF NOT(EOF(FFileDefs)) THEN
          BEGIN
               ClearBuffer;
               IF Override='' THEN AddToBuffer('@HEADER','AREA:  '+FileAreas.Area_Name)
                              ELSE AddToBuffer('@HEADER','File Search');
               DisplayGraphicFile('FLISTHDR',True,True,True);
               ScreenNumber := 1;
               NewPickList(True);
               PickInfo.Current := 0;
               Counter          := 0;
               LastArea         := '';
               ChangeMouse(BusyMouse);
               REPEAT
                     READ(FFileDefs,FileDefs^);
                     IF Override<>'' THEN
                     BEGIN
                          READ(FFileIndex,FileIndex);
                          IF LastArea<>FileIndex.Area_Name THEN
                          BEGIN
                               LastArea := FileIndex.Area_Name;
                               Temp     := _Replicate('Ä',80);
                               Move(LastArea[1],Temp[2],Length(LastArea));
                               AddToPickList(Temp,0,False);
                          END;
                     END;
                     INC(Counter);
                     FillChar(FileDesc^,SizeOf(FileDesc^),0);
                     FOR Loop := 1 TO FileDefs^.Desc_Lines DO
                         READ(FFileDesc,FileDesc^[Loop]);
                     Temp_FName := _PadRight(FileDefs^.file_name,13);
                     {Create The File Size}
                     IF FileDefs^.File_Size<=1024 THEN
                     BEGIN {Bytes}
                          temp_fsize := _String(FileDefs^.file_size)+'B ';
                     END
                     ELSE IF FileDefs^.File_Size>=1024000 THEN
                     BEGIN {Megs}
                          Logical := FileDefs^.file_size/1024000;
                          STR(Logical:0:1,temp_fsize);
                          temp_fsize := temp_fsize+'M ';
                     END
                     ELSE
                     BEGIN {KBytes}
                          temp_fsize := _String(Round(FileDefs^.file_size/1024))+'K ';
                     END;
                     Temp_FSize := _PadLeft(Temp_FSize,6);
                     IF (FileDefs^.added_date>UserRecord.last_logoff)
                        THEN Temp_FDate := TranslateDate1(_UnpackedDate(FileDefs^.file_date)+Chr(254))
                        ELSE Temp_FDate := TranslateDate1(_UnpackedDate(FileDefs^.file_date)+' ');
                     IF override<>'' THEN
                     BEGIN
                       fileareas.area_path := fileindex.path;
                       fileareas.cd_rom    := fileindex.cd_rom;
                     END;
                     {Check If The File Is Online}
                     GoodFile := False;
                     IF fileareas.cd_rom<>0 THEN
                     BEGIN
                       IF IsCDOnline(fileareas.cd_rom)
                          THEN GoodFile := True
                          ELSE GoodFile := False;
                     END
                     ELSE
                     BEGIN
                       IF _FileExists(fileareas.area_path+FileDefs^.file_name)
                          THEN GoodFile := true;
                     END;
                     Work := Colours.FileListFileName;
                     C    := ' ';
                     FOR loop := 1 TO Tagged DO
                     BEGIN
                       IF _RemoveSpaces(TaggedFiles^[loop].FileName)=_RemoveSpaces(temp_fname) THEN
                       BEGIN
                         Work := Colours.FileListTaggedFile;
                         C    := Chr(254);
                       END;
                     END;
                     IF GoodFile THEN
                     BEGIN
                       Temp := C+'{'+_String(Work)+'}'+Temp_FName+
                               '{'+_String(Colours.FileListFileSize)+'}'+Temp_FSize+
                               '{'+_String(Colours.FileListFileDate)+'}'+Temp_FDate+' '+
                               '{'+_String(Colours.FileListDescription1)+'}'+FileDesc^[1].Desc;
                     END
                     ELSE
                     BEGIN
                       Temp := C+'{'+_String(Work)+'}'+Temp_FName+
                               '{'+_String(Colours.FileListFileSize)+'}'+Temp_FSize+
                               '{'+_String(Colours.FileListOfflineFile)+'}'+' Offline  '+
                               '{'+_String(Colours.FileListDescription1)+'}'+FileDesc^[1].Desc;
                     END;
                     AddToPickList(Temp,Counter,True);
                     IF ((FileDefs^.Desc_Lines<>1) AND (UserRecord.file_lines<>1)) THEN
                     BEGIN
                       FOR Loop := 2 TO UserRecord.file_lines DO
                       BEGIN
                         IF Loop<=FileDefs^.Desc_Lines THEN
                            AddToPickList(_PadRight('',30)+'{'+
                                          _String(Colours.FileListDescriptions)+
                                          '}'+FileDesc^[Loop].Desc,0,False);
                       END;
                     END;
               UNTIL EOF(FFileDefs);
               CLOSE(FFileDefs);
               CLOSE(FFileDesc);
               IF Override<>'' THEN CLOSE(ffileindex);
               ChangeMouse(DefaultMouse);
               HideTheMouse;
               BeginPickList;
               SetUpPickList;
               ShowTheMouse;
               OuttaHere := False;
               P5 := GetCommandKeyPress('FLISTHDR',5);
               P6 := GetCommandKeyPress('FLISTHDR',6);
               P7 := GetCommandKeyPress('FLISTHDR',7);
               P8 := GetCommandKeyPress('FLISTHDR',8);
               REPEAT
                     c := UpCase(GetKeyPress);
                     IF ((C=#27) OR (C=P5)) THEN
                     BEGIN
                          OuttaHere := True;
                     END
                     ELSE IF ((C=#2) OR (C=P7)) THEN
                     BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                            Counter := TrueIndex(PickInfo.Current);
                            IF override='' THEN ASSIGN(fFileDefs,fileareas.dos_name+'.FIL')
                                           ELSE ASSIGN(fFileDefs,override+'.FIL');
                            RESET(fFileDefs);
                            Seek(fFileDefs,Counter-1);
                            READ(fFileDefs,FileDefs^);
                            CLOSE(fFileDefs);
                            FillChar(FileDesc^,SizeOf(FileDesc^),0);
                            IF override='' THEN ASSIGN(ffiledesc,fileareas.dos_name+'.TXT')
                                           ELSE ASSIGN(ffiledesc,override+'.TXT');
                            RESET(ffiledesc);
                            SEEK(ffiledesc,FileDefs^.First_Desc-1);
                            FOR Loop := 1 TO FileDefs^.Desc_Lines DO
                                READ(FFileDesc,FileDesc^[Loop]);
                            CLOSE(ffiledesc);
                            SaveCurrentWindow('FILELIST');
                            ExamineFile;
                            RedrawHeader;
                          END;
                     END
                     ELSE IF C=P8 THEN
                     BEGIN
                          IF (PickInfo.Current<>0) THEN
                          BEGIN
                            Counter := TrueIndex(PickInfo.Current);
                            SaveCurrentWindow('FILELIST');
                            IF override='' THEN ASSIGN(fFileDefs,fileareas.dos_name+'.FIL')
                                           ELSE ASSIGN(fFileDefs,override+'.FIL');
                            RESET(fFileDefs);
                            Seek(fFileDefs,Counter-1);
                            READ(fFileDefs,FileDefs^);
                            CLOSE(fFileDefs);
                            IF Override<>'' THEN
                            BEGIN
                              ASSIGN(ffileindex,override+'.IDX');
                              RESET(ffileindex);
                              SEEK(ffileindex,Counter-1);
                              READ(ffileindex,fileindex);
                              CLOSE(ffileindex);
                              FileAreas.Area_Path := fileindex.path;
                            END;
                            FillChar(FileDesc^,SizeOf(FileDesc^),0);
                            IF override='' THEN ASSIGN(ffiledesc,fileareas.dos_name+'.TXT')
                                           ELSE ASSIGN(ffiledesc,override+'.TXT');
                            RESET(ffiledesc);
                            SEEK(ffiledesc,FileDefs^.First_Desc-1);
                            FOR Loop := 1 TO FileDefs^.Desc_Lines DO
                                READ(FFileDesc,FileDesc^[Loop]);
                            CLOSE(ffiledesc);
                            IF NOT(_FileExists(FileAreas.Area_Path+FileDefs^.File_Name)) THEN
                            BEGIN
                              IF ((Freqs.AllowFreqs) AND (UserRecord.Security>=Freqs.Access) AND
                                 GotTheKeys(UserRecord.Tags,Freqs.Tags)) THEN
                              BEGIN
                                DisplayGraphicFile('FREQASK',False,True,True);
                                IF Get_Yes_No THEN RequestFile(Counter);
                              END
                              ELSE
                              BEGIN
                                System_Prompt('',41);
                                Get_Enter;
                              END;
                            END
                            ELSE View_Archive(FileAreas.Area_Path,FileDefs^.File_Name);
                            RedrawHeader;
                          END;
                     END
                     ELSE IF ((C=#1) OR (C=P6)) THEN
                     BEGIN
                          IF ((UserRecord.Security>=FileAreas.DL_Access) AND
                              GotTheKeys(UserRecord.Tags,FileAreas.Tags) AND
                              (PickInfo.Current<>0)) THEN
                          BEGIN
                            Counter := TrueIndex(PickInfo.Current);
                            IF override='' THEN ASSIGN(fFileDefs,fileareas.dos_name+'.FIL')
                                           ELSE ASSIGN(fFileDefs,override+'.FIL');
                            RESET(fFileDefs);
                            Seek(fFileDefs,Counter-1);
                            READ(fFileDefs,FileDefs^);
                            CLOSE(fFileDefs);
                            IF Override<>'' THEN
                            BEGIN
                              ASSIGN(ffileindex,override+'.IDX');
                              RESET(ffileindex);
                              SEEK(ffileindex,Counter-1);
                              READ(ffileindex,fileindex);
                              CLOSE(ffileindex);
                              FileAreas.Area_Path := fileindex.path;
                            END;
                            IF NOT(_FileExists(FileAreas.Area_Path+FileDefs^.File_Name)) THEN
                            BEGIN
                              SaveCurrentWindow('FILELIST');
                              IF ((Freqs.AllowFreqs) AND (UserRecord.Security>=Freqs.Access) AND
                                 GotTheKeys(UserRecord.Tags,Freqs.Tags)) THEN
                              BEGIN
                                DisplayGraphicFile('FREQASK',False,True,True);
                                IF Get_Yes_No THEN RequestFile(Counter);
                              END
                              ELSE
                              BEGIN
                                System_Prompt('',41);
                                Get_Enter;
                              END;
                            END
                            ELSE
                            BEGIN
                              IF NOT(FileIsTagged(Counter)) THEN
                              BEGIN
                                IF (Tagged<>15) THEN
                                BEGIN
                                  {Add It If Its A Free File}
                                  IF IsFreeFile(Counter) THEN GOTO AddTheFile;
                                  {Check if the user has enough time left}
                                  TempFSize := GetTheFileSize(Counter);
                                  Time_For_Downloads := 0;
                                  IF (tagged<>0) THEN
                                  BEGIN
                                    FOR loop := 1 TO tagged DO
                                        time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles^[loop].Size);
                                    time_for_downloads := time_for_downloads+DL_ESTIMATE2(TempFSize);
                                  END
                                  ELSE time_for_downloads  := DL_ESTIMATE2(TempFSize);
                                  IF (time_for_downloads>AbsTimeLeft) THEN
                                  BEGIN
                                    SaveCurrentWindow('FILELIST');
                                    System_Prompt('',44);
                                    Get_Enter;
                                    GOTO SkipTheMark;
                                  END;
                                  {Check if the user has enough bytes left}
                                  IF (BytesInQueue+TempFSize>UserRecord.DLBytesRemaining) THEN
                                  BEGIN
                                    SaveCurrentWindow('FILELIST');
                                    System_Prompt('',45);
                                    Get_Enter;
                                    GOTO SkipTheMark;
                                  END;
                                  {Check the user's ratio}
                                  IF (NOT(RatioClear(BytesInQueue+TempFSize))) THEN
                                  BEGIN
                                    SaveCurrentWindow('FILELIST');
                                    System_Prompt('',46);
                                    Get_Enter;
                                    GOTO SkipTheMark;
                                  END;
                                  {Lets add it to the queue}
                                  AddTheFile:
                                  TagFile(Counter);
                                  ReloadTag;
                                  GOTO SkippingPast;
                                END
                                ELSE
                                BEGIN
                                  SaveCurrentWindow('FILELIST');
                                  System_Prompt('',48);
                                  Get_Enter;
                                END;
                              END
                              ELSE
                              BEGIN
                                PickInfo.Active := True;
                                RemoveFromQueue(GetTheFileName(Counter));
                                ReloadTag;
                                GOTO SkippingPast;
                              END;
                              SkipTheMark:
                            END;
                            RedrawHeader;
                            SkippingPast:
                          END;
                     END;
               UNTIL OuttaHere;
               KillPickList;
          END
          ELSE
          BEGIN
               CLOSE(FFileDefs);
               CLOSE(FFileDesc);
               IF Override<>'' THEN CLOSE(ffileindex);
               IF override='' THEN
               BEGIN
                    System_Prompt('',50);
                    get_enter;
               END;
          END;
     END
     ELSE
     BEGIN
          {$I-}
          CLOSE(FFileDefs);
          CLOSE(FFileDesc);
          IF Override<>'' THEN CLOSE(ffileindex);
          {$I+}
          IF IOResult=0 THEN;
          IF override='' THEN
          BEGIN
               System_Prompt('',50);
               get_enter;
          END;
     END;
END;


END.