{$I DEFINES.INC}
UNIT Status;


INTERFACE


PROCEDURE UpdateScreenInfo(WhichTic: Word);
PROCEDURE DrawStartingStatus;
PROCEDURE DrawTicStatus;
PROCEDURE ClearTicStatus;
PROCEDURE RestoreScreen;
PROCEDURE SaveScreen;


IMPLEMENTATION


USES {$IFNDEF MSDOS}VideoUtils,{$ENDIF}Globals,FastW1,Crt,Dos,BsString,LogFile,BsFile,BsAkas,ApTimer,BsTime,BsVideo;


PROCEDURE SaveScreen;
BEGIN
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SavedScreen,4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenSave(SavedScreen);
{$ENDIF}
     WhereXYAbs(SavedScreenXY);
     TextBackGround(0);
     TextColor(7);
     ClrScr;
END;


PROCEDURE RestoreScreen;
BEGIN
{$IFDEF MSDOS}
     Move(SavedScreen,MEM[SegB800:0],4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenRestore(SavedScreen);
{$ENDIF}
     GotoXYAbs(SavedScreenXY);
END;


PROCEDURE DrawStartingStatus;
{$IFNDEF MSDOS}
CONST MemAvail: LongInt = 640 * 1024; // Pretend we have 640k
{$ENDIF}    
VAR  Temp  : String;
     DFree : Longint;
BEGIN
     DFree := Round(DiskFree(0)/1024000);
     Temp := _String(DFree)+'mb';
     FastWrite(Temp,8,70,31);
     FastWrite(_String(MemAvail),9,70,31);
     FastWrite(_String(NumberOfTics),10,70,31);
     FastWrite(_String(RunningAFix),13,70,31);
     IF (DFree<5) THEN WriteLogFile('!!! WARNING - LESS THAN 5 MB ON PROCESSING DRIVE !!!');
END;


PROCEDURE DrawTicStatus;
BEGIN
     FastWrite(_PadRight(CurrentTicFile,12),9,6,10);
     FastWrite(_PadRight(TicFile.AreaTag,12),10,6,10);
     FastWrite(_PadRight(TicFile.FileName,12),11,6,10);
     FastWrite(_PadRight(_String(Round(_FileSize(Mailer.Inbound+TicFile.FileName)/1024))+'kb',12),12,6,10);
     FastWrite(_PadRight(AddressToString(TicFile.AkaFrom),12),13,6,10);
     FastWrite(_PadRight(TicFile.Password,12),14,6,10);
END;


PROCEDURE ClearTicStatus;
BEGIN
     FastWrite(_PadRight('',12),9,6,10);
     FastWrite(_PadRight('',12),10,6,10);
     FastWrite(_PadRight('',12),11,6,10);
     FastWrite(_PadRight('',12),12,6,10);
     FastWrite(_PadRight('',12),13,6,10);
     FastWrite(_PadRight('',12),14,6,10);
     FastWrite(' ',9,37,8);
     FastWrite(' ',10,37,8);
     FastWrite(' ',11,37,8);
     FastWrite(' ',12,37,8);
     FastWrite(' ',13,37,8);
     FastWrite(' ',14,37,8);
END;


PROCEDURE UpdateScreenInfo(WhichTic: Word);
BEGIN
     FastWrite(_PadRight(_String(Round(DiskFree(0)/1024000))+'mb',7),8,70,31);
     FastWrite(_PadRight(_String(WhichTic),7),11,70,31);
     FastWrite(_PadRight(_String(RunningOutTics),7),12,70,31);
     FastWrite(_PadRight(FormatMinSec(ElapsedTimeInSecs(BigTimer)),7),14,70,31);
END;


END.