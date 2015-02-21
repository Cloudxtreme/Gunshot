{$I DEFINES.INC}
UNIT _Pop;


INTERFACE


FUNCTION DoPopUp: Word;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,_Text,BHandler,_Icons,WinDefs,Shotgun,BsFile,
     _FSelect,BsString,_VSave,Gx2_Bp,Img2_Bp,BsGraph,_GoodWin;


FUNCTION DoPopUp: Word;
VAR  WorkSG2  : _Raw_File;
     FWorkSG2 : File Of _Raw_File;
     x,y      : Word;
     LoopX    : Word;
     Counter  : Word;
     C        : Word;
     NewTool  : Boolean;
     Temp     : String;
     What     : Word;
     dipal    : Array[0..767] Of Byte;
     c1,c2,c3 : Integer;
LABEL           SkipSave,SkipSave2;
BEGIN
     DoARedraw := False;
     IF MouseOn THEN GrDisplayMouse(GrHide);
     SaveWindow(3);
     NButtons := 0;
     DrawWindow(400,170,600,410,'DRAWING TOOLS',FloatingMenu);
     OutTextXY(420,200,1,255,1,'Filename:');
     OutTextXY(490,200,0,255,1,CurrentFile);
     {Buttons First}
     x         := 410;
     y         := 220;
     Counter   := 0;
     FOR LoopX := 1 TO 36 DO
     BEGIN
          SystemButton(x,y,x+30,y+30,1,False,True);
          SystemIcon(x,y,Icn[LoopX]);
          CASE LoopX OF
          28:  BEGIN {TEXT FILE BOXES}
                    OutTextXY(X+4,y+14,0,255,1,'TXT');
                    OutTextXY(X+3,y+13,14,255,1,'TXT');
               END;
          33:  BEGIN {BMP}
                    OutTextXY(X+4,y+14,0,255,1,'BMP');
                    OutTextXY(X+3,y+13,14,255,1,'BMP');
               END;
          END;
          INC(Counter);
          INC(x,30);
          IF Counter=6 THEN
          BEGIN
               Counter := 0;
               x       := 410;
               INC(y,30);
          END;
     END;
     IF MouseOn THEN GrDisplayMouse(GrShow);
     NewTool := False;
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           1:     BEGIN
                       WindowHeader('DRAWING TOOLS',False);
                       IF DoChangeBackGround THEN DoARedraw := True;
                       WindowHeader('DRAWING TOOLS',True);
                  END;
           2:     BEGIN
                       WindowHeader('DRAWING TOOLS',False);
                       DoChangeMouse; {MOUSE}
                       WindowHeader('DRAWING TOOLS',True);
                  END;
           3:     BEGIN
                       WindowHeader('DRAWING TOOLS',False);
                       DoChangeSound; {SOUND}
                       WindowHeader('DRAWING TOOLS',True);
                  END;
           4..32: BEGIN
                       NewTool := True;
                       DoPopUp := C;
                  END;
           33:    BEGIN
                       KillWindow;
                       ReloadWindow(3);
                       Temp := 'SNAPSHOT.BMP';
                       What := FileSelector(JPEGDir,'*.*','',Temp,False,True,True);
                       CASE What OF
                       2:   BEGIN {SAVE}
                                 IF _FileExists(JPEGDir+Temp) THEN
                                 BEGIN
                                      IF NOT(VerifySave(Temp+' already exists!',
                                         'Do you wish to proceed and overwrite','the existing file?'))
                                         THEN GOTO SkipSave2;
                                 END;
                                 What := 0;
                                 FOR LoopX := 0 TO 255 DO
                                 BEGIN
                                      gxGetPaletteRGB(LoopX,c1,c2,c3);
                                      dipal[What]   := c1;
                                      dipal[What+1] := c2;
                                      dipal[What+2] := c3;
                                      INC(What,3);
                                 END;
                                 GrDisplayMouse(GrHide);
                                 imgDisplayFile(0,0,GraphMaxX,YWindow,0,JPEGDir+Temp,imgBMP,imgTRUNC,@DiPal);
                                 GrDisplayMouse(GrShow);
                                 SkipSave2:
                            END;
                       END;
                       DoPopUp := 0;
                       Exit;
                  END;
           34:    BEGIN
                       IF VerifySave('Using the trash can will totally erase the',
                                     'current file in memory. Do you want to','proceed?') THEN
                       BEGIN
                            NewTool := True;
                            DoPopUp := C;
                       END;
                  END;
           35:    BEGIN
                       WindowHeader('DRAWING TOOLS',False);
                       Temp := CurrentFile;
                       _CreatePath(SGDir);
                       What := FileSelector(SGDir,'*.SG','',Temp,True,True,True);
                       CASE What OF
                       1:   BEGIN {LOAD}
                                 IF VerifySave('Loading a new file will destroy the file',
                                               'currently in memory. Do you want to','proceed?') THEN
                                 BEGIN
                                      CurrentFile := Temp;
                                      ASSIGN(FWorkSg,SGDir+Temp);
                                      ASSIGN(FWorkSg2,WorkDir+'TEMPWORK.$$$');
                                      REWRITE(FWorkSg2);
                                      RESET(FWorkSg);
                                      REPEAT
                                            READ(FWorkSG,WorkSg);
                                            WRITE(FWorkSg2,WorkSG);
                                      UNTIL EOF(FWorkSg);
                                      CLOSE(FWorkSg2);
                                      CLOSE(FWorkSg);
                                      DoARedraw := True;
                                      NewTool   := True;
                                      DoPopUp   := 35;
                                 END;
                            END;
                       2:   BEGIN {SAVE}
                                 IF CheckRightWindows THEN
                                 BEGIN
                                      IF _FileExists(SGDir+Temp) THEN
                                      BEGIN
                                           IF NOT(VerifySave(Temp+' already exists!',
                                              'Do you wish to proceed and overwrite','the existing file?'))
                                              THEN GOTO SkipSave;
                                      END;
                                      CurrentFile := Temp;
                                      ASSIGN(FWorkSg,WorkDir+'TEMPWORK.$$$');
                                      ASSIGN(FWorkSg2,SGDir+Temp);
                                      REWRITE(FWorkSg2);
                                      RESET(FWorkSg);
                                      REPEAT
                                            READ(FWorkSG,WorkSg);
                                            WRITE(FWorkSg2,WorkSG);
                                      UNTIL EOF(FWorkSg);
                                      CLOSE(FWorkSg2);
                                      CLOSE(FWorkSg);
                                      NewTool := True;
                                      DoPopUp := 0;
                                      SkipSave:
                                 END;
                            END;
                       END;
                       WindowHeader('DRAWING TOOLS',True);
                  END;
           36:    BEGIN
                       NewTool := True;
                       DoPopUp := 0;
                  END;
           END;
     UNTIL NewTool;
     KillWindow;
     ReloadWindow(3);
END;


END.
