{$I DEFINES.INC}
UNIT Dial_Out;


INTERFACE


PROCEDURE DialOut(PhoneNumber,Title: String; UseNode: Word);


IMPLEMENTATION


USES Globals,ApTimer,ApUart,ApCom,ApPort,ApMisc,BsMulti,BsLog,Yapp,
     Screens,KeyInput,Comm,SBuffer,Time,Carrier,Crt,ErrorLog,BsString,
     BsFile;


FUNCTION Comm_init2(BaudRate,ThePort,Device: Longint): Boolean;
CONST BufferSize = 2048;
VAR   BaseAddr   : Word;
      NewAddr    : Word;
      TVector    : Array[0..15] Of Byte;
BEGIN
     IF (NodeInfo2.ComDevice<>NodeInfo.ComDevice) THEN
     BEGIN
          Comm_Init2 := False;
          Exit;
     END;
     IF Device=1 THEN
     BEGIN
          TVector[0]  := 0;   TVector[1]  := $9;  TVector[2]  := $A;  TVector[3]  := $B;
          TVector[4]  := $C;  TVector[5]  := $D;  TVector[6]  := $E;  TVector[7]  := $F;
          TVector[8]  := $70; TVector[9]  := $71; TVector[10] := $72; TVector[11] := $73;
          TVector[12] := $74; TVector[13] := $75; TVector[14] := $76; TVector[15] := $77;
          NewAddr := _Numeric('$'+NodeInfo2.PortAddr);
          CASE ThePort OF
          1:   SetUart(COM1,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          2:   SetUart(COM2,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          3:   SetUart(COM3,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          4:   SetUart(COM4,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          5:   SetUart(COM5,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          6:   SetUart(COM6,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          7:   SetUart(COM7,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          8:   SetUart(COM8,NewAddr,NodeInfo2.IRQ,TVector[NodeInfo2.IRQ]);
          END;
     END;
     CASE ThePort OF
     1:   InitPort(DialOutPort,COM1,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     2:   InitPort(DialOutPort,COM2,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     3:   InitPort(DialOutPort,COM3,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     4:   InitPort(DialOutPort,COM4,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     5:   InitPort(DialOutPort,COM5,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     6:   InitPort(DialOutPort,COM6,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     7:   InitPort(DialOutPort,COM7,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     8:   InitPort(DialOutPort,COM8,BaudRate,NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     END;
     IF AsyncStatus=ecOk THEN
     BEGIN
          IF Device=1 THEN
          BEGIN
               {Enable Fifos For UARTs}
               BaseAddr := GetBaseAddr(DialOutPort);
               IF ClassifyUart(BaseAddr,True)=U16550A THEN
               BEGIN
                    CASE NodeInfo2.Fifos OF
                    1:   SetFifoBuffering(BaseAddr,True,1);
                    2:   SetFifoBuffering(BaseAddr,True,4);
                    3:   SetFifoBuffering(BaseAddr,True,8);
                    4:   SetFifoBuffering(BaseAddr,True,14);
                    END;
               END;
          END;
          CASE NodeInfo2.FlowControl OF
          1:   HWFlowEnable(DialOutPort,Trunc(BufferSize*0.9),Trunc(BufferSize*0.1),hfUseRTS OR hfRequireCTS);
          2:   HWFlowEnable(DialOutPort,Trunc(BufferSize*0.9),Trunc(BufferSize*0.1),hfUseDTR OR hfRequireDSR);
          3:   SWFlowEnable(DialOutPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25));
          END;
          _Delay(NodeInfo2.CommandDelay);
          FlushInBuffer(DialOutPort);
          Comm_Init2 := True;
     END
     ELSE Comm_Init2 := False;
END;


PROCEDURE DialOut(PhoneNumber,Title: String; UseNode: Word);
VAR  Counter      : Word;
     DialTimer    : EventTimer;
     Temp         : String;
     C            : Char;
     AllDone      : Boolean;
     GotSomething : Boolean;
     FFile        : File;
LABEL               ScrewIt;
BEGIN
     bsWriteLog('Using dial through service: '+Title,True);
     bsWriteLog('Service phone number: '+PhoneNumber,True);
     IF _FileExists(INTR_Directory+'\DIALUSED.NOW') THEN
     BEGIN
          bsWriteLog('Dial through is in use [DIALUSED.NOW]',True);
          DisplayGraphicFile('DT_INUSE',False,True,True);
          Get_Enter;
          Exit;
     END;
     ASSIGN(FFile,INTR_Directory+'\DIALUSED.NOW');
     REWRITE(FFile);
     CLOSE(FFile);
     ASSIGN(FNodeInfo,DATA_Directory+'\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,UseNode-1);
     READ(FNodeInfo,NodeInfo2);
     CLOSE(FNodeInfo);
     IF Comm_Init2(ReturnRate(NodeInfo2.BaudRate,NodeInfo2.ComDevice),
                   NodeInfo2.ComPort,NodeInfo2.ComDevice) THEN
     BEGIN
          {HANGUP THE MODEM}
          DrainOutBuffer(DialOutPort,Secs2Tics(60));
          SetDTR(DialOutPort,False); _Delay(500);
          SetDTR(DialOutPort,True); _Delay(500);
          PutStringTimeout(DialOutPort,NodeInfo2.OnHook+#13,182); _Delay(500);
          SetDTR(DialOutPort,False); _Delay(500);
          FlushInBuffer(DialOutPort);
          {INITIALIZE THE MODEM}
          SetDTR(DialOutPort,True);
          FlushInBuffer(DialOutPort);
          _Delay(NodeInfo2.CommandDelay);
          FOR Counter := 1 TO 3 DO
          BEGIN
               IF NodeInfo2.InitString[Counter]<>'' THEN
               BEGIN
                    PutStringTimeout(DialOutPort,NodeInfo2.InitString[Counter]+#13,182);
                    _Delay(NodeInfo2.CommandDelay);
               END;
          END;
          {DIAL THE MODEM}
          ClearBuffer;
          AddToBuffer('@SYSTEMNAME',Title);
          DisplayGraphicFile('DT_DIAL',True,True,True);
          PutStringTimeout(DialOutPort,NodeInfo2.Dial+PhoneNumber+#13,182);
          _Delay(NodeInfo2.CommandDelay);
          {WAIT FOR A RESPONSE}
          GotSomething := False;
          NewTimerSecs(DialTimer,60);
          REPEAT
                IF CharReady(DialOutPort) THEN
                BEGIN
                     Temp := '';
                     REPEAT
                           IF CharReady(DialOutPort) THEN
                           BEGIN
                                GetChar(DialOutPort,c);
                                IF ((ORD(c)>31) AND (ORD(c)<91)) THEN Temp := Temp+c;
                                _Delay(20);
                           END;
                     UNTIL ((c=#13) OR NOT(CharReady(DialOutPort)));
                END
                ELSE TimeSlice;
                IF Pos('NO CARRIER',Temp)<>0 THEN
                BEGIN
                     DisplayGraphicFile('DT_NOANS',False,True,True);
                     Get_Enter;
                     GOTO ScrewIt;
                END;
                IF Pos('BUSY',Temp)<>0 THEN
                BEGIN
                     DisplayGraphicFile('DT_BUSY',False,True,True);
                     Get_Enter;
                     GOTO ScrewIt;
                END;
                IF Pos('CONNECT',Temp)<>0 THEN GotSomething := True;
                IF Pos('CARRIER',Temp)<>0 THEN GotSomething := True;
                IF TimerExpired(DialTimer) THEN
                BEGIN
                     DisplayGraphicFile('DT_NOANS',False,True,True);
                     Get_Enter;
                     GOTO ScrewIt;
                END;
          UNTIL GotSomething;
          _Delay(500);
          PutStringTimeout(BBSPort,#255#120#13,YappDelay);
          IF GetYAPPAck THEN
          BEGIN
               AllDone := False;
               REPEAT
                     IF CharReady(DialOutPort) THEN
                     BEGIN
                          WHILE CharReady(DialOutPort) DO
                          BEGIN
                               GetChar(DialOutPort,c);
                               PutChar(BBSPort,c);
                          END;
                     END
                     ELSE IF CharReady(BBSPort) THEN
                     BEGIN
                          WHILE CharReady(BBSPort) DO
                          BEGIN
                               GetChar(BBSPort,c);
                               PutChar(DialOutPort,c);
                          END;
                     END
                     ELSE
                     BEGIN
                          TimeLimit;
                          IF NOT(CheckDCD(DialOutPort)) THEN AllDone := True;
                          CheckForCarrier;
                     END;
                     IF KeyPressed THEN AllDOne := True
                                   ELSE TimeSlice;
               UNTIL AllDone;
               bsWriteLog('Returned from dial through',True);
               PutStringTimeout(BBSPort,#255#121#13,YappDelay);
               IF NOT(GetYAPPAck) THEN
               BEGIN
                    bsWriteLog('Graphics session lost on return',True);
                    Halt;
               END;
          END;
          ScrewIt:
          DonePort(DialOutPort);
     END
     ELSE
     BEGIN
          DoErrorLog(14,_String(NodeInfo2.ComPort));
          bsWriteLog('Could not open the dial through port.',True);
     END;
     ERASE(FFile);
END;


END.
