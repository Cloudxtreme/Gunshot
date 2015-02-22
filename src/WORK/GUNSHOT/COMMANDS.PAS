{$I DEFINES.INC}
UNIT Commands;


INTERFACE


FUNCTION  GetCommandKeyPress (Screen: String; Index: Word): Char;
FUNCTION  GetCommandString   (Screen: String; Index: Word): String;
PROCEDURE DoCommandString    (Screen: String; Index: Word);


IMPLEMENTATION


USES Globals,ANSIMisc,Shotgun;


FUNCTION GetCommandKeyPress(Screen: String; Index: Word): Char;
VAR  FCommandFile : File Of _Command;
     CommandFile  : _Command;
BEGIN
     ASSIGN(FCommandFile,LANG_Directory+'\'+Screen+'.CMD');
     {$I-}RESET(FCommandFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          SEEK(FCommandFile,Index-1);
          READ(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
          GetCommandKeyPress := CommandFile.KeyPress;
     END
     ELSE GetCommandKeyPress := #13;
END;


PROCEDURE DoCommandString(Screen: String; Index: Word);
VAR  FCommandFile : File Of _Command;
     CommandFile  : _Command;
BEGIN
     ASSIGN(FCommandFile,LANG_Directory+'\'+Screen+'.CMD');
     {$I-}RESET(FCommandFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          SEEK(FCommandFile,Index-1);
          READ(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
          WriteAnsi(CommandFile.ANSIString+' ',False,True);
     END;
END;


FUNCTION GetCommandString(Screen: String; Index: Word): String;
VAR  FCommandFile : File Of _Command;
     CommandFile  : _Command;
BEGIN
     ASSIGN(FCommandFile,LANG_Directory+'\'+Screen+'.CMD');
     {$I-}RESET(FCommandFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          SEEK(FCommandFile,Index-1);
          READ(FCommandFile,CommandFile);
          CLOSE(FCommandFile);
          GetCommandString := CommandFile.ANSIString;
     END
     ELSE GetCommandString := '';
END;


END.