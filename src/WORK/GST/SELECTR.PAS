{$I DEFINES.INC}
UNIT Selectr;


INTERFACE


FUNCTION DoFileQueue(IsBatch: Boolean): Boolean;


IMPLEMENTATION


{$IFDEF DPMI}
USES __Gfx,Gx2_Bp,Gr2_Bp,Graphics,Globals,Bs,Dos,Drives,Fx;
{$ELSE}
USES __Gfx,Gx_Tp,Gr_Tp,Graphics,Globals,Bs,Dos,Drives,Fx;
{$ENDIF}


TYPE File_Info      = RECORD
     FName          : String[12];
     IsDir          : Boolean;
     END;
TYPE FFile_Info     = Array[1..1000] Of File_Info;
TYPE ButCoord       = RECORD
     x1             : Word;
     y1             : Word;
     x2             : Word;
     y2             : Word;
     END;
VAR  STheDrives     : String;
     SCurrentPath   : String;
     SCurrentDrive  : Byte;
     NFiles         : Word;
     FileInfo       : ^FFile_Info;
     SCurrentFile   : Word;
     SCurrentRem    : Word;
     WindowX1,
     WindowX2,
     WindowY1,
     WindowY2       : Word;
     SelBut         : Array[1..33] Of ButCoord;
     NSelBut        : Word;
     AtTheTop       : Word;


PROCEDURE DrawSomeFiles;
VAR  Loop : Word;
     Cur  : Word;
     xx   : Word;
     yy   : Word;
     Temp : String;
BEGIN
     Cur := AtTheTop;
     yy  := WindowY1+60;
     xx  := WindowX1+20;
     FOR Loop := 1 TO 13 DO
     BEGIN
          IF (Cur<=NFiles) THEN
          BEGIN
               IF FileInfo^[Cur].IsDir THEN Temp := ' '+_PadRight(FileInfo^[Cur].FName,14)+'<DIR> '
                                       ELSE Temp := ' '+_PadRight(FileInfo^[Cur].FName,14)+'      ';
          END
          ELSE Temp := _PadRight('',21);
          IF Cur=SCurrentFile THEN OutTextXY(xx,yy,15,8,3,Temp)
                              ELSE OutTextXY(xx,yy,0,15,3,Temp);
          INC(yy,12);
          INC(Cur);
     END;
END;


PROCEDURE LoadInFiles;
VAR  DirInfo : SearchRec;
BEGIN
     NFiles := 0;
     FindFirst(SCurrentPath+'*.*',Anyfile-VolumeID-Hidden,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          INC(NFiles);
          FileInfo^[NFiles].FName := DirInfo.Name;
          FileInfo^[NFiles].IsDir := ((DirInfo.Attr AND $10)<>0);
          FindNext(DirInfo);
     END;
END;


PROCEDURE AddSelButton(x1,y1,x2,y2: Word);
BEGIN
     INC(NSelBut);
     SelBut[NSelBut].x1 := x1+1;
     SelBut[NSelBut].y1 := y1+1;
     SelBut[NSelBut].x2 := x2-1;
     SelBut[NSelBut].y2 := y2-1;
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
     RaisedBox(X1+1,Y1+1,X2-1,Y2-1);
END;


PROCEDURE DrawDrives;
VAR  Loop   : Word;
     xx     : Word;
     yy     : Word;
     Colour : Byte;
BEGIN
     xx := WindowX1+10;
     yy := WindowY2-50;
     FOR Loop := 1 TO 13 DO
     BEGIN
          IF Chr(64+Loop)= STheDrives[SCurrentDrive]
             THEN Colour := 1
             ELSE Colour := 8;
          OutTextXY(xx+7,yy+4,Colour,255,3,Chr(64+Loop));
          INC(xx,20);
     END;
     xx := WindowX1+10;
     yy := WindowY2-30;
     FOR Loop := 1 TO 13 DO
     BEGIN
          IF Chr(77+Loop)= STheDrives[SCurrentDrive]
             THEN Colour := 1
             ELSE Colour := 8;
          OutTextXY(xx+7,yy+4,Colour,255,3,Chr(77+Loop));
          INC(xx,20);
     END;
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(WindowX1+11,WindowY1+31,WindowX1+489,WindowY1+49,GrFill);
     OutTextXY(WindowX1+19,WindowY1+34,0,255,1,SCurrentPath+'*.*');
     AtTheTop := 1;
     SCurrentFile := 0;
END;


PROCEDURE ChangeDrive(TheOne: Char);
VAR  Loop    : Word;
     NewOne  : Word;
     DirInfo : SearchRec;
BEGIN
     Loop := 1;
     NewOne := 0;
     REPEAT
           IF STheDrives[Loop]=TheOne THEN NewOne := Loop;
           INC(Loop);
     UNTIL ((NewOne<>0) OR (Loop>Length(STheDrives)));
     IF (NewOne<>SCurrentDrive) THEN
     BEGIN
          FindFirst(STheDrives[NewOne]+':\*.*',Anyfile-VolumeID,DirInfo);
          IF DosError=0 THEN
          BEGIN
               SCurrentDrive := NewOne;
               ChDir(STheDrives[SCurrentDrive]+':\');
               GetDir(0,SCurrentPath);
               SCurrentPath := _Path(SCurrentPath);
               GrDisplayMouse(GrHide);
               DrawDrives;
               LoadInFiles;
               DrawSomeFiles;
               GrDisplayMouse(GrShow);
          END;
     END;
END;


PROCEDURE DrawFileSelectorWindow;
VAR  Loop   : Word;
     xx     : Word;
     yy     : Word;
BEGIN
     Windowx1 := 50;
     Windowy1 := 50;
     Windowx2 := 550;
     Windowy2 := 350;
     {Window Face}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,7,GrOpaque);
     GrDrawRect(WindowX1,WindowY1,WindowX2,WindowY2,GrFill+GrOutline);
     {Window Shadows}
     GrSetColor(8);
     GrDrawLine(WindowX1+1,WindowY2-1,WindowX2-1,WindowY2-1);
     GrDrawLine(WindowX2-1,WindowY1+1,WindowX2-1,WindowY2-1);
     GrSetColor(15);
     GrDrawLine(WindowX1+1,WindowY1+1,WindowX2-1,WindowY1+1);
     GrDrawLine(WindowX1+1,WindowY1+1,WindowX1+1,WindowY2-1);
     {Window Header}
     GrSetFillStyle(GrFSolid,241,GrOpaque);
     GrDrawRect(WindowX1+5,WindowY1+5,WindowX2-5,WindowY1+25,GrFill);
     OutTextXY(WindowX1+15,WindowY1+8,0,255,1,'Upload File(s)');
     {Window Shadow}
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(Windowx1+5,Windowy2+1,Windowx2+5,Windowy2+5,GrFill);
     GrDrawRect(Windowx2+1,Windowy1+5,Windowx2+5,Windowy2+5,GrFill);
     {Path Box}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(WindowX1+10,WindowY1+30,WindowX1+490,WindowY1+50,GrFill+GrOutline);
     InvertedBox(WindowX1+10,WindowY1+30,WindowX1+490,WindowY1+50);
     {Work Area Left}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(WindowX1+10,WindowY1+55,WindowX1+190,WindowY1+220,GrFill+GrOutline);
     InvertedBox(WindowX1+10,WindowY1+55,WindowX1+211,WindowY1+220);
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrDrawRect(WindowX1+11,WindowY1+56,WindowX1+189,WindowY1+219,GrOutline);
     GrSetLineStyle(GrLSolid,1);
     GrSetColor(0);
     GrDrawRect(WindowX1+190,WindowY1+56,WindowX1+210,WindowY1+219,GrOutline);
     {Work Area Right}
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(WindowX1+290,WindowY1+55,WindowX1+490,WindowY1+220,GrFill+GrOutline);
     InvertedBox(WindowX1+290,WindowY1+55,WindowX1+490,WindowY1+220);
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrDrawRect(WindowX1+291,WindowY1+56,WindowX1+489,WindowY1+219,GrOutline);
     GrSetLineStyle(GrLSolid,1);
     {Buttons}
     AddSelButton(WindowX1+220,WindowY1+60,WindowX1+280,WindowY1+90);
     OutTextXY(WindowX1+230,WindowY1+68,0,255,1,'Add >>');
     AddSelButton(WindowX1+220,WindowY1+95,WindowX1+280,WindowY1+125);
     OutTextXY(WindowX1+230,WindowY1+103,0,255,1,'<< Rem');
     AddSelButton(WindowX1+220,WindowY1+130,WindowX1+280,WindowY1+160);
     OutTextXY(WindowX1+237,WindowY1+138,0,255,1,'Clear');
     AddSelButton(WindowX2-180,WindowY2-50,WindowX2-100,WindowY2-10);
     SystemIcon(WindowX2-175,WindowY2-45,65);
     OutTextXY(WindowX2-145,WindowY2-36,0,255,1,'Upload');
     AddSelButton(WindowX2-90,WindowY2-50,WindowX2-10,WindowY2-10);
     SystemIcon(WindowX2-85,WindowY2-45,64);
     OutTextXY(WindowX2-55,WindowY2-36,0,255,1,'Cancel');
     xx := WindowX1+10;
     yy := WindowY2-50;
     FOR Loop := 1 TO 13 DO
     BEGIN
          AddSelButton(xx,yy,xx+20,yy+20);
          INC(xx,20);
     END;
     xx := WindowX1+10;
     yy := WindowY2-30;
     FOR Loop := 1 TO 13 DO
     BEGIN
          AddSelButton(xx,yy,xx+20,yy+20);
          INC(xx,20);
     END;
     AddSelButton(WindowX1+190,WindowY1+56,WindowX1+210,WindowY1+76);
     SystemIcon(WindowX1+194,WindowY1+60,28);
     AddSelButton(WindowX1+190,WindowY1+199,WindowX1+210,WindowY1+219);
     SystemIcon(WindowX1+194,WindowY1+203,29);
     DrawDrives;
     LoadInFiles;
     DrawSomeFiles;
END;


PROCEDURE MoveSelectorWindow(x1,y1,x2,y2: word);
VAR  new_x,new_y       : word;
     x_add,y_add       : word;
     start_x1,start_y1 : word;
     old_m_x,old_m_y   : word;
     LastX,LastY       : Word;
     OldX1,OldY1       : Word;
     OldX2,OldY2       : Word;
     X_Move,Y_Move     : Integer;
     Loop              : Word;
     SVX               : Word;
     SVY               : Word;
BEGIN
     SVX      := GetMouseX;
     SVY      := GetMouseY;
     old_m_x  := SVX-x1;
     old_m_y  := SVY-y1;
     start_x1 := x1;
     start_y1 := y1;
     LastX    := SVX;
     LastY    := SVY;
     x_add    := x2-SVX;
     y_add    := y2-SVY;
     GrSetMouseBounds(old_m_x+5,old_m_y+5,GraphMaxX-x_add-5,GraphMaxY-50-y_add-5);
     GrSetLineStyle(GrLSolid,2);
     GrSetOp(GxXOR);
     GrSetColor(XORLine);
     GrDisplayMouse(GrHide);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrDisplayMouse(GrShow);
     REPEAT
           IF ((GetMouseX<>LastX) OR (GetMouseY<>LastY)) THEN
           BEGIN
                Lastx := GetMouseX;
                Lasty := GetMouseY;
                GrDisplayMouse(GrHide);
                GrDrawRect(x1,y1,x2,y2,GrOutline);
                x1 := LastX-old_m_x;
                y1 := Lasty-old_m_y;
                x2 := Lastx+X_Add;
                y2 := Lasty+y_add;
                GrDrawRect(x1,y1,x2,y2,GrOutline);
                GrDisplayMouse(GrShow);
           END;
     UNTIL GrGetMouseButtons<>GrLButton;
     GrDisplayMouse(GrHide);
     GrDrawRect(x1,y1,x2,y2,GrOutline);
     GrDisplayMouse(GrShow);
     X_Move := 0;
     Y_Move := 0;
     IF (x1>start_x1) THEN X_Move := x1-start_x1
        ELSE IF (x1<start_x1) THEN X_Move := -1*(start_x1-x1);
     IF (y1>start_y1) THEN Y_Move := y1-start_y1
        ELSE IF (y1<start_y1) THEN Y_Move := -1*(start_y1-y1);
     GrSetOp(GxSet);
     GrSetMouseBounds(0,0,GraphMaxX-10,GraphMaxY-10);
     GrSetLineStyle(GrLSolid,1);
     {RECALCULATE BUTTONS, AND WINDOW}
     IF ((X_Move<>0) OR (Y_Move<>0)) THEN
     BEGIN
          GrDisplayMouse(GrHide);
          Get2(WindowX1,WindowY1,WindowX2,WindowY2);
          WindowX1 := WindowX1+X_Move;
          WindowX2 := WindowX2+X_Move;
          WindowY1 := WindowY1+Y_Move;
          WindowY2 := WindowY2+Y_Move;
          Put(0,0,False);
          Put2(WindowX1,WindowY1,True);
          {Window Shadow}
          GrSetFillStyle(GrFCloseDot,0,GrTrans);
          GrDrawRect(Windowx1+5,Windowy2+1,Windowx2+5,Windowy2+5,GrFill);
          GrDrawRect(Windowx2+1,Windowy1+5,Windowx2+5,Windowy2+5,GrFill);
          GrDisplayMouse(GrShow);
          FOR Loop := 1 TO NSelBut DO
          BEGIN
               SelBut[Loop].x1 := SelBut[Loop].x1+X_Move;
               SelBut[Loop].x2 := SelBut[Loop].x2+X_Move;
               SelBut[Loop].y1 := SelBut[Loop].y1+Y_Move;
               SelBut[Loop].y2 := SelBut[Loop].y2+Y_Move;
          END;
     END;
END;


FUNCTION DoSelButton: Byte;
VAR  Num     : Byte;
     AllDone : Boolean;
     Loop    : Word;
     xx,yy   : Word;
LABEL          Skip;
BEGIN
     Num := 0;
     AllDone := False;
     REPEAT
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                xx := GetMouseX;
                yy := GetMouseY;
                Loop := 1;
                REPEAT
                      IF ((xx>SelBut[Loop].x1) AND (xx<SelBut[Loop].x2) AND
                         (yy>SelBut[Loop].y1) AND (yy<SelBut[Loop].y2)) THEN
                      BEGIN
                           IF (Loop<>Num) THEN
                           BEGIN
                                GrDisplayMouse(GrHide);
                                IF Num<>0 THEN RaisedBox(SelBut[Num].x1,SelBut[Num].y1,SelBut[Num].x2,SelBut[Num].y2);
                                Num := Loop;
                                InvertedBox(SelBut[Num].x1,SelBut[Num].y1,SelBut[Num].x2,SelBut[Num].y2);
                                GrDisplayMouse(GrShow);
                                GOTO Skip;
                           END
                           ELSE GOTO Skip;
                      END;
                      INC(Loop);
                UNTIL (Loop>NSelBut);
                Skip:
                IF ((Loop>NSelBut) AND (Num<>0)) THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     RaisedBox(SelBut[Num].x1,SelBut[Num].y1,SelBut[Num].x2,SelBut[Num].y2);
                     GrDisplayMouse(GrShow);
                     Num := 0;
                END
           END
           ELSE
           BEGIN
                IF Num<>0 THEN
                BEGIN
                     GrDisplayMouse(GrHide);
                     RaisedBox(SelBut[Num].x1,SelBut[Num].y1,SelBut[Num].x2,SelBut[Num].y2);
                     GrDisplayMouse(GrShow);
                END;
                AllDone := True;
           END;
     UNTIL AllDone;
     DoSelButton := Num;
END;


PROCEDURE RedrawTheUploadQueue;
VAR  Loop : Word;
     xx   : Word;
     yy   : Word;
     Temp : String;
BEGIN
     yy  := WindowY1+60;
     xx  := WindowX1+300;
     FOR Loop := 1 TO 13 DO
     BEGIN
          IF (Loop<=FilesInQueue)
             THEN Temp := ' '+_PadRight(_NoPath(FileQueue[Loop]),13)
             ELSE Temp := _PadRight('',14);
          IF Loop=SCurrentRem THEN OutTextXY(xx,yy,15,8,3,Temp)
                              ELSE OutTextXY(xx,yy,0,15,3,Temp);
          INC(yy,12);
     END;
END;


PROCEDURE AddInTheFile(FNum: Word; Batch: Boolean);
VAR  Loop     : Word;
     MaxQueue : Word;
LABEL           SkipIt;
BEGIN
     IF Batch THEN MaxQueue := 13
              ELSE MaxQueue := 1;
     IF (FilesInQueue<MaxQueue) THEN
     BEGIN
          IF (FilesInQueue<>0) THEN
          BEGIN
               FOR Loop := 1 TO FilesInQueue DO
               BEGIN
                    IF FileInfo^[FNum].FName=_NoPath(FileQueue[Loop]) THEN GOTO SkipIt;
               END;
          END;
          INC(FilesInQueue);
          FileQueue[FilesInQueue] := UpperCase(SCurrentPath+FileInfo^[FNum].FName);
          RedrawTheUploadQueue;
          SkipIt:
     END;
END;


PROCEDURE TakeOutTheFile(Num: Word);
VAR  Loop : Word;
BEGIN
     IF SCurrentRem=FilesInQueue THEN
     BEGIN
          DEC(FilesInQueue);
     END
     ELSE
     BEGIN
          FOR Loop := Num TO 12 DO
          BEGIN
               FileQueue[Loop] := FileQueue[Loop+1];
          END;
          DEC(FilesInQueue);
     END;
END;


FUNCTION DoFileQueue(IsBatch: Boolean): Boolean;
VAR  AllDone       : Boolean;
     xxx           : Word;
     yyy           : Word;
     TheStatus     : Boolean;
     Loop          : Word;
     Work          : Word;
     OldDir        : String;
     TheOne        : Word;
BEGIN
     NEW(FileInfo);
     FilesInQueue           := 0;
     TheStatus              := False;
     NSelBut                := 0;
     AtTheTop               := 1;
     SCurrentFile           := 0;
     SCurrentRem            := 0;
     STheDrives             := GetDrives;
     SCurrentDrive          := 0;
     Loop                   := 1;
     REPEAT
           IF STheDrives[Loop]='C' THEN SCurrentDrive := Loop;
           INC(Loop);
     UNTIL ((SCurrentDrive<>0) OR (Loop>Length(STheDrives)));
     SCurrentPath := STheDrives[SCurrentDrive]+':\';
     GetDir(0,OldDir);
     ChDir(SCurrentPath);
     GetDir(0,SCurrentPath);
     SCurrentPath := _Path(SCurrentPath);
     FillChar(FileQueue,SizeOf(FileQueue),0);
     GrDisplayMouse(GrHide);
     Get(0,0,GraphMaxX,GraphMaxY);
     DrawFileSelectorWindow;
     GrDisplayMouse(GrShow);
     AllDone := False;
     REPEAT
           IF GrGetMouseButtons=GrRButton THEN AllDone := True;
           IF GrGetMouseButtons=GrLButton THEN
           BEGIN
                xxx := GetMouseX;
                yyy := GetMouseY;
                IF ((xxx>WindowX1) AND (xxx<WindowX2) AND
                   (yyy>WindowY1) AND (yyy<WindowY1+24)) THEN
                BEGIN
                     MoveSelectorWindow(WindowX1,WindowY1,WindowX2,WindowY2);
                END
                ELSE IF ((xxx>WindowX1+11) AND (xxx<WindowX1+189) AND
                        (yyy>WindowY1+60) AND (yyy<WindowY1+219)) THEN
                BEGIN
                     TheOne := Trunc((yyy-(WindowY1+60))/12)+1;
                     IF ((TheOne>0) AND (TheOne<14)) THEN
                     BEGIN
                          IF (TheOne+AtTheTop-1<=NFiles) THEN
                          BEGIN
                               IF FileInfo^[TheOne+AtTheTop-1].IsDir THEN
                               BEGIN
                                    {$I-}
                                    ChDir(FileInfo^[TheOne+AtTheTop-1].FName);
                                    {$I+}
                                    IF IOResult=0 THEN
                                    BEGIN
                                         GetDir(0,SCurrentPath);
                                         SCurrentPath := _Path(SCurrentPath);
                                         GrDisplayMouse(GrHide);
                                         DrawDrives;
                                         LoadInFiles;
                                         DrawSomeFiles;
                                         GrDisplayMouse(GrShow);
                                         REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                                    END;
                               END
                               ELSE
                               BEGIN
                                    IF (TheOne+AtTheTop-1<>SCurrentFile) THEN
                                    BEGIN
                                         SCurrentFile := TheOne+AtTheTop-1;
                                         GrDisplayMouse(GrHide);
                                         DrawSomeFiles;
                                         GrDisplayMouse(GrShow);
                                         REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                                    END
                                    ELSE
                                    BEGIN
                                         AddInTheFile(SCurrentFile,IsBatch);
                                         SCurrentFile := 0;
                                         GrDisplayMouse(GrHide);
                                         DrawSomeFiles;
                                         GrDisplayMouse(GrShow);
                                         REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                                    END;
                               END;
                          END;
                     END;
                END
                ELSE IF ((xxx>WindowX1+291) AND (xxx<WindowX1+489) AND
                        (yyy>WindowY1+60) AND (yyy<WindowY1+219)) THEN
                BEGIN
                     TheOne := Trunc((yyy-(WindowY1+60))/12)+1;
                     IF ((TheOne>0) AND (TheOne<14) AND (FilesInQueue<>0)) THEN
                     BEGIN
                          IF (TheOne<=FilesInQueue) THEN
                          BEGIN
                               IF (TheOne<>SCurrentRem) THEN
                               BEGIN
                                    SCurrentRem := TheOne;
                                    GrDisplayMouse(GrHide);
                                    RedrawTheUploadQueue;
                                    GrDisplayMouse(GrShow);
                                    REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     Work := DoSelButton;
                     CASE Work OF
                     1:     BEGIN {ADD}
                                 IF (SCurrentFile<>0) THEN
                                 BEGIN
                                      AddInTheFile(SCurrentFile,IsBatch);
                                      SCurrentFile := 0;
                                      GrDisplayMouse(GrHide);
                                      DrawSomeFiles;
                                      GrDisplayMouse(GrShow);
                                      REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                                 END;
                            END;
                     2:     BEGIN {REMOVE}
                                 IF (SCurrentRem<>0) THEN
                                 BEGIN
                                      TakeOutTheFile(SCurrentRem);
                                      SCurrentRem := 0;
                                      GrDisplayMouse(GrHide);
                                      RedrawTheUploadQueue;
                                      GrDisplayMouse(GrShow);
                                      REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
                                 END;
                            END;
                     3:     BEGIN {CLEAR}
                                 FilesInQueue := 0;
                                 GrDisplayMouse(GrHide);
                                 RedrawTheUploadQueue;
                                 GrDisplayMouse(GrShow);
                            END;
                     4:     BEGIN
                                 TheStatus := True;
                                 AllDone   := True;
                            END;
                     5:     BEGIN
                                 TheStatus  := False;
                                 AllDone    := True;
                            END;
                     6..31: ChangeDrive(Chr(59+Work));
                     32:    IF (AtTheTop>1) THEN
                            BEGIN
                                 DEC(AtTheTop,13);
                                 GrDisplayMouse(GrHide);
                                 DrawSomeFiles;
                                 GrDisplayMouse(GrShow);
                            END;
                     33:    IF (AtTheTop+13<=NFiles) THEN
                            BEGIN
                                 INC(AtTheTop,13);
                                 GrDisplayMouse(GrHide);
                                 DrawSomeFiles;
                                 GrDisplayMouse(GrShow);
                            END;
                     END;
                END;
           END;
     UNTIL AllDone;
     ChDir(OldDir);
     GrDisplayMouse(GrHide);
     Put(0,0,True);
     GrDisplayMouse(GrShow);
     IF TheStatus THEN
     BEGIN
          IF FilesInQueue=0 THEN TheStatus := False;
     END;
     DISPOSE(FileInfo);
     DoFileQueue := TheStatus;
END;


END.
