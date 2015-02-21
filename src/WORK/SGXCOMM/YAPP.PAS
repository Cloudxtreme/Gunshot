{$I DEFINES.INC}
UNIT YAPP;


INTERFACE


FUNCTION TransmitYAPP (FName: String; LogIt: Boolean) : Boolean;
FUNCTION GetYAPPAck                                   : Boolean;


IMPLEMENTATION


USES ApTimer,ApCom,ApMisc,ApPort,Globals,BsString,
     Carrier,BsLog,MkFFile,FMode,BsFile;


FUNCTION GetYAPPAck: Boolean;
VAR  C   : Char;
     TTT : EventTimer;
BEGIN
     NewTimer(TTT,YappDelay);
     C := #0;
     REPEAT
           IF CharReady(BBSPort) THEN GetChar(BBSPort,C)
                                 ELSE CheckForCarrier;
     UNTIL ((c=#254) OR (c=#255) OR (TimerExpired(TTT)));
     IF C=#255 THEN GetYAPPAck := True
               ELSE GetYAPPAck := False;
END;


FUNCTION TransmitYAPP(FName: String; LogIt: Boolean): Boolean;
TYPE Needed_Stuff  = RECORD
     BytesRead     : Word;
     Crc           : Longint;
     END;
VAR  Needed        : Needed_Stuff;
     Buffer        : Array[1..4096] Of Byte;
     FSize         : Longint;
     Loop          : Word;
     BytesSent     : Word;
     Errors        : Byte;
     TTT           : EventTimer;
     CPS           : Longint;
LABEL                OverAgain,Abort;

     FUNCTION SendYAPPHeader: Boolean;
     BEGIN
          PutBlockTimeout(BBSPort,FSize,4,BytesSent,YappDelay);
          IF GetYAPPAck THEN SendYAPPHeader := True
                        ELSE SendYAPPHeader := False;
     END;

BEGIN
     IF NOT(_FileExists(FName)) THEN
     BEGIN
          TransmitYAPP := False;
          Exit;
     END;
     TBufferedFile.OpenFile(FName,SetFileMode);
     FSize  := TBufferedFile.RawSize;
     Errors := 0;
     IF NOT(SendYAPPHeader) THEN
     BEGIN
          TBufferedFile.CloseFile;
          TransmitYAPP := False;
          Exit;
     END;
     IF LogIt THEN NewTimer(TTT,1440*60);
     REPEAT
           IF RemoteYappVersion>=612
              THEN TBufferedFile.BlkRead(Buffer,4096,Needed.BytesRead)
              ELSE TBufferedFile.BlkRead(Buffer,1024,Needed.BytesRead);
           IF (Needed.BytesRead<>0) THEN
           BEGIN
                {Create The Crc}
                Needed.Crc := $FFFFFFFF;
                FOR Loop := 1 TO Needed.BytesRead DO Needed.Crc := UpdateCrc32(Buffer[Loop],Needed.Crc);
                OverAgain:
                FlushInBuffer(BBSPort);
                PutBlockDirect(BBSPort,Needed,6,BytesSent);                {Block Size + Crc}
                PutBlockDirect(BBSPort,Buffer,Needed.BytesRead,BytesSent); {Data}
                IF NOT(GetYAPPAck) THEN
                BEGIN
                     apDelay(500);
                     INC(Errors);
                     INC(SessionErrors);
                     IF Errors=8 THEN GOTO Abort;
                     GOTO OverAgain;
                END;
           END;
     UNTIL Needed.BytesRead=0;
     TBufferedFile.CloseFile;
     TransmitYAPP := True;
     IF LogIt THEN
     BEGIN
          CPS := Trunc(FSize/ElapsedTimeInSecs(TTT));
          bsWriteLog('Resource: '+FName+'  CPS: '+_String(CPS),True);
     END;
     Exit;
     Abort:
     TBufferedFile.CloseFile;
     TransmitYAPP := False;
     Exit;
END;


END.
