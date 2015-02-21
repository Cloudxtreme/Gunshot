{$I DEFINES.INC}
UNIT Upload;


INTERFACE


PROCEDURE private_upload(recv_path: string);
PROCEDURE ul_file;


IMPLEMENTATION


USES Dos,XFer,BsString,Globals,BsLog,Screens,KeyInput,ApPort,ApCom,
     ErrorLog,ApTimer,Time,UlScan,Execute,ExtDos,Carrier,Yapp,BsFile;


PROCEDURE private_upload(recv_path: string);
VAR  work_it : string;
     loop    : word;
     work    : Word;
     c       : Char;
     Count   : Word;
     LABEL     private_ul_pass;
BEGIN
     _EraseFile(NODE_Directory+'\NEWFILES.$$$');
     IF Recv_Path[LENGTH(Recv_Path)]<>'\' THEN Recv_Path := Recv_Path+'\';
     {$I-}
     Chdir(_Mid(recv_path,1,LENGTH(recv_path)-1));
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          PutStringTimeout(BBSPort,#255#128#13,YappDelay);
          C := #0;
          REPEAT
                IF CharReady(BBSPort) THEN GetChar(BBSPort,c)
                                      ELSE CheckForCarrier;
          UNTIL C=#13;
          IF GetYappAck THEN
          BEGIN
               bsWriteLog('Private upload to '+recv_path,True);
               PutStringTimeout(BBSPort,#255#126#13,YappDelay);
               ReceiveFiles(Recv_path,False);
               IF AbortedProtocol THEN bsWriteLog('Upload aborted',True)
                                  ELSE bsWriteLog('Upload complete',True);
          END
          ELSE bsWriteLog('Upload aborted',True);
     END
     ELSE
     BEGIN
          DoErrorLog(20,recv_path);
          System_Prompt('',37);
          Get_Enter;
     END;
     private_ul_pass:
     Chdir(Shotgun_Directory);
     CheckForCarrier;
END;


PROCEDURE ul_file;
VAR  work_it   : string;
     loop      : word;
     temp      : string;
     Recv_Path : String;
     ULTimer   : EventTimer;
     C         : Char;
     Count     : Word;
     LABEL       pass;
BEGIN
     recv_path := HOLD_Directory+'\';
     work_it   := _Mid(recv_path,1,LENGTH(recv_path)-1);
     {$I-}
     Chdir(work_it);
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          PutStringTimeout(BBSPort,#255#128#13,YappDelay);
          C := #0;
          REPEAT
                IF CharReady(BBSPort) THEN GetChar(BBSPort,c)
                                      ELSE CheckForCarrier;
          UNTIL C=#13;
          IF GetYappAck THEN
          BEGIN
               bsWriteLog('User uploading to '+recv_path,True);
               PutStringTimeout(BBSPort,#255#126#13,YappDelay);
               NewTimerSecs(ULTimer,1440*60);
               ReceiveFiles(Recv_path,True);
               IF AbortedProtocol THEN bsWriteLog('Upload aborted',True)
                                  ELSE bsWriteLog('Upload complete',True);
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
          ELSE bsWriteLog('Upload aborted',True);
     END
     ELSE
     BEGIN
          DoErrorLog(21,recv_path);
          System_Prompt('',27);
          Get_Enter;
     END;
     pass:
     Chdir(Shotgun_Directory);
     clear_hold_dir;
     CheckForCarrier;
END;


END.