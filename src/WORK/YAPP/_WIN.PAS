{$I DEFINES.INC}
UNIT _Win;


INTERFACE


USES Globals,Gunshot;


PROCEDURE DrawTheWindow    (Raw: _Raw_File);
PROCEDURE InvertedBox      (x1,y1,x2,y2: Word);
PROCEDURE RaisedBox        (x1,y1,x2,y2: Word);
PROCEDURE DrawWindowHeader (Index: Word; Enabled: Boolean);


IMPLEMENTATION


USES Gr2_Bp,_Icons,_Text;


PROCEDURE DrawTheWindow(Raw: _Raw_File);
VAR  x1,y1,x2,y2 : Word;
     Raw2        : _Raw_File;
BEGIN
     Raw2.Text    := Raw.Text;
     Raw2.Colour1 := Raw.Colour8;
     Raw2.Colour7 := 1;
     Raw2.Colour3 := 0;
     Raw2.Colour4 := 0;
     Raw2.Colour5 := 0;
     Raw2.Colour6 := 0;
     Raw2.Colour2 := 0;
     x1 := Raw.x1; y1 := Raw.y1;
     x2 := Raw.x2; y2 := Raw.y2;
     {Window Face}
     GrSetColor(0);
     CASE Raw.Colour10 OF
     0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
     1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
     END;
     CASE Raw.Style OF
     1:   BEGIN {Classic Relief}
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               GrDrawLine(x2-4,y1+4,x2-4,y1+26);
               GrDrawLine(x1+4,y1+26,x2-4,y1+26);
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+4,y1+4,x2-4,y1+4);
               GrDrawLine(x1+4,y1+4,x1+4,y1+26);
               {Header Background}
               GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
               GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
               {Do The Header}
               IF Raw.Colour9=1 THEN
               BEGIN {Mimimized Header}
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+26,y1+25,x2-26,y1+25);
                    GrDrawLine(x2-26,y1+5,x2-26,y1+25);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+26,y1+5,x1+26,y1+25);
                    GrDrawLine(x1+26,y1+5,x2-26,y1+5);
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    Raw2.x1 := x1+41;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN {Non-Mimimized Header}
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     2:   BEGIN {Stamped Headers}
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               IF Raw.Colour9=1 THEN
               BEGIN
                    {Header Background}
                    GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
                    GrDrawRect(X1+30,Y1+5,X2-30,Y1+25,GrFill);
                    {Highlight Header}
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+30,y1+25,x2-30,y1+25);
                    GrDrawLine(x2-30,y1+5,x2-30,y1+25);
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+30,y1+5,x1+30,y1+25);
                    GrDrawLine(x1+30,y1+5,x2-30,y1+5);
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    {Header Background}
                    GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
                    GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
                    {Highlight Header}
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     3:   BEGIN {Dozzzy Windows}
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Borders Etc.}
               GrSetColor(Raw.Colour2);
               GrDrawRect(X1+1,Y1+1,X2-1,Y2-1,GrOutline);
               GrDrawRect(X1+2,Y1+2,X2-2,Y2-2,GrOutline);
               GrDrawRect(X1+3,Y1+3,X2-3,Y2-3,GrOutline);
               GrSetColor(0);
               GrDrawRect(x1+4,y1+4,x2-4,y2-4,GrOutline);
               GrDrawLine(x1+4,y1+26,x2-4,y1+26);
               GrDrawLine(x1,y1+15,x1+4,y1+15);
               GrDrawLine(x1+15,y1,x1+15,y1+4);
               GrDrawLine(x2,y1+15,x2-4,y1+15);
               GrDrawLine(x2-15,y1,x2-15,y1+4);
               GrDrawLine(x1,y2-15,x1+4,y2-15);
               GrDrawLine(x1+15,y2-4,x1+15,y2);
               GrDrawLine(x2,y2-15,x2-4,y2-15);
               GrDrawLine(x2-15,y2-4,x2-15,y2);
               {Header Background}
               GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
               GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
               IF Raw.Colour9=1 THEN
               BEGIN
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    GrSetColor(0);
                    GrDrawLine(x1+26,y1+5,x1+26,y1+25);
                    GrDrawLine(x2-26,y1+5,x2-26,y1+25);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     4:   BEGIN {Panel Window}
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
          END;
     END;
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(x1+5,y2+1,x2+5,y2+5,GrFill);
     GrDrawRect(x2+1,y1+5,x2+5,y2+5,GrFill);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(15);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(8);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE RaisedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(8);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(15);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE DrawWindowHeader(Index: Word; Enabled: Boolean);
VAR  x1,y1,x2,y2 : Word;
     Raw         : _Raw_File;
     Raw2        : _Raw_File;
BEGIN
     Raw := SavedCutouts[Index].WindowDef;
     Raw.x1 := Raw.x1+SavedCutouts[Index].MoveX;
     Raw.y1 := Raw.y1+SavedCutouts[Index].MoveY;
     Raw.x2 := Raw.x2+SavedCutouts[Index].MoveX;
     Raw.y2 := Raw.y2+SavedCutouts[Index].MoveY;
     Raw2.Text := Raw.Text;
     IF Enabled THEN Raw2.Colour1 := Raw.Colour8
                ELSE Raw2.Colour1 := Colours.DisabledText;
     Raw2.Colour7 := 1;
     Raw2.Colour3 := 0;
     Raw2.Colour4 := 0;
     Raw2.Colour5 := 0;
     Raw2.Colour6 := 0;
     Raw2.Colour2 := 0;
     x1 := Raw.x1; y1 := Raw.y1;
     x2 := Raw.x2; y2 := Raw.y2;
     CASE Raw.Style OF
     1:   BEGIN {Classic Relief}
               IF Raw.Colour9=1 THEN
               BEGIN {Mimimized Header}
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+26,Y1+5,X2-26,Y1+25,GrFill);
                    IF Enabled THEN GrSetColor(Raw.Colour7)
                               ELSE GrSetColor(Colours.DisabledShadow);
                    GrDrawLine(x1+26,y1+25,x2-26,y1+25);
                    GrDrawLine(x2-26,y1+5,x2-26,y1+25);
                    IF Enabled THEN GrSetColor(Raw.Colour6)
                               ELSE GrSetColor(Colours.DisabledHighlight);
                    GrDrawLine(x1+26,y1+5,x1+26,y1+25);
                    GrDrawLine(x1+26,y1+5,x2-26,y1+5);
                    Raw2.x1 := x1+41;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN {Non-Mimimized Header}
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
                    IF Enabled THEN GrSetColor(Raw.Colour7)
                               ELSE GrSetColor(Colours.DisabledShadow);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    IF Enabled THEN GrSetColor(Raw.Colour6)
                               ELSE GrSetColor(Colours.DisabledHighlight);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     2:   BEGIN {Stamped Headers}
               IF Raw.Colour9=1 THEN
               BEGIN
                    {Header Background}
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+30,Y1+5,X2-30,Y1+25,GrFill);
                    {Highlight Header}
                    IF Enabled THEN GrSetColor(Raw.Colour6)
                               ELSE GrSetColor(Colours.DisabledHighlight);
                    GrDrawLine(x1+30,y1+25,x2-30,y1+25);
                    GrDrawLine(x2-30,y1+5,x2-30,y1+25);
                    IF Enabled THEN GrSetColor(Raw.Colour7)
                               ELSE GrSetColor(Colours.DisabledShadow);
                    GrDrawLine(x1+30,y1+5,x1+30,y1+25);
                    GrDrawLine(x1+30,y1+5,x2-30,y1+5);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    {Header Background}
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
                    {Highlight Header}
                    IF Enabled THEN GrSetColor(Raw.Colour6)
                               ELSE GrSetColor(Colours.DisabledHighlight);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    IF Enabled THEN GrSetColor(Raw.Colour7)
                               ELSE GrSetColor(Colours.DisabledShadow);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     3:   BEGIN {Dozzzy Windows}
               IF Raw.Colour9=1 THEN
               BEGIN
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+27,Y1+6,X2-27,Y1+24,GrFill);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    IF Enabled THEN GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,Colours.DisabledBackground,GrOpaque);
                    GrDrawRect(X1+5,Y1+6,X2-5,Y1+24,GrFill);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     END;
END;


END.
