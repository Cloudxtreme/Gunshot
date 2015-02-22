{$I DEFINES.INC}
UNIT XFer;


INTERFACE


PROCEDURE TransmitFile(Filename: String; Protocl: Byte);
PROCEDURE ReceiveFiles(Filename: String; Protocl: Byte; DoDupes: Boolean);


IMPLEMENTATION


USES {$IFNDEF MSDOS}VideoUtils,{$ENDIF}ApAbsPcl,ApXmodem,ApYmodem,ApZmodem,Globals,Crt,ApTimer,BsVideo,
     BsString,ApCom,ApPort,Dos,ApMisc,BsMulti,BsLog,SaveScrn,CDS,
     MkFFile,FMode,BsFile,BsTime,BsKeys;


TYPE InfoRec  = RECORD
     Protocol   : Array[1..2] Of Word;
     FileName   : Array[1..2] Of Word;
     Size       : Array[1..2] Of Word;
     Sent       : Array[1..2] Of Word;
     Speed      : Array[1..2] Of Word;
     Time       : Array[1..2] Of Word;
     Left       : Array[1..2] Of Word;
     CPS        : Array[1..2] Of Word;
     END;
TYPE TransferModeType    = (Transmit,Receive);
VAR  TProtocol           : Byte;
     TransferMode        : TransferModeType;
     SrcFileName         : String[80];
     Info                : InfoRec;
     SavedCursorX        : Word;
     SavedCursorY        : Word;
     LastCPS             : Longint;
     CheckThoseDupes     : Boolean;
     PROTO               : ProtocolRecPtr;

{$F+}
FUNCTION CheckForDupes(F : ProtocolRecPtr): Boolean;
VAR  Strr         : String;
     FileOk       : Boolean;
     FA000000     : FFileObj;
     FIL          : FFileObj;
     faBytesRead  : Word;
     filBytesRead : Word;
BEGIN
     FileOk := True;
     IF ((transferMode=receive) AND (CheckThoseDupes)) THEN
     BEGIN
       IF System_Info.CheckDupes=1 THEN
       BEGIN
         strr := _UpperCase(_NoExtension(GetFileName(F)));
         FA000000.Init(32768);
         FIL.Init(16384);
         FA000000.OpenFile(DATA_Directory+'\FA000000.DAT',SetFileMode);
         REPEAT
           FA000000.BlkRead(FileAreas,SizeOf(FileAreas),faBytesRead);
           IF (faBytesRead<>0) THEN
           BEGIN
             IF (FileAreas.CD_ROM<>0) THEN
             BEGIN
               IF (System_Info.CheckDupesCD=1) THEN
               BEGIN
                 IF _FileExists(FileAreas.dos_name+'.FIL') THEN
                 BEGIN
                   FIL.OpenFile(FileAreas.dos_name+'.FIL',SetFileMode);
                   REPEAT
                     FIL.BlkRead(FileDefs,SizeOf(FileDefs),filBytesRead);
                     IF (filBytesRead<>0) THEN
                     BEGIN
                       IF _UpperCase(_NoExtension(FileDefs.file_name))=Strr THEN FileOk := False;
                     END;
                   UNTIL ((filBytesRead=0) OR (FileOk=False));
                   FIL.CloseFile;
                 END;
               END;
             END
             ELSE IF NOT(FileAreas.PassThrough) THEN
             BEGIN
               IF _FileExists(FileAreas.Area_Path+Strr+'.*') THEN FileOk := False;
             END;
           END;
         UNTIL ((faBytesRead=0) OR (FileOk=False));
         FA000000.CloseFile;
         FA000000.Done;
         FIL.Done;
       END;
     END;
     CheckForDupes := FileOk;
END;
{$F-}

{$F+}
FUNCTION KbdAbort: Boolean;
VAR  Ch      : Char;
     Aborted : Boolean;
BEGIN
     Aborted := False;
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
          NewTimerSecs(CarrierTimer,4);
          IF KeyPressed THEN
          BEGIN
               Ch := ReadKey;
               IF Ch = #0 THEN Ch := ReadKey;
               IF Ch = #27 THEN
               BEGIN
                    WeAbort := True;
                    Aborted := True;
               END;
          END;
          IF NOT(CheckDCD(BBSPort)) THEN Aborted := True;
     END;
     KbdAbort := Aborted;
END;
{$F-}

{$F+}
FUNCTION GetNextFile(PROTO: ProtocolRecPtr; VAR FName: PathStr): Boolean;
BEGIN
     INC(CurrentFileNum);
     FName := FileQueueList[CurrentFileNum];
     IF (CurrentFileNum>FilesToSend) THEN
     BEGIN
          GetNextFile := False;
          FName       := '';
     END
     ELSE GetNextFile := True;
END;
{$F-}

{$F+}
PROCEDURE LogFileActivity(P : ProtocolRecPtr; LogFileStatus : LogFileType);
VAR  TFile : Text;
BEGIN
     CASE LogFileStatus OF
     lfReceiveOk     : BEGIN
                            FileTransferSuccess := True;
                            ASSIGN(TFile,NODE_Directory+'\NEWFILES.$$$');
                            {$I-}APPEND(TFile);{$I+}
                            IF IOResult<>0 THEN REWRITE(TFile);
                            WRITELN(TFile,_PadRight(_NoPath(GetPathName(P)),14)+
                                          _PadLeft(_String(_FileSize(GetPathName(P))),9));
                            CLOSE(TFile);
                       END;
     lfReceiveFail   : _EraseFile(GetPathName(P));
     lfTransmitOk    : IF CurrentFileNum=0 THEN
                       BEGIN
                            TaggedFiles[1].FileCPS := LastCPS;
                            TaggedFiles[1].TransferOk := True;
                       END
                       ELSE
                       BEGIN
                            TaggedFiles[CurrentFileNum].FileCPS := LastCPS;
                            TaggedFiles[CurrentFileNum].TransferOk := True;
                       END;
     lfTransmitFail,
     lfTransmitSkip  : IF (CurrentFileNum<>0) THEN TaggedFiles[CurrentFileNum].TransferOk := False
                                              ELSE TaggedFiles[1].TransferOk := False;
     END;
END;
{$F-}

PROCEDURE Shadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
{$IFDEF MSDOS}
          Mem[SegB800:x] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          VideoUtils.SetAttrAt(8, Loop+1, yy2+1);
{$ENDIF}
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
{$IFDEF MSDOS}
          Mem[SegB800:y] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          VideoUtils.SetAttrAt(8, xx2+1, Loop+1);
{$ENDIF}
          INC(y,160);
     END;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
BEGIN
     Shadow(x1,y1,x2,y2);
     TextBackGround(1);
     FOR LoopY := y1 TO y2 DO
     BEGIN
          GOTOXY(x1,LoopY);
          IF LoopY=y1 THEN
          BEGIN
               TextColor(9);
               WRITE('Ú');
               FOR Loop2 := x1+1 TO x2-1 DO WRITE('Ä');
               TextColor(0);
               WRITE('¿');
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               TextColor(9);
               WRITE('À');
               TextColor(0);
               FOR Loop2 := x1+1 TO x2-1 DO WRITE('Ä');
               WRITE('Ù');
          END
          ELSE
          BEGIN
               TextColor(9);
               WRITE('³');
               TextColor(0);
               FOR Loop2 := x1+1 TO x2-1 DO WRITE(' ');
               WRITE('³');
          END;
     END;
     Title := '  '+Title+'  ';
     GotoXy(x1+3,y1);
     TextBackGround(1);
     TextColor(15);
     WRITE(Title);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop : Word;
BEGIN
     TextBackground(1);
     TextColor(0);
     GotoXY(x1,y1);
     WRITE('Ú');
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     TextColor(9);
     WRITE('¿');
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          GotoXY(x1,loop);
          TextColor(0);  WRITE('³');
          GotoXY(x2,loop);
          TextColor(9); WRITE('³');
     END;
     GotoXY(x1,y2);
     TextColor(0);  WRITE('À');
     TextColor(9);
     FOR Loop := x1+1 TO x2-1 DO WRITE('Ä');
     WRITE('Ù');
END;


{$F+}
PROCEDURE WindowStatus(P: ProtocolRecPtr; Starting,Ending: Boolean);
CONST Progress : String[30] = 'ÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛÛ';
VAR   CurFileSize         : Longint;
      CurBytesRemaining   : Longint;
      CurBytesTransferred : Longint;
      CurElapsedTics      : Longint;
      CurProtocol         : Longint;
      LastBytesSent       : Longint;
      S                   : String;
      Temp                : String;
      TheAttr             : Word;
      Work                : Word;
      ActualCPS           : Longint;
      R                   : Longint;
      Seconds             : Longint;

      PROCEDURE ClearProgress;
      BEGIN
           TheAttr := 1;
           FastWrite('±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±',15,27,TheAttr);
      END;

BEGIN
     IF Starting THEN
     BEGIN
          Info.Protocol[1] := 32;  Info.Protocol[2] := 10;
          Info.FileName[1] := 32;  Info.FileName[2] := 11;
          Info.Size[1]     := 32;  Info.Size[2]     := 12;
          Info.Sent[1]     := 32;  Info.Sent[2]     := 13;
          Info.Speed[1]    := 56;  Info.Speed[2]    := 10;
          Info.Time[1]     := 56;  Info.Time[2]     := 11;
          Info.Left[1]     := 56;  Info.Left[2]     := 12;
          Info.CPS[1]      := 56;  Info.CPS[2]      := 13;
          IF transferMode=receive
             THEN DrawWindow(18,8,65,17,'RECEIVING FILE(S)')
             ELSE DrawWindow(18,8,65,17,'SENDING FILE(S)');
          TheAttr := 27;
          FastWrite(' Protocol:                  Speed:  ',10,21,TheAttr);
          FastWrite('     File:                   Time:  ',11,21,TheAttr);
          FastWrite('     Size:                   Left:  ',12,21,TheAttr);
          FastWrite('     Sent:                    CPS:  ',13,21,TheAttr);
          {Progress indicator}
          InvertedBox(25,14,58,16);
          ClearProgress;
          {Baud Rate}
          TheAttr := 31;
          FastWrite(_String(ActualBaud),Info.Speed[2],Info.Speed[1],TheAttr);
          {Protocol}
          CurProtocol := GetProtocol(P);
          S           := ProtocolTypeString[CurProtocol];
          CASE GetCheckType(P) OF
          bcCrc16     : S := S+'/16';
          bcCrc32     : S := S+'/32';
          bcCrcK      : S := S+'/Crc';
          END;
          FastWrite(S,Info.Protocol[2],Info.Protocol[1],TheAttr);
     END;
     {Update the data areas}
     IF ((NOT(Starting)) AND (NOT(Ending))) THEN
     BEGIN
          WITH P^.PData^ DO
          BEGIN
               TheAttr             := 31;
               CurFileSize         := GetFileSize(P);
               CurBytesRemaining   := GetBytesRemaining(P);
               CurBytesTransferred := GetBytesTransferred(P);
               CurElapsedTics      := GetElapsedTics(P);
               LastFilesBytesSent  := CurBytesTransferred;
               {File Name}
               FastWrite(_PadRight(GetFileName(P),12),Info.FileName[2],Info.FileName[1],TheAttr);
               {File Size}
               IF CurFileSize=0 THEN S := ''
                                ELSE S := _String(CurFileSize);
               FastWrite(_PadRight(S,9),Info.Size[2],Info.Size[1],TheAttr);
               {Estimated time}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurFileSize)),7),
                         Info.Time[2],Info.Time[1],TheAttr);
               {Time remaining}
               FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurBytesRemaining)),7),
                         Info.Left[2],Info.Left[1],TheAttr);
               {Bytes Transferred}
               FastWrite(_PadRight(_String(CurBytesTransferred),9),Info.Sent[2],Info.Sent[1],TheAttr);
               {CPS}
               IF CurElapsedTics>0 THEN
               BEGIN
                    R         := CurBytesTransferred-GetInitialFilePos(P);
                    ActualCPS := Trunc(R/(CurElapsedTics/18.2));
                    LastCPS   := ActualCPS;
               END
               ELSE ActualCPS := 0;
               FastWrite(_PadRight(_String(ActualCPS),6),Info.CPS[2],Info.CPS[1],TheAttr);
               {Progress Indicator}
               IF CurFileSize=0 THEN ClearProgress
               ELSE
               BEGIN
                    Work := Trunc((CurBytesTransferred/CurFileSize)*30);
                    IF ((Work>0) AND (Work<31)) THEN
                    BEGIN
                         Move(Progress[1],Temp[1],Work);
                         Temp[0] := Chr(Work);
                         TheAttr := 9;
                         FastWrite(Temp,15,27,TheAttr);
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
     NewTimerSecs(CarrierTimer,4);
     CurrentFileNum := 0;
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
                           SetAcceptFileFunc(PROTO,CheckForDupes);
                           SetActualBps(PROTO,ActualBaud);
                           SetLogFileProc(PROTO,LogFileActivity);
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
                           SetBlockWait(PROTO,RelaxedBlockWait);
                           DoFinishParams;
                           SetShowStatusProc(PROTO,WindowStatus);
                           SetOverwriteOption(PROTO,WriteRename);
                           SetAcceptFileFunc(PROTO,CheckForDupes);
                           SetActualBps(PROTO,ActualBaud);
                           SetLogFileProc(PROTO,LogFileActivity);
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
                           SetAcceptFileFunc(PROTO,CheckForDupes);
                           SetRecoverOption(PROTO,True);
                           SetActualBps(PROTO,ActualBaud);
                           SetLogFileProc(PROTO,LogFileActivity);
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
     TextBackGround(0);
     TextColor(7);
END;


PROCEDURE HandleAbort;
BEGIN
     IF WeAbort THEN
     BEGIN
          _Delay(2000);
          FlushOutBuffer(BBSPort);
          FlushInBuffer(BBSPort);
     END
     ELSE
     BEGIN
          IF AbortedProtocol THEN
          BEGIN
               _Delay(2000);
               FlushOutBuffer(BBSPort);
               FlushInBuffer(BBSPort);
          END
          ELSE _Delay(2000);
     END;
END;


PROCEDURE TransmitFile(Filename: String; Protocl: Byte);
BEGIN
     bsWriteLog('Downloading file(s) from the system',False);
     CASE Protocl OF
     1:   bsWriteLog('Protocol selected:  ZModem',False);
     2:   bsWriteLog('Protocol selected:  XModem',False);
     3:   bsWriteLog('Protocol selected:  XModem-1k',False);
     4:   bsWriteLog('Protocol selected:  YModem',False);
     5:   bsWriteLog('Protocol selected:  YModem-G',False);
     END;
     WeAbort := False;
     SrcFilename := FileName;
     TransferMode := Transmit;
     AbortedProtocol := False;
     FileTransferSuccess := False;
     CASE Protocl OF
     1:   TProtocol := ZModem;
     2:   TProtocol := XModem;
     3:   TProtocol := XModem1K;
     4:   TProtocol := YModem;
     5:   TProtocol := YModemG;
     END;
     Save_Screen2;
     SavedCursorX := WhereX;
     SavedCursorY := WhereY;
     _HideCursor;
     TransferFiles;
     HandleAbort;
     Restore_Screen2;
     _ShowCursor;
     GotoXY(SavedCursorX,SavedCursorY);
END;


PROCEDURE ReceiveFiles(Filename: String; Protocl: Byte; DoDupes: Boolean);
BEGIN
     bsWriteLog('Uploading file(s) to the system',False);
     CASE Protocl OF
     1:   bsWriteLog('Protocol selected:  ZModem',False);
     2:   bsWriteLog('Protocol selected:  XModem',False);
     3:   bsWriteLog('Protocol selected:  XModem-1k',False);
     4:   bsWriteLog('Protocol selected:  YModem',False);
     5:   bsWriteLog('Protocol selected:  YModem-G',False);
     END;
     IF DoDupes THEN CheckThoseDupes := True
                ELSE CheckThoseDupes := False;
     WeAbort := False;
     SrcFilename := FileName;
     TransferMode := Receive;
     AbortedProtocol := False;
     FileTransferSuccess := False;
     CASE Protocl OF
     1:   TProtocol := ZModem;
     2:   TProtocol := XModem;
     3:   TProtocol := XModem1K;
     4:   TProtocol := YModem;
     5:   TProtocol := YModemG;
     END;
     Save_Screen2;
     SavedCursorX := WhereX;
     SavedCursorY := WhereY;
     _HideCursor;
     TransferFiles;
     HandleAbort;
     Restore_Screen2;
     _ShowCursor;
     GotoXY(SavedCursorX,SavedCursorY);
END;


END.
