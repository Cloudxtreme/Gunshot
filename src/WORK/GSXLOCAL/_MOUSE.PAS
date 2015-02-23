{$I DEFINES.INC}
UNIT _Mouse;


INTERFACE


USES Globals,Gx2_Bp,Dos,Gunshot;


VAR MouseVisible  : Boolean;


FUNCTION  LeftButtonPress   : Boolean;
FUNCTION  RightButtonPress  : Boolean;
FUNCTION  InitTheMouse      : Boolean;
FUNCTION  MousePosX         : Word;
FUNCTION  MousePosY         : Word;
PROCEDURE ChangeMouse       (MMouse: _Mouse_Def);
PROCEDURE SetMouseBounds    (x1,y1,x2,y2: Word);
PROCEDURE SetMouseProtect   (x1,y1,x2,y2: Word);
PROCEDURE SetMousePos       (x1,y1: Word);
PROCEDURE ProtectMouse;
PROCEDURE UnProtectMouse;
PROCEDURE HideTheMouse;
PROCEDURE ShowTheMouse;
PROCEDURE KillTheMouse;


IMPLEMENTATION


USES BsString,Gx2_BpVC,Gr2_Bp,BsGraph,_Virtual;


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


PROCEDURE HideTheMouse;
BEGIN
     IF MouseVisible THEN grDisplayMouse(GrHide);
     MouseVisible := False;
END;


PROCEDURE ShowTheMouse;
BEGIN
     IF NOT(MouseVisible) THEN grDisplayMouse(GrShow);
     MouseVisible := True;
END;


FUNCTION InitTheMouse: Boolean;
VAR  Error : Integer;
BEGIN
     Error := GrInitMouse;
     IF Error=GxSuccess THEN
     BEGIN
       GrSetMouseMode(gxGRAPHICS);
       GrTrackMouse(GrTrack);
       GrSetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
       SetPixeltoMickey(3,5);
       SetMousePos(Trunc(GraphMaxX/2),Trunc(GraphMaxY/2));
       InitTheMouse := True;
     END
     ELSE InitTheMouse := False;
END;


PROCEDURE KillTheMouse;
BEGIN
     GrTrackMouse(grNOTRACK);
     GrStopMouse;
END;


FUNCTION LeftButtonPress: Boolean;
BEGIN
     IF GrGetMouseButtons=GrLButton
        THEN LeftButtonPress := True
        ELSE LeftButtonPress := False;
END;


FUNCTION RightButtonPress: Boolean;
BEGIN
     IF GrGetMouseButtons=GrRButton
        THEN RightButtonPress := True
        ELSE RightButtonPress := False;
END;


FUNCTION MousePosX: Word;
VAR  Work  : Integer;
     Crap  : Integer;
     Error : Integer;
BEGIN
     Error := GrGetMousePos(Work,Crap);
     IF Error=grSuccess THEN MousePosX := Work
                        ELSE MousePosX := 0;
END;


FUNCTION MousePosY: Word;
VAR  Work  : Integer;
     Crap  : Integer;
     Error : Integer;
BEGIN
     Error := GrGetMousePos(Crap,Work);
     IF Error=grSuccess THEN MousePosY := Work
                        ELSE MousePosY := 0;
END;


PROCEDURE SetMouseBounds(x1,y1,x2,y2: Word);
BEGIN
     GrSetMouseBounds(x1,y1,x2,y2);
END;


PROCEDURE SetMouseProtect(x1,y1,x2,y2: Word);
BEGIN
     GrSetMouseProtect(x1,y1,x2,y2);
END;


PROCEDURE SetMousePos(x1,y1: Word);
BEGIN
     GrSetMousePos(x1,y1);
END;


PROCEDURE ProtectMouse;
BEGIN
     GrProtectMouse(GrProtect);
END;


PROCEDURE UnProtectMouse;
BEGIN
     GrProtectMouse(GrNoProtect);
END;


BEGIN
     MouseVisible  := False;
END.