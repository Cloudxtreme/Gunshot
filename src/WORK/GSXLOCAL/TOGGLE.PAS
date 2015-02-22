{$I DEFINES.INC}
UNIT Toggle;


INTERFACE


PROCEDURE StartToggle(Size: Longint);
PROCEDURE RedrawToggle;
PROCEDURE EndToggle;
PROCEDURE DoToggle;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Mouse;


PROCEDURE StartToggle(Size: Longint);
BEGIN
     ToggleInfo.Total   := Size;
     ToggleInfo.Current := 0;
     ToggleInfo.Last    := 0;
     ToggleInfo.Active  := True;
     IF ((ToggleInfo.x2-ToggleInfo.x1)>=(ToggleInfo.y2-ToggleInfo.y1))
        THEN ToggleInfo.Horizontal := True
        ELSE ToggleInfo.Horizontal := False;
END;


PROCEDURE EndToggle;
BEGIN
     ToggleInfo.Active := False;
END;


PROCEDURE DoToggle;
VAR  Work  : Word;
     Width : Word;
BEGIN
     INC(ToggleInfo.Current);
     IF ToggleInfo.Horizontal THEN
     BEGIN
          Width := ToggleInfo.x2-ToggleInfo.x1+1;
          Work  := Trunc((ToggleInfo.Current/ToggleInfo.Total)*Width);
          IF Work<>ToggleInfo.Last THEN
          BEGIN
               ToggleInfo.Last := Work;
               GrSetFillStyle(GrFSolid,ToggleInfo.Colour,GrOpaque);
               SetMouseProtect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x2,ToggleInfo.y2);
               ProtectMouse;
               GrDrawRect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x1+Work,ToggleInfo.y2,GrFill);
               UnProtectMouse;
          END;
     END
     ELSE
     BEGIN
          Width := ToggleInfo.y2-ToggleInfo.y1+1;
          Work  := Trunc((ToggleInfo.Current/ToggleInfo.Total)*Width);
          IF Work<>ToggleInfo.Last THEN
          BEGIN
               ToggleInfo.Last := Work;
               GrSetFillStyle(GrFSolid,ToggleInfo.Colour,GrOpaque);
               SetMouseProtect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x2,ToggleInfo.y2);
               ProtectMouse;
               GrDrawRect(ToggleInfo.x1,ToggleInfo.y2,ToggleInfo.x2,ToggleInfo.y2-Work,GrFill);
               UnProtectMouse;
          END;
     END;
END;


PROCEDURE RedrawToggle;
VAR  Work  : Word;
     Width : Word;
BEGIN
     IF ToggleInfo.Horizontal THEN
     BEGIN
          Width := ToggleInfo.x2-ToggleInfo.x1+1;
          Work  := Trunc((ToggleInfo.Current/ToggleInfo.Total)*Width);
          ToggleInfo.Last := Work;
          GrSetFillStyle(GrFSolid,ToggleInfo.Colour,GrOpaque);
          SetMouseProtect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x2,ToggleInfo.y2);
          ProtectMouse;
          GrDrawRect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x1+Work,ToggleInfo.y2,GrFill);
          UnProtectMouse;
     END
     ELSE
     BEGIN
          Width := ToggleInfo.y2-ToggleInfo.y1+1;
          Work  := Trunc((ToggleInfo.Current/ToggleInfo.Total)*Width);
          ToggleInfo.Last := Work;
          GrSetFillStyle(GrFSolid,ToggleInfo.Colour,GrOpaque);
          SetMouseProtect(ToggleInfo.x1,ToggleInfo.y1,ToggleInfo.x2,ToggleInfo.y2);
          ProtectMouse;
          GrDrawRect(ToggleInfo.x1,ToggleInfo.y2,ToggleInfo.x2,ToggleInfo.y2-Work,GrFill);
          UnProtectMouse;
     END;
END;


END.
