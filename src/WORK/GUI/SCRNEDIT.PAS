{$I DEFINES.INC}
UNIT ScrnEdit;


INTERFACE


PROCEDURE ScreenEditor;


IMPLEMENTATION


USES Globals,Gr2_Bp,Cutouts,SetWork,Gx2_Bp,BsGraph,_Keys,Drag1,Drag2,Obs,
     _Icons,_Text,PalBoxes,DoDraw,Redraw,ObjSet,Crt,BHandler,_Pop,_Default,
     BsString,MiscDefs,_Win,LoadIcon,_FSelect,IconMisc,ImgDefs,_VSave,
     Shotgun;


PROCEDURE ScreenEditor;
VAR  c          : Word;
     Work       : Word;
     DoX        : Word;
     DoY        : Word;
     XX         : Word;
     YY         : Word;
     OldObject  : Word;
     OldRaw     : _Raw_File;
     Temp       : String;
     What       : Word;
     WhichPress : Word;
LABEL             SkipPast;
BEGIN
     GrDisplayMouse(GrHide);
     Save_Screen;
     SetupWork;
     GrSetMousePos(320,150);
     TrackX      := 320;
     TrackY      := 150;
     GrSetLineStyle(GrLSolid,1);
     GrSetOp(GxXOR);
     GrSetColor(XORLine);
     GrDrawLine(0,TrackY,639,TrackY);
     GrDrawLine(TrackX,0,TrackX,YWindow);
     GrSetOp(GxSet);
     REPEAT
           IF GetMouseY<=YWindow THEN
           BEGIN
                Position;
                IF DrawMode THEN
                BEGIN
                     XX := GetMouseXG(Grid);
                     YY := GetMouseYG(Grid);
                     IF (GetMouseY>=YWindow-8) THEN DEC(YY,30);
                     CASE HoldRaw.Number OF
                     10:  IF GetDragBox(XX,YY,XX+14,YY+14) THEN
                          BEGIN
                               HoldRaw.x1 := xxx1;
                               HoldRaw.y1 := yyy1;
                               HoldRaw.x2 := xxx1+14;
                               HoldRaw.y2 := yyy1+14;
                               WriteFile;
                               IF MouseOn THEN GrDisplayMouse(GrHide);
                               SystemIcon(xxx1,yyy1,21);
                               IF MouseOn THEN GrDisplayMouse(GrShow);
                          END;
                     12,
                     24,
                     25:  BEGIN
                               CASE HoldRaw.Style OF
                               16:  BEGIN
                                         IF GetDragBox(XX,YY,XX+15,YY+15) THEN
                                         BEGIN
                                              HoldRaw.x1 := xxx1;
                                              HoldRaw.y1 := yyy1;
                                              HoldRaw.x2 := xxx1+15;
                                              HoldRaw.y2 := yyy1+15;
                                              WriteFile;
                                              IF MouseOn THEN GrDisplayMouse(GrHide);
                                              CASE HoldRaw.Number OF
                                              12:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
                                              24:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
                                              25:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                              END;
                                              IF MouseOn THEN GrDisplayMouse(GrShow);
                                         END;
                                    END;
                               30:  BEGIN
                                         IF GetDragBox(XX,YY,XX+29,YY+29) THEN
                                         BEGIN
                                              HoldRaw.x1 := xxx1;
                                              HoldRaw.y1 := yyy1;
                                              HoldRaw.x2 := xxx1+29;
                                              HoldRaw.y2 := yyy1+29;
                                              WriteFile;
                                              IF MouseOn THEN GrDisplayMouse(GrHide);
                                              CASE HoldRaw.Number OF
                                              12:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
                                              24:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
                                              25:  DrawIcon(HoldRaw.X1,HoldRaw.Y1,HoldRaw.Colour1,
                                                            HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                              END;
                                              IF MouseOn THEN GrDisplayMouse(GrShow);
                                         END;
                                    END;
                               END;
                          END;
                     19:  BEGIN
                               What := (GetStringWidth(HoldRaw.Colour4)*8)+20;
                               IF GetDragBox(XX,YY,XX+What,YY+20) THEN
                               BEGIN
                                    HoldRaw.x1 := xxx1;
                                    HoldRaw.y1 := yyy1;
                                    WriteFile;
                                    IF MouseOn THEN GrDisplayMouse(GrHide);
                                    GrSetFillStyle(GrFSolid,HoldRaw.Colour1,GrOpaque);
                                    GrDrawRect(HoldRaw.x1,HoldRaw.y1,HoldRaw.x1+What,HoldRaw.y1+20,GrFill);
                                    IF MouseOn THEN GrDisplayMouse(GrShow);
                               END;
                          END;
                     END;
                END;
           END;
           WhichPress := GrGetMouseButtons;
           IF ((WhichPress=GrLButton) OR (WhichPress=GrRButton)) THEN
           BEGIN
                IF ((GetMouseY>YWindow) AND (WhichPress=GrLButton)) THEN
                BEGIN
                     XX := GetMouseX;
                     YY := GetMouseY;
                     IF ChangedAColour(xx,yy) THEN
                     BEGIN
                          CASE HoldRaw.Number OF
                          4,7,18,23:
                               BEGIN
                                    HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                               END;
                          5,6,20:
                               BEGIN
                                    CASE ChangedWhich OF
                                    1:   HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    2:   HoldRaw.colour2 := Palettes[ChangedWhich].Current;
                                    END;
                                    IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                               END;
                          8,9,19:
                               BEGIN
                                    CASE ChangedWhich OF
                                    1:   HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    2:   HoldRaw.colour2 := Palettes[ChangedWhich].Current;
                                    3:   HoldRaw.colour3 := Palettes[ChangedWhich].Current;
                                    END;
                                    IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                               END;
                          14,16:
                               BEGIN
                                    HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    IF (ObjectNumber<>0) THEN UpdatePoly;
                               END;
                          15,17:
                               BEGIN
                                    CASE ChangedWhich OF
                                    1:   HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    2:   HoldRaw.colour2 := Palettes[ChangedWhich].Current;
                                    END;
                                    IF (ObjectNumber<>0) THEN UpdatePoly;
                               END;
                          26:  BEGIN
                                    HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                                    IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                               END;
                          END;
                     END
                     ELSE MoveColourPal(xx,yy);
                END
                ELSE
                BEGIN
                     IF MouseOn THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          MouseOn := False;
                     END
                     ELSE
                     BEGIN
                          GrSetOp(GxXOR);
                          GrSetColor(XORLine);
                          GrDrawLine(0,TrackY,639,TrackY);
                          GrDrawLine(TrackX,0,TrackX,YWindow);
                          GrSetOp(GxSet);
                     END;
                     IF (DrawMode) AND ((WhichPress=GrLButton)) THEN
                     BEGIN
                          DoTheDraw;
                     END
                     ELSE {PICK}
                     BEGIN
                          OldObject := ObjectNumber;
                          IF CheckObject(GetMouseXG(Grid),GetMouseYG(Grid)) THEN
                          BEGIN
                               IF (WhichPress=GrLButton) THEN
                               BEGIN
                                    HighLightObject(GetMouseXG(Grid),GetMouseYG(Grid),False);
                                    IF (OldObject<>ObjectNumber) THEN
                                    BEGIN
                                         SetUpEditObject;
                                    END;
                                    IF ((HoldRaw.Number<14) OR (HoldRaw.Number>17))
                                       THEN RedrawScreen(ObjectNumber,0);
                                    CASE HoldRaw.Number OF
                                    4:   BEGIN
                                              CASE EditNode OF
                                              1:   IF GetSeededLineDraw(HoldRaw.x2,HoldRaw.y2) THEN
                                                   BEGIN
                                                        HoldRaw.x1 := xxx1;
                                                        HoldRaw.y1 := yyy1;
                                                        HoldRaw.x2 := xxx2;
                                                        HoldRaw.y2 := yyy2;
                                                        WriteToFile(ObjectNumber);
                                                   END;
                                              2:   IF GetSeededLineDraw(HoldRaw.x1,HoldRaw.y1) THEN
                                                   BEGIN
                                                        HoldRaw.x1 := xxx1;
                                                        HoldRaw.y1 := yyy1;
                                                        HoldRaw.x2 := xxx2;
                                                        HoldRaw.y2 := yyy2;
                                                        WriteToFile(ObjectNumber);
                                                   END;
                                              END;
                                         END;
                                    5,8,9,11,18,20,21,22,23,27,28:
                                         BEGIN
                                              CASE EditNode OF
                                              1:   IF GetSeededBoxDraw(HoldRaw.x2,HoldRaw.y2) THEN
                                                   BEGIN
                                                        HoldRaw.x1 := xxx1;
                                                        HoldRaw.y1 := yyy1;
                                                        HoldRaw.x2 := xxx2;
                                                        HoldRaw.y2 := yyy2;
                                                        WriteToFile(ObjectNumber);
                                                   END;
                                              2:   IF GetSeededBoxDraw(HoldRaw.x1,HoldRaw.y1) THEN
                                                   BEGIN
                                                        HoldRaw.x1 := xxx1;
                                                        HoldRaw.y1 := yyy1;
                                                        HoldRaw.x2 := xxx2;
                                                        HoldRaw.y2 := yyy2;
                                                        WriteToFile(ObjectNumber);
                                                   END;
                                              END;
                                         END;
                                    6:   BEGIN
                                              CASE EditNode OF
                                              1:   IF GetSeededCircleDraw(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2) THEN
                                                   BEGIN
                                                        HoldRaw.x1 := xxx1;
                                                        HoldRaw.y1 := yyy1;
                                                        HoldRaw.x2 := xxx2;
                                                        HoldRaw.y2 := yyy2;
                                                        WriteToFile(ObjectNumber);
                                                   END;
                                              END;
                                         END;
                                    7:   BEGIN
                                              IF GetSeededFillDraw(HoldRaw.x1,HoldRaw.y1) THEN
                                              BEGIN
                                                   HoldRaw.x1 := xxx1;
                                                   HoldRaw.y1 := yyy1;
                                                   WriteToFile(ObjectNumber);
                                              END;
                                         END;
                                    10:  BEGIN
                                              IF GetSeededDragBox(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2) THEN
                                              BEGIN
                                                   HoldRaw.x1 := xxx1;
                                                   HoldRaw.y1 := yyy1;
                                                   HoldRaw.x2 := xxx1+14;
                                                   HoldRaw.y2 := yyy1+14;
                                                   WriteToFile(ObjectNumber);
                                              END;
                                         END;
                                    12,
                                    24,
                                    25:  BEGIN
                                              IF GetSeededDragBox(HoldRaw.x1,HoldRaw.y1,HoldRaw.x2,HoldRaw.y2) THEN
                                              BEGIN
                                                   HoldRaw.x1 := xxx1;
                                                   HoldRaw.y1 := yyy1;
                                                   HoldRaw.x2 := xxx1+HoldRaw.Style-1;
                                                   HoldRaw.y2 := yyy1+HoldRaw.Style-1;
                                                   WriteToFile(ObjectNumber);
                                              END;
                                         END;
                                    13:  BEGIN
                                              GetFontSize(HoldRaw.Colour7,HoldRaw.ObjFile,HoldRaw.Text,DoX,DoY);
                                              IF GetSeededDragBox(HoldRaw.x1,HoldRaw.y1,HoldRaw.x1+DoX-1,HoldRaw.y1+DoY-1) THEN
                                              BEGIN
                                                   HoldRaw.x1 := xxx1;
                                                   HoldRaw.y1 := yyy1;
                                                   WriteToFile(ObjectNumber);
                                              END;
                                         END;
                                    14:  GetDragPoly;
                                    15:  GetDragPoly;
                                    16:  GetDragBezier;
                                    17:  GetDragBezier;
                                    19:  BEGIN
                                              What := (GetStringWidth(HoldRaw.Colour4)*8)+20;
                                              IF GetSeededDragBox(HoldRaw.x1,HoldRaw.y1,HoldRaw.x1+What,HoldRaw.y1+20) THEN
                                              BEGIN
                                                   HoldRaw.x1 := xxx1;
                                                   HoldRaw.y1 := yyy1;
                                                   WriteToFile(ObjectNumber);
                                              END;
                                         END;
                                    26:  GetDragArc;
                                    END;
                                    RedrawScreen(0,0);
                                    HighLightTheObject(ObjectNumber);
                               END
                               ELSE
                               BEGIN
                                    HighLightObject(GetMouseXG(Grid),GetMouseYG(Grid),True);
                                    SetUpEditObject;
                                    REPEAT UNTIL (GrGetMouseButtons<>GrRButton);
                                    DrawMode := False;
                               END;
                          END
                          ELSE
                          BEGIN
                               KeyBox       := False;
                               NButtons     := 6;
                               NumPalettes  := 0;
                               ObjectNumber := 0;
                               GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                               GrDrawRect(0,YWindow+2,380,GraphMaxY-1,GrFill);
                               RedrawScreen(0,0);
                          END;
                     END;
                     TrackX := 999;
                     TrackY := 999;
                     GOTO SkipPast;
                END;
           END;
           IF (((HoldRaw.Number<>10) AND (HoldRaw.Number<>12) AND (HoldRaw.Number<>19) AND
              (HoldRaw.Number<>24) AND (HoldRaw.Number<>25)) OR (NOT(DrawMode))) THEN
           BEGIN
                IF ((GetMouseXG(Grid)<>TrackX) OR (GetMouseYG(Grid)<>TrackY)) THEN
                BEGIN
                     IF GetMouseY>YWindow THEN
                     BEGIN
                          IF NOT(MouseOn) THEN
                          BEGIN
                               GrSetLineStyle(GrLSolid,1);
                               GrSetOp(GxXOR);
                               GrSetColor(XORLine);
                               GrDrawLine(0,TrackY,639,TrackY);
                               GrDrawLine(TrackX,0,TrackX,YWindow);
                               GrSetOp(GxSet);
                               MouseOn := True;
                               GrDisplayMouse(GrShow);
                          END;
                     END
                     ELSE
                     BEGIN
                          IF MouseOn THEN
                          BEGIN
                               GrDisplayMouse(GrHide);
                               MouseOn := False;
                               GrSetLineStyle(GrLSolid,1);
                               GrSetOp(GxXOR);
                               GrSetColor(XORLine);
                               TrackX := GetMouseXG(Grid);
                               TrackY := GetMouseYG(Grid);
                               GrDrawLine(0,TrackY,639,TrackY);
                               GrDrawLine(TrackX,0,TrackX,YWindow);
                               GrSetOp(GxSet);
                          END
                          ELSE
                          BEGIN
                               GrSetLineStyle(GrLSolid,1);
                               GrSetOp(GxXOR);
                               GrSetColor(XORLine);
                               GrDrawLine(0,TrackY,639,TrackY);
                               GrDrawLine(TrackX,0,TrackX,YWindow);
                               TrackX := GetMouseXG(Grid);
                               TrackY := GetMouseYG(Grid);
                               GrDrawLine(0,TrackY,639,TrackY);
                               GrDrawLine(TrackX,0,TrackX,YWindow);
                               GrSetOp(GxSet);
                          END;
                     END;
                END;
           END;
           c := MouseHandler(False);
           CASE C OF
           1:   BEGIN
                     IF NOT(VerifySave('Exiting the screen editor will totally erase',
                                       'the current file in memory. Do you want',
                                       'to proceed?'))
                                       THEN C := 0;
                END;
           2:   BEGIN
                     Work := DoPopUp;
                     IF DoARedraw THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          RedrawScreen(0,0);
                          GrDisplayMouse(GrShow);
                     END;
                     IF Work<>0 THEN
                     BEGIN
                          {WE HAVE SELECTED A NEW TOOL!}
                          CASE Work OF
                          4:   Tool4;
                          5:   Tool5;
                          6:   Tool6;
                          7:   Tool7;
                          8:   Tool8;
                          9:   Tool9;
                          10:  Tool10;
                          11:  Tool11;
                          12:  Tool12;
                          13:  Tool13;
                          14:  Tool14;
                          15:  Tool15;
                          16:  Tool16;
                          17:  Tool17;
                          18:  Tool18;
                          19:  Tool19;
                          20:  Tool20;
                          21:  Tool21;
                          22:  Tool22;
                          23:  Tool23;
                          24:  Tool24;
                          25:  Tool25;
                          26:  Tool26;
                          27:  Tool27;
                          28:  Tool28;
                          34:  Tool34;
                          END;
                     END;
                END;
           3:   BEGIN {Eraser Tool}
                     IF DrawMode THEN
                     BEGIN
                          GrDisplayMouse(GrHide);
                          IF KillLast THEN RedrawScreen(0,0);
                          GrDisplayMouse(GrShow);
                     END
                     ELSE
                     BEGIN
                          IF ObjectNumber<>0 THEN
                          BEGIN
                               GrDisplayMouse(GrHide);
                               DeleteObject(ObjectNumber);
                               KeyBox       := False;
                               NButtons     := 6;
                               NumPalettes  := 0;
                               ObjectNumber := 0;
                               GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                               GrDrawRect(0,YWindow+2,380,GraphMaxY-1,GrFill);
                               RedrawScreen(0,0);
                               GrDisplayMouse(GrShow);
                          END;
                     END;
                END;
           4:   BEGIN
                     IF (Grid<40) THEN INC(Grid)
                                  ELSE Grid := 1;
                     OutTextXY(450,YWindow+24,0,15,1,_String(Grid)+'  ');
                END;
           5:   BEGIN
                     IF (Grid>1) THEN DEC(Grid)
                                 ELSE Grid := 40;
                     OutTextXY(450,YWindow+24,0,15,1,_String(Grid)+'  ');
                END;
           6:   BEGIN
                     IF DrawMode THEN OldRaw  := HoldRaw
                                 ELSE HoldRaw := OldRaw;
                     FlipDrawMode;
                     ObjectNumber := 0;
                END;
           ELSE BEGIN
                     CASE HoldRaw.Number OF
                     4:   BEGIN
                               CASE C OF
                               7:   BEGIN
                                         GrDisplayMouse(GrHide);
                                         GrSetColor(7);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         IF HoldRaw.colour2<8 THEN INC(HoldRaw.colour2,2)
                                                              ELSE HoldRaw.colour2 := 1;
                                         GrSetColor(0);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         GrDisplayMouse(GrShow);
                                         GrSetLineStyle(GrLSolid,1);
                                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                    END;
                               END;
                          END;
                     8:   BEGIN
                               CASE C OF
                               7:   BEGIN
                                         HoldRaw.Number := 9;
                                         WriteToFile(ObjectNumber);
                                         SetUpEditObject;
                                    END;
                               END;
                          END;
                     9:   BEGIN
                               CASE C OF
                               7:   BEGIN
                                         HoldRaw.Number := 8;
                                         WriteToFile(ObjectNumber);
                                         SetUpEditObject;
                                    END;
                               END;
                          END;
                     11:  BEGIN
                               CASE C OF
                               7:   BEGIN
                                         DoChangeWindow;
                                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                    END;
                               END;
                          END;
                     12:  BEGIN
                               CASE C OF
                               7:   BEGIN {Change Icon}
                                         CurrentSize := HoldRaw.Style;
                                         SaveWindow(1);
                                         What := LoadFromBank(HoldRaw.ObjFile);
                                         ReloadWindow(1);
                                         IF What<>0 THEN
                                         BEGIN
                                              HoldRaw.Colour1 := What;
                                              GrDisplayMouse(GrHide);
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              GrDrawRect(162,YWindow+7,198,YWindow+43,GrFill);
                                              DrawIcon(165,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,
                                                       HoldRaw.Colour3,HoldRaw.ObjFile);
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               8:   BEGIN {Change Icon Bank}
                                         Temp := HoldRaw.ObjFile;
                                         What := FileSelector(ICONDir,'*.30','*.16',Temp,True,False,True);
                                         IF What=1 THEN
                                         BEGIN
                                              HoldRaw.Style := WhatSize(ICONDir+Temp);
                                              HoldRaw.ObjFile := Temp;
                                              GrDisplayMouse(GrHide);
                                              OutTextXY(240,YWindow+18,0,15,2,_PadRight(HoldRaw.ObjFile,12));
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              GrDrawRect(162,YWindow+7,198,YWindow+43,GrFill);
                                              DrawIcon(165,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,
                                                       HoldRaw.Colour3,HoldRaw.ObjFile);
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               9:   BEGIN {Change Effect}
                                         GetChangeEffect(HoldRaw.Colour3);
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(240,YWindow+18,0,15,2,_PadRight(HoldRaw.ObjFile,12));
                                         GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                         GrDrawRect(162,YWindow+7,198,YWindow+43,GrFill);
                                         DrawIcon(165,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,
                                                  HoldRaw.Colour3,HoldRaw.ObjFile);
                                         GrDisplayMouse(GrShow);
                                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                    END;
                               END;
                          END;
                     13:  BEGIN
                               CASE C OF
                               7:   BEGIN
                                         DoChangeFonts;
                                         GrDisplayMouse(GrHide);
                                         GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                         GrDrawRect(71,YWindow+21,187,YWindow+43,GrFill);
                                         CASE HoldRaw.Colour7 OF
                                         0:   Temp := HoldRaw.ObjFile;
                                         1:   Temp := 'System Font';
                                         2:   Temp := '8x16 Font';
                                         3:   Temp := '8x14 Font';
                                         4:   Temp := '8x8 Font';
                                         5:   Temp := 'Helvetica';
                                         6:   Temp := 'Roman';
                                         END;
                                         OutTextXY(81,YWindow+26,0,255,2,Temp);
                                         OutTextXY(80,YWindow+25,15,255,2,Temp);
                                         GrDisplayMouse(GrShow);
                                         IF (ObjectNumber<>0) THEN
                                         BEGIN
                                              WriteToFile(ObjectNumber);
                                              GrDisplayMouse(GrHide);
                                              RedrawScreen(0,0);
                                              HighLightTheObject(ObjectNumber);
                                              GrDisplayMouse(GrShow);
                                         END;
                                    END;
                               8:   IF GetChangeText THEN
                                    BEGIN
                                         WriteToFile(ObjectNumber);
                                         GrDisplayMouse(GrHide);
                                         RedrawScreen(0,0);
                                         HighLightTheObject(ObjectNumber);
                                         GrDisplayMouse(GrShow);
                                    END;
                               END;
                          END;
                     14,16:
                          BEGIN
                               CASE C OF
                               7:   BEGIN
                                         GrDisplayMouse(GrHide);
                                         GrSetColor(7);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         IF HoldRaw.colour2<8 THEN INC(HoldRaw.colour2,2)
                                                              ELSE HoldRaw.colour2 := 1;
                                         GrSetColor(0);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         GrDisplayMouse(GrShow);
                                         GrSetLineStyle(GrLSolid,1);
                                         IF (ObjectNumber<>0) THEN UpdatePoly;
                                    END;
                               END;
                          END;
                     19:  BEGIN
                               CASE C OF
                               7:   BEGIN
                                         DoChangePromptType;
                                         IF (ObjectNumber<>0) THEN
                                         BEGIN
                                              WriteToFile(ObjectNumber);
                                              RedrawScreen(0,0);
                                              HighLightTheObject(ObjectNumber);
                                         END;
                                    END;
                               END;
                          END;
                     22:  BEGIN
                               CASE C OF
                               7:   BEGIN
                                         Temp := HoldRaw.ObjFile;
                                         What := FileSelector(JPEGDir,'*.*','',Temp,True,False,True);
                                         IF What=1 THEN
                                         BEGIN
                                              HoldRaw.ObjFile := Temp;
                                              GrDisplayMouse(GrHide);
                                              OutTextXY(240,YWindow+18,0,15,2,_PadRight(HoldRaw.ObjFile,12));
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               8:   IF GetChangeImage THEN
                                    BEGIN
                                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                    END;
                               END;
                          END;
                     24:  BEGIN
                               CASE C OF
                               7,8: BEGIN {Change Icon}
                                         CurrentSize := HoldRaw.Style;
                                         SaveWindow(1);
                                         What := LoadFromBank(HoldRaw.ObjFile);
                                         ReloadWindow(1);
                                         IF What<>0 THEN
                                         BEGIN
                                              CASE C OF
                                              7:   HoldRaw.Colour1 := What;
                                              8:   HoldRaw.Colour2 := What;
                                              END;
                                              GrDisplayMouse(GrHide);
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              CASE C OF
                                              7:   BEGIN
                                                        GrDrawRect(140,YWindow+10,170,YWindow+40,GrFill);
                                                        DrawIcon(140,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,
                                                                 HoldRaw.Colour3,HoldRaw.ObjFile);
                                                   END;
                                              8:   BEGIN
                                                        GrDrawRect(180,YWindow+10,210,YWindow+40,GrFill);
                                                        DrawIcon(180,YWindow+10,HoldRaw.Colour2,HoldRaw.Style,
                                                                 HoldRaw.Colour3,HoldRaw.ObjFile);
                                                   END;
                                              END;
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               9:   BEGIN {Change Icon Bank}
                                         Temp := HoldRaw.ObjFile;
                                         What := FileSelector(ICONDir,'*.30','*.16',Temp,True,False,True);
                                         IF What=1 THEN
                                         BEGIN
                                              HoldRaw.Style := WhatSize(ICONDir+Temp);
                                              HoldRaw.ObjFile := Temp;
                                              GrDisplayMouse(GrHide);
                                              OutTextXY(255,YWindow+18,0,15,2,_PadRight(HoldRaw.ObjFile,12));
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              GrDrawRect(140,YWindow+10,170,YWindow+40,GrFill);
                                              GrDrawRect(180,YWindow+10,210,YWindow+40,GrFill);
                                              DrawIcon(140,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,
                                                       HoldRaw.Colour3,HoldRaw.ObjFile);
                                              DrawIcon(180,YWindow+10,HoldRaw.Colour2,HoldRaw.Style,
                                                       HoldRaw.Colour3,HoldRaw.ObjFile);
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               END;
                          END;
                     25:  BEGIN
                               CASE C OF
                               7,8,9,10,11,12,13,14:
                                    BEGIN {Change Icon}
                                         CurrentSize := HoldRaw.Style;
                                         SaveWindow(1);
                                         What := LoadFromBank(HoldRaw.ObjFile);
                                         ReloadWindow(1);
                                         IF What<>0 THEN
                                         BEGIN
                                              CASE C OF
                                              7:   HoldRaw.Colour1 := What;
                                              8:   HoldRaw.Colour2 := What;
                                              9:   HoldRaw.Colour3 := What;
                                              10:  HoldRaw.Colour4 := What;
                                              11:  HoldRaw.Colour5 := What;
                                              12:  HoldRaw.Colour6 := What;
                                              13:  HoldRaw.Colour7 := What;
                                              14:  HoldRaw.Colour8 := What;
                                              END;
                                              GrDisplayMouse(GrHide);
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              xx := 0;
                                              FOR Work := 1 TO 8 DO
                                              BEGIN
                                                   IF (Work=(C-6)) THEN
                                                   BEGIN
                                                        GrDrawRect(xx+2,YWindow+20,xx+30,YWindow+48,GrFill);
                                                        CASE Work OF
                                                        1:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour1,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        2:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour2,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        3:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour3,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        4:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour4,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        5:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour5,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        6:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour6,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        7:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour7,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        8:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour8,
                                                                      HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                        END;
                                                   END;
                                                   INC(xx,32);
                                              END;
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               15:  BEGIN {Change Icon Bank}
                                         Temp := HoldRaw.ObjFile;
                                         What := FileSelector(ICONDir,'*.30','*.16',Temp,True,False,True);
                                         IF What=1 THEN
                                         BEGIN
                                              HoldRaw.Style := WhatSize(ICONDir+Temp);
                                              HoldRaw.ObjFile := Temp;
                                              GrDisplayMouse(GrHide);
                                              OutTextXY(270,YWindow+30,0,15,2,_PadRight(HoldRaw.ObjFile,12));
                                              GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                                              xx := 0;
                                              FOR Work := 1 TO 8 DO
                                              BEGIN
                                                   GrDrawRect(xx+2,YWindow+20,xx+30,YWindow+48,GrFill);
                                                   CASE Work OF
                                                   1:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour1,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   2:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour2,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   3:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour3,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   4:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour4,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   5:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour5,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   6:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour6,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   7:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour7,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   8:   DrawIcon(xx+1,YWindow+19,HoldRaw.Colour8,
                                                                 HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
                                                   END;
                                                   INC(xx,32);
                                              END;
                                              GrDisplayMouse(GrShow);
                                              IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                         END;
                                    END;
                               END;
                          END;
                     26:  BEGIN
                               CASE C OF
                               7:   BEGIN
                                         GrDisplayMouse(GrHide);
                                         GrSetColor(7);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         IF HoldRaw.colour2<8 THEN INC(HoldRaw.colour2,2)
                                                              ELSE HoldRaw.colour2 := 1;
                                         GrSetColor(0);
                                         GrSetLineStyle(GrLSolid,HoldRaw.colour2);
                                         GrDrawLine(240,YWindow+15,330,YWindow+15);
                                         GrDisplayMouse(GrShow);
                                         GrSetLineStyle(GrLSolid,1);
                                         IF (ObjectNumber<>0) THEN WriteToFile(ObjectNumber);
                                    END;
                               END;
                          END;
                     28:  BEGIN
                               CASE C OF
                               7:   IF GetChangeTextFile THEN
                                    BEGIN
                                         IF (ObjectNumber<>0) THEN
                                         BEGIN
                                              WriteToFile(ObjectNumber);
                                              GrDisplayMouse(GrHide);
                                              RedrawScreen(0,0);
                                              HighLightTheObject(ObjectNumber);
                                              GrDisplayMouse(GrShow);
                                         END;
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           SkipPast:
           What := CheckKeys;
           IF (ObjectNumber<>0) THEN
           BEGIN
                IF ((What=1) OR (What=2)) THEN
                BEGIN
                     CASE What OF
                     1:   MoveToTop(ObjectNumber);
                     2:   MoveToBottom(ObjectNumber);
                     END;
                     KeyBox       := False;
                     NButtons     := 6;
                     NumPalettes  := 0;
                     ObjectNumber := 0;
                     IF MouseOn THEN GrDisplayMouse(GrHide);
                     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                     GrDrawRect(0,YWindow+2,380,GraphMaxY-1,GrFill);
                     RedrawScreen(0,0);
                     IF MouseOn THEN GrDisplayMouse(GrShow);
                     TrackX := 999;
                     TrackY := 999;
                END
                ELSE IF What=3 THEN
                BEGIN
                     IF ObjectNumber<>0 THEN
                     BEGIN
                          IF MouseOn THEN GrDisplayMouse(GrHide);
                          DeleteObject(ObjectNumber);
                          KeyBox       := False;
                          NButtons     := 6;
                          NumPalettes  := 0;
                          ObjectNumber := 0;
                          GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                          GrDrawRect(0,YWindow+2,380,GraphMaxY-1,GrFill);
                          RedrawScreen(0,0);
                          IF MouseOn THEN GrDisplayMouse(GrShow);
                          TrackX := 999;
                          TrackY := 999;
                     END;
                END;
           END;
     UNTIL c=1;
     GrSetLineStyle(GrLSolid,1);
     GrSetOp(GxSet);
     IF MouseOn THEN GrDisplayMouse(GrHide);
     Load_Screen;
     ERASE(FWorkSG);
     GrDisplayMouse(GrShow);
END;


END.
