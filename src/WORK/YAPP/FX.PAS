{$I DEFINES.INC}
UNIT Fx;


{$F-}


INTERFACE


PROCEDURE SaveTextScreen;
PROCEDURE LoadTextScreen;
PROCEDURE TransmitFiles;
PROCEDURE ReceiveFiles(Filename: String);


IMPLEMENTATION


USES  ApAbsPcl,ApZmodem,ApCom,Crt,Dos,Tx2_Bp,Gr2_Bp,BsMulti,BsString,
      BsGraph,Globals,BsVideo,ApMisc,ApTimer,ApPort,BsTime,BsFile,BsKeys;


TYPE  TransferModeType  = (Transmit,Receive);
VAR   PROTO             : ProtocolRecPtr;
      TransferMode      : TransferModeType;
      SrcFileName       : String[80];

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
TYPE File_Queue = RECORD
     FName      : String[80];
     END;
VAR  FileQueue  : File_Queue;
     FFileQueue : File Of File_Queue;
BEGIN
     INC(CurrentFileNum);
     IF (CurrentFileNum>FilesInQueue) THEN
     BEGIN
          FName := '';
          GetNextFile := False;
     END
     ELSE
     BEGIN
          ASSIGN(FFileQueue,GST_Directory+'\FQUEUE.TMP');
          RESET(FFileQueue);
          SEEK(FFileQueue,CurrentFileNum-1);
          READ(FFileQueue,FileQueue);
          CLOSE(FFileQueue);
          FName := FileQueue.FName;
          GetNextFile := True;
     END;
END;
{$F-}


PROCEDURE OutTextXYFR(x,y,f,b: word; s: String);
VAR  Width : Integer;
BEGIN
     Width := TxStrWidth(s);
     txSetFace(txNormal);
     txSetColor(f,b);
     txOutTextXy(s,x-Width,y);
END;


PROCEDURE OutTextXY(x,y,f,b: word; s: String);
VAR  Error : Integer;
BEGIN
     txSetFace(txNormal);
     txSetColor(f,b);
     txOutTextXy(s,x,y);
END;


PROCEDURE SaveTextScreen;
VAR  TextSaveScreen  : Array[1..4000] Of Byte;
     FTextSaveScreen : File;
BEGIN
     Move(MEM[SegB800:0],TextSaveScreen,4000);
     ASSIGN(FTextSaveScreen,GST_Directory+'\XFER$$$$.SCR');
     REWRITE(FTextSaveScreen,1);
     BLOCKWRITE(FTextSaveScreen,TextSaveScreen,4000);
     CLOSE(FTextSaveScreen);
END;

PROCEDURE LoadTextScreen;
VAR  TextSaveScreen  : Array[1..4000] Of Byte;
     FTextSaveScreen : File;
BEGIN
     ASSIGN(FTextSaveScreen,GST_Directory+'\XFER$$$$.SCR');
     {$I-}RESET(FTextSaveScreen,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          BLOCKREAD(FTextSaveScreen,TextSaveScreen,4000);
          CLOSE(FTextSaveScreen);
          ERASE(FTextSaveScreen);
          Move(TextSaveScreen,MEM[SegB800:0],4000);
     END;
END;

{$F+}
PROCEDURE WindowStatus(P: ProtocolRecPtr; Starting,Ending: Boolean);
VAR  CurFileSize           : Longint;
     CurFileName           : String;
     CurBytesTransferred   : Longint;
     CurBytesRemaining     : Longint;
     R                     : Longint;
     ActualCPS             : Longint;
     CurElapsedTics        : Longint;

     PROCEDURE ClearStatus;
     BEGIN
          IF IsGfx THEN
          BEGIN
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(120,GraphMaxY-45,205,GraphMaxY-2,GrFill);
          END;
     END;

BEGIN
     IF Starting THEN
     BEGIN
          IF IsGfx THEN
          BEGIN
               OutTextXYFR(112,GraphMaxY-45,0,7,'File:');
               OutTextXYFR(112,GraphMaxY-31,0,7,'Size:');
               OutTextXYFR(112,GraphMaxY-17,0,7,'Sent:');
          END
          ELSE
          BEGIN
               _HideCursor;
               SaveTextScreen;
               FastWrite('     RECEIVING FILE(S)                          ',8,18,31);
               FastWrite('                                                ',9,18,31);
               FastWrite('    Protocol:                  Speed:           ',10,18,31);
               FastWrite('        File:                   Time:           ',11,18,31);
               FastWrite('        Size:                   Left:           ',12,18,31);
               FastWrite('        Sent:                    CPS:           ',13,18,31);
               FastWrite('                                                ',14,18,31);
               FastWrite('                                                ',15,18,31);
               FastWrite('ÚÄÄÄ',8,18,25);
               FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',8,41,25);
               FastWrite('¿',8,65,16);
               FastWrite('³',9,18,25);  FastWrite('³',9,65,16);
               FastWrite('³',10,18,25); FastWrite('³',10,65,16);
               FastWrite('³',11,18,25); FastWrite('³',11,65,16);
               FastWrite('³',12,18,25); FastWrite('³',12,65,16);
               FastWrite('³',13,18,25); FastWrite('³',13,65,16);
               FastWrite('³',14,18,25); FastWrite('³',14,65,16);
               FastWrite('À',15,18,25);
               FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',15,19,16);
               FastWrite(_PadRight(_String(YappDef.Baud),8),10,57,27);
          END;
     END
     ELSE IF Ending THEN
     BEGIN
          IF IsGfx THEN
          BEGIN
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(80,GraphMaxY-45,205,GraphMaxY-2,GrFill);
          END
          ELSE
          BEGIN
               LoadTextScreen;
               _ShowCursor;
          END;
     END
     ELSE
     BEGIN
          WITH P^.PData^ DO
          BEGIN
               CurFileSize := GetFileSize(P);
               CurFileName := GetFileName(P);
               CurBytesTransferred := GetBytesTransferred(P);
               CurBytesRemaining   := GetBytesRemaining(P);
               CurElapsedTics      := GetElapsedTics(P);
               IF ((CurFileSize=0) OR (CurBytesTransferred=0)) THEN ClearStatus;
               IF IsGfx THEN
               BEGIN
                    OutTextXY(120,GraphMaxY-17,0,7,_String(CurBytesTransferred));
                    OutTextXY(120,GraphMaxY-31,0,7,_String(CurFileSize));
                    OutTextXY(120,GraphMaxY-45,0,7,CurFileName);
               END
               ELSE
               BEGIN
                    FastWrite(_PadRight(CurFileName,12),11,33,27);
                    FastWrite(_PadRight(_String(CurFileSize),12),12,33,27);
                    FastWrite(_PadRight(_String(CurBytesTransferred),12),13,33,27);
                    FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurFileSize)),7),11,57,27);
                    FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurBytesRemaining)),7),12,57,27);
                    IF CurElapsedTics>0 THEN
                    BEGIN
                         R         := CurBytesTransferred-GetInitialFilePos(P);
                         ActualCPS := Trunc(R/(CurElapsedTics/18.2));
                    END
                    ELSE ActualCPS := 0;
                    FastWrite(_PadRight(_String(ActualCPS),8),13,57,27);
               END;
          END;
     END;
END;
{$F-}

PROCEDURE TransferFiles;
BEGIN
     IF IsGfx THEN
     BEGIN
          GrSetMouseProtect(0,YWindow,GraphMaxX,GraphMaxY);
          GrProtectMouse(GrProtect);
          GrSetClipping(GrNoClip);
     END;
     SetAbortFunc(BBSPort,KbdAbort);
     InitZmodem(PROTO,BBSPort);
     IF GetAsyncStatus=ecOk THEN
     BEGIN
          IF transferMode=transmit THEN SetNextFileFunc(PROTO,GetNextFile);
          SetShowStatusProc(PROTO,WindowStatus);
          SetFinishWaitZM(PROTO,Secs2Tics(20),3);
          SetHandshakeWait(PROTO,Secs2Tics(5),10);
          SetRecoverOption(PROTO,True);
          SetActualBps(PROTO,YappDef.Baud);
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
     IF IsGfx THEN
     BEGIN
          GrProtectMouse(GrNoProtect);
          GrSetClipping(GrClip);
     END;
     SetAbortFunc(BBSPort,NoAbortFunc);
END;


PROCEDURE Send;
BEGIN
     PutStringTimeout(BBSPort,#255#252#13,YappDelay);
END;


PROCEDURE Wait;
VAR  Temp : String;
     Good : Boolean;
     TTT  : EventTimer;
BEGIN
     Good := False;
     NewTimer(TTT,YappDelay);
     REPEAT
           GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
           IF Pos(#255#252#13,Temp)<>0 THEN Good := True;
           IF TimerExpired(TTT) THEN Good := True;
           IF NOT(CheckDCD(BBSPort)) THEN Good := True;
     UNTIL Good;
END;


PROCEDURE DoReceiveHandShake;
BEGIN
     IF NOT(Disconnected) THEN _Delay(2000);
     IF NOT(Disconnected) THEN Send;
     IF NOT(Disconnected) THEN Wait;
     IF NOT(Disconnected) THEN Send;
     IF NOT(Disconnected) THEN Wait;
END;


PROCEDURE DoTransmitHandShake;
BEGIN
     IF NOT(Disconnected) THEN _Delay(2000);
     IF NOT(Disconnected) THEN Wait;
     IF NOT(Disconnected) THEN Send;
     IF NOT(Disconnected) THEN Wait;
     IF NOT(Disconnected) THEN Send;
END;


PROCEDURE TransmitFiles;
BEGIN
     Doing_Receive  := False;
     WeAbort        := False;
     TransferMode   := Transmit;
     CurrentFileNum := 0;
     TransferFiles;
     PutStringTimeout(BBSPort,'OO'+#13,YappDelay);
     IF IsGfx THEN DoTransmitHandShake;
     _EraseFile(GST_Directory+'\FQUEUE.TMP');
END;


PROCEDURE ReceiveFiles(Filename: String);
BEGIN
     Doing_Receive  := True;
     WeAbort        := False;
     TransferMode   := Receive;
     SrcFilename    := FileName;
     CurrentFileNum := 0;
     TransferFiles;
     IF IsGfx THEN DoReceiveHandShake;
END;


END.
