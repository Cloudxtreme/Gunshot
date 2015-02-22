{$I DEFINES.INC}
UNIT BsLog;


INTERFACE


VAR bsLogFileStarted : Boolean;
    bsLogApplication : String[40];
    bsLogNodeNumber  : Word;
    bsRunningMode    : String[20];


PROCEDURE bsSetLog(Application,RunMode: String; NodeNumber: Word);
PROCEDURE bsWriteLog(InString: String; LocalDisplay: Boolean);


IMPLEMENTATION


USES BsFile,BsString,BsTime,Crt;


PROCEDURE bsSetLog(Application,RunMode: String; NodeNumber: Word);
BEGIN
     bsLogApplication := Application;
     bsLogNodeNumber  := NodeNumber;
     bsRunningMode    := RunMode;
     _CreatePath('\SHOTGUN\LOGS');
END;


PROCEDURE bsWriteLog(InString: String; LocalDisplay: Boolean);
{$IFNDEF MSDOS}
CONST MemAvail: LongInt = 640 * 1024; // Pretend we have 640k
{$ENDIF}    
VAR  FFile : File;
     Temp  : String;

     PROCEDURE LineWrite(InStr: String);
     BEGIN
          Temp := InStr+#13#10;
          BLOCKWRITE(FFile,Temp[1],LENGTH(Temp));
          IF LocalDisplay THEN
          BEGIN
            TextColor(3);
            WRITELN(InStr);
          END;
     END;

BEGIN
     IF NOT(bsLogFileStarted) THEN
     BEGIN
       ASSIGN(FFile,'\SHOTGUN\LOGS\SHOTGUN.'+_String(bsLogNodeNumber));
       {$I-}RESET(FFile,1);{$I+}
       IF IOResult=0 THEN
       BEGIN
         SEEK(FFile,FileSize(FFile));
         LineWrite('');
       END
       ELSE REWRITE(FFile,1);
       Temp := '-------  '+bsLogApplication+' starting up: '+_DayOfWeek+' '+_GetPrettyDate+', '+_GetPrettyTime;
       IF (bsRunningMode<>'') THEN Temp := Temp+'  '+bsRunningMode;
       LineWrite(Temp);
       Temp := _PadLeft(_GetPrettyTime,7)+'  '+'Memory Available: '+_String(Trunc(MemAvail/1024))+'kb';
       LineWrite(Temp);
       bsLogFileStarted := True;
     END
     ELSE
     BEGIN
       ASSIGN(FFile,'\SHOTGUN\LOGS\SHOTGUN.'+_String(bsLogNodeNumber));
       {$I-}RESET(FFile,1);{$I+}
       IF IOResult=0 THEN SEEK(FFile,FileSize(FFile))
                     ELSE REWRITE(FFile,1);
     END;
     Temp := _PadLeft(_GetPrettyTime,7)+'  '+InString;
     LineWrite(Temp);
     CLOSE(FFile);
END;


BEGIN
     bsLogFileStarted := False;
END.
