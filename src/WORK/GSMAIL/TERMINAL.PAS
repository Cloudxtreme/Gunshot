{$I DEFINES.INC}
UNIT Terminal;


INTERFACE


PROCEDURE DoTerminal;


IMPLEMENTATION


USES Globals,Crt,FastW1,ApAnsi,ApPort,ApCom,ApAbsPcl,ApZModem,ApXModem,
     ApYModem,Dos,Comm,DrawScrn,ApTimer,ApMisc,SaveScrn,BsMulti,Editor,
     BsFile,BsExec,TermHelp,BsKeys,BsString,BsTime,BsCom,BsVideo,DoProg;


PROCEDURE SaveCursor;
BEGIN
     WhereXYAbs(SaveXYPos);
     SaveAttr := TextAttr;
     _HideCursor;
END;


PROCEDURE RestoreCursor;
BEGIN
     TextAttr := SaveAttr;
     GotoXYAbs(SaveXYPos);
     _ShowCursor;
END;


PROCEDURE UpdateConnectRate;
BEGIN
     FastWrite(_PadRight('COM'+_String(NodeInfo.ComPort)+':'+_String(ActualBaud),11),
               Window2+7,57,ShotgunColours.SGMailStatusHighlight);
END;


PROCEDURE UpdateOnlineTime;
BEGIN
     FastWrite(OnlineTime,Window2+7,70,ShotgunColours.SGMailStatusHighlight);
END;


PROCEDURE SetUpStartVideo;
VAR  WorkAttr: Byte;
BEGIN
     Textcolor(7);
     Textbackground(0);
     ClrScr;
     WorkAttr := Trunc(ShotgunColours.SGMailStatusText/16);
     WorkAttr := WorkAttr*16;
     FastWrite(_PadRight('                 ³                                    ³            ³ ',80),Window2+7,1,WorkAttr);
     FastWrite('F1 - Help',Window2+7,2,ShotgunColours.SGMailStatusText);
     Window(1,1,80,NumLines-1);
     UpdateConnectRate;
     UpdateOnlineTime;
     Textcolor(7);
     Textbackground(0);
     FastW1.GotoXY(1,1);
END;


FUNCTION JustFirstNumbers(InString: String): String;
VAR  Loop    : Word;
     Temp    : String;
     AllDone : Boolean;
BEGIN
     Loop     := 0;
     AllDone  := False;
     Temp     := '';
     FOR Loop := 1 TO LENGTH(InString) DO
     BEGIN
          IF NOT(AllDone) THEN
          BEGIN
               IF ((Ord(InString[Loop])>=48) AND (Ord(InString[Loop])<=57)) THEN
               BEGIN
                    Temp := Temp+ InString[Loop];
               END
               ELSE AllDone := True;
          END;
     END;
     JustFirstNumbers := Temp;
END;

{$F+}
FUNCTION KbdAbort : Boolean;
CONST Escape = #$1B;
VAR   Ch     : Char;
BEGIN
     KbdAbort := False;
     IF KeyPressed THEN
     BEGIN
          Ch := ReadKey;
          IF Ch = #0 THEN Ch := ReadKey;
          IF Ch = Escape THEN
          BEGIN
               KbdAbort := True;
               WeAbort  := True;
          END;
     END;
END;
{$F-}

{$F+}
FUNCTION GetNextFile(PROTO: ProtocolRecPtr; VAR FName: PathStr): Boolean;
BEGIN
     INC(CurrentFileNum);
     FName := FileQueue^[CurrentFileNum];
     IF (CurrentFileNum>FilesInQueue) THEN
     BEGIN
          GetNextFile := False;
          FName       := '';
     END
     ELSE GetNextFile := True;
END;
{$F-}

{$F+}
PROCEDURE WindowStatus(P: ProtocolRecPtr; Starting,Ending: Boolean);
VAR   CurFileSize         : Longint;
      CurBytesRemaining   : Longint;
      CurBytesTransferred : Longint;
      CurProtocol         : Longint;
      CurElapsedTics      : Longint;
      LastBytesSent       : Longint;
      S                   : String;
      R                   : Longint;
      ActualCPS           : Longint;
      Temp                : String;
      Work                : Word;

     PROCEDURE ClearProgress;
     BEGIN
          FastWrite('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±',15,27,ShotgunColours.SGMailProgressBarBack);
          pCurrent := 0;
     END;

BEGIN
     IF Starting THEN
     BEGIN
          IF doing_receive
             THEN DrawWindow(18,8,65,17,'RECEIVING FILE(S)',True)
             ELSE DrawWindow(18,8,65,17,'SENDING FILE(S)',True);
          FastWrite(' Protocol:                  Speed:  ',10,21,ShotgunColours.SGMailWindowText);
          FastWrite('     File:                   Time:  ',11,21,ShotgunColours.SGMailWindowText);
          FastWrite('     Size:                   Left:  ',12,21,ShotgunColours.SGMailWindowText);
          FastWrite('     Sent:                    CPS:  ',13,21,ShotgunColours.SGMailWindowText);
          {Progress indicator}
          InvertedBox(25,14,58,16);
          ClearProgress;
          {Baud Rate}
          FastWrite(_String(ActualBaud),Info.Speed[2],Info.Speed[1],ShotgunColours.SGMailWindowHighlight);
          {Protocol}
          CurProtocol := GetProtocol(P);
          S           := ProtocolTypeString[CurProtocol];
          CASE GetCheckType(P) OF
          bcCrc16     : S := S+'/Crc16';
          bcCrc32     : S := S+'/Crc32';
          bcCrcK      : S := S+'/Crc';
          END;
          FastWrite(S,Info.Protocol[2],Info.Protocol[1],ShotgunColours.SGMailWindowHighlight);
     END;
     {Update time online}
     IF (OnlineTime<>'Offline') THEN
     BEGIN
          Temp := _String(Round(ElapsedTimeInSecs(Timer)/60))+'m';
          Temp := _PadRight(Temp,7);
          IF Temp<>OnlineTime THEN
          BEGIN
               OnlineTime := Temp;
               UpdateOnlineTime;
          END;
     END;
     {Update the data areas}
     IF ((NOT(Starting)) AND (NOT(Ending))) THEN
     BEGIN
          WITH P^.PData^ DO
          BEGIN
               CurFileSize         := GetFileSize(P);
               CurBytesRemaining   := GetBytesRemaining(P);
               CurBytesTransferred := GetBytesTransferred(P);
               CurElapsedTics      := GetElapsedTics(P);
               {File Name}
               FastWrite(_PadRight(GetFileName(P),12),Info.FileName[2],Info.FileName[1],ShotgunColours.SGMailWindowHighlight);
               {File Size}
               IF CurFileSize=0 THEN S := ''
                                ELSE S := _String(CurFileSize);
               FastWrite(_PadRight(S,9),Info.Size[2],Info.Size[1],ShotgunColours.SGMailWindowHighlight);
               {Estimated time}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurFileSize)),6),
                         Info.Time[2],Info.Time[1],ShotgunColours.SGMailWindowHighlight);
               {Time remaining}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurBytesRemaining)),6),
                         Info.Left[2],Info.Left[1],ShotgunColours.SGMailWindowHighlight);
               {Bytes Transferred}
               FastWrite(_PadRight(_String(CurBytesTransferred),9),
                         Info.Sent[2],Info.Sent[1],ShotgunColours.SGMailWindowHighlight);
               {CPS}
               IF CurElapsedTics>0 THEN
               BEGIN
                    R         := CurBytesTransferred-GetInitialFilePos(P);
                    ActualCPS := Trunc(R/(CurElapsedTics/18.2));
               END
               ELSE ActualCPS := 0;
               FastWrite(_PadRight(_String(ActualCPS),6),Info.CPS[2],Info.CPS[1],ShotgunColours.SGMailWindowHighlight);
               {Progress Indicator}
               IF CurFileSize=0
                  THEN ClearProgress
                  ELSE DoProgressBar(CurBytesTransferred,CurFileSize,30,pCurrent,27,15,False);
          END;
     END;
END;
{$F-}

PROCEDURE TransferFiles;

     PROCEDURE DoFinishParams;
     BEGIN
          CASE TProtocol OF
          Xmodem,
          Xmodem1K,
          Xmodem1KG : BEGIN
                           SetFinishWaitXM(PROTO,Secs2Tics(20));
                           SetHandshakeWait(PROTO,Secs2Tics(5),10);
                      END;
          Ymodem,
          YmodemG   : BEGIN
                           SetFinishWaitXM(PROTO,Secs2Tics(20));
                           SetHandshakeWait(PROTO,Secs2Tics(5),10);
                      END;
          Zmodem    : BEGIN
                           SetFinishWaitZM(PROTO,Secs2Tics(20),3);
                           SetHandshakeWait(PROTO,Secs2Tics(5),10);
                      END;
          END;
     END;

BEGIN
     SetAbortFunc(bsBBSPort,KbdAbort);
     DefProtocolOptions := apRTSLowForWrite;
     pCurrent := 0;
     CASE TProtocol OF
     Xmodem,
     Xmodem1K,
     Xmodem1KG : BEGIN
                      InitXmodem(PROTO,bsBBSPort,(TProtocol=Xmodem1K),TProtocol=Xmodem1KG);
                      IF GetAsyncStatus=ecOk THEN
                      BEGIN
                           SetBlockWait(PROTO,RelaxedBlockWait);
                           DoFinishParams;
                           SetShowStatusProc(PROTO,WindowStatus);
                           SetOverwriteOption(PROTO,WriteRename);
                           SetActualBps(PROTO,ActualBaud);
                           CASE TransferMode OF
                           Transmit : BEGIN
                                           SetFileMask(PROTO,SrcFileName);
                                           ProtocolTransmitXM(PROTO);
                                      END;
                           Receive  : BEGIN
                                           SetReceiveFileName(PROTO,SrcFileName);
                                           ProtocolReceiveXM(PROTO);
                                      END;
                           END;
                           DoneXmodem(PROTO);
                           IF GetAsyncStatus<>ecOk THEN AbortedProtocol := True;
                      END;
                 END;
     Ymodem,
     YmodemG   : BEGIN
                      InitYmodem(PROTO,bsBBSPort,True,(TProtocol=YmodemG));
                      IF GetAsyncStatus=ecOk THEN
                      BEGIN
                           IF transferMode=transmit
                              THEN SetNextFileFunc(PROTO,GetNextFile);
                           SetShowStatusProc(PROTO,WindowStatus);
                           SetBlockWait(PROTO,RelaxedBlockWait);
                           DoFinishParams;
                           SetOverwriteOption(PROTO,WriteRename);
                           SetActualBps(PROTO,ActualBaud);
                           CASE TransferMode OF
                           Transmit : ProtocolTransmitYM(PROTO);
                           Receive  : BEGIN
                                           SetDestinationDirectory(PROTO,SrcFileName);
                                           ProtocolReceiveYM(PROTO);
                                      END;
                           END;
                           DoneYmodem(PROTO);
                           IF GetAsyncStatus<>ecOk THEN AbortedProtocol := True;
                           IF TransferMode=Receive THEN PutChar(bsBBSPort,#6);
                      END;
                 END;
     Zmodem    : BEGIN
                      InitZmodem(PROTO,bsBBSPort);
                      IF GetAsyncStatus=ecOk THEN
                      BEGIN
                           IF transferMode=transmit
                              THEN SetNextFileFunc(PROTO,GetNextFile);
                           SetShowStatusProc(PROTO,WindowStatus);
                           DoFinishParams;
                           SetRecoverOption(PROTO,True);
                           SetActualBps(PROTO,ActualBaud);
                           SetFileMgmtOptions(PROTO,True,False,WriteDifferent);
                           CASE TransferMode OF
                           Transmit : ProtocolTransmitZM(PROTO);
                           Receive  : BEGIN
                                           SetDestinationDirectory(PROTO,SrcFileName);
                                           ProtocolReceiveZM(PROTO);
                                      END;
                           END;
                           DoneZmodem(PROTO);
                           IF GetAsyncStatus<>ecOk THEN AbortedProtocol := True;
                      END;
                 END;
     END;
     SetAbortFunc(bsBBSPort,NoAbortFunc);
END;


PROCEDURE HandleAbort;
BEGIN
     IF WeAbort THEN
     BEGIN
          bsClearInBuffer;
          bsClearOutBuffer;
          PutString(bsBBSPort,#24#24#24#24#24);
          _Delay(1000);
          bsClearInBuffer;
          bsClearOutBuffer;
     END
     ELSE
     BEGIN
          IF AbortedProtocol THEN
          BEGIN
               _Delay(1000);
               bsClearInBuffer;
               bsClearOutBuffer;
          END
          ELSE _Delay(1000);
     END;
END;


PROCEDURE TransmitFiles(Filename: String; Protocl: Byte);
BEGIN
     SaveCursor;
     Doing_Receive  := False;
     WeAbort        := False;
     CASE Protocl OF
     1:   TProtocol := ZModem;
     2:   TProtocol := XModem;
     3:   TProtocol := XModem1K;
     4:   TProtocol := YModem;
     5:   TProtocol := YModemG;
     END;
     TransferMode        := Transmit;
     SrcFilename         := FileName;
     CurrentFileNum      := 0;
     SaveScreen(2);
     TransferFiles;
     HandleAbort;
     RestoreScreen(2);
     RestoreCursor;
END;


PROCEDURE ReceiveFiles(Filename: String; Protocl: Byte);
BEGIN
     SaveCursor;
     Doing_Receive  := True;
     WeAbort        := False;
     CASE Protocl OF
     1:   TProtocol := ZModem;
     2:   TProtocol := XModem;
     3:   TProtocol := XModem1K;
     4:   TProtocol := YModem;
     5:   TProtocol := YModemG;
     END;
     TransferMode        := Receive;
     SrcFilename         := FileName;
     CurrentFileNum      := 0;
     SaveScreen(2);
     TransferFiles;
     HandleAbort;
     RestoreScreen(2);
     RestoreCursor;
END;


FUNCTION SelectProtocol: Byte;
VAR  Prots   : Array[1..6] Of String[17];
     Current : Byte;
     C       : Char;

     PROCEDURE Redraw;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 6 DO
          BEGIN
               IF Loop=Current THEN FastWrite(Prots[Loop],9+Loop,14,ShotgunColours.SGMailMenuSelected)
                               ELSE FastWrite(Prots[Loop],9+Loop,14,ShotgunColours.SGMailWindowText);
          END;
     END;

BEGIN
     Prots[1] := '    ZModem       ';
     Prots[2] := '    XModem       ';
     Prots[3] := '    1K-XModem    ';
     Prots[4] := '    YModem       ';
     Prots[5] := '    YModem-G     ';
     Prots[6] := '    Abort        ';
     Current  := 1;
     SaveCursor;
     SaveScreen(2);
     DrawWindow(10,8,34,17,'Select Protocol',True);
     InvertedBox(13,9,31,16);
     Redraw;
     C := #0;
     REPEAT
           IF Keypressed THEN
           BEGIN
                C := ReadKey;
                CASE ORD(c) OF
                0:   BEGIN
                          C := ReadKey;
                          CASE ORD(C) OF
                          72:  BEGIN
                                    DEC(Current);
                                    IF Current=0 THEN Current := 6;
                                    Redraw;
                               END;
                          80:  BEGIN
                                    INC(Current);
                                    IF Current=7 THEN Current := 1;
                                    Redraw;
                               END;
                          END;
                     END;
                27:  Current := 6;
                END;
           END
           ELSE TimeSlice;
     UNTIL ((c=#13) OR (c=#27) OR (c=#32));
     IF Current=6 THEN Current := 0;
     RestoreScreen(2);
     RestoreCursor;
     SelectProtocol := Current;
END;


FUNCTION TrimDirectory(InString: String): String;
VAR  Loop : Word;
     Work : Word;
BEGIN
     Work := 0;
     Delete(InString,LENGTH(InString),1);
     FOR Loop := LENGTH(InString) DOWNTO 1 DO
     BEGIN
          IF Work=0 THEN
          BEGIN
               IF InString[Loop]='\' THEN Work := Loop;
          END;
     END;
     InString := _Mid(InString,1,Work);
     TrimDirectory := InString;
END;


FUNCTION GetFileList(Drives: String; Batch: Boolean): Boolean;
TYPE File_Info    = RECORD
     FName        : String[12];
     IsDir        : Boolean;
     END;
TYPE FFile_Info   = Array[1..1000] Of File_Info;
VAR  WindowNumber : Word;
     AllDone      : Boolean;
     CurrentDrive : Byte;
     CurrentFile  : Word;
     C            : Char;
     Top          : Word;
     FileInfo     : ^FFile_Info;
     TheDirectory : String;
     Files        : Word;
     MaxLimit     : Byte;
LABEL               Tab;

     PROCEDURE RedrawDrives(Clear: Boolean);
     VAR  Loop : Word;
     BEGIN
          IF CurrentDrive=0 THEN
          BEGIN
               FOR Loop := 1 TO LENGTH(Drives) DO
               BEGIN
                    IF Drives[Loop]=TheDirectory[1] THEN CurrentDrive := Loop;
               END;
          END;
          FOR Loop := 1 TO 15 DO
          BEGIN
               IF (Loop<=LENGTH(Drives)) THEN
               BEGIN
                    IF ((Loop=CurrentDrive) AND (NOT(Clear)))
                       THEN FastWrite('   '+Drives[Loop]+':   ',5+Loop,5,ShotgunColours.SGMailMenuSelected)
                       ELSE FastWrite('   '+Drives[Loop]+':   ',5+Loop,5,ShotgunColours.SGMailWindowText);
               END;
          END;
     END;

     PROCEDURE LoadInDirectory;
     VAR  DirInfo : SearchRec;
     BEGIN
          FindFirst(TheDirectory+'*.*',Anyfile-VolumeID,DirInfo);
          IF DosError<>0 THEN
          BEGIN
               TheDirectory := Drives[CurrentDrive]+':\';
          END;
          Files := 0;
          FindFirst(TheDirectory+'*.*',Anyfile-VolumeID-Hidden,DirInfo);
          WHILE DosError=0 DO
          BEGIN
               INC(Files);
               FileInfo^[Files].FName := DirInfo.Name;
               FileInfo^[Files].IsDir := ((DirInfo.Attr AND $10)<>0);
               FindNext(DirInfo);
          END;
     END;

     PROCEDURE RedrawFiles(Clear: Boolean);
     VAR  Loop : Word;
          Temp : String;
     BEGIN
          FOR Loop := 1 TO 15 DO
          BEGIN
               IF (Loop+Top-1<=Files) THEN
               BEGIN
                    IF FileInfo^[Loop+Top-1].IsDir
                       THEN Temp := ' '+_PadRight(FileInfo^[Loop+Top-1].FName,13)+'<DIR>'
                       ELSE Temp := ' '+_PadRight(FileInfo^[Loop+Top-1].FName,13)+'     ';
                    IF ((Loop+Top-1=CurrentFile) AND (NOT(Clear)))
                       THEN FastWrite(Temp,5+Loop,15,ShotgunColours.SGMailMenuSelected)
                       ELSE FastWrite(Temp,5+Loop,15,ShotgunColours.SGMailWindowText);
               END
               ELSE FastWrite('                   ',5+Loop,15,ShotgunColours.SGMailWindowText);
          END;
     END;

     PROCEDURE RedrawPath;
     BEGIN
          FastWrite('Current Path:',22,5,ShotgunColours.SGMailWindowHighlight);
          FastWrite(_PadRight(TheDirectory,58),22,20,ShotgunColours.SGMailWindowHighlight);
     END;

     PROCEDURE RedrawQueue;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 15 DO FastWrite(_PadRight(FileQueue^[Loop],39),5+Loop,38,ShotgunColours.SGMailWindowText);
     END;

     FUNCTION InQueue(InString: String): Boolean;
     VAR  IsThere : Boolean;
          Loop    : Word;
     BEGIN
          IsThere := False;
          FOR Loop := 1 TO FilesInQueue DO
          BEGIN
               IF FileQueue^[Loop]=InString THEN IsThere := True;
          END;
          InQueue := IsThere;
     END;

BEGIN {68}
     IF Batch THEN MaxLimit := 15
              ELSE MaxLimit := 1;
     New(FileInfo);
     FillChar(FileInfo^,SizeOf(FileInfo^),0);
     FillChar(FileQueue^,SizeOf(FileQueue^),0);
     FilesInQueue := 0;
     WindowNumber := 1;
     CurrentDrive := 0;
     CurrentFile  := 1;
     SaveCursor;
     SaveScreen(2);
     DrawWindow(3,3,78,23,'Upload File Queue',True);
     InvertedBox(4,5,13,21);
     InvertedBox(14,5,35,21);
     InvertedBox(36,5,77,21);
     FastWrite('Drives ',5,5,ShotgunColours.SGMailWindowHighlight);
     FastWrite('Files ',5,15,ShotgunColours.SGMailWindowHighlight);
     FastWrite('Upload Queue ',5,37,ShotgunColours.SGMailWindowHighlight);
     TheDirectory := 'C:\';
     Top          := 1;
     RedrawDrives(False);
     LoadInDirectory;
     RedrawFiles(True);
     RedrawPath;
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                CASE ORD(c) OF
                0:   BEGIN
                          C := ReadKey;
                          CASE ORD(c) OF
                          75,
                          15:  BEGIN
                                    IF WindowNumber=1 THEN
                                    BEGIN
                                         WindowNumber := 2;
                                         RedrawDrives(True);
                                         RedrawFiles(False);
                                    END
                                    ELSE
                                    BEGIN
                                         WindowNumber := 1;
                                         RedrawDrives(False);
                                         RedrawFiles(True);
                                    END;
                               END;
                          68:  AllDone := True;
                          72:  BEGIN
                                    CASE WindowNumber OF
                                    1:   BEGIN
                                              DEC(CurrentDrive);
                                              IF CurrentDrive=0 THEN
                                                 CurrentDrive := LENGTH(Drives);
                                              RedrawDrives(False);
                                              TheDirectory := Drives[CurrentDrive]+':\';
                                              CurrentFile  := 1;
                                              Top          := 1;
                                              LoadInDirectory;
                                              RedrawFiles(True);
                                              RedrawPath;
                                         END;
                                    2:   IF CurrentFile>1 THEN
                                         BEGIN
                                              DEC(CurrentFile);
                                              IF CurrentFile<Top THEN DEC(Top);
                                              RedrawFiles(False);
                                         END;
                                    END;
                               END;
                          80:  BEGIN
                                    CASE WindowNumber OF
                                    1:   BEGIN
                                              INC(CurrentDrive);
                                              IF CurrentDrive>LENGTH(Drives)
                                                 THEN CurrentDrive := 1;
                                              RedrawDrives(False);
                                              TheDirectory := Drives[CurrentDrive]+':\';
                                              CurrentFile  := 1;
                                              Top          := 1;
                                              LoadInDirectory;
                                              RedrawFiles(True);
                                              RedrawPath;
                                         END;
                                    2:   IF CurrentFile<Files THEN
                                         BEGIN
                                              INC(CurrentFile);
                                              IF CurrentFile>Top+14 THEN INC(Top);
                                              RedrawFiles(False);
                                         END;
                                    END;
                               END;
                          77:  GOTO Tab;
                          END;
                     END;
                9:   BEGIN
                          Tab:
                          IF WindowNumber=1 THEN
                          BEGIN
                               WindowNumber := 2;
                               RedrawDrives(True);
                               RedrawFiles(False);
                          END
                          ELSE
                          BEGIN
                               WindowNumber := 1;
                               RedrawDrives(False);
                               RedrawFiles(True);
                          END;
                     END;
                13,
                32:  IF WindowNumber=2 THEN
                     BEGIN
                          IF FileInfo^[CurrentFile].IsDir THEN
                          BEGIN
                               IF FileInfo^[CurrentFile].FName='.' THEN
                               BEGIN
                                    CurrentFile  := 1;
                                    Top          := 1;
                                    LoadInDirectory;
                                    RedrawFiles(False);
                                    RedrawPath;
                               END
                               ELSE IF FileInfo^[CurrentFile].FName='..' THEN
                               BEGIN
                                    IF Length(TheDirectory)<>3 THEN
                                    BEGIN
                                         TheDirectory := TrimDirectory(TheDirectory);
                                         CurrentFile  := 1;
                                         Top          := 1;
                                         LoadInDirectory;
                                         RedrawFiles(False);
                                         RedrawPath;
                                    END;
                               END
                               ELSE
                               BEGIN
                                    TheDirectory := TheDirectory+FileInfo^[CurrentFile].FName+'\';
                                    CurrentFile  := 1;
                                    Top          := 1;
                                    LoadInDirectory;
                                    RedrawFiles(False);
                                    RedrawPath;
                               END;
                          END
                          ELSE IF FilesInQueue<>MaxLimit THEN
                          BEGIN
                               IF NOT(InQueue(TheDirectory+FileInfo^[CurrentFile].FName)) THEN
                               BEGIN
                                    INC(FilesInQueue);
                                    FileQueue^[FilesInQueue] := TheDirectory+FileInfo^[CurrentFile].FName;
                                    RedrawQueue;
                               END;
                          END;
                     END;
                27:  BEGIN
                          FilesInQueue := 0;
                          AllDone      := True;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     RestoreScreen(2);
     RestoreCursor;
     Dispose(FileInfo);
     IF FilesInQueue=0 THEN GetFileList := False
                       ELSE GetFileList := True;
END;


FUNCTION GetPathName: String;
VAR  Test : File;
     Temp : String;
BEGIN
     SaveCursor;
     SaveScreen(2);
     DrawWindow(5,9,75,13,'XModem Download',True);
     Temp := aGetInput(10,11,50,15,'',True,True);
     RestoreScreen(2);
     RestoreCursor;
     IF Temp=#27 THEN Temp := '';
     IF (Temp<>'') THEN
     BEGIN
          ASSIGN(Test,Temp);
          {$I-}REWRITE(Test);{$I+}
          IF IOResult=0 THEN
          BEGIN
               CLOSE(Test);
               ERASE(Test);
          END
          ELSE Temp := '';
     END;
     GetPathName := Temp;
END;


PROCEDURE DoTerminal;
VAR  ccc             : Char;
     OuttaHere       : Boolean;
     Temp            : String;
     Temp2           : String;
     Work            : Word;
     XPos            : Word;
     GotPad          : Boolean;
     WTimer          : EventTimer;
     TTT             : EventTimer;
     SvX             : Word;
     SvY             : Word;
     Crap            : Char;
     SaveNumLines    : Word;
LABEL                  Skip;
BEGIN
     Info.Protocol[1] := 32;  Info.Protocol[2] := 10;
     Info.FileName[1] := 32;  Info.FileName[2] := 11;
     Info.Size[1]     := 32;  Info.Size[2]     := 12;
     Info.Sent[1]     := 32;  Info.Sent[2]     := 13;
     Info.Speed[1]    := 56;  Info.Speed[2]    := 10;
     Info.Time[1]     := 56;  Info.Time[2]     := 11;
     Info.Left[1]     := 56;  Info.Left[2]     := 12;
     Info.CPS[1]      := 56;  Info.CPS[2]      := 13;
     New(FileQueue);
     SaveScreen(4);

     {Set Back To 25 Line Mode}
     SaveNumLines := NumLines;
     NumLines     := 25;
     SetOurVideoMode;

     Offline    := True;
     OnlineTime := 'Offline';
     OuttaHere  := False;
     ActualBaud := bsReturnRate(NodeInfo.BaudRate,NodeInfo.ComDevice);
     SetUpStartVideo;
     NewTimerSecs(Timer,1440*60);
     SetCurrentAnsiPort(bsBBSPort);
     PutString(bsBBSPort,NodeInfo.OnHook+#13);
     IsOnline := False;
     REPEAT
           IF CharReady(bsBBSPort) THEN
           BEGIN
                Temp   := '';
                GotPad := False;
                WHILE CharReady(bsBBSPort) DO
                BEGIN
                     GetChar(bsBBSPort,ccc);
                     Temp := Temp+ccc;
                     IF ccc=#24 THEN GotPad := True;
                     IF GotPad THEN Delay(5);
                     IF LENGTH(Temp)=255 THEN GOTO Skip;
                     IF (NOT(IsOnline) AND NOT(CharReady(bsBBSPort))) THEN Delay(5);
                END;
                Skip:
                _HideCursor;
                WriteStringAnsi(Temp);
                _ShowCursor;
                IF OnlineTime='Offline' THEN
                BEGIN
                     IF bsCarrierDetected THEN
                     BEGIN
                          IsOnline := True;
                          Work     := Pos('CONNECT',Temp);
                          IF (Work<>0) THEN
                          BEGIN
                               Delete(Temp,1,Work+7);
                               Temp := JustFirstNumbers(Temp);
                               ActualBaud := _Numeric(Temp);
                          END;
                          Work     := Pos('CARRIER',Temp);
                          IF (Work<>0) THEN
                          BEGIN
                               Delete(Temp,1,Work+7);
                               Temp := JustFirstNumbers(Temp);
                               ActualBaud := _Numeric(Temp);
                          END;
                          NewTimerSecs(Timer,1440*60);
                          OnlineTime := '0m     ';
                          UpdateConnectRate;
                          UpdateOnlineTime;
                     END;
                END
                ELSE IF GotPad THEN
                BEGIN
                     IF (Pos(#24+'B00',Temp)<>0) THEN
                     BEGIN
                          ReceiveFiles(MailerInfo.Inbound,1);
                          UpdateOnlineTime;
                     END;
                END;
           END
           ELSE IF KeyPressed THEN
           BEGIN
                ccc := ReadKey;
                IF ccc=#00 THEN
                BEGIN
                     ccc := ReadKey;
                     CASE ORD(ccc) OF
                     35:  bsOnHook(NodeInfo.OnHook);
                     45:  OuttaHere := True;
                     73:  BEGIN {Send Files}
                               Work := SelectProtocol;
                               IF Work<>0 THEN
                               BEGIN
                                    CASE Work OF
                                    2,3: BEGIN {XModem}
                                              IF GetFileList(GetDrives,False) THEN
                                              BEGIN
                                                   TransmitFiles(FileQueue^[1],Work);
                                                   UpdateOnlineTime;
                                              END;
                                         END;
                                    ELSE BEGIN {Others}
                                              IF GetFileList(GetDrives,True) THEN
                                              BEGIN
                                                   TransmitFiles('',Work);
                                                   UpdateOnlineTime;
                                              END;
                                         END;
                                    END;
                               END;
                          END;
                     81:  BEGIN {Receive Files}
                               Work := SelectProtocol;
                               IF Work<>0 THEN
                               BEGIN
                                    CASE Work OF
                                    2,3: BEGIN {XModem}
                                              Temp := GetPathName;
                                              IF (Temp<>'') THEN
                                              BEGIN
                                                   ReceiveFiles(Temp,Work);
                                                   UpdateOnlineTime;
                                              END;
                                         END;
                                    ELSE BEGIN {Others}
                                              ReceiveFiles(MailerInfo.Inbound,Work);
                                              UpdateOnlineTime;
                                         END;
                                    END;
                               END;
                          END;
                     71:  PutString(bsBBSPort,#27#91#72); {home}
                     72:  PutString(bsBBSPort,#27#91#65); {U arrow}
                     75:  PutString(bsBBSPort,#27#91#68); {L arrow}
                     77:  PutString(bsBBSPort,#27#91#67); {R arrow}
                     79:  PutString(bsBBSPort,#27#91#75); {end}
                     80:  PutString(bsBBSPort,#27#91#66); {D arrow}
                     83:  PutString(bsBBSPort,#127);      {delete}
                     119: PutString(bsBBSPort,#27#91#76); {ctrl+home}
                     132: PutString(bsBBSPort,#27#91#77); {ctrl+PgUp}
                     59:  DoTerminalHelp;
                     46:  PutString(bsBBSPort,#27+'[1;37m'+#27+'[40m'+chr(27)+'[2J');
                     60:  BEGIN {Dos Shell}
                               SaveScreen(2);
                               SvX := WhereX;
                               SvY := WhereY;
                               Window(1,1,80,NumLines);
                               TextBackground(0);
                               TextColor(7);
                               ClrScr;
                               WHILE KeyPressed DO Crap := ReadKey;
                               PutEnviro('PROMPT=Enter EXIT to return to SGMail!!$_$p$g');
                               DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),
                                      SwapMethod,Shotgun_Directory+'\NODE'+_String(SimNode));
                               ChDir(Shotgun_Directory);
                               Window(1,1,80,NumLines-1);
                               RestoreScreen(2);
                               FastW1.GotoXY(SvX,SvY);
                          END;
                     ELSE PutChar(bsBBSPort,Chr(128+Ord(ccc)));
                     END;
                END
                ELSE PutChar(bsBBSPort,ccc);
           END
           ELSE
           BEGIN
                TimeSlice;
                IF (OnlineTime<>'Offline') THEN
                BEGIN
                     Temp := _String(Round(ElapsedTimeInSecs(Timer)/60))+'m';
                     Temp := _PadRight(Temp,7);
                     IF Temp<>OnlineTime THEN
                     BEGIN
                          OnlineTime := Temp;
                          UpdateOnlineTime;
                     END;
                     IF NOT(bsCarrierDetected) THEN
                     BEGIN
                          IsOnline   := False;
                          OnlineTime := 'Offline';
                          ActualBaud := bsReturnRate(NodeInfo.BaudRate,NodeInfo.ComDevice);
                          UpdateConnectRate;
                          UpdateOnlineTime;
                     END;
                END;
           END;
     UNTIL OuttaHere;
     _HideCursor;

     {Set Back To Original Mode}
     NumLines := SaveNumLines;
     SetOurVideoMode;

     RestoreScreen(4);
     Dispose(FileQueue);
END;


END.