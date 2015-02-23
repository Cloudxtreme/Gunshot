{$I DEFINES.INC}
UNIT Comm;


INTERFACE


PROCEDURE HangUp;
PROCEDURE Comm_deinit;
PROCEDURE ClearInBuffer;
FUNCTION  ReturnRate    (InWord,Device: Word)     : Longint;
FUNCTION  Comm_init     (ThePort,Device: Longint) : Boolean;


IMPLEMENTATION


USES Globals,ApPort,ApCom,ErrorLog,{$IFDEF MSDOS}ApUart,{$ENDIF}ApFossil,{$IFDEF MSDOS}ApDigi14,{$ENDIF}
     ApMisc,ApTimer,{$IFDEF MSDOS}ApInt14,{$ENDIF}BsString,BsMulti;


PROCEDURE ClearInBuffer;
VAR  C : Char;
BEGIN
     IF LocalLogon THEN Exit;
     FlushInBuffer(BBSPort);
END;


FUNCTION ReturnRate(InWord,Device: Word): Longint;
VAR  WorkRate : Longint;
BEGIN
     CASE InWord OF
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
     IF ((Device=4) AND (WorkRate>9600)) THEN WorkRate := 9600;
     ReturnRate := WorkRate;
END;


FUNCTION Comm_init(ThePort,Device: Longint): Boolean;
CONST BufferSize = 4096;
VAR   BaseAddr   : Word;
      NewAddr    : Word;
      TVector    : Array[0..15] Of Byte;
BEGIN
{$IFNDEF MSDOS}
     Device := 2; // Force FOSSIL, which is where the socket code lives on non-MSDOS platforms
{$ENDIF}
     IF LocalLogon THEN Exit;
     DefPortOptions := DefPortOptionsSimple;
     IF NodeInfo.ptBufferGetChar THEN DefPortOptions := (DefPortOptions OR ptBufferGetChar);
     CASE Device OF
{$IFDEF MSDOS}
     1:   ActivateApUart;
{$ENDIF}
     2:   BEGIN
            ActivateApFossil;
            DefFossilOptions := DefFossilOptionsSimple;
            IF NodeInfo.ptHandleFossilBug THEN DefFossilOptions := (DefFossilOptions OR ptHandleFossilBug);
            IF NodeInfo.ptTrueOutBuffFree THEN DefFossilOptions := (DefFossilOptions OR ptTrueOutBuffFree);
            IF NodeInfo.ptClearFlow THEN DefFossilOptions := (DefFossilOptions OR ptPutCharWait);
          END;
{$IFDEF MSDOS}
     3:   BEGIN
            ActivateApDigi14;
            DefDigi14Options := DefDigi14OptionsSimple;
            IF NodeInfo.ptPutCharWait THEN DefDigi14Options := (DefDigi14Options OR ptReadWriteWait);
            IF NodeInfo.ptReadWriteWait THEN DefDigi14Options := (DefDigi14Options OR ptClearFlow);
          END;
{$ENDIF}
{$IFDEF MSDOS}
     4:   ActivateApInt14;
{$ENDIF}
     ELSE DoErrorLog(2,'');
     END;
     IF Device=1 THEN
     BEGIN
          TVector[0]  := 0;   TVector[1]  := $9;  TVector[2]  := $A;  TVector[3]  := $B;
          TVector[4]  := $C;  TVector[5]  := $D;  TVector[6]  := $E;  TVector[7]  := $F;
          TVector[8]  := $70; TVector[9]  := $71; TVector[10] := $72; TVector[11] := $73;
          TVector[12] := $74; TVector[13] := $75; TVector[14] := $76; TVector[15] := $77;
          NewAddr := _Numeric('$'+NodeInfo.PortAddr);
          CASE ThePort OF
          1:   SetUart(COM1,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          2:   SetUart(COM2,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          3:   SetUart(COM3,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          4:   SetUart(COM4,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          5:   SetUart(COM5,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          6:   SetUart(COM6,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          7:   SetUart(COM7,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          8:   SetUart(COM8,NewAddr,NodeInfo.IRQ,TVector[NodeInfo.IRQ]);
          END;
     END;
{$IFNDEF MSDOS}
     //REETODO Apro_Use_Old_Handle := SocketHandle;
{$ENDIF}
     CASE ThePort OF
     1:   InitPortKeep(BBSPort,COM1,BufferSize,BufferSize+30);
     2:   InitPortKeep(BBSPort,COM2,BufferSize,BufferSize+30);
     3:   InitPortKeep(BBSPort,COM3,BufferSize,BufferSize+30);
     4:   InitPortKeep(BBSPort,COM4,BufferSize,BufferSize+30);
     5:   InitPortKeep(BBSPort,COM5,BufferSize,BufferSize+30);
     6:   InitPortKeep(BBSPort,COM6,BufferSize,BufferSize+30);
     7:   InitPortKeep(BBSPort,COM7,BufferSize,BufferSize+30);
     8:   InitPortKeep(BBSPort,COM8,BufferSize,BufferSize+30);
     ELSE DoErrorLog(3,'');
     END;
     IF AsyncStatus=ecOk THEN
     BEGIN
          ptOptionsOff(BBSPort,ptRestoreOnClose OR ptDropModemOnClose);
{$IFDEF MSDOS}
          IF Device=1 THEN
          BEGIN
               BaseAddr := GetBaseAddr(BBSPort);
               IF ClassifyUart(BaseAddr,True)=U16550A THEN
               BEGIN
                    CASE NodeInfo.Fifos OF
                    1:   SetFifoBuffering(BaseAddr,True,1);
                    2:   SetFifoBuffering(BaseAddr,True,4);
                    3:   SetFifoBuffering(BaseAddr,True,8);
                    4:   SetFifoBuffering(BaseAddr,True,14);
                    END;
               END;
          END;
{$ENDIF}
          CASE NodeInfo.FlowControl OF
          1:   HWFlowEnable(BBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25),hfUseRTS OR hfRequireCTS);
          2:   HWFlowEnable(BBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25),hfUseDTR OR hfRequireDSR);
          3:   SWFlowEnable(BBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25));
          END;
          SetDTR(BBSPort,True);
          SetRTS(BBSPort,True);
          Comm_Init := True;
     END
     ELSE Comm_Init := False;
END;


PROCEDURE HangUp;
BEGIN
     IF LocalLogon THEN Exit;
     DrainOutBuffer(BBSPort,Secs2Tics(20));
     SetDTR(BBSPort,False);
     PutString(BBSPort,'+++');
     _Delay(1000);
     PutString(BBSPort,NodeInfo.OnHook+#13);
     SetDTR(BBSPort,False);
     _Delay(500);
     FlushInBuffer(BBSPort);
END;


PROCEDURE Comm_deinit;
BEGIN
     IF LocalLogon THEN Exit;
     DrainOutBuffer(BBSPort,Secs2Tics(20));
     DonePort(BBSPort);
END;


END.
