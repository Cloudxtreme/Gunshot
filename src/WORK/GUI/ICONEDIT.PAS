{$I DEFINES.INC}
UNIT IconEdit;


INTERFACE


PROCEDURE IconEditor;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,Gx2_BpVC,_FSelect,CutOuts,_Images,_Text,BsGraph,
     Gx2_Bp,Crt,PalBoxes,BHandler,_Icons,IconMisc,BsString,_VSave,LoadIcon,
     SaveIcon,ImgDefs,Shotgun,BsFile;


PROCEDURE NewIconBank(FileN: String; Siz: Word);
VAR   Work_Icon30_2  : _Icon30x30;
      Work_Icon16_2  : _Icon16x16;
      FWork_Icon30_2 : File Of _Icon30x30;
      FWork_Icon16_2 : File Of _Icon16x16;
      Loop           : Word;
BEGIN
     FillChar(Work_Icon30_2,SizeOf(Work_Icon30_2),255);
     FillChar(Work_Icon16_2,SizeOf(Work_Icon16_2),255);
     CASE siz OF
     16:  BEGIN
               ASSIGN(FWork_Icon16_2,ICONDir+FileN);
               REWRITE(FWork_Icon16_2);
               FOR Loop := 1 TO 100 DO WRITE(FWork_Icon16_2,Work_Icon16_2);
               CLOSE(FWork_Icon16_2);
          END;
     30:  BEGIN
               ASSIGN(FWork_Icon30_2,ICONDir+FileN);
               REWRITE(FWork_Icon30_2);
               FOR Loop := 1 TO 100 DO WRITE(FWork_Icon30_2,Work_Icon30_2);
               CLOSE(FWork_Icon30_2);
          END;
     END;
END;


PROCEDURE DrawIconWorkGrid;
VAR  LoopX,LoopY : Word;
     LocX,LocY   : Word;
     StartX      : Word;
     StartY      : Word;
BEGIN
     StartX := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
     StartY := ScreenInfo.OrigY1+ScreenInfo.YOffSet+40;
     GrSetColor(0);
     GrDrawRect(StartX,StartY,StartX+(CurrentSize*GridSize),StartY+(CurrentSize*GridSize),GrOutline);
     InvertedBox(StartX-1,StartY-1,StartX+(CurrentSize*GridSize)+1,StartY+(CurrentSize*GridSize)+1);
     LocX := StartX;
     LocY := StartY;
     FOR LoopX := 1 TO CurrentSize+1 DO
     BEGIN
          IF LoopX=(Trunc(CurrentSize/2))+1 THEN GrSetColor(9)
                                            ELSE GrSetColor(0);
          GrDrawRect(LocX,StartY,LocX,StartY+(CurrentSize*GridSize),GrOutline);
          INC(LocX,GridSize);
     END;
     FOR LoopY := 1 TO CurrentSize+1 DO
     BEGIN
          IF LoopY=(Trunc(CurrentSize/2))+1 THEN GrSetColor(9)
                                            ELSE GrSetColor(0);
          GrDrawRect(StartX,LocY,StartX+(CurrentSize*GridSize),LocY,GrOutline);
          INC(LocY,GridSize);
     END;
END;


PROCEDURE DrawWorkIcon;
VAR  LoopX : Word;
     LoopY : Word;
     LocX  : Word;
     LocY  : Word;
BEGIN
     LocX := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
     LocY := ScreenInfo.OrigY1+ScreenInfo.YOffSet+40;
     FOR LoopX := 1 TO CurrentSize DO
     BEGIN
          FOR LoopY := 1 TO CurrentSize DO
          BEGIN
               CASE CurrentSize OF
               16:  BEGIN
                         IF Work_Icon16.matrix[LoopX,LoopY]=255 THEN
                         BEGIN
                              gxVirtualDisplay(Disabled,0,0,
                                               LocX+1+((LoopX-1)*GridSize),
                                               LocY+1+((LoopY-1)*GridSize),
                                               LocX-1+(LoopX*GridSize),
                                               LocY-1+(LoopY*GridSize),0);
                              GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,7);
                         END
                         ELSE
                         BEGIN
                              GrSetFillStyle(GrFSolid,Work_Icon16.matrix[LoopX,LoopY],GrOpaque);
                              GrDrawRect(LocX+1+((LoopX-1)*GridSize),LocY+1+((LoopY-1)*GridSize),
                                         LocX-1+(LoopX*GridSize),LocY-1+(LoopY*GridSize),GrFill);
                              GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,Work_Icon16.matrix[LoopX,LoopY]);
                         END;
                    END;
               30:  BEGIN
                         IF Work_Icon30.matrix[LoopX,LoopY]=255 THEN
                         BEGIN
                              gxVirtualDisplay(Disabled,0,0,
                                               LocX+1+((LoopX-1)*GridSize),
                                               LocY+1+((LoopY-1)*GridSize),
                                               LocX-1+(LoopX*GridSize),
                                               LocY-1+(LoopY*GridSize),0);
                              GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,7);
                         END
                         ELSE
                         BEGIN
                              GrSetFillStyle(GrFSolid,Work_Icon30.matrix[LoopX,LoopY],GrOpaque);
                              GrDrawRect(LocX+1+((LoopX-1)*GridSize),LocY+1+((LoopY-1)*GridSize),
                                         LocX-1+(LoopX*GridSize),LocY-1+(LoopY*GridSize),GrFill);
                              GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,Work_Icon30.matrix[LoopX,LoopY]);
                         END;
                    END;
               END;
          END;
     END;
END;


PROCEDURE UpdateWorkIcon(LoopX,LoopY: Word);
VAR  LocX  : Word;
     LocY  : Word;
BEGIN
     GrDisplayMouse(GrHide);
     LocX := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
     LocY := ScreenInfo.OrigY1+ScreenInfo.YOffSet+40;
     CASE CurrentSize OF
     16:  BEGIN
               IF Work_Icon16.matrix[LoopX,LoopY]=255 THEN
               BEGIN
                    gxVirtualDisplay(Disabled,0,0,
                                     LocX+1+((LoopX-1)*GridSize),
                                     LocY+1+((LoopY-1)*GridSize),
                                     LocX-1+(LoopX*GridSize),
                                     LocY-1+(LoopY*GridSize),0);
                    GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,7);
               END
               ELSE
               BEGIN
                    GrSetFillStyle(GrFSolid,Work_Icon16.matrix[LoopX,LoopY],GrOpaque);
                    GrDrawRect(LocX+1+((LoopX-1)*GridSize),LocY+1+((LoopY-1)*GridSize),
                               LocX-1+(LoopX*GridSize),LocY-1+(LoopY*GridSize),GrFill);
                    GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,Work_Icon16.matrix[LoopX,LoopY]);
               END;
          END;
     30:  BEGIN
               IF Work_Icon30.matrix[LoopX,LoopY]=255 THEN
               BEGIN
                    gxVirtualDisplay(Disabled,0,0,
                                     LocX+1+((LoopX-1)*GridSize),
                                     LocY+1+((LoopY-1)*GridSize),
                                     LocX-1+(LoopX*GridSize),
                                     LocY-1+(LoopY*GridSize),0);
                    GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,7);
               END
               ELSE
               BEGIN
                    GrSetFillStyle(GrFSolid,Work_Icon30.matrix[LoopX,LoopY],GrOpaque);
                    GrDrawRect(LocX+1+((LoopX-1)*GridSize),LocY+1+((LoopY-1)*GridSize),
                               LocX-1+(LoopX*GridSize),LocY-1+(LoopY*GridSize),GrFill);
                    GrPutPixel(SmallX+9+LoopX,SmallY+9+LoopY,Work_Icon30.matrix[LoopX,LoopY]);
               END;
          END;
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE ClearWorkIcon;
VAR  Loop1 : Word;
     Loop2 : Word;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         work_icon16.matrix[loop2,loop1] := 255;
                    END;
               END;
          END;
     30:  BEGIN
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         work_icon30.matrix[loop2,loop1] := 255;
                    END;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE FlipLeftRight;
VAR  loop1      : word;
     loop2      : word;
     temp_icon  : _ICON30x30;
     temp_icon2 : _ICON16x16;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               temp_icon2 := work_icon16;
               FOR loop1 := 1 TO 16 DO  {MOVE X}
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         work_icon16.matrix[loop1,loop2] := temp_icon2.matrix[17-loop1,loop2];
                    END;
               END;
          END;
     30:  BEGIN
               temp_icon := work_icon30;
               FOR loop1 := 1 TO 30 DO  {MOVE X}
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         work_icon30.matrix[loop1,loop2] := temp_icon.matrix[31-loop1,loop2];
                    END;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE FlipUpDown;
VAR  loop1      : word;
     loop2      : word;
     temp_icon  : _ICON30x30;
     temp_icon2 : _ICON16x16;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               temp_icon2 := work_icon16;
               FOR loop1 := 1 TO 16 DO  {MOVE X}
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         work_icon16.matrix[loop2,loop1] := temp_icon2.matrix[loop2,17-loop1];
                    END;
               END;
          END;
     30:  BEGIN
               temp_icon := work_icon30;
               FOR loop1 := 1 TO 30 DO  {MOVE X}
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         work_icon30.matrix[loop2,loop1] := temp_icon.matrix[loop2,31-loop1];
                    END;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Rotate;
VAR  loop1      : word;
     loop2      : word;
     temp_icon  : _ICON30x30;
     temp_icon2 : _ICON16x16;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               temp_icon2 := work_icon16;
               FOR loop1 := 1 TO 16 DO  {MOVE Y}
               BEGIN
                    FOR loop2 := 1 TO 16 DO {MOVE X}
                    BEGIN
                         work_icon16.matrix[loop1,loop2] := temp_icon2.matrix[loop2,17-loop1];
                    END;
               END;
          END;
     30:  BEGIN
               temp_icon := work_icon30;
               FOR loop1 := 1 TO 30 DO  {MOVE Y}
               BEGIN
                    FOR loop2 := 1 TO 30 DO {MOVE X}
                    BEGIN
                         work_icon30.matrix[loop1,loop2] := temp_icon.matrix[loop2,31-loop1];
                    END;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE DrawCurrentColour;
BEGIN
     GrSetFillStyle(GrFSolid,CurrentDraw,GrOpaque);
     GrDrawRect(CurrentDrawX+5,CurrentDrawY+5,
                CurrentDrawX+44,CurrentDrawY+44,GrFill);
END;


PROCEDURE Exchange(x,y,button_stat: word);
VAR  loop1      : word;
     loop2      : word;
     colour_at  : byte;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               colour_at := work_icon16.matrix[x,y];
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         CASE button_stat OF
                         1: BEGIN
                                 IF work_icon16.matrix[loop1,loop2]=colour_at THEN
                                    work_icon16.matrix[loop1,loop2] := CurrentDraw;
                            END;
                         2: BEGIN
                                 IF work_icon16.matrix[loop1,loop2]=colour_at THEN
                                    work_icon16.matrix[loop1,loop2] := 255;
                            END;
                         END;
                    END;
               END;
          END;
     30:  BEGIN
               colour_at := work_icon30.matrix[x,y];
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         CASE button_stat OF
                         1: BEGIN
                                 IF work_icon30.matrix[loop1,loop2]=colour_at THEN
                                    work_icon30.matrix[loop1,loop2] := CurrentDraw;
                            END;
                         2: BEGIN
                                 IF work_icon30.matrix[loop1,loop2]=colour_at THEN
                                    work_icon30.matrix[loop1,loop2] := 255;
                            END;
                         END;
                    END;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE move_left;
VAR  loop1      : word;
     loop2      : word;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 15 DO
                    BEGIN
                         Work_Icon16.matrix[loop2,loop1] := Work_Icon16.matrix[loop2+1,loop1];
                    END;
                    Work_Icon16.matrix[16,loop1] := 255;
               END;
          END;
     30:  BEGIN
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 29 DO
                    BEGIN
                         Work_Icon30.matrix[loop2,loop1] := Work_Icon30.matrix[loop2+1,loop1];
                    END;
                    Work_Icon30.matrix[30,loop1] := 255;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE move_right;
VAR  loop1      : word;
     loop2      : word;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 16 DOWNTO 2 DO
                    BEGIN
                         Work_Icon16.matrix[loop2,loop1] := Work_Icon16.matrix[loop2-1,loop1];
                    END;
                    Work_Icon16.matrix[1,loop1] := 255;
               END;
          END;
     30:  BEGIN
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 30 DOWNTO 2 DO
                    BEGIN
                         Work_Icon30.matrix[loop2,loop1] := Work_Icon30.matrix[loop2-1,loop1];
                    END;
                    Work_Icon30.matrix[1,loop1] := 255;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE move_up;
VAR  loop1      : word;
     loop2      : word;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 15 DO
                    BEGIN
                         Work_Icon16.matrix[loop1,loop2] := Work_Icon16.matrix[loop1,loop2+1];
                    END;
                    Work_Icon16.matrix[loop1,16] := 255;
               END;
          END;
     30:  BEGIN
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 29 DO
                    BEGIN
                         Work_Icon30.matrix[loop1,loop2] := Work_Icon30.matrix[loop1,loop2+1];
                    END;
                    Work_Icon30.matrix[loop1,30] := 255;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE move_down;
VAR  loop1      : word;
     loop2      : word;
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 16 DOWNTO 2 DO
                    BEGIN
                         Work_Icon16.matrix[loop1,loop2] := Work_Icon16.matrix[loop1,loop2-1];
                    END;
                    Work_Icon16.matrix[loop1,1] := 255;
               END;
          END;
     30:  BEGIN
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 30 DOWNTO 2 DO
                    BEGIN
                         Work_Icon30.matrix[loop1,loop2] := Work_Icon30.matrix[loop1,loop2-1];
                    END;
                    Work_Icon30.matrix[loop1,1] := 255;
               END;
          END;
     END;
     GrDisplayMouse(GrHide);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE FillIcon(xx,yy: word);
VAR  loop1          : word;
     loop2          : word;
     fill_colour    : byte;
     replace_colour : byte;
     masking_tape   : integer;
     found_colour   : boolean;
BEGIN
     GrDisplayMouse(GrHide);
     fill_colour    := CurrentDraw;
     masking_tape := -1;
     found_colour := false;
     CASE CurrentSize OF
     16:  BEGIN
               Replace_Colour := work_icon16.matrix[xx,yy];
               REPEAT
                     INC(masking_tape);
                     IF ((masking_tape<>fill_colour) AND (masking_tape<>replace_colour)) THEN found_colour := True;
               UNTIL ((found_colour) AND (masking_tape<>7));
               GrSetFillStyle(GrFSolid,masking_tape,GrOpaque);
               GrDrawRect(SmallX+9,SmallY+9,SmallX+40,SmallY+40,GrFill);
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         IF work_icon16.matrix[loop1,loop2]=replace_colour THEN
                         BEGIN
                              GrPutPixel(SmallX+9+Loop1,SmallY+9+Loop2,replace_colour);
                         END;
                    END;
               END;
               GrSetFillStyle(GrFSolid,Fill_Colour,GrOpaque);
               GrFloodFill(SmallX+9+xx,SmallY+9+yy,masking_tape);
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         IF work_icon16.matrix[loop1,loop2]<>replace_colour THEN
                         BEGIN
                              GrPutPixel(SmallX+9+Loop1,SmallY+9+Loop2,work_icon16.matrix[loop1,loop2]);
                         END;
                    END;
               END;
               FOR loop1 := 1 TO 16 DO
               BEGIN
                    FOR loop2 := 1 TO 16 DO
                    BEGIN
                         IF work_icon16.matrix[loop1,loop2]=replace_colour THEN
                         BEGIN
                              work_icon16.matrix[loop1,loop2] := GrGetPixel(SmallX+9+loop1,SmallY+9+loop2);
                         END;
                    END;
               END;
          END;
     30:  BEGIN
               Replace_Colour := work_icon30.matrix[xx,yy];
               REPEAT
                     INC(masking_tape);
                     IF ((masking_tape<>fill_colour) AND (masking_tape<>replace_colour)) THEN found_colour := True;
               UNTIL ((found_colour) AND (masking_tape<>7));
               GrSetFillStyle(GrFSolid,masking_tape,GrOpaque);
               GrDrawRect(SmallX+9,SmallY+9,SmallX+40,SmallY+40,GrFill);
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         IF work_icon30.matrix[loop1,loop2]=replace_colour THEN
                         BEGIN
                              GrPutPixel(SmallX+9+Loop1,SmallY+9+Loop2,replace_colour);
                         END;
                    END;
               END;
               GrSetFillStyle(GrFSolid,Fill_Colour,GrOpaque);
               GrFloodFill(SmallX+9+xx,SmallY+9+yy,masking_tape);
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         IF work_icon30.matrix[loop1,loop2]<>replace_colour THEN
                         BEGIN
                              GrPutPixel(SmallX+9+Loop1,SmallY+9+Loop2,work_icon30.matrix[loop1,loop2]);
                         END;
                    END;
               END;
               FOR loop1 := 1 TO 30 DO
               BEGIN
                    FOR loop2 := 1 TO 30 DO
                    BEGIN
                         IF work_icon30.matrix[loop1,loop2]=replace_colour THEN
                         BEGIN
                              work_icon30.matrix[loop1,loop2] := GrGetPixel(SmallX+9+loop1,SmallY+9+loop2);
                         END;
                    END;
               END;
          END;
     END;
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(SmallX+9,SmallY+9,SmallX+40,SmallY+40,GrFill);
     DrawWorkIcon;
     GrDisplayMouse(GrShow);
END;


PROCEDURE DoIconGrabber;
VAR  What        : Word;
     Temp        : String;
     GotIt       : Byte;
     Bootit      : Boolean;
     Work        : Word;
     Width       : Word;
     Height      : Word;
     OldMouse    : Boolean;
     x1,y1,x2,y2 : Word;
     Loop1       : Word;
     Loop2       : Word;
     GGrid       : Byte;
     C           : Char;
BEGIN
     Temp := '';
     What := FileSelector(JPEGDir,'*.*','',Temp,True,False,True);
     CASE What OF
     1:   BEGIN
               GrDisplayMouse(GrHide);
               Save_Screen;
               FillChar(HoldRaw,SizeOf(HoldRaw),0);
               MouseOn := True;
               GrDisplayMouse(GrShow);
               HoldRaw.Colour2 := 4;
               GetChangeImage;
               MouseOn := False;
               GrDisplayMouse(GrHide);
               GrSetFillStyle(GrFSolid,0,GrOpaque);
               GrDrawRect(0,0,639,479,GrFill);
               LoadGraphicFile(JPEGDir+Temp,0,0,639,479,HoldRaw.Colour2,
                               HoldRaw.Colour1,HoldRaw.Colour3,True);
               OutTextXY(0,465,15,0,1,'  Click the left mouse button to grab an icon. Right mouse button to abort.');
               x1     := 100;
               y1     := 100;
               x2     := 100+CurrentSize-1;
               y2     := 100+CurrentSize-1;
               GGrid  := 10;
               GrSetMousePos(x1,y1);
               Width  := x2-x1+1;
               Height := y2-y1+1;
               GrSetColor(XORLine);
               GrSetOp(GxXOR);
               GrDrawRect(x1,y1,x2,y2,GrOutline);
               GotIt := 0;
               REPEAT
                     {Drag a frame around}
                     IF ((GetMouseXG(GGrid)<>X1) OR (GetMouseYG(GGrid)<>Y1)) THEN
                     BEGIN
                          GrDrawRect(x1,y1,x2,y2,GrOutline);
                          x1 := GetMouseXG(GGrid);
                          y1 := GetMouseYG(GGrid);
                          x2 := x1+Width-1;
                          y2 := y1+Height-1;
                          GrDrawRect(x1,y1,x2,y2,GrOutline);
                     END;
                     IF GrGetMouseButtons=GrLButton THEN GotIt := 1;
                     IF GrGetMouseButtons=GrRButton THEN GotIt := 2;
                     IF KeyPressed THEN
                     BEGIN
                          C := ReadKey;
                          IF Ord(C)=0 THEN
                          BEGIN
                               C := ReadKey;
                               CASE Ord(C) OF
                               72:  GrSetMousePos(GetMouseXG(GGrid),GetMouseYG(GGrid)-GGrid);
                               80:  GrSetMousePos(GetMouseXG(GGrid),GetMouseYG(GGrid)+GGrid);
                               75:  GrSetMousePos(GetMouseXG(GGrid)-GGrid,GetMouseYG(GGrid));
                               77:  GrSetMousePos(GetMouseXG(GGrid)+GGrid,GetMouseYG(GGrid));
                               END;
                          END
                          ELSE
                          BEGIN
                               CASE C OF
                               '1': GGrid := 1;
                               '2': GGrid := 2;
                               '3': GGrid := 3;
                               '4': GGrid := 4;
                               '5': GGrid := 5;
                               '6': GGrid := 6;
                               '7': GGrid := 7;
                               '8': GGrid := 8;
                               '9': GGrid := 9;
                               '0': GGrid := 10;
                               END;
                          END;
                     END;
               UNTIL (GotIt<>0);
               GrDrawRect(x1,y1,x2,y2,GrOutline);
               GrSetOp(GxSet);
               IF GotIt=1 THEN
               BEGIN
                    {Grab the icon!}
                    CASE CurrentSize OF
                    16:  BEGIN
                              FOR loop1 := 1 TO 16 DO
                              BEGIN
                                   FOR loop2 := 1 TO 16 DO
                                   BEGIN
                                        work_icon16.matrix[loop1,loop2] :=
                                          GrGetPixel(x1+loop1-1,y1+loop2-1);
                                   END;
                              END;
                         END;
                    30:  BEGIN
                              FOR loop1 := 1 TO 30 DO
                              BEGIN
                                   FOR loop2 := 1 TO 30 DO
                                   BEGIN
                                        work_icon30.matrix[loop1,loop2] :=
                                          GrGetPixel(x1+loop1-1,y1+loop2-1);
                                   END;
                              END;
                         END;
                    END;
               END;
               Load_Screen;
               IF GotIt=1 THEN DrawWorkIcon;
               GrDisplayMouse(GrShow);
          END;
     END;
END;


PROCEDURE ScrollToColour(DeX,DeY: Word);
VAR  TheColour : Word;
     Loop      : Word;
     AllDone   : Boolean;
BEGIN
     CASE CurrentSize OF
     16:  TheColour := Work_Icon16.Matrix[DeX,DeY];
     30:  TheColour := Work_Icon30.Matrix[DeX,DeY];
     END;
     Palettes[1].Current := TheColour;
     CurrentDraw         := TheColour;
     AllDone := False;
     Loop    := 0;
     REPEAT
           Palettes[1].LeftColour := Loop;
           IF ((TheColour>=Loop) AND (TheColour<=Loop+15)) THEN AllDone := True;
           INC(Loop);
     UNTIL AllDone;
     RedrawPaletteCurrentColour(1);
     DrawCurrentColour;
     RedrawColourPal(1);
END;


PROCEDURE IconEditor;
VAR  DoJob  : Word;
     Action : Word;
     WinX1  : Word;
     WinY1  : Word;
     WinX2  : Word;
     WinY2  : Word;
     DoX    : Word;
     DoY    : Word;
     Work   : Word;
     TFill  : Word;
     What   : Word;
     Temp   : String;

     PROCEDURE ResizeIconGrid(NewSize: Word);
     VAR  LoopX : Word;
          LoopY : Word;
     BEGIN
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          LoopX := ScreenInfo.OrigX1+277+ScreenInfo.XOffset;
          LoopY := ScreenInfo.OrigY1+130+ScreenInfo.YOffset;
          GrDrawRect(LoopX+1,LoopY+1,LoopX+48,LoopY+48,GrFill);
          LoopX := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
          LoopY := ScreenInfo.OrigY1+ScreenInfo.YOffSet+40;
          GrDrawRect(LoopX-1,LoopY-1,LoopX+(30*GridSize)+1,LoopY+(30*GridSize)+1,GrFill);
          CASE NewSize OF
          16:  BEGIN
                    CurrentSize := 16;
                    ClearWorkIcon;
                    FOR LoopY := 1 TO 16 DO
                    BEGIN
                         FOR LoopX := 1 TO 16 DO
                         BEGIN
                              Work_Icon16.Matrix[LoopX,LoopY] :=
                                Work_Icon30.Matrix[LoopX,LoopY];
                         END;
                    END;
               END;
          30:  BEGIN
                    CurrentSize := 30;
                    ClearWorkIcon;
                    FOR LoopY := 1 TO 16 DO
                    BEGIN
                         FOR LoopX := 1 TO 16 DO
                         BEGIN
                              Work_Icon30.Matrix[LoopX,LoopY] :=
                                Work_Icon16.Matrix[LoopX,LoopY];
                         END;
                    END;
               END;
          END;
          DrawIconWorkGrid;
          DrawWorkIcon;
     END;

BEGIN
     CurrentIcon := 1;
     CurrentIFile := 'ICONLIB1.30';
     CurrentDraw := 0;
     CurrentSize := 30;
     DExchange   := False;
     DFill       := False;
     DSucker     := False;
     NButtons    := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(50,100,540,400,'ICON EDITOR - '+CurrentIFile,IconEditWindow);
     OutTextXY(ScreenInfo.OrigX1+330,ScreenInfo.OrigY1+50,0,255,1,'Colour Palette');
     ClearPaletteQueue;
     AddToPaletteQueue(ScreenInfo.OrigX1+300+ScreenInfo.XOffset,
                       ScreenInfo.OrigY1+75+ScreenInfo.YOffset,
                       10,CurrentDraw,False);
     DoY := 313;
     DoX := 320;
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,4);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,2);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,3);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,5);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,6);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,19); INC(DoX,34);
     DoX := 320;
     INC(DoY,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,7);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,18); INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,20); INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,8);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,33); INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,9);  INC(DoX,34);

     {MOVE ICON}
     SystemButton(ScreenInfo.OrigX1+425+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+120+ScreenInfo.YOffset,
                 ScreenInfo.OrigX1+445+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+140+ScreenInfo.YOffset,1,False,True);
     SystemIcon  (ScreenInfo.OrigX1+430+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+125+ScreenInfo.YOffset,28);
     SystemButton(ScreenInfo.OrigX1+425+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+160+ScreenInfo.YOffset,
                 ScreenInfo.OrigX1+445+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+180+ScreenInfo.YOffset,1,False,True);
     SystemIcon  (ScreenInfo.OrigX1+430+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+165+ScreenInfo.YOffset,29);
     SystemButton(ScreenInfo.OrigX1+405+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+140+ScreenInfo.YOffset,
                 ScreenInfo.OrigX1+425+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+160+ScreenInfo.YOffset,1,False,True);
     SystemIcon  (ScreenInfo.OrigX1+410+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+145+ScreenInfo.YOffset,26);
     SystemButton(ScreenInfo.OrigX1+445+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+140+ScreenInfo.YOffset,
                 ScreenInfo.OrigX1+465+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+160+ScreenInfo.YOffset,1,False,True);
     SystemIcon  (ScreenInfo.OrigX1+450+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+145+ScreenInfo.YOffset,27);
     OutTextXY   (ScreenInfo.OrigX1+423+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+186+ScreenInfo.YOffset,
                 0,255,1,'MOVE');
     OutTextXY   (ScreenInfo.OrigX1+422+ScreenInfo.XOffset,
                 ScreenInfo.OrigY1+185+ScreenInfo.YOffset,
                 15,255,1,'MOVE');
     {CURRENT DRAW COLOUR}
     CurrentDrawX := ScreenInfo.OrigX1+337+ScreenInfo.XOffset;
     CurrentDrawY := ScreenInfo.OrigY1+130+ScreenInfo.YOffset;
     InvertedBox(CurrentDrawX,CurrentDrawY,CurrentDrawX+50,CurrentDrawY+50);
     OutTextXY(CurrentDrawX+7,CurrentDrawY+56,0,255,1,'COLOUR');
     OutTextXY(CurrentDrawX+6,CurrentDrawY+55,15,255,1,'COLOUR');
     {ACTUAL SIZE BOX}
     SmallX := ScreenInfo.OrigX1+277+ScreenInfo.XOffset;
     SmallY := ScreenInfo.OrigY1+130+ScreenInfo.YOffset;
     InvertedBox(SmallX,SmallY,SmallX+50,SmallY+50);
     OutTextXY(SmallX+9,SmallY+56,0,255,1,'ACTUAL');
     OutTextXY(SmallX+8,SmallY+55,15,255,1,'ACTUAL');

     DrawIconWorkGrid;
     LoadInIcon(CurrentIcon);
     DrawWorkIcon;
     DrawCurrentColour;
     GrDisplayMouse(GrShow);
     GetFreeMem;
     REPEAT
           CurrentDrawX := ScreenInfo.OrigX1+337+ScreenInfo.XOffset;
           CurrentDrawY := ScreenInfo.OrigY1+130+ScreenInfo.YOffset;
           SmallX       := ScreenInfo.OrigX1+277+ScreenInfo.XOffset;
           SmallY       := ScreenInfo.OrigY1+130+ScreenInfo.YOffset;
           WinX1        := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
           WinY1        := ScreenInfo.OrigY1+ScreenInfo.YOffSet+40;
           WinX2        := (ScreenInfo.OrigX1+ScreenInfo.XOffset+20)+(CurrentSize*GridSize);
           WinY2        := (ScreenInfo.OrigY1+ScreenInfo.YOffSet+40)+(CurrentSize*GridSize);
           DoJob        := MouseHandler(False);
           CASE DoJob OF
           1:   BEGIN {CHANGE FILE BANK}
                     WindowHeader('ICON EDITOR - '+CurrentIFile,False);
                     Temp := CurrentIFile;
                     What := FileSelector(ICONDir,'*.30','*.16',Temp,True,True,False);
                     CASE What OF
                     1:   BEGIN {LOAD}
                               Work := WhatSize(ICONDir+Temp);
                               IF Work<>CurrentSize THEN
                               BEGIN
                                    IF CurrentSize=30 THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         ResizeIconGrid(16);
                                         CurrentIFile := Temp;
                                         GrDisplayMouse(GrShow);
                                    END
                                    ELSE
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         ResizeIconGrid(30);
                                         CurrentIFile := Temp;
                                         GrDisplayMouse(GrShow);
                                    END;
                               END
                               ELSE CurrentIFile := Temp;
                          END;
                     2:   BEGIN {NEW!}
                               IF _FileExists(ICONDir+Temp) THEN
                               BEGIN
                                    IF VerifySave('The file you specified already exists!',
                                                  'Are you sure you want to overwrite it?','') THEN
                                    BEGIN
                                         CASE CurrentSize OF
                                         16:  NewIconBank(Temp,16);
                                         30:  NewIconBank(Temp,30);
                                         END;
                                         CurrentIFile := Temp;
                                    END;
                               END
                               ELSE
                               BEGIN
                                    CASE CurrentSize OF
                                    16:  NewIconBank(Temp,16);
                                    30:  NewIconBank(Temp,30);
                                    END;
                                    CurrentIFile := Temp;
                               END;
                          END;
                     END;
                     WindowHeader('ICON EDITOR - '+CurrentIFile,True);
                END;
           2:   BEGIN {LOAD}
                     WindowHeader('ICON EDITOR - '+CurrentIFile,False);
                     SaveWindow(1);
                     Action := LoadFromBank(CurrentIFile);
                     ReloadWindow(1);
                     WindowHeader('ICON EDITOR - '+CurrentIFile,True);
                     IF Action<>0 THEN
                     BEGIN
                          CurrentIcon := Action;
                          LoadInIcon(CurrentIcon);
                          GrDisplayMouse(GrHide);
                          DrawWorkIcon;
                          GrDisplayMouse(GrShow);
                     END;
                END;
           3:   BEGIN {SAVE}
                     WindowHeader('ICON EDITOR - '+CurrentIFile,False);
                     SaveWindow(1);
                     SaveToBank(CurrentIFile);
                     ReloadWindow(1);
                     WindowHeader('ICON EDITOR - '+CurrentIFile,True);
                END;
           4:   FlipLeftRight;
           5:   FlipUpDown;
           6:   BEGIN {SUCKER}
                     IF NOT(DSucker) THEN
                     BEGIN
                          DSucker   := True;
                          DExchange := False;
                          DFill     := False;
                     END
                     ELSE
                     BEGIN
                          DSucker   := False;
                          DExchange := False;
                          DFill     := False;
                     END;
                END;
           7:   Rotate;
           8:   BEGIN {COLOUR EXCHANGE}
                     IF NOT(DExchange) THEN
                     BEGIN
                          DExchange := True;
                          DFill     := False;
                          DSucker   := False;
                     END
                     ELSE
                     BEGIN
                          DExchange := False;
                          DFill     := False;
                          DSucker   := False;
                     END;
                END;
           9:   BEGIN {FILL}
                     IF NOT(DFill) THEN
                     BEGIN
                          DFill     := True;
                          DExchange := False;
                          DSucker   := False;
                     END
                     ELSE
                     BEGIN
                          DFill     := False;
                          DExchange := False;
                          DSucker   := False;
                     END;
                END;
           10:  ClearWorkIcon;
           11:  BEGIN {ICON GRABBER}
                     WindowHeader('ICON EDITOR - '+CurrentIFile,False);
                     IF VerifySave('The icon grabber will erase the current',
                                   'icon in memory. Do you want to proceed?','')
                        THEN DoIconGrabber;
                     WindowHeader('ICON EDITOR - '+CurrentIFile,True);
                END;
           13:  Move_Up;
           14:  Move_Down;
           15:  Move_Left;
           16:  Move_Right;
           END;
           CASE DoJob OF
           1..5  : BEGIN
                        DExchange := False;
                        DFill     := False;
                        DSucker   := False;
                   END;
           7     : BEGIN
                        DExchange := False;
                        DFill     := False;
                        DSucker   := False;
                   END;
           11..15: BEGIN
                        DExchange := False;
                        DFill     := False;
                        DSucker   := False;
                   END;
           END;
           CASE DoJob OF
           1..16 : BEGIN
                        GrDisplayMouse(GrHide);
                        IF DFill THEN
                        BEGIN
                             InvertedBox(Buttons[9].x1+2,Buttons[9].y1+2,
                                         Buttons[9].x2-2,Buttons[9].y2-2);
                        END
                        ELSE
                        BEGIN
                             GrSetColor(WindowBack);
                             GrDrawRect(Buttons[9].x1+2,Buttons[9].y1+2,
                                        Buttons[9].x2-2,Buttons[9].y2-2,GrOutline);
                        END;
                        IF DExchange THEN
                        BEGIN
                             InvertedBox(Buttons[8].x1+2,Buttons[8].y1+2,
                                         Buttons[8].x2-2,Buttons[8].y2-2);
                        END
                        ELSE
                        BEGIN
                             GrSetColor(WindowBack);
                             GrDrawRect(Buttons[8].x1+2,Buttons[8].y1+2,
                                        Buttons[8].x2-2,Buttons[8].y2-2,GrOutline);
                        END;
                        IF DSucker THEN
                        BEGIN
                             InvertedBox(Buttons[6].x1+2,Buttons[6].y1+2,
                                         Buttons[6].x2-2,Buttons[6].y2-2);
                        END
                        ELSE
                        BEGIN
                             GrSetColor(WindowBack);
                             GrDrawRect(Buttons[6].x1+2,Buttons[6].y1+2,
                                        Buttons[6].x2-2,Buttons[6].y2-2,GrOutline);
                        END;
                        GrDisplayMouse(GrShow);
                   END;
           END;
           IF DoJob=0 THEN
           BEGIN
                IF GrGetMouseButtons=GrLButton THEN
                BEGIN
                     IF ChangedAColour(GetMouseX,GetMouseY) THEN
                     BEGIN
                          CurrentDraw := Palettes[ChangedWhich].Current;
                          GrDisplayMouse(GrHide);
                          DrawCurrentColour;
                          GrDisplayMouse(GrShow);
                     END
                     ELSE MoveColourPal(GetMouseX,GetMouseY);
                END;
                IF ((GetMouseX>WinX1) AND (GetMouseX<WinX2) AND
                   (GetMouseY>WinY1) AND (GetMouseY<WinY2)) THEN
                BEGIN
                     IF GrGetMouseButtons=GrLButton THEN
                     BEGIN
                          DoX := (TRUNC((GetMouseX-WinX1)/GridSize))+1;
                          DoY := (TRUNC((GetMouseY-WinY1)/GridSize))+1;
                          IF ((DoX>0) AND (DoX<CurrentSize+1) AND (DoY>0) AND (DoY<CurrentSize+1)) THEN
                          BEGIN
                               IF DExchange THEN
                               BEGIN
                                    Exchange(DoX,DoY,1);
                                    DExchange := False;
                                    GrDisplayMouse(GrHide);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[8].x1+2,Buttons[8].y1+2,
                                               Buttons[8].x2-2,Buttons[8].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE IF DSucker THEN
                               BEGIN
                                    DSucker := False;
                                    GrDisplayMouse(GrHide);
                                    ScrollToColour(DoX,DoY);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[6].x1+2,Buttons[6].y1+2,
                                               Buttons[6].x2-2,Buttons[6].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE IF DFill THEN
                               BEGIN
                                    FillIcon(DoX,DoY);
                                    DFill := False;
                                    GrDisplayMouse(GrHide);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[9].x1+2,Buttons[9].y1+2,
                                               Buttons[9].x2-2,Buttons[9].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE
                               BEGIN
                                    CASE CurrentSize OF
                                    16:  BEGIN
                                              IF (Work_Icon16.Matrix[DoX,DoY]<>CurrentDraw) THEN
                                              BEGIN
                                                   Work_Icon16.Matrix[DoX,DoY] := CurrentDraw;
                                                   UpdateWorkIcon(DoX,DoY);
                                              END;
                                         END;
                                    30:  BEGIN
                                              IF (Work_Icon30.Matrix[DoX,DoY]<>CurrentDraw) THEN
                                              BEGIN
                                                   Work_Icon30.Matrix[DoX,DoY] := CurrentDraw;
                                                   UpdateWorkIcon(DoX,DoY);
                                              END;
                                         END;
                                    END;
                               END;
                          END;
                     END
                     ELSE IF GrGetMouseButtons=GrRButton THEN
                     BEGIN
                          DoX := (TRUNC((GetMouseX-WinX1)/GridSize))+1;
                          DoY := (TRUNC((GetMouseY-WinY1)/GridSize))+1;
                          IF ((DoX>0) AND (DoX<CurrentSize+1) AND (DoY>0) AND (DoY<CurrentSize+1)) THEN
                          BEGIN
                               IF DExchange THEN
                               BEGIN
                                    Exchange(DoX,DoY,2);
                                    DExchange := False;
                                    GrDisplayMouse(GrHide);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[8].x1+2,Buttons[8].y1+2,
                                               Buttons[8].x2-2,Buttons[8].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE IF DSucker THEN
                               BEGIN
                                    DSucker := False;
                                    GrDisplayMouse(GrHide);
                                    ScrollToColour(DoX,DoY);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[6].x1+2,Buttons[6].y1+2,
                                               Buttons[6].x2-2,Buttons[6].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE IF DFill THEN
                               BEGIN
                                    TFill := CurrentDraw;
                                    CurrentDraw := 255;
                                    FillIcon(DoX,DoY);
                                    CurrentDraw := TFill;
                                    DFill := False;
                                    GrDisplayMouse(GrHide);
                                    GrSetColor(WindowBack);
                                    GrDrawRect(Buttons[9].x1+2,Buttons[9].y1+2,
                                               Buttons[9].x2-2,Buttons[9].y2-2,
                                               GrOutline);
                                    GrDisplayMouse(GrShow);
                               END
                               ELSE
                               BEGIN
                                    CASE CurrentSize OF
                                    16:  BEGIN
                                              IF (Work_Icon16.Matrix[DoX,DoY]<>255) THEN
                                              BEGIN
                                                   Work_Icon16.Matrix[DoX,DoY] := 255;
                                                   UpdateWorkIcon(DoX,DoY);
                                              END;
                                         END;
                                    30:  BEGIN
                                              IF (Work_Icon30.Matrix[DoX,DoY]<>255) THEN
                                              BEGIN
                                                   Work_Icon30.Matrix[DoX,DoY] := 255;
                                                   UpdateWorkIcon(DoX,DoY);
                                              END;
                                         END;
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
     UNTIL DoJob=12;
     KillWindow;
END;


END.
