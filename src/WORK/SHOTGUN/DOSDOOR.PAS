{$I DEFINES.INC}
UNIT DosDoor;


INTERFACE


PROCEDURE dos_door(CommandPath,CommandLine: string; Busy,NameType,BaudType: byte);


IMPLEMENTATION


USES BsLog,Screens,ANSIMisc,KeyInput,Comm,Crt,ErrorLog,Status,
     Globals,DoorFile,Reload,Execute,BsString,BsFile;


PROCEDURE dos_door(CommandPath,CommandLine: string; Busy,NameType,BaudType: byte);
VAR  work_it    : string;
     Work       : Word;
     InUse      : File;
     BusyFile   : String;
BEGIN
     Work := Pos(' ',CommandLine);
     IF Work<>0 THEN Work_It := _Mid(CommandLine,1,Work-1)
                ELSE Work_It := CommandLine;
     BusyFile := _NoExtension(Work_It)+'.BSY';
     bsWriteLog('Running DOS door: '+CommandPath+CommandLine,False);
     IF _FileExists(CommandPath+BusyFile) THEN
     BEGIN
          bsWriteLog('Door is in use ['+BusyFile+']',False);
          SendCrLf(2);
          DisplayGraphicsFile('DOORUSED',True,False,True,True,False);
          Get_Enter;
     END
     ELSE
     BEGIN
          IF _FileExists(CommandPath+Work_It) THEN
          BEGIN
               IF Busy=1 THEN
               BEGIN
                    ASSIGN(InUse,CommandPath+BusyFile);
                    REWRITE(InUse);
                    CLOSE(InUse);
               END;
               make_door_files(NameType,BaudType);
               IF IsRip THEN ResetRip;
               ClrPortScr;
               Window(1,1,80,25);
               TextBackground(0);
               TextColor(7);
               ClrScr;
               Work_It := _Mid(CommandPath,1,LENGTH(CommandPath)-1);
               Chdir(Work_It);
               IF NOT(LocalLogon) THEN Comm_DeInit;
               DumpUser;
               ExecuteDosCommand(CommandPath+CommandLine);
               Chdir(Shotgun_Directory);
               bsWriteLog('Returned from door',False);
               IF Busy=1 THEN _EraseFile(CommandPath+BusyFile);
               IF NOT(LocalLogon) THEN
               BEGIN
                    IF NOT(Comm_Init(NodeInfo.ComPort,NodeInfo.ComDevice)) THEN
                    BEGIN
                         DoErrorLog(14,_String(NodeInfo.ComPort));
                         ClrScr;
                         WRITELN('Cannot initialize port!!!!');
                         WRITELN('Shotgun is shutting down.');
                         WRITELN;
                         Halt;
                    END;
               END;
               ReloadUser;
               Window(1,1,80,24);
               TextBackground(0);
               TextColor(7);
               ClrScr;
               Fore(7);
               Back(0);
               ClrPortScr;
               Status_Line;
          END
          ELSE DoErrorLog(36,CommandPath+Work_It);
     END;
END;


END.
