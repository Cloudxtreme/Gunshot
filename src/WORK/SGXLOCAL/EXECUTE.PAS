{$I DEFINES.INC}
UNIT Execute;


INTERFACE


FUNCTION ExecuteDosCommand (CommandLine: String)            : Word;
FUNCTION RUN_PROGRAM       (CommandLine: String)            : word;


IMPLEMENTATION


USES Dos,ErrorLog,_Save,BsString,BsFile;


FUNCTION ExecuteDosCommand(CommandLine: String): Word;
VAR  PPointer   : Word;
     Executable : String;
     Work       : Word;
BEGIN
     Executable := _UpperCase(CommandLine);
     Work := Pos(' ',Executable);
     IF Work<>0 THEN Executable := _Mid(Executable,1,Work-1);
     IF ((Executable<>'COMMAND.COM') AND (Executable<>'COPY')) THEN
     BEGIN
          IF NOT(_FileExists(Executable)) THEN DoErrorLog(15,Executable);
     END;
     SwapVectors;
     Exec(GetEnv('COMSPEC'),' /C '+CommandLine);
     SwapVectors;
     ExecuteDOSCommand := DosExitCode;
END;


FUNCTION RUN_PROGRAM(CommandLine: String): word;
VAR  pointer      : word;
BEGIN
     Save_Mouse;
     pointer := ExecuteDOSCommand(CommandLine+' >NUL');
     Load_Mouse;
     RUN_PROGRAM  := pointer;
END;


END.
