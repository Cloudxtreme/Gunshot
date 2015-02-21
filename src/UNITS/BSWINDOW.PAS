{$I DEFINES.INC}
UNIT BsWindow;


INTERFACE


PROCEDURE winClearCurrentEvent;
PROCEDURE winDrawCurrentEvent;
FUNCTION  winEventHandler: Word;
PROCEDURE winNewWindow(x1,y1,width,height: Word; Title: String);
PROCEDURE winKillWindow;
PROCEDURE winStart;


IMPLEMENTATION


USES BsBack,BsButton,BsDrop,BsFile,BsFore,BsFrames,BsGlobal,BsEdit,
     BsOnOff,BsMisc,BsMouse,BsMulti,BsString,BsVideo,Crt,BsPick;


PROCEDURE winClearCurrentEvent;
VAR  Index : Word;
BEGIN
     Index := dtEventQueue[dtCurrentEvent].IndexNum;
     CASE dtEventQueue[dtCurrentEvent].EventType OF
     1:   winDrawButton(Index,False,False);        {Button}
     2:   winDrawOnOff(Index,False);               {On/Off Toggle}
     3:   winDrawDropList(Index,False);            {Drop Lists}
     4:   winDrawBackPal(Index,False);             {Background Palettes}
     5:   winDrawForePal(Index,False);             {Foreground Palettes}
     6:   winDrawPickList(Index,False,True);       {Pick Lists}
     7:   winEditorRedraw(Index,False,True,False); {Editors}
     END;
END;


PROCEDURE winDrawCurrentEvent;
VAR  Index : Word;
BEGIN
     Index := dtEventQueue[dtCurrentEvent].IndexNum;
     CASE dtEventQueue[dtCurrentEvent].EventType OF
     1:   winDrawButton(Index,True,False);        {Button}
     2:   winDrawOnOff(Index,True);               {On/Off Toggle}
     3:   winDrawDropList(Index,True);            {Drop Lists}
     4:   winDrawBackPal(Index,True);             {Background Palettes}
     5:   winDrawForePal(Index,True);             {Foreground Palettes}
     6:   winDrawPickList(Index,True,True);       {Pick Lists}
     7:   winEditorRedraw(Index,False,True,True); {Editors}
     END;
END;


PROCEDURE winNewWindow(x1,y1,width,height: Word; Title: String);
VAR  Temp  : String;
     Loop  : Word;
     Tmp   : Array[1..8000] Of Byte;
     FFile : File;
     x2,y2 : Word;
BEGIN
     {Save The Last Window! FUCK}
     FillChar(dtBackGround^,SizeOf(dtBackGround^),0);
     FillChar(dtButtons^,SizeOf(dtButtons^),0);
     FillChar(dtDropList^,SizeOf(dtDropList^),0);
     FillChar(dtEditor^,SizeOf(dtEditor^),0);
     FillChar(dtPickList^,SizeOf(dtPickList^),0);
     FillChar(dtForeGround^,SizeOf(dtForeGround^),0);
     FillChar(dtOnOff^,SizeOf(dtOnOff^),0);
     FillChar(dtEventQueue,SizeOf(dtEventQueue),0);
     dtCurrentEvent := 1;
     dtNumEvents    := 0;
     IF x1=0 THEN x1 := Trunc((80-Width+1)/2)+1;
     IF y1=0 THEN y1 := Trunc((dtApp^.VideoMode-Height+1)/2)+1;
     x2 := x1+Width-1;
     y2 := y1+Height-1;
     INC(dtWindows^.NumWindows);
     dtWindows^.Window[dtWindows^.NumWindows].XPos := x1;
     dtWindows^.Window[dtWindows^.NumWindows].YPos := y1;
     _HideMouse;
     Move(MEM[SegB800:0],Tmp,dtApp^.VideoMode*160);
     ASSIGN(FFile,dtApp^.WorkDir+'\TMP'+_String(dtWindows^.NumWindows)+'.$$$');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,Tmp,SizeOf(Tmp));
     CLOSE(FFile);
     winDropShadow(x1,y1,x2,y2);
     CASE dtApp^.AppStyle OF
     1:   BEGIN {Front Door}
            FOR Loop := y1 TO y2 DO
            BEGIN
                   IF Loop=y1 THEN Temp := 'É'+_Replicate('Í',x2-x1-1)+'»'
              ELSE IF Loop=y2 THEN Temp := 'È'+_Replicate('Í',x2-x1-1)+'¼'
              ELSE Temp := 'º'+_Replicate(' ',x2-x1-1)+'º';
              FastWrite(Temp,Loop,x1,dtColours^.WindowBorderH);
            END;
            Title := ' '+Title+' ';
            FastWrite(Title,y1,x2-LENGTH(Title),dtColours^.WindowTitle);
          END;
     2,5: BEGIN {Turbo Vision}
            FOR Loop := y1 TO y2 DO
            BEGIN
                   IF Loop=y1 THEN Temp := 'É'+_Replicate('Í',x2-x1-1)+'»'
              ELSE IF Loop=y2 THEN Temp := 'È'+_Replicate('Í',x2-x1-1)+'¼'
              ELSE Temp := 'º'+_Replicate(' ',x2-x1-1)+'º';
              FastWrite(Temp,Loop,x1,dtColours^.WindowBorderH);
            END;
            Title := ' '+Title+' ';
            Loop  := Trunc((x2-x1+1-LENGTH(Title))/2);
            FastWrite(Title,y1,x1+Loop,dtColours^.WindowTitle);
          END;
     3:   BEGIN {Norton Utilities}
            FOR Loop := y1 TO y2 DO
            BEGIN
              IF Loop=y1 THEN
              BEGIN
                FastWrite(_Replicate(' ',x2-x1+1),Loop,x1,dtColours^.WindowTitle);
                FastWrite(Title,y1,x1+Trunc((x2-x1+1-LENGTH(Title))/2),dtColours^.WindowTitle);
              END
              ELSE
              BEGIN
                Temp := _Replicate(' ',x2-x1+1);
                FastWrite(Temp,Loop,x1,dtColours^.WindowBorderH);
              END;
            END;
          END;
     4:   BEGIN {Shotgun Professional}
            FOR Loop := y1 TO y2 DO
            BEGIN
              IF Loop=y1 THEN
              BEGIN
                Temp := _PadRight('  '+Title,x2-x1-1);
                FastWrite('Ú',Loop,x1,dtColours^.WindowBorderH);
                FastWrite(Temp,Loop,x1+1,dtColours^.WindowTitle);
                FastWrite('¿',Loop,x2,dtColours^.WindowBorderL);
              END
              ELSE IF Loop=y2 THEN
              BEGIN
                FastWrite('À',Loop,x1,dtColours^.WindowBorderH);
                Temp := _Replicate('Ä',x2-x1-1)+'Ù';
                FastWrite(Temp,Loop,x1+1,dtColours^.WindowBorderL);
              END
              ELSE
              BEGIN
                FastWrite('³',Loop,x1,dtColours^.WindowBorderH);
                Temp := _Replicate(' ',x2-x1-1)+'³';
                FastWrite(Temp,Loop,x1+1,dtColours^.WindowBorderL);
              END;
            END;
          END;
     END;
     _ShowMouse;
END;


PROCEDURE winKillWindow;
VAR  Tmp       : Array[1..8000] Of Byte;
     FFile     : File;
     BytesRead : Word;
     Loop      : Word;
BEGIN
     ASSIGN(FFile,dtApp^.WorkDir+'\TMP'+_String(dtWindows^.NumWindows)+'.$$$');
     RESET(FFile,1);
     BLOCKREAD(FFile,Tmp,SizeOf(Tmp),BytesRead);
     CLOSE(FFile);
     ERASE(FFile);
     FOR Loop := 1 TO dtDropList^.NumDropLists DO
     BEGIN
       CLOSE(dtDropList^.List[Loop].FFile);
       ERASE(dtDropList^.List[Loop].FFile);
     END;
     FOR Loop := 1 TO dtPickList^.NumPickLists DO
     BEGIN
       CLOSE(dtPickList^.List[Loop].FFile);
       ERASE(dtPickList^.List[Loop].FFile);
     END;
     FOR Loop := 1 TO dtEditor^.NumEditors DO
     BEGIN
       Dispose(dtEditor^.Editor[Loop].BodyText);
     END;
     _HideMouse;
     Move(Tmp,MEM[SegB800:0],dtApp^.VideoMode*160);
     _ShowMouse;
     DEC(dtWindows^.NumWindows);
     {Load The Last Window! FUCK}
END;


PROCEDURE winStart;
VAR  Loop  : Word;
     Loop2 : Word;
     x     : Word;
     y     : Word;
BEGIN
     FOR Loop := 1 TO dtDropList^.NumDropLists DO
     BEGIN
       CLOSE(dtDropList^.List[Loop].FFile);
       RESET(dtDropList^.List[Loop].FFile);
       winDrawDropList(Loop,False);
     END;
     FOR Loop := 1 TO dtPickList^.NumPickLists DO
     BEGIN
       CLOSE(dtPickList^.List[Loop].FFile);
       RESET(dtPickList^.List[Loop].FFile);
       winDrawPickList(Loop,False,True);
       x := dtPickList^.List[Loop].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos+dtPickList^.List[Loop].Len+2;
       y := dtPickList^.List[Loop].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos-1;
       _HideMouse;
       FOR Loop2 := 1 TO dtPickList^.List[Loop].OnScreen DO
       BEGIN
         IF Loop2=1 THEN
         BEGIN
           FastWrite('',y+Loop2,x,dtColours^.ScrollBarH);
         END
         ELSE IF Loop2=dtPickList^.List[Loop].OnScreen THEN
         BEGIN
           FastWrite('',y+Loop2,x,dtColours^.ScrollBarH);
         END
         ELSE
         BEGIN
           FastWrite('°',y+Loop2,x,dtColours^.ScrollBarL);
         END;
       END;
       winPickScroller(Loop);
       _ShowMouse;
     END;
     FOR Loop := 1 TO dtEditor^.NumEditors DO winEditorRedraw(Loop,False,True,False);
     CASE dtEventQueue[1].EventType OF
     1:   winDrawButton(1,True,False);        {Button}
     2:   winDrawOnOff(1,True);               {On/Off Toggle}
     3:   winDrawDropList(1,True);            {Drop Lists}
     4:   winDrawBackPal(1,True);             {Background Palettes}
     5:   winDrawForePal(1,True);             {Foreground Palettes}
     6:   winDrawPickList(1,True,True);       {Pick Lists}
     7:   winEditorRedraw(1,False,True,True); {Editors}
     END;
END;


FUNCTION winEventHandler: Word;
VAR  C          : Char;
     Work       : Word;
     Loop       : Word;
     MouseB     : Word;
     MouseX     : Word;
     MouseY     : Word;
     OuttaHere  : Boolean;
     x1,x2,y    : Word;
     Selected   : Boolean;
     SavedEvent : Word;
LABEL             PassTheKey;

     PROCEDURE PreviousEvent;
     BEGIN
          winClearCurrentEvent;
          DEC(dtCurrentEvent);
          IF dtCurrentEvent=0 THEN dtCurrentEvent := dtNumEvents;
          winDrawCurrentEvent;
     END;

     PROCEDURE NextEvent;
     BEGIN
          winClearCurrentEvent;
          INC(dtCurrentEvent);
          IF dtCurrentEvent>dtNumEvents THEN dtCurrentEvent := 1;
          winDrawCurrentEvent;
     END;

     PROCEDURE ToggleOnOff;
     BEGIN
          Work := dtEventQueue[dtCurrentEvent].IndexNum;
          IF dtOnOff^.Button[Work].Enabled THEN
          BEGIN
            IF dtOnOff^.Button[Work].Status
               THEN dtOnOff^.Button[Work].Status := False
               ELSE dtOnOff^.Button[Work].Status := True;
            winDrawCurrentEvent;
          END;
     END;

     PROCEDURE KillTime;
     BEGIN
          REPEAT
            TimeSlice;
          UNTIL _MousePosition(MouseX,MouseY)=0;
     END;

BEGIN
     winEventHandler := 0;
     MouseB := _MousePosition(MouseX,MouseY);
     IF MouseB=1 THEN
     BEGIN
       SavedEvent := dtCurrentEvent;
       IF winFindPickList(MouseX,MouseY) THEN
       BEGIN
         Work := dtEventQueue[dtCurrentEvent].IndexNum;
         winDoPickList(Work,MouseX,MouseY);
       END
       ELSE IF winFindOnOff(MouseX,MouseY) THEN
       BEGIN
         ToggleOnOff;
         KillTime;
       END
       ELSE IF winFindDropList(MouseX,MouseY) THEN
       BEGIN
         Work := dtEventQueue[dtCurrentEvent].IndexNum;
         IF dtDropList^.List[Work].Enabled THEN
         BEGIN
           winDoDropList(Work);
           winDrawCurrentEvent;
         END;
         KillTime;
       END
       ELSE IF winDoBackground(MouseX,MouseY) THEN
       BEGIN
         Work := dtEventQueue[dtCurrentEvent].IndexNum;
         winSetBackground(Work,MouseX,MouseY);
       END
       ELSE IF winDoForeground(MouseX,MouseY) THEN
       BEGIN
         Work := dtEventQueue[dtCurrentEvent].IndexNum;
         winSetForeground(Work,MouseX,MouseY);
       END
       ELSE IF winDoEditor(MouseX,MouseY) THEN
       BEGIN
         KillTime;
       END
       ELSE IF winFindButton(MouseX,MouseY) THEN
       BEGIN
         winDrawButton(dtEventQueue[dtCurrentEvent].IndexNum,True,True);
         x1 := dtButtons^.Button[dtCurrentEvent].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
         x2 := x1+dtButtons^.Button[dtCurrentEvent].Len-1;
         y  := dtButtons^.Button[dtCurrentEvent].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
         OuttaHere := False;
         Selected  := True;
         REPEAT
           MouseB := _MousePosition(MouseX,MouseY);
           CASE MouseB OF
           0:   OuttaHere := True;
           1:   TimeSlice;
           END;
           IF ((MouseX<x1) OR (MouseX>x2) OR (MouseY<>Y)) THEN
           BEGIN
             OuttaHere := True;
             Selected  := False;
           END;
         UNTIL OuttaHere;
         winDrawButton(dtEventQueue[dtCurrentEvent].IndexNum,True,False);
         IF Selected THEN
         BEGIN
           Work := dtEventQueue[dtCurrentEvent].IndexNum;
           IF dtButtons^.Button[Work].Enabled THEN winEventHandler := Work;
         END;
       END
       ELSE TimeSlice;
     END
     ELSE IF KeyPressed THEN
     BEGIN
       C := ReadKey;
       CASE C OF
       #0:  BEGIN
              C := ReadKey;
              CASE C OF
              #15:   PreviousEvent; {Shift-Tab}
              #45:   BEGIN {Alt-X}
                       winClearCurrentEvent;
                       ApplicationClosed := True;
                     END;
              #60:   winShellToDos; {Dos}
              #59:   BEGIN {F1}
                       {FUCK}
                     END;
              #72:   BEGIN {Up Arrow}
                       CASE dtEventQueue[dtCurrentEvent].EventType OF
                       1,2,3: PreviousEvent;
                       4:     winMakeBackChange(dtEventQueue[dtCurrentEvent].IndexNum,directionUP);
                       5:     winMakeForeChange(dtEventQueue[dtCurrentEvent].IndexNum,directionUP);
                       6:     BEGIN
                                Work := dtEventQueue[dtCurrentEvent].IndexNum;
                                IF dtPickList^.List[Work].Current>1 THEN
                                BEGIN
                                  DEC(dtPickList^.List[Work].Current);
                                  winDrawPickList(Work,True,False);
                                END;
                              END;
                       7:     winEditorUpArrow(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #80:   BEGIN {Down Arrow}
                       CASE dtEventQueue[dtCurrentEvent].EventType OF
                       1,2,3: NextEvent;
                       4:     winMakeBackChange(dtEventQueue[dtCurrentEvent].IndexNum,directionDOWN);
                       5:     winMakeForeChange(dtEventQueue[dtCurrentEvent].IndexNum,directionDOWN);
                       6:     BEGIN
                                Work := dtEventQueue[dtCurrentEvent].IndexNum;
                                IF dtPickList^.List[Work].Current<dtPickList^.List[Work].NumItems THEN
                                BEGIN
                                  INC(dtPickList^.List[Work].Current);
                                  winDrawPickList(Work,True,False);
                                END;
                              END;
                       7:     winEditorDownArrow(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #75:   BEGIN {Left Arrow}
                       CASE dtEventQueue[dtCurrentEvent].EventType OF
                       4:   winMakeBackChange(dtEventQueue[dtCurrentEvent].IndexNum,directionLEFT);
                       5:   winMakeForeChange(dtEventQueue[dtCurrentEvent].IndexNum,directionLEFT);
                       7:   winEditorLeftArrow(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #77:   BEGIN {Right Arrow}
                       CASE dtEventQueue[dtCurrentEvent].EventType OF
                       4:   winMakeBackChange(dtEventQueue[dtCurrentEvent].IndexNum,directionRIGHT);
                       5:   winMakeForeChange(dtEventQueue[dtCurrentEvent].IndexNum,directionRIGHT);
                       7:   winEditorRightArrow(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #73:   BEGIN {PgUp}
                       IF dtEventQueue[dtCurrentEvent].EventType=6 THEN
                       BEGIN
                         Work := dtEventQueue[dtCurrentEvent].IndexNum;
                         IF (dtPickList^.List[Work].Current>dtPickList^.List[Work].OnScreen) THEN
                         BEGIN
                           DEC(dtPickList^.List[Work].Current,dtPickList^.List[Work].OnScreen);
                           winDrawPickList(Work,True,False);
                         END
                         ELSE IF (dtPickList^.List[Work].Current<>1) THEN
                         BEGIN
                           dtPickList^.List[Work].Current := 1;
                           winDrawPickList(Work,True,False);
                         END;
                       END
                       ELSE IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorPageUp(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #81:   BEGIN {PgDn}
                       IF dtEventQueue[dtCurrentEvent].EventType=6 THEN
                       BEGIN
                         WITH dtPickList^ DO
                         BEGIN
                           Work := dtEventQueue[dtCurrentEvent].IndexNum;
                           IF (List[Work].Current+List[Work].OnScreen<=List[Work].NumItems) THEN
                           BEGIN
                             INC(List[Work].Current,List[Work].OnScreen);
                             winDrawPickList(Work,True,False);
                           END
                           ELSE IF (List[Work].Current<>List[Work].NumItems) THEN
                           BEGIN
                             List[Work].Current := List[Work].NumItems;
                             winDrawPickList(Work,True,False);
                           END;
                         END;
                       END
                       ELSE IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorPageDown(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #132:  BEGIN {Ctrl-PgUp}
                       IF dtEventQueue[dtCurrentEvent].EventType=6 THEN
                       BEGIN
                         Work := dtEventQueue[dtCurrentEvent].IndexNum;
                         IF dtPickList^.List[Work].Current<>1 THEN
                         BEGIN
                           dtPickList^.List[Work].Current := 1;
                           winDrawPickList(Work,True,False);
                         END;
                       END
                       ELSE IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorTop(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #118:  BEGIN {Ctrl+PgDn}
                       IF dtEventQueue[dtCurrentEvent].EventType=6 THEN
                       BEGIN
                         Work := dtEventQueue[dtCurrentEvent].IndexNum;
                         IF dtPickList^.List[Work].Current<>dtPickList^.List[Work].NumItems THEN
                         BEGIN
                           dtPickList^.List[Work].Current := dtPickList^.List[Work].NumItems;
                           winDrawPickList(Work,True,False);
                         END;
                       END
                       ELSE IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorEnd(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #71:   BEGIN {Home}
                       IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorStartOfLine(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #79:   BEGIN {End}
                       IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorEndOfLine(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              #83:   BEGIN {Delete}
                       IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         winEditorDelete(dtEventQueue[dtCurrentEvent].IndexNum);
                       END;
                     END;
              ELSE   BEGIN {Other Presses}
                       IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
                       BEGIN
                         C := Chr(Ord(C)+128);
                         GOTO PassTheKey;
                       END;
                     END;
              END;
            END;
       #8:  BEGIN {Back Space}
              IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
              BEGIN
                winEditorBackspace(dtEventQueue[dtCurrentEvent].IndexNum);
              END;
            END;
       #9:  BEGIN {Tab}
              NextEvent;
            END;
       #27: BEGIN {Esc}
              winClearCurrentEvent;
              winEventHandler := evtExitWindow;
            END;
       #25: BEGIN {Ctrl-Y}
              IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
              BEGIN
                winEditorDeleteLine(dtEventQueue[dtCurrentEvent].IndexNum);
              END;
            END;
       #13: BEGIN {Enter}
              Work := dtEventQueue[dtCurrentEvent].IndexNum;
              CASE dtEventQueue[dtCurrentEvent].EventType OF
              1:   BEGIN {Selected Button}
                     IF dtButtons^.Button[Work].Enabled THEN winEventHandler := Work;
                   END;
              3:   BEGIN {Selected Drop List}
                     IF dtDropList^.List[Work].Enabled THEN
                     BEGIN
                       winDoDropList(Work);
                       winDrawCurrentEvent;
                     END;
                   END;
              7:   BEGIN
                     winEditorInsert(Work,C);
                     winEditorRedraw(Work,False,False,True);
                     WITH dtEditor^.Editor[Work] DO
                     BEGIN
                       IF NOT(IsOnScreen) THEN
                       BEGIN
                         winEditorGetLocators(Work);
                         INC(TopLine);
                         TopCharNum := Locators[TopLine];
                         winEditorRedraw(Work,False,True,True);
                       END;
                     END;
                   END;
              END;
            END;
       #32: BEGIN
              IF dtEventQueue[dtCurrentEvent].EventType=2
                 THEN ToggleOnOff
                 ELSE GOTO PassTheKey;
            END;
       ELSE BEGIN
              PassTheKey:
              IF dtEventQueue[dtCurrentEvent].EventType IN [1..5] THEN
              BEGIN
                C    := UpCase(C);
                Work := 0;
                FOR Loop := 1 TO dtNumEvents DO
                BEGIN
                  CASE dtEventQueue[Loop].EventType OF
                  1:   BEGIN {Button}
                         IF dtButtons^.Button[dtEventQueue[Loop].IndexNum].KeyPress=C THEN
                         BEGIN
                           Work := Loop;
                         END;
                       END;
                  2:   BEGIN {On/Off Selector}
                         IF dtOnOff^.Button[dtEventQueue[Loop].IndexNum].KeyPress=C THEN
                         BEGIN
                           Work := Loop;
                         END;
                       END;
                  3:   BEGIN {Drop List}
                         IF dtDropList^.List[dtEventQueue[Loop].IndexNum].KeyPress=C THEN
                         BEGIN
                           Work := Loop;
                         END;
                       END;
                  4:   BEGIN {Background Palette}
                         IF dtBackGround^.Palette[dtEventQueue[Loop].IndexNum].KeyPress=C THEN
                         BEGIN
                           Work := Loop;
                         END;
                       END;
                  5:   BEGIN {Foreground Palette}
                         IF dtForeGround^.Palette[dtEventQueue[Loop].IndexNum].KeyPress=C THEN
                         BEGIN
                           Work := Loop;
                         END;
                       END;
                  END;
                END;
                IF (Work<>0) THEN
                BEGIN
                  winClearCurrentEvent;
                  dtCurrentEvent := Work;
                  winDrawCurrentEvent;
                  CASE dtEventQueue[dtCurrentEvent].EventType OF
                  1:   BEGIN {Buttons}
                         IF dtButtons^.Button[dtEventQueue[dtCurrentEvent].IndexNum].Enabled THEN
                         BEGIN
                           winEventHandler := dtEventQueue[dtCurrentEvent].IndexNum;
                         END;
                       END;
                  3:   BEGIN {Drop List}
                         Work := dtEventQueue[dtCurrentEvent].IndexNum;
                         IF dtDropList^.List[Work].Enabled THEN
                         BEGIN
                           winDoDropList(Work);
                           winDrawCurrentEvent;
                         END;
                       END;
                  END;
                END;
              END
              ELSE IF dtEventQueue[dtCurrentEvent].EventType=7 THEN
              BEGIN
                Work := dtEventQueue[dtCurrentEvent].IndexNum;
                winEditorInsert(Work,C);
                WITH dtEditor^.Editor[Work] DO
                BEGIN
                  IF ((LENGTH(OnScreen[UserY])>CharsOnScrn) OR (UserX=80)) THEN
                  BEGIN
                    winEditorRedraw(Work,False,False,True);
                    IF NOT(IsOnScreen) THEN
                    BEGIN
                      winEditorGetLocators(Work);
                      INC(TopLine);
                      TopCharNum := Locators[TopLine];
                      winEditorRedraw(Work,False,True,True);
                    END;
                  END
                  ELSE
                  BEGIN
                    _HideMouse;
                    IF (UserX=LENGTH(OnScreen[UserY])+1) THEN
                    BEGIN
                      FastWrite(C,UserY+(YPos-1),UserX+(XPos-1),dtColours^.EditText);
                      INC(UserX);
                    END
                    ELSE
                    BEGIN
                      FastWrite(_Mid(OnScreen[UserY],UserX,Length(OnScreen[UserY])),
                                UserY+(YPos-1),UserX+(XPos-1),dtColours^.EditText);
                      INC(UserX);
                    END;
                    _ShowMouse;
                    winEditorGotoXY(Work,UserX,UserY);
                  END;
                END;
              END;
            END;
       END;
     END
     ELSE TimeSlice;
END;


END.