{$I DEFINES.INC}
UNIT GSession;


INTERFACE


PROCEDURE DoTerminal;


IMPLEMENTATION


USES ApTimer,Globals,ApPort,ApCom,ApAnsi,DropFile,Crt,Comm,BsMulti,
     BsVideo,ApAbsPcl,ApXModem,ApYModem,ApZModem,Dos,ApMisc,BsFile,
     __Gfx,BsExec,BsString,BsKeys,BsTime;


VAR  SaveScreen2 : Array[1..4000] Of Byte;


PROCEDURE Save_Screen2;
BEGIN
     Move(MEM[SegB800:0],SaveScreen2,4000);
END;


PROCEDURE Restore_Screen2;
BEGIN
     Move(SaveScreen2,MEM[SegB800:0],4000);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     Attr1 := 16;
     Attr2 := 25;
     FastWrite('⁄',y1,x1,Attr1);
     FastWrite(_Replicate('ƒ',x2-x1-1),y1,x1+1,Attr1);
     FastWrite('ø',y1,x2,Attr2);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          FastWrite('≥',Loop,x1,Attr1);
          FastWrite('≥',Loop,x2,Attr2);
     END;
     FastWrite('¿',y2,x1,Attr1);
     FastWrite(_Replicate('ƒ',x2-x1-1),y2,x1+1,Attr2);
     FastWrite('Ÿ',y2,x2,Attr2);
END;


PROCEDURE DropShadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
          Mem[SegB800:x] := 8;
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
          Mem[SegB800:y] := 8;
          INC(y,160);
     END;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
     Temp   : String;
     Attr1  : Word;
     Attr2  : Word;
BEGIN
     IF Shad THEN DropShadow(x1,y1,x2,y2);
     Attr1 := 16;
     Attr2 := 25;
     FOR LoopY := y1 TO y2 DO
     BEGIN
          IF LoopY=y1 THEN
          BEGIN
               FastWrite('⁄',LoopY,x1,Attr2);
               FastWrite(_Replicate('ƒ',x2-x1-1),LoopY,x1+1,Attr2);
               FastWrite('ø',LoopY,x2,Attr1);
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               FastWrite('¿',LoopY,x1,Attr2);
               FastWrite(_Replicate('ƒ',x2-x1-1),LoopY,x1+1,Attr1);
               FastWrite('Ÿ',LoopY,x2,Attr1);
          END
          ELSE
          BEGIN
               FastWrite('≥',LoopY,x1,Attr2);
               FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,Attr1);
               FastWrite('≥',LoopY,x2,Attr1);
          END;
     END;
     IF (Title<>'') THEN
     BEGIN
          Title := '  '+Title+'  ';
          FastWrite(Title,y1,x1+3,31);
     END;
END;


PROCEDURE DoTerminalHelp;
TYPE ScrnType    = Array[1..4000] Of Char;
VAR  SavedScreen : ^ScrnType;
     C           : Char;
BEGIN
     New(SavedScreen);
     Move(MEM[SegB800:0],SavedScreen^,4000);
     _HideCursor;
     DrawWindow(18,8,58,18,'TERMINAL HELP',True);
     InvertedBox(20,9,56,17);
     FastWrite('PgUp ........ Send Files         ',10,22,27);
     FastWrite('PgDn ........ Receive Files      ',11,22,27);
     FastWrite('ALT-C ....... Clear The Screen   ',12,22,27);
     FastWrite('ALT-H ....... Hangup The Modem   ',13,22,27);
     FastWrite('ALT-S ....... Toggle Capture     ',14,22,27);
     FastWrite('ALT-X ....... Quit The Terminal  ',15,22,27);
     FastWrite('ALT-Z ....... DOS Shell          ',16,22,27);
     C := ReadKey;
     IF Ord(C)=0 THEN C := ReadKey;
     Move(SavedScreen^,MEM[SegB800:0],4000);
     Dispose(SavedScreen);
     _ShowCursor;
END;


PROCEDURE SaveCursor;
BEGIN
     SaveXPos := WhereX;
     SaveYPos := WhereY;
     SaveAttr := TextAttr;
     _HideCursor;
END;


PROCEDURE RestoreCursor;
BEGIN
     TextAttr := SaveAttr;
     GotoXY(SaveXPos,SaveYPos);
     _ShowCursor;
END;


FUNCTION NoCarrier: Boolean;
BEGIN
     IF NOT(CheckDCD(BBSPort)) THEN NoCarrier := True
                               ELSE NoCarrier := False;
END;


PROCEDURE UpdateConnectRate;
BEGIN
     FastWrite(_PadRight('COM'+_String(CommDef.Port)+':'+_String(ActualBaud),11),25,57,31);
END;


PROCEDURE UpdateOnlineTime;
BEGIN
     FastWrite(OnlineTime,25,70,31);
END;


PROCEDURE SetUpStartVideo;
BEGIN
     HighVideo;
     Textcolor(7);
     Textbackground(0);
     TextMode(C80);
     ClrScr;
     FastWrite(_PadRight('                 ≥                                    ≥            ≥ ',80),25,1,16);
     FastWrite('Alt-V View Help',25,2,27);
     Window(1,1,80,24);
     UpdateConnectRate;
     UpdateOnlineTime;
     Textcolor(7);
     Textbackground(0);
     GotoXY(1,1);
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
     FName := FileQueue[CurrentFileNum];
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
CONST Progress : String[30] = '€€€€€€€€€€€€€€€€€€€€€€€€€€€€€€';
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
          FastWrite('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±',15,27,1);
     END;

BEGIN
     IF Starting THEN
     BEGIN
          IF doing_receive
             THEN DrawWindow(18,8,65,17,'RECEIVING FILE(S)',True)
             ELSE DrawWindow(18,8,65,17,'SENDING FILE(S)',True);
          FastWrite(' Protocol:                  Speed:  ',10,21,27);
          FastWrite('     File:                   Time:  ',11,21,27);
          FastWrite('     Size:                   Left:  ',12,21,27);
          FastWrite('     Sent:                    CPS:  ',13,21,27);
          {Progress indicator}
          InvertedBox(25,14,58,16);
          ClearProgress;
          {Baud Rate}
          FastWrite(_String(ActualBaud),Info.Speed[2],Info.Speed[1],31);
          {Protocol}
          CurProtocol := GetProtocol(P);
          S           := ProtocolTypeString[CurProtocol];
          CASE GetCheckType(P) OF
          bcCrc16     : S := S+'/Crc16';
          bcCrc32     : S := S+'/Crc32';
          bcCrcK      : S := S+'/Crc';
          END;
          FastWrite(S,Info.Protocol[2],Info.Protocol[1],31);
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
               FastWrite(_PadRight(GetFileName(P),12),Info.FileName[2],Info.FileName[1],31);
               {File Size}
               IF CurFileSize=0 THEN S := ''
                                ELSE S := _String(CurFileSize);
               FastWrite(_PadRight(S,9),Info.Size[2],Info.Size[1],31);
               {Estimated time}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurFileSize)),7),
                         Info.Time[2],Info.Time[1],31);
               {Time remaining}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurBytesRemaining)),7),
                         Info.Left[2],Info.Left[1],31);
               {Bytes Transferred}
               FastWrite(_PadRight(_String(CurBytesTransferred),9),Info.Sent[2],Info.Sent[1],31);
               {CPS}
               IF CurElapsedTics>0 THEN
               BEGIN
                    R         := CurBytesTransferred-GetInitialFilePos(P);
                    ActualCPS := Trunc(R/(CurElapsedTics/18.2));
               END
               ELSE ActualCPS := 0;
               FastWrite(_PadRight(_String(ActualCPS),6),Info.CPS[2],Info.CPS[1],31);
               {Progress Indicator}
               IF CurFileSize=0 THEN ClearProgress
               ELSE
               BEGIN
                    Work := Trunc((CurBytesTransferred/CurFileSize)*30);
                    IF ((Work>0) AND (Work<31)) THEN
                    BEGIN
                         Move(Progress[1],Temp[1],Work);
                         Temp[0] := Chr(Work);
                         FastWrite(Temp,15,27,9);
                    END
                    ELSE ClearProgress;
               END;
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
     SetAbortFunc(BBSPort,KbdAbort);
     CASE TProtocol OF
     Xmodem,
     Xmodem1K,
     Xmodem1KG : BEGIN
                      InitXmodem(PROTO,BBSPort,(TProtocol=Xmodem1K),TProtocol=Xmodem1KG);
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
                      InitYmodem(PROTO,BBSPort,True,(TProtocol=YmodemG));
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
                           IF TransferMode=Receive THEN PutChar(BBSPort,#6);
                      END;
                 END;
     Zmodem    : BEGIN
                      InitZmodem(PROTO,BBSPort);
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
     SetAbortFunc(BBSPort,NoAbortFunc);
END;


PROCEDURE HandleAbort;
BEGIN
     IF WeAbort THEN
     BEGIN
          IF Doing_Receive THEN FlushInBuffer(BBSPort)
                           ELSE FlushOutBuffer(BBSPort);
          PutString(BBSPort,#24#24#24#24#24);
          Delay(2000);
          FlushOutBuffer(BBSPort);
          FlushInBuffer(BBSPort);
     END
     ELSE
     BEGIN
          IF AbortedProtocol THEN
          BEGIN
               Delay(2000);
               FlushOutBuffer(BBSPort);
               FlushInBuffer(BBSPort);
          END
          ELSE Delay(2000);
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
     Save_Screen2;
     TransferFiles;
     HandleAbort;
     Restore_Screen2;
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
     Save_Screen2;
     TransferFiles;
     HandleAbort;
     Restore_Screen2;
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
               IF Loop=Current THEN FastWrite(Prots[Loop],9+Loop,14,63)
                               ELSE FastWrite(Prots[Loop],9+Loop,14,31);
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
     Save_Screen2;
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
     Restore_Screen2;
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
                       THEN FastWrite('   '+Drives[Loop]+':   ',5+Loop,5,63)
                       ELSE FastWrite('   '+Drives[Loop]+':   ',5+Loop,5,27);
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
                       THEN FastWrite(Temp,5+Loop,15,63)
                       ELSE FastWrite(Temp,5+Loop,15,27);
               END
               ELSE FastWrite('                   ',5+Loop,15,31);
          END;
     END;

     PROCEDURE RedrawPath;
     BEGIN
          FastWrite('Current Path:',22,5,31);
          FastWrite(_PadRight(TheDirectory,58),22,20,31);
     END;

     PROCEDURE RedrawQueue;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 15 DO FastWrite(_PadRight(FileQueue[Loop],39),5+Loop,38,27);
     END;

     FUNCTION InQueue(InString: String): Boolean;
     VAR  IsThere : Boolean;
          Loop    : Word;
     BEGIN
          IsThere := False;
          FOR Loop := 1 TO FilesInQueue DO
          BEGIN
               IF FileQueue[Loop]=InString THEN IsThere := True;
          END;
          InQueue := IsThere;
     END;

BEGIN {68}
     IF Batch THEN MaxLimit := 15
              ELSE MaxLimit := 1;
     New(FileInfo);
     FillChar(FileInfo^,SizeOf(FileInfo^),0);
     FillChar(FileQueue,SizeOf(FileQueue),0);
     FilesInQueue := 0;
     WindowNumber := 1;
     CurrentDrive := 0;
     CurrentFile  := 1;
     SaveCursor;
     Save_Screen2;
     DrawWindow(3,3,78,23,'Upload File Queue',True);
     InvertedBox(4,5,13,21);
     InvertedBox(14,5,35,21);
     InvertedBox(36,5,77,21);
     FastWrite('Drives ',5,5,31);
     FastWrite('Files ',5,15,31);
     FastWrite('Upload Queue ',5,37,31);
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
                                    FileQueue[FilesInQueue] := TheDirectory+FileInfo^[CurrentFile].FName;
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
     Restore_Screen2;
     RestoreCursor;
     Dispose(FileInfo);
     IF FilesInQueue=0 THEN GetFileList := False
                       ELSE GetFileList := True;
END;


FUNCTION GetInput(X,Y,Len,Attr: Word; Stuff: String; Blocked: Boolean): String;
VAR  AllDone   : Boolean;
     OldX,OldY : Word;
     Loop      : Word;
     C         : Char;

     PROCEDURE Redraw;
     BEGIN
          IF Blocked THEN
          BEGIN
               FastWrite(_Replicate('±',Len),Y,X,1);
               FastWrite(Stuff,Y,X,15);
          END
          ELSE FastWrite(_PadRight(Stuff,Len),Y,X,31);
          GotoXY(X+Length(Stuff),Y);
     END;

BEGIN
     OldX := WhereX;
     OldY := WhereY;
     Redraw;
     _ShowCursor;
     c := Chr(0);
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF (Ord(c)<>0) THEN
                BEGIN
                     CASE Ord(C) OF
                     8:   BEGIN
                               IF LENGTH(Stuff)>0 THEN
                               BEGIN
                                    Delete(Stuff,LENGTH(Stuff),1);
                                    Redraw;
                               END;
                          END;
                     127: BEGIN
                               Stuff := '';
                               Redraw;
                          END;
                     13:  AllDone := True;
                     27:  BEGIN
                               Stuff := '';
                               AllDone := True;
                          END;
                     ELSE IF Ord(c)>31 THEN
                          BEGIN
                               IF LENGTH(Stuff)<Len THEN
                               BEGIN
                                    Stuff := Stuff+c;
                                    Redraw;
                               END;
                          END;
                     END;
                END
                ELSE c := ReadKey;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     _HideCursor;
     FastWrite(_PadRight(Stuff,Len),Y,X,Attr);
     GotoXY(OldX,OldY);
     GetInput := Stuff;
END;


FUNCTION GetPathName: String;
VAR  Test : File;
     Temp : String;
BEGIN
     SaveCursor;
     Save_Screen2;
     DrawWindow(5,9,75,13,'XModem Download',True);
     Temp := GetInput(10,11,50,15,'',True);
     Restore_Screen2;
     RestoreCursor;
     ASSIGN(Test,Temp);
     {$I-}REWRITE(Test);{$I+}
     IF IOResult=0 THEN
     BEGIN
          CLOSE(Test);
          ERASE(Test);
     END
     ELSE Temp := '';
     GetPathName := Temp;
END;


PROCEDURE ShowInstallIns;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     _HideCursor;
     WriteStringAnsi(#$0C);
     ASSIGN(TFile,'GSTINST.$$$');
     RESET(TFile);
     REPEAT
           READLN(TFile,Temp);
           Temp := Temp+#$0A#$0D;
           WriteStringAnsi(Temp);
     UNTIL EOF(TFile);
     CLOSE(TFile);
     ERASE(TFile);
     _ShowCursor;
END;


PROCEDURE DoTerminal;
VAR  ccc       : Char;
     OuttaHere : Boolean;
     Temp      : String;
     Temp2     : String;
     Work      : Word;
     XPos      : Word;
     GotPad    : Boolean;
     WTimer    : EventTimer;
     TTT       : EventTimer;
     Sig       : String;
     SvX       : Word;
     SvY       : Word;
     IsFirst   : Boolean;
LABEL            Skip;
BEGIN
     Info.Protocol[1] := 32;  Info.Protocol[2] := 10;
     Info.FileName[1] := 32;  Info.FileName[2] := 11;
     Info.Size[1]     := 32;  Info.Size[2]     := 12;
     Info.Sent[1]     := 32;  Info.Sent[2]     := 13;
     Info.Speed[1]    := 56;  Info.Speed[2]    := 10;
     Info.Time[1]     := 56;  Info.Time[2]     := 11;
     Info.Left[1]     := 56;  Info.Left[2]     := 12;
     Info.CPS[1]      := 56;  Info.CPS[2]      := 13;
     Offline    := False;
     OuttaHere  := False;
     CaptureOn  := False;
     IsOnline   := True;
     IsFirst    := True;
     NewTimerSecs(Timer,1440*60);
     OnlineTime := '0m     ';
     SetUpStartVideo;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                Temp   := '';
                GotPad := False;
                WHILE CharReady(BBSPort) DO
                BEGIN
                     GetChar(BBSPort,ccc);
                     Temp := Temp+ccc;
                     IF ccc=#24 THEN GotPad := True;
                     IF (ccc=#255) THEN
                     BEGIN
                          NewTimerSecs(TTT,5);
                          Temp2 := ccc;
                          REPEAT
                                IF CharReady(BBSPort) THEN
                                BEGIN
                                     GetChar(BBSPort,ccc);
                                     Temp2 := Temp2+ccc;
                                END;
                          UNTIL ((CCC=#13) OR (TimerExpired(TTT)));
                          IF ((NOT(DialDir.DoESCs)) AND (IsFirst)) THEN
                          BEGIN
                               IsFirst := False;
                               GOTO Skip;
                          END;
                          IF Temp2=#255#0#13 THEN
                          BEGIN
                               IF _FileExists('YAPP_E.EXE') THEN
                               BEGIN
                                    Save_Screen2;
                                    CreateDropFile;
                                    SvX := WhereX;
                                    SvY := WhereY;
                                    Window(1,1,80,25);
                                    ClrScr;
                                    Comm_deinit;
                                    IF DialDir.Sound THEN Sig := ' 1 $$BB$$SS$$ '
                                                     ELSE Sig := ' 0 $$BB$$SS$$ ';
                                    DoExec('YAPP_E.EXE',_String(CommDef.Port)+' '+
                                           _String(ActualBaud)+Sig+CommDef.DlDir+' -NOROM',
                                           USE_ALL,BaseDir);
                                    ChDir(BaseDir);
                                    Comm_init;
                                    Window(1,1,80,24);
                                    Restore_Screen2;
                                    GotoXY(SvX,SvY);
                                    Temp := '';
                                    IF _FileExists('YAPP16.EXE') THEN
                                    BEGIN
                                         _EraseFile('YAPP_E.EXE');
                                         _RenameFile('YAPP16.EXE','YAPP_E.EXE');
                                    END;
                                    IF _FileExists('GSTINST.$$$') THEN ShowInstallIns;
                                    IsFirst := True;
                               END
                               ELSE Temp := Temp+Temp2;
                          END
                          ELSE Temp := Temp+Temp2;
                     END;
                     IF LENGTH(Temp)=255 THEN GOTO Skip;
                     IF GotPad THEN Delay(5);
                     IF (NOT(IsOnline) AND NOT(CharReady(BBSPort))) THEN Delay(5);
                END;
                Skip:
                IF (Pos('**EMSI_REQA77E',Temp)<>0) THEN
                BEGIN
                     IF DialDir.DoESCs THEN PutString(BBSPort,#27#27);
                END;
                _HideCursor;
                WriteStringAnsi(Temp);
                _ShowCursor;
                IF NOT(IsOnline) THEN
                BEGIN
                     IF NOT(NoCarrier) THEN
                     BEGIN
                          IsOnline   := True;
                          Work       := Pos('CONNECT',Temp);
                          ActualBaud := ReturnRate(CommDef.Baud,CommDef.Device);
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
                          ReceiveFiles(CommDef.DLDir,1);
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
                     35:  HangUp;
                     45:  OuttaHere := True;
                     59:  SendCommandString(DialDir.F1,False,False);
                     60:  SendCommandString(DialDir.F2,False,False);
                     61:  SendCommandString(DialDir.F3,False,False);
                     62:  SendCommandString(DialDir.F4,False,False);
                     63:  SendCommandString(DialDir.F5,False,False);
                     64:  SendCommandString(DialDir.F6,False,False);
                     65:  SendCommandString(DialDir.F7,False,False);
                     66:  SendCommandString(DialDir.F8,False,False);
                     67:  SendCommandString(DialDir.F9,False,False);
                     68:  SendCommandString(DialDir.F10,False,False);
                     73:  BEGIN {Send Files}
                               Work := SelectProtocol;
                               IF Work<>0 THEN
                               BEGIN
                                    CASE Work OF
                                    2,3: BEGIN {XModem}
                                              IF GetFileList(GetDrives,False) THEN
                                              BEGIN
                                                   TransmitFiles(FileQueue[1],Work);
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
                                              ReceiveFiles(CommDef.DLDir,Work);
                                              UpdateOnlineTime;
                                         END;
                                    END;
                               END;
                          END;
                     71:  PutString(BBSPort,#27#91#72); {home}
                     72:  PutString(BBSPort,#27#91#65); {U arrow}
                     75:  PutString(BBSPort,#27#91#68); {L arrow}
                     77:  PutString(BBSPort,#27#91#67); {R arrow}
                     79:  PutString(BBSPort,#27#91#75); {end}
                     80:  PutString(BBSPort,#27#91#66); {D arrow}
                     83:  PutString(BBSPort,#127);      {delete}
                     119: PutString(BBSPort,#27#91#76); {ctrl+home}
                     132: PutString(BBSPort,#27#91#77); {ctrl+PgUp}
                     46:  PutString(BBSPort,#27+'[1;37m'+#27+'[40m'+chr(27)+'[2J');
                     31:  BEGIN {Screen Capture}
                               IF CaptureOn THEN CaptureOn := False
                                            ELSE CaptureOn := True;
                               Save_Screen2;
                               IF CaptureOn THEN FastWrite('!CAPTURE ON!',1,1,31)
                                            ELSE FastWrite('!CAPTURE OFF!',1,1,31);
                               _Delay(1000);
                               Restore_Screen2;
                               IF CaptureOn THEN StartCapture
                                            ELSE EndCapture;
                          END;
                     44:  BEGIN {Dos Shell}
                               Save_Screen2;
                               SvX := WhereX;
                               SvY := WhereY;
                               Window(1,1,80,25);
                               ClrScr;
                               PutEnviro('PROMPT=Enter EXIT to return to the GST Services Manager!!$_$p$g');
                               DoExec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'),USE_ALL,BaseDir);
                               ChDir(BaseDir);
                               Window(1,1,80,24);
                               Restore_Screen2;
                               GotoXY(SvX,SvY);
                          END;
                     47:  DoTerminalHelp;
                     ELSE PutChar(BBSPort,Chr(128+Ord(ccc)));
                     END;
                END
                ELSE PutChar(BBSPort,ccc);
           END
           ELSE
           BEGIN
                TimeSlice;
                IF (IsOnline) THEN
                BEGIN
                     Temp := _String(Round(ElapsedTimeInSecs(Timer)/60))+'m';
                     Temp := _PadRight(Temp,7);
                     IF (Temp<>OnlineTime) THEN
                     BEGIN
                          OnlineTime := Temp;
                          UpdateOnlineTime;
                     END;
                     IF NoCarrier THEN
                     BEGIN
                          IsOnline   := False;
                          OnlineTime := 'Offline';
                          ActualBaud := ReturnRate(CommDef.Baud,CommDef.Device);
                          UpdateConnectRate;
                          UpdateOnlineTime;
                     END;
                END;
           END;
     UNTIL OuttaHere;
     IF CaptureOn THEN EndCapture;
     CaptureOn := False;
END;


END.
