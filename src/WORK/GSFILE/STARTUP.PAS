{$I DEFINES.INC}
UNIT StartUp;


INTERFACE


PROCEDURE MakeUsBusy;
PROCEDURE KillOurBusy;
PROCEDURE KillNullTics;
PROCEDURE SetTheVideoMode;
PROCEDURE DrawOpeningScreen;
PROCEDURE DrawMainProcessingScreen;
PROCEDURE DrawAreafixProcessingScreen;
PROCEDURE DrawShutdownScreen;
PROCEDURE GetCommandLineOptions;
PROCEDURE ForceMailerRescan;
FUNCTION  SomethingToDo: Boolean;
FUNCTION  WeAreReadyToGo: Boolean;
FUNCTION  LoadDataFiles: Boolean;
FUNCTION  LoadTheTics: Boolean;
PROCEDURE Help;


IMPLEMENTATION


USES FastW1,BsString,Globals,BsFile,BsMulti,Gunshot,Process,KeyCheck,
     Crt,LogFile,Dos,BsKeys,BsVideo,BsFido,BsExec,BsTime,ApTimer,BsLog;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     Attr1 := 16;
     Attr2 := 25;
     FastWrite('Ú',y1,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y1,x1+1,Attr1);
     FastWrite('¿',y1,x2,Attr2);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
       FastWrite('³',Loop,x1,Attr1);
       FastWrite('³',Loop,x2,Attr2);
     END;
     FastWrite('À',y2,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y2,x1+1,Attr2);
     FastWrite('Ù',y2,x2,Attr2);
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
     Temp   : String;
     Attr1  : Word;
     Attr2  : Word;
BEGIN
     Attr1 := 16;
     Attr2 := 25;
     FOR LoopY := y1 TO y2 DO
     BEGIN
       IF LoopY=y1 THEN
       BEGIN
         FastWrite('Ú',LoopY,x1,Attr2);
         FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr2);
         FastWrite('¿',LoopY,x2,Attr1);
       END
       ELSE IF LoopY=y2 THEN
       BEGIN
         FastWrite('À',LoopY,x1,Attr2);
         FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr1);
         FastWrite('Ù',LoopY,x2,Attr1);
       END
       ELSE
       BEGIN
         FastWrite('³',LoopY,x1,Attr2);
         FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,Attr1);
         FastWrite('³',LoopY,x2,Attr1);
       END;
     END;
END;


PROCEDURE GetCommandLineOptions;
VAR  Loop : Word;
     Temp : String;
BEGIN
     BaseDirectory := _UpperCase(_GetFilePath(ParamStr(0)));
     Dec(BaseDirectory[0]);
     ChDir(BaseDirectory);
     IF ParamCount=0 THEN Help;
     NodeNumber      := 0;
     ScanForViruses  := True;
     DoCrcChecking   := True;
     AreaFixMessages := False;
     KeepAFix        := False;
     DoNotify        := False;
     DoConverting    := True;
     FOR loop := 1 TO paramcount DO
     BEGIN
       Temp := _UpperCase(ParamStr(Loop));
       IF Temp='-?' THEN
       BEGIN
         Help;
       END
       ELSE IF Temp='-NOCONVERT' THEN
       BEGIN
         DoConverting := False;
       END
       ELSE IF Temp='-NOSCAN' THEN
       BEGIN
         ScanForViruses := False;
       END
       ELSE IF Temp='-KEEPAFIX' THEN
       BEGIN
         KeepAFix := True;
       END
       ELSE IF Temp='-NOCRC' THEN
       BEGIN
         DoCrcChecking := False;
       END
       ELSE IF Temp='-NOTIFY' THEN
       BEGIN
         DoNotify := True;
       END
       ELSE IF _Mid(Temp,1,2)='-N' THEN
       BEGIN
         Delete(Temp,1,2);
         NodeNumber := _Numeric(Temp);
       END;
     END;
     IF NodeNumber=0 THEN Help;
END;


FUNCTION WeAreReadyToGo: Boolean;
VAR  TryCount : Byte;
     Loop2    : Word;
     Loop     : Word;
     C        : Char;
BEGIN
     FOR Loop := 1 TO 30 DO
     BEGIN
       IF _FileExists(BaseDirectory+'\GSFILE.$$$') THEN
       BEGIN
         IF Loop=1 THEN FOR Loop2 := 6 TO 25 DO FastWrite(_Replicate(' ',80),Loop2,1,7);
         FastWrite('GSFile busy. <Esc> aborts. Timeout: '+_String(Loop)+' ',7,1,14);
         _Delay(1000);
       END
       ELSE
       BEGIN
         FastWrite(_Replicate(' ',80),7,1,7);
         WeAreReadyToGo := True;
         Exit;
       END;
       IF KeyPressed THEN
       BEGIN
         C := ReadKey;
         CASE C OF
         #0:  C := ReadKey;
         #27: BEGIN
                WeAreReadyToGo := False;
                Exit;
              END;
         END;
       END
       ELSE TimeSlice;
     END;
     WeAreReadyToGo := False;
END;


FUNCTION LoadDataFiles: Boolean;
VAR  Status : Boolean;
BEGIN
     Status := True;
     IF NOT(_FileExists(BaseDirectory+'\DATA\LINKS.DAT')) THEN Status := False;
     {=======================================================================}
     { MAILER DATA - REQUIRED FOR INBOUND PATH                               }
     {=======================================================================}
     ASSIGN(FMailer,BaseDirectory+'\DATA\MAILER.DAT');
     {$I-}RESET(FMailer);{$I+}
     IF IOResult=0 THEN
     BEGIN
       {$I-}SEEK(FMailer,NodeNumber-1);{$I+}
       IF IOResult=0 THEN READ(FMailer,Mailer)
                     ELSE Status := False;
       CLOSE(FMailer);
     END
     ELSE Status := False;
     {=======================================================================}
     { MAILER2 DATA - REQUIRED FOR VIDEO EMULATION ETC.                      }
     {=======================================================================}
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     {$I-}RESET(FMailer2Info);{$I+}
     IF IOResult=0 THEN
     BEGIN
       {$I-}SEEK(FMailer2Info,NodeNumber-1);{$I+}
       IF IOResult=0 THEN READ(FMailer2Info,Mailer2Info)
                     ELSE Status := False;
       CLOSE(FMailer2Info);
     END
     ELSE Status := False;
     {=======================================================================}
     { SYSTEM DATA - REQUIRED FOR BAD FILES PATH                             }
     {=======================================================================}
     ASSIGN(FSystemInfo,BaseDirectory+'\DATA\SYSTEM.DAT');
     {$I-}RESET(FSystemInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
       READ(FSystemInfo,SystemInfo);
       CLOSE(FSystemInfo);
     END
     ELSE Status := False;
     {=======================================================================}
     { NETWORK DATA - REQUIRED FOR REPORTS                                   }
     {=======================================================================}
     IF NOT(_FileExists(BaseDirectory+'\DATA\NETWORK.DAT')) THEN Status := False;
     {=======================================================================}
     { ARCHIVER DEFINITIONS                                                  }
     {=======================================================================}
     ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
     {$I-}RESET(FArcDefs);{$I+}
     IF IOResult=0 THEN
     BEGIN
       READ(FArcDefs,ArcDefs);
       CLOSE(FArcDefs);
     END
     ELSE Status := False;
     {=======================================================================}
     { SCANNER DEFINITIONS                                                   }
     {=======================================================================}
     ASSIGN(FScanners,BaseDirectory+'\DATA\SCANNERS.DAT');
     {$I-}RESET(FScanners);{$I+}
     IF IOResult=0 THEN
     BEGIN
       READ(FScanners,Scanners);
       CLOSE(FScanners);
     END
     ELSE Status := False;
     CheckRegistered(BaseDirectory,'GSFile');
     bsSetLog(OurAppName,'',NodeNumber);
     IF NOT(Status) THEN
     BEGIN
       WriteLogFile('! Missing data file(s)! Run GSConfig.');
       WriteLogFile('! Check for - \GUNSHOT\DATA\LINKS.DAT');
       WriteLogFile('!             \GUNSHOT\DATA\MAILER.DAT');
       WriteLogFile('!             \GUNSHOT\DATA\SYSTEM.DAT');
       WriteLogFile('!             \GUNSHOT\DATA\NETWORK.DAT');
       WriteLogFile('!             \GUNSHOT\DATA\ARCHIVE.DAT');
       WriteLogFile('!             \GUNSHOT\DATA\SCANNERS.DAT');
     END;
     CASE SystemInfo.SwapMethod OF
     1:   SwapMethod := USE_EMS or USE_XMS;
     2:   SwapMethod := USE_ALL;
     3:   SwapMethod := USE_FILE or CHECK_NET;
     END;
     LoadDataFiles := Status;
END;


FUNCTION LoadTheTics: Boolean;
VAR  DirInfo : SearchRec;
BEGIN
     NumberOfTics := 0;
     FindFirst(Mailer.Inbound+'*.TIC',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       IF (NumberOfTics<1000) THEN
       BEGIN
         INC(NumberOfTics);
         TicFileName[NumberOfTics] := _UpperCase(DirInfo.Name);
       END;
       FindNext(DirInfo);
     END;
     IF NumberOfTics=0 THEN LoadTheTics := False
                       ELSE LoadTheTics := True;
END;


PROCEDURE Help;
BEGIN
     DrawOpeningScreen;
     WriteLn('GSFile Command Line Options:');
     WriteLn;
     WriteLn('      GSFILE.EXE <arg> <arg> ...');
     WriteLn;
     WriteLn('             -N<xxx>      : xxx is the node number to use.');
     WriteLn('             -NOSCAN      : Prevents virus checking of files.');
     WriteLn('             -NOCRC       : Disables CRC checking of files.');
     WriteLn('             -NOCONVERT   : Disables archive conversions.');
     WriteLn('             -NOTIFY      : Sends config notifications to downlinks.');
     WriteLn('             -KEEPAFIX    : Keep a copy of areafix messages.');
     _ShowCursor;
     Halt;
END;


PROCEDURE DrawMainProcessingScreen;
VAR  Loop : Word;
BEGIN
     MainScreenActive := True;
     DrawWindow(1,6,80,25);
     InvertedBox(3,8,56,15);
     InvertedBox(3,17,78,24);
     FOR Loop := 9 TO 14 DO FastWrite(_Replicate(' ',52),Loop,4,7);
     FOR Loop := 18 TO 23 DO FastWrite(_Replicate(' ',73),Loop,4,7);
     FastWrite(_Replicate('±',54),7,3,23);
     FastWrite(_Replicate('±',76),16,3,23);
     FastWrite(' PROGRESS ',7,5,31);
     FastWrite(' LOG ',16,5,31);
     FastWrite('[        ]',8,69,27);
     FastWrite('[        ]',9,69,27);
     FastWrite('[        ]',10,69,27);
     FastWrite('[        ]',11,69,27);
     FastWrite('[        ]',12,69,27);
     FastWrite('[        ]',13,69,27);
     FastWrite('[        ]',14,69,27);
     FastWrite('Work Dir',8,59,31);
     FastWrite('Conv Mem',9,59,31);
     FastWrite('TICs In',10,59,31);
     FastWrite('TICs Done',11,59,31);
     FastWrite('TICs Out',12,59,31);
     FastWrite('AreaFix',13,59,31);
     FastWrite('Elapsed',14,59,31);
     FastWrite('[            ]',9,5,8);
     FastWrite('[            ]',10,5,8);
     FastWrite('[            ]',11,5,8);
     FastWrite('[            ]',12,5,8);
     FastWrite('[            ]',13,5,8);
     FastWrite('[            ]',14,5,8);
     FastWrite('TIC File',9,20,7);
     FastWrite('File Echo',10,20,7);
     FastWrite('Attached File',11,20,7);
     FastWrite('File Size    ',12,20,7);
     FastWrite('Origin   ',13,20,7);
     FastWrite('Password',14,20,7);
     FastWrite('[ ]',9,36,8);
     FastWrite('[ ]',10,36,8);
     FastWrite('[ ]',11,36,8);
     FastWrite('[ ]',12,36,8);
     FastWrite('[ ]',13,36,8);
     FastWrite('[ ]',14,36,8);
     FastWrite('Copy To Work',9,40,7);
     FastWrite('Dearc Archive',10,40,7);
     FastWrite('Virus Check',11,40,7);
     FastWrite('Ext FILE_ID.DIZ',12,40,7);
     FastWrite('Rearc Archive',13,40,7);
     FastWrite('Add To Database',14,40,7);
END;


PROCEDURE DrawAreafixProcessingScreen;
VAR  Loop : Word;
BEGIN
     MainScreenActive := True;
     DrawWindow(1,6,80,25);
     InvertedBox(3,8,56,15);
     InvertedBox(3,17,78,24);
     FOR Loop := 9 TO 14 DO FastWrite(_Replicate(' ',52),Loop,4,7);
     FOR Loop := 18 TO 23 DO FastWrite(_Replicate(' ',73),Loop,4,7);
     FastWrite(_Replicate('±',54),7,3,23);
     FastWrite(_Replicate('±',75),16,3,23);
     FastWrite(' PROGRESS ',7,5,31);
     FastWrite(' LOG ',16,5,31);
END;


PROCEDURE DrawOpeningScreen;
BEGIN
     _HideCursor;
     AppHeader('GSFile - TIC File Processor For Gunshot Professional');
END;


PROCEDURE DrawShutdownScreen;
BEGIN
     DrawOpeningScreen;
     FastWrite('Inbound Files',7,3,7);
     FastWrite('Inbound Bytes',8,3,7);
     FastWrite('Outbound Files',9,3,7);
     FastWrite('Stored Bytes',10,3,7);
     FastWrite('Areafix Msgs',11,3,7);
     FastWrite('Process Time',12,3,7);
     FastWrite('[            ]',7,20,8);
     FastWrite('[            ]',8,20,8);
     FastWrite('[            ]',9,20,8);
     FastWrite('[            ]',10,20,8);
     FastWrite('[            ]',11,20,8);
     FastWrite('[            ]',12,20,8);
     FastWrite(_String(RunningInFiles),7,22,14);
     FastWrite(_String(RunningInbound),8,22,14);
     FastWrite(_String(RunningOutTics),9,22,14);
     FastWrite(_String(RunningStored),10,22,14);
     FastWrite(_String(RunningAFix),11,22,14);
     FastWrite(FormatMinSec(ElapsedTimeInSecs(BigTimer)),12,22,14);
     FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',13,1,8);
     FastWrite('All done!',14,1,7);
     GotoXY(1,15);
     _ShowCursor;
END;


PROCEDURE ForceMailerRescan;
VAR  FFile : File;
BEGIN
     _CreatePath(Mailer.Semaphores);
     ASSIGN(FFile,Mailer.Semaphores+'RESCAN.NOW');
     REWRITE(FFile);
     CLOSE(FFile);
END;


PROCEDURE KillNullTics;
VAR  DirInfo : SearchRec;
BEGIN
     FindFirst(Mailer.Outbound+'*.TIC',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          IF DirInfo.Size=0 THEN _EraseFile(Mailer.Outbound+DirInfo.Name);
          FindNext(DirInfo);
     END;
END;


PROCEDURE MakeUsBusy;
VAR  TFile : File;
BEGIN
     ASSIGN(TFile,BaseDirectory+'\GSFILE.$$$');
     REWRITE(TFile,1);
     CLOSE(TFile);
END;


PROCEDURE KillOurBusy;
BEGIN
     _EraseFile(BaseDirectory+'\GSFILE.$$$');
END;


PROCEDURE SetTheVideoMode;
BEGIN
     TextMode(CO80);
     ReinitFastWrite;
END;


FUNCTION SomethingToDo: Boolean;
VAR  DoSome : Boolean;
     Loop   : Word;
     Temp   : String;
     Orig   : AddrType;
     Dest   : AddrType;
BEGIN
     DoSome := False;
     IF _FileExists(Mailer.Inbound+'*.TIC') THEN DoSome := True;
     IF DoNotify THEN DoSome := True;
     rFidoStartUpArea(Mailer.NetMail);
     IF (rFidoNumberOfMsgs<>0) THEN
     BEGIN
       FOR Loop := 1 TO rFidoNumberOfMsgs DO
       BEGIN
         IF rFidoOpenMessage(Loop) THEN
         BEGIN
           Temp := _UpperCase(rFidoGetMsgTo);
           IF ((Temp='GSFILE') OR (Temp='RAID')) THEN
           BEGIN
             IF ((NOT rFidoIsReceived) AND (NOT rFidoIsLocal)) THEN
             BEGIN
               rFidoGetAkas(Orig,Dest);
               IF IsOurNode(Dest) THEN
               BEGIN
                 DoSome := True;
                 AreaFixMessages := True;
               END;
             END;
           END;
           rFidoCloseMessage;
         END;
       END;
     END;
     rFidoCloseArea;
     SomethingToDo := DoSome;
END;


END.