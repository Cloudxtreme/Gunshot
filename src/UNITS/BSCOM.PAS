{$I DEFINES.INC}
UNIT BsCom;


INTERFACE


USES ApPort,ApAbsPcl,ApAbsFax;


CONST bsUart         : Byte = 1;
      bsFossil       : Byte = 2;
      bsDigiBoard    : Byte = 3;
      bsInt14        : Byte = 4;
      bsLanInt14     : Byte = 5;
      bsOS2VDM       : Byte = 6;
VAR   bsBBSPort      : PortRecPtr;
      bsBBSProtocol  : ProtocolRecPtr;
      bsBBSFax       : FaxRecPtr;


FUNCTION  bsOpenPort(ThePort,Device,BaudRate,BufferSize: Longint; IsOnline: Boolean;
                     PortAddr: String; IRQ,Fifos,Flow: Byte; v1,v2,v3,v4,v5,v6: Boolean): Boolean;
PROCEDURE bsClosePort(KeepOnline: Boolean);
FUNCTION  bsReturnRate(InWord,Device: Word): Longint;
PROCEDURE bsSendCommandString(InString: String; CommandDelay: Word);
PROCEDURE bsSendString(InString: String);
FUNCTION  bsGetFossilName(fport: Byte): String;
FUNCTION  bsCarrierDetected: Boolean;
PROCEDURE bsClearInBuffer;
PROCEDURE bsClearOutBuffer;
PROCEDURE bsOffHook(OffHook: String);
PROCEDURE bsOnHook(OnHook: String);
FUNCTION  bsGetFaxSupport: String;
PROCEDURE bsStartFax(FaxID,DestDir,FaxClass: String);
PROCEDURE bsStopFax;


IMPLEMENTATION


USES Dos,BsString,ApUart,ApFossil,ApDigi14,ApInt14,
     ApMisc,ApCom,BsMulti,ApTimer,ApFax12;


FUNCTION bsGetFossilName(fport: Byte): String;
TYPE fossilrec = RECORD
     strsize   : Word;
     majrev    : Byte;
     minver    : Byte;
     idofs     : Word;
     idseg     : Word;
     ibuff     : Word;
     ifree     : Word;
     obuff     : Word;
     ofree     : Word;
     swidth    : Byte;
     sheight   : Byte;
     dte       : Byte;
END;
VAR  regs      : Registers;
     fosinfo   : FossilRec;
     fosname   : String[78];
     i         : Byte;
     Temp      : String;
     Work      : Word;
BEGIN
     regs.ah := $04;
     regs.dx := fport;
     intr($14,regs);
     IF regs.ax<>$1954 THEN
     BEGIN
       bsGetFossilName := 'Unknown';
       Exit;
     END;
     regs.ah := $1b;
     regs.cx := sizeof(fosinfo);
     regs.dx := fport;
     regs.es := seg(fosinfo);
     regs.di := ofs(fosinfo);
     intr($14, regs);
     IF fosinfo.majrev<>5 THEN
     BEGIN
       bsGetFossilName := 'Unknown';
       Exit;
     END;
     fosname := '';
     i := 0;
     REPEAT
       fosname := fosname+chr(mem[fosinfo.idseg:fosinfo.idofs+i]);
       inc(i);
     UNTIL(mem[fosinfo.idseg:fosinfo.idofs+i]=0);
     Temp := _UpperCase(fosname);
     IF Pos('RAY GWINN',Temp)<>0 THEN
     BEGIN
       IF (Pos('VX00',Temp)<>0) THEN
       BEGIN
         Work := Pos('VX00',Temp);
         Delete(Temp,1,Work-1);
         Delete(Temp,1,4);
         Temp := _RemoveLeftSpaces(Temp);
         Work := Pos(' ',Temp);
         Temp := _Mid(Temp,1,Work-1);
         fosname := 'SIO/VX00 v'+_LowerCase(Temp);
       END
       ELSE IF (Pos('X00',Temp)<>0) THEN
       BEGIN
         Work := Pos('X00',Temp);
         Delete(Temp,1,Work-1);
         Delete(Temp,1,4);
         Temp := _RemoveLeftSpaces(Temp);
         Work := Pos(' ',Temp);
         Temp := _Mid(Temp,1,Work-1);
         fosname := 'X00 '+_LowerCase(Temp);
       END;
     END
     ELSE IF (Pos('BNU FOSSIL COMMUNICATIONS DRIVER ',Temp)=1) THEN
     BEGIN
       Delete(Temp,1,33);
       fosname := 'BNU '+_LowerCase(Temp);
     END;
     bsGetFossilName := fosname;
END;


FUNCTION bsReturnRate(InWord,Device: Word): Longint;
VAR  WorkRate : Longint;
BEGIN
     CASE InWord OF
     0:   WorkRate := 0;
     1:   WorkRate := 300;
     2:   WorkRate := 600;
     3:   WorkRate := 1200;
     4:   WorkRate := 2400;
     5:   WorkRate := 4800;
     6:   WorkRate := 9600;
     7:   WorkRate := 19200;
     8:   WorkRate := 38400;
     9:   WorkRate := 57600;
     10:  WorkRate := 115200;
     ELSE WorkRate := 38400;
     END;
     IF ((Device=bsInt14) AND (WorkRate>9600)) THEN WorkRate := 9600;
     bsReturnRate := WorkRate;
END;


FUNCTION bsOpenPort(ThePort,Device,BaudRate,BufferSize: Longint; IsOnline: Boolean;
                    PortAddr: String; IRQ,Fifos,Flow: Byte; v1,v2,v3,v4,v5,v6: Boolean): Boolean;
CONST TVector  : Array[0..15] Of Byte = (0,$9,$A,$B,$C,$D,$E,$F,$70,$71,$72,$73,$74,$75,$76,$77);
VAR   BaseAddr : Word;
      NewAddr  : Word;
BEGIN
     BaudRate := bsReturnRate(BaudRate,Device);
     DefPortOptions := DefPortOptionsSimple;
     CASE Device OF
     1:   BEGIN
            ActivateApUart;
            IF v1 THEN DefPortOptions := (DefPortOptions OR ptBufferGetChar);
          END;
     2:   BEGIN
            ActivateApFossil;
            DefFossilOptions := DefFossilOptionsSimple;
            IF v1 THEN DefFossilOptions := (DefFossilOptions OR ptBufferGetChar);
            IF v2 THEN DefFossilOptions := (DefFossilOptions OR ptHandleFossilBug);
            IF v3 THEN DefFossilOptions := (DefFossilOptions OR ptTrueOutBuffFree);
            IF v4 THEN DefFossilOptions := (DefFossilOptions OR ptPutCharWait);
          END;
     3:   BEGIN
            ActivateApDigi14;
            DefDigi14Options := DefDigi14OptionsSimple;
            IF v1 THEN DefDigi14Options := (DefDigi14Options OR ptBufferGetChar);
            IF v5 THEN DefDigi14Options := (DefDigi14Options OR ptReadWriteWait);
            IF v6 THEN DefDigi14Options := (DefDigi14Options OR ptClearFlow);
          END;
     4:   BEGIN
            ActivateApInt14;
            IF v1 THEN DefPortOptions := (DefPortOptions OR ptBufferGetChar);
          END;
     5,6: BEGIN
            bsOpenPort := False;
            Exit;
          END;
     END;
     IF Device=bsUart THEN
     BEGIN
          NewAddr := _Numeric('$'+PortAddr);
          CASE ThePort OF
          1:   SetUart(COM1,NewAddr,IRQ,TVector[IRQ]);
          2:   SetUart(COM2,NewAddr,IRQ,TVector[IRQ]);
          3:   SetUart(COM3,NewAddr,IRQ,TVector[IRQ]);
          4:   SetUart(COM4,NewAddr,IRQ,TVector[IRQ]);
          5:   SetUart(COM5,NewAddr,IRQ,TVector[IRQ]);
          6:   SetUart(COM6,NewAddr,IRQ,TVector[IRQ]);
          7:   SetUart(COM7,NewAddr,IRQ,TVector[IRQ]);
          8:   SetUart(COM8,NewAddr,IRQ,TVector[IRQ]);
          END;
     END;
     IF IsOnline THEN
     BEGIN
          CASE ThePort OF
          1:   InitPortKeep(bsBBSPort,COM1,BufferSize,BufferSize+30);
          2:   InitPortKeep(bsBBSPort,COM2,BufferSize,BufferSize+30);
          3:   InitPortKeep(bsBBSPort,COM3,BufferSize,BufferSize+30);
          4:   InitPortKeep(bsBBSPort,COM4,BufferSize,BufferSize+30);
          5:   InitPortKeep(bsBBSPort,COM5,BufferSize,BufferSize+30);
          6:   InitPortKeep(bsBBSPort,COM6,BufferSize,BufferSize+30);
          7:   InitPortKeep(bsBBSPort,COM7,BufferSize,BufferSize+30);
          8:   InitPortKeep(bsBBSPort,COM8,BufferSize,BufferSize+30);
          END;
     END
     ELSE
     BEGIN
          CASE ThePort OF
          1:   InitPort(bsBBSPort,COM1,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          2:   InitPort(bsBBSPort,COM2,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          3:   InitPort(bsBBSPort,COM3,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          4:   InitPort(bsBBSPort,COM4,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          5:   InitPort(bsBBSPort,COM5,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          6:   InitPort(bsBBSPort,COM6,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          7:   InitPort(bsBBSPort,COM7,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          8:   InitPort(bsBBSPort,COM8,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
          END;
     END;
     IF AsyncStatus=ecOk THEN
     BEGIN
          IF Device=bsUart THEN
          BEGIN
               BaseAddr := GetBaseAddr(bsBBSPort);
               IF ClassifyUart(BaseAddr,True)=U16550A THEN
               BEGIN
                    CASE Fifos OF
                    1:   SetFifoBuffering(BaseAddr,True,1);
                    2:   SetFifoBuffering(BaseAddr,True,4);
                    3:   SetFifoBuffering(BaseAddr,True,8);
                    4:   SetFifoBuffering(BaseAddr,True,14);
                    END;
               END;
          END;
          CASE Flow OF
          1:   HWFlowEnable(bsBBSPort,Trunc(BufferSize*0.9),Trunc(BufferSize*0.1),hfUseRTS OR hfRequireCTS);
          2:   HWFlowEnable(bsBBSPort,Trunc(BufferSize*0.9),Trunc(BufferSize*0.1),hfUseDTR OR hfRequireDSR);
          3:   SWFlowEnable(bsBBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25));
          END;
          bsClearInBuffer;
          bsOpenPort := True;
     END
     ELSE bsOpenPort := False;
END;


PROCEDURE bsClosePort(KeepOnline: Boolean);
BEGIN
     IF KeepOnline THEN ptOptionsOff(bsBBSPort,ptRestoreOnClose OR ptDropModemOnClose);
     DonePort(bsBBSPort);
END;


FUNCTION bsCarrierDetected: Boolean;
BEGIN
     IF CheckDCD(bsBBSPort)
        THEN bsCarrierDetected := True
        ELSE bsCarrierDetected := False;
END;


PROCEDURE bsClearInBuffer;
BEGIN
     REPEAT
       FlushInBuffer(bsBBSPort);
       _Delay(200);
     UNTIL NOT(CharReady(bsBBSPort));
END;


PROCEDURE bsClearOutBuffer;
BEGIN
     _Delay(200);
     FlushOutBuffer(bsBBSPort);
END;


PROCEDURE bsOffHook(OffHook: String);
BEGIN
     PutString(bsBBSPort,OffHook+#13);
     bsClearInBuffer;
END;


PROCEDURE bsOnHook(OnHook: String);
BEGIN
     IF bsCarrierDetected THEN
     BEGIN
       SetDTR(bsBBSPort,False);
       _Delay(500);
       PutString(bsBBSPort,'+++');
       _Delay(500);
       bsClearInBuffer;
       SetDTR(bsBBSPort,True);
       _Delay(500);
     END;
     PutString(bsBBSPort,OnHook+#13);
     bsClearInBuffer;
END;


FUNCTION bsGetFaxSupport: String;
VAR  Temp : String;
     TTT  : EventTimer;
     C    : Char;
BEGIN
     Temp := '';
     _Delay(1000);
     bsClearInBuffer;
     PutString(bsBBSPort,'at+fclass=?'+#13);
     NewTimerSecs(TTT,4);
     REPEAT
       IF CharReady(bsBBSPort) THEN
       BEGIN
         GetChar(bsBBSPort,C);
         Temp := Temp+C;
         IF LENGTH(Temp)>200 THEN Delete(Temp,1,50);
         IF C=#13 THEN
         BEGIN
           IF (Pos('2.0',Temp)<>0) THEN
           BEGIN
             bsGetFaxSupport := 'Class 2.0';
             Exit;
           END
           ELSE IF (Pos('2',Temp)<>0) THEN
           BEGIN
             bsGetFaxSupport := 'Class 2';
             Exit;
           END
           ELSE IF (Pos('1',Temp)<>0) THEN
           BEGIN
             bsGetFaxSupport := 'Class 1';
             Exit;
           END
           ELSE IF (Pos('ERROR',Temp)<>0) THEN
           BEGIN
             bsGetFaxSupport := 'None';
             Exit;
           END;
         END;
       END
       ELSE TimeSlice;
     UNTIL TimerExpired(TTT);
     bsGetFaxSupport := 'None';
END;


PROCEDURE bsSendCommandString(InString: String; CommandDelay: Word);
VAR  BytesSent : Word;
BEGIN
     InString := InString+#13;
     _Delay(CommandDelay);
     PutBlockDirect(bsBBSPort,InString[1],Ord(InString[0]),BytesSent);
END;


PROCEDURE bsSendString(InString: String);
VAR  BytesSent : Word;
BEGIN
     InString := InString+#13;
     PutBlockDirect(bsBBSPort,InString[1],Ord(InString[0]),BytesSent);
END;


FUNCTION JustNumbers(InString: String): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := '';
     FOR Loop := 1 TO LENGTH(InString) DO
     BEGIN
          IF (InString[Loop] IN ['0'..'9']) THEN Temp := Temp+InString[Loop];
          IF InString[Loop]=' ' THEN Temp := Temp+InString[Loop];
     END;
     IF Temp='' THEN Temp := '00000000000';
     JustNumbers := Temp;
END;


PROCEDURE bsStartFax(FaxID,DestDir,FaxClass: String);
BEGIN
     IF DestDir[LENGTH(DestDir)]='\' THEN Dec(DestDir[0]);
     InitC12ReceiveFax(bsBBSFax,JustNumbers(FaxID),bsBBSPort);
     SetOneFax(bsBBSFax,True);
     SetFaxNameFunc(bsBBSFax,FaxNameCount);
     SetDestinationDir(bsBBSFax,DestDir);
          IF FaxClass='Class 2.0' THEN SetClassType(bsBBSFax,ctClass2_0)
     ELSE IF FaxClass='Class 2' THEN SetClassType(bsBBSFax,ctClass2)
     ELSE IF FaxClass='Class 1' THEN SetClassType(bsBBSFax,ctClass1);
END;


PROCEDURE bsStopFax;
BEGIN
     DoneC12ReceiveFax(bsBBSFax);
END;


END.
