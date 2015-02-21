{$I DEFINES.INC}
UNIT BHandler;


INTERFACE


FUNCTION  MouseHandler(DoKeys: Boolean): Word;
PROCEDURE SystemButton(x1,y1,x2,y2,Style: Word; Hold,Redraw: Boolean);


IMPLEMENTATION


USES Globals,Gx2_Bp,Gr2_Bp,_Icons,BsGraph,_Virtual,_Fields,Crt,BsString,BsKeys,PickLst;


{==========================================================================}
{                                                                          }
{         PLACES AN ICON ON THE SCREEN FOR THE TERMINAL'S BUTTONS          }
{                  PUTS THE BUTTON IN THE BUTTON STACK                     }
{                                                                          }
{==========================================================================}
PROCEDURE SystemButton(x1,y1,x2,y2,Style: Word; Hold,Redraw: Boolean);
BEGIN
     LastPressed := 0;
     INC(NButtons);
     Buttons[NButtons].Holdable := Hold;
     Buttons[NButtons].Enabled  := True;
     CASE Style OF
     1:   BEGIN
               IF Redraw THEN
               BEGIN
                    GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
                    GrDrawRect(x1,y1,x2,y2,GrFill);
                    GrSetColor(0);
                    GrDrawRect(x1,y1,x2,y2,GrOutline);
                    GrSetColor(WindowLow);
                    GrDrawLine(x1+1,y2-1,x2-1,y2-1);
                    GrDrawLine(x2-1,y1+1,x2-1,y2-1);
                    GrSetColor(WindowHigh);
                    GrDrawLine(x1+1,y1+1,x2-1,y1+1);
                    GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               END;
               Buttons[NButtons].x2      := x2;
               Buttons[NButtons].y2      := y2;
          END;
     4:   BEGIN
               IF Redraw THEN SystemIcon(x1,y1,21);
               Buttons[NButtons].x2      := x1+15;
               Buttons[NButtons].y2      := y1+15;
          END;
     END;
     Buttons[NButtons].x1      := x1;
     Buttons[NButtons].y1      := y1;
     Buttons[NButtons].HBorder := WindowHigh;
     Buttons[NButtons].DBorder := WindowLow;
     Buttons[NButtons].BType   := Style;
     Buttons[NButtons].FillC   := WindowBack;
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
     GrSetMouseBounds(old_m_x+5,old_m_y+5,GraphMaxX-x_add-5,GraphMaxY-y_add-5);
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
     GrSetMouseBounds(0,0,GraphMaxX,GraphMaxY-4);
     GrSetLineStyle(GrLSolid,1);
     {RECALCULATE BUTTONS, AND WINDOW}
     IF ((X_Move<>0) OR (Y_Move<>0)) THEN
     BEGIN
          GrDisplayMouse(GrHide);
          save_cutout(ScreenInfo.OrigX1+ScreenInfo.XOffSet,
                      ScreenInfo.OrigY1+ScreenInfo.YOffSet,
                      ScreenInfo.OrigX2+ScreenInfo.XOffSet,
                      ScreenInfo.OrigY2+ScreenInfo.YOffSet,
                      ScreenInfo.Index,1);
          load_cutout(0,0,ScreenInfo.Index,0);
          OldX1              := ScreenInfo.OrigX1+ScreenInfo.XOffSet;
          OldY1              := ScreenInfo.OrigY1+ScreenInfo.YOffSet;
          OldX2              := ScreenInfo.OrigX2+ScreenInfo.XOffSet;
          OldY2              := ScreenInfo.OrigY2+ScreenInfo.YOffSet;
          ScreenInfo.XOffSet := ScreenInfo.XOffSet+X_Move;
          ScreenInfo.YOffSet := ScreenInfo.YOffSet+Y_Move;
          save_cutout(ScreenInfo.OrigX1+ScreenInfo.XOffSet,
                      ScreenInfo.OrigY1+ScreenInfo.YOffSet,
                      ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,
                      ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,
                      ScreenInfo.Index,0);
          load_cutout(X_Move,Y_Move,ScreenInfo.Index,1);
          GrSetFillStyle(GrFCloseDot,0,GrTrans);
          GrDrawRect(ScreenInfo.OrigX1+ScreenInfo.XOffSet+5,
                     ScreenInfo.OrigY2+ScreenInfo.YOffSet+1,
                     ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,
                     ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,GrFill);
          GrDrawRect(ScreenInfo.OrigX2+ScreenInfo.XOffSet+1,
                     ScreenInfo.OrigY1+ScreenInfo.YOffSet+5,
                     ScreenInfo.OrigX2+ScreenInfo.XOffSet+5,
                     ScreenInfo.OrigY2+ScreenInfo.YOffSet+5,GrFill);
          GrDisplayMouse(GrShow);
          FOR Loop := 1 TO NButtons DO
          BEGIN
               IF ((Buttons[Loop].x1>=OldX1) AND (Buttons[Loop].x2<=OldX2) AND
                   (Buttons[Loop].y1>=OldY1) AND (Buttons[Loop].y2<=OldY2)) THEN
               BEGIN
                    Buttons[Loop].x1 := Buttons[Loop].x1+X_Move;
                    Buttons[Loop].y1 := Buttons[Loop].y1+Y_Move;
                    Buttons[Loop].x2 := Buttons[Loop].x2+X_Move;
                    Buttons[Loop].y2 := Buttons[Loop].y2+Y_Move;
               END;
          END;
          IF NFields<>0 THEN
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
          IF NumPalettes<>0 THEN
          BEGIN
               FOR Loop := 1 TO NumPalettes DO
               BEGIN
                    IF ((Palettes[Loop].x1>=OldX1) AND (Palettes[Loop].x2<=OldX2) AND
                       (Palettes[Loop].y1>=OldY1) AND (Palettes[Loop].y2<=OldY2)) THEN
                    BEGIN
                         Palettes[Loop].Selectedx1 := Palettes[Loop].Selectedx1+X_Move;
                         Palettes[Loop].Selectedy1 := Palettes[Loop].Selectedy1+Y_Move;
                         Palettes[Loop].Selectedx2 := Palettes[Loop].Selectedx2+X_Move;
                         Palettes[Loop].Selectedy2 := Palettes[Loop].Selectedy2+Y_Move;
                         Palettes[Loop].Dnx1       := Palettes[Loop].Dnx1+X_Move;
                         Palettes[Loop].Dny1       := Palettes[Loop].Dny1+Y_Move;
                         Palettes[Loop].Dnx2       := Palettes[Loop].Dnx2+X_Move;
                         Palettes[Loop].Dny2       := Palettes[Loop].Dny2+Y_Move;
                         Palettes[Loop].Upx1       := Palettes[Loop].Upx1+X_Move;
                         Palettes[Loop].Upy1       := Palettes[Loop].Upy1+Y_Move;
                         Palettes[Loop].Upx2       := Palettes[Loop].Upx2+X_Move;
                         Palettes[Loop].Upy2       := Palettes[Loop].Upy2+Y_Move;
                         Palettes[Loop].x1         := Palettes[Loop].x1+X_Move;
                         Palettes[Loop].y1         := Palettes[Loop].y1+Y_Move;
                         Palettes[Loop].x2         := Palettes[Loop].x2+X_Move;
                         Palettes[Loop].y2         := Palettes[Loop].y2+Y_Move;
                    END;
               END;
          END;
          IF PickInfo.Active THEN
          BEGIN
               PickInfo.x1 := PickInfo.x1+X_Move;
               PickInfo.y1 := PickInfo.y1+Y_Move;
               PickInfo.x2 := PickInfo.x2+X_Move;
               PickInfo.y2 := PickInfo.y2+Y_Move;
               PickInfo.Locator := PickInfo.Locator+Y_Move;
          END;
     END;
END;


PROCEDURE PressButton(Num: Word);
VAR  x1,y1,x2,y2 : Word;
BEGIN
     x1 := Buttons[Num].X1;
     x2 := Buttons[Num].X2;
     y1 := Buttons[Num].Y1;
     y2 := Buttons[Num].Y2;
     GrDisplayMouse(GrHide);
     CASE Buttons[Num].BType OF
     1:   BEGIN
               GrSetColor(Buttons[Num].FillC);
               GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
          END;
     2:   BEGIN
               GrSetColor(Buttons[Num].FillC);
               GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrOutline);
          END;
     3:   {INVISIBLE ICON};
     4:   SystemIcon(x1,y1,52);
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE ReleaseButton(Num: Word);
VAR  x1,y1,x2,y2 : Word;
BEGIN
     x1 := Buttons[Num].X1;
     x2 := Buttons[Num].X2;
     y1 := Buttons[Num].Y1;
     y2 := Buttons[Num].Y2;
     GrDisplayMouse(GrHide);
     CASE Buttons[Num].BType OF
     1:   BEGIN
               GrSetColor(Buttons[Num].DBorder);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Buttons[Num].HBorder);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
          END;
     2:   BEGIN
               GrSetColor(Buttons[Num].HBorder);
               GrDrawRect(x1+1,y1+1,x2,y2,GrOutline);
               GrSetColor(Buttons[Num].DBorder);
               GrDrawLine(x1,y1,x2,y1);
               GrDrawLine(x1,y1,x1,y2);
               GrDrawLine(x1+2,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+2,x2-1,y2-1);
          END;
     3:   {INVISIBLE ICON};
     4:   SystemIcon(x1,y1,51);
     END;
     GrDisplayMouse(GrShow);
END;


PROCEDURE ProcessButton(xx,yy: Word);
VAR  Loop  : Word;
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
                         GrDisplayMouse(GrHide);
                         ChangeField(Loop);
                         GrDisplayMouse(GrShow);
                         Exit;
                    END;
               END;
          END;
     END;
     IF ((LastPressed=0) AND (NButtons<>0)) THEN
     BEGIN
          FOR Loop := 1 TO NButtons DO
          BEGIN
               IF ((xx>=Buttons[Loop].x1) AND (xx<=Buttons[Loop].x2)) THEN
               BEGIN
                    IF ((yy>=Buttons[Loop].y1) AND (yy<=Buttons[Loop].y2)) THEN
                    BEGIN
                         IF Buttons[Loop].Enabled THEN
                         BEGIN
                              LastPressed := Loop;
                              PressButton(LastPressed);
                              Exit;
                         END;
                    END;
               END;
          END;
     END
     ELSE IF (LastPressed<>0) THEN
     BEGIN
          {CHECK TO SEE IF THE USER MOVED OFF OF THE BUTTON}
          IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
              (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2)) THEN
          BEGIN
               ReleaseButton(LastPressed);
               LastPressed := 0;
          END;
     END;
END;


PROCEDURE HandleKeys;
VAR  c      : Char;
     ThePos : Word;
LABEL         DnArrow,SkipOnIn;
BEGIN
     GrDisplayMouse(GrHide);
     C := ReadKey;
     IF NFields=0 THEN
     BEGIN
          IF ORD(c)=0 THEN c := ReadKey;
          GrDisplayMouse(GrShow);
          Exit;
     END;
     CASE ORD(c) OF
     13:  GOTO DnArrow;
     0:   BEGIN
               C := ReadKey;
               CASE ORD(c) OF
               15,72: BEGIN {SHIFT TAB & UpArrow}
                           IF FieldNum=1 THEN ChangeField(NFields)
                                         ELSE ChangeField(FieldNum-1);
                      END;
               80:    BEGIN {DownArrow}
                           DnArrow:
                           IF FieldNum=NFields THEN ChangeField(1)
                                               ELSE ChangeField(FieldNum+1);
                      END;
               71:    BEGIN {HOME}
                           IF (Fields[FieldNum].CursorPos<>1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := 1;
                                RedrawField;
                           END;
                      END;
               79:    BEGIN {END}
                           IF (Fields[FieldNum].CursorPos<>LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
                                RedrawField;
                           END;
                      END;
               75:    BEGIN {Left}
                           IF (Fields[FieldNum].CursorPos>1) THEN
                           BEGIN
                                DEC(Fields[FieldNum].CursorPos);
                                RedrawField;
                           END;
                      END;
               77:    BEGIN {Right}
                           IF (Fields[FieldNum].CursorPos<LENGTH(Fields[FieldNum].Text)+1) THEN
                           BEGIN
                                INC(Fields[FieldNum].CursorPos);
                                RedrawField;
                           END;
                      END;
               83:    BEGIN {DELETE}
                           ThePos := Fields[FieldNum].CursorPos;
                           IF (ThePos<=LENGTH(Fields[FieldNum].Text)) THEN
                           BEGIN
                                Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+
                                      _Mid(Fields[FieldNum].Text,ThePos+1,LENGTH(Fields[FieldNum].Text));
                                RedrawField;
                           END;
                      END;
               ELSE   BEGIN
                           C := IsTheKeyOk(C,True);
                           IF (C<>#0) THEN GOTO SkipOnIn;
                      END;
               END;
          END;
     8:   BEGIN {BACKSPACE}
               ThePos := Fields[FieldNum].CursorPos;
               IF ThePos>1 THEN
               BEGIN
                    Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-2)+
                          _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                    DEC(Fields[FieldNum].CursorPos);
                    RedrawField;
               END;
          END;
     9:   BEGIN {TAB}
               IF FieldNum=NFields THEN ChangeField(1)
                                   ELSE ChangeField(FieldNum+1);
          END;
     ELSE IF (IsTheKeyOk(C,False)<>#0) THEN
       BEGIN
         C := IsTheKeyOk(C,False);
         SkipOnIn:
         IF (LENGTH(Fields[FieldNum].Text)<Fields[FieldNum].MaxLength) THEN
         BEGIN
              CASE Fields[FieldNum].EntryType OF
              0:   BEGIN {0-Plain String}
                        ThePos := Fields[FieldNum].CursorPos;
                        Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                              _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                        INC(Fields[FieldNum].CursorPos);
                   END;
              1:   BEGIN {1-Plain Numeric}
                        IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                        BEGIN
                             ThePos := Fields[FieldNum].CursorPos;
                             Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                             INC(Fields[FieldNum].CursorPos);
                        END;
                   END;
              2:   BEGIN {2-Proper String}
                        ThePos := Fields[FieldNum].CursorPos;
                        IF ThePos=1 THEN C := UpCase(C)
                        ELSE
                        BEGIN
                             IF (ThePos<>2) THEN
                             BEGIN
                                  IF Fields[FieldNum].Text[ThePos-1]=' ' THEN C := UpCase(C);
                             END;
                        END;
                        Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                              _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                        INC(Fields[FieldNum].CursorPos);
                   END;
              3:   BEGIN {3-Date}
                   END;
              4:   BEGIN {4-Phone Number}
                        IF (((ORD(c)>47) AND (ORD(c)<58)) OR (c='-')) THEN
                        BEGIN
                             ThePos := Fields[FieldNum].CursorPos;
                             Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                             INC(Fields[FieldNum].CursorPos);
                        END;
                   END;
              5:   BEGIN {5-Filename}
                        C := UpCase(C);
                        IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR
                           (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_')) THEN
                        BEGIN
                             ThePos := Fields[FieldNum].CursorPos;
                             Fields[FieldNum].Text := _Mid(Fields[FieldNum].Text,1,ThePos-1)+C+
                                   _Mid(Fields[FieldNum].Text,ThePos,LENGTH(Fields[FieldNum].Text));
                             INC(Fields[FieldNum].CursorPos);
                        END;
                   END;
              END;
              RedrawField;
         END;
       END;
     END;
     GrDisplayMouse(GrShow);
END;


FUNCTION MouseHandler(DoKeys: Boolean): Word;
VAR  w      : Word;
     xx     : Word;
     yy     : Word;
     C      : Char;
     TheOne : Word;
BEGIN
     IF ((KeyPressed) AND (DoKeys)) THEN HandleKeys;
     w  := 0;
     IF GrGetMouseButtons=GrLButton THEN
     BEGIN
          xx := GetMouseX;
          yy := GetMouseY;

          IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
             (xx<PickInfo.x2+21) AND (yy>PickInfo.Locator) AND
             (yy<PickInfo.Locator+20)) THEN
          BEGIN
               IF MoveLocator THEN
               BEGIN
                    GrDisplayMouse(GrHide);
                    DrawPickListLocator;
                    SetUpPickList;
                    GrDisplayMouse(GrShow);
               END;
          END
          ELSE IF ((xx>ScreenInfo.OrigX1+ScreenInfo.XOffset) AND
                  (xx<ScreenInfo.OrigX2+ScreenInfo.XOffset) AND
                  (yy>ScreenInfo.OrigY1+ScreenInfo.YOffset) AND
                  (yy<ScreenInfo.OrigY1+ScreenInfo.YOffset+24)) THEN
          BEGIN
               move_frame(ScreenInfo.OrigX1+ScreenInfo.XOffset,
                          ScreenInfo.OrigY1+ScreenInfo.YOffset,
                          ScreenInfo.OrigX2+ScreenInfo.XOffset,
                          ScreenInfo.OrigY2+ScreenInfo.YOffset);
          END
          ELSE IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
                  (xx<PickInfo.x2+21) AND (yy>PickInfo.y1+21) AND
                  (yy<PickInfo.Locator)) THEN
          BEGIN
               ScrollPickPgUp;
               REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
          END
          ELSE IF ((PickInfo.Active) AND (xx>PickInfo.x2+1) AND
                  (xx<PickInfo.x2+21) AND (yy>PickInfo.Locator+20) AND
                  (yy<PickInfo.y2-21)) THEN
          BEGIN
               ScrollPickPgDown;
               REPEAT UNTIL (GrGetMouseButtons<>GrLButton);
          END
          ELSE
          BEGIN
               IF ((LastPressed<>0) AND (Buttons[LastPressed].Holdable)) THEN
               BEGIN
                    IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
                       (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2)) THEN
                    BEGIN
                         ReleaseButton(LastPressed);
                         LastPressed := 0;
                    END
                    ELSE
                    BEGIN
                         {BUTTON IS STILL PRESSED}
                         IF PickInfo.Active THEN
                         BEGIN
                              w := LastPressed;
                              IF ((xx>PickInfo.x2+1) AND (xx<PickInfo.x2+21) AND
                                 (yy>PickInfo.y1) AND (yy<PickInfo.y1+21)) THEN
                              BEGIN
                                   ScrollPickUp;
                              END
                              ELSE IF ((xx>PickInfo.x2+1) AND (xx<PickInfo.x2+21) AND
                                      (yy>PickInfo.y2-20) AND (yy<PickInfo.y2)) THEN
                              BEGIN
                                   ScrollPickDown;
                              END;
                         END;
                    END;
               END
               ELSE
               BEGIN
                    ProcessButton(xx,yy);
                    IF PickInfo.Active THEN
                    BEGIN
                         IF ((xx>PickInfo.x1) AND (xx<PickInfo.x2) AND
                            (yy>PickInfo.y1+8) AND (yy<PickInfo.y2-8)) THEN
                         BEGIN
                              TheOne := PickInfo.Top+Trunc((yy-PickInfo.y1+8)/15)-1;
                              IF TheOne<>PickInfo.Current THEN
                              BEGIN
                                   IF ((TheOne>=PickInfo.Top) AND (TheOne<=(PickInfo.Top+PickInfo.ItemsOnScrn-1))) THEN
                                   BEGIN
                                        IF TheOne<=PickInfo.NumItems THEN
                                        BEGIN
                                             PickInfo.Current := TheOne;
                                             GrDisplayMouse(GrHide);
                                             SetUpPickList;
                                             GrDisplayMouse(GrShow);
                                        END;
                                   END;
                              END;
                         END;
                    END;
               END;
          END;
     END
     ELSE
     BEGIN
          IF LastPressed<>0 THEN
          BEGIN
               xx := GetMouseX;
               yy := GetMouseY;
               ReleaseButton(LastPressed);
               IF ((xx<Buttons[LastPressed].x1) OR (xx>Buttons[LastPressed].x2) OR
                  (yy<Buttons[LastPressed].y1) OR (yy>Buttons[LastPressed].y2))
                  THEN w := 0
                  ELSE w := LastPressed;
               LastPressed := 0;
          END;
     END;
     MouseHandler := w;
END;


END.
