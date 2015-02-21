{$I DEFINES.INC}
UNIT _Toggle;


INTERFACE


PROCEDURE StartToggle(JumpIn: Boolean);
PROCEDURE RedrawToggle;
PROCEDURE EndToggle;
PROCEDURE DoToggle;


IMPLEMENTATION


USES Globals,Gr2_Bp;


PROCEDURE StartToggle(JumpIn: Boolean);
BEGIN
     IF NOT(JumpIn) THEN Toggle.Percent := 0;
     Toggle.Active  := True;
     IF ((Toggle.x2-Toggle.x1)>=(Toggle.y2-Toggle.y1))
        THEN Toggle.Horizontal := True
        ELSE Toggle.Horizontal := False;
END;


PROCEDURE EndToggle;
BEGIN
     Toggle.Active := False;
END;


PROCEDURE DoToggle;
VAR  Work  : Word;
     Width : Word;
BEGIN
     IF Toggle.Horizontal THEN
     BEGIN
          Width := Toggle.x2-Toggle.x1+1;
          Work  := Trunc((Toggle.Percent/100)*Width);
          IF Work>Width THEN Work := Width;
          GrSetFillStyle(GrFSolid,Toggle.Colour,GrOpaque);
          GrSetMouseProtect(Toggle.x1,Toggle.y1,Toggle.x2,Toggle.y2);
          GrProtectMouse(grPROTECT);
          GrDrawRect(Toggle.x1,Toggle.y1,Toggle.x1+Work,Toggle.y2,GrFill);
          GrProtectMouse(grNOPROTECT);
     END
     ELSE
     BEGIN
          Width := Toggle.y2-Toggle.y1+1;
          Work  := Trunc((Toggle.Percent/100)*Width);
          IF Work>Width THEN Work := Width;
          GrSetFillStyle(GrFSolid,Toggle.Colour,GrOpaque);
          GrSetMouseProtect(Toggle.x1,Toggle.y1,Toggle.x2,Toggle.y2);
          GrProtectMouse(grPROTECT);
          GrDrawRect(Toggle.x1,Toggle.y2,Toggle.x2,Toggle.y2-Work,GrFill);
          GrProtectMouse(grNOPROTECT);
     END;
END;


PROCEDURE RedrawToggle;
VAR  Work  : Word;
     Width : Word;
BEGIN
     IF Toggle.Horizontal THEN
     BEGIN
          Width := Toggle.x2-Toggle.x1+1;
          Work  := Trunc((Toggle.Percent/100)*Width);
          IF Work>Width THEN Work := Width;
          GrSetFillStyle(GrFSolid,Toggle.Colour,GrOpaque);
          GrSetMouseProtect(Toggle.x1,Toggle.y1,Toggle.x2,Toggle.y2);
          GrProtectMouse(grPROTECT);
          GrDrawRect(Toggle.x1,Toggle.y1,Toggle.x1+Work,Toggle.y2,GrFill);
          GrProtectMouse(grNOPROTECT);
     END
     ELSE
     BEGIN
          Width := Toggle.y2-Toggle.y1+1;
          Work  := Trunc((Toggle.Percent/100)*Width);
          IF Work>Width THEN Work := Width;
          GrSetFillStyle(GrFSolid,Toggle.Colour,GrOpaque);
          GrSetMouseProtect(Toggle.x1,Toggle.y1,Toggle.x2,Toggle.y2);
          GrProtectMouse(grPROTECT);
          GrDrawRect(Toggle.x1,Toggle.y2,Toggle.x2,Toggle.y2-Work,GrFill);
          GrProtectMouse(grNOPROTECT);
     END;
END;


END.
