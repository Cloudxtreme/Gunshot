{$I DEFINES.INC}
UNIT LogFile;


INTERFACE


PROCEDURE WriteLogFile(InString: String);
PROCEDURE FinishLogFile;


IMPLEMENTATION


USES Globals,BsString,Version,BsTime,FastW1,Status,ApTimer,BsVideo,KeyCheck,BsLog;


PROCEDURE Get(x1,y1,x2,y2: Word);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     GetPut1.NumLines := y2-y1+1;
     Count := 1;
     FOR Loop := y1 TO y2 DO
     BEGIN
       GetPut1.Lines[Count].LineLength := x2-x1+1;
{$IFDEF MSDOS}
       Move(MEM[SegB800:(((Loop-1)*160)+((x1-1)*2))],GetPut1.Lines[Count].Line,(x2-x1+1)*2);
{$ENDIF}
{$IFNDEF MSDOS}
  WriteLn('REEPORT LOGFILE Get'); Halt;
{$ENDIF}
       INC(Count);
     END;
END;


PROCEDURE Put(x,y: Word);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     Count := 1;
     FOR Loop := y TO (y+GetPut1.NumLines-1) DO
     BEGIN
{$IFDEF MSDOS}
       Move(GetPut1.Lines[Count].Line,MEM[SegB800:(((Loop-1)*160)+((x-1)*2))],(GetPut1.Lines[Count].LineLength)*2);
{$ENDIF}
{$IFNDEF MSDOS}
  WriteLn('REEPORT LOGFILE Put'); Halt;
{$ENDIF}
       INC(Count);
     END;
END;


PROCEDURE WriteLogFile(InString: String);
VAR  Temp : String;
BEGIN
     bsWriteLog(InString,False);
     Temp := _PadLeft(_GetPrettyTime,7)+'  '+InString;
     IF MainScreenActive THEN
     BEGIN
       Get(4,19,76,23);
       Put(4,18);
       FastWrite(_PadRight(' '+Temp,73),23,4,7);
     END;
END;


PROCEDURE FinishLogFile;
BEGIN
     MainScreenActive := False;
     bsWriteLog('旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커',False);
     bsWriteLog('  Inbound Files  ['+_PadRight(_String(RunningInFiles),10)+']',False);
     bsWriteLog('  Inbound Bytes  ['+_PadRight(_String(RunningInbound),10)+']',False);
     bsWriteLog('  Outbound Files ['+_PadRight(_String(RunningOutTics),10)+']',False);
     bsWriteLog('  Stored Bytes   ['+_PadRight(_String(RunningStored),10)+']',False);
     bsWriteLog('  Areafix Msgs   ['+_PadRight(_String(RunningAFix),10)+']',False);
     bsWriteLog('  Process Time   ['+_PadRight(FormatMinSec(ElapsedTimeInSecs(BigTimer)),10)+']',False);
     bsWriteLog('읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸',False);
     bsWriteLog('End Run.',False);
END;


END.