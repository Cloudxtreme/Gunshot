{$I DEFINES.INC}
UNIT DownLoad;


INTERFACE


PROCEDURE dl_file(send_file: string);
PROCEDURE dl_queue;


IMPLEMENTATION


USES Globals,GetProto,ANSIMisc,Screens,BsLog,ErrorLog,KeyInput,XFer,
     EditBtch,MiscStr,AllGone,Time,Carrier,BsFile,BsString,BsTime;


PROCEDURE dl_file(send_file: string);
VAR  Chuckie             : String;
     Work                : Word;
     LABEL                 pass;
BEGIN
     AbortedProtocol := False;
     IF NOT(LocalLogon) THEN
     BEGIN
          IF ((UserRecord.DefaultProtocol<1) OR (UserRecord.DefaultProtocol>5)) THEN
          BEGIN
               select_protocol;
               IF protocol=255 THEN
               BEGIN
                    AbortedProtocol := True;
                    GOTO pass;
               END;
          END
          ELSE Protocol := UserRecord.DefaultProtocol;
          ClrPortScr;
          CASE protocol OF
          1:   System_Prompt('',8,true,False);
          2:   System_Prompt('',4,true,False);
          3:   System_Prompt('',5,true,False);
          4:   System_Prompt('',6,true,False);
          5:   System_Prompt('',7,true,False);
          END;
          System_Prompt('',22,true,False);
          SendCrLf(1);
          Chuckie := _NoPath(_UpperCase(Send_File));
          bsWriteLog('User downloading '+Chuckie,False);
          System_Prompt(chuckie,54,true,False);
          IF NOT(_FileExists(send_file)) THEN
          BEGIN
               DoErrorLog(22,send_file);
               bsWriteLog('File: '+Chuckie+' is missing',False);
               SendCrLf(1);
               System_Prompt('',24,true,False);
               GET_ENTER;
               AbortedProtocol := True;
               GOTO Pass;
          END
          ELSE
          BEGIN
               FilesToSend      := 1;
               FileQueueList[1] := Send_file;
               TransmitFile(send_file,Protocol);
          END;
          SendCrLf(1);
     END
     ELSE
     BEGIN
          SendCrLf(2);
          FORE(7);  WRITEANSI('Full path for local DL:  ',false,False);
          Fore(15); Get_String(40,'',true,false,true,False);
          SendCrLf(1);
          IF Input_String='' THEN
          BEGIN
               AbortedProtocol := True;
               GOTO pass;
          END;
          IF Input_String[LENGTH(Input_String)]='\' THEN DEC(Input_String[0]);
          _CreatePath(Input_String);
          SendCrLf(1);
          Fore(10); WRITEANSI('Copying file(s) to directory: '+input_string,False,False);
          _CopyFile(_NoPath(send_file),_GetFilePath(send_file),input_string);
          SendCrLf(2);
     END;
     pass:
     IF AbortedProtocol THEN bsWriteLog('Download aborted',False)
                        ELSE bsWriteLog('Download complete',False);
     CheckForCarrier;
END;


PROCEDURE dl_queue;
VAR  CommandLine   : string;
     loop          : byte;
     send_file     : string;
     Reset_it      : boolean;
     in_byte       : byte;
     log_off       : boolean;
     bytes         : longint;
     GotMem        : Boolean;
     ok            : boolean;
     file_found    : boolean;
     ByPass        : Boolean;
LABEL                Pass,SkipTheRest;
BEGIN
     edit_batch;
     IF do_download=True THEN
     BEGIN
          IF NOT(LocalLogon) THEN
          BEGIN
               IF tagged=0 THEN GOTO pass;
               IF ((UserRecord.DefaultProtocol<1) OR (UserRecord.DefaultProtocol>5)) THEN
               BEGIN
                    select_protocol;
                    IF protocol=255 THEN GOTO Pass;
               END
               ELSE Protocol := UserRecord.DefaultProtocol;
               log_off := false;
               SendCrLf(2);
               System_Prompt('',21,false,False);
               IF Get_Yes_No THEN log_off := true;
               ClrPortScr;
               IF system_info.use_cd_temp=1 THEN
               BEGIN
                    FOR loop := 1 TO TAGGED DO
                    BEGIN
                         IF TaggedFiles[Loop].CDRom THEN
                         BEGIN
                              System_Prompt(TaggedFiles[loop].FileName,55,true,false);
                              File_Found := _CopyFile(TaggedFiles[loop].FileName,
                                                      TaggedFiles[loop].FilePath,
                                                      CD_Directory);
                         END;
                    END;
                    SendCrLf(1);
               END;
               ClrPortScr;
               CASE protocol OF
               1:   System_Prompt('',8,true,false);
               2:   System_Prompt('',4,true,false);
               3:   System_Prompt('',5,true,false);
               4:   System_Prompt('',6,true,false);
               5:   System_Prompt('',7,true,false);
               END;
               System_Prompt('',22,true,false);
               SendCrLf(1);
               ByPass := False;
               IF ((Protocol<>2) AND (Protocol<>3)) THEN
               BEGIN
                    FilesToSend  := Tagged;
                    FOR loop := 1 TO tagged DO
                    BEGIN
                         IF _FileExists(CD_Directory+'\'+TaggedFiles[loop].FileName)
                            THEN send_file := CD_Directory+'\'+TaggedFiles[loop].FileName
                            ELSE send_file := TaggedFiles[loop].FilePath+TaggedFiles[loop].FileName;
                         System_Prompt(TaggedFiles[loop].FileName,54,true,false);
                         FileQueueList[Loop] := Send_file;
                         TaggedFiles[Loop].TransferOk   := False;
                    END;
                    TransmitFile('',Protocol);
                    IF AbortedProtocol THEN
                    BEGIN
                         IF ((LastFilesBytesSent>=TaggedFiles[CurrentFileNum].Size) AND NOT(WeAbort)) THEN
                         BEGIN
                              bsWriteLog('Alert to sysop!!! Probable leach of files!!!',False);
                              bsWriteLog('File size: '+_String(TaggedFiles[CurrentFileNum].Size)+
                                         '  Bytes sent: '+_String(LastFilesBytesSent),False);
                              IF DisplayGraphicsFile('LEACH',True,False,False,True,False) THEN Get_Enter;
                         END;
                         log_off := false;
                    END;
               END
               ELSE
               BEGIN
                    FOR loop := 1 TO tagged DO
                    BEGIN
                         IF _FileExists(CD_Directory+'\'+TaggedFiles[loop].FileName)
                            THEN send_file := CD_Directory+'\'+TaggedFiles[loop].FileName
                            ELSE send_file := TaggedFiles[loop].FilePath+TaggedFiles[loop].FileName;
                         System_Prompt(TaggedFiles[loop].FileName,54,true,false);
                         FilesToSend      := 1;
                         FileQueueList[1] := send_file;
                         TransmitFile(send_file,Protocol);
                         IF AbortedProtocol THEN
                         BEGIN
                              TaggedFiles[Loop].TransferOk := False;
                              log_off := false;
                              GOTO SkipTheRest;
                         END;
                         TaggedFiles[Loop].TransferOk := True;
                    END;
                    SkipTheRest:
               END;
               {UPDATE THE USERS ACCOUNT & THE FILE DATABASE}
               FOR loop := 1 TO tagged DO
               BEGIN
                    IF TaggedFiles[Loop].TransferOk THEN
                    BEGIN
                         IF _FileExists(CD_Directory+'\'+TaggedFiles[loop].FileName)
                            THEN send_file := CD_Directory+'\'+TaggedFiles[loop].FileName
                            ELSE send_file := TaggedFiles[loop].FilePath+TaggedFiles[loop].FileName;
                         bytes := _FileSize(send_file);
                         IF TaggedFiles[Loop].FreeFile=false THEN
                         BEGIN
                              INC(UserRecord.dl_total,bytes);
                              INC(UserRecord.DLBytesToday,bytes);
                              DEC(UserRecord.DLBytesRemaining,bytes);
                         END;
                         INC(UserRecord.files_downloaded);
                         bsWriteLog('Download: '+_UpperCase(TaggedFiles[loop].FileName)+
                                    ' successful ('+_String(TaggedFiles[Loop].FileCPS)+' CPS)',False);
                         {UPDATE FILE DATABASE}
                         ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
                         reset(FFileArea);
                         Seek(FFileArea,(TaggedFiles[Loop].FileArea-1));
                         read(FFileArea,FileAreas);
                         close(FFileArea);
                         ok := false;
                         ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                         RESET(FFileDefs);
                         REPEAT
                               Read(FFileDefs,FileDefs);
                               IF _UpperCase(FileDefs.file_name)=TaggedFiles[loop].FileName THEN
                               BEGIN
                                    ok := true;
                                    Seek(FFileDefs,Filepos(FFileDefs)-1);
                                    INC(FileDefs.dled);
                                    FileDefs.Last_DLed := _ProperDateNoTime;
                                    WRITE(FFileDefs,FileDefs);
                               END;
                         UNTIL ((EOF(FFileDefs)) OR (ok=true));
                         CLOSE(FFileDefs);
                    END
                    ELSE bsWriteLog('Download: '+_UpperCase(TaggedFiles[loop].FileName)+' unsuccessful',False);
               END;
               {SHOW THE DOWNLOAD STATS}
               SendCrLf(2);
               FOR loop := 1 TO TAGGED DO
               BEGIN
                    System_Prompt(TaggedFiles[loop].FileName,57,false,true);
                    IF TaggedFiles[Loop].TransferOk=true
                       THEN System_Prompt('',58,True,false)
                       ELSE System_Prompt('',59,true,false);
               END;
               IF AbortedProtocol THEN bsWriteLog('Download aborted',False)
                                  ELSE bsWriteLog('Download complete',False);
               clear_file_queue;
               SendCrLf(1);
               IF log_off=false THEN
               BEGIN
                    System_Prompt('',23,true,false);
                    Get_Enter;
               END
               ELSE
               BEGIN
                    bsWriteLog('Auto-logoff initiated',False);
                    dispatcher(1);
               END;
          END
          ELSE
          BEGIN
               IF TAGGED=0 THEN GOTO pass;
               SendCrLf(2);
               FORE(7);  WRITEANSI('Full path for local DL:  ',false,False);
               Fore(15); Get_String(40,'',true,false,true,False);
               SendCrLf(1);
               IF Input_String='' THEN GOTO pass;
               IF Input_String[LENGTH(Input_String)]='\' THEN DEC(Input_String[0]);
               _CreatePath(Input_String);
               log_off := false;
               SendCrLf(1);
               System_Prompt('',21,false,false);
               IF Get_Yes_No THEN log_off := true;
               SendCrLf(2);
               Fore(10); WRITEANSI('Copying file(s) to directory: '+input_string,False,False);
               FOR loop := 1 TO TAGGED DO
               BEGIN
                    File_Found := _CopyFile(TaggedFiles[loop].FileName,TaggedFiles[loop].FilePath,input_string);
                    IF File_Found THEN TaggedFiles[Loop].TransferOk := true;
               END;
               {UPDATE THE FILE DATABASE!}
               ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles[Loop].FileSub)+'.DAT');
               reset(FFileArea);
               Seek(FFileArea,(TaggedFiles[Loop].FileArea-1));
               read(FFileArea,FileAreas);
               close(FFileArea);
               ok := false;
               ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
               RESET(FFileDefs);
               REPEAT
                     Read(FFileDefs,FileDefs);
                     IF _UpperCase(FileDefs.file_name)=TaggedFiles[loop].FileName THEN
                     BEGIN
                          ok := true;
                          Seek(FFileDefs,Filepos(FFileDefs)-1);
                          INC(FileDefs.dled);
                          WRITE(FFileDefs,FileDefs);
                     END;
               UNTIL ((EOF(FFileDefs)) OR (ok=true));
               CLOSE(FFileDefs);
               SendCrLf(2);
               IF log_off=false THEN
               BEGIN
                    System_Prompt('',23,true,false);
                    Get_Enter;
               END
               ELSE
               BEGIN
                    bsWriteLog('Auto-logoff initiated',False);
                    dispatcher(1);
               END;
               clear_file_queue;
          END;
     END;
     pass:
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(FFileArea);
     Seek(FFileArea,(CurrentFileArea-1));
     read(FFileArea,FileAreas);
     close(FFileArea);
     CheckForCarrier;
END;


END.
