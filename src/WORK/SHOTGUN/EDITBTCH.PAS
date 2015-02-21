{$I DEFINES.INC}
UNIT EditBtch;


INTERFACE


PROCEDURE edit_batch;
PROCEDURE clear_file_queue;


IMPLEMENTATION


USES Globals,ANSIMisc,Screens,KeyInput,SBuffer,DLEst,Time,ChangeFa,
     MiscStr,BsLog,FileAdd,FileKill,FileSrch,ListFile,Commands,
     BsString;


PROCEDURE clear_file_queue;
VAR  loop      : word;
     TempQueue : Array[1..15] Of TaggedFileRecord;
     Active    : Word;
BEGIN
     Active := 0;
     FOR loop := 1 TO tagged DO
     BEGIN
          IF NOT(TaggedFiles[Loop].TransferOk) THEN
          BEGIN
               INC(Active);
               TempQueue[Active] := TaggedFiles[Loop];
          END;
     END;
     tagged := Active;
     FOR loop := 1 TO tagged DO TaggedFiles[Loop] := TempQueue[Loop];
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
          time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles[loop].Size);
          draw_batch_work := draw_batch_work+TaggedFiles[loop].Size;
     END;
     IF (time_for_downloads>AbsTimeLeft) THEN
     BEGIN
          SendCrLf(2);
          system_prompt('',53,true,False);
          Get_Enter;
     END;
     Draw_Batch_Work := 0;
     ClearBuffer;
     FOR Loop := 1 TO 15 DO
     BEGIN
          Temp := _String(Loop);
          IF Length(Temp)=1 THEN Temp := '0'+Temp;
          IF Loop<=Tagged THEN
          BEGIN
               INC(Draw_Batch_Work,TaggedFiles[Loop].Size);
               AddToBuffer('@FILENAME'+Temp,TaggedFiles[Loop].FileName);
               AddToBuffer('@FILEDESCRIPTION'+Temp,TaggedFiles[Loop].Description);
               AddToBuffer('@SIZE'+Temp,_String(TaggedFiles[Loop].Size));
               AddToBuffer('@DLT'+Temp,dl_estimate(TaggedFiles[Loop].Size));
          END
          ELSE
          BEGIN
               AddToBuffer('@FILENAME'+Temp,DontSend);
               AddToBuffer('@FILEDESCRIPTION'+Temp,DontSend);
               AddToBuffer('@SIZE'+Temp,DontSend);
               AddToBuffer('@DLT'+Temp,DontSend);
          END;
     END;
     AddToBuffer('@TBYTES',_String(Draw_Batch_Work));
     AddToBuffer('@TTIME',dl_estimate(draw_batch_work));
     DisplayGraphicsFile('DLQUEUE',True,True,True,True,False);
     DoCommandString('DLQUEUE',1);
     DoCommandString('DLQUEUE',2);
     DoCommandString('DLQUEUE',3);
     DoCommandString('DLQUEUE',4);
     IF UserRecord.Security>=system_info.FileKill THEN DoCommandString('DLQUEUE',5);
     IF UserRecord.Security>=system_info.FileCopy THEN DoCommandString('DLQUEUE',6);
     IF UserRecord.Security>=system_info.FileMove THEN DoCommandString('DLQUEUE',7);
     DoCommandString('DLQUEUE',8);
     system_prompt('',1,false,True);
END;


PROCEDURE edit_batch;
VAR  c            : char;
     loop         : word;
     kill         : word;
     number_files : longint;
     Temp         : String;
     FilesWritten : Word;
     CopyToArea   : Word;
     OldSub       : Word;
     OldArea      : Word;
     Crud         : Longint;
     Success      : Boolean;
     Code         : Integer;
     P1,P2,P3,P4  : Char;
     P5,P6,P7,P8  : Char;
BEGIN
     draw_batch;
     c := chr(0);
     REPEAT
           P1 := GetCommandKeyPress('DLQUEUE',1);
           P2 := GetCommandKeyPress('DLQUEUE',2);
           P3 := GetCommandKeyPress('DLQUEUE',3);
           P4 := GetCommandKeyPress('DLQUEUE',4);
           P5 := GetCommandKeyPress('DLQUEUE',5);
           P6 := GetCommandKeyPress('DLQUEUE',6);
           P7 := GetCommandKeyPress('DLQUEUE',7);
           P8 := GetCommandKeyPress('DLQUEUE',8);
           Temp := P1+P2+P3+P4+P8;
           IF UserRecord.Security>=system_info.FileKill THEN Temp := Temp+P5;
           IF UserRecord.Security>=system_info.FileCopy THEN Temp := Temp+P6;
           IF UserRecord.Security>=system_info.FileMove THEN Temp := Temp+P7;
           c := Get_Menu_Selection(Temp,CHR(0));
           IF C=P1 THEN
           BEGIN
                number_files := search_file('A');
                IF number_files<>0 THEN List_Files(NODE_Directory+'\SEARCH$$');
                time_for_downloads := 0;
                FOR loop := 1 TO TAGGED DO
                BEGIN
                     time_for_downloads := time_for_downloads+
                                           DL_ESTIMATE2(TaggedFiles[Loop].Size);
                END;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P2 THEN
           BEGIN
                SendCrLf(2);
                system_prompt('',52,false,True);
                Get_Number(2,'',False);
                IF input_string<>'' THEN
                BEGIN
                     VAL(input_string,kill,code);
                     IF ((kill>0) AND (kill<=Tagged)) THEN
                     BEGIN
                          FOR loop := kill TO tagged-1 DO
                          BEGIN
                               TaggedFiles[loop] := TaggedFiles[loop+1];
                          END;
                          FillChar(TaggedFiles[Tagged],SizeOf(TaggedFiles[Tagged]),0);
                          DEC(tagged);
                     END;
                END;
                time_for_downloads := 0;
                FOR loop := 1 TO TAGGED DO
                BEGIN
                     time_for_downloads := time_for_downloads+DL_ESTIMATE2(TaggedFiles[loop].Size);
                END;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P3 THEN
           BEGIN
                FOR loop := 1 TO 15 DO TaggedFiles[loop].TransferOk := true;
                clear_file_queue;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P4 THEN
           BEGIN
                IF (time_for_downloads<=AbsTimeLeft) THEN do_download := true;
           END
           ELSE IF C=P5 THEN
           BEGIN
                SendCrLf(2);
                System_Prompt('',137,false,False);
                IF Get_Yes_No=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                IF FileDefs.File_Name=TaggedFiles[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                     bsWriteLog('Erasing '+FileDefs.File_Name+' from area #'+
                                                _String(TaggedFiles[Loop].FileArea),False);
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          KillFile(FileAreas.Area_Path,TaggedFiles[Loop].FileSub,TaggedFiles[Loop].FileArea);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P6 THEN
           BEGIN
                OldArea := CurrentFileArea;
                OldSub  := CurrentFileSub;
                CurrentFileSub := 0;
                IF Change_FArea=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                IF FileDefs.File_Name=TaggedFiles[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                     bsWriteLog('Copying '+FileDefs.File_Name+
                                              ' from area #'+_String(TaggedFiles[Loop].FileArea)+
                                              ' to area #'+_String(CurrentFileArea),False);
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          AddFile(FileAreas.Area_Path,CurrentFileSub,CurrentFileArea);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                CurrentFileArea := OldArea;
                CurrentFileSub  := OldSub;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P7 THEN
           BEGIN
                OldArea := CurrentFileArea;
                OldSub  := CurrentFileSub;
                CurrentFileSub := 0;
                IF Change_FArea=True THEN
                BEGIN
                     FOR Loop := 1 TO Tagged DO
                     BEGIN
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                IF FileDefs.File_Name=TaggedFiles[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                     bsWriteLog('Moving '+FileDefs.File_Name+
                                              ' from area #'+_String(TaggedFiles[Loop].FileArea)+
                                              ' to area #'+_String(CurrentFileArea),False);
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          AddFile(FileAreas.Area_Path,CurrentFileSub,CurrentFileArea);
                          {LOAD THE AREA}
                          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
                          RESET(FFileArea);
                          SEEK(FFileArea,TaggedFiles[Loop].FileArea-1);
                          READ(FFileArea,FileAreas);
                          CLOSE(FFileArea);
                          {LOAD THE FILE}
                          ASSIGN(FFileDefs,FileAreas.Dos_Name+'.FIL');
                          RESET(FFileDefs);
                          Success := False;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                IF FileDefs.File_Name=TaggedFiles[Loop].FileName THEN
                                BEGIN
                                     ASSIGN(FFileDesc,FileAreas.Dos_Name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     Success := True;
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Success));
                          CLOSE(FFileDefs);
                          KillFile(FileAreas.Area_Path,TaggedFiles[Loop].FileSub,TaggedFiles[Loop].FileArea);
                     END;
                     FOR Loop := 1 TO 15 DO TaggedFiles[Loop].TransferOk := true;
                     clear_file_queue;
                END;
                CurrentFileArea := OldArea;
                CurrentFileSub  := OldSub;
                draw_batch;
                c := chr(0);
           END
           ELSE IF C=P8 THEN
           BEGIN
                do_download := false;
           END;
     UNTIL (ord(c)<>0);
END;


END.