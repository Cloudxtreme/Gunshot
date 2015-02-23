{$I DEFINES.INC}
UNIT BsEdit;


INTERFACE


PROCEDURE winNewEditor(x,y,MaxLen,OnScreen: Word; HelpIndex: Word);
PROCEDURE winEditorRedraw(Index: Word; JustLocateCursor,ForceRedraw,Enabled: Boolean);
PROCEDURE winAppendEditor(Index: Word; InString: String);
PROCEDURE winEditorPageUp(Index: Word);
PROCEDURE winEditorPageDown(Index: Word);
PROCEDURE winEditorLeftArrow(Index: Word);
PROCEDURE winEditorRightArrow(Index: Word);
PROCEDURE winEditorUpArrow(Index: Word);
PROCEDURE winEditorDownArrow(Index: Word);
PROCEDURE winEditorEndOfLine(Index: Word);
PROCEDURE winEditorStartOfLine(Index: Word);
PROCEDURE winEditorEnd(Index: Word);
PROCEDURE winEditorTop(Index: Word);
PROCEDURE winEditorDelete(Index: Word);
PROCEDURE winEditorDeleteLine(Index: Word);
PROCEDURE winEditorBackspace(Index: Word);
PROCEDURE winEditorInsert(Index: Word; Ch: Char);
PROCEDURE winEditorGetLocators(Index: Word);
PROCEDURE winEditorGotoXY(Index,X,Y: Word);
FUNCTION  winDoEditor(x,y: Word): Boolean;


IMPLEMENTATION


USES BsGlobal,FastW1,BsString,BsMouse,BsKeys,BsVideo,BsWindow;


PROCEDURE winNewEditor(x,y,MaxLen,OnScreen: Word; HelpIndex: Word);
VAR  Work : Word;
BEGIN
     INC(dtNumEvents);
     INC(dtEditor^.NumEditors);
     Work := dtEditor^.NumEditors;
     dtEventQueue[dtNumEvents].EventType  := 7;
     dtEventQueue[dtNumEvents].IndexNum   := dtEditor^.NumEditors;
     dtEventQueue[dtNumEvents].HelpIndex  := HelpIndex;
     FillChar(dtEditor^.Editor[Work],SizeOf(dtEditor^.Editor[Work]),0);
     New(dtEditor^.Editor[Work].BodyText);
     FillChar(dtEditor^.Editor[Work].BodyText^,SizeOf(dtEditor^.Editor[Work].BodyText^),0);
     dtEditor^.Editor[Work].XPos          := x+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     dtEditor^.Editor[Work].YPos          := y+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     dtEditor^.Editor[Work].CharsOnScrn   := MaxLen;
     dtEditor^.Editor[Work].LinesOnScrn   := OnScreen;
     dtEditor^.Editor[Work].BodyText^[1]  := #255;
     dtEditor^.Editor[Work].UserX         := 1;
     dtEditor^.Editor[Work].UserY         := 1;
     dtEditor^.Editor[Work].TopCharNum    := 1;
     dtEditor^.Editor[Work].Current       := 1;
     dtEditor^.Editor[Work].TopLine       := 1;
     dtEditor^.Editor[Work].TotalLines    := 1;
     dtEditor^.Editor[Work].Total         := 0;
     dtEditor^.Editor[Work].LastPosX      := 1;
     dtEditor^.Editor[Work].LastPosY      := 1;
END;


PROCEDURE winEditorGetLocators(Index: Word);
VAR  AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     NumChars   : Byte;
     Loop       : Word;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       Loop       := 0;
       AllDone    := False;
       TotalLines := 0;
       REPEAT
         INC(Loop);
         INC(TotalLines);
         IF TotalLines=3000 THEN Exit;
         Locators[TotalLines] := Loop;
         IF BodyText^[Loop]=#255 THEN
         BEGIN
           AllDone := True;
         END
         ELSE IF (BodyText^[Loop]<>#13) THEN
         BEGIN
           Loop2     := Loop;
           Good      := False;
           LastSpace := Loop;
           Start     := Loop;
           NumChars  := 0;
           REPEAT
             INC(NumChars);
             CASE Ord(BodyText^[Loop2]) OF
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
                    ELSE IF BodyText^[Loop2]=#32 THEN LastSpace := Loop2;
                  END;
             END;
             INC(Loop2);
           UNTIL Good;
         END;
       UNTIL AllDone;
       Locators[TotalLines+1] := Loop+1;
     END;
END;


PROCEDURE winEditorGotoXY(Index,X,Y: Word);
VAR  WorkX : Word;
     WorkY : Word;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       LastPosX := X;
       LastPosY := Y;
       WorkX := XPos+(LastPosX-1);
       WorkY := YPos+(LastPosY-1);
       FastW1.GotoXY(WorkX,WorkY);
     END;
END;


PROCEDURE winEditorRedraw(Index: Word; JustLocateCursor,ForceRedraw,Enabled: Boolean);
VAR  LineNum    : Word;
     AllDone    : Boolean;
     Loop2      : Word;
     Good       : Boolean;
     LastSpace  : Word;
     Start      : Word;
     OldScreen  : Array[1..50] Of String[88];
     OldUserY   : Word;
     WorkY      : Word;
     Loop       : Word;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       _HideMouse;
       OldUserY := UserY;
       Move(OnScreen,OldScreen,SizeOf(OnScreen));
       FillChar(OnScreen,SizeOf(OnScreen),0);
       LineNum    := 1;
       Loop       := TopCharNum-1;
       AllDone    := False;
       IsOnScreen := False;
       REPEAT
         INC(Loop);
         IF BodyText^[Loop]=#255 THEN
         BEGIN
           IF Loop=Current THEN
           BEGIN
             UserX := 1;
             UserY := LineNum;
             IsOnScreen := True;
           END;
           AllDone := True;
         END
         ELSE IF BodyText^[Loop]=#13 THEN
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
             OnScreen[LineNum] := OnScreen[LineNum]+BodyText^[Loop2];
             IF LENGTH(OnScreen[LineNum])<=CharsOnScrn THEN
             BEGIN
               IF BodyText^[Loop2]=#32 THEN LastSpace := Loop2;
             END;
             CASE Ord(BodyText^[Loop2]) OF
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
                        OnScreen[LineNum] := OnScreen[LineNum]+BodyText^[Loop2];
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
             WorkY := YPos+(Loop-1);
             IF Enabled
                THEN FastWrite(_PadRight(OnScreen[Loop],CharsOnScrn),WorkY,XPos,dtColours^.EditText)
                ELSE FastWrite(_PadRight(OnScreen[Loop],CharsOnScrn),WorkY,XPos,dtColours^.EditTextDisabled);
           END;
         END;
       END;
       IF Enabled THEN
       BEGIN
         winEditorGotoXY(Index,UserX,UserY);
         _ShowCursor;
       END
       ELSE _HideCursor;
       _ShowMouse;
     END;
END;


PROCEDURE winEditorInsert(Index: Word; Ch: Char);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF Total>=48000 THEN Exit;
       Move(BodyText^[Current],BodyText^[Current+1],(Total+1)-Current+1);
       BodyText^[Current] := Ch;
       INC(Current);
       INC(Total);
       Insert(Ch,OnScreen[UserY],UserX);
       BodyText^[48000] := #255;
     END;
END;


PROCEDURE winEditorDelete(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF BodyText^[Current]=#255 THEN Exit;
       Move(BodyText^[Current+1],BodyText^[Current],Total-Current+1);
       DEC(Total);
       BodyText^[48000] := #255;
       winEditorRedraw(Index,False,False,True);
     END;
END;


PROCEDURE winEditorBackspace(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF Current=1 THEN Exit;
       Move(BodyText^[Current],BodyText^[Current-1],(Total+1)-Current+1);
       DEC(Total);
       DEC(Current);
       BodyText^[48000] := #255;
       winEditorRedraw(Index,False,False,True);
       IF NOT(IsOnScreen) THEN
       BEGIN
         winEditorGetLocators(Index);
         DEC(TopLine);
         TopCharNum := Locators[TopLine];
         winEditorRedraw(Index,False,True,True);
       END;
     END;
END;


PROCEDURE winEditorStartOfLine(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF UserX<>1 THEN
       BEGIN
         Current := Current-UserX+1;
         UserX   := 1;
         winEditorGotoXY(Index,UserX,UserY);
       END;
     END;
END;


PROCEDURE winEditorEndOfLine(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF (UserX<>LENGTH(OnScreen[UserY])+1) THEN
       BEGIN
         winEditorGetLocators(Index);
         Current := Locators[TopLine+UserY]-1;
         winEditorRedraw(Index,True,False,True);
       END;
     END;
END;


PROCEDURE winEditorDeleteLine(Index: Word);
VAR  NumBytes : Word;
     LStart   : Word;
     LEnd     : Word;
     Looper   : Word;
     Moving   : Word;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       LStart   := Locators[TopLine+UserY-1];
       LEnd     := Locators[TopLine+UserY]-1;
       NumBytes := LEnd-LStart+1;
       Moving   := Total-LStart+1;
       FOR Looper := 1 TO NumBytes DO
       BEGIN
         IF BodyText^[LStart]<>#255 THEN
         BEGIN
           Move(BodyText^[LStart+1],BodyText^[LStart],Moving);
           DEC(Total);
         END;
       END;
       BodyText^[Total+1] := #255;
       winEditorGetLocators(Index);
       IF (Current>=Locators[TopLine+UserY]) THEN Current := Locators[TopLine+UserY]-1;
       winEditorRedraw(Index,False,False,True);
     END;
END;


PROCEDURE winEditorLeftArrow(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF Current>1 THEN
       BEGIN
         Dec(Current);
         winEditorRedraw(Index,True,False,True);
         IF NOT(IsOnScreen) THEN
         BEGIN
           winEditorGetLocators(Index);
           DEC(TopLine);
           TopCharNum := Locators[TopLine];
           winEditorRedraw(Index,False,True,True);
         END;
       END;
     END;
END;


PROCEDURE winEditorRightArrow(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF Current<=Total THEN
       BEGIN
         Inc(Current);
         winEditorRedraw(Index,True,False,True);
         IF NOT(IsOnScreen) THEN
         BEGIN
           winEditorGetLocators(Index);
           INC(TopLine);
           TopCharNum := Locators[TopLine];
           winEditorRedraw(Index,False,True,True);
         END;
       END;
     END;
END;


PROCEDURE winEditorTop(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       UserX       := 1;
       UserY       := 1;
       TopCharNum  := 1;
       Current     := 1;
       TopLine     := 1;
       winEditorRedraw(Index,False,True,True);
     END;
END;


PROCEDURE winEditorUpArrow(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       IF TopLine+UserY-1>1 THEN
       BEGIN
         Current := Locators[TopLine+UserY-2]+UserX-1;
         IF Current>=Locators[TopLine+UserY-1] THEN Current := Locators[TopLine+UserY-1]-1;
         winEditorRedraw(Index,True,False,True);
         IF NOT(IsOnScreen) THEN
         BEGIN
           DEC(TopLine);
           TopCharNum := Locators[TopLine];
           winEditorRedraw(Index,False,True,True);
         END;
       END;
     END;
END;


PROCEDURE winEditorDownArrow(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       IF TopLine+UserY-1<TotalLines THEN
       BEGIN
         Current := Locators[TopLine+UserY]+UserX-1;
         IF Current>=Locators[TopLine+UserY+1] THEN Current := Locators[TopLine+UserY+1]-1;
         winEditorRedraw(Index,True,False,True);
         IF NOT(IsOnScreen) THEN
         BEGIN
           INC(TopLine);
           TopCharNum := Locators[TopLine];
           winEditorRedraw(Index,False,True,True);
         END;
       END;
     END;
END;


PROCEDURE winEditorPageUp(Index: Word);
VAR  Temporary : Integer;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       IF TopLine>1 THEN
       BEGIN
         Temporary := TopLine;
         Temporary := Temporary-LinesOnScrn;
         IF Temporary<1 THEN Temporary := 1;
         TopLine := Temporary;
         TopCharNum := Locators[TopLine];
         Current    := Locators[TopLine];
         winEditorRedraw(Index,False,True,True);
       END;
     END;
END;


PROCEDURE winEditorPageDown(Index: Word);
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       IF TopLine<TotalLines THEN
       BEGIN
         INC(TopLine,LinesOnScrn);
         IF TopLine>TotalLines THEN TopLine := TotalLines;
         TopCharNum := Locators[TopLine];
         Current    := Locators[TopLine];
         winEditorRedraw(Index,False,True,True);
       END;
     END;
END;


PROCEDURE winEditorEnd(Index: Word);
VAR  Good   : Boolean;
     TheTop : Word;
BEGIN
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       winEditorGetLocators(Index);
       Good   := False;
       TheTop := TotalLines;
       IF TheTop<>TopLine THEN
       BEGIN
         TopCharNum  := Locators[TheTop];
         Current     := Locators[TheTop];
         TopLine     := TheTop;
         winEditorRedraw(Index,False,True,True);
       END;
     END;
END;


PROCEDURE winEditorClearWindow(Index: Word; Enabled: Boolean);
VAR  Loop       : Word;
     Temp       : String;
     EditorAttr : Word;
BEGIN
     IF Enabled THEN EditorAttr := dtColours^.EditText
                ELSE EditorAttr := dtColours^.EditTextDisabled;
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       Temp := _PadRight('',CharsOnScrn);
       FOR Loop := YPos TO (YPos+LinesOnScrn-1) DO FastWrite(Temp,Loop,XPos,EditorAttr);
     END;
END;


PROCEDURE winAppendEditor(Index: Word; InString: String);
VAR  Loop : Word;
     LLen : Word;
BEGIN
     LLen := LENGTH(InString);
     WITH dtEditor^.Editor[Index] DO
     BEGIN
       IF (Total+LLen+1>48000) THEN Exit;
       Move(InString[1],BodyText^[Total+1],LLen);
       INC(Total,LLen);
       BodyText^[Total+1] := #255;
     END;
END;


FUNCTION winDoEditor(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx1  : Word;
     yy1  : Word;
     xx2  : Word;
     yy2  : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=7 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         WITH dtEditor^.Editor[Evt] DO
         BEGIN
           xx1  := XPos;
           yy1  := YPos;
           xx2  := XPos+CharsOnScrn-1;
           yy2  := YPos+LinesOnScrn-1;
           IF ((x>=xx1) AND (x<=xx2) AND (y>=yy1) AND (y<=yy2)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winDoEditor := True;
             Exit;
           END;
         END;
       END;
     END;
     winDoEditor := False;
END;


END.