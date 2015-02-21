{$I DEFINES.INC}
UNIT GfxProto;


INTERFACE


FUNCTION  GetYAPPAck                                         : Boolean;
FUNCTION  ReceiveYAPP     (FName: String; Progress: Boolean) : Boolean;
FUNCTION  GetVariable     (Work: Byte; Arg: Longint)         : String;
PROCEDURE RequestResource (FName: String);


IMPLEMENTATION


USES ApCom,ApPort,ApTimer,Globals,BsComp,ApMisc,Crt,BsFile,
     AnsiSide,Gr2_Bp,BsGraph,_Win,_Text,Shotgun,FMode,BsString;


PROCEDURE RequestResource(FName: String);
VAR  Temp      : String;
     Temp2     : String;
     c         : Char;
     Ext       : String[3];
     BytesSent : Word;
     Status    : Boolean;
BEGIN
     Temp := #255+FName+#13;
     PutBlockDirect(BBSPort,Temp[1],Length(Temp),BytesSent);
     c := #0;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,c);
                IF c=#255 THEN
                BEGIN
                     GetStringTimeout(BBSPort,Temp,255,[#13],YappDelay);
                     Delete(Temp,1,1);
                     DEC(Temp[0]);
                     PutChar(BBSPort,#255);
                     Ext := _GetFileExtension(Temp);
                     Temp2 := _NoExtension(Temp);
                     IF ((Ext='IMG') OR (Ext='FNT') OR (Ext='VOC') OR (Ext='FLI'))
                        THEN Status := ReceiveYAPP(RESOURCES+Temp2+'.$$$',True)
                        ELSE Status := ReceiveYAPP(RESOURCES+Temp2+'.$$$',False);
                     IF Status THEN pDecompressFile(RESOURCES+Temp2+'.$$$',RESOURCES+Temp2+'.'+Ext);
                     _EraseFile(RESOURCES+Temp2+'.$$$');
                     PutChar(BBSPort,#252);
                     Exit;
                END;
           END
           ELSE IF NoCarrier THEN C := #254;
     UNTIL c=#254;
END;


FUNCTION GetVariable(Work: Byte; Arg: Longint): String;
VAR  InString  : String;
     BytesSent : Word;
BEGIN
     CASE Work OF
     114,
     115: BEGIN
               InString := #255#205+Chr(Work)+#13;
               PutBlockDirect(BBSPort,InString[1],Length(InString),BytesSent);
               InString := _String(Arg)+#13;
               PutBlockDirect(BBSPort,InString[1],Length(InString),BytesSent);
               GetStringTimeout(BBSPort,InString,255,[#13],YappDelay);
               DEC(InString[0]);
               GetVariable := InString;
          END;
     ELSE BEGIN
               InString := #255#205+Chr(Work)+#13;
               PutBlockDirect(BBSPort,InString[1],Length(InString),BytesSent);
               GetStringTimeout(BBSPort,InString,255,[#13],YappDelay);
               DEC(InString[0]);
               GetVariable := InString;
          END;
     END;
END;


PROCEDURE ClearProgress;
BEGIN
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(80,GraphMaxY-40,184,GraphMaxY-10,GrFill);
     GrSetClipping(GrClip);
     GrProtectMouse(GrNoProtect);
END;


PROCEDURE StartProgress;
BEGIN
     GrSetMouseProtect(0,YWindow,GraphMaxX,GraphMaxY);
     GrProtectMouse(GrProtect);
     GrSetClipping(GrNoClip);
     InvertedBox(80,GraphMaxY-24,184,GraphMaxY-10);
     GrSetFillStyle(GrFSolid,9,GrOpaque);
     OutTextXY(104,GraphMaxY-40,0,255,1,'Resource');
END;


FUNCTION GetYAPPAck: Boolean;
VAR  C   : Char;
     TTT : EventTimer;
BEGIN
     NewTimer(TTT,YappDelay);
     C := #0;
     REPEAT
                IF CharReady(BBSPort) THEN GetChar(BBSPort,C)
           ELSE IF NoCarrier THEN c := #254;
     UNTIL ((c=#254) OR (c=#255) OR (TimerExpired(TTT)));
     IF C=#255 THEN GetYAPPAck := True
               ELSE GetYAPPAck := False;
END;


FUNCTION ReceiveYAPP(FName: String; Progress: Boolean): Boolean;
TYPE Needed_Stuff  = RECORD
     Expected      : Word;
     Crc           : Longint;
     END;
VAR  Buffer    : Array[1..4096] Of Byte;
     FSize     : Longint;
     TName     : String;
     GotBytes  : Longint;
     Needed    : Needed_Stuff;
     Crc2      : Longint;
     BytesSent : Word;
     Loop      : Word;
     Cps       : Longint;
     Percent   : Word;
     SavePerc  : Word;
     Errors    : Byte;
LABEL            Abort;
BEGIN
     GetBlockTimeOut(BBSPort,FSize,4,BytesSent,[],YappDelay);
     PutChar(BBSPort,#255);
     GotBytes := 0;
     Errors   := 0;
     SavePerc := 255;
     IF Progress THEN StartProgress;
     TBufferedFile.OpenFile(FName,SetFileMode);
     REPEAT
           GetBlockTimeOut(BBSPort,Needed,6,BytesSent,[],YappDelay); {Block Size + Crc}
           GetBlockTimeOut(BBSPort,Buffer,Needed.Expected,BytesSent,[],YappDelay); {Data}
           IF Needed.Expected=BytesSent THEN
           BEGIN
                Crc2 := $FFFFFFFF;
                FOR Loop := 1 TO Needed.Expected DO Crc2 := UpdateCrc32(Buffer[Loop],Crc2);
                IF Crc2=Needed.Crc THEN
                BEGIN
                     PutChar(BBSPort,#255);
                     INC(GotBytes,Needed.Expected);
                     {SetRTS(BBSPort,False);}
                     TBufferedFile.BlkWrite(Buffer,Needed.Expected);
                     {SetRTS(BBSPort,True);}
                     IF Progress THEN
                     BEGIN
                          Percent := Trunc((GotBytes/FSize)*100);
                          IF (Percent<>SavePerc) THEN
                          BEGIN
                               SavePerc := Percent;
                               GrDrawRect(82,GraphMaxY-22,82+Percent,GraphMaxY-12,GrFill);
                          END;
                     END;
                END
                ELSE
                BEGIN
                     Delay(500);
                     FlushInBuffer(BBSPort);
                     PutChar(BBSPort,#254);
                     INC(Errors);
                     IF ((Errors=8) OR (NoCarrier)) THEN GOTO Abort;
                END;
           END
           ELSE
           BEGIN
                Delay(500);
                FlushInBuffer(BBSPort);
                PutChar(BBSPort,#254);
                INC(Errors);
                IF ((Errors=8) OR (NoCarrier)) THEN GOTO Abort;
           END;
     UNTIL (GotBytes>=FSize);
     TBufferedFile.CloseFile;
     IF Progress THEN ClearProgress;
     ReceiveYAPP := True;
     Exit;
     Abort:
     TBufferedFile.CloseFile;
     _EraseFile(FName);
     IF Progress THEN ClearProgress;
     ReceiveYAPP := False;
     Exit;
END;


END.