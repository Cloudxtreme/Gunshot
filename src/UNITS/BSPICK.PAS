{$I DEFINES.INC}
UNIT BsPick;


INTERFACE


PROCEDURE winAppendPickList(Index: Word; InString: String);
PROCEDURE winDrawPickList(Index: Word; MakeCurrent,DrawFrame: Boolean);
PROCEDURE winNewPickList(x,y,Len,OnScreen: Word; Current: Word; HelpIndex: Word);
PROCEDURE winPickReCalcTop(Index: Word);
PROCEDURE winSetPickList(Index,x,y: Word);
PROCEDURE winDoPickList(Index,x,y: Word);
PROCEDURE winPickScroller(Index: Word);
FUNCTION  winFindPickList(x,y: Word): Boolean;


IMPLEMENTATION


USES BsFrames,BsGlobal,BsMouse,BsMulti,BsString,BsVideo,BsWindow,Crt;


PROCEDURE winNewPickList(x,y,Len,OnScreen: Word; Current: Word; HelpIndex: Word);
VAR  Work : Word;
BEGIN
     INC(dtNumEvents);
     INC(dtPickList^.NumPickLists);
     Work := dtPickList^.NumPickLists;
     dtEventQueue[dtNumEvents].EventType := 6;
     dtEventQueue[dtNumEvents].IndexNum  := dtPickList^.NumPickLists;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtPickList^.List[Work].XPos     := x;
     dtPickList^.List[Work].YPos     := y;
     dtPickList^.List[Work].Current  := Current;
     dtPickList^.List[Work].Len      := Len;
     dtPickList^.List[Work].OnScreen := OnScreen;
     dtPickList^.List[Work].NumItems := 0;
     dtPickList^.List[Work].Top      := 1;
     dtPickList^.List[Work].Scroller := 0;
     ASSIGN(dtPickList^.List[Work].FFile,dtApp^.WorkDir+'\PL'+_String(Work)+'.'+_String(dtWindows^.NumWindows));
     REWRITE(dtPickList^.List[Work].FFile);
END;


PROCEDURE winAppendPickList(Index: Word; InString: String);
VAR  PickList : PickListText;
BEGIN
     INC(dtPickList^.List[Index].NumItems);
     PickList.Line := InString;
     WRITE(dtPickList^.List[Index].FFile,PickList);
END;


PROCEDURE winPickReCalcTop(Index: Word);
BEGIN
     IF dtPickList^.List[Index].Current<dtPickList^.List[Index].Top THEN
     BEGIN
       dtPickList^.List[Index].Top := dtPickList^.List[Index].Current;
     END
     ELSE IF dtPickList^.List[Index].Current>dtPickList^.List[Index].Top+dtPickList^.List[Index].OnScreen-1 THEN
     BEGIN
       dtPickList^.List[Index].Top := dtPickList^.List[Index].Current-dtPickList^.List[Index].OnScreen+1;
     END;
END;


PROCEDURE winDrawPickList(Index: Word; MakeCurrent,DrawFrame: Boolean);
VAR  Temp      : String;
     X,Y       : Word;
     Work      : Word;
     PickList  : PickListText;
     BytesRead : Word;
     Loop      : Word;
BEGIN
     IF dtPickList^.List[Index].NumItems=0 THEN Exit;
     _HideMouse;
     X := dtPickList^.List[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     Y := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     winPickReCalcTop(Index);
     SEEK(dtPickList^.List[Index].FFile,dtPickList^.List[Index].Top-1);
     IF MakeCurrent THEN
     BEGIN
       IF DrawFrame THEN winRaisedFrame(dtPickList^.List[Index].XPos-1,dtPickList^.List[Index].YPos-1,
                                        dtPickList^.List[Index].XPos+dtPickList^.List[Index].Len+3,
                                        dtPickList^.List[Index].YPos+dtPickList^.List[Index].OnScreen);
       Work := dtPickList^.List[Index].Top;
       FOR Loop := 1 TO dtPickList^.List[Index].OnScreen DO
       BEGIN
         IF NOT(EOF(dtPickList^.List[Index].FFile))
            THEN READ(dtPickList^.List[Index].FFile,PickList)
            ELSE PickList.Line := '';
         Temp := ' '+_PadRight(PickList.Line,dtPickList^.List[Index].Len)+' ';
         IF Work=dtPickList^.List[Index].Current
            THEN FastWrite(Temp,y+Loop-1,x,dtColours^.PickSHighlight)
            ELSE FastWrite(Temp,y+Loop-1,x,dtColours^.PickSNormal);
         INC(Work);
       END;
     END
     ELSE
     BEGIN
       IF DrawFrame THEN winInvertedFrame(dtPickList^.List[Index].XPos-1,dtPickList^.List[Index].YPos-1,
                                          dtPickList^.List[Index].XPos+dtPickList^.List[Index].Len+3,
                                          dtPickList^.List[Index].YPos+dtPickList^.List[Index].OnScreen);
       Work := dtPickList^.List[Index].Top;
       FOR Loop := 1 TO dtPickList^.List[Index].OnScreen DO
       BEGIN
         IF NOT(EOF(dtPickList^.List[Index].FFile))
            THEN READ(dtPickList^.List[Index].FFile,PickList)
            ELSE PickList.Line := '';
         Temp := ' '+_PadRight(PickList.Line,dtPickList^.List[Index].Len)+' ';
         IF Work=dtPickList^.List[Index].Current
            THEN FastWrite(Temp,y+Loop-1,x,dtColours^.PickHighlight)
            ELSE FastWrite(Temp,y+Loop-1,x,dtColours^.PickNormal);
         INC(Work);
       END;
     END;
     winPickScroller(Index);
     _ShowMouse;
END;


PROCEDURE winChangePickList(Index: Word; OldSelect,NewSelect: Longint);
VAR  Temp      : String;
     X,Y       : Word;
     Work      : Word;
     PickList  : PickListText;
     BytesRead : Word;
     Loop      : Word;
BEGIN
     IF dtPickList^.List[Index].NumItems=0 THEN Exit;
     _HideMouse;
     X := dtPickList^.List[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     Y := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     SEEK(dtPickList^.List[Index].FFile,dtPickList^.List[Index].Top-1);
     Work := dtPickList^.List[Index].Top;
     FOR Loop := 1 TO dtPickList^.List[Index].OnScreen DO
     BEGIN
       IF NOT(EOF(dtPickList^.List[Index].FFile))
          THEN READ(dtPickList^.List[Index].FFile,PickList)
          ELSE PickList.Line := '';
       Temp := ' '+_PadRight(PickList.Line,dtPickList^.List[Index].Len)+' ';
            IF Work=NewSelect THEN FastWrite(Temp,y+Loop-1,x,dtColours^.PickSHighlight)
       ELSE IF Work=OldSelect THEN FastWrite(Temp,y+Loop-1,x,dtColours^.PickSNormal);
       INC(Work);
     END;
     winPickScroller(Index);
     _ShowMouse;
END;


FUNCTION winFindPickList(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=6 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         xx  := dtPickList^.List[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
         yy  := dtPickList^.List[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
         IF ((x>=xx) AND (x<=xx+dtPickList^.List[Evt].Len+2)) THEN
         BEGIN
           IF ((y>=yy) AND (y<=yy+dtPickList^.List[Evt].OnScreen-1)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winFindPickList := True;
             Exit;
           END;
         END;
       END;
     END;
     winFindPickList := False;
END;


PROCEDURE winSetPickList(Index,x,y: Word);
VAR  TheOne : Word;
     yy     : Word;
BEGIN
     yy := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     TheOne := y-yy+dtPickList^.List[Index].Top;
     IF (dtPickList^.List[Index].Current<>TheOne) THEN
     BEGIN
       IF (TheOne<=dtPickList^.List[Index].NumItems) THEN
       BEGIN
         dtPickList^.List[Index].Current := TheOne;
         winDrawPickList(Index,True,False);
       END;
     END;
END;


PROCEDURE winReselectPickList(Index,x,y: Word);
VAR  TheOne : Word;
     yy     : Word;
     OldOne : Word;
BEGIN
     yy := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     TheOne := y-yy+dtPickList^.List[Index].Top;
     IF (dtPickList^.List[Index].Current<>TheOne) THEN
     BEGIN
       IF (TheOne<=dtPickList^.List[Index].NumItems) THEN
       BEGIN
         OldOne := dtPickList^.List[Index].Current;
         dtPickList^.List[Index].Current := TheOne;
         winChangePickList(Index,OldOne,TheOne);
       END;
     END;
END;


PROCEDURE winPickScroller(Index: Word);
VAR  x1,y1,y2 : Word;
     NumBars  : Byte;
BEGIN
     IF dtPickList^.List[Index].NumItems=0 THEN Exit;
     NumBars := dtPickList^.List[Index].OnScreen-2;
     x1 := dtPickList^.List[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos+dtPickList^.List[Index].Len+2;
     y1 := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos+1;
     y2 := y1+NumBars-1;
     IF (dtPickList^.List[Index].Scroller<>0) THEN FastWrite('°',dtPickList^.List[Index].Scroller,x1,dtColours^.ScrollBarL);
     dtPickList^.List[Index].Scroller := Trunc((dtPickList^.List[Index].Current/dtPickList^.List[Index].NumItems)*NumBars);
     dtPickList^.List[Index].Scroller := dtPickList^.List[Index].Scroller+y1;
     IF (dtPickList^.List[Index].Scroller<Y1) THEN dtPickList^.List[Index].Scroller := Y1;
     IF (dtPickList^.List[Index].Scroller>Y2) THEN dtPickList^.List[Index].Scroller := Y2;
     FastWrite('þ',dtPickList^.List[Index].Scroller,x1,dtColours^.ScrollBarH);
END;


PROCEDURE winDoPickList(Index,x,y: Word);
VAR  y1,y2   : Word;
     NumBars : Byte;

     PROCEDURE KillTime;
     BEGIN
          REPEAT
            TimeSlice;
          UNTIL _MousePosition(x,y)=0;
     END;

BEGIN
     NumBars := dtPickList^.List[Index].OnScreen-2;
     y1 := dtPickList^.List[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     y2 := y1+NumBars+1;
     IF (x<dtPickList^.List[Index].XPos+dtPickList^.List[Index].Len+dtWindows^.Window[dtWindows^.NumWindows].XPos+2) THEN
     BEGIN
       {winSetPickList(Index,x,y);}
       winReselectPickList(Index,x,y);
     END
     ELSE
     BEGIN
       IF y=y1 THEN
       BEGIN
         IF dtPickList^.List[Index].Current>1 THEN
         BEGIN
           DEC(dtPickList^.List[Index].Current);
           winDrawPickList(Index,True,False);
         END;
       END
       ELSE IF y=y2 THEN
       BEGIN
         IF dtPickList^.List[Index].Current<dtPickList^.List[Index].NumItems THEN
         BEGIN
           INC(dtPickList^.List[Index].Current);
           winDrawPickList(Index,True,False);
         END;
       END
       ELSE IF ((y>y1) AND (y<dtPickList^.List[Index].Scroller)) THEN
       BEGIN
         IF (dtPickList^.List[Index].Current>dtPickList^.List[Index].OnScreen) THEN
         BEGIN
           DEC(dtPickList^.List[Index].Current,dtPickList^.List[Index].OnScreen);
           winDrawPickList(Index,True,False);
         END
         ELSE IF (dtPickList^.List[Index].Current<>1) THEN
         BEGIN
           dtPickList^.List[Index].Current := 1;
           winDrawPickList(Index,True,False);
         END;
         KillTime;
       END
       ELSE IF ((y<y2) AND (y>dtPickList^.List[Index].Scroller)) THEN
       BEGIN
         IF (dtPickList^.List[Index].Current+dtPickList^.List[Index].OnScreen<=dtPickList^.List[Index].NumItems) THEN
         BEGIN
           INC(dtPickList^.List[Index].Current,dtPickList^.List[Index].OnScreen);
           winDrawPickList(Index,True,False);
         END
         ELSE IF (dtPickList^.List[Index].Current<>dtPickList^.List[Index].NumItems) THEN
         BEGIN
           dtPickList^.List[Index].Current := dtPickList^.List[Index].NumItems;
           winDrawPickList(Index,True,False);
         END;
         KillTime;
       END;
     END;
END;


END.