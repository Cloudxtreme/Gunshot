{$I DEFINES.INC}
UNIT Status;


INTERFACE


PROCEDURE status_line;


IMPLEMENTATION


USES ErrorLog,BsString;


PROCEDURE status_line;
VAR  TheMem : Longint;
BEGIN
     IF IOResult=0 THEN;
     TheMem := MemAvail;
     IF TheMem<640000 THEN DoErrorLog(35,_String(TheMem));
END;


END.