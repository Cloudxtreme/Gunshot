{$I DEFINES.INC}
UNIT NoIBM;


INTERFACE


FUNCTION Strip_Ibm(Work_String: String): String;


IMPLEMENTATION


USES MkString;


FUNCTION Strip_Ibm(Work_String: String): String;
VAR  Loop       : Byte;
BEGIN
     IF Work_String<>'' THEN
     BEGIN
          FOR Loop := 1 TO LENGTH(Work_String) DO
               IF ord(work_string[loop])>127 THEN
                  work_string[loop] := CleanChar(work_string[loop]);
          Strip_Ibm := Work_String;
     END
     ELSE Strip_Ibm := '';
END;


END.