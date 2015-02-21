{$I DEFINES.INC}
UNIT FilePick;


INTERFACE


USES BsMouse,CRT,IntrFace,BsString,BsFile,Dispatch,DosShell,CnfgVars;


TYPE PickRecord2=RECORD
     A         : String[78];
     END;
VAR
     PickingListFile2    : PickRecord2;
     FPickingListFile2   : File Of PickRecord2;
     QuittingButton2X1   : Word;
     QuittingButton2X2   : Word;
     QuittingButton2Y1   : Word;
     OrphaningButton2X1  : Word;
     OrphaningButton2X2  : Word;
     OrphaningButton2Y1  : Word;
     ImportingButton2X1  : Word;
     ImportingButton2X2  : Word;
     ImportingButton2Y1  : Word;
     AddingButton2X1     : Word;
     AddingButton2X2     : Word;
     AddingButton2Y1     : Word;
     DeletingButton2X1   : Word;
     DeletingButton2X2   : Word;
     DeletingButton2Y1   : Word;
     EditingButton2X1    : Word;
     EditingButton2X2    : Word;
     EditingButton2Y1    : Word;
     MovingButton2X1     : Word;
     MovingButton2X2     : Word;
     MovingButton2Y1     : Word;
     CopyingButton2X1    : Word;
     CopyingButton2X2    : Word;
     CopyingButton2Y1    : Word;
     PickingList2X       : Word;
     PickingList2Y       : Word;
     PickingListPerPage2 : Word;
     PickingListTitle2   : String;
     ScrollingBar2X      : Word;
     ScrollingBar2Y1     : Word;
     ScrollingBar2Y2     : Word;
     ScrollingPad2Y      : Word;
     PickingTop2         : Word;
     PickingItem2        : Word;
     PickingListItems2   : Word;
     HasFilesBBS         : Boolean;


PROCEDURE UpdatePickingList2;
PROCEDURE DrawPickingListButtons2;
PROCEDURE ReleasePickingListButton2  (Number: Byte);
PROCEDURE PressPickingListButton2    (Number: Byte);
PROCEDURE SetUpPickingList2          (WindowTitle: String);
FUNCTION  DoPickingList2             : Word;


IMPLEMENTATION


PROCEDURE DrawPickingListButtons2;
VAR  Loop : Word;
BEGIN
     _HideMouse;
     QuittingButton2X1  := 4;
     QuittingButton2X2  := 11;
     QuittingButton2Y1  := 22;

     EditingButton2X1   := 13;
     EditingButton2X2   := 20;
     EditingButton2Y1   := 22;

     AddingButton2X1    := 22;
     AddingButton2X2    := 28;
     AddingButton2Y1    := 22;

     DeletingButton2X1  := 30;
     DeletingButton2X2  := 39;
     DeletingButton2Y1  := 22;

     OrphaningButton2X1 := 41;
     OrphaningButton2X2 := 50;
     OrphaningButton2Y1 := 22;

     MovingButton2X1     := 52;
     MovingButton2X2     := 59;
     MovingButton2Y1     := 22;

     CopyingButton2X1    := 61;
     CopyingButton2X2    := 68;
     CopyingButton2Y1    := 22;

     ImportingButton2X1 := 70;
     ImportingButton2X2 := 76;
     ImportingButton2Y1 := 22;

     FOR Loop := QuittingButton2X1 TO QuittingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,QuittingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,QuittingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(QuittingButton2X2+1,QuittingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(QuittingButton2X1,QuittingButton2Y1); WRITE('  Q');
     TextColor_BS(0);
     WRITE('uit  ');


     FOR Loop := EditingButton2X1 TO EditingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,EditingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,EditingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(EditingButton2X2+1,EditingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(EditingButton2X1,EditingButton2Y1); WRITE('  E');
     TextColor_BS(0);
     WRITE('dit  ');


     FOR Loop := AddingButton2X1 TO AddingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,AddingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,AddingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(AddingButton2X2+1,AddingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(AddingButton2X1,AddingButton2Y1); WRITE('  A');
     TextColor_BS(0);
     WRITE('dd  ');


     FOR Loop := DeletingButton2X1 TO DeletingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,DeletingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,DeletingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(DeletingButton2X2+1,DeletingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(DeletingButton2X1,DeletingButton2Y1); WRITE('  D');
     TextColor_BS(0);
     WRITE('elete  ');


     FOR Loop := OrphaningButton2X1 TO OrphaningButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,OrphaningButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,OrphaningButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(OrphaningButton2X2+1,OrphaningButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(OrphaningButton2X1,OrphaningButton2Y1); WRITE('  O');
     TextColor_BS(0);
     WRITE('rphan  ');

     FOR Loop := MovingButton2X1 TO MovingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,MovingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,MovingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(MovingButton2X2+1,MovingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(MovingButton2X1,MovingButton2Y1); WRITE('  M');
     TextColor_BS(0);
     WRITE('ove  ');

     FOR Loop := CopyingButton2X1 TO CopyingButton2X2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,CopyingButton2Y1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(1);
          GotoXY(Loop+1,CopyingButton2Y1+1);
          WRITE('ß');
     END;
     GotoXY(CopyingButton2X2+1,CopyingButton2Y1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(CopyingButton2X1,CopyingButton2Y1); WRITE('  C');
     TextColor_BS(0);
     WRITE('opy  ');

     IF HasFilesBBS THEN
     BEGIN
          FOR Loop := ImportingButton2X1 TO ImportingButton2X2 DO
          BEGIN
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(Loop,ImportingButton2Y1);
               WRITE(' ');
               {BUTTON SHADOW}
               TextColor_BS(0); TextBackGround_BS(1);
               GotoXY(Loop+1,ImportingButton2Y1+1);
               WRITE('ß');
          END;
          GotoXY(ImportingButton2X2+1,ImportingButton2Y1);
          WRITE('Ü');
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(ImportingButton2X1,ImportingButton2Y1); WRITE('  B');
          TextColor_BS(0);
          WRITE('BS  ');
     END;
     _ShowMouse;
END;


PROCEDURE ReleasePickingListButton2(Number: Byte);
VAR
     Loop         : Word;
BEGIN
     _HideMouse;
     CASE Number Of
     2:   BEGIN
               FOR Loop := QuittingButton2X1 TO QuittingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,QuittingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,QuittingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(QuittingButton2X2+1,QuittingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(QuittingButton2X1,QuittingButton2Y1); WRITE('  Q');
               TextColor_BS(0);
               WRITE('uit  ');
          END;
     3:   BEGIN
               FOR Loop := OrphaningButton2X1 TO OrphaningButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,OrphaningButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,OrphaningButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(OrphaningButton2X2+1,OrphaningButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(OrphaningButton2X1,OrphaningButton2Y1); WRITE('  O');
               TextColor_BS(0);
               WRITE('rphan  ');
          END;
     4:   IF HasFilesBBS THEN
          BEGIN
               FOR Loop := ImportingButton2X1 TO ImportingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,ImportingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,ImportingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(ImportingButton2X2+1,ImportingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(ImportingButton2X1,ImportingButton2Y1); WRITE('  B');
               TextColor_BS(0);
               WRITE('BS  ');
          END;
     5:   BEGIN
               FOR Loop := AddingButton2X1 TO AddingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,AddingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,AddingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(AddingButton2X2+1,AddingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(AddingButton2X1,AddingButton2Y1); WRITE('  A');
               TextColor_BS(0);
               WRITE('dd  ');
          END;
     6:   BEGIN
               FOR Loop := DeletingButton2X1 TO DeletingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,DeletingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,DeletingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(DeletingButton2X2+1,DeletingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(DeletingButton2X1,DeletingButton2Y1); WRITE('  D');
               TextColor_BS(0);
               WRITE('elete  ');
          END;
     7:   BEGIN
               FOR Loop := EditingButton2X1 TO EditingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,EditingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,EditingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(EditingButton2X2+1,EditingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(EditingButton2X1,EditingButton2Y1); WRITE('  E');
               TextColor_BS(0);
               WRITE('dit  ');
          END;
     8:   BEGIN
               FOR Loop := CopyingButton2X1 TO CopyingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,CopyingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,CopyingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(CopyingButton2X2+1,CopyingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(CopyingButton2X1,CopyingButton2Y1); WRITE('  C');
               TextColor_BS(0);
               WRITE('opy  ');
          END;
     9:   BEGIN
               FOR Loop := MovingButton2X1 TO MovingButton2X2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,MovingButton2Y1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(1);
                    GotoXY(Loop+1,MovingButton2Y1+1);
                    WRITE('ß');
               END;
               GotoXY(MovingButton2X2+1,MovingButton2Y1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(MovingButton2X1,MovingButton2Y1); WRITE('  M');
               TextColor_BS(0);
               WRITE('ove  ');
          END;
     END;
     _ShowMouse;
END;


PROCEDURE PressPickingListButton2(Number: Byte);
VAR  Loop         : Word;
BEGIN
     _HideMouse;
     CASE Number OF
     2:   BEGIN
               TextBackGround_BS(1);
               GotoXY(QuittingButton2X1,QuittingButton2Y1);   WRITE('         ');
               GotoXY(QuittingButton2X1,QuittingButton2Y1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(QuittingButton2X1+1,QuittingButton2Y1);
               TextColor_BS(4); WRITE('  Q');
               TextColor_BS(0); WRITE('uit  ');
          END;
     3:   BEGIN
               TextBackGround_BS(1);
               GotoXY(OrphaningButton2X1,OrphaningButton2Y1);   WRITE('           ');
               GotoXY(OrphaningButton2X1,OrphaningButton2Y1+1); WRITE('           ');
               TextBackGround_BS(7);
               GotoXY(OrphaningButton2X1+1,OrphaningButton2Y1);
               TextColor_BS(4); WRITE('  O');
               TextColor_BS(0); WRITE('rphan  ');
          END;
     4:   IF HasFilesBBS THEN
          BEGIN
               TextBackGround_BS(1);
               GotoXY(ImportingButton2X1,ImportingButton2Y1);   WRITE('        ');
               GotoXY(ImportingButton2X1,ImportingButton2Y1+1); WRITE('        ');
               TextBackGround_BS(7);
               GotoXY(ImportingButton2X1+1,ImportingButton2Y1);
               TextColor_BS(4); WRITE('  B');
               TextColor_BS(0); WRITE('BS  ');
          END;
     5:   BEGIN
               TextBackGround_BS(1);
               GotoXY(AddingButton2X1,AddingButton2Y1);   WRITE('        ');
               GotoXY(AddingButton2X1,AddingButton2Y1+1); WRITE('        ');
               TextBackGround_BS(7);
               GotoXY(AddingButton2X1+1,AddingButton2Y1);
               TextColor_BS(4); WRITE('  A');
               TextColor_BS(0); WRITE('dd  ');
          END;
     6:   BEGIN
               TextBackGround_BS(1);
               GotoXY(DeletingButton2X1,DeletingButton2Y1);   WRITE('           ');
               GotoXY(DeletingButton2X1,DeletingButton2Y1+1); WRITE('           ');
               TextBackGround_BS(7);
               GotoXY(DeletingButton2X1+1,DeletingButton2Y1);
               TextColor_BS(4); WRITE('  D');
               TextColor_BS(0); WRITE('elete  ');
          END;
     7:   BEGIN
               TextBackGround_BS(1);
               GotoXY(EditingButton2X1,EditingButton2Y1);   WRITE('         ');
               GotoXY(EditingButton2X1,EditingButton2Y1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(EditingButton2X1+1,EditingButton2Y1);
               TextColor_BS(4); WRITE('  E');
               TextColor_BS(0); WRITE('dit  ');
          END;
     8:   BEGIN
               TextBackGround_BS(1);
               GotoXY(CopyingButton2X1,CopyingButton2Y1);   WRITE('         ');
               GotoXY(CopyingButton2X1,CopyingButton2Y1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(CopyingButton2X1+1,CopyingButton2Y1);
               TextColor_BS(4); WRITE('  C');
               TextColor_BS(0); WRITE('opy  ');
          END;
     9:   BEGIN
               TextBackGround_BS(1);
               GotoXY(MovingButton2X1,MovingButton2Y1);   WRITE('         ');
               GotoXY(MovingButton2X1,MovingButton2Y1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(MovingButton2X1+1,MovingButton2Y1);
               TextColor_BS(4); WRITE('  M');
               TextColor_BS(0); WRITE('ove  ');
          END;
     END;
     _ShowMouse;
END;


PROCEDURE SetUpPickingList2(WindowTitle: String);
VAR
     Loop         : Word;
BEGIN
     DrawWindow(1,1,80,24,WindowTitle,False);
     _HideMouse;
     TextBackGround_BS(0);
     TextColor_BS(14);
     GotoXY(PickingList2X-4,PickingList2Y+2);
     WRITE(PickingListTitle2);
     TextBackGround_BS(7);

     ScrollingBar2X  := 79;
     ScrollingBar2Y1 := PickingList2Y+3;
     ScrollingBar2Y2 := PickingList2Y+2+PickingListPerPage2;

     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile2);
     SEEK(FPickingListFile2,PickingTop2-1);
     FOR Loop := 1 TO PickingListPerPage2 DO
     BEGIN
          IF NOT(EOF(FPickingListFile2)) THEN
          BEGIN
               IF (PickingTop2-1+Loop)=PickingItem2 THEN TextBackGround_BS(15);
               READ(FPickingListFile2,PickingListFile2);
          END
          ELSE PickingListFile2.A := '';

          PickingListFile2.A := _PadRight(PickingListFile2.A,77);
          GotoXY(PickingList2X-4,PickingList2Y+2+Loop);
          TextColor_BS(0); WRITE(_Mid(PickingListFile2.A,1,13));
          TextColor_BS(9);
          IF _Mid(PickingListFile2.A,15,22)='  Orphan' THEN TextColor_BS(4);
          IF _Mid(PickingListFile2.A,15,22)=' Missing' THEN TextColor_BS(4);
          WRITE(_Mid(PickingListFile2.A,14,22));
          TextColor_BS(1);
          WRITE(_Mid(PickingListFile2.A,23,77));

          TextColor_BS(11);
          IF ((Loop<>1) AND (Loop<>PickingListPerPage2)) THEN
          BEGIN
               TextColor_BS(8);
               TextBackGround_BS(0);
               GotoXY(PickingList2X+73,PickingList2Y+2+Loop);
               WRITE('²');
          END;
          TextBackGround_BS(7);
     END;
     CLOSE(FPickingListFile2);
     TextColor_BS(15);
     TextBackGround_BS(7);
     GotoXY(ScrollingBar2X,ScrollingBar2Y1);
     WRITE(CHR(30));
     GotoXY(ScrollingBar2X,ScrollingBar2Y2);
     WRITE(CHR(31));
     ScrollingPad2Y := (ScrollingBar2Y2-1)-(ScrollingBar2Y1+1);
     ScrollingPad2Y := ScrollingPad2Y*(PickingItem2-1);
     IF PickingListItems2>1 THEN ScrollingPad2Y := Round(ScrollingPad2Y/(PickingListItems2-1))
                            ELSE ScrollingPad2Y := 0;
     GotoXY(ScrollingBar2X,ScrollingBar2Y1+1+ScrollingPad2Y);
     TextColor_BS(15);
     TextBackGround_BS(7);
     WRITE(CHR(254));
     DrawPickingListButtons2;
     _ShowMouse;
END;


PROCEDURE UpdatePickingList2;
VAR
     Loop         : Word;
     OldPadY      : Word;
BEGIN
     OldPadY    := ScrollingPad2Y;
     ScrollingPad2Y := (ScrollingBar2Y2-1)-(ScrollingBar2Y1+1);
     ScrollingPad2Y := ScrollingPad2Y*(PickingItem2-1);
     IF PickingListItems2>1 THEN ScrollingPad2Y := Round(ScrollingPad2Y/(PickingListItems2-1))
                            ELSE ScrollingPad2Y := 0;
     _HideMouse;
     TextBackGround_BS(7);
     ASSIGN(FPickingListFile2,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile2);
     SEEK(FPickingListFile2,PickingTop2-1);
     FOR Loop := 1 TO PickingListPerPage2 DO
     BEGIN
          IF NOT(EOF(FPickingListFile2)) THEN
          BEGIN
               IF (PickingTop2-1+Loop)=PickingItem2 THEN TextBackGround_BS(15);
               READ(FPickingListFile2,PickingListFile2);
          END
          ELSE PickingListFile2.A := '';

          PickingListFile2.A := _PadRight(PickingListFile2.A,77);
          GotoXY(PickingList2X-4,PickingList2Y+2+Loop);
          TextColor_BS(0); WRITE(_Mid(PickingListFile2.A,1,13));
          TextColor_BS(9);
          IF _Mid(PickingListFile2.A,15,22)='  Orphan' THEN TextColor_BS(4);
          IF _Mid(PickingListFile2.A,15,22)=' Missing' THEN TextColor_BS(4);
          WRITE(_Mid(PickingListFile2.A,14,22));
          TextColor_BS(1);
          WRITE(_Mid(PickingListFile2.A,23,77));

          TextColor_BS(11);
          IF (OldPadY<>ScrollingPad2Y) THEN
          BEGIN
               IF ((Loop<>1) AND (Loop<>PickingListPerPage2)) THEN
               BEGIN
                    TextColor_BS(8);
                    TextBackGround_BS(0);
                    GotoXY(PickingList2X+73,PickingList2Y+2+Loop);
                    WRITE('²');
               END;
          END;
          TextBackGround_BS(7);
     END;
     CLOSE(FPickingListFile2);
     IF (OldPadY<>ScrollingPad2Y) THEN
     BEGIN
          GotoXY(ScrollingBar2X,ScrollingBar2Y1+1+ScrollingPad2Y);
          TextColor_BS(15);
          TextBackGround_BS(7);
          WRITE(CHR(254));
     END;
     _ShowMouse;
END;


FUNCTION DoPickingList2: Word;
VAR  Changes      : Boolean;
     c            : Char;
     Number       : Longint;
     Work         : Longint;
     LeftBox      : Boolean;
LABEL               ArrowUp,ArrowDown;
LABEL               PushButton2,PushButton3;
LABEL               PushButton4,PushButton5;
LABEL               PushButton6,PushButton7;
LABEL               PushButton8,PushButton9;
BEGIN
     Changes := False;
     Number  := 0;
     REPEAT
           MouseB := _MousePosition(Mouse_X,Mouse_Y);
           IF MouseB=1 THEN
           BEGIN
                IF ((Mouse_X>PickingList2X-5) AND (Mouse_X<PickingList2X+73) AND
                   (Mouse_Y>PickingList2Y+2) AND (Mouse_Y<PickingList2Y+PickingListPerPage2+3)) THEN
                BEGIN
                     Work := Mouse_Y-(PickingList2Y+2);
                     IF ((Work+PickingTop2-1<>PickingItem2) AND (Work+PickingTop2-1<=PickingListItems2)) THEN
                     BEGIN
                          PickingItem2 := Work+PickingTop2-1;
                          UpdatePickingList2;
                     END;
                END
                ELSE IF Mouse_X=ScrollingBar2X THEN
                BEGIN
                     IF Mouse_Y=ScrollingBar2Y1 THEN GOTO ArrowUp
                        ELSE IF Mouse_Y=ScrollingBar2Y2 THEN GOTO ArrowDown;
                END
                ELSE IF (Mouse_Y=QuittingButton2Y1) THEN
                BEGIN
                     IF ((Mouse_X>=QuittingButton2X1) AND (Mouse_X<=QuittingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(2);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>QuittingButton2Y1) OR (Mouse_X<QuittingButton2X1) OR (Mouse_X>QuittingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(2);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton2:
                               Number  := 0;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=OrphaningButton2X1) AND (Mouse_X<=OrphaningButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(3);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>OrphaningButton2Y1) OR
                                   (Mouse_X<OrphaningButton2X1) OR
                                   (Mouse_X>OrphaningButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(3);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton3:
                               Number  := 3;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=ImportingButton2X1) AND (Mouse_X<=ImportingButton2X2)) THEN
                     BEGIN
                          IF HasFilesBBS THEN
                          BEGIN
                               PressPickingListButton2(4);
                               LeftBox := False;
                               REPEAT
                                     MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                     IF ((Mouse_Y<>ImportingButton2Y1) OR
                                        (Mouse_X<ImportingButton2X1) OR
                                        (Mouse_X>ImportingButton2X2))
                                        THEN LeftBox := True;
                               UNTIL ((MouseB<>1) OR (LeftBox));
                               ReleasePickingListButton2(4);
                               IF LeftBox=False THEN
                               BEGIN
                                    PushButton4:
                                    Number  := 4;
                                    Changes := True;
                               END;
                          END;
                     END
                     ELSE IF ((Mouse_X>=AddingButton2X1) AND (Mouse_X<=AddingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(5);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>AddingButton2Y1) OR (Mouse_X<AddingButton2X1) OR (Mouse_X>AddingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(5);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton5:
                               Number  := 5;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=DeletingButton2X1) AND (Mouse_X<=DeletingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(6);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>DeletingButton2Y1) OR (Mouse_X<DeletingButton2X1) OR (Mouse_X>DeletingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(6);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton6:
                               Number  := 6;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=EditingButton2X1) AND (Mouse_X<=EditingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(7);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>EditingButton2Y1) OR (Mouse_X<EditingButton2X1) OR (Mouse_X>EditingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(7);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton7:
                               Number  := 7;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=CopyingButton2X1) AND (Mouse_X<=CopyingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(8);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>CopyingButton2Y1) OR (Mouse_X<CopyingButton2X1) OR (Mouse_X>CopyingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(8);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton8:
                               Number  := 8;
                               Changes := True;
                          END;
                     END
                     ELSE IF ((Mouse_X>=MovingButton2X1) AND (Mouse_X<=MovingButton2X2)) THEN
                     BEGIN
                          PressPickingListButton2(9);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>MovingButton2Y1) OR (Mouse_X<MovingButton2X1) OR (Mouse_X>MovingButton2X2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton2(9);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton9:
                               Number  := 9;
                               Changes := True;
                          END;
                     END;
                END;
           END;
           IF Keypressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     CASE ORD(c) OF
                     45:  ShutDown;
                     60:  ShellToDos;
                     68 : DumpTheScreen;
                     73:  BEGIN {PageUp}
                               IF PickingListItems2>PickingListPerPage2 THEN
                               BEGIN
                                    IF (PickingTop2>PickingListPerPage2)
                                       THEN PickingTop2 := (PickingTop2-PickingListPerPage2)
                                       ELSE PickingTop2 := 1;
                                    IF (PickingItem2<PickingTop2)
                                       THEN PickingItem2 := PickingTop2
                                       ELSE IF (PickingItem2>(PickingTop2-1+PickingListPerPage2))
                                       THEN PickingItem2 := PickingTop2-1+PickingListPerPage2;
                                    UpdatePickingList2;
                               END;
                          END;
                     81:  BEGIN {PageDown}
                               IF PickingListItems2>PickingListPerPage2 THEN
                               BEGIN
                                    IF (PickingTop2<(PickingListItems2-PickingListPerPage2))
                                       THEN PickingTop2 := (PickingTop2+PickingListPerPage2)
                                       ELSE PickingTop2 := PickingListItems2;
                                    IF (PickingItem2<PickingTop2)
                                       THEN PickingItem2 := PickingTop2
                                       ELSE IF (PickingItem2>(PickingTop2-1+PickingListPerPage2))
                                       THEN PickingItem2 := PickingTop2-1+PickingListPerPage2;
                                    UpdatePickingList2;
                               END;
                          END;
                     72:  BEGIN {ArrowUp}
                               ArrowUp:
                               IF PickingItem2>1 THEN
                               BEGIN
                                    DEC(PickingItem2);
                                    IF (PickingItem2<PickingTop2) THEN DEC(PickingTop2);
                                    UpdatePickingList2;
                               END;
                          END;
                     80:  BEGIN {ArrowDown}
                               ArrowDown:
                               IF PickingItem2<PickingListItems2 THEN
                               BEGIN
                                    INC(PickingItem2);
                                    IF (PickingItem2>(PickingTop2-1+PickingListPerPage2)) THEN INC(PickingTop2);
                                    UpdatePickingList2;
                               END;
                          END;
                     132: BEGIN {CTRL-PgUp}
                               PickingItem2 := 1;
                               PickingTop2  := 1;
                               UpdatePickingList2;
                          END;
                     118: BEGIN {CTRL-PgDn}
                               PickingItem2 := PickingListItems2;
                               PickingTop2  := PickingListItems2;
                               UpdatePickingList2;
                          END;
                     16:  GOTO PushButton2;
                     24:  GOTO PushButton3;
                     48:  IF HasFilesBBS THEN GOTO PushButton4;
                     30:  GOTO PushButton5;
                     32:  GOTO PushButton6;
                     18:  GOTO PushButton7;
                     46:  GOTO PushButton8;
                     50:  GOTO PushButton9;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(c) OF
                     32:  BEGIN
                               Number  := 10;
                               Changes := True;
                          END;
                     13:  BEGIN
                               Number  := 7;
                               Changes := True;
                          END;
                     27:  BEGIN
                               Number  := 0;
                               Changes := True;
                          END;
                     END;
                END;
           END;
     UNTIL Changes;
     DoPickingList2 := Number;
END;


END.
