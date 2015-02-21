{$I DEFINES.INC}
UNIT BsMouse;


INTERFACE


USES Dos;


VAR Mouse_Reg       : Registers;
    Mouse_Installed : Boolean;
    Mouse_Error     : Word;


PROCEDURE _SetPixeltoMickey(Horiz,Verti : Word);
FUNCTION  _MousePosition (VAR MouseX,MouseY: Word) : Word;
FUNCTION  IsMouseInstalled: Boolean;
FUNCTION  _InitMouse: Word;
PROCEDURE _ShowMouse;
PROCEDURE _HideMouse;


IMPLEMENTATION


FUNCTION _InitMouse : Word;
BEGIN
     WITH Mouse_Reg DO Ax := 0;
     Intr($33,Mouse_Reg);
     _InitMouse := Mouse_Reg.Ax;
END;


PROCEDURE _ShowMouse;
BEGIN
     IF NOT(Mouse_Installed) THEN Exit;
     Mouse_Reg.Ax := 1;
     Intr($33,Mouse_Reg);
END;


PROCEDURE _HideMouse;
BEGIN
     IF NOT(Mouse_Installed) THEN Exit;
     Mouse_Reg.AX := 2;
     Intr($33,Mouse_Reg);
END;


FUNCTION _MousePosition(VAR MouseX,MouseY : Word) : Word;
BEGIN
     IF NOT(Mouse_Installed) THEN
     BEGIN
          MouseX := 1;
          MouseY := 1;
          _MousePosition := 0;
          Exit;
     END;
     Mouse_Reg.Ax := 3;
     Intr($33,Mouse_Reg);
     WITH Mouse_Reg DO
     BEGIN
          MouseX := TRUNC((Succ(Cx)+7)/8);
          MouseY := TRUNC((Succ(Dx)+7)/8);
          _MousePosition := Bx;
     END;
END;


FUNCTION IsMouseInstalled: Boolean;
VAR  Reg : Registers;
BEGIN
     FillChar(Reg,SizeOf(Reg),0);
     WITH Reg DO Ax := 0;
     Intr($33,Reg);
     IsMouseInstalled := Reg.Ax = 65535;
END;


PROCEDURE _SetPixeltoMickey(Horiz,Verti : Word);
VAR  Regs : Registers;
BEGIN
     FillChar(Regs,SizeOf(Regs),0);
     Regs.Ax := 15;
     Regs.Cx := Horiz;
     Regs.Dx := Verti;
     Intr($33,Regs);
END;


BEGIN
     Mouse_Error := _InitMouse;
     Mouse_Installed := Mouse_Error = 65535;
END.