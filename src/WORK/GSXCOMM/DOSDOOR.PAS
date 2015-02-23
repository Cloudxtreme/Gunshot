{$I DEFINES.INC}
UNIT DosDoor;


INTERFACE


PROCEDURE dos_door(CommandPath,CommandLine: string; Busy,NameType,BaudType: byte);
PROCEDURE svga_door(CommandPath,CommandLine: string; Busy: byte);


IMPLEMENTATION


USES BsLog,Screens,KeyInput,Comm,Crt,ErrorLog,Status,Globals,
     DoorFile,Reload,Execute,Yapp,Gfx,ApPort,ApCom,SaveScrn,
     BsString,BsFile;


PROCEDURE dos_door(CommandPath,CommandLine: string; Busy,NameType,BaudType: byte);
VAR  work_it    : String;
     Work       : Word;
     InUse      : File;
     BusyFile   : String;
BEGIN
     Work := Pos(' ',CommandLine);
     IF Work<>0 THEN Work_It := _Mid(CommandLine,1,Work-1)
                ELSE Work_It := CommandLine;
     BusyFile := _NoExtension(Work_It)+'.BSY';
     bsWriteLog('Running DOS door: '+CommandPath+CommandLine,True);
     IF _FileExists(CommandPath+BusyFile) THEN
     BEGIN
          bsWriteLog('Door is in use ['+BusyFile+']',True);
          IF DisplayGraphicFile('DOORUSED',False,True,True) THEN Get_Enter;
     END
     ELSE
     BEGIN
          IF _FileExists(CommandPath+Work_It) THEN
          BEGIN
               DOOR_EXECUTED := True;
               IF Busy=1 THEN
               BEGIN
                    ASSIGN(InUse,CommandPath+BusyFile);
                    REWRITE(InUse);
                    CLOSE(InUse);
               END;
               make_door_files(NameType,BaudType);
               PutStringTimeout(BBSPort,#255#120#13,YappDelay);
               IF GetYAPPAck THEN
               BEGIN
                    Work_It := _Mid(CommandPath,1,LENGTH(CommandPath)-1);
                    Chdir(Work_It);
                    Comm_DeInit;
                    Save_Screen2;
                    Window(1,1,80,25);
                    TextColor(7);
                    TextBackground(0);
                    ClrScr;
                    DumpUser;
                    ExecuteDosCommand(CommandPath+CommandLine);
                    Chdir(Gunshot_Directory);
                    Window(1,1,80,24);
                    TextColor(7);
                    TextBackground(0);
                    Restore_Screen2;
                    bsWriteLog('Returned from door',True);
                    IF Busy=1 THEN _EraseFile(CommandPath+BusyFile);
                    IF NOT(Comm_Init(NodeInfo.ComPort,NodeInfo.ComDevice)) THEN
                    BEGIN
                         TextMode(co80);
                         DoErrorLog(14,_String(NodeInfo.ComPort));
                         ClrScr;
                         WRITELN('Cannot initialize port!!!!');
                         WRITELN('Gunshot is shutting down.');
                         WRITELN;
                         Halt;
                    END;
                    PutStringTimeout(BBSPort,#255#121#13,YappDelay);
                    IF NOT(GetYAPPAck) THEN
                    BEGIN
                         bsWriteLog('Graphics session lost on return',True);
                         Halt;
                    END;
                    ReloadUser;
               END;
          END
          ELSE DoErrorLog(36,CommandPath+Work_It);
     END;
END;


PROCEDURE svga_door(CommandPath,CommandLine: string; Busy: byte);
VAR  work_it    : String;
     Work       : Word;
     InUse      : File;
     BusyFile   : String;
BEGIN
     Work := Pos(' ',CommandLine);
     IF Work<>0 THEN Work_It := _Mid(CommandLine,1,Work-1)
                ELSE Work_It := CommandLine;
     BusyFile := _NoExtension(Work_It)+'.BSY';
     bsWriteLog('Running SVGA door: '+CommandPath+CommandLine,True);
     IF _FileExists(CommandPath+BusyFile) THEN
     BEGIN
          bsWriteLog('Door is in use ['+BusyFile+']',True);
          IF DisplayGraphicFile('DOORUSED',False,True,True) THEN Get_Enter;
     END
     ELSE
     BEGIN
          IF _FileExists(CommandPath+Work_It) THEN
          BEGIN
               DOOR_EXECUTED := True;
               IF Busy=1 THEN
               BEGIN
                    ASSIGN(InUse,CommandPath+BusyFile);
                    REWRITE(InUse);
                    CLOSE(InUse);
               END;
               PutStringTimeout(BBSPort,#255#139#13,YappDelay);
               make_door_files(0,0);
               Work_It := _Mid(CommandPath,1,LENGTH(CommandPath)-1);
               Chdir(Work_It);
               Comm_DeInit;
               Save_Screen2;
               Window(1,1,80,25);
               TextColor(7);
               TextBackground(0);
               ClrScr;
               DumpUser;
               ExecuteDosCommand(CommandPath+CommandLine);
               Chdir(Gunshot_Directory);
               Window(1,1,80,24);
               TextColor(7);
               TextBackground(0);
               Restore_Screen2;
               bsWriteLog('Returned from door',True);
               IF Busy=1 THEN _EraseFile(CommandPath+BusyFile);
               IF NOT(Comm_Init(NodeInfo.ComPort,NodeInfo.ComDevice)) THEN
               BEGIN
                    TextMode(co80);
                    DoErrorLog(14,_String(NodeInfo.ComPort));
                    ClrScr;
                    WRITELN('Cannot initialize port!!!!');
                    WRITELN('Gunshot is shutting down.');
                    WRITELN;
                    Halt;
               END;
               ReloadUser;
          END
          ELSE DoErrorLog(36,CommandPath+Work_It);
     END;
END;


END.