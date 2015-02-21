{$I DEFINES.INC}
UNIT ObjSet;


INTERFACE


PROCEDURE FlipDrawMode;
PROCEDURE SetUpEditObject;
PROCEDURE ScreenSetupBasic;
PROCEDURE ScreenSetup4;
PROCEDURE ScreenSetup5;
PROCEDURE ScreenSetup6;
PROCEDURE ScreenSetup7;
PROCEDURE ScreenSetup8;
PROCEDURE ScreenSetup9;
PROCEDURE ScreenSetup10;
PROCEDURE ScreenSetup11;
PROCEDURE ScreenSetup12;
PROCEDURE ScreenSetup13;
PROCEDURE ScreenSetup14;
PROCEDURE ScreenSetup15;
PROCEDURE ScreenSetup16;
PROCEDURE ScreenSetup17;
PROCEDURE ScreenSetup18;
PROCEDURE ScreenSetup19;
PROCEDURE ScreenSetup20;
PROCEDURE ScreenSetup21;
PROCEDURE ScreenSetup22;
PROCEDURE ScreenSetup23;
PROCEDURE ScreenSetup24;
PROCEDURE ScreenSetup25;
PROCEDURE ScreenSetup26;
PROCEDURE ScreenSetup27;
PROCEDURE ScreenSetup28;


IMPLEMENTATION


USES Globals,PalBoxes,Gr2_Bp,BsGraph,BHandler,_Icons,_Text,_Win,BsString,Redraw;


PROCEDURE ScreenSetupBasic;
BEGIN
     KeyBox  := False;
     ClearPaletteQueue;
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrDrawRect(0,YWindow+2,380,GraphMaxY-1,GrFill);
     NButtons := 0;
     {EXIT BUTTON}
     SystemButton(600,YWindow+17,630,YWindow+47,1,False,False);
     SystemIcon(600,YWindow+17,9);
     {TOOL BAR BUTTON}
     SystemButton(510,YWindow+17,570,YWindow+47,1,False,False);
     IF DrawMode THEN
     BEGIN
          OutTextXY(517,YWindow+25,0,255,1,'Tool Bar');
          Buttons[2].Enabled := True;
     END
     ELSE
     BEGIN
          OutTextXY(517,YWindow+25,8,255,1,'Tool Bar');
          GrSetFillStyle(GrFCloseDot,WindowBack,GrTrans);
          GrDrawRect(512,YWindow+19,568,YWindow+45,GrFill);
          Buttons[2].Enabled := False;
     END;
     {ERASER BUTTON}
     SystemButton(570,YWindow+17,600,YWindow+47,1,False,False);
     SystemIcon(570,YWindow+17,61);
     {GRID CHANGE BUTTONS}
     SystemButton(480,YWindow+16,495,YWindow+31,1,False,False);
     SystemButton(480,YWindow+31,495,YWindow+46,1,False,False);
     SystemIcon(481,YWindow+19,74);
     SystemIcon(481,YWindow+34,75);
     OutTextXY(445,YWindow+2,0,255,1,'Grid');
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(435,YWindow+17,478,YWindow+45,GrFill+GrOutline);
     InvertedBox(434,YWindow+16,479,YWindow+46);
     OutTextXY(450,YWindow+24,0,15,1,_String(Grid)+'  ');
     {DRAWMODE BUTTON}
     SystemButton(390,YWindow+16,420,YWindow+46,1,False,False);
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrDrawRect(392,YWindow+18,418,YWindow+44,GrFill);
     IF DrawMode THEN SystemIcon(390,YWindow+16,31)
                 ELSE SystemIcon(390,YWindow+16,30);
     OutTextXY(390,YWindow+2,0,255,1,'Mode');
END;


{LINES}
PROCEDURE ScreenSetup4;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour1,False);
     SystemButton(190,YWindow+4,350,YWindow+26,1,False,True);
     GrSetColor(0);
     GrSetLineStyle(GrLSolid,HoldRaw.colour2);
     GrDrawLine(240,YWindow+15,330,YWindow+15);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Line');
     OutTextXY(196,YWindow+8,0,255,1,'Width');
     OutTextXY(120,YWindow+30,0,WindowBack,1,'Colour');
END;


{BOXES}
PROCEDURE ScreenSetup5;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+8,10,HoldRaw.Colour1,True);
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour2,True);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Rectangle');
     OutTextXY(116,YWindow+6,0,WindowBack,1,'Outline');
     OutTextXY(140,YWindow+30,0,WindowBack,1,'Fill');
END;


{ELLIPSES}
PROCEDURE ScreenSetup6;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+8,10,HoldRaw.Colour1,True);
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour2,True);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Ellipse');
     OutTextXY(116,YWindow+6,0,WindowBack,1,'Outline');
     OutTextXY(140,YWindow+30,0,WindowBack,1,'Fill');
END;


{FLOOD FILL}
PROCEDURE ScreenSetup7;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+20,10,HoldRaw.Colour1,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Flood Fill');
     OutTextXY(120,YWindow+18,0,WindowBack,1,'Colour');
END;


{NORMAL BUTTONS}
PROCEDURE ScreenSetup8;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(220,YWindow+7,8,HoldRaw.Colour1,False);
     AddToPaletteQueue(220,YWindow+22,8,HoldRaw.Colour2,False);
     AddToPaletteQueue(220,YWindow+37,8,HoldRaw.Colour3,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Normal Button');
     OutTextXY(160,YWindow+5,0,WindowBack,1,'Face');
     OutTextXY(138,YWindow+20,0,WindowBack,1,'Highlight');
     OutTextXY(142,YWindow+35,0,WindowBack,1,'Shadow');
     KeyBoxX := 15;
     KeyBoxY := YWindow+24;
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrSetColor(0);
     GrDrawRect(KeyBoxX,KeyBoxY,KeyBoxX+20,KeyBoxY+20,GrFill+GrOutline);
     InvertedBox(KeyBoxX-1,KeyBoxY-1,KeyBoxX+21,KeyBoxY+21);
     OutTextXY(KeyBoxX+7,KeyBoxY+3,0,15,3,HoldRaw.Return);
     KeyBox  := True;
END;


{PANEL BUTTONS}
PROCEDURE ScreenSetup9;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(220,YWindow+7,8,HoldRaw.Colour1,False);
     AddToPaletteQueue(220,YWindow+22,8,HoldRaw.Colour2,False);
     AddToPaletteQueue(220,YWindow+37,8,HoldRaw.Colour3,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Bevelled Button');
     OutTextXY(160,YWindow+5,0,WindowBack,1,'Face');
     OutTextXY(138,YWindow+20,0,WindowBack,1,'Highlight');
     OutTextXY(142,YWindow+35,0,WindowBack,1,'Shadow');
     KeyBoxX := 15;
     KeyBoxY := YWindow+24;
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrSetColor(0);
     GrDrawRect(KeyBoxX,KeyBoxY,KeyBoxX+20,KeyBoxY+20,GrFill+GrOutline);
     InvertedBox(KeyBoxX-1,KeyBoxY-1,KeyBoxX+21,KeyBoxY+21);
     OutTextXY(KeyBoxX+7,KeyBoxY+3,0,15,3,HoldRaw.Return);
     KeyBox  := True;
END;


{POP BUTTONS}
PROCEDURE ScreenSetup10;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Radio Button');
     KeyBoxX := 40;
     KeyBoxY := YWindow+24;
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrSetColor(0);
     GrDrawRect(KeyBoxX,KeyBoxY,KeyBoxX+20,KeyBoxY+20,GrFill+GrOutline);
     InvertedBox(KeyBoxX-1,KeyBoxY-1,KeyBoxX+21,KeyBoxY+21);
     OutTextXY(KeyBoxX+7,KeyBoxY+3,0,15,3,HoldRaw.Return);
     KeyBox  := True;
END;


{WINDOWS}
PROCEDURE ScreenSetup11;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Window');
     SystemButton(190,YWindow+14,330,YWindow+36,1,False,True);
     OutTextXY(210,YWindow+18,0,255,1,'Window Settings');
END;


{ICONS}
PROCEDURE ScreenSetup12;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Icon');
     SystemButton(160,YWindow+5,200,YWindow+45,1,False,True);
     SystemButton(210,YWindow+15,230,YWindow+35,1,False,True);
     SystemButton(95,YWindow+15,150,YWindow+35,1,False,True);
     OutTextXY(105,YWindow+18,0,255,1,'Effect');
     SystemIcon(214,YWindow+19,46);
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(231,YWindow+16,346,YWindow+34,GrOutline+GrFill);
     InvertedBox(231,YWindow+15,347,YWindow+35);
     OutTextXY(240,YWindow+18,0,15,2,HoldRaw.ObjFile);
     DrawIcon(165,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
END;


{TEXT}
PROCEDURE ScreenSetup13;
VAR  Temp : String;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Text');
     SystemButton(200,YWindow+20,300,YWindow+44,1,False,True);
     OutTextXY(213,YWindow+24,0,255,1,'Font Settings');
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
     InvertedBox(70,YWindow+20,188,YWindow+44);
     OutTextXY(70,YWindow+4,1,255,1,'Font File:');
END;


{POLY LINES}
PROCEDURE ScreenSetup14;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Polyline');
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour1,False);
     SystemButton(190,YWindow+4,350,YWindow+26,1,False,True);
     GrSetColor(0);
     GrSetLineStyle(GrLSolid,HoldRaw.colour2);
     GrDrawLine(240,YWindow+15,330,YWindow+15);
     OutTextXY(196,YWindow+8,0,255,1,'Width');
     OutTextXY(120,YWindow+30,0,WindowBack,1,'Colour');
END;


{POLYGONS}
PROCEDURE ScreenSetup15;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+8,10,HoldRaw.Colour1,True);
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour2,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Polygon');
     OutTextXY(116,YWindow+6,0,WindowBack,1,'Outline');
     OutTextXY(140,YWindow+30,0,WindowBack,1,'Fill');
END;


{BEZIER CURVES}
PROCEDURE ScreenSetup16;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Bezier Curve');
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour1,False);
     SystemButton(190,YWindow+4,350,YWindow+26,1,False,True);
     GrSetColor(0);
     GrSetLineStyle(GrLSolid,HoldRaw.colour2);
     GrDrawLine(240,YWindow+15,330,YWindow+15);
     OutTextXY(196,YWindow+8,0,255,1,'Width');
     OutTextXY(120,YWindow+30,0,WindowBack,1,'Colour');
END;


{BEZIER OBJECTS}
PROCEDURE ScreenSetup17;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Bezier Object');
     AddToPaletteQueue(190,YWindow+8,10,HoldRaw.Colour1,True);
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour2,False);
     OutTextXY(116,YWindow+6,0,WindowBack,1,'Outline');
     OutTextXY(140,YWindow+30,0,WindowBack,1,'Fill');
END;


{PROGRESS INDICATORS}
PROCEDURE ScreenSetup18;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+22,10,HoldRaw.Colour1,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Progress Indicator');
     OutTextXYFR(155,YWindow+20,0,WindowBack,'Colour');
END;


{PROMPT BOXES}
PROCEDURE ScreenSetup19;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Data Entry Box');
     AddToPaletteQueue(220,YWindow+7,8,HoldRaw.Colour1,False);
     AddToPaletteQueue(220,YWindow+22,8,HoldRaw.Colour2,False);
     AddToPaletteQueue(220,YWindow+37,8,HoldRaw.Colour3,False);
     OutTextXYFR(185,YWindow+5,0,WindowBack,'Background');
     OutTextXYFR(185,YWindow+20,0,WindowBack,'Entry Text');
     OutTextXYFR(185,YWindow+35,0,WindowBack,'Disabled Text');
     SystemButton(10,YWindow+24,85,YWindow+44,1,False,True);
     OutTextXY(34,YWindow+26,0,255,1,'Type');
END;


{DIMENSION FRAMES}
PROCEDURE ScreenSetup20;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+8,10,HoldRaw.Colour1,False);
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour2,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'3D Frame');
     OutTextXYFR(155,YWindow+6,0,WindowBack,'Upper Left');
     OutTextXYFR(155,YWindow+30,0,WindowBack,'Lower Right');
END;


{PICK LISTS}
PROCEDURE ScreenSetup21;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Pick List');
END;


{GRAPHIC IMAGES}
PROCEDURE ScreenSetup22;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Graphic Image');
     SystemButton(210,YWindow+15,230,YWindow+35,1,False,True);
     SystemIcon(214,YWindow+19,46);
     SystemButton(100,YWindow+15,200,YWindow+35,1,False,True);
     OutTextXY(130,YWindow+18,0,WindowBack,1,'Options');
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(231,YWindow+16,346,YWindow+34,GrOutline+GrFill);
     InvertedBox(231,YWindow+15,347,YWindow+35);
     OutTextXY(240,YWindow+18,0,15,2,HoldRaw.ObjFile);
END;


{STRING PADS}
PROCEDURE ScreenSetup23;
BEGIN
     ScreenSetupBasic;
     AddToPaletteQueue(190,YWindow+20,10,HoldRaw.Colour1,False);
     OutTextXY(6,YWindow+4,0,WindowBack,1,'String Pad');
     OutTextXY(120,YWindow+18,0,WindowBack,1,'Colour');
END;


{CUSTOM CONTROLS}
PROCEDURE ScreenSetup24;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'3D Custom Control');
     SystemButton(135,YWindow+5,175,YWindow+45,1,False,True);
     SystemButton(175,YWindow+5,215,YWindow+45,1,False,True);
     SystemButton(225,YWindow+15,245,YWindow+35,1,False,True);
     SystemIcon(229,YWindow+19,46);
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(246,YWindow+16,361,YWindow+34,GrOutline+GrFill);
     InvertedBox(246,YWindow+15,362,YWindow+35);
     OutTextXY(255,YWindow+18,0,15,2,HoldRaw.ObjFile);
     DrawIcon(140,YWindow+10,HoldRaw.Colour1,HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
     DrawIcon(180,YWindow+10,HoldRaw.Colour2,HoldRaw.Style,HoldRaw.Colour3,HoldRaw.ObjFile);
END;


{ANIMATED ICONS}
PROCEDURE ScreenSetup25;
VAR  Loop : Word;
     X    : Word;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Animated Icon');
     X := 0;
     FOR Loop := 1 TO 8 DO
     BEGIN
          SystemButton(x,YWindow+18,x+32,YWindow+50,1,False,True);
          CASE Loop OF
          1:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour1,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          2:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour2,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          3:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour3,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          4:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour4,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          5:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour5,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          6:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour6,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          7:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour7,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          8:   DrawIcon(x+1,YWindow+19,HoldRaw.Colour8,HoldRaw.Style,HoldRaw.Colour9,HoldRaw.ObjFile);
          END;
          INC(x,32);
     END;
     SystemButton(260,YWindow+5,377,YWindow+25,1,False,True);
     OutTextXY(295,YWindow+8,0,WindowBack,1,'Icon File');
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(261,YWindow+28,376,YWindow+46,GrOutline+GrFill);
     InvertedBox(260,YWindow+27,377,YWindow+47);
     OutTextXY(270,YWindow+30,0,15,2,HoldRaw.ObjFile);
END;


{PLAIN ARC TOOL}
PROCEDURE ScreenSetup26;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Plain Arc');
     AddToPaletteQueue(190,YWindow+32,10,HoldRaw.Colour1,False);
     SystemButton(190,YWindow+4,350,YWindow+26,1,False,True);
     GrSetColor(0);
     GrSetLineStyle(GrLSolid,HoldRaw.colour2);
     GrDrawLine(240,YWindow+15,330,YWindow+15);
     OutTextXY(196,YWindow+8,0,255,1,'Width');
     OutTextXY(120,YWindow+30,0,WindowBack,1,'Colour');
END;


{CLICKABLE REGIONS}
PROCEDURE ScreenSetup27;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Clickable Region');
     KeyBoxX := 40;
     KeyBoxY := YWindow+24;
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrSetColor(0);
     GrDrawRect(KeyBoxX,KeyBoxY,KeyBoxX+20,KeyBoxY+20,GrFill+GrOutline);
     InvertedBox(KeyBoxX-1,KeyBoxY-1,KeyBoxX+21,KeyBoxY+21);
     OutTextXY(KeyBoxX+7,KeyBoxY+3,0,15,3,HoldRaw.Return);
     KeyBox  := True;
END;


{TEXT BOXES}
PROCEDURE ScreenSetup28;
BEGIN
     ScreenSetupBasic;
     OutTextXY(6,YWindow+4,0,WindowBack,1,'Textfile Box');
     SystemButton(100,YWindow+15,200,YWindow+35,1,False,True);
     OutTextXY(125,YWindow+18,0,WindowBack,1,'Text File');
END;


PROCEDURE SetUpEditObject;
BEGIN
     IF MouseOn THEN GrDisplayMouse(GrHide);
     CASE HoldRaw.Number OF
     4:   ScreenSetup4;
     5:   ScreenSetup5;
     6:   ScreenSetup6;
     7:   ScreenSetup7;
     8:   BEGIN
               ScreenSetup8;
               SystemButton(50,YWindow+24,130,YWindow+44,1,False,True);
               OutTextXY(55,YWindow+27,0,255,1,'Switch Style');
          END;
     9:   BEGIN
               ScreenSetup9;
               SystemButton(50,YWindow+24,130,YWindow+44,1,False,True);
               OutTextXY(55,YWindow+27,0,255,1,'Switch Style');
          END;
     10:  ScreenSetup10;
     11:  ScreenSetup11;
     12:  ScreenSetup12;
     13:  BEGIN
               ScreenSetup13;
               SystemButton(300,YWindow+20,359,YWindow+44,1,False,True);
               OutTextXY(308,YWindow+25,0,255,1,'ABC abc');
          END;
     14:  ScreenSetup14;
     15:  ScreenSetup15;
     16:  ScreenSetup16;
     17:  ScreenSetup17;
     18:  ScreenSetup18;
     19:  ScreenSetup19;
     20:  ScreenSetup20;
     21:  ScreenSetup21;
     22:  ScreenSetup22;
     23:  ScreenSetup23;
     24:  ScreenSetup24;
     25:  ScreenSetup25;
     26:  ScreenSetup26;
     27:  ScreenSetup27;
     28:  ScreenSetup28;
     END;
     IF MouseOn THEN GrDisplayMouse(GrShow);
END;


PROCEDURE FlipDrawMode;
BEGIN
     IF DrawMode THEN DrawMode := False
                 ELSE DrawMode := True;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     ObjectNumber := 0;
     IF DrawMode THEN
     BEGIN
          CASE HoldRaw.Number OF
          4:   ScreenSetup4;
          5:   ScreenSetup5;
          6:   ScreenSetup6;
          7:   ScreenSetup7;
          8:   ScreenSetup8;
          9:   ScreenSetup9;
          10:  ScreenSetup10;
          11:  ScreenSetup11;
          12:  ScreenSetup12;
          13:  ScreenSetup13;
          14:  ScreenSetup14;
          15:  ScreenSetup15;
          16:  ScreenSetup16;
          17:  ScreenSetup17;
          18:  ScreenSetup18;
          19:  ScreenSetup19;
          20:  ScreenSetup20;
          21:  ScreenSetup21;
          22:  ScreenSetup22;
          23:  ScreenSetup23;
          24:  ScreenSetup24;
          25:  ScreenSetup25;
          26:  ScreenSetup26;
          27:  ScreenSetup27;
          28:  ScreenSetup28;
          END;
     END
     ELSE ScreenSetupBasic;
     Buttons[2].Enabled := DrawMode;
     IF DrawMode THEN OutTextXY(517,YWindow+25,0,255,1,'Tool Bar')
                 ELSE
                 BEGIN
                      OutTextXY(517,YWindow+25,8,255,1,'Tool Bar');
                      GrSetFillStyle(GrFCloseDot,WindowBack,GrTrans);
                      GrDrawRect(512,YWindow+19,568,YWindow+45,GrFill);
                 END;
     RedrawScreen(0,0);
     IF MouseOn THEN GrDisplayMouse(GrShow);
END;


END.
