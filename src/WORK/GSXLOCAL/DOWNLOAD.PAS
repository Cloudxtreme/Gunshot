{$I DEFINES.INC}
UNIT DownLoad;


INTERFACE


PROCEDURE dl_file(send_file: string);
PROCEDURE dl_queue;


IMPLEMENTATION


USES Globals,Screens,SBuffer,_Mouse,BsLog,AllGone,BsTime,
     EditBtch,KeyInput,MiscStr,Time,BsFile,BsString;


PROCEDURE dl_file(send_file: string);
VAR  Chuckie             : String;
     Work                : Word;
     LABEL                 pass;
BEGIN
     AbortedProtocol := False;
     IF FixedDLPath='' THEN
     BEGIN
          IF DisplayGraphicFile('LDL1',False,True,True) THEN Get_Enter;
          IF Fields^[1].Text='' THEN
          BEGIN
               AbortedProtocol := True;
               GOTO pass;
          END;
          FixedDLPath := Fields^[1].Text;
          IF FixedDLPath[LENGTH(FixedDLPath)]='\' THEN DEC(FixedDLPath[0]);
          _CreatePath(FixedDLPath);
     END;
     ClearBuffer;
     AddToBuffer('@INSERT',_UpperCase(FixedDLPath));
     DisplayGraphicFile('LDL2',True,True,True);
     ChangeMouse(BusyMouse);
     _CopyFile(_NoPath(send_file),_GetFilePath(send_file),FixedDLPath);
     ChangeMouse(DefaultMouse);
     pass:
     IF AbortedProtocol THEN bsWriteLog('Download aborted',False)
                        ELSE bsWriteLog('Download complete',False);
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
          IF TAGGED=0 THEN GOTO pass;
          IF FixedDLPath='' THEN
          BEGIN
               IF DisplayGraphicFile('LDL1',False,True,True) THEN Get_Enter;
               IF Fields^[1].Text='' THEN GOTO pass;
               FixedDLPath := Fields^[1].Text;
               IF FixedDLPath[LENGTH(FixedDLPath)]='\' THEN DEC(FixedDLPath[0]);
               _CreatePath(FixedDLPath);
          END;
          log_off := false;
          System_Prompt('',21);
          IF Get_Yes_No THEN log_off := true;
          ClearBuffer;
          AddToBuffer('@INSERT',_UpperCase(FixedDLPath));
          DisplayGraphicFile('LDL2',True,True,True);
          ChangeMouse(BusyMouse);
          FOR loop := 1 TO TAGGED DO
          BEGIN
               File_Found := _CopyFile(TaggedFiles^[loop].FileName,TaggedFiles^[loop].FilePath,FixedDLPath);
               IF File_Found THEN TaggedFiles^[Loop].TransferOk := true;
          END;
          ChangeMouse(DefaultMouse);
          {UPDATE THE FILE DATABASE!}
          ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(TaggedFiles^[Loop].FileSub)+'.DAT');
          RESET(FFileArea);
          SEEK(FFileArea,(TaggedFiles^[Loop].FileArea-1));
          READ(FFileArea,FileAreas);
          CLOSE(FFileArea);
          ok := false;
          ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
          RESET(FFileDefs);
          REPEAT
                Read(FFileDefs,FileDefs^);
                IF _UpperCase(FileDefs^.file_name)=TaggedFiles^[loop].FileName THEN
                BEGIN
                     ok := true;
                     Seek(FFileDefs,Filepos(FFileDefs)-1);
                     INC(FileDefs^.dled);
                     FileDefs^.Last_DLed := _ProperDateNoTime;
                     WRITE(FFileDefs,FileDefs^);
                END;
          UNTIL ((EOF(FFileDefs)) OR (ok=true));
          CLOSE(FFileDefs);
          IF log_off THEN
          BEGIN
               bsWriteLog('Auto-logoff initiated',False);
               dispatch(1);
          END;
          clear_file_queue;
     END;
     pass:
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     SEEK(FFileArea,(CurrentFileArea-1));
     READ(FFileArea,FileAreas);
     CLOSE(FFileArea);
END;


END.
