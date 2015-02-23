{$I DEFINES.INC}
UNIT _Mouse;


INTERFACE


USES Globals,Gunshot;


PROCEDURE ChangeMouse(MMouse: _Mouse_Def);


IMPLEMENTATION


USES Gr2_Bp,BsString;


PROCEDURE ChangeMouse(MMouse: _Mouse_Def);
VAR  HiByte    : Byte;
     LoByte    : Byte;
     WorkX     : Word;
     WorkY     : Word;
     MMask     : Array[0..15] Of Word;
     MCursor   : Array[0..15] Of Word;
     C         : Byte;
BEGIN
     {DO CURSOR}
     FOR WorkY := 1 TO 16 DO
     BEGIN
          LoByte  := 0;
          C       := 7;
          {FIRST BYTE}
          FOR WorkX := 1 TO 8 DO
          BEGIN
               IF MMouse.Cursor[WorkX,WorkY]=False
                  THEN LoByte := _ClrBit(LoByte,C)
                  ELSE LoByte := _SetBit(LoByte,C);
               DEC(c);
          END;
          HiByte  := 0;
          C       := 7;
          {SECOND BYTE}
          FOR WorkX := 9 TO 16 DO
          BEGIN
               IF MMouse.Cursor[WorkX,WorkY]=False
                  THEN HiByte := _ClrBit(HiByte,C)
                  ELSE HiByte := _SetBit(HiByte,C);
               DEC(c);
          END;
          MCursor[WorkY-1] := (LoByte*256)+HiByte;
     END;
     {DO MASK}
     FOR WorkY := 1 TO 16 DO
     BEGIN
          LoByte  := 0;
          C       := 7;
          {FIRST BYTE}
          FOR WorkX := 1 TO 8 DO
          BEGIN
               IF MMouse.Mask[WorkX,WorkY]=True
                  THEN LoByte := _ClrBit(LoByte,C)
                  ELSE LoByte := _SetBit(LoByte,C);
               DEC(c);
          END;
          HiByte  := 0;
          C       := 7;
          {SECOND BYTE}
          FOR WorkX := 9 TO 16 DO
          BEGIN
               IF MMouse.Mask[WorkX,WorkY]=True
                  THEN HiByte := _ClrBit(HiByte,C)
                  ELSE HiByte := _SetBit(HiByte,C);
               DEC(c);
          END;
          MMask[WorkY-1] := (LoByte*256)+HiByte;
     END;
     GrSetMouseMask(grCUSER,MMouse.HotX,MMouse.HotY,@MCursor,@MMask);
     GrSetMouseStyle(GrCUSER,MMouse.Colour);
END;


END.
