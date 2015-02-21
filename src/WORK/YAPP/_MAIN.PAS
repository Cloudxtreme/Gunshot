{$I DEFINES.INC}
UNIT _Main;


INTERFACE


FUNCTION  FoundAlreadyOnStack (InString: String)  : Boolean;
FUNCTION  UnpackTheGIP        (VAR FName: String) : Boolean;
PROCEDURE RedrawScreen        (FName: String);
PROCEDURE RebuildDeskTop;


IMPLEMENTATION


USES Gx2_Bp,Gx2_BpVC,Gr2_Bp,Tx2_Bp,Globals,BsGraph,_Icons,GfxProto,_Bezier,
     _Win,_Mouse,_Token,_Text,_Buffers,_Fields,_Extern,_Images,Shotgun,
     BsComp,BsFile;


FUNCTION FoundAlreadyOnStack(InString: String): Boolean;
VAR  Loop       : Word;
     TempSaved  : Saved_Cutouts;
     FoundIndex : Word;
     Work       : Word;
LABEL             Continue;
BEGIN
     FoundIndex := 0;
     FOR Loop := 1 TO NumCutouts DO
     BEGIN
          IF ((SavedCutouts[Loop].FileName=InString) AND (SavedCutouts[Loop].Active)) THEN
          BEGIN
               FoundIndex := Loop;
               GOTO Continue;
          END;
     END;
     Continue:
     IF FoundIndex=0 THEN
     BEGIN
          FoundAlreadyOnStack := False;
          Exit;
     END;
     Work := 2;
     TempSaved := SavedCutouts[FoundIndex];
     FOR Loop := 2 TO NumCutouts DO
     BEGIN
          IF Loop<>FoundIndex THEN
          BEGIN
               SavedCutouts[Work] := SavedCutouts[Loop];
               INC(Work);
          END;
     END;
     FillChar(SavedCutouts[NumCutouts],SizeOf(SavedCutouts[NumCutouts]),0);
     SavedCutouts[1] := TempSaved;
     FoundAlreadyOnStack := True;
END;


PROCEDURE RebuildDeskTop;
VAR  Loop : Word;
BEGIN
     grSetActiveVirtual(OffScreen);
     txSetActiveVirtual(OffScreen);
     grSetVirtual(gxTrue);
     txSetVirtual(gxTrue);
     gxVirtualVirtual(ScreenBack,0,0,GraphMaxX,YWindow,OffScreen,0,0,gxSet);
     FOR Loop := NumCutouts DOWNTO 2 DO
     BEGIN
          IF SavedCutouts[Loop].Active THEN
          BEGIN
               WITH SavedCutouts[Loop] DO
               BEGIN
                    gxVirtualVirtual(Cutout,0,0,Coordinates[3]-Coordinates[1],
                                     Coordinates[4]-Coordinates[2],OffScreen,
                                     Coordinates[1],Coordinates[2],gxSet);
                    GrSetFillStyle(GrFCloseDot,0,GrTrans);
                    GrDrawRect(Coordinates[1]+5,Coordinates[4]+1,Coordinates[3]+5,Coordinates[4]+5,GrFill);
                    GrDrawRect(Coordinates[3]+1,Coordinates[2]+5,Coordinates[3]+5,Coordinates[4]+5,GrFill);
              END;
              DrawWindowHeader(Loop,False);
          END;
     END;
     gxVirtualVirtual(OffScreen,0,0,GraphMaxX,YWindow,WindowBack,0,0,gxSet);
     WITH SavedCutouts[1] DO
     BEGIN
          IF SavedCutouts[1].Active THEN
          BEGIN
               gxVirtualVirtual(Cutout,0,0,Coordinates[3]-Coordinates[1],
                                Coordinates[4]-Coordinates[2],OffScreen,
                                Coordinates[1],Coordinates[2],gxSet);
               GrSetFillStyle(GrFCloseDot,0,GrTrans);
               GrDrawRect(Coordinates[1]+5,Coordinates[4]+1,Coordinates[3]+5,Coordinates[4]+5,GrFill);
               GrDrawRect(Coordinates[3]+1,Coordinates[2]+5,Coordinates[3]+5,Coordinates[4]+5,GrFill);
               DrawWindowHeader(1,True);
          END;
          gxVirtualDisplay(OffScreen,Coordinates[1],Coordinates[2],Coordinates[1],
                           Coordinates[2],Coordinates[3]+5,Coordinates[4]+5,0);
     END;
     grSetVirtual(gxFalse);
     txSetVirtual(gxFalse);
END;


PROCEDURE RedrawScreen(FName: String);
VAR  LoopX       : Word;
     LoopY       : Word;
     NewBack     : Boolean;
     SavedIt     : Boolean;
     VoiceFile   : String[12];
     XShift      : Word;
     YShift      : Word;
     Loop        : Word;
     BytesRead   : Word;
LABEL              Pass1,Pass2;
BEGIN
     IF NOT(_FileExists(FName)) THEN Exit;
     SavedCutouts[1].MoveX := ScreenInfo.MoveX;
     SavedCutouts[1].MoveY := ScreenInfo.MoveY;
     XShift := Trunc((GraphMaxX-639)/2);
     YShift := Trunc((GraphMaxY-479)/2);
     ASSIGN(FRawFile,FName);
     RESET(FRawFile);
     IF SavedCutouts[1].FileName=FName THEN
     BEGIN
          GrDisplayMouse(GrHide);
          LastMouse := 1;
          ChangeMouse(DefaultMouse);
          GrSetClipRegion(0,0,GraphMaxX,YWindow);
          GrSetClipping(GrClip);
          REPEAT
                READ(FRawFile,RawFile);
                INC(RawFile.x1,XShift);
                INC(RawFile.y1,YShift);
                INC(RawFile.x2,XShift);
                INC(RawFile.y2,YShift);
                IF ScreenInfo.HasWindow THEN
                BEGIN
                     IF ((RawFile.x1>ScreenInfo.OrigX1) AND (RawFile.x1<ScreenInfo.OrigX2) AND
                        (RawFile.y1>ScreenInfo.OrigY1) AND (RawFile.y1<ScreenInfo.OrigY2)) THEN
                     BEGIN
                          RawFile.x1 := RawFile.x1+ScreenInfo.MoveX;
                          RawFile.y1 := RawFile.y1+ScreenInfo.MoveY;
                          RawFile.x2 := RawFile.x2+ScreenInfo.MoveX;
                          RawFile.y2 := RawFile.y2+ScreenInfo.MoveY;
                     END;
                END;
                CASE RawFile.Number OF
                11:  BEGIN {Window}
                          IF ((Pos('{',RawFile.Text)<>0) OR (Pos('@',RawFile.Text)<>0)) THEN
                          BEGIN
                               SavedCutouts[1].WindowDef.Text := RawFile.Text;
                               IF UsingBuffer THEN SavedCutouts[1].WindowDef.Text := ProcessBuffer(RawFile.Text);
                               DrawWindowHeader(1,True);
                          END;
                     END;
                13:  BEGIN {Text}
                          IF ((Pos('{',RawFile.Text)<>0) OR (Pos('@',RawFile.Text)<>0)) THEN
                          BEGIN
                               DoText(RawFile);
                          END;
                     END;
                21,
                28:  BEGIN {Work Areas}
                          GrSetFillStyle(GrFSolid,Colours.PickListBack,GrOpaque);
                          GrDrawRect(RawFile.x1+1,RawFile.y1+1,RawFile.x2-21,RawFile.y2-1,GrFill);
                     END;
                23:  BEGIN
                          GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                          GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrFill);
                     END;
                END;
          UNTIL ((EOF(FRawFile)) OR (Disconnected));
          GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
          GrSetClipping(GrClip);
          GrDisplayMouse(GrShow);
     END
     ELSE
     BEGIN
          IF SavedCutouts[1].FileName<>'' THEN
          BEGIN
               IF SavedCutouts[1].KeepWindow THEN
               BEGIN
                    {Move All The Windows Down The Ladder}
                    GrDisplayMouse(GrHide);
                    SaveCutout(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2,ScreenInfo.Y2,1);
                    FOR Loop := NumCutouts DOWNTO 2 DO SavedCutouts[Loop] := SavedCutouts[Loop-1];
                    DrawWindowHeader(2,False);
                    GrDisplayMouse(GrShow);
               END
               ELSE
               BEGIN
                    {Kill The Last Window Since It Was Temporary}
                    GrDisplayMouse(GrHide);
                    LoadUnderGround(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2+5,ScreenInfo.Y2+5);
                    GrDisplayMouse(GrShow);
                    KillCutout(1);
               END;
          END;
          {Clear out the old variables/screens}
          IF NCustom<>0 THEN
          BEGIN
               FOR LoopX := 1 TO NCustom DO
               BEGIN
                    gxDestroyVirtual(Custom[Loopx].Icon1);
                    gxDestroyVirtual(Custom[Loopx].Icon2);
               END;
          END;
          IF NAnimate<>0 THEN
          BEGIN
               FOR LoopX := 1 TO NAnimate DO
               BEGIN
                    gxDestroyVirtual(Animate[Loopx].Icon[1]);
                    gxDestroyVirtual(Animate[Loopx].Icon[2]);
                    gxDestroyVirtual(Animate[Loopx].Icon[3]);
                    gxDestroyVirtual(Animate[Loopx].Icon[4]);
                    gxDestroyVirtual(Animate[Loopx].Icon[5]);
                    gxDestroyVirtual(Animate[Loopx].Icon[6]);
                    gxDestroyVirtual(Animate[Loopx].Icon[7]);
                    gxDestroyVirtual(Animate[Loopx].Icon[8]);
               END;
          END;
          GrDisplayMouse(GrHide);
          LastMouse := 1;
          ChangeMouse(DefaultMouse);
          IF FoundAlreadyOnStack(FName) THEN
          BEGIN
               RebuildDeskTop;
               ScreenInfo.HasWindow  := True;
               ScreenInfo.x1         := 32000;
               ScreenInfo.y1         := 32000;
               ScreenInfo.x2         := 32000;
               ScreenInfo.y2         := 32000;
               PadX1                 := 32000;
               PadY1                 := 32000;
               PadX2                 := 32000;
               PadY2                 := 32000;

               {SYSTEM BUTTONS!}
               NButtons             := 2;
               Buttons^[1].Return    := #0;
               Buttons^[1].x1        := 8;
               Buttons^[1].y1        := YWindow+8;
               Buttons^[1].x2        := 42;
               Buttons^[1].y2        := YWindow+42;
               Buttons^[1].BType     := 1;
               Buttons^[1].FillC     := 7;
               Buttons^[1].HBorder   := 15;
               Buttons^[1].DBorder   := 8;
               Buttons^[1].Holdable  := False;
               Buttons^[2].Return    := #0;
               Buttons^[2].x1        := 43;
               Buttons^[2].y1        := YWindow+8;
               Buttons^[2].x2        := 77;
               Buttons^[2].y2        := YWindow+42;
               Buttons^[2].BType     := 1;
               Buttons^[2].FillC     := 7;
               Buttons^[2].HBorder   := 15;
               Buttons^[2].DBorder   := 8;
               Buttons^[2].Holdable  := False;

               NFields               := 0;
               NCustom               := 0;
               NAnimate              := 0;
               VoiceFile             := '';
               GrSetClipRegion(0,0,GraphMaxX,YWindow);
               GrSetClipping(GrClip);
               REPEAT
                     READ(FRawFile,RawFile);
                     INC(RawFile.x1,XShift);
                     INC(RawFile.y1,YShift);
                     INC(RawFile.x2,XShift);
                     INC(RawFile.y2,YShift);
                     CASE RawFile.Number OF
                     2:   BEGIN {SCREEN MOUSE}
                               IF RawFile.Style=1 THEN
                               BEGIN
                                    ASSIGN(FMouse,RESOURCES+RawFile.Crc32+'.MSE');
                                    RESET(FMouse);
                                    READ(FMouse,DefaultMouse);
                                    CLOSE(FMouse);
                                    ChangeMouse(DefaultMouse);
                               END;
                          END;
                     3:   IF ((RawFile.Style=1) AND (YappDef.Sound))
                             THEN VoiceFile := RawFile.Crc32+'.VOC';
                     8:   BEGIN {Normal Buttons}
                               INC(NButtons);
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].Holdable := False;
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                          END;
                     9:   BEGIN {Panel Buttons}
                               INC(NButtons);
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 2;
                               Buttons^[NButtons].Holdable := False;
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                          END;
                     10:  BEGIN {Pop Buttons}
                               INC(NButtons);
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X1+13;
                               Buttons^[NButtons].y2       := RawFile.Y1+13;
                               Buttons^[NButtons].BType    := 4;
                               Buttons^[NButtons].Holdable := False;
                          END;
                     11:  BEGIN {Window}
                               ScreenInfo.HasWindow   := True;
                               ScreenInfo.x1          := RawFile.x1+SavedCutouts[1].MoveX;
                               ScreenInfo.y1          := RawFile.y1+SavedCutouts[1].MoveY;
                               ScreenInfo.x2          := RawFile.x2+SavedCutouts[1].MoveX;
                               ScreenInfo.y2          := RawFile.y2+SavedCutouts[1].MoveY;
                               ScreenInfo.OrigX1      := RawFile.x1;
                               ScreenInfo.OrigY1      := RawFile.y1;
                               ScreenInfo.OrigX2      := RawFile.x2;
                               ScreenInfo.OrigY2      := RawFile.y2;
                               ScreenInfo.MoveX       := SavedCutouts[1].MoveX;
                               ScreenInfo.MoveY       := SavedCutouts[1].MoveY;
                          END;
                     13:  BEGIN {Text}
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               IF ((Pos('{',RawFile.Text)<>0) AND (Pos('}',RawFile.Text)<>0))
                                  THEN DoText(RawFile)
                               ELSE IF Pos('@',RawFile.Text)<>0
                                  THEN DoText(RawFile);
                          END;
                     18:  BEGIN {Progress Indicators}
                               Toggle.x1     := RawFile.x1+SavedCutouts[1].MoveX;
                               Toggle.y1     := RawFile.y1+SavedCutouts[1].MoveY;
                               Toggle.x2     := RawFile.x2+SavedCutouts[1].MoveX;
                               Toggle.y2     := RawFile.y2+SavedCutouts[1].MoveY;
                               Toggle.Colour := RawFile.Colour1;
                          END;
                     19:  BEGIN {PROMPT BOXES}
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               SystemField(RawFile);
                          END;
                     21,
                     28:  BEGIN {WORK AREAS}
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               INC(NButtons);
                               Buttons^[NButtons].Return   := #1;
                               Buttons^[NButtons].x1       := RawFile.X2-20;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y1+20;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].FillC    := 7;
                               Buttons^[NButtons].HBorder  := 15;
                               Buttons^[NButtons].DBorder  := 8;
                               Buttons^[NButtons].Holdable := True;
                               INC(NButtons);
                               Buttons^[NButtons].Return   := #2;
                               Buttons^[NButtons].x1       := RawFile.X2-20;
                               Buttons^[NButtons].y1       := RawFile.Y2-20;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].FillC    := 7;
                               Buttons^[NButtons].HBorder  := 15;
                               Buttons^[NButtons].DBorder  := 8;
                               Buttons^[NButtons].Holdable := True;
                               PickInfo.x1 := RawFile.x1;
                               PickInfo.y1 := RawFile.y1;
                               PickInfo.x2 := RawFile.x2-21;
                               PickInfo.y2 := RawFile.y2;
                          END;
                     23:  BEGIN
                               PadX1 := RawFile.x1+SavedCutouts[1].MoveX;
                               PadY1 := RawFile.y1+SavedCutouts[1].MoveY;
                               PadX2 := RawFile.x2+SavedCutouts[1].MoveX;
                               PadY2 := RawFile.y2+SavedCutouts[1].MoveY;
                               GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                               GrDrawRect(PadX1,PadY1,PadX2,PadY2,GrFill);
                          END;
                     24:  BEGIN
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               AddCustomControl(RawFile);
                          END;
                     25:  BEGIN
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               AddAnimatedControl(RawFile);
                          END;
                     27:  BEGIN {Clickable Regions}
                               INC(NButtons);
                               RawFile.x1 := RawFile.x1+SavedCutouts[1].MoveX;
                               RawFile.y1 := RawFile.y1+SavedCutouts[1].MoveY;
                               RawFile.x2 := RawFile.x2+SavedCutouts[1].MoveX;
                               RawFile.y2 := RawFile.y2+SavedCutouts[1].MoveY;
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 3;
                               Buttons^[NButtons].Holdable := False;
                          END;
                     END;
               UNTIL ((EOF(FRawFile)) OR (Disconnected));
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
               IF NFields<>0 THEN DrawFields;
               IF ((VoiceFile<>'') AND (YappDef.Sound)) THEN PlayVocFile(RESOURCES+VoiceFile);
               GrDisplayMouse(GrShow);
          END
          ELSE
          BEGIN
               SavedCutouts[1].KeepWindow := True;
               SavedCutouts[1].FileName   := FName;
               SavedCutouts[1].Active     := False;
               ScreenInfo.HasWindow       := False;
               ScreenInfo.x1              := 32000;
               ScreenInfo.y1              := 32000;
               ScreenInfo.x2              := 32000;
               ScreenInfo.y2              := 32000;
               PadX1                      := 32000;
               PadY1                      := 32000;
               PadX2                      := 32000;
               PadY2                      := 32000;

               {SYSTEM BUTTONS!}
               NButtons             := 2;
               Buttons^[1].Return    := #0;
               Buttons^[1].x1        := 8;
               Buttons^[1].y1        := YWindow+8;
               Buttons^[1].x2        := 42;
               Buttons^[1].y2        := YWindow+42;
               Buttons^[1].BType     := 1;
               Buttons^[1].FillC     := 7;
               Buttons^[1].HBorder   := 15;
               Buttons^[1].DBorder   := 8;
               Buttons^[1].Holdable  := False;
               Buttons^[2].Return    := #0;
               Buttons^[2].x1        := 43;
               Buttons^[2].y1        := YWindow+8;
               Buttons^[2].x2        := 77;
               Buttons^[2].y2        := YWindow+42;
               Buttons^[2].BType     := 1;
               Buttons^[2].FillC     := 7;
               Buttons^[2].HBorder   := 15;
               Buttons^[2].DBorder   := 8;
               Buttons^[2].Holdable  := False;

               NFields                    := 0;
               NCustom                    := 0;
               NAnimate                   := 0;
               NewBack                    := False;
               SavedIt                    := False;
               VoiceFile                  := '';
               GrSetClipRegion(0,0,GraphMaxX,YWindow);
               GrSetClipping(GrClip);
               REPEAT
                     READ(FRawFile,RawFile);
                     INC(RawFile.x1,XShift);
                     INC(RawFile.y1,YShift);
                     INC(RawFile.x2,XShift);
                     INC(RawFile.y2,YShift);
                     CASE RawFile.Number OF
                     1:   BEGIN {SCREEN BACKGROUND}
                               CASE RawFile.Style OF
                               0:   BEGIN {SOLID}
                                         NewBack := True;
                                         GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                                         GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                                    END;
                               1:   BEGIN {ICON}
                                         NewBack := True;
                                         GrSetFillStyle(GrFSolid,0,GrOpaque);
                                         GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
                                         IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.ICO'))
                                            THEN RequestResource(RawFile.Crc32+'.ICO');
                                         ASSIGN(FIcon30,RESOURCES+RawFile.Crc32+'.ICO');
                                         RESET(FIcon30);
                                         READ(FIcon30,Icon30);
                                         CLOSE(FIcon30);
                                         gxDisplayVirtual(0,0,29,29,0,IconHdr,0,0);
                                         grSetActiveVirtual(IconHdr);
                                         grSetVirtual(gxTrue);
                                         WITH Icon30 DO
                                         BEGIN
                                          FOR LoopX := 0 TO 29 DO
                                           FOR loopY := 0 TO 29 DO
                                            IF Matrix[loopX+1,loopY+1]<>255 THEN
                                             GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                                         END;
                                         grSetVirtual(gxFalse);
                                         gxVirtualDisplay(IconHdr,0,0,0,0,29,29,0);
                                         Get(0,0,29,29);
                                         LoopX := 30;
                                         REPEAT
                                               Put(LoopX,0,True,False);
                                               INC(LoopX,30);
                                         UNTIL (LoopX>GraphMaxX);
                                         Put(0,0,True,True);
                                         Get(0,0,GraphMaxX,29);
                                         LoopY := 30;
                                         REPEAT
                                               Put(0,LoopY,True,False);
                                               INC(LoopY,30);
                                         UNTIL (LoopY>YWindow);
                                         Put(0,0,True,True);
                                    END;
                               3:   BEGIN
                                         NewBack := True;
                                         IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.IMG'))
                                            THEN RequestResource(RawFile.Crc32+'.IMG');
                                         TileGraphicFile(RESOURCES+RawFile.Crc32+'.IMG');
                                    END;
                               END;
                          END;
                     2:   BEGIN {SCREEN MOUSE}
                               IF RawFile.Style=1 THEN
                               BEGIN
                                    IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.MSE'))
                                       THEN RequestResource(RawFile.Crc32+'.MSE');
                                    ASSIGN(FMouse,RESOURCES+RawFile.Crc32+'.MSE');
                                    RESET(FMouse);
                                    READ(FMouse,DefaultMouse);
                                    CLOSE(FMouse);
                                    ChangeMouse(DefaultMouse);
                               END;
                          END;
                     3:   BEGIN {SCREEN SOUND}
                               IF RawFile.Style=1 THEN
                               BEGIN
                                    IF YappDef.Sound THEN
                                    BEGIN
                                         IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.VOC'))
                                            THEN RequestResource(RawFile.Crc32+'.VOC');
                                         VoiceFile := RawFile.Crc32+'.VOC';
                                    END;
                               END;
                          END;
                     4:   BEGIN {LINES}
                               GrSetColor(RawFile.colour1);
                               GrSetLineStyle(GrLSolid,RawFile.colour2);
                               GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                               GrSetLineStyle(GrLSolid,1);
                          END;
                     5:   BEGIN {RECTANGLES}
                               IF RawFile.Colour2=255 THEN
                               BEGIN
                                    IF RawFile.Colour1<>255 THEN
                                    BEGIN
                                         GrSetColor(RawFile.colour1);
                                         GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline);
                                    END;
                               END
                               ELSE
                               BEGIN
                                    IF RawFile.Colour1=255 THEN
                                    BEGIN
                                         GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                                         GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                                    END
                                    ELSE
                                    BEGIN
                                         GrSetColor(RawFile.colour1);
                                         GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                                         GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                                    END;
                               END;
                          END;
                     6:   BEGIN {ELLIPSES}
                               IF RawFile.Colour2=255 THEN
                               BEGIN
                                    IF RawFile.Colour1<>255 THEN
                                    BEGIN
                                         DEC(RawFile.x2,XShift);
                                         DEC(RawFile.y2,YShift);
                                         GrSetColor(RawFile.colour1);
                                         GrDrawEllipse(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline);
                                    END;
                               END
                               ELSE
                               BEGIN
                                    IF RawFile.Colour1=255 THEN
                                    BEGIN
                                         DEC(RawFile.x2,XShift);
                                         DEC(RawFile.y2,YShift);
                                         GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                                         GrDrawEllipse(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                                    END
                                    ELSE
                                    BEGIN
                                         DEC(RawFile.x2,XShift);
                                         DEC(RawFile.y2,YShift);
                                         GrSetColor(RawFile.colour1);
                                         GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                                         GrDrawEllipse(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                                    END;
                               END;
                          END;
                     7:   BEGIN {FLOODFILL}
                               GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                               GrFloodSpill(RawFile.x1,RawFile.y1);
                          END;
                     8:   BEGIN {Normal Buttons}
                               INC(NButtons);
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].Holdable := False;
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               GrSetColor(0);
                               GrSetFillStyle(GrFSolid,Buttons^[NButtons].FillC,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                               GrSetColor(Buttons^[NButtons].DBorder);
                               GrDrawLine(RawFile.X1+1,RawFile.Y2-1,RawFile.X2-1,RawFile.Y2-1);
                               GrDrawLine(RawFile.X2-1,RawFile.Y1+1,RawFile.X2-1,RawFile.Y2-1);
                               GrSetColor(Buttons^[NButtons].HBorder);
                               GrDrawLine(RawFile.X1+1,RawFile.Y1+1,RawFile.X1+1,RawFile.Y2-1);
                               GrDrawLine(RawFile.X1+1,RawFile.Y1+1,RawFile.X2-1,RawFile.Y1+1);
                          END;
                     9:   BEGIN {Panel Buttons}
                               INC(NButtons);
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 2;
                               Buttons^[NButtons].Holdable := False;
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               GrSetFillStyle(GrFSolid,Buttons^[NButtons].FillC,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                               GrSetColor(Buttons^[NButtons].HBorder);
                               GrDrawRect(RawFile.X1+1,RawFile.Y1+1,RawFile.X2,RawFile.Y2,GrOutline);
                               GrSetColor(Buttons^[NButtons].DBorder);
                               GrDrawLine(RawFile.X1,RawFile.Y1,RawFile.X1,RawFile.Y2);
                               GrDrawLine(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y1);
                               GrDrawLine(RawFile.X1+2,RawFile.Y2-1,RawFile.X2-1,RawFile.Y2-1);
                               GrDrawLine(RawFile.X2-1,RawFile.Y1+2,RawFile.X2-1,RawFile.Y2-1);
                          END;
                     10:  BEGIN {Pop Buttons}
                               INC(NButtons);
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X1+13;
                               Buttons^[NButtons].y2       := RawFile.Y1+13;
                               Buttons^[NButtons].BType    := 4;
                               Buttons^[NButtons].Holdable := False;
                               SystemIcon(RawFile.x1,RawFile.y1,21);
                          END;
                     11:  BEGIN {Window}
                               IF ((NewBack) AND (NOT(SavedIt))) THEN
                               BEGIN
                                    KillBackDrop;
                                    SaveBackDrop;
                                    SavedIt := True;
                                    FOR Loop := NumCutouts DOWNTO 2 DO LoadCutout(Loop);
                               END;
                               SaveUnderGround;
                               ScreenInfo.HasWindow   := True;
                               ScreenInfo.x1          := RawFile.x1;
                               ScreenInfo.y1          := RawFile.y1;
                               ScreenInfo.x2          := RawFile.x2;
                               ScreenInfo.y2          := RawFile.y2;
                               ScreenInfo.OrigX1      := RawFile.x1;
                               ScreenInfo.OrigY1      := RawFile.y1;
                               ScreenInfo.OrigX2      := RawFile.x2;
                               ScreenInfo.OrigY2      := RawFile.y2;
                               ScreenInfo.MoveX       := 0;
                               ScreenInfo.MoveY       := 0;
                               CASE RawFile.Colour9 OF
                               0:   SavedCutouts[1].KeepWindow := False;
                               1:   SavedCutouts[1].KeepWindow := True;
                               END;
                               SavedCutouts[1].WindowDef := RawFile;
                               SavedCutouts[1].WindowDef.Text := ProcessBuffer(RawFile.Text);
                               DrawTheWindow(RawFile);
                          END;
                     12:  BEGIN {Icon}
                               IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.ICO'))
                                  THEN RequestResource(RawFile.Crc32+'.ICO');
                               DrawIcon(RawFile.X1,RawFile.Y1,RawFile.Colour1,
                                        RawFile.Style,RawFile.Colour3,RawFile.Crc32+'.ICO');
                          END;
                     13:  BEGIN {Text}
                               IF RawFile.Colour7=0 THEN
                               BEGIN
                                    IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.FNT'))
                                       THEN RequestResource(RawFile.Crc32+'.FNT');
                               END;
                               DoText(RawFile);
                          END;
                     14:  BEGIN {POLYLINES}
                               GrSetColor(RawFile.colour1);
                               GrSetLineStyle(GrLSolid,RawFile.colour2);
                               GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                               REPEAT
                                     READ(FRawFile,RawFile);
                                     INC(RawFile.x1,XShift);
                                     INC(RawFile.y1,YShift);
                                     INC(RawFile.x2,XShift);
                                     INC(RawFile.y2,YShift);
                                     GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                               UNTIL RawFile.Style=255;
                               GrSetLineStyle(GrLSolid,1);
                          END;
                     15:  BEGIN {POLYGONS}
                               GrSetColor(RawFile.colour1);
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               LoopX := 2;
                               PolyPoint^[0] := RawFile.x1;
                               PolyPoint^[1] := RawFile.y1;
                               REPEAT
                                     READ(FRawFile,RawFile);
                                     INC(RawFile.x1,XShift);
                                     INC(RawFile.y1,YShift);
                                     INC(RawFile.x2,XShift);
                                     INC(RawFile.y2,YShift);
                                     IF (LoopX+2>PolySize) THEN GOTO Pass1;
                                     IF RawFile.Style<>255 THEN
                                     BEGIN
                                          PolyPoint^[LoopX] := RawFile.x1; INC(LoopX);
                                          PolyPoint^[LoopX] := RawFile.y1; INC(LoopX);
                                     END;
                               UNTIL RawFile.Style=255;
                               PolyPoint^[LoopX] := RawFile.x1; INC(LoopX);
                               PolyPoint^[LoopX] := RawFile.y1; INC(LoopX);
                               PolyPoint^[LoopX] := RawFile.x2; INC(LoopX);
                               PolyPoint^[LoopX] := RawFile.y2; INC(LoopX);
                               IF RawFile.colour1=255
                                  THEN GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrFill)
                                  ELSE GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrOutline+GrFill);
                               Pass1:
                          END;
                     16:  BEGIN {BEZIER CURVES}
                               GrSetColor(RawFile.colour1);
                               GrSetLineStyle(GrLSolid,RawFile.colour2);
                               INC(RawFile.Colour3,XShift);
                               INC(RawFile.Colour4,YShift);
                               INC(RawFile.Colour5,XShift);
                               INC(RawFile.Colour6,YShift);
                               GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                            RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               REPEAT
                                     READ(FRawFile,RawFile);
                                     INC(RawFile.x1,XShift);
                                     INC(RawFile.y1,YShift);
                                     INC(RawFile.x2,XShift);
                                     INC(RawFile.y2,YShift);
                                     INC(RawFile.Colour3,XShift);
                                     INC(RawFile.Colour4,YShift);
                                     INC(RawFile.Colour5,XShift);
                                     INC(RawFile.Colour6,YShift);
                                     GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                                  RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               UNTIL RawFile.Style=255;
                               GrSetLineStyle(GrLSolid,1);
                          END;
                     17:  BEGIN {BEZIER OBJECTS}
                               GrSetColor(RawFile.colour1);
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               WorkWord := 0;
                               INC(RawFile.Colour3,XShift);
                               INC(RawFile.Colour4,YShift);
                               INC(RawFile.Colour5,XShift);
                               INC(RawFile.Colour6,YShift);
                               AddToBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                           RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               REPEAT
                                     READ(FRawFile,RawFile);
                                     INC(RawFile.x1,XShift);
                                     INC(RawFile.y1,YShift);
                                     INC(RawFile.x2,XShift);
                                     INC(RawFile.y2,YShift);
                                     INC(RawFile.Colour3,XShift);
                                     INC(RawFile.Colour4,YShift);
                                     INC(RawFile.Colour5,XShift);
                                     INC(RawFile.Colour6,YShift);
                                     IF (LoopX+2>PolySize) THEN GOTO Pass2;
                                     AddToBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                                 RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               UNTIL RawFile.Style=255;
                               IF RawFile.colour1=255
                                  THEN GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill)
                                  ELSE GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill+GrOutline);
                               Pass2:
                          END;
                     18:  BEGIN {Progress Indicators}
                               Toggle.x1     := RawFile.x1;
                               Toggle.y1     := RawFile.y1;
                               Toggle.x2     := RawFile.x2;
                               Toggle.y2     := RawFile.y2;
                               Toggle.Colour := RawFile.Colour1;
                          END;
                     19:  BEGIN {PROMPT BOXES}
                               SystemField(RawFile);
                          END;
                     20:  BEGIN {DIMENSION FRAMES}
                               GrSetColor(RawFile.Colour2);
                               GrDrawLine(RawFile.x1,RawFile.y2,RawFile.x2,RawFile.y2);
                               GrDrawLine(RawFile.x2,RawFile.y1,RawFile.x2,RawFile.y2);
                               GrSetColor(RawFile.Colour1);
                               GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y1);
                               GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x1,RawFile.y2);
                          END;
                     21,
                     28:  BEGIN {WORK AREAS}
                               INC(NButtons);
                               Buttons^[NButtons].Return   := #1;
                               Buttons^[NButtons].x1       := RawFile.X2-20;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y1+20;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].FillC    := 7;
                               Buttons^[NButtons].HBorder  := 15;
                               Buttons^[NButtons].DBorder  := 8;
                               Buttons^[NButtons].Holdable := True;
                               INC(NButtons);
                               Buttons^[NButtons].Return   := #2;
                               Buttons^[NButtons].x1       := RawFile.X2-20;
                               Buttons^[NButtons].y1       := RawFile.Y2-20;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 1;
                               Buttons^[NButtons].FillC    := 7;
                               Buttons^[NButtons].HBorder  := 15;
                               Buttons^[NButtons].DBorder  := 8;
                               Buttons^[NButtons].Holdable := True;
                               PickInfo.x1 := RawFile.x1;
                               PickInfo.y1 := RawFile.y1;
                               PickInfo.x2 := RawFile.x2-21;
                               PickInfo.y2 := RawFile.y2;
                               GrSetColor(0);
                               GrSetFillStyle(GrFSolid,Colours.PickListBack,GrOpaque);
                               GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline+GrFill);
                               GrSetFillStyle(GrFSolid,7,GrOpaque);
                               GrDrawRect(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y2-1,GrFill);
                               GrDrawLine(RawFile.x2-20,RawFile.y1,RawFile.x2-20,RawFile.y2);
                               GrDrawLine(RawFile.x2-20,RawFile.y1+20,RawFile.x2,RawFile.y1+20);
                               GrDrawLine(RawFile.x2-20,RawFile.y2-20,RawFile.x2,RawFile.y2-20);
                               RaisedBox(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y1+19);
                               RaisedBox(RawFile.x2-19,RawFile.y2-19,RawFile.x2-1,RawFile.y2-1);
                          END;
                     22:  BEGIN {GRAPHIC IMAGES}
                               IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.IMG'))
                                  THEN RequestResource(RawFile.Crc32+'.IMG');
                               LoadGraphicFile(RESOURCES+RawFile.Crc32+'.IMG',RawFile.x1,RawFile.y1,
                                               RawFile.x2,RawFile.y2,RawFile.Colour2,RawFile.Colour1,RawFile.Colour3,True);
                          END;
                     23:  BEGIN
                               PadX1 := RawFile.x1;
                               PadY1 := RawFile.y1;
                               PadX2 := RawFile.x2;
                               PadY2 := RawFile.y2;
                          END;
                     24:  BEGIN
                               IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.CC'))
                                  THEN RequestResource(RawFile.Crc32+'.CC');
                               AddCustomControl(RawFile);
                          END;
                     25:  BEGIN
                               IF NOT(_FileExists(RESOURCES+RawFile.Crc32+'.ANI'))
                                  THEN RequestResource(RawFile.Crc32+'.ANI');
                               AddAnimatedControl(RawFile);
                          END;
                     26:  BEGIN {PLAIN ARCS}
                               GrSetColor(RawFile.colour1);
                               GrSetLineStyle(GrLSolid,RawFile.colour2);
                               INC(RawFile.Colour3,XShift);
                               INC(RawFile.Colour4,YShift);
                               INC(RawFile.Colour5,XShift);
                               INC(RawFile.Colour6,YShift);
                               GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                            RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               GrSetLineStyle(GrLSolid,1);
                          END;
                     27:  BEGIN {Clickable Regions}
                               INC(NButtons);
                               Buttons^[NButtons].Return   := RawFile.Return;
                               Buttons^[NButtons].x1       := RawFile.X1;
                               Buttons^[NButtons].y1       := RawFile.Y1;
                               Buttons^[NButtons].x2       := RawFile.X2;
                               Buttons^[NButtons].y2       := RawFile.Y2;
                               Buttons^[NButtons].BType    := 3;
                               Buttons^[NButtons].Holdable := False;
                          END;
                     END;
               UNTIL ((EOF(FRawFile)) OR (Disconnected));
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
               IF NOT(DidOneYet) THEN
               BEGIN
                    SaveBackDrop;
                    DidOneYet := True;
               END;
               IF NFields<>0 THEN DrawFields;
               IF ((VoiceFile<>'') AND (YappDef.Sound)) THEN PlayVocFile(RESOURCES+VoiceFile);
               GrDisplayMouse(GrShow);
          END;
     END;
     CLOSE(FRawFile);
END;


FUNCTION UnpackTheGIP(VAR FName: String): Boolean;
TYPE DecompBuffer  = Array[1..8192] Of Byte;
VAR  Buffer        : ^DecompBuffer;
     FFile         : File;
     FFile2        : File;
     GIPHeader     : _GIPHeader;
     GIPFileHeader : _GIPFileHeader;
     GetBytes      : Longint;
     OutFile       : String;
BEGIN
     IF _FileExists(FName) THEN
     BEGIN
          New(Buffer);
          ASSIGN(FFile,FName);
          RESET(FFile,1);
          BLOCKREAD(FFile,GIPHeader,SizeOf(GIPHeader));
          REPEAT
                BLOCKREAD(FFile,GIPFileHeader,SizeOf(GIPFileHeader));
                GetBytes := GIPFileHeader.FileLength;
                ASSIGN(FFile2,GIP_Directory+'COMPRESS.TMP');
                REWRITE(FFile2,1);
                REPEAT
                      IF GetBytes>SizeOf(Buffer^) THEN
                      BEGIN
                           BLOCKREAD(FFile,Buffer^,SizeOf(Buffer^));
                           BLOCKWRITE(FFile2,Buffer^,SizeOf(Buffer^));
                           DEC(GetBytes,SizeOf(Buffer^));
                      END
                      ELSE
                      BEGIN
                           BLOCKREAD(FFile,Buffer^,GetBytes);
                           BLOCKWRITE(FFile2,Buffer^,GetBytes);
                           GetBytes := 0;
                      END;
                UNTIL (GetBytes=0);
                CLOSE(FFile2);
                OutFile := GIP_Directory+GIPFileHeader.FName;
                IF _GetFileExtension(GIPFileHeader.FName)='SG'
                   THEN FName := GIP_Directory+GIPFileHeader.FName;
                pDecompressFile(GIP_Directory+'COMPRESS.TMP',OutFile);
                _EraseFile(GIP_Directory+'COMPRESS.TMP');
          UNTIL EOF(FFile);
          CLOSE(FFile);
          Dispose(Buffer);
          UnpackTheGIP := True;
     END
     ELSE UnpackTheGIP := False;
END;


END.
