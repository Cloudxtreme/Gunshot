{$I DEFINES.INC}
UNIT StartUp;


INTERFACE


PROCEDURE HangUp;
PROCEDURE LoadUpGfx;
PROCEDURE EraseGIPDir;
PROCEDURE ShutDownGfx;
PROCEDURE Comm_deinit;
PROCEDURE LoadDropFile;
PROCEDURE EraseSessionDir;
PROCEDURE SendCommandString (InString: String; RaiseDTR,SendCr: Boolean);
FUNCTION  Comm_init         : Boolean;


IMPLEMENTATION


USES Globals,ApUart,ApFossil,ApDigi14,ApAnsi,Crt,ApPort,ApCom,ApMisc,
     Gx2_Bp,Gx2_BpVC,Gr2_Bp,Tx2_Bp,Fx2_Bp,BsComp,BsGraph,_Virtual,
     _Images,_Icons,_Win,_Buffers,Dos,BsString,BsFile;


FUNCTION Comm_init: Boolean;
CONST BufferSize  = 8192;
VAR   BaseAddr    : Word;
      NewAddr     : Word;
      TVector     : Array[0..15] Of Byte;
BEGIN
     CASE YappDef.Device OF
     1:   ActivateApUart;
     2:   ActivateApFossil;
     3:   ActivateApDigi14;
     END;
     IF YappDef.Device=1 THEN
     BEGIN
          TVector[0]  := 0;   TVector[1]  := $9;  TVector[2]  := $A;  TVector[3]  := $B;
          TVector[4]  := $C;  TVector[5]  := $D;  TVector[6]  := $E;  TVector[7]  := $F;
          TVector[8]  := $70; TVector[9]  := $71; TVector[10] := $72; TVector[11] := $73;
          TVector[12] := $74; TVector[13] := $75; TVector[14] := $76; TVector[15] := $77;
          NewAddr := _Numeric('$'+YappDef.PortAddr);
          CASE YappDef.Port OF
          1:   SetUart(COM1,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          2:   SetUart(COM2,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          3:   SetUart(COM3,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          4:   SetUart(COM4,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          5:   SetUart(COM5,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          6:   SetUart(COM6,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          7:   SetUart(COM7,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          8:   SetUart(COM8,NewAddr,YappDef.IRQ,TVector[YappDef.IRQ]);
          END;
     END;
     CASE YappDef.Port OF
     1:   InitPortKeep(BBSPort,COM1,BufferSize,BufferSize+30);
     2:   InitPortKeep(BBSPort,COM2,BufferSize,BufferSize+30);
     3:   InitPortKeep(BBSPort,COM3,BufferSize,BufferSize+30);
     4:   InitPortKeep(BBSPort,COM4,BufferSize,BufferSize+30);
     5:   InitPortKeep(BBSPort,COM5,BufferSize,BufferSize+30);
     6:   InitPortKeep(BBSPort,COM6,BufferSize,BufferSize+30);
     7:   InitPortKeep(BBSPort,COM7,BufferSize,BufferSize+30);
     8:   InitPortKeep(BBSPort,COM8,BufferSize,BufferSize+30);
     END;
     IF AsyncStatus=ecOk THEN
     BEGIN
          ptOptionsOff(BBSPort,ptRestoreOnClose OR ptDropModemOnClose);
          IF YappDef.Device=1 THEN
          BEGIN
               BaseAddr := GetBaseAddr(BBSPort);
               IF ClassifyUart(BaseAddr,True)=U16550A THEN SetFifoBuffering(BaseAddr,True,14);
          END;
          HWFlowEnable(BBSPort,Trunc(BufferSize*0.75),Trunc(BufferSize*0.25),hfUseRTS OR hfRequireCTS);
          SetCurrentAnsiPort(BBSPort);
          Comm_Init := True;
     END
     ELSE Comm_Init := False;
END;


PROCEDURE HangUp;
BEGIN
     SetDTR(BBSPort,False);
     PutString(BBSPort,'+++');
     Delay(500);
     PutString(BBSPort,'ATH0'+#13);
     SetDTR(BBSPort,False);
     Delay(500);
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
          Delay(50);
     END;
     Loop := 1;
     REPEAT
                IF InString[Loop]='~' THEN Delay(500)
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


PROCEDURE SetDefaultPalette;
VAR  Error    : Integer;
     Ct       : Word;
BEGIN
     FillChar(P256,SizeOf(P256),0);
     FillChar(G256,SizeOf(G256),0);

     {256 Colour Palette}

          Ct    := 0;
          {Basic Palette}
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
          P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
          P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
          P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          {Purple}
          P256[Ct] := 15; INC(ct);  P256[Ct] := 3;  INC(ct);  P256[Ct] := 12; INC(ct);
          P256[Ct] := 18; INC(ct);  P256[Ct] := 6;  INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 21; INC(ct);  P256[Ct] := 9;  INC(ct);  P256[Ct] := 18; INC(ct);
          P256[Ct] := 24; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 21; INC(ct);
          P256[Ct] := 28; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 32; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 29; INC(ct);
          P256[Ct] := 36; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 33; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 37; INC(ct);
          P256[Ct] := 44; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 41; INC(ct);
          P256[Ct] := 48; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 52; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 49; INC(ct);
          P256[Ct] := 56; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 53; INC(ct);
          P256[Ct] := 58; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 55; INC(ct);
          P256[Ct] := 60; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 57; INC(ct);
          P256[Ct] := 62; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 59; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 60; INC(ct);
          {Blues}
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 18; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 23; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 28; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 33; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 38; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 43; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 48; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 53; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 58; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          {Dusty Blues}
          P256[Ct] := 7;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 31; INC(ct);
          P256[Ct] := 12; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 41; INC(ct);
          P256[Ct] := 17; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
          P256[Ct] := 22; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 46; INC(ct);
          P256[Ct] := 27; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 51; INC(ct);
          P256[Ct] := 32; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 56; INC(ct);
          P256[Ct] := 37; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 61; INC(ct);
          P256[Ct] := 41; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 15; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 58; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 5; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 10; INC(ct);  P256[Ct] := 27; INC(ct);  P256[Ct] := 5; INC(ct);
          P256[Ct] := 15; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 37; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 47; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 62; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 5; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 26; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 34; INC(ct);
          P256[Ct] := 18; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 48; INC(ct);
          P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);
          P256[Ct] := 58; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 34; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 38; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 46; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 62; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 43; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 57; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 9; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 5; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 19; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 29; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 39; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 55; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 60; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 43; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 48; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 29; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 37; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 41; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 48; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 53; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 56; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 3; INC(ct);
          P256[Ct] := 59; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 6; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 18; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 0; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
          P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 41; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 43; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 27; INC(ct);
          P256[Ct] := 46; INC(ct);  P256[Ct] := 1; INC(ct);  P256[Ct] := 29; INC(ct);
          P256[Ct] := 53; INC(ct);  P256[Ct] := 2; INC(ct);  P256[Ct] := 34; INC(ct);
          P256[Ct] := 59; INC(ct);  P256[Ct] := 8; INC(ct);  P256[Ct] := 36; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 44; INC(ct);
          P256[Ct] := 62; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 47; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 49; INC(ct);
          P256[Ct] := 62; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 56; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 60; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 5;  INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 0;  INC(ct);  P256[Ct] := 17; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 10; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 15; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
          P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 0;  INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 5;  INC(ct);
          P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 15; INC(ct);
          P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 25; INC(ct);
          P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 35; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 45; INC(ct);
          {Grays}
          P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);
          P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);
          P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);
          P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
          P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);
          P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);
          P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);
          P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);
          P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
          P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
          P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);
          P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);
          P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);
          P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
          P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
          P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);
          P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);
          P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);
          P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
          P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
          P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);
          P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);
          P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);
          P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
          P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
          P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);
          P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);
          P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);
          P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);
          P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);

          {Grayscale palette}
          FOR Ct := 678 TO 767 DO G256[Ct] := P256[Ct];

     Error := gxSetConvertPalette(GxPAL5,@P256);
     Error := GxSetDisplayPalette(@P256);
END;


PROCEDURE LoadTheFont(FileName: String; VAR TextHeader: TxHeader);
BEGIN
     txLibFont(gxCMM,GraphLib,FileName,TextHeader);
END;


PROCEDURE LoadUpGfx;
VAR  Error : Integer;
     Temp  : String;
BEGIN
     Sig := '';
     IF (ParamStr(4)='$$BB$$SS$$') THEN Sig := 'YAPP';
     IF (ParamStr(4)='$$JJ$$PP$$') THEN Sig := 'CYBER';
     IF Sig='' THEN Halt;
     SGT_Directory := _UpperCase(_GetFilePath(ParamStr(0)));
     IF SGT_Directory[Length(SGT_Directory)]='\' THEN DEC(SGT_Directory[0]);
     ChDir(SGT_directory);
     SESSION_Directory := SGT_directory+'\SESSION';
     RESOURCES         := SGT_directory+'\RESOURCE\';
     GIP_Directory     := SGT_directory+'\GIPS\';
     _CreatePath(SESSION_Directory);
     _CreatePath(RESOURCES);
     _CreatePath(GIP_Directory);
     FileMode := 66;
     IF NOT(_FileExists('YAPPINFO.DEF')) THEN
     BEGIN
          FillChar(YappDef,SizeOf(YappDef),0);
          YappDef.UlDir  := 'C:\';
          YappDef.Device := 1;
          YappDef.Port   := _Numeric(ParamStr(1));
          YappDef.Baud   := _Numeric(ParamStr(2));
          IF ParamStr(3)='1' THEN YappDef.Sound := True
                             ELSE YappDef.Sound := False;
          YappDef.DlDir     := _UpperCase(ParamStr(5));
          IF YappDef.DlDir='-NOROM' THEN YappDef.DlDir := '';
          YappDef.VideoSize := 640;
     END
     ELSE LoadDropFile;
     YappDef.UlDir := _UpperCase(_Path(YappDef.UlDir));
     YappDef.DlDir := _UpperCase(_Path(YappDef.DlDir));
     _CreatePath(YappDef.UlDir);
     _CreatePath(YappDef.DlDir);
     Comm_Init;
     EraseSessionDir;
     NEW(CBuffer);
     NEW(Buttons);
     NEW(WorkBuffer);
     TBufferedFile.Init(16384);
     ModeSelected := YappDef.VideoSize;
     NEW(GFXBuffer);
     Error := GxSetBuffer(@GFXBuffer^,SizeOf(GFXBuffer^));
     GraphicsMode_BS(256,ModeSelected,True,True);
     IF NOT(GraphicsInitialized) THEN Halt(2);
     YWindow := GraphMaxY-50;
     {Load Icon Work Buffer}
     gxCreateVirtual(gxCMM,IconHdr,TheDisplay,30,30);
     gxOpenLib(gxGXL,SGT_Directory+'\YAPP.GXL',GraphLib,Nil,0);
     LoadTheFont('GUI_____.GFT',SystemFont);
     LoadTheFont('HELV____.GFT',HelvFont);
     LoadTheFont('ROMAN___.GFT',RomanFont);
     LoadTheFont('BIT8X16.GFT',BitFont8x16);
     LoadTheFont('BIT8X14.GFT',BitFont8x14);
     LoadTheFont('BIT8X8.GFT',BitFont8x8);
     gxCloseLib(GraphLib);
     txSetFont(SystemFont);
     CreateVirtual(OffScreen,GraphMaxX+1,YWindow+1,TheDisplay);
     CreateVirtual(WindowBack,GraphMaxX+1,YWindow+1,TheDisplay);
     GrSetViewPort(0,0,GraphMaxX,GraphMaxY);
     SetDefaultPalette;
     Fade_Off;
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(0,YWindow+1,GraphMaxX,GraphMaxY,GrFill);
     GrSetColor(15); GrDrawLine(0,YWindow+1,GraphMaxX,YWindow+1);
     GrSetColor(8);  GrDrawLine(0,GraphMaxY,GraphMaxX,GraphMaxY);
     IF Sig='YAPP'  THEN LoadGraphicLib('YAPP____.$$$',GraphMaxX-180,GraphMaxY-40,GraphMaxX,GraphMaxY-2);
     IF Sig='CYBER' THEN LoadGraphicLib('CYBER___.$$$',GraphMaxX-150,GraphMaxY-47,GraphMaxX,GraphMaxY-2);
     SystemIcon(10,YWindow+10,81);
     SystemIcon(45,YWindow+10,90);
     RaisedBox(9,YWindow+9,41,YWindow+41);
     RaisedBox(44,YWindow+9,76,YWindow+41);
     GrSetMouseMode(gxGRAPHICS);
     Error := GrInitMouse;
     IF Error<>GxSuccess THEN
     BEGIN
          TextMode(co80);
          Halt(4);
     END;
     GrSetMouseMode(gxGraphics);
     GrTrackMouse(GrTrack);
     GrSetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
     SetPixeltoMickey(3,5);
     GrSetMouseStyle(0,15);
     IF YappDef.Sound THEN SystemIcon(GraphMaxX-174,GraphMaxY-38,73);
     Fade_In;
     NEW(PolyPoint);
END;


PROCEDURE ShutDownGfx;
VAR  Loop      : Word;
BEGIN
     KillBackDrop;
     FOR Loop := 1 TO 10 DO KillCutout(Loop);
     IF NCustom<>0 THEN
     BEGIN
          FOR Loop := 1 TO NCustom DO
          BEGIN
               gxDestroyVirtual(Custom[Loop].Icon1);
               gxDestroyVirtual(Custom[Loop].Icon2);
          END;
     END;
     IF NAnimate<>0 THEN
     BEGIN
          FOR Loop := 1 TO NAnimate DO
          BEGIN
               gxDestroyVirtual(Animate[Loop].Icon[1]);
               gxDestroyVirtual(Animate[Loop].Icon[2]);
               gxDestroyVirtual(Animate[Loop].Icon[3]);
               gxDestroyVirtual(Animate[Loop].Icon[4]);
               gxDestroyVirtual(Animate[Loop].Icon[5]);
               gxDestroyVirtual(Animate[Loop].Icon[6]);
               gxDestroyVirtual(Animate[Loop].Icon[7]);
               gxDestroyVirtual(Animate[Loop].Icon[8]);
          END;
     END;
     Fade_Out;
     Delay(512);
     DISPOSE(PolyPoint);
     DISPOSE(WorkBuffer);
     gxDestroyVirtual(IconHdr);
     gxDestroyVirtual(OffScreen);
     gxDestroyVirtual(WindowBack);
     txFreeFont(SystemFont);
     txFreeFont(HelvFont);
     txFreeFont(RomanFont);
     txFreeFont(workfont);
     txFreeFont(BitFont8x16);
     txFreeFont(BitFont8x14);
     txFreeFont(BitFont8x8);
     GrStopMouse;
     gxSetMode(GxText);
     DISPOSE(GFXBuffer);
     gxDone;
     DISPOSE(CBuffer);
     DISPOSE(Buttons);
     TBufferedFile.Done;
     EraseSessionDir;
     Comm_deinit;
END;


PROCEDURE LoadDropFile;
VAR  FFile     : File;
     BytesRead : Word;
BEGIN
     ASSIGN(FFile,'YAPPINFO.DEF');
     RESET(FFile,1);
     BLOCKREAD(FFile,YappDef,SizeOf(YappDef),BytesRead);
     CLOSE(FFile);
     ERASE(FFile);
     IF (BytesRead<>SizeOf(YappDef)) THEN YappDef.VideoSize := 640;
END;


PROCEDURE EraseGIPDir;
VAR  DirInfo : SearchRec;
     crap    : File;
BEGIN
     FindFirst(GIP_Directory+'*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,GIP_Directory+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
END;


PROCEDURE EraseSessionDir;
VAR  DirInfo : SearchRec;
     crap    : File;
BEGIN
     FindFirst(SESSION_Directory+'\*.*',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          {$I-}
          ASSIGN(crap,SESSION_Directory+'\'+DirInfo.Name);
          ERASE(crap);
          {$I+}
          IF IOResult=0 THEN;
          FindNext(DirInfo);
     END;
     EraseGIPDir;
END;


END.
