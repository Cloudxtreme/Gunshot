{$I DEFINES.INC}
UNIT WinDefs;


INTERFACE


FUNCTION  DoChangeBackGround: Boolean;
PROCEDURE DoChangeMouse;
PROCEDURE DoChangeSound;


IMPLEMENTATION


USES Globals,BsString,Gr2_Bp,_Win,_Text,BHandler,_Icons,LoadMse,
     _FSelect,Fx2_Bp,IconMisc,PalBoxes,BsGraph,LoadIcon,Gunshot,
     BsFile;


PROCEDURE DoChangeMouse;
VAR  GotNew    : Boolean;
     Temp      : String;
     What      : Word;
     c         : Word;
     Working   : _Raw_File;

     PROCEDURE DrawOutMouse;
     VAR  LoopX,LoopY : Word;
          FMouseDef2  : File Of _Mouse_Def;
          MouseDef2   : _Mouse_Def;
          XX          : Word;
          YY          : Word;
     BEGIN
          IF _FileExists(ICONDir+Working.ObjFile) THEN
          BEGIN
               ASSIGN(FMouseDef2,ICONDir+Working.ObjFile);
               RESET(FMouseDef2);
               SEEK(FMouseDef2,Working.Colour1-1);
               READ(FMouseDef2,MouseDef2);
               CLOSE(FMouseDef2);
               XX := ScreenInfo.OrigX1+ScreenInfo.XOffset+83;
               YY := ScreenInfo.OrigY1+ScreenInfo.YOffset+103;
               {Mask First}
               FOR LoopX := 0 TO 15 DO
               BEGIN
                    FOR LoopY := 0 TO 15 DO
                    BEGIN
                         IF MouseDef2.Mask[LoopX+1,LoopY+1]=True
                            THEN GrPutPixel(XX+LoopX,YY+LoopY,0)
                            ELSE GrPutPixel(XX+LoopX,YY+LoopY,7);
                    END;
               END;
               {Cursor Next}
               FOR LoopX := 0 TO 15 DO
               BEGIN
                    FOR LoopY := 0 TO 15 DO
                    BEGIN
                         IF MouseDef2.Cursor[LoopX+1,LoopY+1]=True THEN
                            GrPutPixel(XX+LoopX,YY+LoopY,MouseDef2.Colour);
                    END;
               END;
          END;
     END;

     PROCEDURE ToggleType;
     BEGIN
          InvertedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+40,
                      ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+80);
          InvertedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+90,
                      ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+130);
          OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+43,8,255,1,'None');
          OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+93,8,255,1,'Change');
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
          GrDrawRect(Buttons[3].x1+4,Buttons[3].y1+4,Buttons[3].x1+9,Buttons[3].y1+9,GrFill);
          CASE Working.Style OF
          0:   BEGIN
                    Buttons[4].Enabled := False;
                    Buttons[5].Enabled := False;
                    GrSetColor(0);
                    GrSetFillStyle(GrFSolid,7,GrOpaque);
                    GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffset+131,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+101,
                               ScreenInfo.OrigX1+ScreenInfo.XOffset+251,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+119,GrOutline+GrFill);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+143,ScreenInfo.OrigY1+ScreenInfo.YOffset+104,
                               8,255,2,Working.ObjFile);
                    GrSetFillStyle(GrFSolid,4,GrOpaque);
                    GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
                    RaisedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+40,
                              ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+80);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+43,
                              0,255,1,'None');
               END;
          1:   BEGIN
                    Buttons[4].Enabled := True;
                    Buttons[5].Enabled := True;
                    GrSetColor(0);
                    GrSetFillStyle(GrFSolid,15,GrOpaque);
                    GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffset+131,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+101,
                               ScreenInfo.OrigX1+ScreenInfo.XOffset+251,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+119,GrOutline+GrFill);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+143,ScreenInfo.OrigY1+ScreenInfo.YOffset+104,
                               0,255,2,Working.ObjFile);
                    GrSetFillStyle(GrFSolid,4,GrOpaque);
                    GrDrawRect(Buttons[3].x1+4,Buttons[3].y1+4,Buttons[3].x1+9,Buttons[3].y1+9,GrFill);
                    RaisedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+90,
                              ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+130);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+93,
                              0,255,1,'Change');
               END;
          END;
     END;

BEGIN
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,1);
     READ(FWorkSg,Working);
     CLOSE(FWorkSg);
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(100,100,389,280,'MOUSE POINTER',EditWindow);
     SystemButton(314,240,379,270,1,False,True);
     OutTextXY(334,247,0,255,1,'Done');
     SystemButton(ScreenInfo.OrigX1+20,ScreenInfo.OrigY1+60,0,0,4,False,True);
     SystemButton(ScreenInfo.OrigX1+20,ScreenInfo.OrigY1+110,0,0,4,False,True);
     SystemButton(ScreenInfo.OrigX1+80,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+120,1,False,True);
     SystemButton(ScreenInfo.OrigX1+110,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+130,ScreenInfo.OrigY1+120,1,False,True);
     SystemIcon(ScreenInfo.OrigX1+114,ScreenInfo.OrigY1+104,46);
     InvertedBox(ScreenInfo.OrigX1+130,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+252,ScreenInfo.OrigY1+120);
     ToggleType;
     DrawOutMouse;
     GrDisplayMouse(GrShow);
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           2:   IF (Working.Style<>0) THEN
                BEGIN
                     Working.Style := 0;
                     GrDisplayMouse(GrHide);
                     ToggleType;
                     GrDisplayMouse(GrShow);
                END;
           3:   IF (Working.Style<>1) THEN
                BEGIN
                     Working.Style := 1;
                     GrDisplayMouse(GrHide);
                     ToggleType;
                     GrDisplayMouse(GrShow);
                END;
           4:   BEGIN {LOAD NEW MOUSE}
                     WindowHeader('MOUSE POINTER',False);
                     SaveWindow(2);
                     GotNew := LoadMouseFromBank(Working.ObjFile);
                     ReloadWindow(2);
                     IF GotNew THEN
                     BEGIN
                          Working.Colour1 := LoadedMouseNumber;
                          GrDisplayMouse(GrHide);
                          ToggleType;
                          DrawOutMouse;
                          GrDisplayMouse(GrShow);
                     END;
                     WindowHeader('MOUSE POINTER',True);
                END;
           5:   BEGIN {CHANGE MOUSE BANK}
                     WindowHeader('MOUSE POINTER',False);
                     Temp := Working.ObjFile;
                     What := FileSelector(ICONDir,'*.MSE','',Temp,True,False,True);
                     IF What=1 THEN
                     BEGIN
                          Working.ObjFile := Temp;
                          GrDisplayMouse(GrHide);
                          ToggleType;
                          DrawOutMouse;
                          GrDisplayMouse(GrShow);
                     END;
                     WindowHeader('MOUSE POINTER',True);
                END;
           END;
     UNTIL C=1;
     GrDisplayMouse(GrHide);
     KillWindow;
     ReloadWindow(1);
     GrDisplayMouse(GrShow);
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,1);
     WRITE(FWorkSg,Working);
     CLOSE(FWorkSg);
END;



PROCEDURE PlayVocFile(FName: String);
VAR  VocFile  : FXSOUND;
     ssize    : Longint;
     rc       : Integer;
     Loop     : Word;
BEGIN
     GrDisplayMouse(GrHide);
     IF (fxSBInstalled=fxSUCCESS) THEN
     BEGIN
          IF (fxInstallSound(fxSOUNDBLASTER)=fxSUCCESS) THEN
          BEGIN
               ssize := fxFileSoundSize(FName,fxVOC);
               IF (ssize>0) THEN
               BEGIN
                    rc := fxCreateSound(VocFile,fxVOC,ssize);
                    IF (rc=fxSUCCESS) THEN
                    BEGIN
                         rc := fxFileSound(FName,VocFile);
                         IF (rc=fxSUCCESS) THEN
                         BEGIN
                              rc := fxPlaySound(VocFile,0,1,fxFORE);
                              rc := fxDestroySound(VocFile);
                              rc := fxRemoveSound(fxSOUNDBLASTER);
                         END
                         ELSE
                         BEGIN
                              rc := fxDestroySound(VocFile);
                              rc := fxRemoveSound(fxSOUNDBLASTER);
                         END;
                    END
                    ELSE rc := fxRemoveSound(fxSOUNDBLASTER);
               END
               ELSE rc := fxRemoveSound(fxSOUNDBLASTER);
          END;
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE DoChangeSound;
VAR  Temp      : String;
     What      : Word;
     c         : Word;
     Working   : _Raw_File;

     PROCEDURE ToggleType;
     BEGIN
          InvertedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+40,
                      ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+80);
          InvertedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+90,
                      ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+130);
          OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+43,8,255,1,'None');
          OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+93,8,255,1,'Play');
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
          GrDrawRect(Buttons[3].x1+4,Buttons[3].y1+4,Buttons[3].x1+9,Buttons[3].y1+9,GrFill);
          CASE Working.Style OF
          0:   BEGIN
                    Buttons[4].Enabled := False;
                    Buttons[5].Enabled := False;
                    GrSetColor(0);
                    GrSetFillStyle(GrFSolid,7,GrOpaque);
                    GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffset+131,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+101,
                               ScreenInfo.OrigX1+ScreenInfo.XOffset+251,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+119,GrOutline+GrFill);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+143,ScreenInfo.OrigY1+ScreenInfo.YOffset+104,
                               8,255,2,Working.ObjFile);
                    GrSetFillStyle(GrFSolid,4,GrOpaque);
                    GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
                    RaisedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+40,
                              ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+80);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+43,
                              0,255,1,'None');
               END;
          1:   BEGIN
                    Buttons[4].Enabled := True;
                    Buttons[5].Enabled := True;
                    GrSetColor(0);
                    GrSetFillStyle(GrFSolid,15,GrOpaque);
                    GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffset+131,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+101,
                               ScreenInfo.OrigX1+ScreenInfo.XOffset+251,
                               ScreenInfo.OrigY1+ScreenInfo.YOffset+119,GrOutline+GrFill);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+143,ScreenInfo.OrigY1+ScreenInfo.YOffset+104,
                               0,255,2,Working.ObjFile);
                    GrSetFillStyle(GrFSolid,4,GrOpaque);
                    GrDrawRect(Buttons[3].x1+4,Buttons[3].y1+4,Buttons[3].x1+9,Buttons[3].y1+9,GrFill);
                    RaisedBox(ScreenInfo.OrigX1+ScreenInfo.XOffset+10,ScreenInfo.OrigY1+ScreenInfo.YOffset+90,
                              ScreenInfo.OrigX2+ScreenInfo.XOffset-10,ScreenInfo.OrigY1+ScreenInfo.YOffset+130);
                    OutTextXY(ScreenInfo.OrigX1+ScreenInfo.XOffset+15,ScreenInfo.OrigY1+ScreenInfo.YOffset+93,
                              0,255,1,'Play');
               END;
          END;
     END;

BEGIN
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,2);
     READ(FWorkSg,Working);
     CLOSE(FWorkSg);
     SaveWindow(1);
     NButtons := 0;
     GrDisplayMouse(GrHide);
     DrawWindow(100,100,389,280,'SOUND ATTACHMENT',EditWindow);
     SystemButton(314,240,379,270,1,False,True);
     OutTextXY(334,247,0,255,1,'Done');
     SystemButton(ScreenInfo.OrigX1+20,ScreenInfo.OrigY1+60,0,0,4,False,True);
     SystemButton(ScreenInfo.OrigX1+20,ScreenInfo.OrigY1+110,0,0,4,False,True);
     SystemButton(ScreenInfo.OrigX1+110,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+130,ScreenInfo.OrigY1+120,1,False,True);
     SystemButton(ScreenInfo.OrigX1+60,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+120,1,False,True);
     OutTextXY(ScreenInfo.OrigX1+68,ScreenInfo.OrigY1+103,0,255,1,'Test');
     SystemIcon(ScreenInfo.OrigX1+114,ScreenInfo.OrigY1+104,46);
     InvertedBox(ScreenInfo.OrigX1+130,ScreenInfo.OrigY1+100,ScreenInfo.OrigX1+252,ScreenInfo.OrigY1+120);
     ToggleType;
     GrDisplayMouse(GrShow);
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           2:   IF (Working.Style<>0) THEN
                BEGIN
                     Working.Style := 0;
                     GrDisplayMouse(GrHide);
                     ToggleType;
                     GrDisplayMouse(GrShow);
                END;
           3:   IF (Working.Style<>1) THEN
                BEGIN
                     Working.Style := 1;
                     GrDisplayMouse(GrHide);
                     ToggleType;
                     GrDisplayMouse(GrShow);
                END;
           4:   BEGIN {CHANGE SOUND BANK}
                     WindowHeader('SOUND ATTACHMENT',False);
                     Temp := Working.ObjFile;
                     What := FileSelector(SOUNDDir,'*.VOC','',Temp,True,False,True);
                     IF What=1 THEN
                     BEGIN
                          Working.ObjFile := Temp;
                          GrDisplayMouse(GrHide);
                          ToggleType;
                          GrDisplayMouse(GrShow);
                     END;
                     WindowHeader('SOUND ATTACHMENT',True);
                END;
           5:   BEGIN {Test the sound file}
                     PlayVocFile(SOUNDDir+Working.ObjFile);
                END;
           END;
     UNTIL C=1;
     GrDisplayMouse(GrHide);
     KillWindow;
     ReloadWindow(1);
     GrDisplayMouse(GrShow);
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     SEEK(FWorkSg,2);
     WRITE(FWorkSg,Working);
     CLOSE(FWorkSg);
END;


FUNCTION DoChangeBackGround: Boolean;
VAR  C            : Word;
     Work         : Word;
     MadeAChange  : Boolean;
     Temp         : String;
     What         : Word;
     Working      : _Raw_File;
     IBox1X1      : Word;
     IBox1Y1      : Word;
     IBox1X2      : Word;
     IBox1Y2      : Word;
     IBox2X1      : Word;
     IBox2Y1      : Word;
     IBox2X2      : Word;
     IBox2Y2      : Word;
     IBox3X1      : Word;
     IBox3Y1      : Word;
     IBox3X2      : Word;
     IBox3Y2      : Word;
     IBox4X1      : Word;
     IBox4Y1      : Word;
     IBox4X2      : Word;
     IBox4Y2      : Word;
     PBox4X1      : Word;
     PBox4Y1      : Word;
     PBox5X1      : Word;
     PBox5Y1      : Word;
     XX,YY        : Word;

     PROCEDURE ChangeBackType(Number: Word);
     VAR  Loop : Word;
     BEGIN
          IBox1X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
          IBox1Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+40;
          IBox1X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
          IBox1Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+100;
          IBox2X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
          IBox2Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+110;
          IBox2X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
          IBox2Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+170;
          IBox3X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
          IBox3Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+180;
          IBox3X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
          IBox3Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+240;
          IBox4X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
          IBox4Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+250;
          IBox4X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
          IBox4Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+310;
          PBox4X1 := IBox2X1+137;
          PBox4Y1 := IBox2Y1+12;
          PBox5X1 := IBox4X1+137;
          PBox5Y1 := IBox4Y1+12;
          GrDisplayMouse(GrHide);
          InvertedBox(IBox1X1,IBox1Y1,IBox1X2,IBox1Y2);
          InvertedBox(IBox2X1,IBox2Y1,IBox2X2,IBox2Y2);
          InvertedBox(IBox3X1,IBox3Y1,IBox3X2,IBox3Y2);
          InvertedBox(IBox4X1,IBox4Y1,IBox4X2,IBox4Y2);
          Working.Style := Number;
          GrSetFillStyle(GrFSolid,7,GrOpaque);
          FOR Loop := 2 TO 5 DO
          BEGIN
               GrDrawRect(Buttons[Loop].x1+4,Buttons[Loop].y1+4,
                          Buttons[Loop].x1+9,Buttons[Loop].y1+9,GrFill);
          END;
          GrSetFillStyle(GrFSolid,4,GrOpaque);
          GrDrawRect(Buttons[Working.Style+2].x1+4,Buttons[Working.Style+2].y1+4,
                     Buttons[Working.Style+2].x1+9,Buttons[Working.Style+2].y1+9,GrFill);
          OutTextXY(Buttons[2].x1-15,Buttons[2].y1-25,8,255,1,'Solid Fill');
          OutTextXY(Buttons[3].x1-15,Buttons[3].y1-25,8,255,1,'Icon Fill');
          OutTextXY(Buttons[4].x1-15,Buttons[4].y1-25,8,255,1,'None');
          OutTextXY(Buttons[5].x1-15,Buttons[5].y1-25,8,255,1,'Wallpaper Bitmap');
          CASE Working.Style OF
          0:   OutTextXY(Buttons[2].x1-15,Buttons[2].y1-25,0,255,1,'Solid Fill');
          1:   OutTextXY(Buttons[3].x1-15,Buttons[3].y1-25,0,255,1,'Icon Fill');
          2:   OutTextXY(Buttons[4].x1-15,Buttons[4].y1-25,0,255,1,'None');
          3:   OutTextXY(Buttons[5].x1-15,Buttons[5].y1-25,0,255,1,'Wallpaper Bitmap');
          END;
          CASE Working.Style OF
          0:   RaisedBox(IBox1X1,IBox1Y1,IBox1X2,IBox1Y2);
          1:   RaisedBox(IBox2X1,IBox2Y1,IBox2X2,IBox2Y2);
          2:   RaisedBox(IBox3X1,IBox3Y1,IBox3X2,IBox3Y2);
          3:   RaisedBox(IBox4X1,IBox4Y1,IBox4X2,IBox4Y2);
          END;
          CASE Working.Style OF
          1:   BEGIN
                    Buttons[6].Enabled := True;
                    Buttons[7].Enabled := True;
                    Buttons[8].Enabled := False;
               END;
          3:   BEGIN
                    Buttons[6].Enabled := False;
                    Buttons[7].Enabled := False;
                    Buttons[8].Enabled := True;
               END;
          ELSE BEGIN
                    Buttons[6].Enabled := False;
                    Buttons[7].Enabled := False;
                    Buttons[8].Enabled := False;
               END;
          END;
          IF Working.Style=1 THEN
          BEGIN
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,15,GrOpaque);
               GrDrawRect(PBox4X1+66,PBox4Y1+9,PBox4X1+186,PBox4Y1+27,GrOutline+GrFill);
               InvertedBox(PBox4X1+65,PBox4Y1+8,PBox4X1+187,PBox4Y1+28);
               OutTextXY(PBox4X1+78,PBox4Y1+12,0,255,2,Working.ObjFile);
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(PBox5X1+66,PBox5Y1+9,PBox5X1+186,PBox5Y1+27,GrOutline+GrFill);
               InvertedBox(PBox5X1+65,PBox5Y1+8,PBox5X1+187,PBox5Y1+28);
               OutTextXY(PBox5X1+78,PBox5Y1+12,8,255,2,Working.ObjFile);
          END
          ELSE IF Working.Style=3 THEN
          BEGIN
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(PBox4X1+66,PBox4Y1+9,PBox4X1+186,PBox4Y1+27,GrOutline+GrFill);
               InvertedBox(PBox4X1+65,PBox4Y1+8,PBox4X1+187,PBox4Y1+28);
               OutTextXY(PBox4X1+78,PBox4Y1+12,8,255,2,Working.ObjFile);
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,15,GrOpaque);
               GrDrawRect(PBox5X1+66,PBox5Y1+9,PBox5X1+186,PBox5Y1+27,GrOutline+GrFill);
               InvertedBox(PBox5X1+65,PBox5Y1+8,PBox5X1+187,PBox5Y1+28);
               OutTextXY(PBox5X1+78,PBox5Y1+12,0,255,2,Working.ObjFile);
          END
          ELSE
          BEGIN
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(PBox4X1+66,PBox4Y1+9,PBox4X1+186,PBox4Y1+27,GrOutline+GrFill);
               InvertedBox(PBox4X1+65,PBox4Y1+8,PBox4X1+187,PBox4Y1+28);
               OutTextXY(PBox4X1+78,PBox4Y1+12,8,255,2,Working.ObjFile);
               GrSetColor(0);
               GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(PBox5X1+66,PBox5Y1+9,PBox5X1+186,PBox5Y1+27,GrOutline+GrFill);
               InvertedBox(PBox5X1+65,PBox5Y1+8,PBox5X1+187,PBox5Y1+28);
               OutTextXY(PBox5X1+78,PBox5Y1+12,8,255,2,Working.ObjFile);
          END;
          GrDisplayMouse(GrShow);
     END;

     PROCEDURE LoadTheIcon;
     VAR  IcnSize : Word;
          LoopX   : Word;
          LoopY   : Word;
     BEGIN
          IF _FileExists(ICONDir+Working.ObjFile) THEN
          BEGIN
               CurrentIFile := Working.ObjFile;
               CurrentSize  := 30;
               LoadInIcon(Working.Colour4);
               GrDisplayMouse(GrHide);
               FOR LoopX := 1 TO 30 DO
               BEGIN
                    FOR LoopY := 1 TO 30 DO
                    BEGIN
                         IF Work_Icon30.matrix[LoopX,LoopY]=255
                            THEN GrPutPixel(PBox4X1+2+LoopX,PBox4Y1+2+LoopY,7)
                            ELSE GrPutPixel(PBox4X1+2+LoopX,PBox4Y1+2+LoopY,Work_Icon30.matrix[LoopX,LoopY]);
                    END;
               END;
               GrDisplayMouse(GrShow);
          END;
     END;

BEGIN
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     READ(FWorkSg,Working);
     CLOSE(FWorkSg);
     SaveWindow(1);
     NButtons    := 0;
     MadeAChange := False;
     GrDisplayMouse(GrHide);
     DrawWindow(100,50,489,410,'SCREEN BACKGROUND',EditWindow);
     IBox1X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
     IBox1Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+40;
     IBox1X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
     IBox1Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+100;
     IBox2X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
     IBox2Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+110;
     IBox2X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
     IBox2Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+170;
     IBox3X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
     IBox3Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+180;
     IBox3X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
     IBox3Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+240;
     IBox4X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
     IBox4Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+250;
     IBox4X2 := ScreenInfo.OrigX1+ScreenInfo.XOffset+379;
     IBox4Y2 := ScreenInfo.OrigY1+ScreenInfo.YOffset+310;
     ClearPaletteQueue;
     AddToPaletteQueue(IBox1X1+140,IBox1Y1+25,10,Working.Colour1,False);
     {SYSTEM BUTTONS}
     SystemButton(414,370,479,400,1,False,True);
     OutTextXY(434,377,0,255,1,'Done');
     SystemButton(130,118,0,0,4,False,True);
     SystemButton(130,188,0,0,4,False,True);
     SystemButton(130,258,0,0,4,False,True);
     SystemButton(130,328,0,0,4,False,True);
     {ICON FILL BACKGROUND BUTTONS}
     PBox4X1 := IBox2X1+137;
     PBox4Y1 := IBox2Y1+12;
     SystemButton(PBox4X1,PBox4Y1,PBox4X1+36,PBox4Y1+36,1,False,True);
     SystemButton(PBox4X1+45,PBox4Y1+8,PBox4X1+65,PBox4Y1+28,1,False,True);
     SystemIcon(PBox4X1+49,PBox4Y1+13,46);
     {WALLPAPER BACKGROUND BUTTONS}
     PBox5X1 := IBox4X1+137;
     PBox5Y1 := IBox4Y1+12;
     SystemButton(PBox5X1+45,PBox5Y1+8,PBox5X1+65,PBox5Y1+28,1,False,True);
     SystemIcon(PBox5X1+49,PBox5Y1+13,46);
     GrDisplayMouse(GrShow);
     ChangeBackType(Working.Style);
     LoadTheIcon;
     REPEAT
           IBox1X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
           IBox1Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+40;
           IBox2X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
           IBox2Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+110;
           IBox3X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
           IBox3Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+180;
           IBox4X1 := ScreenInfo.OrigX1+ScreenInfo.XOffset+10;
           IBox4Y1 := ScreenInfo.OrigY1+ScreenInfo.YOffset+250;
           PBox4X1 := IBox2X1+137;
           PBox4Y1 := IBox2Y1+12;
           CASE Working.Style OF
           0:   BEGIN
                     IF GrGetMouseButtons=GrLButton THEN
                     BEGIN
                          XX := GetMouseX;
                          YY := GetMouseY;
                          IF ChangedAColour(XX,YY) THEN
                          BEGIN
                               Working.colour1 := Palettes[ChangedWhich].Current;
                               MadeAChange := True;
                          END
                          ELSE MoveColourPal(XX,YY);
                     END;
                END;
           END;
           C := MouseHandler(False);
           CASE C OF
           2..5:  IF (C-2<>Working.Style) THEN
                  BEGIN
                       Working.Style := C-2;
                       ChangeBackType(C-2);
                       MadeAChange := True;
                  END;
           6:     BEGIN {CHANGE ICON}
                       IF _FileExists(ICONDir+Working.ObjFile) THEN
                       BEGIN
                            WindowHeader('SCREEN BACKGROUND',False);
                            CurrentIFile := Working.ObjFile;
                            CurrentSize  := 30;
                            SaveWindow(2);
                            What := LoadFromBank(CurrentIFile);
                            ReloadWindow(2);
                            IF What<>0 THEN
                            BEGIN
                                 Working.Colour4 := What;
                                 ChangeBackType(1);
                                 LoadTheIcon;
                                 MadeAChange := True;
                            END;
                            WindowHeader('SCREEN BACKGROUND',True);
                       END;
                  END;
           7:     BEGIN {CHANGE ICON BANK}
                       WindowHeader('SCREEN BACKGROUND',False);
                       Temp := Working.ObjFile;
                       What := FileSelector(ICONDir,'*.30','',Temp,True,False,True);
                       IF What=1 THEN
                       BEGIN
                            Working.ObjFile := Temp;
                            ChangeBackType(1);
                            LoadTheIcon;
                            MadeAChange := True;
                       END;
                       WindowHeader('SCREEN BACKGROUND',True);
                  END;
           8:     BEGIN {CHANGE WALLPAPER BITMAP}
                       WindowHeader('SCREEN BACKGROUND',False);
                       Temp := Working.ObjFile;
                       What := FileSelector(JPEGDir,'*.*','',Temp,True,False,True);
                       IF What=1 THEN
                       BEGIN
                            Working.ObjFile := Temp;
                            ChangeBackType(3);
                            MadeAChange := True;
                       END;
                       WindowHeader('SCREEN BACKGROUND',True);
                  END;
           END;
     UNTIL C=1;
     GrDisplayMouse(GrHide);
     KillWindow;
     ReloadWindow(1);
     GrDisplayMouse(GrShow);
     DoChangeBackground := MadeAChange;
     ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
     RESET(FWorkSg);
     WRITE(FWorkSg,Working);
     CLOSE(FWorkSg);
END;


END.
