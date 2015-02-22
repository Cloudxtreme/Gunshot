{$I DEFINES.INC}
UNIT EditBtch;


INTERFACE


PROCEDURE clear_file_queue;
PROCEDURE edit_batch;


IMPLEMENTATION


USES Globals,Screens,KeyInput,_Pick,Gr2_Bp,DLEst,Time,SBuffer,ChangeFA,
     MiscStr,BsLog,_Mouse,FileAdd,FileKill,FileSrch,ListFile,Commands,
     BsString;


PROCEDURE clear_file_queue;
VAR  loop      : word;
     TempQueue : Array[1..15] Of TaggedFileRecord;
     Active    : Word;
BEGIN
     Active := 0;
     FOR loop := 1 TO tagged DO
     BEGIN
          IF NOT(TaggedFiles^[Loop].TransferOk) THEN
          BEGIN
               INC(Active);
               TempQueue[Active] := TaggedFiles^[Loop];
          END;
     END;
     tagged := Active;
     FOR loop := 1 TO tagged DO TaggedFiles^[Loop] := TempQueue[Loop];
END;


PROCEDURE draw_batch;
VAR  draw_batch_work       : longint;
     loop                  : word;
     Temp                  : String;
BEGIN
     draw_batch_work := 0;
     do_download := false;
     time_for_downloads := 0;
     FOR loop := 1 TO TAGGED DO
     BEGIN
          time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles^[loop].Size);
          draw_batch_work := draw_batch_work+TaggedFiles^[loop].Size;
     END;
     IF (time_for_downloads>AbsTimeLeft) THEN
     BEGIN
          system_prompt('',53);
          Get_Enter;
     END;
     ClearBuffer;
     Draw_Batch_Work := 0;
     FOR Loop := 1 TO TAGGED DO
         INC(Draw_Batch_Work,TaggedFiles^[Loop].Size);
     AddToBuffer('@TBYTES',_String(Draw_Batch_Work));
     AddToBuffer('@TTIME',dl_estimate(draw_batch_work));
     DisplayGraphicFile('DLQUEUE',True,True,True);
     NewPickList(True);
     PickInfo.Current := 0;
     FOR Loop := 1 TO Tagged DO
     BEGIN
          Temp := ' ';
          Temp := Temp+'{'+_String(Colours.FileQueueName)+'}'+_PadRight(TaggedFiles^[Loop].FileName,14);
          Temp := Temp+'{'+_String(Colours.FileQueueDesc)+'}'+_PadRight(TaggedFiles^[Loop].Description,27);
          Temp := Temp+'{'+_String(Colours.FileQueueSize)+'}'+_PadRight(_String(TaggedFiles^[Loop].Size),10);
          Temp := Temp+'{'+_String(Colours.FileQueueTime)+'}'+_PadRight(dl_estimate(TaggedFiles^[Loop].Size),7);
          AddToPickList(Temp,Loop,True);
     END;
     HideTheMouse;
     BeginPickList;
     SetUpPickList;
     ShowTheMouse;
END;


PROCEDURE edit_batch;
VAR  c            : char;
     Temp         : String;
     OuttaHere    : Boolean;
     loop         : word;
     OldSub       : Word;
     OldArea      : Word;
     Success      : Boolean;
     Crud         : Longint;
     number_files : longint;
     kill         : word;
     P1,P2,P3,P4  : Char;
     P5,P6,P7,P8  : Char;
BEGIN
     Draw_Batch;
     OuttaHere := False;
     REPEAT
           P1 := GetCommandKeyPress('DLQUEUE',1);
           P2 := GetCommandKeyPress('DLQUEUE',2);
           P3 := GetCommandKeyPress('DLQUEUE',3);
           P4 := GetCommandKeyPress('DLQUEUE',4);
           P5 := GetCommandKeyPress('DLQUEUE',5);
           P6 := GetCommandKeyPress('DLQUEUE',6);
           P7 := GetCommandKeyPress('DLQUEUE',7);
           P8 := GetCommandKeyPress('DLQUEUE',8);
           Temp := P1+P2+P3+P4+P8+#27;
           IF UserRecord.Security>=system_info.FileKill THEN Temp := Temp+P5;
           IF UserRecord.Security>=system_info.FileCopy THEN Temp := Temp+P6;
           IF UserRecord.Security>=system_info.FileMove THEN Temp := Temp+P7;
           c := Get_Menu_Selection(Temp,CHR(0));
           IF C=P1 THEN
           BEGIN
                KillPickList;
                number_files := search_file('A');
                IF (number_files<>0) THEN List_Files(NODE_Directory+'\SEARCH$$');
                time_for_downloads := 0;
                FOR loop := 1 TO TAGGED DO
                BEGIN
                     time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles^[Loop].Size);
                END;
                draw_batch;
           END
           ELSE IF C=P2 THEN
           BEGIN
                KillPickList;
                IF (PickInfo.Current<>0) THEN
                BEGIN
                     kill := PickInfo.Current;
                     IF ((kill>0) AND (kill<=Tagged)) THEN
                     BEGIN
                          FOR loop := kill TO tagged-1 DO
                              TaggedFiles^[loop] := TaggedFiles^[loop+1];
                          FillChar(TaggedFiles^[Tagged],SizeOf(TaggedFiles^[Tagged]),0);
                          DEC(tagged);
                     END;
                END;
                time_for_downloads := 0;
                FOR loop := 1 TO TAGGED DO
                BEGIN
                     time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles^[loop].Size);
                END;
                draw_batch;
           END
           ELSE IF C=P3 THEN
           BEGIN
                FOR loop := 1 TO 15 DO TaggedFiles^[loop].TransferOk := true;
                clear_file_queue;
                KillPickList;
                draw_batch;
           END
           ELSE IF C=P4 THEN
           BEGIN
                IF (time_for_downloads<=AbsTimeLeft) THEN
                BEGIN
                     do_download := true;
                     OuttaHere := True;
                END;
           END
           ELSE IF C=P5 THEN
           BEGIN
                KillPickList;
                System_Prompt('',137);
                IF Get_Yes_No=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles^[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles^[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs^);
                                IF FileDefs^.File_Name=TaggedFiles^[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs^.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs^.Desc_Lines DO
                                         READ(FFileDesc,FileDesc^[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                     bsWriteLog('Erasing '+FileDefs^.File_Name+' from area #'+
                                                _String(TaggedFiles^[Loop].FileArea),False);
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          ChangeMouse(BusyMouse);
                          KillFile(FileAreas.Area_Path,TaggedFiles^[Loop].FileSub,TaggedFiles^[Loop].FileArea);
                          ChangeMouse(DefaultMouse);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles^[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                draw_batch;
           END
           ELSE IF C=P6 THEN
           BEGIN
                KillPickList;
                OldArea := CurrentFileArea;
                OldSub  := CurrentFileSub;
                CurrentFileSub := 0;
                IF Change_FArea=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles^[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles^[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs^);
                                IF FileDefs^.File_Name=TaggedFiles^[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs^.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs^.Desc_Lines DO
                                         READ(FFileDesc,FileDesc^[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                     bsWriteLog('Copying '+FileDefs^.File_Name+
                                              ' from area #'+_String(TaggedFiles^[Loop].FileArea)+
                                              ' to area #'+_String(CurrentFileArea),False);
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          ChangeMouse(BusyMouse);
                          AddFile(FileAreas.Area_Path,CurrentFileSub,CurrentFileArea);
                          ChangeMouse(DefaultMouse);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles^[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                CurrentFileArea := OldArea;
                CurrentFileSub  := OldSub;
                draw_batch;
           END
           ELSE IF C=P7 THEN
           BEGIN
                KillPickList;
                OldArea := CurrentFileArea;
                OldSub  := CurrentFileSub;
                CurrentFileSub := 0;
                IF Change_FArea=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles^[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles^[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs^);
                                IF FileDefs^.File_Name=TaggedFiles^[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs^.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs^.Desc_Lines DO
                                         READ(FFileDesc,FileDesc^[Crud]);
                                     CLOSE(FFileDesc);
                                     bsWriteLog('Moving '+FileDefs^.File_Name+
                                              ' from area #'+_String(TaggedFiles^[Loop].FileArea)+
                                              ' to area #'+_String(CurrentFileArea),False);
                                     Success := True;
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          ChangeMouse(BusyMouse);
                          AddFile(FileAreas.Area_Path,CurrentFileSub,CurrentFileArea);
                          ChangeMouse(DefaultMouse);
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles^[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles^[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs^);
                                IF FileDefs^.File_Name=TaggedFiles^[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs^.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs^.Desc_Lines DO
                                         READ(FFileDesc,FileDesc^[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          ChangeMouse(BusyMouse);
                          KillFile(FileAreas.Area_Path,TaggedFiles^[Loop].FileSub,TaggedFiles^[Loop].FileArea);
                          ChangeMouse(DefaultMouse);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles^[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                CurrentFileArea := OldArea;
                CurrentFileSub  := OldSub;
                draw_batch;
           END
           ELSE IF ((C=P8) OR (C=#27)) THEN
           BEGIN
                do_download := false;
                OuttaHere := True;
           END;
     UNTIL OuttaHere;
     KillPickList;
END;


END.