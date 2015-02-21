{$I DEFINES.INC}
UNIT BsButton;


INTERFACE


PROCEDURE winDrawButton(Index: Word; MakeCurrent,Depress: Boolean);
FUNCTION  winFindButton(x,y: Word): Boolean;
PROCEDURE winNewButton(LabelName: String; x,y,Len: Word; Enabled: Boolean; HelpIndex: Word);


IMPLEMENTATION


USES BsGlobal,BsMouse,BsString,BsVideo,BsWindow;


PROCEDURE winDrawButton(Index: Word; MakeCurrent,Depress: Boolean);
VAR  LabelName : String;
     Work      : Word;
     X,Y       : Word;
BEGIN
     _HideMouse;
     X := dtButtons^.Button[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     Y := dtButtons^.Button[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     IF Depress THEN
     BEGIN
       IF dtApp^.AppStyle=1 THEN
       BEGIN
         LabelName := _PadRight(''+dtButtons^.Button[Index].LabelName,dtButtons^.Button[Index].Len)+'';
         Work := Pos('~',LabelName);
         Delete(LabelName,Work,1);
         IF dtButtons^.Button[Index].Enabled THEN
         BEGIN
           FastWrite(LabelName,y,x,dtColours^.ButtonSNormal);
           FastWrite(LabelName[Work],y,x+Work-1,dtColours^.ButtonSHighlight);
         END
         ELSE FastWrite(LabelName,y,x,dtColours^.ButtonSDisabled);
       END
       ELSE
       BEGIN
         LabelName := _PadRight(''+dtButtons^.Button[Index].LabelName,dtButtons^.Button[Index].Len)+'';
         Work := Pos('~',LabelName);
         Delete(LabelName,Work,1);
         IF dtButtons^.Button[Index].Enabled THEN
         BEGIN
           FastWrite(LabelName,y,x+1,dtColours^.ButtonSNormal);
           FastWrite(LabelName[Work],y,x+Work,dtColours^.ButtonSHighlight);
         END
         ELSE FastWrite(LabelName,y,x+1,dtColours^.ButtonSDisabled);
         Work := LENGTH(LabelName);
         FastWrite(' ',y,x,dtColours^.WindowBack);
         FastWrite(_Replicate(' ',Work),y+1,x+1,dtColours^.WindowBack);
       END;
     END
     ELSE
     BEGIN
       IF MakeCurrent THEN
       BEGIN
         LabelName := _PadRight(''+dtButtons^.Button[Index].LabelName,dtButtons^.Button[Index].Len)+'';
         Work := Pos('~',LabelName);
         Delete(LabelName,Work,1);
         IF dtButtons^.Button[Index].Enabled THEN
         BEGIN
           FastWrite(LabelName,y,x,dtColours^.ButtonSNormal);
           FastWrite(LabelName[Work],y,x+Work-1,dtColours^.ButtonSHighlight);
         END
         ELSE FastWrite(LabelName,y,x,dtColours^.ButtonSDisabled);
       END
       ELSE
       BEGIN
         LabelName := _PadRight(' '+dtButtons^.Button[Index].LabelName,dtButtons^.Button[Index].Len+1);
         Work := Pos('~',LabelName);
         Delete(LabelName,Work,1);
         IF dtButtons^.Button[Index].Enabled THEN
         BEGIN
           FastWrite(LabelName,y,x,dtColours^.ButtonNormal);
           FastWrite(LabelName[Work],y,x+Work-1,dtColours^.ButtonHighlight);
         END
         ELSE FastWrite(LabelName,y,x,dtColours^.ButtonDisabled);
       END;
       IF (dtApp^.AppStyle<>1) THEN
       BEGIN
         Work := LENGTH(LabelName);
         FastWrite('Ü',y,x+Work,dtColours^.ButtonShadow);
         FastWrite(_Replicate('ß',Work),y+1,x+1,dtColours^.ButtonShadow);
       END;
     END;
     _ShowMouse;
END;


FUNCTION winFindButton(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
     Len  : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=1 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         xx  := dtButtons^.Button[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
         yy  := dtButtons^.Button[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
         Len := dtButtons^.Button[Evt].Len;
         IF y=yy THEN
         BEGIN
           IF ((x>=xx) AND (x<xx+Len)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winFindButton := True;
             Exit;
           END;
         END;
       END;
     END;
     winFindButton := False;
END;


PROCEDURE winNewButton(LabelName: String; x,y,Len: Word; Enabled: Boolean; HelpIndex: Word);
VAR  Work : Word;
BEGIN
     INC(dtNumEvents);
     INC(dtButtons^.NumButtons);
     dtEventQueue[dtNumEvents].EventType := 1;
     dtEventQueue[dtNumEvents].IndexNum  := dtButtons^.NumButtons;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtButtons^.Button[dtButtons^.NumButtons].XPos      := x;
     dtButtons^.Button[dtButtons^.NumButtons].YPos      := y;
     dtButtons^.Button[dtButtons^.NumButtons].LabelName := LabelName;
     dtButtons^.Button[dtButtons^.NumButtons].Enabled   := Enabled;
     dtButtons^.Button[dtButtons^.NumButtons].Len       := Len;
     Work := Pos('~',LabelName);
     dtButtons^.Button[dtButtons^.NumButtons].KeyPress := UpCase(LabelName[Work+1]);
     winDrawButton(dtButtons^.NumButtons,False,False);
END;


END.
