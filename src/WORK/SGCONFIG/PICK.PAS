{$I DEFINES.INC}
UNIT Pick;


INTERFACE


USES BsMouse,CRT,IntrFace,BsString,BsFile,Dispatch,DosShell;


TYPE PickRecord=RECORD
     A         : String[40];
     END;
VAR
     PickingListFile    : PickRecord;
     FPickingListFile   : File Of PickRecord;
     SelectingButtonX1  : Word;
     SelectingButtonX2  : Word;
     SelectingButtonY1  : Word;
     QuittingButtonX1   : Word;
     QuittingButtonX2   : Word;
     QuittingButtonY1   : Word;
     PickingListX       : Word;
     PickingListY       : Word;
     PickingListPerPage : Word;
     PickingListTitle   : String;
     ScrollingBarX      : Word;
     ScrollingBarY1     : Word;
     ScrollingBarY2     : Word;
     ScrollingPadY      : Word;
     PickingTop         : Word;
     PickingItem        : Word;
     PickingListItems   : Word;


PROCEDURE UpdatePickingList;
PROCEDURE DrawPickingListButtons;
PROCEDURE ReleasePickingListButton  (Number: Byte);
PROCEDURE PressPickingListButton    (Number: Byte);
PROCEDURE SetUpPickingList          (WindowTitle: String);
FUNCTION  DoPickingList             : Word;


IMPLEMENTATION


USES CnfgVars;


PROCEDURE DrawPickingListButtons;
VAR
     Loop         : Word;
BEGIN
     _HideMouse;
     SelectingButtonX1 := PickingListX+44;
     SelectingButtonX2 := PickingListX+51;
     SelectingButtonY1 := PickingListY+PickingListPerPage-1;
     QuittingButtonX1  := PickingListX+44;
     QuittingButtonX2  := PickingListX+51;
     QuittingButtonY1  := PickingListY+PickingListPerPage+1;

     FOR Loop := QuittingButtonX1 TO QuittingButtonX2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,QuittingButtonY1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(Loop+1,QuittingButtonY1+1);
          WRITE('ß');
     END;
     GotoXY(QuittingButtonX2+1,QuittingButtonY1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(QuittingButtonX1,QuittingButtonY1); WRITE(' C');
     TextColor_BS(0);
     WRITE('ancel ');
     _ShowMouse;

     FOR Loop := SelectingButtonX1 TO SelectingButtonX2 DO
     BEGIN
          TextBackGround_BS(7);
          TextColor_BS(4);
          GotoXY(Loop,SelectingButtonY1);
          WRITE(' ');
          {BUTTON SHADOW}
          TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(Loop+1,SelectingButtonY1+1);
          WRITE('ß');
     END;
     GotoXY(SelectingButtonX2+1,SelectingButtonY1);
     WRITE('Ü');
     TextBackGround_BS(7);
     TextColor_BS(4);
     GotoXY(SelectingButtonX1,SelectingButtonY1); WRITE(' S');
     TextColor_BS(0);
     WRITE('elect ');
     _ShowMouse;
END;


PROCEDURE ReleasePickingListButton(Number: Byte);
VAR
     Loop         : Word;
BEGIN
     _HideMouse;
     CASE Number Of
     1:   BEGIN {SELECT}
               FOR Loop := SelectingButtonX1 TO SelectingButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,SelectingButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,SelectingButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(SelectingButtonX2+1,SelectingButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(SelectingButtonX1,SelectingButtonY1); WRITE(' S');
               TextColor_BS(0);
               WRITE('elect ');
          END;
     2:   BEGIN {CANCEL}
               FOR Loop := QuittingButtonX1 TO QuittingButtonX2 DO
               BEGIN
                    TextBackGround_BS(7);
                    TextColor_BS(4);
                    GotoXY(Loop,QuittingButtonY1);
                    WRITE(' ');
                    {BUTTON SHADOW}
                    TextColor_BS(0); TextBackGround_BS(Colour.WindowBackGround);
                    GotoXY(Loop+1,QuittingButtonY1+1);
                    WRITE('ß');
               END;
               GotoXY(QuittingButtonX2+1,QuittingButtonY1);
               WRITE('Ü');
               TextBackGround_BS(7);
               TextColor_BS(4);
               GotoXY(QuittingButtonX1,QuittingButtonY1); WRITE(' C');
               TextColor_BS(0);
               WRITE('ancel ');
               _ShowMouse;
          END;
     END;
     _ShowMouse;
END;


PROCEDURE PressPickingListButton(Number: Byte);
VAR
     Loop         : Word;
BEGIN
     _HideMouse;
     CASE Number OF
     1:   BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(SelectingButtonX1,SelectingButtonY1); WRITE('         ');
               GotoXY(SelectingButtonX1,SelectingButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(SelectingButtonX1+1,SelectingButtonY1);
               TextColor_BS(4); WRITE(' S');
               TextColor_BS(0); WRITE('elect ');
          END;
     2:   BEGIN
               TextBackGround_BS(Colour.WindowBackGround);
               GotoXY(QuittingButtonX1,QuittingButtonY1); WRITE('         ');
               GotoXY(QuittingButtonX1,QuittingButtonY1+1); WRITE('         ');
               TextBackGround_BS(7);
               GotoXY(QuittingButtonX1+1,QuittingButtonY1);
               TextColor_BS(4); WRITE(' C');
               TextColor_BS(0); WRITE('ancel ');
          END;
     END;
     _ShowMouse;
END;


PROCEDURE SetUpPickingList(WindowTitle: String);
VAR
     Loop         : Word;
BEGIN
     DrawWindow(PickingListX-5,PickingListY,PickingListX+54,PickingListY+PickingListPerPage+3,WindowTitle,True);
     _HideMouse;
     TextBackGround_BS(0);
     TextColor_BS(14);
     GotoXY(PickingListX-4,PickingListY+2);
     WRITE('###  ');
     WRITE(PickingListTitle);
     TextBackGround_BS(Colour.WindowBackGround);
     ScrollingBarX  := PickingListX+42;
     ScrollingBarY1 := PickingListY+3;
     ScrollingBarY2 := PickingListY+2+PickingListPerPage;

     ASSIGN(FPickingListFile,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile);
     SEEK(FPickingListFile,PickingTop-1);
     FOR Loop := 1 TO PickingListPerPage DO
     BEGIN
          IF NOT(EOF(FPickingListFile)) THEN
          BEGIN
               IF (PickingTop-1+Loop)=PickingItem THEN TextBackGround_BS(3);
               TextColor_BS(14);
               GotoXY(PickingListX-4,PickingListY+2+Loop);
               WRITE(_PadRight(_String(PickingTop-1+Loop),6));
               READ(FPickingListFile,PickingListFile);
          END
          ELSE
          BEGIN
               GotoXY(PickingListX-4,PickingListY+2+Loop);
               WRITE('      ');
               PickingListFile.A := '';
          END;
          TextColor_BS(15);
          GotoXY(PickingListX+2,PickingListY+2+Loop);
          WRITE(_PadRight(PickingListFile.A,40));
          TextColor_BS(11);
          IF ((Loop<>1) AND (Loop<>PickingListPerPage)) THEN
          BEGIN
               TextColor_BS(8);
               TextBackGround_BS(0);
               GotoXY(PickingListX+42,PickingListY+2+Loop);
               WRITE('²');
          END;
          TextBackGround_BS(Colour.WindowBackGround);
     END;
     CLOSE(FPickingListFile);
     TextColor_BS(15);
     TextBackGround_BS(7);
     GotoXY(ScrollingBarX,ScrollingBarY1);
     WRITE(CHR(30));
     GotoXY(ScrollingBarX,ScrollingBarY2);
     WRITE(CHR(31));
     ScrollingPadY := (ScrollingBarY2-1)-(ScrollingBarY1+1);
     ScrollingPadY := ScrollingPadY*(PickingItem-1);
     IF PickingListItems>1 THEN ScrollingPadY := Round(ScrollingPadY/(PickingListItems-1))
                           ELSE ScrollingPadY := 0;
     GotoXY(ScrollingBarX,ScrollingBarY1+1+ScrollingPadY);
     TextColor_BS(15);
     TextBackGround_BS(7);
     WRITE(CHR(254));
     DrawPickingListButtons;
     _ShowMouse;
END;


PROCEDURE UpdatePickingList;
VAR
     Loop         : Word;
     OldPadY      : Word;
BEGIN
     OldPadY    := ScrollingPadY;
     ScrollingPadY := (ScrollingBarY2-1)-(ScrollingBarY1+1);
     ScrollingPadY := ScrollingPadY*(PickingItem-1);
     IF PickingListItems>1 THEN ScrollingPadY := Round(ScrollingPadY/(PickingListItems-1))
                           ELSE ScrollingPadY := 0;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     ASSIGN(FPickingListFile,WorkDir+'\PICKING.LST');
     RESET(FPickingListFile);
     SEEK(FPickingListFile,PickingTop-1);
     FOR Loop := 1 TO PickingListPerPage DO
     BEGIN
          IF NOT(EOF(FPickingListFile)) THEN
          BEGIN
               IF (PickingTop-1+Loop)=PickingItem THEN TextBackGround_BS(3);
               TextColor_BS(14);
               GotoXY(PickingListX-4,PickingListY+2+Loop);
               WRITE(_PadRight(_String(PickingTop-1+Loop),6));
               READ(FPickingListFile,PickingListFile);
          END
          ELSE
          BEGIN
               GotoXY(PickingListX-4,PickingListY+2+Loop);
               WRITE('      ');
               PickingListFile.A := '';
          END;
          TextColor_BS(15);
          GotoXY(PickingListX+2,PickingListY+2+Loop);
          WRITE(_PadRight(PickingListFile.A,40));
          TextColor_BS(11);
          IF (OldPadY<>ScrollingPadY) THEN
          BEGIN
               IF ((Loop<>1) AND (Loop<>PickingListPerPage)) THEN
               BEGIN
                    TextColor_BS(8);
                    TextBackGround_BS(0);
                    GotoXY(PickingListX+42,PickingListY+2+Loop);
                    WRITE('²');
               END;
          END;
          TextBackGround_BS(Colour.WindowBackGround);
     END;
     CLOSE(FPickingListFile);
     IF (OldPadY<>ScrollingPadY) THEN
     BEGIN
          GotoXY(ScrollingBarX,ScrollingBarY1+1+ScrollingPadY);
          TextColor_BS(15);
          TextBackGround_BS(7);
          WRITE(CHR(254));
     END;
     _ShowMouse;
END;


FUNCTION DoPickingList: Word;
VAR
     Changes      : Boolean;
     c            : Char;
     Number       : Longint;
     Work         : Longint;
     LeftBox      : Boolean;
LABEL               ArrowUp,ArrowDown;
LABEL               PushButton1,PushButton2;
BEGIN
     Changes := False;
     Number  := 0;
     REPEAT
           Memory;
           MouseB := _MousePosition(Mouse_X,Mouse_Y);
           IF MouseB=1 THEN
           BEGIN
                IF ((Mouse_X>PickingListX-5) AND (Mouse_X<PickingListX+42)) THEN
                BEGIN
                     IF ((Mouse_Y>PickingListY+2) AND (Mouse_Y<PickingListY+PickingListPerPage+3)) THEN
                     BEGIN
                          Work := Mouse_Y-(PickingListY+2);
                          IF ((Work+PickingTop-1<>PickingItem) AND (Work+PickingTop-1<=PickingListItems)) THEN
                          BEGIN
                               PickingItem := Work+PickingTop-1;
                               UpdatePickingList;
                          END;
                     END;
                END
                ELSE IF Mouse_X=ScrollingBarX THEN
                BEGIN
                     IF Mouse_Y=ScrollingBarY1 THEN GOTO ArrowUp
                        ELSE IF Mouse_Y=ScrollingBarY2 THEN GOTO ArrowDown;
                END
                ELSE IF ((Mouse_X>=SelectingButtonX1) AND (Mouse_X<=SelectingButtonX2)) THEN
                BEGIN
                     IF (Mouse_Y=SelectingButtonY1) THEN
                     BEGIN
                          PressPickingListButton(1);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>SelectingButtonY1) OR (Mouse_X<SelectingButtonX1) OR (Mouse_X>SelectingButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton(1);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton1:
                               Number  := 1;
                               Changes := True;
                          END;
                     END
                     ELSE IF (Mouse_Y=QuittingButtonY1) THEN
                     BEGIN
                          PressPickingListButton(2);
                          LeftBox := False;
                          REPEAT
                                MouseB := _MousePosition(Mouse_X,Mouse_Y);
                                IF ((Mouse_Y<>QuittingButtonY1) OR (Mouse_X<QuittingButtonX1) OR (Mouse_X>QuittingButtonX2))
                                   THEN LeftBox := True;
                          UNTIL ((MouseB<>1) OR (LeftBox));
                          ReleasePickingListButton(2);
                          IF LeftBox=False THEN
                          BEGIN
                               PushButton2:
                               Number  := 0;
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
                               IF (PickingTop>PickingListPerPage)
                                  THEN PickingTop := (PickingTop-PickingListPerPage)
                                  ELSE PickingTop := 1;
                               IF (PickingItem<PickingTop)
                                  THEN PickingItem := PickingTop
                                  ELSE IF (PickingItem>(PickingTop-1+PickingListPerPage))
                                  THEN PickingItem := PickingTop-1+PickingListPerPage;
                               UpdatePickingList;
                          END;
                     81:  BEGIN {PageDown}
                               IF (PickingTop<(PickingListItems-PickingListPerPage))
                                  THEN PickingTop := (PickingTop+PickingListPerPage)
                                  ELSE PickingTop := PickingListItems;
                               IF (PickingItem<PickingTop)
                                  THEN PickingItem := PickingTop
                                  ELSE IF (PickingItem>(PickingTop-1+PickingListPerPage))
                                  THEN PickingItem := PickingTop-1+PickingListPerPage;
                               UpdatePickingList;
                          END;
                     72:  BEGIN {ArrowUp}
                               ArrowUp:
                               IF PickingItem>1 THEN
                               BEGIN
                                    DEC(PickingItem);
                                    IF (PickingItem<PickingTop) THEN DEC(PickingTop);
                                    UpdatePickingList;
                               END;
                          END;
                     80:  BEGIN {ArrowDown}
                               ArrowDown:
                               IF PickingItem<PickingListItems THEN
                               BEGIN
                                    INC(PickingItem);
                                    IF (PickingItem>(PickingTop-1+PickingListPerPage)) THEN INC(PickingTop);
                                    UpdatePickingList;
                               END;
                          END;
                     132: BEGIN {CTRL-PgUp}
                               PickingItem := 1;
                               PickingTop  := 1;
                               UpdatePickingList;
                          END;
                     118: BEGIN {CTRL-PgDn}
                               PickingItem := PickingListItems;
                               PickingTop  := PickingListItems;
                               UpdatePickingList;
                          END;
                     31:  GOTO PushButton1;
                     46:  GOTO PushButton2;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(c) OF
                     13,
                     32:  BEGIN
                               Number  := 1;
                               Changes := True;
                          END;
                     27:  BEGIN
                               Changes := True;
                               Number  := 0;
                          END;
                     END;
                END;
           END;
     UNTIL Changes;
     DoPickingList := Number;
END;


END.
