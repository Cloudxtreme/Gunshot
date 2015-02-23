{$I DEFINES.INC}
UNIT _Win;


INTERFACE


USES Globals,Gunshot;


PROCEDURE DrawWindow     (x1,y1,x2,y2: word; title: String; Number: Word);
PROCEDURE WindowHeader   (title: String; Enabled: Boolean);
PROCEDURE GrowWindow     (xx1,yy1,xx2,yy2: Word);
PROCEDURE ShrinkWindow   (xx1,yy1,xx2,yy2: Word);
PROCEDURE InvertedBox    (x1,y1,x2,y2: Word);
PROCEDURE RaisedBox      (x1,y1,x2,y2: Word);
PROCEDURE DrawTheWindow  (Raw: _Raw_File);
PROCEDURE SaveWindow     (Num: Byte);
PROCEDURE ReloadWindow   (Num: Byte);
PROCEDURE GetFreeMem;
PROCEDURE KillWindow;


IMPLEMENTATION


USES Gx2_Bp,Gr2_Bp,_Text,_Icons,_Virtual,BsString,Dos,BsGraph;


PROCEDURE DrawTheWindow(Raw: _Raw_File);
VAR  x1,y1,x2,y2: Word;
BEGIN
     x1 := Raw.x1; y1 := Raw.y1;
     x2 := Raw.x2; y2 := Raw.y2;
     CASE Raw.Style OF
     1:   BEGIN {Classic Relief}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               GrSetColor(Raw.Colour3);
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
                    OutTextXY(x1+41,y1+8,Raw.Colour8,255,1,Raw.Text);
               END
               ELSE
               BEGIN {Non-Mimimized Header}
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    OutTextXY(x1+15,y1+8,Raw.Colour8,255,1,Raw.Text);
               END;
          END;
     2:   BEGIN {Stamped Headers}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
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
                    OutTextXY(x1+40,y1+8,Raw.Colour8,255,1,Raw.Text);
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
                    OutTextXY(x1+15,y1+8,Raw.Colour8,255,1,Raw.Text);
               END;
          END;
     3:   BEGIN {Dozzzy Windows}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
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
                    OutTextXY(x1+40,y1+8,Raw.Colour8,255,1,Raw.Text);
               END
               ELSE OutTextXY(x1+15,y1+8,Raw.Colour8,255,1,Raw.Text);
          END;
     4:   BEGIN {Panel Window}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
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
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(WindowHigh);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(WindowLow);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE RaisedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(WindowLow);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(WindowHigh);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE GetFreeMem;
VAR  Temp1 : String;
     Temp2 : String;
BEGIN
     Temp1 := _String(Trunc(MaxAvail/1024))+'K';
     Temp2 := _String(Trunc(DiskFree(0)/1024))+'K';
     GrDisplayMouse(GrHide);
     OutTextXY(55,GraphMaxY-40,11,1,2,_PadRight(Temp1,11));
     OutTextXY(55,GraphMaxY-24,11,1,2,_PadRight(Temp2,11));
     GrDisplayMouse(GrShow);
END;


PROCEDURE SaveWindow(Num: Byte);
VAR  Loop : Word;
BEGIN
     Saved[Num].NumPalettes := NumPalettes;
     Saved[Num].ScreenInfo  := ScreenInfo;
     Saved[Num].NButtons    := NButtons;
     Saved[Num].NFields     := NFields;
     ASSIGN(FButtons,'SGB'+_String(Num)+'.$$$');
     REWRITE(FButtons);
     FOR Loop := 1 TO 110 DO
         WRITE(FButtons,Buttons[Loop]);
     CLOSE(FButtons);
     ASSIGN(FPalettes,'SGP'+_String(Num)+'.$$$');
     REWRITE(FPalettes);
     FOR Loop := 1 TO 8 DO
         WRITE(FPalettes,Palettes[Loop]);
     CLOSE(FPalettes);
     NButtons    := 0;
     NFields     := 0;
     NumPalettes := 0;
     LastPressed := 0;
END;


PROCEDURE ReloadWindow(Num: Byte);
VAR  Loop : Word;
BEGIN
     NumPalettes := Saved[Num].NumPalettes;
     ScreenInfo  := Saved[Num].ScreenInfo;
     NButtons    := Saved[Num].NButtons;
     NFields     := Saved[Num].NFields;
     ASSIGN(FButtons,'SGB'+_String(Num)+'.$$$');
     RESET(FButtons);
     FOR Loop := 1 TO 110 DO
         READ(FButtons,Buttons[Loop]);
     CLOSE(FButtons);
     ERASE(FButtons);
     ASSIGN(FPalettes,'SGP'+_String(Num)+'.$$$');
     RESET(FPalettes);
     FOR Loop := 1 TO 8 DO
         READ(FPalettes,Palettes[Loop]);
     CLOSE(FPalettes);
     ERASE(FPalettes);
     LastPressed := 0;
END;


PROCEDURE GrowWindow(xx1,yy1,xx2,yy2: Word);
VAR  Loop : Word;
     XDif : Word;
     YDif : Word;
     MidX : Word;
     MidY : Word;
BEGIN
     IF NOT(GrowingWindows) THEN Exit;
     XDif := Trunc((xx2-xx1+1)/20);
     YDif := Trunc((yy2-yy1+1)/20);
     MidX := Trunc((xx1+xx2)/2);
     MidY := Trunc((yy1+yy2)/2);
     GrSetLineStyle(GrLSolid,2);
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     FOR Loop := 1 TO 10 DO
     BEGIN
          GrDrawRect(MidX-(Loop*XDif),MidY-(Loop*YDif),MidX+(Loop*XDif),MidY+(Loop*YDif),GrOutLine);
          GrDrawRect(MidX-(Loop*XDif),MidY-(Loop*YDif),MidX+(Loop*XDif),MidY+(Loop*YDif),GrOutLine);
     END;
     GrSetOp(GxSet);
     GrSetLineStyle(GrLSolid,1);
END;


PROCEDURE ShrinkWindow(xx1,yy1,xx2,yy2: Word);
VAR  Loop : Word;
     XDif : Word;
     YDif : Word;
     MidX : Word;
     MidY : Word;
BEGIN
     IF NOT(GrowingWindows) THEN Exit;
     XDif := Trunc((xx2-xx1+1)/20);
     YDif := Trunc((yy2-yy1+1)/20);
     MidX := Trunc((xx1+xx2)/2);
     MidY := Trunc((yy1+yy2)/2);
     GrSetLineStyle(GrLSolid,2);
     GrSetColor(XORLine);
     GrSetOp(GxXOR);
     FOR Loop := 10 DOWNTO 1 DO
     BEGIN
          GrDrawRect(MidX-(Loop*XDif),MidY-(Loop*YDif),MidX+(Loop*XDif),MidY+(Loop*YDif),GrOutLine);
          GrDrawRect(MidX-(Loop*XDif),MidY-(Loop*YDif),MidX+(Loop*XDif),MidY+(Loop*YDif),GrOutLine);
     END;
     GrSetOp(GxSet);
     GrSetLineStyle(GrLSolid,1);
END;


PROCEDURE KillWindow;
BEGIN
     GrDisplayMouse(GrHide);
     Load_Cutout(0,0,ScreenInfo.Index,0);
     ShrinkWindow(ScreenInfo.OrigX1+ScreenInfo.XOffset,
                  ScreenInfo.OrigY1+ScreenInfo.YOffset,
                  ScreenInfo.OrigX2+ScreenInfo.XOffset,
                  ScreenInfo.OrigY2+ScreenInfo.YOffset);
     GrDisplayMouse(GrShow);
     Kill_Cutout(ScreenInfo.Index,0);
     Kill_Cutout(ScreenInfo.Index,1);
     ScreenInfo.XOffSet := 0;
     ScreenInfo.YOffSet := 0;
     ScreenInfo.OrigX1  := 999;
     ScreenInfo.OrigX2  := 999;
     ScreenInfo.OrigY1  := 999;
     ScreenInfo.OrigY1  := 999;
     LastPressed        := 0;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: word; title: String; Number: Word);
BEGIN
     ScreenInfo.OrigX1  := x1;
     ScreenInfo.OrigY1  := y1;
     ScreenInfo.OrigX2  := x2;
     ScreenInfo.OrigY2  := y2;
     ScreenInfo.XOffset := 0;
     ScreenInfo.YOffSet := 0;
     ScreenInfo.Index   := Number;
     Save_Cutout(x1,y1,x2+5,y2+5,Number,0);
     GrowWindow(x1,y1,x2,y2);
     {WINDOW}
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrSetColor(0);
     GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrSetColor(WindowLow);
     GrDrawLine(x1+1,y2-1,x2-1,y2-1);
     GrDrawLine(x2-1,y1+1,x2-1,y2-1);
     GrSetColor(WindowHigh);
     GrDrawLine(x1+1,y1+1,x2-1,y1+1);
     GrDrawLine(x1+1,y1+1,x1+1,y2-1);
     {WINDOW HEADER}
     GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
     GrDrawRect(x1+5,y1+5,x2-5,y1+25,GrFill);
     GrSetColor(WindowLowC);
     GrDrawLine(x1+5,y1+25,x2-5,y1+25);
     GrDrawLine(x2-5,y1+5,x2-5,y1+25);
     GrSetColor(WindowHighC);
     GrDrawLine(x1+5,y1+5,x2-5,y1+5);
     GrDrawLine(x1+5,y1+5,x1+5,y1+25);
     GrSetColor(WindowLow);
     GrDrawLine(x1+4,y1+4,x2-4,y1+4);
     GrDrawLine(x1+4,y1+4,x1+4,y1+26);
     GrSetColor(WindowHigh);
     GrDrawLine(x1+5,y1+26,x2-4,y1+26);
     GrDrawLine(x2-4,y1+5,x2-4,y1+26);
     {WINDOW SHADOW}
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(x1+5,y2+1,x2+5,y2+5,GrFill);
     GrDrawRect(x2+1,y1+5,x2+5,y2+5,GrFill);
     OutTextXY(x1+20,y1+8,WindowTextC,255,1,title);
END;


PROCEDURE WindowHeader(title: String; Enabled: Boolean);
VAR  X1,Y1,X2,Y2 : Word;
BEGIN
     X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset;
     Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset;
     X2 := ScreenInfo.OrigX2+ScreenInfo.XOffset;
     Y2 := ScreenInfo.OrigY2+ScreenInfo.YOffset;
     GrDisplayMouse(GrHide);
     IF Enabled THEN
     BEGIN
          GrSetFillStyle(GrFSolid,WindowHeaderC,GrOpaque);
          GrDrawRect(x1+5,y1+5,x2-5,y1+25,GrFill);
          OutTextXY(x1+20,y1+8,WindowTextC,255,1,title);
          GrSetColor(WindowLowC);
          GrDrawLine(x1+5,y1+25,x2-5,y1+25);
          GrDrawLine(x2-5,y1+5,x2-5,y1+25);
          GrSetColor(WindowHighC);
          GrDrawLine(x1+5,y1+5,x2-5,y1+5);
          GrDrawLine(x1+5,y1+5,x1+5,y1+25);
     END
     ELSE
     BEGIN
          GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
          GrDrawRect(x1+5,y1+5,x2-5,y1+25,GrFill);
          OutTextXY(x1+20,y1+8,WindowTextD,255,1,title);
          GrSetColor(WindowLow);
          GrDrawLine(x1+5,y1+25,x2-5,y1+25);
          GrDrawLine(x2-5,y1+5,x2-5,y1+25);
          GrSetColor(WindowHigh);
          GrDrawLine(x1+5,y1+5,x2-5,y1+5);
          GrDrawLine(x1+5,y1+5,x1+5,y1+25);
     END;
     GrDisplayMouse(GrShow);
END;


END.
