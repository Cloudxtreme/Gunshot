{$I DEFINES.INC}
UNIT Upload;


INTERFACE


PROCEDURE private_upload(recv_path: string);
PROCEDURE ul_file;


IMPLEMENTATION


USES Selectr,BsGraph,SBuffer,KeyInput,UlScan,BsFile,
     Screens,Globals,ErrorLog,ApTimer,ExtDos,BsString;


PROCEDURE private_upload(recv_path: string);
VAR  work_it : string;
     loop    : word;
     work    : Word;
     TFile   : Text;
     Temp    : String;
     TFile2  : Text;
     LABEL     private_ul_pass;
BEGIN
     _EraseFile(NODE_Directory+'\NEWFILES.$$$');
     IF Recv_Path[LENGTH(Recv_Path)]<>'\' THEN Recv_Path := Recv_Path+'\';
     {$I-}
     Chdir(_Mid(recv_path,1,LENGTH(recv_path)-1));
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          IF DoFileQueue THEN
          BEGIN
               IF recv_path[LENGTH(recv_path)]='\' THEN Delete(recv_path,LENGTH(recv_path),1);
               ASSIGN(TFile,NODE_Directory+'\ULQUEUE.LST');
               RESET(TFile);
               REPEAT
                     READLN(TFile,Temp);
                     ClearBuffer;
                     AddToBuffer('@INSERT',Temp);
                     DisplayGraphicFile('LUL2',True,True,True);
                     _CopyFile(_NoPath(Temp),_GetFilePath(Temp),recv_path);
                     ASSIGN(TFile2,NODE_Directory+'\NEWFILES.$$$');
                     {$I-}APPEND(TFile2);{$I+}
                     IF IOResult<>0 THEN REWRITE(TFile2);
                     WRITELN(TFile2,_PadRight(_NoPath(Temp),14)+
                                    _PadLeft(_String(_FileSize(recv_path+'\'+_NoPath(Temp))),9));
                     CLOSE(TFile2);
               UNTIL EOF(TFile);
               CLOSE(TFile);
          END
          ELSE
          BEGIN
               AbortedProtocol := True;
               GOTO private_ul_pass;
          END;
     END
     ELSE
     BEGIN
          DoErrorLog(20,recv_path);
          System_Prompt('',37);
          Get_Enter;
     END;
     private_ul_pass:
     Chdir(Gunshot_Directory);
END;


PROCEDURE ul_file;
VAR  work_it   : string;
     loop      : word;
     temp      : string;
     Recv_Path : String;
     ULTimer   : EventTimer;
     TFile     : Text;
     LABEL       pass;
BEGIN
     recv_path := HOLD_Directory+'\';
     work_it   := _Mid(recv_path,1,LENGTH(recv_path)-1);
     {$I-}
     Chdir(work_it);
     {$I+}
     IF IoResult=0 THEN
     BEGIN
          IF DoFileQueue THEN
          BEGIN
               IF recv_path[LENGTH(recv_path)]='\' THEN Delete(recv_path,LENGTH(recv_path),1);
               ASSIGN(TFile,NODE_Directory+'\ULQUEUE.LST');
               RESET(TFile);
               REPEAT
                     READLN(TFile,Temp);
                     ClearBuffer;
                     AddToBuffer('@INSERT',Temp);
                     DisplayGraphicFile('LUL2',True,True,True);
                     _CopyFile(_NoPath(Temp),_GetFilePath(Temp),recv_path);
               UNTIL EOF(TFile);
               CLOSE(TFile);
               ERASE(TFile);
               scan_uploads;
          END
          ELSE
          BEGIN
               AbortedProtocol := True;
               GOTO PASS;
          END;
     END
     ELSE
     BEGIN
          DoErrorLog(21,recv_path);
          System_Prompt('',27);
          Get_Enter;
     END;
     pass:
     Chdir(Gunshot_Directory);
     clear_hold_dir;
END;


END.
