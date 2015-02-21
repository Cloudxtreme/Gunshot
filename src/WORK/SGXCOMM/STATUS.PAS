{$I DEFINES.INC}
UNIT Status;


INTERFACE


PROCEDURE status_line;


IMPLEMENTATION


USES BsVideo,BsString,Globals,Time,ErrorLog,ApCom;


PROCEDURE status_line;
VAR  TheMem : Longint;
BEGIN
     IF IOResult=0 THEN;
     FastWrite('  USR:                                     S:       T:      B:        M:        ',25,1,27);
     IF NOT(doing_logon) THEN
     BEGIN
          FastWrite(_PadRight(UserRecord.Name,30),25,8,31);
          IF sysop_next THEN FastWrite('!SN!',25,39,30)
                        ELSE FastWrite('    ',25,39,30);
          IF User_Paged THEN FastWrite(#14,25,1,31)
                        ELSE FastWrite(#32,25,1,31);
          FastWrite(_PadRight(_String(UserRecord.security),5),25,47,31);
          FastWrite(_PadRight(_String(MinutesRemaining),4),25,56,31);
          FastWrite(_PadRight(BAUDString,6),25,64,31);
          TheMem := MemAvail;
          IF TheMem<70000 THEN DoErrorLog(35,_String(TheMem));
          FastWrite(_PadRight(_String(TheMem),6),25,74,31);
     END;
     IF NOT(CheckDCD(BBSPort)) THEN FastWrite('NO DCD',25,64,31);
END;


END.
