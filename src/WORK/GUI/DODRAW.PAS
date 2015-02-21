{$I DEFINES.INC}
UNIT DoDraw;


INTERFACE


PROCEDURE DoTheDraw;


IMPLEMENTATION


USES Globals,Gr2_Bp,Gx2_Bp,Drag1,Drag2,BsGraph,BsFile,
     _Win,_Text,Redraw,BsString,_Images,Obs;


PROCEDURE DoTheDraw;
BEGIN
     CASE HoldRaw.Number OF
     4:   IF GetLineDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetColor(HoldRaw.colour1);
               GrSetLineStyle(GrLSolid,HoldRaw.colour2);
               GrDrawLine(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2);
               GrSetLineStyle(GrLSolid,1);
          END;
     5:   IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               IF HoldRaw.Colour2=255 THEN
               BEGIN
                    IF HoldRaw.Colour1<>255 THEN
                    BEGIN
                         GrSetColor(HoldRaw.colour1);
                         GrDrawRect(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2,GrOutline);
                    END;
               END
               ELSE
               BEGIN
                    IF HoldRaw.Colour1=255 THEN
                    BEGIN
                         GrSetFillStyle(GrFSolid,HoldRaw.Colour2,GrOpaque);
                         GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill);
                    END
                    ELSE
                    BEGIN
                         GrSetColor(HoldRaw.colour1);
                         GrSetFillStyle(GrFSolid,HoldRaw.Colour2,GrOpaque);
                         GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,
                                    HoldRaw.Y2,GrFill+GrOutline);
                    END;
               END;
          END;
     6:   IF GetCircleDraw THEN
          BEGIN
               GrSetClipRegion(0,0,GraphMaxX,YWindow);
               GrSetClipping(GrClip);
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               IF HoldRaw.Colour2=255 THEN
               BEGIN
                    IF HoldRaw.Colour1<>255 THEN
                    BEGIN
                         GrSetColor(HoldRaw.colour1);
                         GrDrawEllipse(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2,GrOutline);
                    END;
               END
               ELSE
               BEGIN
                    IF HoldRaw.Colour1=255 THEN
                    BEGIN
                         GrSetFillStyle(GrFSolid,HoldRaw.Colour2,GrOpaque);
                         GrDrawEllipse(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill);
                    END
                    ELSE
                    BEGIN
                         GrSetColor(HoldRaw.colour1);
                         GrSetFillStyle(GrFSolid,HoldRaw.Colour2,GrOpaque);
                         GrDrawEllipse(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,
                                       HoldRaw.Y2,GrFill+GrOutline);
                    END;
               END;
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
          END;
     7:   BEGIN
               HoldRaw.x1 := GetMouseXG(Grid);
               HoldRaw.y1 := GetMouseYG(Grid);
               WriteFile;
               GrSetClipRegion(0,0,GraphMaxX,YWindow);
               GrSetClipping(GrClip);
               GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
               GrFloodSpill(HoldRaw.x1,HoldRaw.y1);
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
               REPEAT UNTIL GrGetMouseButtons<>GrLButton;
          END;
     8:   IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
               GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill+GrOutline);
               GrSetColor(HoldRaw.Colour3);
               GrDrawLine(HoldRaw.X1+1,HoldRaw.Y2-1,HoldRaw.X2-1,HoldRaw.Y2-1);
               GrDrawLine(HoldRaw.X2-1,HoldRaw.Y1+1,HoldRaw.X2-1,HoldRaw.Y2-1);
               GrSetColor(HoldRaw.Colour2);
               GrDrawLine(HoldRaw.X1+1,HoldRaw.Y1+1,HoldRaw.X1+1,HoldRaw.Y2-1);
               GrDrawLine(HoldRaw.X1+1,HoldRaw.Y1+1,HoldRaw.X2-1,HoldRaw.Y1+1);
          END;
     9:   IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
               GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill);
               GrSetColor(HoldRaw.Colour2);
               GrDrawRect(HoldRaw.X1+1,HoldRaw.Y1+1,HoldRaw.X2,HoldRaw.Y2,GrOutline);
               GrSetColor(HoldRaw.Colour3);
               GrDrawLine(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X1,HoldRaw.Y2);
               GrDrawLine(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y1);
               GrDrawLine(HoldRaw.X1+2,HoldRaw.Y2-1,HoldRaw.X2-1,HoldRaw.Y2-1);
               GrDrawLine(HoldRaw.X2-1,HoldRaw.Y1+2,HoldRaw.X2-1,HoldRaw.Y2-1);
          END;
     11:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               DrawTheWindow(HoldRaw);
          END;
     13:  IF GetTextDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               WriteFile;
               DoText(HoldRaw);
          END;
     14:  BEGIN
               GetPolyDraw;
               RedrawScreen(0,0);
          END;
     15:  BEGIN
               GetPolyDraw;
               RedrawScreen(0,0);
          END;
     16:  BEGIN
               GetBezierDraw;
               RedrawScreen(0,0);
          END;
     17:  BEGIN
               GetBezierDraw;
               RedrawScreen(0,0);
          END;
     18:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
               GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill);
          END;
     20:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetColor(HoldRaw.Colour2);
               GrDrawLine(HoldRaw.x1,HoldRaw.y2,HoldRaw.x2,HoldRaw.y2);
               GrDrawLine(HoldRaw.x2,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2);
               GrSetColor(HoldRaw.Colour1);
               GrDrawLine(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y1);
               GrDrawLine(HoldRaw.x1,HoldRaw.y1,HoldRaw.x1,HoldRaw.y2);
          END;
     21,
     28:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2,GrOutline+GrFill);
               GrDrawLine(HoldRaw.x2-20,HoldRaw.y1,HoldRaw.x2-20,HoldRaw.y2);
               GrDrawLine(HoldRaw.x2-20,HoldRaw.y1+20,HoldRaw.x2,HoldRaw.y1+20);
               GrDrawLine(HoldRaw.x2-20,HoldRaw.y2-20,HoldRaw.x2,HoldRaw.y2-20);
               GrSetColor(8);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y1+19,HoldRaw.x2-1,HoldRaw.y1+19);
               GrDrawLine(HoldRaw.x2-1,HoldRaw.y1+1,HoldRaw.x2-1,HoldRaw.y1+19);
               GrSetColor(15);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y1+1,HoldRaw.x2-1,HoldRaw.y1+1);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y1+1,HoldRaw.x2-19,HoldRaw.y1+19);
               GrSetColor(8);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y2-1,HoldRaw.x2-1,HoldRaw.y2-1);
               GrDrawLine(HoldRaw.x2-1,HoldRaw.y2-19,HoldRaw.x2-1,HoldRaw.y2-19);
               GrSetColor(15);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y2-19,HoldRaw.x2-19,HoldRaw.y2-1);
               GrDrawLine(HoldRaw.x2-19,HoldRaw.y2-19,HoldRaw.x2-1,HoldRaw.y2-19);
               IF HoldRaw.Number=28 THEN OutTextXY(HoldRaw.x1+5,HoldRaw.y1+5,7,0,1,'File: '+HoldRaw.Text);
          END;
     22:  IF _FileExists(JPEGDir+HoldRaw.ObjFile) THEN
          BEGIN
               IF GetBoxDraw THEN
               BEGIN
                    HoldRaw.x1      := xxx1;
                    HoldRaw.y1      := yyy1;
                    HoldRaw.x2      := xxx2;
                    HoldRaw.y2      := yyy2;
                    WriteFile;
                    LoadGraphicFile(JPEGDir+HoldRaw.ObjFile,HoldRaw.x1,HoldRaw.y1,
                                    HoldRaw.x2,HoldRaw.y2,HoldRaw.Colour2,
                                    HoldRaw.Colour1,HoldRaw.Colour3,True);
               END;
          END;
     23:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
               GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrFill);
          END;
     26:  BEGIN
               GetArcDraw;
               RedrawScreen(0,0);
          END;
     27:  IF GetBoxDraw THEN
          BEGIN
               HoldRaw.x1 := xxx1;
               HoldRaw.y1 := yyy1;
               HoldRaw.x2 := xxx2;
               HoldRaw.y2 := yyy2;
               WriteFile;
               GrSetColor(XORLine);
               GrSetOp(GxXOR);
               GrDrawRect(HoldRaw.X1,HoldRaw.Y1,HoldRaw.X2,HoldRaw.Y2,GrOutline);
               GrSetOp(GxSet);
          END;
     END;
END;


END.