{$I DEFINES.INC}
UNIT BsDrop;


INTERFACE


PROCEDURE winAppendDropList(Index: Word; InString: String);
PROCEDURE winDoDropList(Index: Word);
PROCEDURE winDrawDropList(Index: Word; MakeCurrent: Boolean);
FUNCTION  winFindDropList(x,y: Word): Boolean;
PROCEDURE winNewDropList(KeyPress: Char; x,y,Len,OnScreen,Current: Word; Enabled: Boolean; HelpIndex: Word);


IMPLEMENTATION


USES BsFrames,BsGlobal,BsMouse,BsMulti,BsString,BsVideo,BsWindow,Crt;


PROCEDURE winNewDropList(KeyPress: Char; x,y,Len,OnScreen: Word; Current: Word; Enabled: Boolean; HelpIndex: Word);
VAR  Work : Word;
BEGIN
     INC(dtNumEvents);
     INC(dtDropList^.NumDropLists);
     Work := dtDropList^.NumDropLists;
     dtEventQueue[dtNumEvents].EventType := 3;
     dtEventQueue[dtNumEvents].IndexNum  := dtDropList^.NumDropLists;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtDropList^.List[Work].XPos     := x+1;
     dtDropList^.List[Work].YPos     := y;
     dtDropList^.List[Work].Enabled  := Enabled;
     dtDropList^.List[Work].Current  := Current;
     dtDropList^.List[Work].Len      := Len;
     dtDropList^.List[Work].OnScreen := OnScreen;
     dtDropList^.List[Work].KeyPress := UpCase(KeyPress);
     dtDropList^.List[Work].NumItems := 0;
     ASSIGN(dtDropList^.List[Work].FFile,dtApp^.WorkDir+'\DL'+_String(Work)+'.'+_String(dtWindows^.NumWindows));
     REWRITE(dtDropList^.List[Work].FFile);
END;


PROCEDURE winAppendDropList(Index: Word; InString: String);
VAR  DropList : PickListText;
BEGIN
     INC(dtDropList^.List[Index].NumItems);
     DropList.Line := _Mid(InString,1,dtDropList^.List[Index].Len);
     WRITE(dtDropList^.List[Index].FFile,DropList);
END;


PROCEDURE winDrawDropList(Index: Word; MakeCurrent: Boolean);
VAR  Temp      : String;
     X,Y       : Word;
     Work      : Word;
     DropList  : PickListText;
     BytesRead : Word;
BEGIN
     _HideMouse;
     X := dtDropList^.List[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     Y := dtDropList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     IF ((dtDropList^.List[Index].NumItems=0) OR (dtDropList^.List[Index].Current=0)) THEN
     BEGIN
       Temp := _Replicate(#32,dtDropList^.List[Index].Len+2);
       Work := LENGTH(Temp)-1;
     END
     ELSE
     BEGIN
       SEEK(dtDropList^.List[Index].FFile,dtDropList^.List[Index].Current-1);
       READ(dtDropList^.List[Index].FFile,DropList);
       Temp := ' '+_PadRight(DropList.Line,dtDropList^.List[Index].Len)+' ';
       Work := LENGTH(Temp)-1;
     END;
     IF MakeCurrent THEN
     BEGIN
       IF dtDropList^.List[Index].Enabled THEN
       BEGIN
         FastWrite(Temp,y,x-1,dtColours^.DropListSText);
         FastWrite('',y,x+Work+1,dtColours^.DropListSText);
       END
       ELSE
       BEGIN
         FastWrite(Temp,y,x-1,dtColours^.DropListSDisabled);
         FastWrite('',y,x+Work+1,dtColours^.DropListSDisabled);
       END;
       FastWrite('Þ',y,x+Work,dtColours^.DropListSBars);
       FastWrite('Ý',y,x+Work+2,dtColours^.DropListSBars);
     END
     ELSE
     BEGIN
       IF dtDropList^.List[Index].Enabled THEN
       BEGIN
         FastWrite(Temp,y,x-1,dtColours^.DropListText);
         FastWrite('',y,x+Work+1,dtColours^.DropListText);
       END
       ELSE
       BEGIN
         FastWrite(Temp,y,x-1,dtColours^.DropListDisabled);
         FastWrite('',y,x+Work+1,dtColours^.DropListDisabled);
       END;
       FastWrite('Þ',y,x+Work,dtColours^.DropListBars);
       FastWrite('Ý',y,x+Work+2,dtColours^.DropListBars);
     END;
     _ShowMouse;
END;


FUNCTION winFindDropList(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=3 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         xx  := dtDropList^.List[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
         yy  := dtDropList^.List[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
         IF y=yy THEN
         BEGIN
           IF ((x>=xx-1) AND (x<=xx+dtDropList^.List[Evt].Len+3)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winFindDropList := True;
             Exit;
           END;
         END;
       END;
     END;
     winFindDropList := False;
END;


PROCEDURE winDoDropList(Index: Word);
VAR  SaveScreen   : Array[1..8000] Of Byte;
     X1,Y1,X2,Y2  : Word;
     Loop         : Word;
     Top          : Word;
     OnScreen     : Word;
     Temp         : String;
     DropList     : PickListText;
     ScrollActive : Boolean;
     AllDone      : Boolean;
     SavedValue   : Word;
     MouseB       : Word;
     MouseX       : Word;
     MouseY       : Word;
     TheOne       : Word;
     C            : Char;
     BytesRead    : Word;
     NumBars      : Byte;
     y            : Word;

     PROCEDURE RedrawPick;
     VAR  Loop2   : Word;
          Percent : Longint;
     BEGIN
       SEEK(dtDropList^.List[Index].FFile,Top-1);
       _HideMouse;
       FOR Loop2 := 1 TO OnScreen DO
       BEGIN
         READ(dtDropList^.List[Index].FFile,DropList);
         Temp := ' '+_PadRight(DropList.Line,dtDropList^.List[Index].Len)+' ';
         IF Top+Loop2-1=dtDropList^.List[Index].Current
            THEN FastWrite(Temp,y1+Loop2,x1+1,dtColours^.PickSHighlight)
            ELSE FastWrite(Temp,y1+Loop2,x1+1,dtColours^.PickSNormal);
       END;
       IF ScrollActive THEN
       BEGIN
          IF (y<>0) THEN FastWrite('°',y,x2-1,dtColours^.ScrollBarL);
          Y := Trunc((dtDropList^.List[Index].Current/dtDropList^.List[Index].NumItems)*NumBars);
          Y := Y1+2+Y;
          IF (Y<Y1+2) THEN Y := Y1+2;
          IF (Y>Y2-2) THEN Y := Y2-2;
          FastWrite('þ',y,x2-1,dtColours^.ScrollBarH);
       END;
       _ShowMouse;
     END;

     PROCEDURE ReCalcTop;
     BEGIN
          IF (dtDropList^.List[Index].Current>OnScreen-1)
             THEN Top := dtDropList^.List[Index].Current-OnScreen+1
             ELSE Top := 1;
     END;

     PROCEDURE GoDown;
     BEGIN
          IF dtDropList^.List[Index].Current<dtDropList^.List[Index].NumItems THEN
          BEGIN
            INC(dtDropList^.List[Index].Current);
            IF (dtDropList^.List[Index].Current>Top+OnScreen-1) THEN INC(Top);
            RedrawPick;
          END;
     END;

     PROCEDURE GoUp;
     BEGIN
          IF dtDropList^.List[Index].Current>1 THEN
          BEGIN
            DEC(dtDropList^.List[Index].Current);
            IF (dtDropList^.List[Index].Current<Top) THEN DEC(Top);
            RedrawPick;
          END;
     END;

     PROCEDURE GoPgUp;
     BEGIN
          IF dtDropList^.List[Index].Current>OnScreen
             THEN DEC(dtDropList^.List[Index].Current,OnScreen)
             ELSE dtDropList^.List[Index].Current := 1;
          RecalcTop;
          RedrawPick;
     END;

     PROCEDURE GoPgDn;
     BEGIN
          IF dtDropList^.List[Index].Current+OnScreen<dtDropList^.List[Index].NumItems
             THEN INC(dtDropList^.List[Index].Current,OnScreen)
             ELSE dtDropList^.List[Index].Current := dtDropList^.List[Index].NumItems;
          RecalcTop;
          RedrawPick;
     END;

     PROCEDURE KillTime;
     BEGIN
          REPEAT
            TimeSlice;
          UNTIL _MousePosition(MouseX,MouseY)=0;
     END;

BEGIN
     IF dtDropList^.List[Index].NumItems=0 THEN Exit;
     _HideMouse;
     Move(MEM[SegB800:0],SaveScreen,dtApp^.VideoBytes);
     {Draw The Window}
     X1 := dtDropList^.List[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos-1;
     Y1 := dtDropList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos+1;
     X2 := X1+dtDropList^.List[Index].Len+4;
     IF dtDropList^.List[Index].NumItems<dtDropList^.List[Index].OnScreen THEN
     BEGIN
       OnScreen := dtDropList^.List[Index].NumItems;
       ScrollActive := False;
     END
     ELSE
     BEGIN
       OnScreen := dtDropList^.List[Index].OnScreen;
       ScrollActive := True;
     END;
     Y2 := Y1+OnScreen+1;
     Y  := 0;
     IF NOT(ScrollActive) THEN DEC(x2,1);
     winDropShadow(x1,y1,x2,y2);
     winWindowFrame(x1,y1,x2,y2);
     NumBars := OnScreen-2;
     IF ScrollActive THEN
     BEGIN
       FOR Loop := (y1+1) TO (y2-1) DO
       BEGIN
         IF Loop=(y1+1) THEN
         BEGIN
           FastWrite('',Loop,x2-1,dtColours^.ScrollBarH);
         END
         ELSE IF Loop=(y2-1) THEN
         BEGIN
           FastWrite('',Loop,x2-1,dtColours^.ScrollBarH);
         END
         ELSE
         BEGIN
           FastWrite('°',Loop,x2-1,dtColours^.ScrollBarL);
         END;
       END;
     END;
     _ShowMouse;
     ReCalcTop;
     SavedValue := dtDropList^.List[Index].Current;
     RedrawPick;
     AllDone := False;
     REPEAT
       MouseB := _MousePosition(MouseX,MouseY);
       IF MouseB=1 THEN
       BEGIN
         IF ((MouseX>x1) AND (MouseX<x1+dtDropList^.List[Index].Len+3)) THEN
         BEGIN
           IF ((MouseY>y1) AND (MouseY<y2)) THEN
           BEGIN
             dtDropList^.List[Index].Current := Top+MouseY-y1-1;
             RedrawPick;
             KillTime;
             AllDone := True;
           END
           ELSE TimeSlice;
         END
         ELSE IF ScrollActive THEN
         BEGIN
           IF (MouseX=x2-1) THEN
           BEGIN
             IF MouseY=y1+1 THEN
             BEGIN
               GoUp;
             END
             ELSE IF MouseY=y2-1 THEN
             BEGIN
               GoDown;
             END
             ELSE IF ((MouseY>y1+1) AND (MouseY<y)) THEN
             BEGIN
               GoPgUp;
               KillTime;
             END
             ELSE IF ((MouseY>y) AND (MouseY<y2-1)) THEN
             BEGIN
               GoPgDn;
               KillTime;
             END
             ELSE TimeSlice;
           END
           ELSE TimeSlice;
         END
         ELSE TimeSlice;
       END
       ELSE IF MouseB=2 THEN
       BEGIN
         dtDropList^.List[Index].Current := SavedValue;
         AllDone := True;
       END
       ELSE IF KeyPressed THEN
       BEGIN
         C := ReadKey;
         CASE C OF
         #0:  BEGIN
                C := ReadKey;
                CASE C OF
                #45:  BEGIN {Exit App}
                        dtDropList^.List[Index].Current := SavedValue;
                        ApplicationClosed := True;
                        AllDone := True;
                      END;
                #72:  BEGIN {Up}
                        GoUp;
                      END;
                #80:  BEGIN {Down}
                        GoDown;
                      END;
                #73:  BEGIN {Page Up}
                        GoPgUp;
                      END;
                #81:  BEGIN {Page Down}
                        GoPgDn;
                      END;
                #132: BEGIN {Ctrl-PgUp}
                        dtDropList^.List[Index].Current := 1;
                        RecalcTop;
                        RedrawPick;
                      END;
                #118: BEGIN {Ctrl-PgDn}
                        dtDropList^.List[Index].Current := dtDropList^.List[Index].NumItems;
                        RecalcTop;
                        RedrawPick;
                      END;
                END;
              END;
         #13: AllDone := True;
         #27: BEGIN
                dtDropList^.List[Index].Current := SavedValue;
                AllDone := True;
              END;
         END;
       END
       ELSE TimeSlice;
     UNTIL AllDone;
     _HideMouse;
     Move(SaveScreen,MEM[SegB800:0],dtApp^.VideoBytes);
     _ShowMouse;
END;


END.