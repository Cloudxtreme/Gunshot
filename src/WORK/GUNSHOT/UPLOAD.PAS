{$I DEFINES.INC}
UNIT Upload;


INTERFACE


PROCEDURE private_upload(recv_path: string);
PROCEDURE ul_file;


IMPLEMENTATION


USES Dos,XFer,ANSIMisc,Globals,GetProto,BsLog,Screens,KeyInput,
     ErrorLog,ApTimer,Time,UlScan,Execute,ExtDos,Carrier,BsFile,
     BsString;


PROCEDURE private_upload(recv_path: string);
VAR  work_it             : string;
     loop                : word;
     work                : Word;
     DirInfo             : SearchRec;
     TFile2              : Text;
     FileName            : String;
     LABEL                 private_ul_pass;
BEGIN
     _EraseFile(NODE_Directory+'\NEWFILES.$$$');
     SendCrLf(1);
     IF Recv_Path[LENGTH(Recv_Path)]<>'\' THEN Recv_Path := Recv_Path+'\';
     {$I-}
     Chdir(_Mid(recv_path,1,LENGTH(recv_path)-1));
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          IF NOT(LocalLogon) THEN
          BEGIN
               IF ((UserRecord.DefaultProtocol<1) OR (UserRecord.DefaultProtocol>5)) THEN
               BEGIN
                    select_protocol;
                    IF protocol=255 THEN GOTO private_ul_pass;
               END
               ELSE Protocol := UserRecord.DefaultProtocol;
               bsWriteLog('Private upload to '+recv_path,False);
               IF ((protocol=2) OR (protocol=3)) THEN
               BEGIN
                    SendCrLf(2);
                    System_Prompt('',26,false,true);
                    Get_String(12,'',true,false,true,False);
                    SendCrLf(1);
                    Work_It := input_string;
                    IF work_it='' THEN GOTO private_ul_pass;
                    recv_path := recv_path+work_it;
               END;
               ClrPortScr;
               CASE protocol OF
               1:   System_Prompt('',14,true,false);
               2:   System_Prompt('',10,true,false);
               3:   System_Prompt('',11,true,false);
               4:   System_Prompt('',12,true,false);
               5:   System_Prompt('',13,true,false);
               END;
               System_Prompt('',22,true,false);
               SendCrLf(1);
               ReceiveFiles(Recv_path,Protocol,False);
               IF AbortedProtocol THEN bsWriteLog('Upload aborted',False)
                                  ELSE bsWriteLog('Upload complete',False);
          END
          ELSE
          BEGIN
               SendCrLf(1);
               FORE(7);  WRITEANSI('Full path & filename of local UL:  ',false,False);
               FORE(15); Get_String(40,'',true,false,true,False);
               SendCrLf(1);
               work_it := input_string;
               IF work_it='' THEN GOTO private_ul_pass;
               IF recv_path[LENGTH(recv_path)]='\' THEN Delete(recv_path,LENGTH(recv_path),1);
               SendCrLf(1);
               Fore(10); WRITEANSI('Copying file(s) to upload directory.',False,False);
               FindFirst(Work_It,Anyfile-Directory-VolumeID,DirInfo);
               WHILE DosError = 0 DO
               BEGIN
                    FileName := _GetFilePath(Work_It)+DirInfo.Name;
                    IF _CopyFile(_NoPath(FileName),_GetFilePath(FileName),recv_path) THEN
                    BEGIN
                         ASSIGN(TFile2,NODE_Directory+'\NEWFILES.$$$');
                         {$I-}APPEND(TFile2);{$I+}
                         IF IOResult<>0 THEN REWRITE(TFile2);
                         WRITELN(TFile2,_PadRight(_NoPath(FileName),14)+
                                        _PadLeft(_String(_FileSize(recv_path+'\'+_NoPath(FileName))),9));
                         CLOSE(TFile2);
                    END;
                    FindNext(DirInfo);
               END;
               SendCrLf(2);
          END;
     END
     ELSE
     BEGIN
          DoErrorLog(20,recv_path);
          System_Prompt('',37,true,false);
          Get_Enter;
     END;
     private_ul_pass:
     Chdir(Gunshot_Directory);
     CheckForCarrier;
END;


PROCEDURE ul_file;
VAR  work_it             : string;
     loop                : word;
     temp                : string;
     Recv_Path           : String;
     ULTimer             : EventTimer;
     LABEL                 pass;
BEGIN
     SendCrLf(1);
     recv_path := HOLD_Directory+'\';
     work_it   := _Mid(recv_path,1,LENGTH(recv_path)-1);
     {$I-}
     Chdir(work_it);
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          IF NOT(LocalLogon) THEN
          BEGIN
               IF ((UserRecord.DefaultProtocol<1) OR (UserRecord.DefaultProtocol>5)) THEN
               BEGIN
                    select_protocol;
                    IF protocol=255 THEN GOTO Pass;
               END
               ELSE Protocol := UserRecord.DefaultProtocol;
               bsWriteLog('User uploading to '+recv_path,False);
               IF ((protocol=2) OR (protocol=3)) THEN
               BEGIN
                    SendCrLf(2);
                    System_Prompt('',26,false,true);
                    Get_String(12,'',true,false,true,False);
                    SendCrLf(1);
                    Work_It := input_string;
                    IF work_it='' THEN GOTO pass;
                    recv_path := recv_path+work_it;
               END;
               ClrPortScr;
               CASE protocol OF
               1:   System_Prompt('',14,true,false);
               2:   System_Prompt('',10,true,false);
               3:   System_Prompt('',11,true,false);
               4:   System_Prompt('',12,true,false);
               5:   System_Prompt('',13,true,false);
               END;
               System_Prompt('',22,true,false);
               SendCrLf(1);
               NewTimerSecs(ULTimer,1440*60);
               ReceiveFiles(Recv_path,Protocol,True);
               IF AbortedProtocol THEN bsWriteLog('Upload aborted',False)
                                  ELSE bsWriteLog('Upload complete',False);
               IF FileTransferSuccess THEN
               BEGIN
                    IF (UserAccess.Ul_Credit<>0) THEN
                    BEGIN
                         AdjustUsersTime(True,Round((ElapsedTimeInSecs(ULTimer)*UserAccess.Ul_Credit)/100));
                         scan_uploads;
                    END
                    ELSE scan_uploads;
               END;
          END
          ELSE
          BEGIN
               SendCrLf(1);
               FORE(7);  WRITEANSI('Full path & filename of local UL:  ',false,False);
               Fore(15); Get_String(40,'',true,false,true,False);
               SendCrLf(1);
               work_it := input_string;
               IF work_it='' THEN GOTO PASS;
               IF recv_path[LENGTH(recv_path)]='\' THEN Delete(recv_path,LENGTH(recv_path),1);
               SendCrLf(1);
               Fore(10); WRITEANSI('Copying file(s) to upload directory.',False,False);
               ExecuteDosCommand('COPY '+work_it+' '+recv_path+' >NUL');
               SendCrLf(2);
               scan_uploads;
          END;
     END
     ELSE
     BEGIN
          DoErrorLog(21,recv_path);
          System_Prompt('',27,true,false);
          Get_Enter;
     END;
     pass:
     Chdir(Gunshot_Directory);
     clear_hold_dir;
     CheckForCarrier;
END;


END.