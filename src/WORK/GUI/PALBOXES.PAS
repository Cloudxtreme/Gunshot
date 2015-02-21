{$I DEFINES.INC}
UNIT PalBoxes;


INTERFACE


PROCEDURE ClearPaletteQueue;
PROCEDURE MoveColourPal(x,y: Word);
PROCEDURE RedrawColourPal(Num: Word);
PROCEDURE RedrawPaletteCurrentColour(Num: Word);
PROCEDURE AddToPaletteQueue(x,y,size,current: Word; AllowNoColour: Boolean);
FUNCTION  ChangedAColour(x,y: Word): Boolean;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,_Text,Crt;


PROCEDURE RedrawPaletteCurrentColour(Num: Word);
BEGIN
     IF Palettes[Num].Current=255 THEN
     BEGIN
          GrSetColor(0);
          GrSetFillStyle(GrFSolid,15,GrOpaque);
          GrDrawRect(Palettes[Num].SelectedX1,Palettes[Num].SelectedY1,
                     Palettes[Num].SelectedX2,Palettes[Num].SelectedY2,GrFill);
          GrDrawLine(Palettes[Num].SelectedX1,Palettes[Num].SelectedY1,
                     Palettes[Num].SelectedX2,Palettes[Num].SelectedY2);
          GrDrawLine(Palettes[Num].SelectedX1,Palettes[Num].SelectedY2,
                     Palettes[Num].SelectedX2,Palettes[Num].SelectedY1);
     END
     ELSE
     BEGIN
          GrSetColor(0);
          GrSetFillStyle(GrFSolid,Palettes[Num].Current,GrOpaque);
          GrDrawRect(Palettes[Num].SelectedX1,Palettes[Num].SelectedY1,
                     Palettes[Num].SelectedX2,Palettes[Num].SelectedY2,GrFill);
     END;
END;


PROCEDURE ClearPaletteQueue;
BEGIN
     NumPalettes := 0;
END;


PROCEDURE DrawCurrentPalette(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(7);
     GrDrawRect(x1+1,y1,x2-1,y2,GrOutline);
     GrSetColor(0);
     GrDrawRect(x1+2,y1+1,x2-2,y2-1,GrOutline);
END;


PROCEDURE AddToPaletteQueue(x,y,size,current: Word; AllowNoColour: Boolean);
VAR  LoopX : Word;
     Loop  : Word;
BEGIN
     INC(NumPalettes);
     Palettes[NumPalettes].Current       := Current;
     Palettes[NumPalettes].X1            := x;
     Palettes[NumPalettes].Y1            := y;
     Palettes[NumPalettes].X2            := x+(16*size);
     Palettes[NumPalettes].Y2            := y+size;
     Palettes[NumPalettes].Size          := Size;
     Palettes[NumPalettes].AllowNoColour := AllowNoColour;
     Palettes[NumPalettes].SelectedX1    := x-16-Size;
     Palettes[NumPalettes].SelectedY1    := y;
     Palettes[NumPalettes].SelectedX2    := x-16;
     Palettes[NumPalettes].SelectedY2    := y+size;
     Palettes[NumPalettes].DnX1          := x-13;
     Palettes[NumPalettes].DnY1          := Y-3;
     Palettes[NumPalettes].DnX2          := x-3;
     Palettes[NumPalettes].DnY2          := Y+Size+3;
     Palettes[NumPalettes].UpX1          := x+(16*size)+3;
     Palettes[NumPalettes].UpY1          := Y-3;
     Palettes[NumPalettes].UpX2          := x+(16*size)+13;
     Palettes[NumPalettes].UpY2          := Y+Size+3;
     Palettes[NumPalettes].LeftColour    := 0;
     {Palette Frame}
     InvertedBox(Palettes[NumPalettes].X1-3,
                 Palettes[NumPalettes].Y1-3,
                 Palettes[NumPalettes].X2+3,
                 Palettes[NumPalettes].Y2+3);
     {Current Colour Frame}
     InvertedBox(Palettes[NumPalettes].SelectedX1-3,
                 Palettes[NumPalettes].SelectedY1-3,
                 Palettes[NumPalettes].SelectedX2+3,
                 Palettes[NumPalettes].SelectedY2+3);
     {Down/Left Button}
     RaisedBox  (Palettes[NumPalettes].DnX1,
                 Palettes[NumPalettes].DnY1,
                 Palettes[NumPalettes].DnX2,
                 Palettes[NumPalettes].DnY2);
     {Up/Right Button}
     RaisedBox  (Palettes[NumPalettes].UpX1,
                 Palettes[NumPalettes].UpY1,
                 Palettes[NumPalettes].UpX2,
                 Palettes[NumPalettes].UpY2);
     OutTextXY(Palettes[NumPalettes].DnX1+3,Palettes[NumPalettes].DnY1+1,8,255,1,'<');
     OutTextXY(Palettes[NumPalettes].UpX1+3,Palettes[NumPalettes].UpY1+1,8,255,1,'>');
     {Draw Palette Boxes}
     GrSetColor(0);
     LoopX := Palettes[NumPalettes].X1;
     FOR Loop := 0 TO 15 DO
     BEGIN
          GrSetFillStyle(GrFSolid,Loop,GrOpaque);
          GrDrawRect(LoopX,y,LoopX+size,y+size,GrOutline+GrFill);
          IF Palettes[NumPalettes].Current=Loop THEN
          BEGIN
               DrawCurrentPalette(LoopX,y,LoopX+size,y+size);
          END;
          INC(LoopX,size);
     END;
     {Draw Current Colour Box}
     IF Palettes[NumPalettes].Current=255 THEN
     BEGIN
          GrSetColor(0);
          GrSetFillStyle(GrFSolid,15,GrOpaque);
          GrDrawRect(Palettes[NumPalettes].SelectedX1,Palettes[NumPalettes].SelectedY1,
                     Palettes[NumPalettes].SelectedX2,Palettes[NumPalettes].SelectedY2,GrFill);
          GrDrawLine(Palettes[NumPalettes].SelectedX1,Palettes[NumPalettes].SelectedY1,
                     Palettes[NumPalettes].SelectedX2,Palettes[NumPalettes].SelectedY2);
          GrDrawLine(Palettes[NumPalettes].SelectedX1,Palettes[NumPalettes].SelectedY2,
                     Palettes[NumPalettes].SelectedX2,Palettes[NumPalettes].SelectedY1);
     END
     ELSE
     BEGIN
          GrSetColor(0);
          GrSetFillStyle(GrFSolid,Current,GrOpaque);
          GrDrawRect(Palettes[NumPalettes].SelectedX1,
                     Palettes[NumPalettes].SelectedY1,
                     Palettes[NumPalettes].SelectedX2,
                     Palettes[NumPalettes].SelectedY2,GrFill);
     END;
END;


PROCEDURE RedrawColourPal(Num: Word);
VAR  LoopX : Word;
     LoopY : Word;
     Loop2 : Word;
BEGIN
     IF NumPalettes=0 THEN Exit;
     {Draw Palette Boxes}
     GrSetColor(0);
     LoopX := Palettes[Num].X1;
     LoopY := Palettes[Num].Y1;
     FOR Loop2 := Palettes[Num].LeftColour TO Palettes[Num].LeftColour+15 DO
     BEGIN
          IF Loop2=255 THEN
          BEGIN
               GrSetFillStyle(GrFSolid,15,GrOpaque);
               GrDrawRect(LoopX,LoopY,LoopX+Palettes[Num].Size,
                          LoopY+Palettes[Num].Size,GrOutline+GrFill);
               GrSetColor(0);
               GrDrawLine(LoopX,LoopY,LoopX+Palettes[Num].Size,LoopY+Palettes[Num].Size);
               GrDrawLine(LoopX,LoopY+Palettes[Num].Size,LoopX+Palettes[Num].Size,LoopY);
               INC(LoopX,Palettes[Num].Size);
          END
          ELSE
          BEGIN
               GrSetFillStyle(GrFSolid,Loop2,GrOpaque);
               GrDrawRect(LoopX,LoopY,LoopX+Palettes[Num].Size,
                          LoopY+Palettes[Num].Size,GrOutline+GrFill);
               IF Palettes[Num].Current=Loop2 THEN
               BEGIN
                    DrawCurrentPalette(LoopX,LoopY,LoopX+Palettes[Num].Size,
                                       LoopY+Palettes[Num].Size);
               END;
               INC(LoopX,Palettes[Num].Size);
          END;
     END;
END;


FUNCTION ChangedAColour(x,y: Word): Boolean;
VAR  Loop : Word;
     TW   : Word;
     Did  : Boolean;
     Temp : Word;
BEGIN
     TW  := 0;
     Did := False;
     IF NumPalettes=0 THEN
     BEGIN
          ChangedWhich   := 0;
          ChangedAColour := False;
          Exit;
     END;
     FOR Loop := 1 TO NumPalettes DO
     BEGIN
          IF ((X>Palettes[Loop].X1) AND (X<Palettes[Loop].X2) AND
             (Y>Palettes[Loop].Y1) AND (Y<Palettes[Loop].Y2)) THEN
          BEGIN
               Temp := (TRUNC((x-Palettes[Loop].X1)/Palettes[Loop].Size))+Palettes[Loop].LeftColour;
               IF Temp<>Palettes[Loop].Current THEN
               BEGIN
                    TW  := Loop;
                    Did := True;
                    GrDisplayMouse(GrHide);
                    Palettes[Loop].Current := Temp;
                    {Draw Current Colour Box}
                    IF Palettes[Loop].Current=255 THEN
                    BEGIN
                         GrSetColor(0);
                         GrSetFillStyle(GrFSolid,15,GrOpaque);
                         GrDrawRect(Palettes[Loop].SelectedX1,
                                    Palettes[Loop].SelectedY1,
                                    Palettes[Loop].SelectedX2,
                                    Palettes[Loop].SelectedY2,GrFill);
                         GrDrawLine(Palettes[Loop].SelectedX1,
                                    Palettes[Loop].SelectedY1,
                                    Palettes[Loop].SelectedX2,
                                    Palettes[Loop].SelectedY2);
                         GrDrawLine(Palettes[Loop].SelectedX1,
                                    Palettes[Loop].SelectedY2,
                                    Palettes[Loop].SelectedX2,
                                    Palettes[Loop].SelectedY1);
                    END
                    ELSE
                    BEGIN
                         GrSetColor(0);
                         GrSetFillStyle(GrFSolid,Palettes[Loop].Current,GrOpaque);
                         GrDrawRect(Palettes[Loop].SelectedX1,Palettes[Loop].SelectedY1,
                                    Palettes[Loop].SelectedX2,Palettes[Loop].SelectedY2,GrFill);
                    END;
                    RedrawColourPal(Loop);
                    GrDisplayMouse(GrShow);
               END;
          END;
     END;
     ChangedWhich   := TW;
     ChangedAColour := Did;
END;


PROCEDURE MoveColourPal(x,y: Word);
VAR  Loop  : Word;
     LoopX : Word;
     LoopY : Word;
     Loop2 : Word;
     MaxX  : Word;
BEGIN
     IF NumPalettes=0 THEN Exit;
     FOR Loop := 1 TO NumPalettes DO
     BEGIN
          IF ((X>Palettes[Loop].DnX1) AND (X<Palettes[Loop].DnX2) AND
             (Y>Palettes[Loop].DnY1) AND (Y<Palettes[Loop].DnY2)) THEN
          BEGIN
               {GO LEFT}
               IF (Palettes[Loop].LeftColour>0) THEN
               BEGIN
                    DEC(Palettes[Loop].LeftColour);
                    GrDisplayMouse(GrHide);
                    {Draw Palette Boxes}
                    GrSetColor(0);
                    LoopX := Palettes[Loop].X1;
                    LoopY := Palettes[Loop].Y1;
                    FOR Loop2 := Palettes[Loop].LeftColour TO Palettes[Loop].LeftColour+15 DO
                    BEGIN
                         GrSetFillStyle(GrFSolid,Loop2,GrOpaque);
                         GrDrawRect(LoopX,LoopY,LoopX+Palettes[Loop].Size,
                                    LoopY+Palettes[Loop].Size,GrOutline+GrFill);
                         IF Palettes[Loop].Current=Loop2 THEN
                         BEGIN
                              DrawCurrentPalette(LoopX,LoopY,LoopX+Palettes[Loop].Size,
                                                 LoopY+Palettes[Loop].Size);
                         END;
                         INC(LoopX,Palettes[Loop].Size);
                    END;
                    GrDisplayMouse(GrShow);
                    Delay(6);
                    Exit;
               END;
          END
          ELSE IF ((X>Palettes[Loop].UpX1) AND (X<Palettes[Loop].UpX2) AND
                  (Y>Palettes[Loop].UpY1) AND (Y<Palettes[Loop].UpY2)) THEN
          BEGIN
               {GO RIGHT}
               IF Palettes[Loop].AllowNoColour THEN MaxX := 255
                                               ELSE MaxX := 254;
               IF ((Palettes[Loop].LeftColour+15)<MaxX) THEN
               BEGIN
                    INC(Palettes[Loop].LeftColour);
                    GrDisplayMouse(GrHide);
                    {Draw Palette Boxes}
                    GrSetColor(0);
                    LoopX := Palettes[Loop].X1;
                    LoopY := Palettes[Loop].Y1;
                    FOR Loop2 := Palettes[Loop].LeftColour TO Palettes[Loop].LeftColour+15 DO
                    BEGIN
                         IF Loop2=255 THEN
                         BEGIN
                              GrSetFillStyle(GrFSolid,15,GrOpaque);
                              GrDrawRect(LoopX,LoopY,LoopX+Palettes[Loop].Size,
                                         LoopY+Palettes[Loop].Size,GrOutline+GrFill);
                              GrSetColor(0);
                              GrDrawLine(LoopX,LoopY,LoopX+Palettes[Loop].Size,LoopY+Palettes[Loop].Size);
                              GrDrawLine(LoopX,LoopY+Palettes[Loop].Size,LoopX+Palettes[Loop].Size,LoopY);
                              INC(LoopX,Palettes[Loop].Size);
                         END
                         ELSE
                         BEGIN
                              GrSetFillStyle(GrFSolid,Loop2,GrOpaque);
                              GrDrawRect(LoopX,LoopY,LoopX+Palettes[Loop].Size,
                                         LoopY+Palettes[Loop].Size,GrOutline+GrFill);
                              IF Palettes[Loop].Current=Loop2 THEN
                              BEGIN
                                   DrawCurrentPalette(LoopX,LoopY,LoopX+Palettes[Loop].Size,
                                                      LoopY+Palettes[Loop].Size);
                              END;
                              INC(LoopX,Palettes[Loop].Size);
                         END;
                    END;
                    GrDisplayMouse(GrShow);
                    Delay(6);
                    Exit;
               END;
          END;
     END;
END;


END.
