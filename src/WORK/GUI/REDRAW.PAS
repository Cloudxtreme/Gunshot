{$I DEFINES.INC}
UNIT Redraw;


INTERFACE


PROCEDURE RedrawScreen(Exclude1,Exclude2: Longint);


IMPLEMENTATION


USES Globals,Gr2_Bp,BsGraph,BsString,Cutouts,_Images,
     _Icons,_Win,_Text,_Bezier,Gx2_Bp,Shotgun,BsFile;


{==========================================================================}
{                                                                          }
{    Redraws the screen                                                    }
{                                                                          }
{==========================================================================}
PROCEDURE RedrawScreen(Exclude1,Exclude2: Longint);
VAR  RawFile2    : _Raw_File;
     LoopX       : Word;
     LoopY       : Word;
     Counter     : Longint;
BEGIN
     GrSetClipRegion(0,0,GraphMaxX,YWindow);
     GrSetClipping(GrClip);
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     Counter := 0;
     REPEAT
           READ(FWorkSg,RawFile2);
           INC(Counter);
           IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
           BEGIN
                CASE RawFile2.Number OF
                1:   IF DrawMode THEN {SCREEN BACKGROUND}
                     BEGIN
                          CASE RawFile2.Style OF
                          0:   BEGIN {SOLID}
                                    GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                                    GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                               END;
                          1:   BEGIN {ICON}
                                    GrSetFillStyle(GrFSolid,0,GrOpaque);
                                    GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                                    IF _FileExists(ICONDir+RawFile2.ObjFile) THEN
                                    BEGIN
                                         ASSIGN(FIcon30,ICONDir+RawFile2.ObjFile);
                                         RESET(FIcon30);
                                         SEEK(FIcon30,RawFile2.Colour4-1);
                                         READ(FIcon30,Icon30);
                                         CLOSE(FIcon30);
                                         FOR LoopX := 1 TO 30 DO
                                         BEGIN
                                              FOR LoopY := 1 TO 30 DO
                                              BEGIN
                                                   IF Icon30.matrix[LoopX,LoopY]<>255 THEN
                                                      GrPutPixel(0+LoopX-1,0+LoopY-1,
                                                      Icon30.matrix[LoopX,LoopY]);
                                              END;
                                         END;
                                         Get(0,0,29,29);
                                         LoopX := 30;
                                         REPEAT
                                               Put(LoopX,0,False);
                                               INC(LoopX,30);
                                         UNTIL (LoopX>639);
                                         Put(0,0,True);
                                         Get(0,0,639,29);
                                         LoopY := 30;
                                         REPEAT
                                               Put(0,LoopY,False);
                                               INC(LoopY,30);
                                         UNTIL (LoopY>YWindow);
                                         Put(0,0,True);
                                    END;
                               END;
                          2:   BEGIN {None}
                                    GrSetFillStyle(GrFSolid,0,GrOpaque);
                                    GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                               END;
                          3:   BEGIN {Wallpaper Bitmap}
                                    IF _FileExists(JPEGDir+RawFile2.ObjFile)
                                       THEN TileGraphicFile(JPEGDir+RawFile2.ObjFile);
                               END;
                          END;
                     END
                     ELSE
                     BEGIN
                          GrSetFillStyle(GrFSolid,0,GrOpaque);
                          GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                     END;
                2:   ; {SCREEN MOUSE}
                3:   ; {SCREEN SOUND}
                4:   IF DrawMode THEN {LINES}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetLineStyle(GrLSolid,RawFile2.colour2);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetLineStyle(GrLSolid,1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                5:   IF DrawMode THEN {RECTANGLES}
                     BEGIN
                          IF RawFile2.Colour2=255 THEN
                          BEGIN
                               IF RawFile2.Colour1<>255 THEN
                               BEGIN
                                    GrSetColor(RawFile2.colour1);
                                    GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                               END;
                          END
                          ELSE
                          BEGIN
                               IF RawFile2.Colour1=255 THEN
                               BEGIN
                                    GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                                    GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill);
                               END
                               ELSE
                               BEGIN
                                    GrSetColor(RawFile2.colour1);
                                    GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                                    GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill+GrOutline);
                               END;
                          END;
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                6:   IF DrawMode THEN {ELLIPSES}
                     BEGIN
                          IF RawFile2.Colour2=255 THEN
                          BEGIN
                               IF RawFile2.Colour1<>255 THEN
                               BEGIN
                                    GrSetColor(RawFile2.colour1);
                                    GrDrawEllipse(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                               END;
                          END
                          ELSE
                          BEGIN
                               IF RawFile2.Colour1=255 THEN
                               BEGIN
                                    GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                                    GrDrawEllipse(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill);
                               END
                               ELSE
                               BEGIN
                                    GrSetColor(RawFile2.colour1);
                                    GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                                    GrDrawEllipse(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill+GrOutline);
                               END;
                          END;
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawEllipse(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                7:   IF DrawMode THEN {FLOODFILL}
                     BEGIN
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrFloodSpill(RawFile2.x1,RawFile2.y1);
                     END
                     ELSE
                     BEGIN
                          GrSetFillStyle(GrFSolid,4,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                8:   IF DrawMode THEN {Normal Buttons}
                     BEGIN
                          GrSetColor(0);
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill+GrOutline);
                          GrSetColor(RawFile2.Colour3);
                          GrDrawLine(RawFile2.X1+1,RawFile2.Y2-1,RawFile2.X2-1,RawFile2.Y2-1);
                          GrDrawLine(RawFile2.X2-1,RawFile2.Y1+1,RawFile2.X2-1,RawFile2.Y2-1);
                          GrSetColor(RawFile2.Colour2);
                          GrDrawLine(RawFile2.X1+1,RawFile2.Y1+1,RawFile2.X1+1,RawFile2.Y2-1);
                          GrDrawLine(RawFile2.X1+1,RawFile2.Y1+1,RawFile2.X2-1,RawFile2.Y1+1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetColor(15);
                          GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                9:   IF DrawMode THEN {Panel Buttons}
                     BEGIN
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill);
                          GrSetColor(RawFile2.Colour2);
                          GrDrawRect(RawFile2.X1+1,RawFile2.Y1+1,RawFile2.X2,RawFile2.Y2,GrOutline);
                          GrSetColor(RawFile2.Colour3);
                          GrDrawLine(RawFile2.X1,RawFile2.Y1,RawFile2.X1,RawFile2.Y2);
                          GrDrawLine(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y1);
                          GrDrawLine(RawFile2.X1+2,RawFile2.Y2-1,RawFile2.X2-1,RawFile2.Y2-1);
                          GrDrawLine(RawFile2.X2-1,RawFile2.Y1+2,RawFile2.X2-1,RawFile2.Y2-1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetColor(15);
                          GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                10:  IF DrawMode THEN {Pop Buttons}
                     BEGIN
                          SystemIcon(RawFile2.x1,RawFile2.y1,21);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetColor(15);
                          GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                11:  IF DrawMode THEN
                     BEGIN
                          DrawTheWindow(RawFile2);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
                          GrDrawLine(RawFile2.x1+2,RawFile2.y1+25,RawFile2.x2-2,RawFile2.y1+25);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                12,
                24,
                25:  IF DrawMode THEN
                     BEGIN
                          CASE RawFile2.Number OF
                          12:  DrawIcon(RawFile2.X1,RawFile2.Y1,RawFile2.Colour1,
                                        RawFile2.Style,RawFile2.Colour3,RawFile2.ObjFile);
                          24:  DrawIcon(RawFile2.X1,RawFile2.Y1,RawFile2.Colour1,
                                        RawFile2.Style,RawFile2.Colour3,RawFile2.ObjFile);
                          25:  DrawIcon(RawFile2.X1,RawFile2.Y1,RawFile2.Colour1,
                                        RawFile2.Style,RawFile2.Colour9,RawFile2.ObjFile);
                          END;
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                13:  IF DrawMode THEN
                     BEGIN
                          DoText(RawFile2);
                     END
                     ELSE
                     BEGIN
                          RawFile2.Colour1 := 7;
                          RawFile2.Text := StripColourCodes(RawFile2.Text);
                          DoText(RawFile2);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                14:  IF DrawMode THEN {POLYLINES}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetLineStyle(GrLSolid,RawFile2.colour2);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                   GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          UNTIL RawFile2.Style=255;
                          GrSetLineStyle(GrLSolid,1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                BEGIN
                                     GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                                     GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                                     GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                                END;
                          UNTIL RawFile2.Style=255;
                     END;
                15:  IF DrawMode THEN {POLYGONS}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                          NEW(PolyPoint);
                          LoopX := 2;
                          PolyPoint^[0] := RawFile2.x1;
                          PolyPoint^[1] := RawFile2.y1;
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF RawFile2.Style<>255 THEN
                                BEGIN
                                     PolyPoint^[LoopX] := RawFile2.x1; INC(LoopX);
                                     PolyPoint^[LoopX] := RawFile2.y1; INC(LoopX);
                                END;
                          UNTIL RawFile2.Style=255;
                          PolyPoint^[LoopX] := RawFile2.x1; INC(LoopX);
                          PolyPoint^[LoopX] := RawFile2.y1; INC(LoopX);
                          PolyPoint^[LoopX] := RawFile2.x2; INC(LoopX);
                          PolyPoint^[LoopX] := RawFile2.y2; INC(LoopX);
                          IF RawFile2.colour1=255
                             THEN GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrFill)
                             ELSE GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrOutline+GrFill);
                          DISPOSE(PolyPoint);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                BEGIN
                                     GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                                     GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                                     GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                                END;
                          UNTIL RawFile2.Style=255;
                     END;
                16:  IF DrawMode THEN {BEZIER CURVES}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetLineStyle(GrLSolid,RawFile2.colour2);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                             RawFile2.Colour3,RawFile2.Colour4,
                                             RawFile2.Colour5,RawFile2.Colour6,
                                             RawFile2.x2,RawFile2.y2);
                          UNTIL RawFile2.Style=255;
                          GrSetLineStyle(GrLSolid,1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                BEGIN
                                     GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                                  RawFile2.Colour3,RawFile2.Colour4,
                                                  RawFile2.Colour5,RawFile2.Colour6,
                                                  RawFile2.x2,RawFile2.y2);
                                     GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                                     GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                                END;
                          UNTIL RawFile2.Style=255;
                     END;
                17:  IF DrawMode THEN {BEZIER OBJECTS}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetFillStyle(GrFSolid,RawFile2.Colour2,GrOpaque);
                          NEW(PolyPoint);
                          WorkWord := 0;
                          AddToBezier(RawFile2.x1,RawFile2.y1,
                                      RawFile2.Colour3,RawFile2.Colour4,
                                      RawFile2.Colour5,RawFile2.Colour6,
                                      RawFile2.x2,RawFile2.y2);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                AddToBezier(RawFile2.x1,RawFile2.y1,
                                            RawFile2.Colour3,RawFile2.Colour4,
                                            RawFile2.Colour5,RawFile2.Colour6,
                                            RawFile2.x2,RawFile2.y2);
                          UNTIL RawFile2.Style=255;
                          IF RawFile2.colour1=255
                             THEN GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill)
                             ELSE GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill+GrOutline);
                          DISPOSE(PolyPoint);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                          REPEAT
                                READ(FWorkSg,RawFile2);
                                INC(Counter);
                                IF ((Exclude1<>Counter) AND (Exclude2<>Counter)) THEN
                                BEGIN
                                     GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                                  RawFile2.Colour3,RawFile2.Colour4,
                                                  RawFile2.Colour5,RawFile2.Colour6,
                                                  RawFile2.x2,RawFile2.y2);
                                     GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                                     GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                                END;
                          UNTIL RawFile2.Style=255;
                     END;
                18:  IF DrawMode THEN {Progress Indicators}
                     BEGIN
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                19:  IF DrawMode THEN {PROMPT BOXES}
                     BEGIN
                          LoopX := (GetStringWidth(RawFile2.Colour4)*8)+20;
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x1+LoopX,RawFile2.y1+20,GrFill);
                     END
                     ELSE
                     BEGIN
                          LoopX := (GetStringWidth(RawFile2.Colour4)*8)+20;
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x1+LoopX,RawFile2.y1+20,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                     END;
                20:  IF DrawMode THEN {DIMENSION FRAMES}
                     BEGIN
                          GrSetColor(RawFile2.Colour2);
                          GrDrawLine(RawFile2.x1,RawFile2.y2,RawFile2.x2,RawFile2.y2);
                          GrDrawLine(RawFile2.x2,RawFile2.y1,RawFile2.x2,RawFile2.y2);
                          GrSetColor(RawFile2.Colour1);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y1);
                          GrDrawLine(RawFile2.x1,RawFile2.y1,RawFile2.x1,RawFile2.y2);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                21:  IF DrawMode THEN {PICK LISTS}
                     BEGIN
                          GrSetColor(0);
                          GrSetFillStyle(GrFSolid,7,GrOpaque);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline+GrFill);
                          GrSetFillStyle(GrFSolid,7,GrOpaque);
                          GrDrawRect(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y2-1,GrFill);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y1+20,RawFile2.x2,RawFile2.y1+20);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y2-20,RawFile2.x2,RawFile2.y2-20);
                          GrSetColor(8);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+19,RawFile2.x2-1,RawFile2.y1+19);
                          GrDrawLine(RawFile2.x2-1,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y1+19);
                          GrSetColor(15);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y1+1);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-19,RawFile2.y1+19);
                          GrSetColor(8);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-1,RawFile2.x2-1,RawFile2.y2-1);
                          GrDrawLine(RawFile2.x2-1,RawFile2.y2-19,RawFile2.x2-1,RawFile2.y2-19);
                          GrSetColor(15);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-19,RawFile2.x2-19,RawFile2.y2-1);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-19,RawFile2.x2-1,RawFile2.y2-19);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrDrawRect(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                22:  IF DrawMode THEN {GRAPHIC IMAGES}
                     BEGIN
                          LoadGraphicFile(JPEGDir+RawFile2.ObjFile,
                                          RawFile2.x1,RawFile2.y1,
                                          RawFile2.x2,RawFile2.y2,
                                          RawFile2.Colour2,
                                          RawFile2.Colour1,
                                          RawFile2.Colour3,
                                          True);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                23:  IF DrawMode THEN {String Pads}
                     BEGIN
                          GrSetFillStyle(GrFSolid,RawFile2.Colour1,GrOpaque);
                          GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrFill);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                26:  IF DrawMode THEN {PLAIN ARCS}
                     BEGIN
                          GrSetColor(RawFile2.colour1);
                          GrSetLineStyle(GrLSolid,RawFile2.colour2);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrSetLineStyle(GrLSolid,1);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawBezier(RawFile2.x1,RawFile2.y1,
                                       RawFile2.Colour3,RawFile2.Colour4,
                                       RawFile2.Colour5,RawFile2.Colour6,
                                       RawFile2.x2,RawFile2.y2);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                27:  IF DrawMode THEN {Clickable Regions}
                     BEGIN
                          GrSetColor(XORLine);
                          GrSetOp(GxXOR);
                          GrDrawRect(RawFile2.X1,RawFile2.Y1,RawFile2.X2,RawFile2.Y2,GrOutline);
                          GrSetOp(GxSet);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrSetColor(15);
                          GrDrawRect(RawFile2.x1+2,RawFile2.y1+2,RawFile2.x2-2,RawFile2.y2-2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                     END;
                28:  IF DrawMode THEN {TEXT BOX}
                     BEGIN
                          GrSetColor(0);
                          GrSetFillStyle(GrFSolid,7,GrOpaque);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline+GrFill);
                          GrSetFillStyle(GrFSolid,7,GrOpaque);
                          GrDrawRect(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y2-1,GrFill);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y1+20,RawFile2.x2,RawFile2.y1+20);
                          GrDrawLine(RawFile2.x2-20,RawFile2.y2-20,RawFile2.x2,RawFile2.y2-20);
                          GrSetColor(8);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+19,RawFile2.x2-1,RawFile2.y1+19);
                          GrDrawLine(RawFile2.x2-1,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y1+19);
                          GrSetColor(15);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-1,RawFile2.y1+1);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y1+1,RawFile2.x2-19,RawFile2.y1+19);
                          GrSetColor(8);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-1,RawFile2.x2-1,RawFile2.y2-1);
                          GrDrawLine(RawFile2.x2-1,RawFile2.y2-19,RawFile2.x2-1,RawFile2.y2-19);
                          GrSetColor(15);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-19,RawFile2.x2-19,RawFile2.y2-1);
                          GrDrawLine(RawFile2.x2-19,RawFile2.y2-19,RawFile2.x2-1,RawFile2.y2-19);
                          OutTextXY(RawFile2.x1+5,RawFile2.y1+5,7,0,1,'File: '+RawFile2.Text);
                     END
                     ELSE
                     BEGIN
                          GrSetColor(7);
                          GrDrawRect(RawFile2.x1,RawFile2.y1,RawFile2.x2,RawFile2.y2,GrOutline);
                          GrDrawRect(RawFile2.x2-20,RawFile2.y1,RawFile2.x2-20,RawFile2.y2,GrOutline);
                          GrSetFillStyle(GrFSolid,14,GrOpaque);
                          GrDrawRect(RawFile2.x1-2,RawFile2.y1-2,RawFile2.x1+2,RawFile2.y1+2,GrFill);
                          GrDrawRect(RawFile2.x2-2,RawFile2.y2-2,RawFile2.x2+2,RawFile2.y2+2,GrFill);
                          OutTextXY(RawFile2.x1+5,RawFile2.y1+5,7,0,1,'File: '+RawFile2.Text);
                     END;
                END;
           END;
     UNTIL EOF(FWorkSG);
     CLOSE(FWorkSg);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


END.
