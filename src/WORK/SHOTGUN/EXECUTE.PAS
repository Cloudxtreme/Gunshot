{$I DEFINES.INC}
UNIT Execute;


INTERFACE


FUNCTION ExecuteDosCommand(CommandLine: String): Word;
FUNCTION RUN_PROGRAM(CommandLine: String): word;


IMPLEMENTATION


USES BsExec,ErrorLog,Dos,BsString,BsFile,Globals;


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
     PPointer := DoExec(GetEnv('COMSPEC'),' /C '+CommandLine,SwappingMethod,NODE_Directory);
     IF PPointer=0 THEN PPointer := DosExitCode;
     ExecuteDOSCommand := PPointer;
END;


FUNCTION RUN_PROGRAM(CommandLine: String) : word;
VAR  PPointer           : word;
BEGIN
     ppointer := ExecuteDosCommand(CommandLine+' >NUL');
     RUN_PROGRAM := ppointer;
END;


END.