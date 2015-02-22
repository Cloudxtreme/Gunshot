{$I DEFINES.INC}
UNIT DosDoor;


INTERFACE


PROCEDURE dos_door(CommandPath,CommandLine: string; Busy,NameType,BaudType: byte);
PROCEDURE svga_door(CommandPath,CommandLine: string; Busy: Byte);


IMPLEMENTATION


USES BsLog,Screens,KeyInput,Crt,ErrorLog,Status,Globals,
     DoorFile,Reload,Execute,_Buffers,BsString,BsFile;


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
     bsWriteLog('Running DOS door: '+CommandPath+CommandLine,False);
     IF _FileExists(CommandPath+BusyFile) THEN
     BEGIN
          bsWriteLog('Door is in use ['+BusyFile+']',False);
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
               Work_It := _Mid(CommandPath,1,LENGTH(CommandPath)-1);
               Chdir(Work_It);
               Save_Screen;
               DumpUser;
               ExecuteDosCommand(CommandPath+CommandLine);
               Chdir(Shotgun_Directory);
               bsWriteLog('Returned from door',False);
               IF Busy=1 THEN _EraseFile(CommandPath+BusyFile);
               Load_Screen;
               ReloadUser;
          END
          ELSE DoErrorLog(36,CommandPath+Work_It);
     END;
END;


PROCEDURE svga_door(CommandPath,CommandLine: string; Busy: Byte);
VAR  work_it    : String;
     Work       : Word;
     InUse      : File;
     BusyFile   : String;
BEGIN
     Work := Pos(' ',CommandLine);
     IF Work<>0 THEN Work_It := _Mid(CommandLine,1,Work-1)
                ELSE Work_It := CommandLine;
     BusyFile := _NoExtension(Work_It)+'.BSY';
     bsWriteLog('Running SVGA door: '+CommandPath+CommandLine,False);
     IF _FileExists(CommandPath+BusyFile) THEN
     BEGIN
          bsWriteLog('Door is in use ['+BusyFile+']',False);
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
               make_door_files(0,0);
               Work_It := _Mid(CommandPath,1,LENGTH(CommandPath)-1);
               Chdir(Work_It);
               Save_Screen;
               DumpUser;
               ExecuteDosCommand(CommandPath+CommandLine);
               Chdir(Shotgun_Directory);
               bsWriteLog('Returned from door',False);
               IF Busy=1 THEN _EraseFile(CommandPath+BusyFile);
               Load_Screen;
               ReloadUser;
          END
          ELSE DoErrorLog(36,CommandPath+Work_It);
     END;
END;


END.
