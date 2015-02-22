{$F+,O+,I-,Q-,A+,G+,R-,S-}
UNIT BsEditor;


INTERFACE


CONST EditorAttr         : Byte = (7*16)+0;
CONST edSave             : Byte = 1;
      edAbort            : Byte = 2;
      edForward          : Byte = 3;
      edBackward         : Byte = 4;
{Full-Screen Editor Object}
TYPE  Editor_Object      = RECORD
      BodyText           : Array[1..48000] Of Char;
      YStart             : Word;
      XStart             : Word;
      UserX              : Word;
      UserY              : Word;
      TopCharNum         : Word;
      Current            : Word;
      Total              : Word;
      OnScreen           : Array[1..25] Of String[88];
      Locators           : Array[1..3000] Of Word;
      TotalLines         : Word;
      IsOnScreen         : Boolean;
      TopLine            : Word;
      CharsOnScrn        : Word;
      LinesOnScrn        : Byte;
      LastPosX           : Word;
      LastPosY           : Word;
      AltKey             : Boolean;
      END;
VAR   EditorObject       : ^Editor_Object;
      EditorActive       : Boolean;


FUNCTION  FullEditor: Byte;
PROCEDURE InitEditor(X1,Y1,X2,Y2: Word);
PROCEDURE EditorRedraw(JustLocateCursor,ForceRedraw: Boolean);


IMPLEMENTATION


USES BsMulti,Crt,FastW1,BsString,BsKeys,BsVideo;


PROCEDURE EditorGetLocators;
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     NumChars   : Byte;
     Loop       : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Loop       := 0;
          AllDone    := False;
          TotalLines := 0;
          REPEAT
                INC(Loop);
                INC(TotalLines);
                IF TotalLines=3000 THEN Exit;
                Locators[TotalLines] := Loop;
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     AllDone := True;
                END
                ELSE IF (BodyText[Loop]<>#13) THEN
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     NumChars  := 0;
                     REPEAT
                           INC(NumChars);
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     Good := True;
                                     Loop := Loop2;
                                END;
                           255: BEGIN
                                     AllDone := True;
                                     Good    := True;
                                     Loop    := Loop2;
                                END;
                           ELSE BEGIN
                                     IF NumChars>CharsOnScrn THEN
                                     BEGIN
                                          Loop := LastSpace;
                                          Good := True;
                                     END
                                     ELSE IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                                END;
                           END;
                           INC(Loop2);
                     UNTIL Good;
                END;
          UNTIL AllDone;
          Locators[TotalLines+1] := Loop+1;
     END;
END;


PROCEDURE EditorGotoXY(X,Y: Word);
VAR  WorkX : Word;
     WorkY : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          LastPosX := X;
          LastPosY := Y;
          WorkX := XStart+(LastPosX-1);
          WorkY := YStart+(LastPosY-1);
          GotoXY(WorkX,WorkY);
     END;
END;


PROCEDURE EditorRedraw(JustLocateCursor,ForceRedraw: Boolean);
VAR  LineNum    : Word;
     AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     OldScreen  : Array[1..25] Of String[88];
     OldUserY   : Word;
     WorkY      : Word;
     Loop       : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          OldUserY := UserY;
          Move(OnScreen,OldScreen,SizeOf(OnScreen));
          FillChar(OnScreen,SizeOf(OnScreen),0);
          LineNum    := 1;
          Loop       := TopCharNum-1;
          AllDone    := False;
          IsOnScreen := False;
          REPEAT
                INC(Loop);
                IF BodyText[Loop]=#255 THEN
                BEGIN
                     IF Loop=Current THEN
                     BEGIN
                          UserX := 1;
                          UserY := LineNum;
                          IsOnScreen := True;
                     END;
                     AllDone := True;
                END
                ELSE IF BodyText[Loop]=#13 THEN
                BEGIN
                     IF Loop=Current THEN
                     BEGIN
                          UserX := 1;
                          UserY := LineNum;
                          IsOnScreen := True;
                     END;
                     INC(LineNum);
                     IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                END
                ELSE
                BEGIN
                     Loop2     := Loop;
                     Good      := False;
                     LastSpace := Loop;
                     Start     := Loop;
                     REPEAT
                           OnScreen[LineNum] := OnScreen[LineNum]+BodyText[Loop2];
                           IF LENGTH(OnScreen[LineNum])<=CharsOnScrn THEN
                           BEGIN
                                IF BodyText[Loop2]=#32 THEN LastSpace := Loop2;
                           END;
                           CASE Ord(BodyText[Loop2]) OF
                           13:  BEGIN
                                     IF Loop2=Current THEN
                                     BEGIN
                                          UserX := Length(OnScreen[LineNum]);
                                          UserY := LineNum;
                                          IsOnScreen := True;
                                     END;
                                     Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                     INC(LineNum);
                                     IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                                     Good := True;
                                     Loop := Loop2;
                                END;
                           255: BEGIN
                                     IF Loop2=Current THEN
                                     BEGIN
                                          UserX := Length(OnScreen[LineNum]);
                                          UserY := LineNum;
                                          IsOnScreen := True;
                                     END;
                                     Delete(OnScreen[LineNum],Length(OnScreen[LineNum]),1);
                                     AllDone := True;
                                     Good    := True;
                                     Loop    := Loop2;
                                END;
                           ELSE BEGIN
                                     IF LENGTH(OnScreen[LineNum])>CharsOnScrn THEN
                                     BEGIN
                                          OnScreen[LineNum] := '';
                                          FOR Loop2 := Start TO LastSpace DO
                                          BEGIN
                                               OnScreen[LineNum] := OnScreen[LineNum]+BodyText[Loop2];
                                               IF Loop2=Current THEN
                                               BEGIN
                                                    UserX := Length(OnScreen[LineNum]);
                                                    UserY := LineNum;
                                                    IsOnScreen := True;
                                               END;
                                          END;
                                          Loop := LastSpace;
                                          Good := True;
                                          INC(LineNum);
                                          IF LineNum=(LinesOnScrn+1) THEN AllDone := True;
                                     END
                                     ELSE
                                     BEGIN
                                          IF Loop2=Current THEN
                                          BEGIN
                                               UserX := Length(OnScreen[LineNum]);
                                               UserY := LineNum;
                                               IsOnScreen := True;
                                          END;
                                     END;
                                END;
                           END;
                           INC(Loop2);
                     UNTIL Good;
                END;
          UNTIL AllDone;
          IF NOT(JustLocateCursor) THEN
          BEGIN
               FOR Loop := 1 TO LinesOnScrn DO
               BEGIN
                    IF ((OldScreen[Loop]<>OnScreen[Loop]) OR (Loop=OldUserY) OR (ForceRedraw)) THEN
                    BEGIN
                         WorkY := YStart+(Loop-1);
                         FastWrite(_PadRight(OnScreen[Loop],CharsOnScrn),WorkY,XStart,EditorAttr);
                    END;
               END;
          END;
          EditorGotoXY(UserX,UserY);
     END;
END;


FUNCTION EditorGetKeyPress: char;
VAR  cc   : Char;
     done : Boolean;
BEGIN
     EditorObject^.AltKey := False;
     Done   := False;
     REPEAT
           IF keypressed THEN
           BEGIN
                cc := ReadKey;
                IF ORD(cc)=0 THEN
                BEGIN
                     cc := ReadKey;
                     EditorObject^.AltKey := True;
                END;
                Done := True;
           END
           ELSE TimeSlice;
     UNTIL Done;
     EditorGetKeyPress := cc;
END;


PROCEDURE EditorInsert(Ch: Char);
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Total>=48000 THEN Exit;
          Move(BodyText[Current],BodyText[Current+1],(Total+1)-Current+1);
          BodyText[Current] := Ch;
          INC(Current);
          INC(Total);
          OnScreen[UserY] := _Mid(OnScreen[UserY],1,UserX-1)+Ch+
                             _Mid(OnScreen[UserY],UserX,LENGTH(OnScreen[UserY]));
          BodyText[48000] := #255;
     END;
END;


PROCEDURE EditorDelete;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF BodyText[Current]=#255 THEN Exit;
          Move(BodyText[Current+1],BodyText[Current],Total-Current+1);
          DEC(Total);
          BodyText[48000] := #255;
          EditorRedraw(False,False);
     END;
END;


PROCEDURE EditorBackspace;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current=1 THEN Exit;
          Move(BodyText[Current],BodyText[Current-1],(Total+1)-Current+1);
          DEC(Total);
          DEC(Current);
          BodyText[48000] := #255;
          EditorRedraw(False,False);
          IF NOT(IsOnScreen) THEN
          BEGIN
               EditorGetLocators;
               DEC(TopLine);
               TopCharNum := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorStartOfLine;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF UserX<>1 THEN
          BEGIN
               Current := Current-UserX+1;
               UserX   := 1;
               EditorGotoXY(UserX,UserY);
          END;
     END;
END;


PROCEDURE EditorEndOfLine;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF (UserX<>LENGTH(OnScreen[UserY])+1) THEN
          BEGIN
               EditorGetLocators;
               Current := Locators[TopLine+UserY]-1;
               EditorRedraw(True,False);
          END;
     END;
END;


PROCEDURE EditorDeleteLine;
VAR  NumBytes : Word;
     LStart   : Word;
     LEnd     : Word;
     Looper   : Word;
     Moving   : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          LStart   := Locators[TopLine+UserY-1];
          LEnd     := Locators[TopLine+UserY]-1;
          NumBytes := LEnd-LStart+1;
          Moving   := Total-LStart+1;
          FOR Looper := 1 TO NumBytes DO
          BEGIN
               IF BodyText[LStart]<>#255 THEN
               BEGIN
                    Move(BodyText[LStart+1],BodyText[LStart],Moving);
                    DEC(Total);
               END;
          END;
          BodyText[Total+1] := #255;
          EditorGetLocators;
          IF (Current>=Locators[TopLine+UserY]) THEN Current := Locators[TopLine+UserY]-1;
          EditorRedraw(False,False);
     END;
END;


PROCEDURE EditorLeftArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current>1 THEN
          BEGIN
               Dec(Current);
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    EditorGetLocators;
                    DEC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorRightArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          IF Current<=Total THEN
          BEGIN
               Inc(Current);
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    EditorGetLocators;
                    INC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorUpArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine+UserY-1>1 THEN
          BEGIN
               Current := Locators[TopLine+UserY-2]+UserX-1;
               IF Current>=Locators[TopLine+UserY-1] THEN Current := Locators[TopLine+UserY-1]-1;
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    DEC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorDownArrow;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine+UserY-1<TotalLines THEN
          BEGIN
               Current := Locators[TopLine+UserY]+UserX-1;
               IF Current>=Locators[TopLine+UserY+1] THEN Current := Locators[TopLine+UserY+1]-1;
               EditorRedraw(True,False);
               IF NOT(IsOnScreen) THEN
               BEGIN
                    INC(TopLine);
                    TopCharNum := Locators[TopLine];
                    EditorRedraw(False,True);
               END;
          END;
     END;
END;


PROCEDURE EditorPageUp;
VAR  Temporary : Integer;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine>1 THEN
          BEGIN
               Temporary := TopLine;
               Temporary := Temporary-LinesOnScrn;
               IF Temporary<1 THEN Temporary := 1;
               TopLine := Temporary;
               TopCharNum := Locators[TopLine];
               Current    := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorPageDown;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          IF TopLine<TotalLines THEN
          BEGIN
               INC(TopLine,LinesOnScrn);
               IF TopLine>TotalLines THEN TopLine := TotalLines;
               TopCharNum := Locators[TopLine];
               Current    := Locators[TopLine];
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorTop;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          UserX       := 1;
          UserY       := 1;
          TopCharNum  := 1;
          Current     := 1;
          TopLine     := 1;
          EditorRedraw(False,True);
     END;
END;


PROCEDURE EditorEnd;
VAR  Good   : Boolean;
     TheTop : Word;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          EditorGetLocators;
          Good   := False;
          TheTop := TotalLines;
          IF TheTop<>TopLine THEN
          BEGIN
               TopCharNum  := Locators[TheTop];
               Current     := Locators[TheTop];
               TopLine     := TheTop;
               EditorRedraw(False,True);
          END;
     END;
END;


PROCEDURE EditorClearWindow;
VAR  Loop : Word;
     Temp : String;
BEGIN
     WITH EditorObject^ DO
     BEGIN
          Temp := _PadRight('',CharsOnScrn);
          FOR Loop := YStart TO (YStart+LinesOnScrn-1) DO
              FastWrite(Temp,Loop,XStart,EditorAttr);
     END;
END;


PROCEDURE InitEditor(X1,Y1,X2,Y2: Word);
BEGIN
     FillChar(EditorObject^,SizeOf(EditorObject^),0);
     WITH EditorObject^ DO
     BEGIN
          XStart      := X1;
          YStart      := Y1;
          CharsOnScrn := X2-X1+1;
          LinesOnScrn := Y2-Y1+1;
          EditorClearWindow;
          BodyText[1] := #255;
          UserX       := 1;
          UserY       := 1;
          TopCharNum  := 1;
          Current     := 1;
          TopLine     := 1;
          TotalLines  := 1;
          LastPosX    := 1;
          LastPosY    := 1;
     END;
END;


FUNCTION FullEditor: Byte;
VAR  OuttaHere : Boolean;
     C         : Char;
LABEL            OverHere;
BEGIN
     _ShowCursor;
     WITH EditorObject^ DO
     BEGIN
          OuttaHere := False;
          EditorRedraw(False,True);
          EditorGotoXY(UserX,UserY);
          REPEAT
                c := EditorGetKeyPress;
                IF AltKey THEN
                BEGIN
                     CASE ORD(c) OF
                     73 : EditorPageUp;
                     81 : EditorPageDown;
                     72 : EditorUpArrow;
                     80 : EditorDownArrow;
                     75 : EditorLeftArrow;
                     77 : EditorRightArrow;
                     71 : EditorStartOfLine;
                     79 : EditorEndOfLine;
                     83 : EditorDelete;
                     132: EditorTop;
                     118: EditorEnd;
                     15 : BEGIN {Backward}
                               FullEditor := edBackward;
                               _HideCursor;
                               Exit;
                          END;
                     ELSE BEGIN
                               C := Chr(Ord(C)+128);
                               GOTO OverHere;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     OverHere:
                     CASE ORD(c) OF
                     25  : EditorDeleteLine;
                     9,
                     27  : BEGIN {Forward}
                                FullEditor := edForward;
                                _HideCursor;
                                Exit;
                           END;
                     8   : EditorBackspace;
                     13  : BEGIN
                                EditorInsert(C);
                                EditorRedraw(False,False);
                                IF NOT(IsOnScreen) THEN
                                BEGIN
                                     EditorGetLocators;
                                     INC(TopLine);
                                     TopCharNum := Locators[TopLine];
                                     EditorRedraw(False,True);
                                END;
                           END;
                     ELSE  BEGIN
                                EditorInsert(C);
                                IF ((LENGTH(OnScreen[UserY])>CharsOnScrn) OR (UserX=80)) THEN
                                BEGIN
                                     EditorRedraw(False,False);
                                     IF NOT(IsOnScreen) THEN
                                     BEGIN
                                          EditorGetLocators;
                                          INC(TopLine);
                                          TopCharNum := Locators[TopLine];
                                          EditorRedraw(False,True);
                                     END;
                                END
                                ELSE
                                BEGIN
                                     IF (UserX=LENGTH(OnScreen[UserY])+1) THEN
                                     BEGIN
                                          FastWrite(C,UserY+(YStart-1),UserX+(XStart-1),EditorAttr);
                                          INC(UserX);
                                     END
                                     ELSE
                                     BEGIN
                                          FastWrite(_Mid(OnScreen[UserY],UserX,Length(OnScreen[UserY])),
                                                    UserY+(YStart-1),UserX+(XStart-1),EditorAttr);
                                          INC(UserX);
                                     END;
                                     EditorGotoXY(UserX,UserY);
                                END;
                           END;
                     END;
                END;
          UNTIL OuttaHere;
     END;
     _HideCursor;
END;


END.
