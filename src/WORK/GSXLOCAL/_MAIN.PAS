{$I DEFINES.INC}
UNIT _Main;


INTERFACE


FUNCTION  FoundAlreadyOnStack (InString: String): Boolean;
PROCEDURE RedrawScreen        (FName: String; IsTemporary: Boolean);
PROCEDURE RebuildDeskTop;


IMPLEMENTATION


USES Gx2_Bp,Gx2_BpVC,Gr2_Bp,Tx2_Bp,Globals,BsGraph,SBuffer,_Win,_Mouse,
     _Text,_Buffers,_Fields,_Icons,_Save,_Images,_Bezier,Execute,Special,
     _Virtual,BsFile;


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
{==========================================================================}
{                                                                          }
{    Rebuilds The Desktop Offscreen, Then Zaps It To The Display           }
{                                                                          }
{==========================================================================}
PROCEDURE RebuildDeskTop;
VAR  Loop    : Word;
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
               gxVirtualVirtual(SavedCutouts[Loop].Cutout,0,0,
                                SavedCutouts[Loop].Coordinates[3]-SavedCutouts[Loop].Coordinates[1],
                                SavedCutouts[Loop].Coordinates[4]-SavedCutouts[Loop].Coordinates[2],
                                OffScreen,SavedCutouts[Loop].Coordinates[1],
                                SavedCutouts[Loop].Coordinates[2],gxSet);
              {Draw the shadow}
              GrSetFillStyle(GrFCloseDot,0,GrTrans);
              GrDrawRect(SavedCutouts[Loop].Coordinates[1]+5,
                         SavedCutouts[Loop].Coordinates[4]+1,
                         SavedCutouts[Loop].Coordinates[3]+5,
                         SavedCutouts[Loop].Coordinates[4]+5,GrFill);
              GrDrawRect(SavedCutouts[Loop].Coordinates[3]+1,
                         SavedCutouts[Loop].Coordinates[2]+5,
                         SavedCutouts[Loop].Coordinates[3]+5,
                         SavedCutouts[Loop].Coordinates[4]+5,GrFill);
              DrawWindowHeader(Loop,False);
          END;
     END;
     gxVirtualVirtual(OffScreen,0,0,GraphMaxX,YWindow,WindowBack,0,0,gxSet);
     IF SavedCutouts[1].Active THEN
     BEGIN
          gxVirtualVirtual(SavedCutouts[1].Cutout,0,0,
                           SavedCutouts[1].Coordinates[3]-SavedCutouts[1].Coordinates[1],
                           SavedCutouts[1].Coordinates[4]-SavedCutouts[1].Coordinates[2],
                           OffScreen,SavedCutouts[1].Coordinates[1],
                           SavedCutouts[1].Coordinates[2],gxSet);
          GrSetFillStyle(GrFCloseDot,0,GrTrans);
          GrDrawRect(SavedCutouts[1].Coordinates[1]+5,
                     SavedCutouts[1].Coordinates[4]+1,
                     SavedCutouts[1].Coordinates[3]+5,
                     SavedCutouts[1].Coordinates[4]+5,GrFill);
          GrDrawRect(SavedCutouts[1].Coordinates[3]+1,
                     SavedCutouts[1].Coordinates[2]+5,
                     SavedCutouts[1].Coordinates[3]+5,
                     SavedCutouts[1].Coordinates[4]+5,GrFill);
          DrawWindowHeader(1,True);
     END;
     gxVirtualDisplay(OffScreen,
                      SavedCutouts[1].Coordinates[1],
                      SavedCutouts[1].Coordinates[2],
                      SavedCutouts[1].Coordinates[1],
                      SavedCutouts[1].Coordinates[2],
                      SavedCutouts[1].Coordinates[3]+5,
                      SavedCutouts[1].Coordinates[4]+5,0);
     grSetVirtual(gxFalse);
     txSetVirtual(gxFalse);
END;
{==========================================================================}
{                                                                          }
{    Redraws the screen                                                    }
{                                                                          }
{==========================================================================}
PROCEDURE RedrawScreen(FName: String; IsTemporary: Boolean);
VAR  LoopX       : Word;
     LoopY       : Word;
     NewBack     : Boolean;
     SavedIt     : Boolean;
     XShift      : Word;
     YShift      : Word;
     VoiceFile   : String[12];
     Loop        : Word;
BEGIN
     SavedCutouts[1].MoveX := ScreenInfo.MoveX;
     SavedCutouts[1].MoveY := ScreenInfo.MoveY;
     XShift := Trunc((GraphMaxX-639)/2);
     YShift := Trunc((GraphMaxY-479)/2);
     ASSIGN(FRawFile,FName);
     RESET(FRawFile);
     IF SavedCutouts[1].FileName=FName THEN
     BEGIN
          HideTheMouse;
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
          UNTIL EOF(FRawFile);
          GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
          GrSetClipping(GrClip);
          ShowTheMouse;
     END
     ELSE
     BEGIN
          IF SavedCutouts[1].FileName<>'' THEN
          BEGIN
               IF SavedCutouts[1].KeepWindow THEN
               BEGIN
                    {Move All The Windows Down The Ladder}
                    HideTheMouse;
                    SaveCutout(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2,ScreenInfo.Y2,1);
                    FOR Loop := NumCutouts DOWNTO 2 DO SavedCutouts[Loop] := SavedCutouts[Loop-1];
                    DrawWindowHeader(2,False);
                    ShowTheMouse;
               END
               ELSE
               BEGIN
                    {Kill The Last Window Since It Was Temporary}
                    HideTheMouse;
                    LoadUnderGround(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2+5,ScreenInfo.Y2+5);
                    ShowTheMouse;
                    KillCutout(1);
               END;
          END;
          {Clear out the old variables/screens}
          IF NCustom<>0 THEN
          BEGIN
               FOR LoopX := 1 TO NCustom DO
               BEGIN
                    DestroyVirtual(Custom^[Loopx].Icon1);
                    DestroyVirtual(Custom^[Loopx].Icon2);
               END;
          END;
          IF NAnimate<>0 THEN
          BEGIN
               FOR LoopX := 1 TO NAnimate DO
               BEGIN
                    DestroyVirtual(Animate^[Loopx].Icon[1]);
                    DestroyVirtual(Animate^[Loopx].Icon[2]);
                    DestroyVirtual(Animate^[Loopx].Icon[3]);
                    DestroyVirtual(Animate^[Loopx].Icon[4]);
                    DestroyVirtual(Animate^[Loopx].Icon[5]);
                    DestroyVirtual(Animate^[Loopx].Icon[6]);
                    DestroyVirtual(Animate^[Loopx].Icon[7]);
                    DestroyVirtual(Animate^[Loopx].Icon[8]);
               END;
          END;
          HideTheMouse;
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
               NButtons              := 2;
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
                                    {$I-}
                                    RESET(FMouse);
                                    {$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         READ(FMouse,DefaultMouse);
                                         CLOSE(FMouse);
                                         ChangeMouse(DefaultMouse);
                                    END;
                               END;
                          END;
                     3:   IF RawFile.Style=1 THEN VoiceFile := RawFile.Crc32+'.VOC';
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
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               Buttons^[NButtons].Holdable := False;
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
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               Buttons^[NButtons].Holdable := False;
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
                               IF (Process_Special(RawFile.Text,False)<>RawFile.Text)
                                  THEN DoText(RawFile)
                               ELSE IF Pos('@',RawFile.Text)<>0
                                  THEN DoText(RawFile);
                          END;
                     18:  BEGIN {Progress Indicators}
                               ToggleInfo.x1     := RawFile.x1+SavedCutouts[1].MoveX;
                               ToggleInfo.y1     := RawFile.y1+SavedCutouts[1].MoveY;
                               ToggleInfo.x2     := RawFile.x2+SavedCutouts[1].MoveX;
                               ToggleInfo.y2     := RawFile.y2+SavedCutouts[1].MoveY;
                               ToggleInfo.Colour := RawFile.Colour1;
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
                               IF RawFile.Number=28 THEN ThePickFile := RawFile.Text;
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
               UNTIL EOF(FRawFile);
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
               IF NFields<>0 THEN DrawFields;
               ShowTheMouse;
               IF VoiceFile<>'' THEN
               BEGIN
                    IF NodeInfo^.UseBlaster THEN
                    BEGIN
                         Save_Mouse;
                         ExecuteDOSCommand(Bin_Directory+'\PLAYVOC.EXE '+RESOURCES+VoiceFile+' $$BB$$SS$$');
                         Load_Mouse;
                    END;
               END;
          END
          ELSE
          BEGIN
               IF IsTemporary THEN SavedCutouts[1].KeepWindow := False
                              ELSE SavedCutouts[1].KeepWindow := True;
               SavedCutouts[1].FileName := FName;
               SavedCutouts[1].Active   := False;
               ScreenInfo.HasWindow     := False;
               ScreenInfo.x1            := 32000;
               ScreenInfo.y1            := 32000;
               ScreenInfo.x2            := 32000;
               ScreenInfo.y2            := 32000;
               PadX1                    := 32000;
               PadY1                    := 32000;
               PadX2                    := 32000;
               PadY2                    := 32000;

               {SYSTEM BUTTONS!}
               NButtons              := 2;
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

               NFields                  := 0;
               NCustom                  := 0;
               NAnimate                 := 0;
               NewBack                  := False;
               SavedIt                  := False;
               VoiceFile                := '';
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
                                         IF _FileExists(RESOURCES+RawFile.Crc32+'.ICO') THEN
                                         BEGIN
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
                                                    Put(LoopX,0,False);
                                                    INC(LoopX,30);
                                              UNTIL (LoopX>GraphMaxX);
                                              Put(0,0,True);
                                              Get(0,0,GraphMaxX,29);
                                              LoopY := 30;
                                              REPEAT
                                                    Put(0,LoopY,False);
                                                    INC(LoopY,30);
                                              UNTIL (LoopY>YWindow);
                                              Put(0,0,True);
                                         END;
                                    END;
                               3:   BEGIN
                                         NewBack := True;
                                         TileGraphicFile(RESOURCES+RawFile.Crc32+'.IMG');
                                    END;
                               END;
                          END;
                     2:   BEGIN {SCREEN MOUSE}
                               IF RawFile.Style=1 THEN
                               BEGIN
                                    ASSIGN(FMouse,RESOURCES+RawFile.Crc32+'.MSE');
                                    {$I-}
                                    RESET(FMouse);
                                    {$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         READ(FMouse,DefaultMouse);
                                         CLOSE(FMouse);
                                         ChangeMouse(DefaultMouse);
                                    END;
                               END;
                          END;
                     3:   BEGIN {SCREEN SOUND}
                               IF RawFile.Style=1 THEN VoiceFile := RawFile.Crc32+'.VOC';
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
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               Buttons^[NButtons].Holdable := False;
                               GrSetColor(0);
                               GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                               GrSetColor(RawFile.Colour3);
                               GrDrawLine(RawFile.X1+1,RawFile.Y2-1,RawFile.X2-1,RawFile.Y2-1);
                               GrDrawLine(RawFile.X2-1,RawFile.Y1+1,RawFile.X2-1,RawFile.Y2-1);
                               GrSetColor(RawFile.Colour2);
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
                               Buttons^[NButtons].FillC    := RawFile.Colour1;
                               Buttons^[NButtons].HBorder  := RawFile.Colour2;
                               Buttons^[NButtons].DBorder  := RawFile.Colour3;
                               Buttons^[NButtons].Holdable := False;
                               GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                               GrSetColor(RawFile.Colour2);
                               GrDrawRect(RawFile.X1+1,RawFile.Y1+1,RawFile.X2,RawFile.Y2,GrOutline);
                               GrSetColor(RawFile.Colour3);
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
                               IF NOT(IsTemporary) THEN
                               BEGIN
                                    CASE RawFile.Colour9 OF
                                    0:   SavedCutouts[1].KeepWindow := False;
                                    1:   SavedCutouts[1].KeepWindow := True;
                                    END;
                               END;
                               SavedCutouts[1].WindowDef := RawFile;
                               IF UsingBuffer THEN SavedCutouts[1].WindowDef.Text := ProcessBuffer(RawFile.Text);
                               DrawTheWindow(RawFile);
                          END;
                     12:  BEGIN {Icon}
                               DrawIcon(RawFile.X1,RawFile.Y1,RawFile.Colour1,
                                        RawFile.Style,RawFile.Colour3,RawFile.Crc32+'.ICO');
                          END;
                     13:  BEGIN {Text}
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
                                     AddToBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                                 RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                               UNTIL RawFile.Style=255;
                               IF RawFile.colour1=255
                                  THEN GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill)
                                  ELSE GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill+GrOutline);
                          END;
                     18:  BEGIN {Progress Indicators}
                               ToggleInfo.x1     := RawFile.x1;
                               ToggleInfo.y1     := RawFile.y1;
                               ToggleInfo.x2     := RawFile.x2;
                               ToggleInfo.y2     := RawFile.y2;
                               ToggleInfo.Colour := RawFile.Colour1;
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
                               IF RawFile.Number=28 THEN ThePickFile := RawFile.Text;
                          END;
                     22:  BEGIN {GRAPHIC IMAGES}
                               LoadGraphicFile(RESOURCES+RawFile.Crc32+'.IMG',RawFile.x1,RawFile.y1,
                                               RawFile.x2,RawFile.y2,RawFile.Colour2,RawFile.Colour1,
                                               RawFile.Colour3,True);
                          END;
                     23:  BEGIN
                               PadX1 := RawFile.x1;
                               PadY1 := RawFile.y1;
                               PadX2 := RawFile.x2;
                               PadY2 := RawFile.y2;
                          END;
                     24:  AddCustomControl(RawFile);
                     25:  AddAnimatedControl(RawFile);
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
               UNTIL EOF(FRawFile);
               GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
               GrSetClipping(GrClip);
               IF NFields<>0 THEN DrawFields;
               ShowTheMouse;
               IF VoiceFile<>'' THEN
               BEGIN
                    IF NodeInfo^.UseBlaster THEN
                    BEGIN
                         Save_Mouse;
                         ExecuteDOSCommand(Bin_Directory+'\PLAYVOC.EXE '+RESOURCES+VoiceFile+' $$BB$$SS$$');
                         Load_Mouse;
                    END;
               END;
          END;
     END;
     CLOSE(FRawFile);
END;


END.
