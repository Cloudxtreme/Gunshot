{$I DEFINES.INC}
UNIT MiscDefs;


INTERFACE


PROCEDURE DoChangeWindow;
PROCEDURE DoChangeFonts;
PROCEDURE DoChangePromptType;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,PalBoxes,BHandler,BsGraph,Crt,
     BsKeys,BsString,Dos,Tx2_Bp,PickLst,_Text,Shotgun;


PROCEDURE DoChangeWindow;
VAR  C           : Word;
     CC          : Char;
     XX,YY       : Word;
     TypeWindowX : Word;
     TypeWindowY : Word;
     NewRaw      : _Raw_File;
     EditPos     : Word;
LABEL              SkipIt,SkipOnIn;

     PROCEDURE UpdateMinimize;
     BEGIN
          CASE HoldRaw.Colour9 OF
          0:   GrSetFillStyle(GrFSolid,7,GrOpaque);
          1:   GrSetFillStyle(GrFSolid,4,GrOpaque);
          END;
          GrDrawRect(Buttons[6].x1+4,Buttons[6].y1+4,Buttons[6].x1+9,Buttons[6].y1+9,GrFill);
     END;

     PROCEDURE UpdateTrans;
     BEGIN
          CASE HoldRaw.Colour10 OF
          0:   GrSetFillStyle(GrFSolid,7,GrOpaque);
          1:   GrSetFillStyle(GrFSolid,4,GrOpaque);
          END;
          GrDrawRect(Buttons[7].x1+4,Buttons[7].y1+4,Buttons[7].x1+9,Buttons[7].y1+9,GrFill);
     END;

     PROCEDURE UpdateStyle;
     VAR  c1,c2,c3,c4,c5,c6,c7,c8 : Byte;
          x,y                     : Word;
     BEGIN
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
          GrDrawRect(Buttons[3].x1+4,Buttons[3].y1+4,Buttons[3].x1+9,Buttons[3].y1+9,GrFill);
          GrDrawRect(Buttons[4].x1+4,Buttons[4].y1+4,Buttons[4].x1+9,Buttons[4].y1+9,GrFill);
          GrDrawRect(Buttons[5].x1+4,Buttons[5].y1+4,Buttons[5].x1+9,Buttons[5].y1+9,GrFill);
          GrSetFillStyle(GrFSolid,4,GrOpaque);
          GrDrawRect(Buttons[HoldRaw.Style+1].x1+4,Buttons[HoldRaw.Style+1].y1+4,
                     Buttons[HoldRaw.Style+1].x1+9,Buttons[HoldRaw.Style+1].y1+9,GrFill);
          NewRaw := HoldRaw;
          NewRaw.x1   := ScreenInfo.OrigX2+ScreenInfo.XOffset-205;
          NewRaw.y1   := ScreenInfo.OrigY1+ScreenInfo.YOffset+135;
          NewRaw.x2   := ScreenInfo.OrigX2+ScreenInfo.XOffset-20;
          NewRaw.y2   := ScreenInfo.OrigY2+ScreenInfo.YOffset-135;
          NewRaw.Text := 'Sample';
          GrSetFillStyle(GrFSolid,8,GrOpaque);
          GrDrawRect(NewRaw.x1,NewRaw.y1,NewRaw.x2,NewRaw.y2,GrFill);
          DrawTheWindow(NewRaw);
          CASE HoldRaw.Style OF
          1:   BEGIN
                    c1 := 0; c2 := 7; c3 := 0; c4 := 0;
                    c5 := 0; c6 := 0; c7 := 0; c8 := 0;
               END;
          2:   BEGIN
                    c1 := 0; c2 := 7; c3 := 0; c4 := 0;
                    c5 := 0; c6 := 0; c7 := 0; c8 := 0;
               END;
          3:   BEGIN
                    c1 := 0; c2 := 0; c3 := 7; c4 := 7;
                    c5 := 0; c6 := 7; c7 := 7; c8 := 0;
               END;
          4:   BEGIN
                    c1 := 0; c2 := 7; c3 := 0; c4 := 0;
                    c5 := 7; c6 := 7; c7 := 7; c8 := 7;
               END;
          END;
          x := ScreenInfo.OrigX1+ScreenInfo.XOffset+135;
          y := ScreenInfo.OrigY1+ScreenInfo.YOffset;
          OutTextXYFR(X,Y+123,c1,255,'Window Background');
          OutTextXYFR(X,Y+148,c2,255,'Window Border');
          OutTextXYFR(X,Y+173,c3,255,'Window Highlight');
          OutTextXYFR(X,Y+198,c4,255,'Window Shadow');
          OutTextXYFR(X,Y+223,c5,255,'Header Background');
          OutTextXYFR(X,Y+248,c6,255,'Header Highlight');
          OutTextXYFR(X,Y+273,c7,255,'Header Shadow');
          OutTextXYFR(X,Y+298,c8,255,'Header Text Colour');
     END;

BEGIN
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(25,50,605,405,'WINDOW SETTINGS',EditWindow);
     ClearPaletteQueue;
     AddToPaletteQueue(200,175,10,HoldRaw.Colour1,False);
     AddToPaletteQueue(200,200,10,HoldRaw.Colour2,False);
     AddToPaletteQueue(200,225,10,HoldRaw.Colour3,False);
     AddToPaletteQueue(200,250,10,HoldRaw.Colour4,False);
     AddToPaletteQueue(200,275,10,HoldRaw.Colour5,False);
     AddToPaletteQueue(200,300,10,HoldRaw.Colour6,False);
     AddToPaletteQueue(200,325,10,HoldRaw.Colour7,False);
     AddToPaletteQueue(200,350,10,HoldRaw.Colour8,False);
     {SYSTEM BUTTONS}
     SystemButton(530,365,595,395,1,False,True);
     OutTextXY(550,373,0,255,1,'Done');
     {SAMPLE WINDOW}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,8,GrOpaque);
     GrDrawRect(390,175,595,280,GrFill+GrOutline);
     InvertedBox(389,174,596,281);
     OutTextXY(390,158,0,255,1,'Sample Window');
     NewRaw := HoldRaw;
     NewRaw.x1   := ScreenInfo.OrigX2+ScreenInfo.XOffset-205;
     NewRaw.y1   := ScreenInfo.OrigY1+ScreenInfo.YOffset+135;
     NewRaw.x2   := ScreenInfo.OrigX2+ScreenInfo.XOffset-20;
     NewRaw.y2   := ScreenInfo.OrigY2+ScreenInfo.YOffset-135;
     NewRaw.Text := 'Sample';
     DrawTheWindow(NewRaw);
     {TEXT ENTRY}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(45,110,585,130,GrOutline+GrFill);
     InvertedBox(44,109,586,131);
     OutTextXY(45,93,0,255,1,'Window Title');
     {STUFFED TEXT ENTRY}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+30;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+63;
     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text);
     OutTextXY(TypeWindowX+(Length(HoldRaw.Text)*8),TypeWindowY+1,0,15,2,'_');
     EditPos := Length(HoldRaw.Text)+1;
     GrSetColor(8); GrDrawLine(35,145,595,145);
     GrSetColor(7); GrDrawLine(35,146,595,146);
     {STYLE SELECTIONS}
     SystemButton(390,326,0,0,4,False,True);
     SystemButton(390,343,0,0,4,False,True);
     SystemButton(390,360,0,0,4,False,True);
     SystemButton(390,377,0,0,4,False,True);
     OutTextXY(410,326,0,255,1,'Classic Relief');
     OutTextXY(410,343,0,255,1,'Stamped Header');
     OutTextXY(410,360,0,255,1,'Dozzy Windows');
     OutTextXY(410,377,0,255,1,'Panel Window');
     {MINIMIZE}
     SystemButton(390,309,0,0,4,False,True);
     OutTextXY(410,309,0,255,1,'Minimizable Window/Screen');
     UpdateMinimize;
     {TRANSPARENT}
     SystemButton(390,292,0,0,4,False,True);
     OutTextXY(410,292,0,255,1,'Transparent Window');
     UpdateTrans;
     UpdateStyle;
     GrDisplayMouse(GrShow);
     REPEAT
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                XX := GetMouseX;
                YY := GetMouseY;
                IF ChangedAColour(XX,YY) THEN
                BEGIN
                     CASE ChangedWhich OF
                     1:   HoldRaw.colour1 := Palettes[ChangedWhich].Current;
                     2:   HoldRaw.colour2 := Palettes[ChangedWhich].Current;
                     3:   HoldRaw.colour3 := Palettes[ChangedWhich].Current;
                     4:   HoldRaw.colour4 := Palettes[ChangedWhich].Current;
                     5:   HoldRaw.colour5 := Palettes[ChangedWhich].Current;
                     6:   HoldRaw.colour6 := Palettes[ChangedWhich].Current;
                     7:   HoldRaw.colour7 := Palettes[ChangedWhich].Current;
                     8:   HoldRaw.colour8 := Palettes[ChangedWhich].Current;
                     END;
                     NewRaw := HoldRaw;
                     NewRaw.x1   := ScreenInfo.OrigX2+ScreenInfo.XOffset-205;
                     NewRaw.y1   := ScreenInfo.OrigY1+ScreenInfo.YOffset+135;
                     NewRaw.x2   := ScreenInfo.OrigX2+ScreenInfo.XOffset-20;
                     NewRaw.y2   := ScreenInfo.OrigY2+ScreenInfo.YOffset-135;
                     NewRaw.Text := 'Sample';
                     GrDisplayMouse(GrHide);
                     GrSetFillStyle(GrFSolid,8,GrOpaque);
                     GrDrawRect(NewRaw.x1,NewRaw.y1,NewRaw.x2,NewRaw.y2,GrFill);
                     DrawTheWindow(NewRaw);
                     GrDisplayMouse(GrShow);
                END
                ELSE MoveColourPal(XX,YY);
           END;
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+30;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+63;
           IF KeyPressed THEN
           BEGIN
                CC := ReadKey;
                IF Ord(CC)=0 THEN
                BEGIN
                     CC := ReadKey;
                     CASE ORD(CC) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(HoldRaw.Text)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(HoldRaw.Text)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(HoldRaw.Text,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(HoldRaw.Text)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,True);
                               IF (CC<>#0) THEN GOTO SkipOnIn;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(CC) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(HoldRaw.Text,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                               END;
                          END;
                     13:  GOTO SkipIt;
                     127: BEGIN
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               OutTextXY(TypeWindowX,TypeWindowY,15,15,2,HoldRaw.Text);
                               HoldRaw.Text := '';
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                          END;
                     ELSE BEGIN
                               CC := IsTheKeyOk(CC,False);
                               IF (CC<>#0) THEN
                               BEGIN
                                    SkipOnIn:
                                    IF LENGTH(HoldRaw.Text)<65 THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         HoldRaw.Text := _Mid(HoldRaw.Text,1,EditPos-1)+CC+
                                                         _Mid(HoldRaw.Text,EditPos,LENGTH(HoldRaw.Text));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,HoldRaw.Text);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           C := MouseHandler(False);
           CASE C OF
           2:   IF HoldRaw.Style<>1 THEN
                BEGIN
                     HoldRaw.Style := 1;
                     GrDisplayMouse(GrHide);
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           3:   IF HoldRaw.Style<>2 THEN
                BEGIN
                     HoldRaw.Style := 2;
                     GrDisplayMouse(GrHide);
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           4:   IF HoldRaw.Style<>3 THEN
                BEGIN
                     HoldRaw.Style := 3;
                     GrDisplayMouse(GrHide);
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           5:   IF HoldRaw.Style<>4 THEN
                BEGIN
                     HoldRaw.Style := 4;
                     GrDisplayMouse(GrHide);
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           6:   BEGIN
                     CASE HoldRaw.Colour9 OF
                     0:   HoldRaw.Colour9 := 1;
                     1:   HoldRaw.Colour9 := 0;
                     END;
                     GrDisplayMouse(GrHide);
                     UpdateMinimize;
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           7:   BEGIN
                     CASE HoldRaw.Colour10 OF
                     0:   HoldRaw.Colour10 := 1;
                     1:   HoldRaw.Colour10 := 0;
                     END;
                     GrDisplayMouse(GrHide);
                     UpdateTrans;
                     UpdateStyle;
                     GrDisplayMouse(GrShow);
                END;
           END;
     UNTIL C=1;
     SkipIt:
     GrDisplayMouse(GrHide);
     KillWindow;
     ReloadWindow(1);
     GrDisplayMouse(GrShow);
     ClearPaletteQueue;
END;


PROCEDURE DoChangeFonts;
VAR  NumFiles : Word;
     DirInfo  : SearchRec;
     Loop     : Word;
     C        : Word;
     FX       : Word;
     FY       : Word;
     WorkSg2  : _Raw_File;
     XX,YY    : Word;
     TheOne   : Word;
     Current  : Word;
     Temp     : String;

     PROCEDURE UpdateAttributes;
     BEGIN
          GrDisplayMouse(GrHide);
          IF HoldRaw.Colour6=1 THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
          IF HoldRaw.Colour5=1 THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[4].x1+4,Buttons[4].y1+4,Buttons[4].x1+9,Buttons[4].y1+9,GrFill);
          IF HoldRaw.Colour3=1 THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                               ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[5].x1+4,Buttons[5].y1+4,Buttons[5].x1+9,Buttons[5].y1+9,GrFill);
          GrDisplayMouse(GrShow);
     END;

     PROCEDURE DrawTheSample;
     BEGIN
          CASE HoldRaw.Colour7 OF
          0:   Temp := HoldRaw.ObjFile;
          1:   Temp := 'System Font';
          2:   Temp := '8x16 Font';
          3:   Temp := '8x14 Font';
          4:   Temp := '8x8 Font';
          5:   Temp := 'Helvetica';
          6:   Temp := 'Roman';
          END;
          OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+180,
                   ScreenInfo.OrigY1+ScreenInfo.YOffset+56,
                   9,WindowBack,2,_PadRight(Temp,12));
          WorkSg2      := HoldRaw;
          WorkSg2.Text := 'ABC abc 0123 !$%';
          WorkSg2.x1   := ScreenInfo.OrigX1+ScreenInfo.XOffset+168;
          WorkSg2.y1   := ScreenInfo.OrigY1+ScreenInfo.YOffset+82;
          GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
          GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffset+161,
                     ScreenInfo.OrigY1+ScreenInfo.YOffset+75,
                     ScreenInfo.OrigX1+ScreenInfo.XOffset+508,
                     ScreenInfo.OrigY1+ScreenInfo.YOffset+149,GrFill);
          TxSetClipRegion(ScreenInfo.OrigX1+ScreenInfo.XOffset+164,
                         ScreenInfo.OrigY1+ScreenInfo.YOffset+76,
                         ScreenInfo.OrigX1+ScreenInfo.XOffset+506,
                         ScreenInfo.OrigY1+ScreenInfo.YOffset+148);
          TxSetClipping(TxClip);
          DoText(WorkSg2);
          TxSetClipRegion(0,0,GraphMaxX,GraphMaxY);
          TxSetClipping(TxClip);
     END;

BEGIN
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(100,100,619,380,'TEXT FONT SETTINGS',EditWindow);
     {Done Button}
     SystemButton(544,340,609,370,1,False,True);
     OutTextXY(564,347,0,255,1,'Done');
     OutTextXY(260,267,1,255,1,'Text Attributes:');
     InvertedBox(260,282,355,370);
     SystemButton(330,290,0,0,4,False,True);
     SystemButton(330,310,0,0,4,False,True);
     SystemButton(330,330,0,0,4,False,True);
     SystemButton(330,350,0,0,4,False,True);
     OutTextXYFR(325,289,0,255,'Bold');
     OutTextXYFR(325,309,0,255,'Italic');
     OutTextXYFR(325,329,0,255,'Underline');
     OutTextXYFR(325,349,0,255,'Shadow');
     GrSetFillStyle(GrFCloseDot,WindowBack,GrTrans);
     GrDrawRect(261,307,328,320,GrFill);
     OutTextXY(365,267,1,255,1,'Text Colours:');
     ClearPaletteQueue;
     InvertedBox(365,282,609,330);
     AddToPaletteQueue(455,292,8,HoldRaw.Colour1,False);
     AddToPaletteQueue(455,312,8,HoldRaw.Colour2,False);
     OutTextXYFR(420,290,0,255,'Stroke');
     OutTextXYFR(420,310,0,255,'Shadow');
     OutTextXY(260,134,1,255,1,'Current Font:');
     InvertedBox(260,149,609,250);
     RaisedBox(261,150,608,174);
     {Create the picklist of available fonts}
     OutTextXY(110,134,1,255,1,'Available Fonts:');
     {Gather the files}
     NewPickList(110,150,13,12);
     AddToPickList('System Font');
     AddToPickList('8x16 Font');
     AddToPickList('8x14 Font');
     AddToPickList('8x8 Font');
     AddToPickList('Helvetica');
     AddToPickList('Roman');
     NumFiles         := 6;
     PickInfo.Current := HoldRaw.Colour7;
     Current          := HoldRaw.Colour7;
     FindFirst(FONTDir+'*.FNT',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          Temp := _UpperCase(DirInfo.Name);
          INC(NumFiles);
          AddToPickList(Temp);
          IF HoldRaw.Colour7=0 THEN
          BEGIN
               IF Temp=HoldRaw.ObjFile THEN
               BEGIN
                    PickInfo.Current := NumFiles;
                    Current          := NumFiles;
               END;
          END;
          FindNext(DirInfo);
     END;
     SetUpPickList;
     DrawTheSample;
     GrDisplayMouse(GrShow);
     UpdateAttributes;
     REPEAT
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                XX := GetMouseX;
                YY := GetMouseY;
                IF ChangedAColour(XX,YY) THEN
                BEGIN
                     CASE ChangedWhich OF
                     1:   HoldRaw.Colour1 := Palettes[ChangedWhich].Current;
                     2:   HoldRaw.Colour2 := Palettes[ChangedWhich].Current;
                     END;
                     DrawTheSample;
                END
                ELSE MoveColourPal(XX,YY);
           END;
           C := MouseHandler(False);
           CASE C OF
           0:   BEGIN
                     IF (PickInfo.Current<>Current) THEN
                     BEGIN
                          Current := PickInfo.Current;
                          IF Current<7 THEN
                          BEGIN
                               HoldRaw.Colour7 := Current;
                               HoldRaw.ObjFile := '';
                          END
                          ELSE
                          BEGIN
                               HoldRaw.ObjFile := _RemoveSpaces(PickList^[Current]);
                               HoldRaw.Colour7 := 0;
                          END;
                          GrDisplayMouse(GrHide);
                          DrawTheSample;
                          GrDisplayMouse(GrShow);
                     END;
                END;
           2:   BEGIN {BOLD}
                     IF HoldRaw.Colour6=1 THEN HoldRaw.Colour6 := 0
                                          ELSE HoldRaw.Colour6 := 1;
                     UpdateAttributes;
                     DrawTheSample;
                END;
           3:   BEGIN {ITALICS - DOESN'T WORK WITH BIT FONTS!}
                     (*
                     IF HoldRaw.Colour4=1 THEN HoldRaw.Colour4 := 0
                                          ELSE HoldRaw.Colour4 := 1;
                     UpdateAttributes;
                     DrawTheSample;
                     *)
                END;
           4:   BEGIN {UNDERLINE}
                     IF HoldRaw.Colour5=1 THEN HoldRaw.Colour5 := 0
                                          ELSE HoldRaw.Colour5 := 1;
                     UpdateAttributes;
                     DrawTheSample;
                END;
           5:   BEGIN {SHADOWED}
                     IF HoldRaw.Colour3=1 THEN HoldRaw.Colour3 := 0
                                          ELSE HoldRaw.Colour3 := 1;
                     UpdateAttributes;
                     DrawTheSample;
                END;
           END;
     UNTIL C=1;
     GrDisplayMouse(GrHide);
     KillWindow;
     ReloadWindow(1);
     KillPickList;
     GrDisplayMouse(GrShow);
END;


PROCEDURE DoChangePromptType;
VAR  C        : Word;
     AllDone  : Boolean;
BEGIN
     IF MouseOn THEN GrDisplayMouse(GrHide);
     SaveWindow(3);
     NButtons := 0;
     DrawWindow(130,110,395,370,'DATA ENTRY BOXES',FloatingMenu);
     SystemButton(320,330,385,360,1,False,True);
     OutTextXY(340,337,0,255,1,'Done');
     NewPickList(142,150,10,25);
     AddToPickList('Users Real Name');
     AddToPickList('Users Alias Name');
     AddToPickList('Users Password');
     AddToPickList('Users Birthdate');
     AddToPickList('Users Street Address');
     AddToPickList('Users City');
     AddToPickList('Users Province/State');
     AddToPickList('Users Country');
     AddToPickList('Users Postal Code');
     AddToPickList('Users Data Number');
     AddToPickList('Users Voice Number');
     AddToPickList('Deposit Bytes');
     AddToPickList('Withdraw Bytes');
     AddToPickList('Deposit Minutes');
     AddToPickList('Withdraw Minutes');
     AddToPickList('File Description Length');
     AddToPickList('General File Name');
     AddToPickList('General Date');
     AddToPickList('General Numeric');
     AddToPickList('General Proper Name');
     AddToPickList('General String 10');
     AddToPickList('General String 20');
     AddToPickList('General String 30');
     AddToPickList('General String 40');
     AddToPickList('General String 50');
     AddToPickList('General String 60');
     AddToPickList('General String 70');
     AddToPickList('Users BBS Name');
     AddToPickList('Users BBS Address');
     AddToPickList('Users BBS Phone Number');
     AddToPickList('Users Comment');
     PickInfo.Current := HoldRaw.colour4;
     SetUpPickList;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     AllDone := False;
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           1:   AllDone := True;
           END;
     UNTIL AllDone;
     HoldRaw.colour4 := PickInfo.Current;
     KillWindow;
     ReloadWindow(3);
     KillPickList;
END;


END.
