{$I DEFINES.INC}
UNIT _BHandle;


INTERFACE


FUNCTION HandleKeys    (C: Char; Alt_Key: Boolean)  : Boolean;
FUNCTION ButtonHandler                              : Char;


IMPLEMENTATION


USES _Fields,Globals,_Pick,Gr2_Bp,_Icons,Gx2_Bp,ApTimer,
     Gx2_BpVC,_DragDrp,ApCom,BsGraph,_Buffers,_Mouse,BsString;


FUNCTION HandleKeys(C: Char; Alt_Key: Boolean): Boolean;
VAR  ThePos : Word;
LABEL         DnArrow;

     PROCEDURE ProcessProperName;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          IF ThePos<>1 THEN
          BEGIN
               IF (ThePos<>2) THEN
               BEGIN
                    IF Fields[FieldNum].Text[ThePos-1]=' ' THEN C := UpCase(C);
               END;
          END
          ELSE C := UpCase(C);
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,
                                   LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessUpperCaseString;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                   UpCase(C)+_Mid(Fields[FieldNum].Text,
                                   ThePos,LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessDate;
     BEGIN
          IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text[ThePos] := C;
               IF (Fields[FieldNum].CursorPos<>10)
                  THEN INC(Fields[FieldNum].CursorPos);
               CASE Fields[FieldNum].CursorPos OF
               3:   INC(Fields[FieldNum].CursorPos);
               6:   INC(Fields[FieldNum].CursorPos);
               END;
          END;
     END;

     PROCEDURE ProcessPhoneNumber;
     BEGIN
          IF (((ORD(c)>47) AND (ORD(c)<58)) OR (c='-')) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

     PROCEDURE ProcessNumeric;
     BEGIN
          IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                        _Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

     PROCEDURE ProcessPlainString;
     BEGIN
          ThePos := Fields[FieldNum].CursorPos;
          Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                   C+_Mid(Fields[FieldNum].Text,
                                   ThePos,LENGTH(Fields[FieldNum].Text));
          INC(Fields[FieldNum].CursorPos);
     END;

     PROCEDURE ProcessFileName;
     BEGIN
          C := UpCase(C);
          IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR
             (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_')) THEN
          BEGIN
               ThePos := Fields[FieldNum].CursorPos;
               Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                        C+_Mid(Fields[FieldNum].Text,ThePos,
                                        LENGTH(Fields[FieldNum].Text));
               INC(Fields[FieldNum].CursorPos);
          END;
     END;

BEGIN
     HandleKeys := False;
     IF NFields=0 THEN
     BEGIN
          IF ((Alt_Key) AND (PickInfo.Active)) THEN
          BEGIN {Alt Keys}
               GrDisplayMouse(GrHide);
               CASE ORD(c) OF
               72:  ScrollPickUp;
               73:  ScrollPickPgUp;
               80:  ScrollPickDown;
               81:  ScrollPickPgDown;
               132: ScrollPickTop;
               118: ScrollPickBottom;
               END;
               GrDisplayMouse(GrShow);
          END;
          Exit;
     END;
     GrDisplayMouse(GrHide);
     IF Alt_Key THEN
     BEGIN {Alt Keys}
          CASE ORD(c) OF
          15,72: BEGIN {SHIFT TAB & UpArrow}
                      IF NFields=1 THEN
                      BEGIN
                           IF ORD(c)=72 THEN ScrollPickUp;
                      END
                      ELSE
                      BEGIN
                           IF FieldNum=1 THEN ChangeField(NFields)
                                         ELSE ChangeField(FieldNum-1);
                      END;
                      HandleKeys := True;
                 END;
          80:    BEGIN {DownArrow}
                      IF NFields=1 THEN
                      BEGIN
                           ScrollPickDown;
                      END
                      ELSE
                      BEGIN
                           DnArrow:
                           IF FieldNum=NFields THEN ChangeField(1)
                                               ELSE ChangeField(FieldNum+1);
                      END;
                      HandleKeys := True;
                 END;
          71:    BEGIN {HOME}
                      IF (Fields[FieldNum].CursorPos<>1) THEN
                      BEGIN
                           Fields[FieldNum].CursorPos := 1;
                           RedrawField;
                      END;
                      HandleKeys := True;
                 END;
          79:    BEGIN {END}
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<>Fields[FieldNum].Length) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := Fields[FieldNum].Length;
                                RedrawField;
                           END;
                      END
                      ELSE
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<>LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
                                RedrawField;
                           END;
                      END;
                      HandleKeys := True;
                 END;
          75:    BEGIN {Left}
                      IF (Fields[FieldNum].CursorPos>1) THEN
                      BEGIN
                           DEC(Fields[FieldNum].CursorPos);
                           IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                           BEGIN
                                CASE Fields[FieldNum].CursorPos OF
                                3:   DEC(Fields[FieldNum].CursorPos);
                                6:   DEC(Fields[FieldNum].CursorPos);
                                END;
                           END;
                           RedrawField;
                      END;
                      HandleKeys := True;
                 END;
          77:    BEGIN {Right}
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<Fields[FieldNum].Length) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                                CASE Fields[FieldNum].CursorPos OF
                                3:   INC(Fields[FieldNum].CursorPos);
                                6:   INC(Fields[FieldNum].CursorPos);
                                END;
                                RedrawField;
                           END;
                      END
                      ELSE
                      BEGIN
                           IF (Fields[FieldNum].CursorPos<LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                                RedrawField;
                           END;
                      END;
                      HandleKeys := True;
                 END;
          83:    BEGIN {DELETE}
                      ThePos := Fields[FieldNum].CursorPos;
                      IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                      BEGIN
                           Fields[FieldNum].Text[ThePos] := ' ';
                           RedrawField;
                      END
                      ELSE
                      BEGIN
                           IF (ThePos<=LENGTH(Fields[FieldNum].Text)) THEN
                           BEGIN
                                Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                                         _Mid(Fields[FieldNum].Text,ThePos+1,
                                                         LENGTH(Fields[FieldNum].Text));
                                RedrawField;
                           END;
                      END;
                      HandleKeys := True;
                 END;
          73:    IF PickInfo.Active THEN ScrollPickPgUp;
          81:    IF PickInfo.Active THEN ScrollPickPgDown;
          132:   IF PickInfo.Active THEN ScrollPickTop;
          118:   IF PickInfo.Active THEN ScrollPickBottom;
          END;
     END
     ELSE
     BEGIN
          CASE ORD(c) OF
          13,27:  ;
          8:   BEGIN {BACKSPACE}
                    ThePos := Fields[FieldNum].CursorPos;
                    IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                    BEGIN
                         CASE ThePos OF
                         2,5,8: BEGIN
                                     Fields[FieldNum].Text[ThePos-1] := ' ';
                                     DEC(Fields[FieldNum].CursorPos);
                                END;
                         4,7:   BEGIN
                                     Fields[FieldNum].Text[ThePos-2] := ' ';
                                     DEC(Fields[FieldNum].CursorPos,2);
                                END;
                         END;
                         RedrawField;
                    END
                    ELSE
                    BEGIN
                         IF ThePos>1 THEN
                         BEGIN
                              Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-2)+
                                                       _Mid(Fields[FieldNum].Text,ThePos,
                                                       LENGTH(Fields[FieldNum].Text));
                              DEC(Fields[FieldNum].CursorPos);
                              RedrawField;
                         END;
                    END;
                    HandleKeys := True;
               END;
          9:   BEGIN {TAB}
                    IF FieldNum=NFields THEN ChangeField(1)
                                        ELSE ChangeField(FieldNum+1);
                    HandleKeys := True;
               END;
          127: BEGIN {Ctrl-Backspace}
                    IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
                    BEGIN
                         Fields[FieldNum].Text := '  /  /  ';
                         Fields[FieldNum].CursorPos := 1;
                         RedrawField;
                    END
                    ELSE
                    BEGIN
                         Fields[FieldNum].Text := '';
                         Fields[FieldNum].CursorPos := 1;
                         RedrawField;
                    END;
                    HandleKeys := True;
               END;
          ELSE IF ((Ord(c)>31) AND (Ord(c)<128)) THEN
            BEGIN
              IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18)) THEN
              BEGIN
                   ProcessDate;
                   RedrawField;
              END
              ELSE IF (LENGTH(Fields[FieldNum].Text)<Fields[FieldNum].Length) THEN
              BEGIN
                   CASE Fields[FieldNum].EntryType OF
                   1:   ProcessProperName;      {user's real name}
                   2:   ProcessProperName;      {user's alias}
                   3:   ProcessUpperCaseString; {user's password}
                   5:   ProcessProperName;      {user's street address}
                   6:   ProcessProperName;      {user's city}
                   7:   ProcessProperName;      {user's province}
                   8:   ProcessProperName;      {user's country}
                   9:   ProcessUpperCaseString; {user's postal code}
                   10:  ProcessPhoneNumber;     {user's data phone}
                   11:  ProcessPhoneNumber;     {user's voice phone}
                   12:  ProcessNumeric;         {Deposit Bytes}
                   13:  ProcessNumeric;         {Withdraw Bytes}
                   14:  ProcessNumeric;         {Deposit Minutes}
                   15:  ProcessNumeric;         {Withdraw Minutes}
                   16:  ProcessNumeric;         {# file display lines}
                   17:  ProcessFileName;
                   19:  ProcessNumeric;
                   20:  ProcessProperName;
                   21,22,23,24,25,26,27:
                        ProcessPlainString;
                   28:  ProcessProperName;
                   29:  ProcessPlainString;
                   30:  ProcessPhoneNumber;
                   31:  ProcessPlainString;
                   END;
                   RedrawField;
              END;
              HandleKeys := True;
            END;
          END;
     END;
     GrDisplayMouse(GrShow);
END;
{==========================================================================}
{                                                                          }
{     RETURNS EITHER A BUTTON THAT WAS PRESSED, A KEYPRESSED, OR NOTHING   }
{                                                                          }
{==========================================================================}
FUNCTION ButtonHandler: Char;
VAR  w         : Char;
     xxx       : Word;
     yyy       : Word;
     TheOne    : Word;
     Looper    : Word;
     NewXY     : Array[1..3] Of Byte;

     PROCEDURE PressButton(Num: Word);
     VAR  x1,y1,x2,y2 : Word;
          Loop        : Word;
     BEGIN
          x1 := Buttons^[Num].X1;
          x2 := Buttons^[Num].X2;
          y1 := Buttons^[Num].Y1;
          y2 := Buttons^[Num].Y2;
          GrDisplayMouse(GrHide);
          CASE Buttons^[Num].BType OF
          1:   BEGIN
                    GrSetColor(Buttons^[Num].FillC);
                    GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
               END;
          2:   BEGIN
                    GrSetColor(Buttons^[Num].FillC);
                    GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
               END;
          3:   {INVISIBLE ICON};
          4:   SystemIcon(x1,y1,52);
          END;
          IF (NCustom<>0) THEN
          BEGIN
               FOR Loop := 1 TO NCustom DO
               BEGIN
                    IF ((Custom[Loop].x1>=x1) AND (Custom[Loop].x2<=x2) AND
                       (Custom[Loop].y1>=y1) AND (Custom[Loop].y2<=y2)) THEN
                    BEGIN
                         gxVirtualDisplay(Custom[Loop].Icon2,0,0,Custom[Loop].x1,
                                          Custom[Loop].y1,Custom[Loop].x2,Custom[Loop].y2,0);
                    END;
               END;
          END;
          GrDisplayMouse(GrShow);
     END;

     PROCEDURE ReleaseButton(Num: Word);
     VAR  x1,y1,x2,y2 : Word;
          Loop        : Word;
     BEGIN
          x1 := Buttons^[Num].X1;
          x2 := Buttons^[Num].X2;
          y1 := Buttons^[Num].Y1;
          y2 := Buttons^[Num].Y2;
          GrDisplayMouse(GrHide);
          CASE Buttons^[Num].BType OF
          1:   BEGIN
                    GrSetColor(Buttons^[Num].DBorder);
                    GrDrawLine(x1+1,y2-1,x2-1,y2-1);
                    GrDrawLine(x2-1,y1+1,x2-1,y2-1);
                    GrSetColor(Buttons^[Num].HBorder);
                    GrDrawLine(x1+1,y1+1,x2-1,y1+1);
                    GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               END;
          2:   BEGIN
                    GrSetColor(Buttons^[Num].HBorder);
                    GrDrawRect(x1+1,y1+1,x2,y2,GrOutline);
                    GrSetColor(Buttons^[Num].DBorder);
                    GrDrawLine(x1,y1,x2,y1);
                    GrDrawLine(x1,y1,x1,y2);
                    GrDrawLine(x1+2,y2-1,x2-1,y2-1);
                    GrDrawLine(x2-1,y1+2,x2-1,y2-1);
               END;
          3:   {INVISIBLE ICON};
          4:   SystemIcon(x1,y1,51);
          END;
          IF (NCustom<>0) THEN
          BEGIN
               FOR Loop := 1 TO NCustom DO
               BEGIN
                    IF ((Custom[Loop].x1>=x1) AND (Custom[Loop].x2<=x2) AND
                       (Custom[Loop].y1>=y1) AND (Custom[Loop].y2<=y2)) THEN
                    BEGIN
                         gxVirtualDisplay(Custom[Loop].Icon1,0,0,Custom[Loop].x1,
                                          Custom[Loop].y1,Custom[Loop].x2,Custom[Loop].y2,0);
                    END;
               END;
          END;
          GrDisplayMouse(GrShow);
     END;

     PROCEDURE ProcessButton(xx,yy: Word);
     VAR  Loop  : Word;
          Found : Boolean;
          DeOne : Integer;
          Scrap : Word;
          Poop  : Word;
     BEGIN
          IF NFields<>0 THEN
          BEGIN
               FOR Loop := 1 TO NFields DO
               BEGIN
                    IF ((xx>Fields[Loop].x1) AND (xx<Fields[Loop].x2) AND
                       (yy>Fields[Loop].y1) AND (yy<Fields[Loop].y2)) THEN
                    BEGIN
                         IF Loop<>FieldNum THEN
                         BEGIN
                              PutStringTimeout(BBSPort,#254#251,YappDelay);
                              PutBlockTimeOut(BBSPort,Loop,2,Scrap,YappDelay);
                              GrDisplayMouse(GrHide);
                              ChangeField(Loop);
                              GrDisplayMouse(GrShow);
                              Exit;
                         END
                         ELSE
                         BEGIN
                              DeOne := xx-Fields[Loop].x1-9;
                              DeOne := Trunc(DeOne/8)+1;
                              IF DeOne<=0 THEN DeOne := 1;
                              IF DeOne>LENGTH(Fields[Loop].Text)+1 THEN
                                 DeOne := LENGTH(Fields[Loop].Text)+1;
                              IF ((Fields[Loop].EntryType=4) OR (Fields[Loop].EntryType=18)) THEN
                              BEGIN
                                   IF DeOne>8 THEN DeOne := 8;
                                   IF ((DeOne=3) OR (DeOne=6)) THEN DeOne := Fields[Loop].CursorPos;
                              END;
                              IF (DeOne<>Fields[Loop].CursorPos) THEN
                              BEGIN
                                   Poop := DeOne;
                                   PutStringTimeout(BBSPort,#254#252,YappDelay);
                                   PutBlockTimeOut(BBSPort,Poop,2,Scrap,YappDelay);
                                   Fields[Loop].CursorPos := DeOne;
                                   GrDisplayMouse(GrHide);
                                   RedrawField;
                                   GrDisplayMouse(GrShow);
                                   Exit;
                              END;
                         END;
                    END;
               END;
          END;
          IF LastPressed=0 THEN
          BEGIN
               Found := False;
               Loop  := 1;
               REPEAT
                     IF ((xx>=Buttons^[Loop].x1) AND (xx<=Buttons^[Loop].x2)) THEN
                     BEGIN
                          IF ((yy>=Buttons^[Loop].y1) AND (yy<=Buttons^[Loop].y2)) THEN
                          BEGIN
                               LastPressed := Loop;
                               Found       := True;
                          END;
                     END;
                     INC(Loop);
               UNTIL ((Loop>NButtons) OR (Found));
               IF Found THEN PressButton(LastPressed);
          END
          ELSE
          BEGIN
               {CHECK TO SEE IF THE USER MOVED OFF OF THE BUTTON}
               IF ((xx<Buttons^[LastPressed].x1) OR (xx>Buttons^[LastPressed].x2) OR
                   (yy<Buttons^[LastPressed].y1) OR (yy>Buttons^[LastPressed].y2)) THEN
               BEGIN
                    ReleaseButton(LastPressed);
                    LastPressed := 0;
               END;
          END;
     END;

     PROCEDURE move_frame(x1,y1,x2,y2: word);
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
          GrSetMouseBounds(old_m_x+5,old_m_y+5,GraphMaxX-x_add-5,YWindow-y_add-5);
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
          GrSetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
          GrSetLineStyle(GrLSolid,1);
          {RECALCULATE BUTTONS, AND WINDOW}
          IF ((X_Move<>0) OR (Y_Move<>0)) THEN
          BEGIN
               GrDisplayMouse(GrHide);
               {Load in and clear the background}
               SaveCutout(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2,ScreenInfo.Y2,1);
               LoadUnderGround(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2+5,ScreenInfo.Y2+5);
               OldX1 := ScreenInfo.X1;
               OldY1 := ScreenInfo.Y1;
               OldX2 := ScreenInfo.X2;
               OldY2 := ScreenInfo.Y2;
               ScreenInfo.X1 := ScreenInfo.X1+X_Move;
               ScreenInfo.Y1 := ScreenInfo.Y1+Y_Move;
               ScreenInfo.X2 := ScreenInfo.X2+X_Move;
               ScreenInfo.Y2 := ScreenInfo.Y2+Y_Move;
               ScreenInfo.MoveX := ScreenInfo.MoveX+X_Move;
               ScreenInfo.MoveY := ScreenInfo.MoveY+Y_Move;
               {Load back in the window at the new position}
               SavedCutouts[1].Coordinates[1] := SavedCutouts[1].Coordinates[1]+X_Move;
               SavedCutouts[1].Coordinates[2] := SavedCutouts[1].Coordinates[2]+Y_Move;
               SavedCutouts[1].Coordinates[3] := SavedCutouts[1].Coordinates[3]+X_Move;
               SavedCutouts[1].Coordinates[4] := SavedCutouts[1].Coordinates[4]+Y_Move;
               LoadCutout(1);
               GrSetFillStyle(GrFCloseDot,0,GrTrans);
               GrDrawRect(ScreenInfo.X1+5,ScreenInfo.Y2+1,ScreenInfo.X2+5,ScreenInfo.Y2+5,GrFill);
               GrDrawRect(ScreenInfo.X2+1,ScreenInfo.Y1+5,ScreenInfo.X2+5,ScreenInfo.Y2+5,GrFill);
               {Move the fields, if any}
               IF (NFields<>0) THEN
               BEGIN
                    FOR Loop := 1 TO NFields DO
                    BEGIN
                         IF ((Fields[Loop].x1>=OldX1) AND (Fields[Loop].x2<=OldX2) AND
                             (Fields[Loop].y1>=OldY1) AND (Fields[Loop].y2<=OldY2)) THEN
                         BEGIN
                              Fields[Loop].x1 := Fields[Loop].x1+X_Move;
                              Fields[Loop].y1 := Fields[Loop].y1+Y_Move;
                              Fields[Loop].x2 := Fields[Loop].x2+X_Move;
                              Fields[Loop].y2 := Fields[Loop].y2+Y_Move;
                         END;
                    END;
               END;
               {Move picklist, if any}
               IF PickInfo.Active THEN
               BEGIN
                    PickInfo.x1      := PickInfo.x1+X_Move;
                    PickInfo.y1      := PickInfo.y1+Y_Move;
                    PickInfo.x2      := PickInfo.x2+X_Move;
                    PickInfo.y2      := PickInfo.y2+Y_Move;
                    PickInfo.Locator := PickInfo.Locator+Y_Move;
               END;
               GrDisplayMouse(GrShow);
               {Move progress indicators,if any}
               IF Toggle.Active THEN
               BEGIN
                    IF ((Toggle.x1>=OldX1) AND (Toggle.x2<=OldX2) AND
                        (Toggle.y1>=OldY1) AND (Toggle.y2<=OldY2)) THEN
                    BEGIN
                         Toggle.x1 := Toggle.x1+X_Move;
                         Toggle.y1 := Toggle.y1+Y_Move;
                         Toggle.x2 := Toggle.x2+X_Move;
                         Toggle.y2 := Toggle.y2+Y_Move;
                    END;
               END;
               {Move the buttons}
               IF (NButtons<>0) THEN
               BEGIN
                    FOR Loop := 1 TO NButtons DO
                    BEGIN
                         IF ((Buttons^[Loop].x1>=OldX1) AND (Buttons^[Loop].x2<=OldX2) AND
                             (Buttons^[Loop].y1>=OldY1) AND (Buttons^[Loop].y2<=OldY2)) THEN
                         BEGIN
                              Buttons^[Loop].x1 := Buttons^[Loop].x1+X_Move;
                              Buttons^[Loop].y1 := Buttons^[Loop].y1+Y_Move;
                              Buttons^[Loop].x2 := Buttons^[Loop].x2+X_Move;
                              Buttons^[Loop].y2 := Buttons^[Loop].y2+Y_Move;
                         END;
                    END;
               END;
               {Move custom controls,if any}
               IF NCustom<>0 THEN
               BEGIN
                    FOR Loop := 1 TO NCustom DO
                    BEGIN
                         IF ((Custom[Loop].x1>=OldX1) AND (Custom[Loop].x2<=OldX2) AND
                             (Custom[Loop].y1>=OldY1) AND (Custom[Loop].y2<=OldY2)) THEN
                         BEGIN
                              Custom[Loop].x1 := Custom[Loop].x1+X_Move;
                              Custom[Loop].y1 := Custom[Loop].y1+Y_Move;
                              Custom[Loop].x2 := Custom[Loop].x2+X_Move;
                              Custom[Loop].y2 := Custom[Loop].y2+Y_Move;
                         END;
                    END;
               END;
               {Move animated controls, if any}
               IF NAnimate<>0 THEN
               BEGIN
                    FOR Loop := 1 TO NAnimate DO
                    BEGIN
                         IF ((Animate[Loop].x1>=OldX1) AND (Animate[Loop].x2<=OldX2) AND
                             (Animate[Loop].y1>=OldY1) AND (Animate[Loop].y2<=OldY2)) THEN
                         BEGIN
                              Animate[Loop].x1 := Animate[Loop].x1+X_Move;
                              Animate[Loop].y1 := Animate[Loop].y1+Y_Move;
                              Animate[Loop].x2 := Animate[Loop].x2+X_Move;
                              Animate[Loop].y2 := Animate[Loop].y2+Y_Move;
                         END;
                    END;
               END;
               {Move the pad if any}
               IF PadX1<>32000 THEN
               BEGIN
                    IF ((PadX1>=OldX1) AND (PadX2<=OldX2) AND
                        (PadY1>=OldY1) AND (PadY2<=OldY2)) THEN
                    BEGIN
                         PadX1 := PadX1+X_Move;
                         PadY1 := PadY1+Y_Move;
                         PadX2 := PadX2+X_Move;
                         PadY2 := PadY2+Y_Move;
                    END;
               END;
          END;
     END;

     PROCEDURE DoAnimatedIcons;
     VAR  Loop : Word;
     BEGIN
          IF (NAnimate<>0) THEN
          BEGIN
               IF TimerExpired(ATimer) THEN
               BEGIN
                    FOR Loop := 1 TO NAnimate DO
                    BEGIN
                         INC(Animate[Loop].Current);
                         IF Animate[Loop].Current=9 THEN Animate[Loop].Current := 1;
                         GrSetMouseProtect(Animate[Loop].x1,Animate[Loop].y1,
                                           Animate[Loop].x2,Animate[Loop].y2);
                         GrProtectMouse(GrProtect);
                         gxVirtualDisplay(Animate[Loop].Icon[Animate[Loop].Current],
                                          0,0,Animate[Loop].x1,Animate[Loop].y1,
                                          Animate[Loop].x2,Animate[Loop].y2,0);
                         GrProtectMouse(GrNoProtect);
                    END;
                    NewTimer(ATimer,1);
               END;
          END;
     END;

BEGIN
     xxx := GetMouseX;
     yyy := GetMouseY;
     w := Chr(0);
     DoAnimatedIcons;

     {=====================================================================}
     {  CHANGING OF THE MOUSE ROUTINE!                                     }
     {=====================================================================}

     CurMouse := 1;
     IF (NFields<>0) THEN
     BEGIN
          FOR Looper := 1 TO NFields DO
          BEGIN
               IF ((xxx>=Fields[Looper].x1) AND (xxx<=Fields[Looper].x2) AND
                  (yyy>=Fields[Looper].y1) AND (yyy<=Fields[Looper].y2)) THEN
               BEGIN
                    CurMouse := 2;
               END;
          END;
     END;
     IF PickInfo.Active THEN
     BEGIN
          IF ((xxx>=PickInfo.x1) AND (xxx<=PickInfo.x2) AND
             (yyy>=PickInfo.y1) AND (yyy<=PickInfo.y2)) THEN
          BEGIN
               IF MsgEditorKludge THEN CurMouse := 2
                                  ELSE CurMouse := 3;
          END;
     END;
     IF (NButtons<>0) THEN
     BEGIN
          FOR Looper := 1 TO NButtons DO
          BEGIN
               IF ((xxx>=Buttons^[Looper].x1) AND (xxx<=Buttons^[Looper].x2) AND
                  (yyy>=Buttons^[Looper].y1) AND (yyy<=Buttons^[Looper].y2)) THEN
               BEGIN
                    CurMouse := 3;
               END;
          END;
     END;
     IF ((ScreenInfo.HasWindow) AND (xxx>ScreenInfo.X1) AND
        (xxx<ScreenInfo.X2) AND (yyy>ScreenInfo.Y1) AND
        (yyy<ScreenInfo.Y1+24)) THEN
     BEGIN
          CurMouse := 4;
     END;
     IF CurMouse<>LastMouse THEN
     BEGIN
          CASE CurMouse OF
          1:   ChangeMouse(DefaultMouse);
          2:   ChangeMouse(InsertMouse);
          3:   ChangeMouse(BPressMouse);
          4:   ChangeMouse(WinMoveMouse);
          END;
     END;
     LastMouse := CurMouse;

     {=====================================================================}
     {  END CHANGING OF THE MOUSE ROUTINE!                                 }
     {=====================================================================}

     IF GrGetMouseButtons=GrLButton THEN
     BEGIN
          {================================================================}
          {  PICK LISTS                                                    }
          {================================================================}
          IF ((PickInfo.Active) AND (xxx>PickInfo.x2+1) AND
             (xxx<PickInfo.x2+21) AND (yyy>PickInfo.Locator) AND
             (yyy<PickInfo.Locator+20)) THEN
          BEGIN
               IF MoveLocator THEN
               BEGIN
                    GrDisplayMouse(GrHide);
                    DrawPickListLocator;
                    SetUpPickList;
                    GrDisplayMouse(GrShow);
               END;
          END
          ELSE IF ((PickInfo.Active) AND (xxx>PickInfo.x2+1) AND
                  (xxx<PickInfo.x2+21) AND (yyy>PickInfo.y1+21) AND
                  (yyy<PickInfo.Locator)) THEN
          BEGIN
               ScrollPickPgUp;
          END
          ELSE IF ((PickInfo.Active) AND (xxx>PickInfo.x2+1) AND
                  (xxx<PickInfo.x2+21) AND (yyy>PickInfo.Locator+20) AND
                  (yyy<PickInfo.y2-21)) THEN
          BEGIN
               ScrollPickPgDown;
          END
          {================================================================}
          {  DRAG WINDOWS AROUND                                           }
          {================================================================}
          ELSE IF ((ScreenInfo.HasWindow) AND (xxx>ScreenInfo.X1) AND
                  (xxx<ScreenInfo.X2) AND (yyy>ScreenInfo.Y1) AND
                  (yyy<ScreenInfo.Y1+24)) THEN
          BEGIN
               move_frame(ScreenInfo.X1,ScreenInfo.Y1,ScreenInfo.X2,ScreenInfo.Y2);
          END
          {================================================================}
          {  BUTTON QUERY                                                  }
          {================================================================}
          ELSE
          BEGIN
               IF ((LastPressed<>0) AND (Buttons^[LastPressed].Holdable)) THEN
               BEGIN
                    IF ((xxx<Buttons^[LastPressed].x1) OR (xxx>Buttons^[LastPressed].x2) OR
                       (yyy<Buttons^[LastPressed].y1) OR (yyy>Buttons^[LastPressed].y2)) THEN
                    BEGIN
                         ReleaseButton(LastPressed);
                         LastPressed := 0;
                    END
                    ELSE
                    BEGIN
                         {BUTTON IS STILL PRESSED}
                         IF PickInfo.Active THEN
                         BEGIN
                              IF ((xxx>PickInfo.x2+1) AND (xxx<PickInfo.x2+21) AND
                                 (yyy>PickInfo.y1) AND (yyy<PickInfo.y1+21)) THEN
                              BEGIN
                                   ScrollPickUp;
                              END
                              ELSE IF ((xxx>PickInfo.x2+1) AND (xxx<PickInfo.x2+21) AND
                                      (yyy>PickInfo.y2-20) AND (yyy<PickInfo.y2)) THEN
                              BEGIN
                                   ScrollPickDown;
                              END;
                         END;
                    END;
               END
               ELSE
               BEGIN
                    ProcessButton(xxx,yyy);
                    IF ((PickInfo.Active) AND (PickInfo.Pickable) AND NOT(MsgEditorKludge)) THEN
                    BEGIN
                         IF ((xxx>PickInfo.x1) AND (xxx<PickInfo.x2) AND
                            (yyy>PickInfo.y1+8) AND (yyy<PickInfo.y2-8)) THEN
                         BEGIN
                              TheOne := PickInfo.Top+Trunc((yyy-PickInfo.y1+8)/14)-1;
                              IF ((TheOne>=PickInfo.Top) AND (TheOne<=(PickInfo.Top+PickInfo.ItemsOnScrn-1))) THEN
                              BEGIN
                                   IF TheOne<>PickInfo.Current THEN
                                   BEGIN
                                        IF TheOne<=PickInfo.NumItems THEN
                                        BEGIN
                                             IF ItemPickable(TheOne) THEN
                                             BEGIN
                                                  GrDisplayMouse(GrHide);
                                                  ReSelectPickList(PickInfo.Current,TheOne);
                                                  GrDisplayMouse(GrShow);
                                                  PickInfo.Current := TheOne;
                                                  PutStringTimeout(BBSPort,#254#250,YappDelay);
                                                  PutBlockTimeOut(BBSPort,TheOne,2,Looper,YappDelay);
                                             END;
                                        END;
                                   END;
                              END;
                         END;
                    END
                    ELSE IF ((PickInfo.Active) AND (MsgEditorKludge)) THEN
                    BEGIN
                         IF ((XXX>=PickInfo.x1) AND (XXX<=PickInfo.x2) AND
                            (YYY>=PickInfo.y1) AND (YYY<=PickInfo.y2)) THEN
                         BEGIN
                              NewXY[1] := 251;
                              NewXY[2] := Trunc((XXX-PickInfo.x1-8)/7)+1;
                              NewXY[3] := Trunc((YYY-PickInfo.y1-10)/14)+1;
                              IF ((NewXY[2]<>MsgOldX) OR (NewXY[3]<>MsgOldY)) THEN
                              BEGIN
                                   MsgOldX := NewXY[2];
                                   MsgOldY := NewXY[3];
                                   PutBlockTimeOut(BBSPort,NewXY[1],3,Looper,YappDelay);
                              END;
                         END;
                    END;
               END;
          END;
     END
     ELSE IF GrGetMouseButtons=GrRButton THEN
     BEGIN
          IF PickInfo.Active THEN
          BEGIN
               IF ((xxx>PickInfo.x1) AND (xxx<PickInfo.x2) AND
                  (yyy>PickInfo.y1+8) AND (yyy<PickInfo.y2-8) AND (ScreenNumber<>0)) THEN
               BEGIN
                    CASE ScreenNumber OF
                    1:   BEGIN {FILE DRAG AND DROP}
                              TheOne := PickInfo.Top+Trunc((yyy-PickInfo.y1+8)/14)-1;
                              IF ((TheOne>=PickInfo.Top) AND (TheOne<=(PickInfo.Top+PickInfo.ItemsOnScrn-1))) THEN
                              BEGIN
                                   IF TheOne<=PickInfo.NumItems THEN
                                   BEGIN
                                        IF ItemPickable(TheOne) THEN
                                        BEGIN
                                             IF TheOne=PickInfo.Current THEN
                                             BEGIN
                                                  DoDragAndDrop('FILE');
                                             END;
                                        END;
                                   END;
                              END;
                         END;
                    2:   BEGIN {MSG DRAG AND DROP}
                              DoDragAndDrop('MSG');
                         END;
                    END;
               END
               ELSE IF (PickInfo.Current<>0) THEN
               BEGIN
                    TheOne := 0;
                    PutStringTimeout(BBSPort,#254#250,YappDelay);
                    PutBlockTimeOut(BBSPort,TheOne,2,Looper,YappDelay);
                    PickInfo.Current := 0;
                    GrDisplayMouse(GrHide);
                    SetUpPickList;
                    GrDisplayMouse(GrShow);
               END;
          END;
     END
     ELSE IF LastPressed<>0 THEN
     BEGIN
          IF ((xxx<Buttons^[LastPressed].x1) OR (xxx>Buttons^[LastPressed].x2) OR
             (yyy<Buttons^[LastPressed].y1) OR (yyy>Buttons^[LastPressed].y2)) THEN
          BEGIN
               ReleaseButton(LastPressed);
               LastPressed := 0;
          END
          ELSE
          BEGIN
               {BUTTON WAS ACTUALLY PRESSED!}
               ReleaseButton(LastPressed);
               IF ((PickInfo.Active) AND (Buttons^[LastPressed].Holdable)) THEN
               BEGIN
                    {do nothing}
               END
               ELSE w := Buttons^[LastPressed].Return;
               LastPressed := 0;
          END;
     END;
     ButtonHandler := w;
END;


END.
