{$I DEFINES.INC}
UNIT FTSC0006;


INTERFACE


FUNCTION  YooHooSender   : Boolean;
FUNCTION  YooHooReceiver : Boolean;
PROCEDURE InitYOOHOODat  (Zone,Net,Node,Point: Word);
PROCEDURE LogTheirHelloPacket;
PROCEDURE LogOurHelloPacket;
PROCEDURE GetSessionCapabilities;


IMPLEMENTATION


USES Globals,DrawScrn,BsLog,ApTimer,FtscProd,Version,Comm,
     ApMisc,ApPort,ApCom,BsMulti,Misc,Gunshot,BsAkas,
     BsString,BsFile,BsCom,EMSI;


PROCEDURE CreateRecordsFTS6;
VAR  Loop : Word;
BEGIN
     LogTheirHelloPacket;
     FillChar(RemoteSystem,SizeOf(RemoteSystem),0);
     IF CallingOut THEN RemoteSystem.CallAddress := MailQueue^[MailQueuePointer].DestAddr
                   ELSE FillChar(RemoteSystem.CallAddress,SizeOf(RemoteSystem.CallAddress),0);
     RemoteSystem.NumberOfAkas  := 1;
     RemoteSystem.Akas[1].Zone  := TheirPacket.Zone;
     RemoteSystem.Akas[1].Net   := TheirPacket.Net;
     RemoteSystem.Akas[1].Node  := TheirPacket.Node;
     RemoteSystem.Akas[1].Point := TheirPacket.Point;
     IF TheirPacket.Password[1]<>#0 THEN
     BEGIN
          RemoteSystem.SessionPassword := '';
          FOR Loop := 1 TO 8 DO
          BEGIN
               IF TheirPacket.Password[Loop]<>#0 THEN
                  RemoteSystem.SessionPassword :=
                  RemoteSystem.SessionPassword+
                  UpCase(TheirPacket.Password[Loop]);
          END;
     END;
     RemoteSystem.BBSName := '';
     FOR Loop := 1 TO 60 DO
     BEGIN
          IF TheirPacket.BBSName[Loop]<>#0 THEN
             RemoteSystem.BBSName :=
             RemoteSystem.BBSName+
             TheirPacket.BBSName[Loop];
     END;
     RemoteSystem.Sysop := '';
     FOR Loop := 1 TO 20 DO
     BEGIN
          IF TheirPacket.Sysop[Loop]<>#0 THEN
             RemoteSystem.Sysop :=
             RemoteSystem.Sysop+
             TheirPacket.Sysop[Loop];
     END;
     RemoteSystem.Location   := 'Somewhere';
     RemoteSystem.MailerVersion := _String(TheirPacket.Product_Major)+'.'+
                                   _String(TheirPacket.Product_Minor);
     RemoteSystem.MailerName := GetProductName(TheirPacket.Product);
     StatusWindow(RemoteSystem.BBSName+', '+AddressToString(RemoteSystem.Akas[1]));
     bsWriteLog(RemoteSystem.BBSName+', '+AddressToString(RemoteSystem.Akas[1]),False);
     StatusWindow('Sysop: '+RemoteSystem.Sysop);
     bsWriteLog('Sysop: '+RemoteSystem.Sysop,False);
     StatusWindow('Using: '+RemoteSystem.MailerName+' '+RemoteSystem.MailerVersion);
     bsWriteLog('Using: '+RemoteSystem.MailerName+' '+RemoteSystem.MailerVersion,False);
END;


FUNCTION ReceiveYooHoo: Boolean;
VAR  Retries   : Byte;
     TTimer    : EventTimer;
     C         : Char;
     BytesRead : Word;
     PacketCRC : Word;
     TmpAka    : AddrType;
     WorkBuf   : Array[1..128] Of Byte;
LABEL            R1,R2,R3,R4,R5,R6,R7,R8;

     FUNCTION CrcOk: Boolean;
     VAR  Loop  : Word;
          WCrc  : Word;
          LBuf  : Array[1..2] Of Byte;
     BEGIN
          WCrc := 0;
          Move(TheirPacket,WorkBuf,SizeOf(TheirPacket));
          FOR Loop := 1 TO 128 DO WCrc := UpdateCrc(WorkBuf[Loop],WCrc);
          WCrc := UpdateCrc(0,WCrc);
          WCrc := UpdateCrc(0,WCrc);
          LBuf[1] := Hi(WCrc);
          LBuf[2] := Lo(WCrc);
          Move(LBuf[1],WCrc,2);
          IF PacketCRC=WCrc THEN CrcOk := True
                            ELSE CrcOk := False;
     END;

BEGIN
     R1:
          Retries := 0;
          NewTimerSecs(TTimer,10);
          GOTO R2;

     R2:
          PutChar(bsBBSPort,ENQ);
          GOTO R3;

     R3:
          IF TimerExpired(TTimer) THEN GOTO R4;
          IF NOT(bsCarrierDetected) THEN
          BEGIN
               ReceiveYooHoo := False;
               Exit;
          END;
          IF CharReady(bsBBSPort) THEN
          BEGIN
               GetChar(bsBBSPort,C);
               CASE C OF
               #$1F : GOTO R5;
               #$05 : GOTO R2;
               END;
          END
          ELSE TimeSlice;
          GOTO R3;

     R4:
          INC(Retries);
          IF Retries=10 THEN
          BEGIN
               ReceiveYooHoo := False;
               Exit;
          END;
          GOTO R2;

     R5:
          GetBlockTimeOut(bsBBSPort,TheirPacket,128,BytesRead,[],Secs2Tics(30));
          IF (BytesRead<>128) THEN
          BEGIN
               ReceiveYooHoo := False;
               Exit;
          END;
          GOTO R6;

     R6:
          GetBlockTimeOut(bsBBSPort,PacketCRC,2,BytesRead,[],Secs2Tics(10));
          IF (BytesRead<>2) THEN GOTO R7;
          IF NOT(CrcOk) THEN GOTO R7;
          GOTO R8;

     R7:
          PutChar(bsBBSPort,'?');
          INC(Retries);
          IF Retries=10 THEN
          BEGIN
               ReceiveYooHoo := False;
               Exit;
          END;
          GOTO R3;

     R8:
          TmpAka.Zone  := TheirPacket.Zone;
          TmpAka.Net   := TheirPacket.Net;
          TmpAka.Node  := TheirPacket.Node;
          TmpAka.Point := TheirPacket.Point;
          IF NOT(AkaIsOk(TmpAka)) THEN
          BEGIN
            TheirPacket.Zone  := 0;
            TheirPacket.Net   := 0;
            TheirPacket.Node  := 0;
            TheirPacket.Point := 0;
          END;
          CreateRecordsFTS6;
          bsClearInBuffer;
          PutChar(bsBBSPort,ACK);
          PutChar(bsBBSPort,YOOHOO);
          ReceiveYooHoo := True;
          Exit;
END;


FUNCTION SendYooHoo: Boolean;
VAR  TTimer    : EventTimer;
     BytesSent : Word;
     WorkBuf   : Array[1..128] Of Byte;
     C         : Char;
LABEL            H2,H3,H4,H5;

     PROCEDURE SendPacketCrc;
     VAR  Loop  : Word;
          WCrc  : Word;
     BEGIN
          WCrc := 0;
          Move(OurPacket,WorkBuf,SizeOf(OurPacket));
          FOR Loop := 1 TO 128 DO WCrc := UpdateCrc(WorkBuf[Loop],WCrc);
          WCrc := UpdateCrc(0,WCrc);
          WCrc := UpdateCrc(0,WCrc);
          PutChar(bsBBSPort,Char(Hi(WCrc)));
          PutChar(bsBBSPort,Char(Lo(WCrc)));
     END;

BEGIN
          LogOurHelloPacket;
     H2:
          PutChar(bsBBSPort,#$1F);
          PutBlockTimeOut(bsBBSPort,OurPacket,SizeOf(OurPacket),BytesSent,Secs2Tics(30));
          GOTO H3;

     H3:
          bsClearInBuffer;
          GOTO H4;

     H4:
          SendPacketCrc;
          GOTO H5;

     H5:
          NewTimerSecs(TTimer,30);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$06 : BEGIN
                                 SendYooHoo := True;
                                 Exit;
                            END;
                     '?'  : GOTO H2;
                     END;
                END
                ELSE TimeSlice;
          UNTIL TimerExpired(TTimer);
          SendYooHoo := False;
          Exit;
END;


FUNCTION YooHooReceiver: Boolean;
VAR   C       : Char;
      TTimer  : EventTimer;
      Retries : Byte;
LABEL V3,V4,V5,V6;
BEGIN
     Retries := 0;

     V3:
          IF NOT(ReceiveYooHoo) THEN
          BEGIN
               YooHooReceiver := False;
               Exit;
          END
          ELSE GOTO V4;

     V4:
          NewTimer(TTimer,10);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$05 : GOTO V6;
                     END;
                END
                ELSE TimeSlice;
          UNTIL TimerExpired(TTimer);
          GOTO V5;

     V5:
          bsClearInBuffer;
          INC(Retries);
          IF Retries=5 THEN
          BEGIN
               YooHooReceiver := False;
               Exit;
          END;
          GOTO V4;

     V6:
          WITH TheirPacket DO InitYOOHOODat(Zone,Net,Node,Point);
          IF SendYooHoo THEN YooHooReceiver := True
                        ELSE YooHooReceiver := False;
END;


FUNCTION YooHooSender: Boolean;
BEGIN
     WITH MailQueue^[MailQueuePointer].DestAddr DO InitYOOHOODat(Zone,Net,Node,Point);
     IF SendYooHoo THEN
     BEGIN
       IF ReceiveYooHoo THEN
       BEGIN
         GetSessionCapabilities;
         YooHooSender := True
       END
       ELSE YooHooSender := False;
     END
     ELSE YooHooSender := False;
END;


PROCEDURE InitYOOHOODat(Zone,Net,Node,Point: Word);
VAR  WorkAddr : AddrType;
     Work     : Word;
     TmpZone  : Word;
     InString : String;
     UseAd    : Byte;
     Loop2    : Word;
     Loop3    : Word;
     AllDone  : Boolean;
     LoByte   : Byte;
     HiByte   : Byte;
     CanZap   : Boolean;
     CanZip   : Boolean;
     CanFTSC  : Boolean;

     PROCEDURE MatchTheZone;
     BEGIN
          AllDone := False;
          ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          REPEAT
                READ(FNetwork,Network);
                IF Zone=Network.Net_Address.Zone THEN
                BEGIN
                     YourSystem.Address := Network.Net_Address;
                     OurPacket.Zone     := YourSystem.Address.Zone;
                     OurPacket.Net      := YourSystem.Address.Net;
                     OurPacket.Node     := YourSystem.Address.Node;
                     OurPacket.Point    := YourSystem.Address.Point;
                     AllDone := True;
                END;
          UNTIL ((EOF(FNetwork)) OR (AllDone));
          CLOSE(FNetwork);
     END;

BEGIN
     WorkAddr.Zone  := Zone;
     WorkAddr.Net   := Net;
     WorkAddr.Node  := Node;
     WorkAddr.Point := Point;
     {BASIC STUFF}
     FillChar(OurPacket,SizeOf(OurPacket),0);
     FillChar(YourSystem,SizeOf(YourSystem),0);
     OurPacket.Signal        := $6F;
     OurPacket.Hello_Version := 1;
     OurPacket.Product       := FTSCProductCode;
     {OUR NETWORK ADDRESS}
     ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     YourSystem.Address      := Network.Net_Address;
     OurPacket.Zone          := YourSystem.Address.Zone;
     OurPacket.Net           := YourSystem.Address.Net;
     OurPacket.Node          := YourSystem.Address.Node;
     OurPacket.Point         := YourSystem.Address.Point;
     OurPacket.Product_Major := 2;
     OurPacket.Product_Minor := 0;
     {OUR BBS NAME}
     Work := LENGTH(MailerInfo.NodeName);
     IF (Work>60) THEN Work := 60;
     Move(MailerInfo.NodeName[1],OurPacket.BBSName,Work);
     {MY NAME AS SYSOP}
     Work := LENGTH(SystemInfo.Sysop);
     IF (Work>20) THEN Work := 20;
     Move(SystemInfo.Sysop[1],OurPacket.Sysop,Work);
     {MATCH REMOTES ZONE}
     IF CallingOut THEN
     BEGIN
          IF ((MailerInfo.MatchZones) AND (CurrentAka=1)) THEN MatchTheZone;
     END
     ELSE MatchTheZone;
     {APPLY SESSION PASSWORD}
     IF _FileExists('\GUNSHOT\DATA\PASSWORD.DAT') THEN
     BEGIN
          AllDone := False;
          ASSIGN(FSessionPW,'\GUNSHOT\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF AkasMatch(WorkAddr,SessionPW.SystemAddress) THEN
                BEGIN
                     YourSystem.SessionPassword := _UpperCase(SessionPW.SystemPW);
                     AllDone := True;
                END;
          UNTIL ((EOF(FSessionPW)) OR (AllDone));
          CLOSE(FSessionPW);
     END;
     Work := LENGTH(YourSystem.SessionPassword);
     IF (Work>8) THEN Work := 8;
     Move(YourSystem.SessionPassword[1],OurPacket.Password,Work);
     IF CallingOut THEN
     BEGIN
       LoByte := 0;
       HiByte := 0;
       {DIET IFNA}
       LoByte := LoByte OR 1;
       {ZED_ZIPPER}
       LoByte := LoByte OR 4;
       {ZED_ZAPPER}
       IF ((DoZap) AND (ConnectRate>=14400)) THEN LoByte := LoByte OR 8;
       {WZ_FREQ}
       HiByte := HiByte OR 128;
       OurPacket.Capabilities := (HiByte*256)+LoByte;
       IF ((DoZap) AND (ConnectRate>=14400)) THEN DoingZap := True;
     END
     ELSE
     BEGIN
       CanFtsc  := ((Lo(TheirPacket.Capabilities) AND 001)<>0);
       CanZip   := ((Lo(TheirPacket.Capabilities) AND 004)<>0);
       CanZap   := ((Lo(TheirPacket.Capabilities) AND 008)<>0);
       DoingZap := False;
       IF ((CanZap) AND (DoZap) AND (ConnectRate>=14400)) THEN
       BEGIN
         LoByte   := 0;
         HiByte   := 0;
         {ZED_ZAPPER}
         LoByte   := LoByte OR 8;
         {WZ_FREQ}
         HiByte   := HiByte OR 128;
         DoingZap := True;
         FTSCType := 1;
       END
       ELSE IF CanZip THEN
       BEGIN
         LoByte   := 0;
         HiByte   := 0;
         {ZED_ZIPPER}
         LoByte   := LoByte OR 4;
         {WZ_FREQ}
         HiByte   := HiByte OR 128;
         FTSCType := 2;
       END
       ELSE IF CanFTSC THEN
       BEGIN
         LoByte   := 0;
         HiByte   := 0;
         {FTSC}
         LoByte   := LoByte OR 1;
         FTSCType := 3;
       END
       ELSE {No Protocols!?!?}
       BEGIN
         LoByte   := 0;
         HiByte   := 0;
         FTSCType := 0;
       END;
       OurPacket.Capabilities := (HiByte*256)+LoByte;
     END;
END;
{===========================================================================}
{                                                                           }
{ Log their hello packet.                                                   }
{                                                                           }
{===========================================================================}
PROCEDURE LogTheirHelloPacket;
VAR  Temp : String;
     Loop : Byte;

     PROCEDURE DumpIt(InString: String);
     BEGIN
          InString := '³ '+_PadRight(InString,63)+' ³';
          bsWriteLog(InString,False);
     END;

BEGIN
     bsWriteLog('ÚÄReceived Hello PacketÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',False);
     DumpIt('Signal: '+_String(TheirPacket.Signal));
     DumpIt('Hello Version: '+_String(TheirPacket.Hello_Version));
     DumpIt('Product: '+_String(TheirPacket.Product)+'/'+
            _String(TheirPacket.Product_Major)+'.'+
            _String(TheirPacket.Product_Minor));
     Temp := '';
     FOR Loop := 1 TO 60 DO Temp := Temp+TheirPacket.BBSName[Loop];
     DumpIt(Temp);
     Temp := '';
     FOR Loop := 1 TO 20 DO Temp := Temp+TheirPacket.Sysop[Loop];
     DumpIt(Temp);
     DumpIt('Aka: '+_String(TheirPacket.Zone)+':'+_String(TheirPacket.Net)+'/'+
                    _String(TheirPacket.Node)+'.'+_String(TheirPacket.Point));
     Temp := '';
     FOR Loop := 1 TO 8 DO Temp := Temp+TheirPacket.Password[Loop];
     DumpIt(Temp);
     DumpIt('Capabilities: '+_String(TheirPacket.Capabilities));
     Temp := '';
     IF ((Lo(TheirPacket.Capabilities) AND 001)<>0) THEN Temp := Temp+'Y_DIETIFNA ';
     IF ((Lo(TheirPacket.Capabilities) AND 002)<>0) THEN Temp := Temp+'FTB_USER ';
     IF ((Lo(TheirPacket.Capabilities) AND 004)<>0) THEN Temp := Temp+'ZED_ZIPPER ';
     IF ((Lo(TheirPacket.Capabilities) AND 008)<>0) THEN Temp := Temp+'ZED_ZAPPER ';
     IF ((Lo(TheirPacket.Capabilities) AND 016)<>0) THEN Temp := Temp+'DOES_JANUS ';
     IF ((Hi(TheirPacket.Capabilities) AND 128)<>0) THEN Temp := Temp+'WZ_FREQ ';
     DumpIt(Temp);
     bsWriteLog('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',False);
END;
{===========================================================================}
{                                                                           }
{ Log our hello packet.                                                     }
{                                                                           }
{===========================================================================}
PROCEDURE LogOurHelloPacket;
VAR  Temp : String;
     Loop : Byte;

     PROCEDURE DumpIt(InString: String);
     BEGIN
          InString := '³ '+_PadRight(InString,63)+' ³';
          bsWriteLog(InString,False);
     END;

BEGIN
     bsWriteLog('ÚÄSent Hello PacketÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',False);
     DumpIt('Signal: '+_String(OurPacket.Signal));
     DumpIt('Hello Version: '+_String(OurPacket.Hello_Version));
     DumpIt('Product: '+_String(OurPacket.Product)+'/'+
            _String(OurPacket.Product_Major)+'.'+
            _String(OurPacket.Product_Minor));
     Temp := '';
     FOR Loop := 1 TO 60 DO Temp := Temp+OurPacket.BBSName[Loop];
     DumpIt(Temp);
     Temp := '';
     FOR Loop := 1 TO 20 DO Temp := Temp+OurPacket.Sysop[Loop];
     DumpIt(Temp);
     DumpIt('Aka: '+_String(OurPacket.Zone)+':'+_String(OurPacket.Net)+'/'+
                    _String(OurPacket.Node)+'.'+_String(OurPacket.Point));
     Temp := '';
     FOR Loop := 1 TO 8 DO Temp := Temp+OurPacket.Password[Loop];
     DumpIt(Temp);
     DumpIt('Capabilities: '+_String(OurPacket.Capabilities));
     Temp := '';
     IF ((Lo(OurPacket.Capabilities) AND 001)<>0) THEN Temp := Temp+'Y_DIETIFNA ';
     IF ((Lo(OurPacket.Capabilities) AND 002)<>0) THEN Temp := Temp+'FTB_USER ';
     IF ((Lo(OurPacket.Capabilities) AND 004)<>0) THEN Temp := Temp+'ZED_ZIPPER ';
     IF ((Lo(OurPacket.Capabilities) AND 008)<>0) THEN Temp := Temp+'ZED_ZAPPER ';
     IF ((Lo(OurPacket.Capabilities) AND 016)<>0) THEN Temp := Temp+'DOES_JANUS ';
     IF ((Hi(OurPacket.Capabilities) AND 128)<>0) THEN Temp := Temp+'WZ_FREQ ';
     DumpIt(Temp);
     bsWriteLog('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',False);
END;


PROCEDURE GetSessionCapabilities;
VAR  CanZap  : Boolean;
     CanZip  : Boolean;
     CanFTSC : Boolean;
BEGIN
     CanFtsc  := ((Lo(TheirPacket.Capabilities) AND 001)<>0);
     CanZip   := ((Lo(TheirPacket.Capabilities) AND 004)<>0);
     CanZap   := ((Lo(TheirPacket.Capabilities) AND 008)<>0);
     DoingZap := False;
     IF ((CanZap) AND (DoZap) AND (ConnectRate>=14400)) THEN
     BEGIN
       DoingZap := True;
       FTSCType := 1;
     END
     ELSE IF CanZip THEN
     BEGIN
       FTSCType := 2;
     END
     ELSE IF CanFTSC THEN
     BEGIN
       FTSCType := 3;
     END
     ELSE {No Protocols!?!?}
     BEGIN
       FTSCType := 0;
     END;
END;


END.