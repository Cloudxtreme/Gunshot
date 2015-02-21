{$I DEFINES.INC}
UNIT RatEdit;


INTERFACE


PROCEDURE MouseEditor;


IMPLEMENTATION


USES Globals,BsString,Gr2_Bp,_Win,Gx2_BpVC,_Text,BHandler,
     _Icons,PalBoxes,BsGraph,_FSelect,LoadMse,SaveMse,BsFile;


PROCEDURE LoadUpMouseRecord;
VAR  X,Y: Word;
BEGIN
     FOR x := 1 TO 16 DO
     BEGIN
          FOR y := 1 TO 16 DO
          BEGIN
               MouseDef.Cursor[x,y] := WorkCursor[x,y];
               MouseDef.Mask[x,y]   := WorkMask[x,y];
          END;
     END;
     MouseDef.HotX   := WorkHotspotX;
     MouseDef.HotY   := WorkHotspotY;
     MouseDef.Colour := WorkColour;
END;


PROCEDURE LoadFromMouseRecord;
VAR  X,Y: Word;
BEGIN
     FOR x := 1 TO 16 DO
     BEGIN
          FOR y := 1 TO 16 DO
          BEGIN
               WorkCursor[x,y] := MouseDef.Cursor[x,y];
               WorkMask[x,y]   := MouseDef.Mask[x,y];
          END;
     END;
     WorkHotspotX := MouseDef.HotX;
     WorkHotspotY := MouseDef.HotY;
     WorkColour   := MouseDef.Colour;
END;


PROCEDURE TestMouse;
VAR  HiByte    : Byte;
     LoByte    : Byte;
     WorkX     : Word;
     WorkY     : Word;
     MMask     : Array[0..15] Of Word;
     MCursor   : Array[0..15] Of Word;
     C         : Byte;
BEGIN
     MouseDef.Colour := WorkColour;
     MouseDef.HotX   := WorkHotspotX;
     MouseDef.HotY   := WorkHotspotY;
     {DO CURSOR}
     FOR WorkY := 1 TO 16 DO
     BEGIN
          LoByte  := 0;
          C       := 7;
          {FIRST BYTE}
          FOR WorkX := 1 TO 8 DO
          BEGIN
               IF WorkCursor[WorkX,WorkY]=False
                  THEN LoByte := _ClrBit(LoByte,C)
                  ELSE LoByte := _SetBit(LoByte,C);
               DEC(c);
          END;
          HiByte  := 0;
          C       := 7;
          {SECOND BYTE}
          FOR WorkX := 9 TO 16 DO
          BEGIN
               IF WorkCursor[WorkX,WorkY]=False
                  THEN HiByte := _ClrBit(HiByte,C)
                  ELSE HiByte := _SetBit(HiByte,C);
               DEC(c);
          END;
          MCursor[WorkY-1] := (LoByte*256)+HiByte;
     END;
     {DO MASK}
     FOR WorkY := 1 TO 16 DO
     BEGIN
          LoByte  := 0;
          C       := 7;
          {FIRST BYTE}
          FOR WorkX := 1 TO 8 DO
          BEGIN
               IF WorkMask[WorkX,WorkY]=True
                  THEN LoByte := _ClrBit(LoByte,C)
                  ELSE LoByte := _SetBit(LoByte,C);
               DEC(c);
          END;
          HiByte  := 0;
          C       := 7;
          {SECOND BYTE}
          FOR WorkX := 9 TO 16 DO
          BEGIN
               IF WorkMask[WorkX,WorkY]=True
                  THEN HiByte := _ClrBit(HiByte,C)
                  ELSE HiByte := _SetBit(HiByte,C);
               DEC(c);
          END;
          MMask[WorkY-1] := (LoByte*256)+HiByte;
     END;
     GrSetMouseMask(grCUSER,MouseDef.HotX,MouseDef.HotY,@MCursor,@MMask);
     GrSetMouseStyle(GrCUSER,MouseDef.Colour);
     REPEAT
     UNTIL (GrGetMouseButtons<>0);
     GrSetMouseStyle(GrCARROW,15);
     REPEAT
     UNTIL (GrGetMouseButtons=0);
END;


PROCEDURE DrawWorkGrid(Number: Byte);
VAR  LoopX,LoopY : Word;
     LocX,LocY   : Word;
     StartX      : Word;
     StartY      : Word;
BEGIN
     GrSetColor(0);
     GrDrawRect(WinX[Number],WinY[Number],WinX[Number]+128,WinY[Number]+128,GrOutline);
     InvertedBox(WinX[Number]-1,WinY[Number]-1,WinX[Number]+129,WinY[Number]+129);
     LocX := WinX[Number];
     LocY := WinY[Number];
     FOR LoopX := 1 TO 17 DO
     BEGIN
          IF LoopX=9 THEN GrSetColor(9)
                     ELSE GrSetColor(0);
          GrDrawLine(LocX,WinY[Number],LocX,WinY[Number]+128);
          INC(LocX,8);
     END;
     FOR LoopY := 1 TO 17 DO
     BEGIN
          IF LoopY=9 THEN GrSetColor(9)
                     ELSE GrSetColor(0);
          GrDrawLine(WinX[Number],LocY,WinX[Number]+128,LocY);
          INC(LocY,8);
     END;
     LocX := WinX[Number];
     LocY := WinY[Number];
     FOR LoopX := 1 TO 16 DO
     BEGIN
          FOR LoopY := 1 TO 16 DO
          BEGIN
               gxVirtualDisplay(Disabled,0,0,
                                LocX+1+((LoopX-1)*8),
                                LocY+1+((LoopY-1)*8),
                                LocX-1+(LoopX*8),
                                LocY-1+(LoopY*8),0);
          END;
     END;
END;


PROCEDURE CheckFile;
VAR  Loop  : Word;
BEGIN
     IF NOT(_FileExists(ICONDir+CurrentIFile)) THEN
     BEGIN
          FillChar(MouseDef,SizeOf(MouseDef),0);
          MouseDef.Colour := 15;
          MouseDef.HotX   := 1;
          MouseDef.HotY   := 1;
          ASSIGN(FMouseDef,ICONDir+CurrentIFile);
          REWRITE(FMouseDef);
          FOR Loop := 1 TO 100 DO WRITE(FMouseDef,MouseDef);
          CLOSE(FMouseDef);
     END;
END;


PROCEDURE UpdateWorkCursor(LoopX,LoopY: Word);
VAR  LocX,LocY   : Word;
BEGIN
     LocX := WinX[1];
     LocY := WinY[1];
     IF WorkCursor[LoopX,LoopY] THEN
     BEGIN
          GrSetFillStyle(GrFSolid,WorkColour,GrOpaque);
          GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                     LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
     END
     ELSE gxVirtualDisplay(Disabled,0,0,LocX+1+((LoopX-1)*8),
                           LocY+1+((LoopY-1)*8),LocX-1+(LoopX*8),
                           LocY-1+(LoopY*8),0);
END;


PROCEDURE UpdateWorkMask(LoopX,LoopY: Word);
VAR  LocX,LocY   : Word;
BEGIN
     LocX := WinX[2];
     LocY := WinY[2];
     IF WorkMask[LoopX,LoopY] THEN
     BEGIN
          GrSetFillStyle(GrFSolid,0,GrOpaque);
          GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                     LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
     END
     ELSE gxVirtualDisplay(Disabled,0,0,LocX+1+((LoopX-1)*8),
                           LocY+1+((LoopY-1)*8),LocX-1+(LoopX*8),
                           LocY-1+(LoopY*8),0);
END;


PROCEDURE UpdateWorkHotSpot(LoopX,LoopY: Word);
VAR  LocX,LocY   : Word;
BEGIN
     LocX := WinX[3];
     LocY := WinY[3];
     gxVirtualDisplay(Disabled,0,0,LocX+1+((WorkHotspotX-1)*8),
                      LocY+1+((WorkHotspotY-1)*8),LocX-1+(WorkHotspotX*8),
                      LocY-1+(WorkHotspotY*8),0);
     WorkHotspotX := LoopX;
     WorkHotspotY := LoopY;
     GrSetFillStyle(GrFSolid,4,GrOpaque);
     GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
END;


PROCEDURE DrawWorkMouse;
VAR  LoopX,LoopY : Word;
     LocX,LocY   : Word;
BEGIN
     {CURSOR}
     LocX := WinX[1];
     LocY := WinY[1];
     FOR LoopX := 1 TO 16 DO
     BEGIN
          FOR LoopY := 1 TO 16 DO
          BEGIN
               IF WorkCursor[LoopX,LoopY] THEN
               BEGIN
                    GrSetFillStyle(GrFSolid,WorkColour,GrOpaque);
                    GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                               LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
               END
               ELSE gxVirtualDisplay(Disabled,0,0,LocX+1+((LoopX-1)*8),
                                     LocY+1+((LoopY-1)*8),LocX-1+(LoopX*8),
                                     LocY-1+(LoopY*8),0);
          END;
     END;
     {MASK}
     LocX := WinX[2];
     LocY := WinY[2];
     FOR LoopX := 1 TO 16 DO
     BEGIN
          FOR LoopY := 1 TO 16 DO
          BEGIN
               IF WorkMask[LoopX,LoopY] THEN
               BEGIN
                    GrSetFillStyle(GrFSolid,0,GrOpaque);
                    GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                               LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
               END
               ELSE gxVirtualDisplay(Disabled,0,0,LocX+1+((LoopX-1)*8),
                                     LocY+1+((LoopY-1)*8),LocX-1+(LoopX*8),
                                     LocY-1+(LoopY*8),0);
          END;
     END;
     {HOTSPOT}
     LocX := WinX[3];
     LocY := WinY[3];
     FOR LoopX := 1 TO 16 DO
     BEGIN
          FOR LoopY := 1 TO 16 DO
          BEGIN
               IF ((WorkHotSpotX=LoopX) AND (WorkHotSpotY=LoopY)) THEN
               BEGIN
                    GrSetFillStyle(GrFSolid,4,GrOpaque);
                    GrDrawRect(LocX+1+((LoopX-1)*8),LocY+1+((LoopY-1)*8),
                               LocX-1+(LoopX*8),LocY-1+(LoopY*8),GrFill);
               END
               ELSE gxVirtualDisplay(Disabled,0,0,LocX+1+((LoopX-1)*8),
                                     LocY+1+((LoopY-1)*8),LocX-1+(LoopX*8),
                                     LocY-1+(LoopY*8),0);
          END;
     END;
END;


PROCEDURE MouseEditor;
VAR  DoJob  : Word;
     Action : Word;
     WinX1  : Word;
     WinY1  : Word;
     WinX2  : Word;
     WinY2  : Word;
     DoX    : Word;
     DoY    : Word;
     Work   : Word;
     Work2  : Word;
     TFill  : Word;
     What   : Word;
     Temp   : String;
     Loaded : Boolean;
LABEL         SkipHandler;
BEGIN
     FOR Work := 1 TO 16 DO
         FOR Work2 := 1 TO 16 DO
             WorkCursor[Work,Work2] := False;
     FOR Work := 1 TO 16 DO
         FOR Work2 := 1 TO 16 DO
             WorkMask[Work,Work2] := False;
     WorkHotspotX := 1;
     WorkHotspotY := 1;
     WorkColour   := 15;
     NButtons     := 0;
     CurrentIFile  := 'MOUSELIB.MSE';
     CheckFile;
     GrDisplayMouse(GrHide);
     DrawWindow(25,100,474,355,'MOUSE EDITOR - '+CurrentIFile,IconEditWindow);
     OutTextXY(45,143,0,255,1,'Cursor');
     OutTextXY(185,143,0,255,1,'Mask');
     OutTextXY(325,143,0,255,1,'Hotspot');
     WinX[1] := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
     WinY[1] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
     WinX[2] := ScreenInfo.OrigX1+ScreenInfo.XOffset+160;
     WinY[2] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
     WinX[3] := ScreenInfo.OrigX1+ScreenInfo.XOffset+300;
     WinY[3] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
     DrawWorkGrid(1);
     DrawWorkGrid(2);
     DrawWorkGrid(3);
     DoY := 306;
     DoX := 256;
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,4);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,2);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,3);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,25); INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,8);  INC(DoX,34);
     SystemButton(DoX,DoY,DoX+34,DoY+34,1,False,True); SystemIcon(DoX+2,DoY+2,9);  INC(DoX,34);
     DrawWorkMouse;
     OutTextXY(95,305,0,255,1,'Colour Palette');
     ClearPaletteQueue;
     AddToPaletteQueue(65,330,10,WorkColour,False);
     GrDisplayMouse(GrShow);
     GetFreeMem;
     REPEAT
           WinX[1] := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
           WinY[1] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
           WinX[2] := ScreenInfo.OrigX1+ScreenInfo.XOffset+20+140;
           WinY[2] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
           WinX[3] := ScreenInfo.OrigX1+ScreenInfo.XOffset+20+280;
           WinY[3] := ScreenInfo.OrigY1+ScreenInfo.YOffSet+60;
           IF GrGetMouseButtons<>0 THEN
           BEGIN
                IF ChangedAColour(GetMouseX,GetMouseY) THEN
                BEGIN
                     WorkColour := Palettes[ChangedWhich].Current;
                     GrDisplayMouse(GrHide);
                     DrawWorkMouse;
                     GrDisplayMouse(GrShow);
                     GOTO SkipHandler;
                END
                ELSE MoveColourPal(GetMouseX,GetMouseY);
                IF ((GetMouseX>WinX[1]) AND (GetMouseX<WinX[1]+128) AND
                   (GetMouseY>WinY[1]) AND (GetMouseY<WinY[1]+128)) THEN
                BEGIN
                     DoX := (TRUNC((GetMouseX-WinX[1])/8))+1;
                     DoY := (TRUNC((GetMouseY-WinY[1])/8))+1;
                     IF ((DoX>0) AND (DoX<17) AND (DoY>0) AND (DoY<17)) THEN
                     BEGIN
                          IF GrGetMouseButtons=GrLButton THEN
                          BEGIN
                               IF WorkCursor[DoX,DoY]<>True THEN
                               BEGIN
                                    WorkCursor[DoX,DoY] := True;
                                    GrDisplayMouse(GrHide);
                                    UpdateWorkCursor(DoX,DoY);
                                    GrDisplayMouse(GrShow);
                               END;
                               GOTO SkipHandler;
                          END
                          ELSE IF GrGetMouseButtons=GrRButton THEN
                          BEGIN
                               IF WorkCursor[DoX,DoY]<>False THEN
                               BEGIN
                                    WorkCursor[DoX,DoY] := False;
                                    GrDisplayMouse(GrHide);
                                    UpdateWorkCursor(DoX,DoY);
                                    GrDisplayMouse(GrShow);
                               END;
                               GOTO SkipHandler;
                          END;
                     END;
                END
                ELSE IF ((GetMouseX>WinX[2]) AND (GetMouseX<WinX[2]+128) AND
                        (GetMouseY>WinY[2]) AND (GetMouseY<WinY[2]+128)) THEN
                BEGIN
                     DoX := (TRUNC((GetMouseX-WinX[2])/8))+1;
                     DoY := (TRUNC((GetMouseY-WinY[2])/8))+1;
                     IF ((DoX>0) AND (DoX<17) AND (DoY>0) AND (DoY<17)) THEN
                     BEGIN
                          IF GrGetMouseButtons=GrLButton THEN
                          BEGIN
                               IF WorkMask[DoX,DoY]<>True THEN
                               BEGIN
                                    WorkMask[DoX,DoY] := True;
                                    GrDisplayMouse(GrHide);
                                    UpdateWorkMask(DoX,DoY);
                                    GrDisplayMouse(GrShow);
                               END;
                               GOTO SkipHandler;
                          END
                          ELSE IF GrGetMouseButtons=GrRButton THEN
                          BEGIN
                               IF WorkMask[DoX,DoY]<>False THEN
                               BEGIN
                                    WorkMask[DoX,DoY] := False;
                                    GrDisplayMouse(GrHide);
                                    UpdateWorkMask(DoX,DoY);
                                    GrDisplayMouse(GrShow);
                               END;
                               GOTO SkipHandler;
                          END;
                     END;
                END
                ELSE IF ((GetMouseX>WinX[3]) AND (GetMouseX<WinX[3]+128) AND
                        (GetMouseY>WinY[3]) AND (GetMouseY<WinY[3]+128)) THEN
                BEGIN
                     DoX := (TRUNC((GetMouseX-WinX[3])/8))+1;
                     DoY := (TRUNC((GetMouseY-WinY[3])/8))+1;
                     IF ((DoX>0) AND (DoX<17) AND (DoY>0) AND (DoY<17)) THEN
                     BEGIN
                          IF GrGetMouseButtons=GrLButton THEN
                          BEGIN
                               IF ((DoX<>WorkHotspotX) OR (DoY<>WorkHotspotY)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    UpdateWorkHotspot(DoX,DoY);
                                    GrDisplayMouse(GrShow);
                               END;
                               GOTO SkipHandler;
                          END;
                     END;
                END;
           END;
           DoJob := MouseHandler(False);
           CASE DoJob OF
           1:   BEGIN {CHANGE MOUSE BANK}
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,False);
                     Temp := CurrentIFile;
                     What := FileSelector(ICONDir,'*.MSE','',Temp,True,True,False);
                     CASE What OF
                     1:   CurrentIFile := Temp;
                     2:   BEGIN
                               CurrentIFile := Temp;
                               CheckFile;
                          END;
                     END;
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,True);
                END;
           2:   BEGIN {LOAD}
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,False);
                     LoadUpMouseRecord;
                     SaveWindow(1);
                     Loaded := LoadMouseFromBank(CurrentIFile);
                     ReloadWindow(1);
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,True);
                     IF Loaded THEN
                     BEGIN
                          LoadFromMouseRecord;
                          GrDisplayMouse(GrHide);
                          DrawWorkMouse;
                          GrDisplayMouse(GrShow);
                     END;
                END;
           3:   BEGIN {SAVE}
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,False);
                     LoadUpMouseRecord;
                     SaveWindow(1);
                     SaveMouseToBank(CurrentIFile);
                     ReloadWindow(1);
                     WindowHeader('MOUSE EDITOR - '+CurrentIFile,True);
                END;
           4:   TestMouse;
           5:   BEGIN {TRASH}
                      FOR Work := 1 TO 16 DO
                          FOR Work2 := 1 TO 16 DO
                              WorkCursor[Work,Work2] := False;
                      FOR Work := 1 TO 16 DO
                          FOR Work2 := 1 TO 16 DO
                              WorkMask[Work,Work2] := False;
                      WorkHotspotX := 1;
                      WorkHotspotY := 1;
                      WorkColour   := 15;
                      GrDisplayMouse(GrHide);
                      DrawWorkMouse;
                      GrDisplayMouse(GrShow);
                END;
           END;
           SkipHandler:
     UNTIL DoJob=6;
     KillWindow;
END;


END.
