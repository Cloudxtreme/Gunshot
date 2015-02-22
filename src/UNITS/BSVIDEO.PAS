{$I DEFINES.INC}
UNIT BsVideo;


INTERFACE


PROCEDURE _HighBackGrounds(TurnOn: Boolean);
PROCEDURE FastWrite(St: String; Row,Col,Attr: Byte);
PROCEDURE ExtendedVideoMode(NumLines: Byte);
PROCEDURE AppHeader(InString: String);


IMPLEMENTATION


USES Dos,FastW1,Crt,Version;


PROCEDURE _HighBackGrounds(TurnOn: Boolean);
VAR  Regs : Registers;
BEGIN
     FillChar(Regs,SizeOf(Regs),0);
     IF TurnOn THEN Regs.BL := 0
               ELSE Regs.BL := 1;
     Regs.AX := $1003;
     Intr($10,Regs);
END;


PROCEDURE SwitchTo28Rows; Assembler;
ASM
   mov ax,1202h
   mov bl,30h
   int 10h
   mov ax,0003h
   int 10h
   mov ax,1111h
   mov bl,00h
   int 10h
END;


PROCEDURE SwitchTo30Rows;
VAR  CrtcReg : Array[1..8] Of Word;
     Offset  : Word;
     I,Data  : Byte;
BEGIN
     CrtcReg[1] := $0c11; CrtcReg[2] := $0d06;
     CrtcReg[3] := $3e07; CrtcReg[4] := $ea10;
     CrtcReg[5] := $8c11; CrtcReg[6] := $df12;
     CrtcReg[7] := $e715; CrtcReg[8] := $0616;
     MemW[$0040:$004c] := 8192;
     Mem[$0040:$0084]  :=29;
     Offset := MemW[$0040:$0063];
     ASM
        cli
     END;
     FOR i := 1 TO 8 DO PortW[Offset] := CrtcReg[i];
     Data := Port[$03cc];
     Data := Data AND $33;
     Data := Data OR $C4;
     Port[$03c2]:=Data;
     ASM
        sti
        mov ah,12h
        mov bl,20h
        int 10h
     END;
END;


PROCEDURE ExtendedVideoMode(NumLines: Byte);
BEGIN
     CASE NumLines OF
     28:  SwitchTo28Rows;
     30:  SwitchTo30Rows;
     END;
END;


PROCEDURE FastWrite(St: String; Row,Col,Attr: Byte);
BEGIN
     FastW1.FastWrite(St,Row,Col,Attr);
END;


PROCEDURE AppHeader(InString: String);
BEGIN
     TextBackground(0);
     TextColor(7);
     ClrScr;
     FastWrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',1,1,25);
     FastWrite('¿',1,80,16);
     FastWrite('³                                                                              ',2,1,25);
     FastWrite('³',2,80,16);
     FastWrite('³                                                                              ',3,1,25);
     FastWrite('³',3,80,16);
     FastWrite('³                                                                              ',4,1,25);
     FastWrite('³',4,80,16);
     FastWrite('À',5,1,25);
     FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',5,2,16);
     FastWrite(InString,2,3,31);
     FastWrite(ShotgunVersion,2,79-LENGTH(ShotgunVersion),31);
     FastWrite(ShotgunCopyright,4,10,27);
     GotoXY(1,7);
END;


END.