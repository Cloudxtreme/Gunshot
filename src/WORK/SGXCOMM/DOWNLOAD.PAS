{$I DEFINES.INC}
UNIT Download;


INTERFACE


PROCEDURE dl_file(send_file: string; IsNewYapp: Boolean);
PROCEDURE dl_queue;


IMPLEMENTATION


USES BsFile,BsString,BsLog,Globals,ErrorLog,Screens,KeyInput,
     XFer,ApCom,EditBtch,MiscStr,AllGone,Time,Carrier,BsTime;


PROCEDURE dl_file(send_file: string; IsNewYapp: Boolean);
VAR  Chuckie             : String;
     Work                : Word;
     LABEL                 pass;
BEGIN
     Chuckie := _NoPath(_UpperCase(Send_File));
     bsWriteLog('User downloading '+Chuckie,True);
     IF NOT(_FileExists(send_file)) THEN
     BEGIN
          DoErrorLog(22,send_file);
          bsWriteLog('File: '+Chuckie+' is missing',True);
          System_Prompt('',24);
          GET_ENTER;
          AbortedProtocol := True;
          GOTO Pass;
     END
     ELSE
     BEGIN
          FilesToSend := 1;
          FileQueueList[1] := Send_file;
          IF IsNewYapp THEN PutStringTimeout(BBSPort,#255#129+Chuckie+#13,YappDelay)
                       ELSE PutStringTimeout(BBSPort,#255#118#13,YappDelay);
          TransmitFile(send_file);
     END;
     Pass:
     IF AbortedProtocol THEN bsWriteLog('Download aborted',True)
                        ELSE bsWriteLog('Download complete',True);
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
          IF tagged=0 THEN GOTO pass;
          log_off := false;
          System_Prompt('',21);
          IF Get_Yes_No THEN log_off := true;
          IF system_info.use_cd_temp=1 THEN
          BEGIN
               FOR loop := 1 TO TAGGED DO
               BEGIN
                    IF TaggedFiles[Loop].CDRom THEN
                    BEGIN
                         System_Prompt(TaggedFiles[loop].FileName,55);
                         File_Found := _CopyFile(TaggedFiles[loop].FileName,
                                                 TaggedFiles[loop].FilePath,
                                                 CD_Directory);
                    END;
               END;
          END;
          ByPass := False;
          FilesToSend  := Tagged;
          FOR loop := 1 TO tagged DO
          BEGIN
               IF _FileExists(CD_Directory+'\'+TaggedFiles[loop].FileName)
                  THEN send_file := CD_Directory+'\'+TaggedFiles[loop].FileName
                  ELSE send_file := TaggedFiles[loop].FilePath+TaggedFiles[loop].FileName;
               FileQueueList[Loop] := Send_file;
               TaggedFiles[Loop].TransferOk   := False;
          END;
          PutStringTimeout(BBSPort,#255#118#13,YappDelay);
          TransmitFile('');
          IF AbortedProtocol THEN
          BEGIN
               IF ((LastFilesBytesSent>=TaggedFiles[CurrentFileNum].Size) AND NOT(WeAbort)) THEN
               BEGIN
                    bsWriteLog('Alert to sysop!!! Probable leach of files!!!',True);
                    bsWriteLog('File size: '+_String(TaggedFiles[CurrentFileNum].Size)+
                             '  Bytes sent: '+_String(LastFilesBytesSent),True);
                    IF DisplayGraphicFile('LEACH',False,True,True) THEN Get_Enter;
               END;
               log_off := false;
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
                             ' successful ('+_String(TaggedFiles[Loop].FileCPS)+' CPS)',True);
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
               ELSE bsWriteLog('Download: '+_UpperCase(TaggedFiles[loop].FileName)+' unsuccessful',True);
          END;
          IF AbortedProtocol THEN bsWriteLog('Download aborted',True)
                             ELSE bsWriteLog('Download complete',True);
          clear_file_queue;
          IF log_off THEN
          BEGIN
               bsWriteLog('Auto-logoff initiated',True);
               Dispatcher(1);
          END;
     END;
     pass:
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,(CurrentFileArea-1));
     READ(FFileArea,FileAreas);
     CLOSE(FFileArea);
     CheckForCarrier;
END;


END.