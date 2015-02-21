{$I DEFINES.INC}
UNIT Comm;


INTERFACE


PROCEDURE HangUp;
PROCEDURE Comm_deinit;
PROCEDURE SendCommandString (InString: String; RaiseDTR,SendCr: Boolean);
FUNCTION  ReturnRate        (InWord,Device: Word): Longint;
FUNCTION  Comm_init         : Boolean;


IMPLEMENTATION


USES Globals,ApUart,ApFossil,ApDigi14,ApPort,ApMisc,ApCom,ApAnsi,
     BsString,BsMulti;


FUNCTION ReturnRate(InWord,Device: Word): Longint;
VAR  WorkRate : Longint;
BEGIN
     WorkRate := 38400;
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
     END;
     ReturnRate := WorkRate;
END;


FUNCTION Comm_init: Boolean;
CONST BufferSize = 4096;
VAR   BaseAddr   : Word;
      NewAddr    : Word;
      TVector    : Array[0..15] Of Byte;
BEGIN
     CASE CommDef.Device OF
     1:   ActivateApUart;
     2:   ActivateApFossil;
     3:   ActivateApDigi14;
     END;
     IF CommDef.Device=1 THEN
     BEGIN
          TVector[0]  := 0;   TVector[1]  := $9;  TVector[2]  := $A;  TVector[3]  := $B;
          TVector[4]  := $C;  TVector[5]  := $D;  TVector[6]  := $E;  TVector[7]  := $F;
          TVector[8]  := $70; TVector[9]  := $71; TVector[10] := $72; TVector[11] := $73;
          TVector[12] := $74; TVector[13] := $75; TVector[14] := $76; TVector[15] := $77;
          NewAddr := _Numeric('$'+CommDef.PortAddr);
          CASE CommDef.Port OF
          1:   SetUart(COM1,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          2:   SetUart(COM2,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          3:   SetUart(COM3,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          4:   SetUart(COM4,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          5:   SetUart(COM5,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          6:   SetUart(COM6,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          7:   SetUart(COM7,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          8:   SetUart(COM8,NewAddr,CommDef.IRQ,TVector[CommDef.IRQ]);
          END;
     END;
     CASE CommDef.Port OF
     1:   InitPort(BBSPort,COM1,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     2:   InitPort(BBSPort,COM2,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     3:   InitPort(BBSPort,COM3,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     4:   InitPort(BBSPort,COM4,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     5:   InitPort(BBSPort,COM5,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     6:   InitPort(BBSPort,COM6,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     7:   InitPort(BBSPort,COM7,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     8:   InitPort(BBSPort,COM8,ReturnRate(CommDef.Baud,CommDef.Device),NoParity,8,1,BufferSize,BufferSize+30,DefPortOptions);
     END;
     IF AsyncStatus=ecOk THEN
     BEGIN
          ptOptionsOff(BBSPort,ptRestoreOnClose OR ptDropModemOnClose);
          IF CommDef.Device=1 THEN
          BEGIN
               BaseAddr := GetBaseAddr(BBSPort);
               IF ClassifyUart(BaseAddr,True)=U16550A THEN SetFifoBuffering(BaseAddr,True,14);
          END;
          HWFlowEnable(BBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25),hfUseRTS OR hfRequireCTS);
          SetCurrentAnsiPort(BBSPort);
          Hangup;
          Comm_Init := True;
     END
     ELSE Comm_Init := False;
END;


PROCEDURE HangUp;
BEGIN
     SetDTR(BBSPort,False);
     PutString(BBSPort,'+++');
     _Delay(500);
     PutString(BBSPort,'ATH0'+#13);
     SetDTR(BBSPort,False);
     _Delay(500);
     FlushInBuffer(BBSPort);
END;


PROCEDURE Comm_deinit;
BEGIN
     DonePort(BBSPort);
END;


PROCEDURE SendCommandString(InString: String; RaiseDTR,SendCr: Boolean);
VAR  Loop : Word;
     C    : Byte;
BEGIN
     IF RaiseDTR THEN
     BEGIN
          SetDTR(BBSPort,True);
          _Delay(50);
     END;
     Loop := 1;
     REPEAT
                IF InString[Loop]='~' THEN _Delay(500)
           ELSE IF InString[Loop]='|' THEN PutChar(BBSPort,#13)
           ELSE IF InString[Loop]='^' THEN
           BEGIN
                INC(Loop);
                CASE UpCase(InString[Loop]) OF
                'A': PutChar(BBSPort,#1);
                'B': PutChar(BBSPort,#2);
                'C': PutChar(BBSPort,#3);
                'D': PutChar(BBSPort,#4);
                'E': PutChar(BBSPort,#5);
                'F': PutChar(BBSPort,#6);
                'G': PutChar(BBSPort,#7);
                'H': PutChar(BBSPort,#8);
                'I': PutChar(BBSPort,#9);
                'J': PutChar(BBSPort,#10);
                'K': PutChar(BBSPort,#11);
                'L': PutChar(BBSPort,#12);
                'M': PutChar(BBSPort,#13);
                'N': PutChar(BBSPort,#14);
                'O': PutChar(BBSPort,#15);
                'P': PutChar(BBSPort,#16);
                'Q': PutChar(BBSPort,#17);
                'R': PutChar(BBSPort,#18);
                'S': PutChar(BBSPort,#19);
                'T': PutChar(BBSPort,#20);
                'U': PutChar(BBSPort,#21);
                'V': PutChar(BBSPort,#22);
                'W': PutChar(BBSPort,#23);
                'X': PutChar(BBSPort,#24);
                'Y': PutChar(BBSPort,#25);
                'Z': PutChar(BBSPort,#26);
                ELSE BEGIN
                          PutChar(BBSPort,'^');
                          PutChar(BBSPort,InString[Loop]);
                     END;
                END;
           END
           ELSE PutChar(BBSPort,InString[Loop]);
           INC(Loop);
     UNTIL (Loop>LENGTH(InString));
     IF SendCr THEN PutChar(BBSPort,#13);
END;


END.
