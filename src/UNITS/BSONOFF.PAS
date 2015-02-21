{$I DEFINES.INC}
UNIT BsOnOff;


INTERFACE


PROCEDURE winDrawOnOff(Index: Word; MakeCurrent: Boolean);
FUNCTION  winFindOnOff(x,y: Word): Boolean;
PROCEDURE winNewOnOff(LabelName: String; x,y: Word; Status,Enabled: Boolean; HelpIndex: Word);


IMPLEMENTATION


USES BsGlobal,BsMouse,BsVideo,BsWindow;


PROCEDURE winDrawOnOff(Index: Word; MakeCurrent: Boolean);
VAR  x,y  : Word;
     C    : Char;
     Temp : String;
     Work : Word;
BEGIN
     Temp := dtOnOff^.Button[Index].LabelName;
     Work := Pos('~',Temp);
     IF (Work<>0) THEN Delete(Temp,Work,1);
     X := dtOnOff^.Button[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
     Y := dtOnOff^.Button[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
     IF dtOnOff^.Button[Index].Status
        THEN C := OnOffToggle
        ELSE C := ' ';
     _HideMouse;
     IF MakeCurrent THEN
     BEGIN
       IF dtOnOff^.Button[Index].Enabled THEN
       BEGIN
          FastWrite(OnOffConfine+Temp,y,x-1,dtColours^.OnOffSNormal);
          FastWrite(C,y,x,dtColours^.OnOffSHighlight);
          IF (Work<>0) THEN FastWrite(Temp[Work],y,x+Work+2,dtColours^.OnOffSHighlight);
       END
       ELSE
       BEGIN
          FastWrite(OnOffConfine+Temp,y,x-1,dtColours^.OnOffSDisabled);
          FastWrite(C,y,x,dtColours^.OnOffSDisabled);
          IF (Work<>0) THEN FastWrite(Temp[Work],y,x+Work+2,dtColours^.OnOffSDisabled);
       END;
     END
     ELSE
     BEGIN
       IF dtOnOff^.Button[Index].Enabled THEN
       BEGIN
          FastWrite(OnOffConfine+Temp,y,x-1,dtColours^.OnOffNormal);
          FastWrite(C,y,x,dtColours^.OnOffHighlight);
          IF (Work<>0) THEN FastWrite(Temp[Work],y,x+Work+2,dtColours^.OnOffHighlight);
       END
       ELSE
       BEGIN
          FastWrite(OnOffConfine+Temp,y,x-1,dtColours^.OnOffDisabled);
          FastWrite(C,y,x,dtColours^.OnOffDisabled);
          IF (Work<>0) THEN FastWrite(Temp[Work],y,x+Work+2,dtColours^.OnOffDisabled);
       END;
     END;
     _ShowMouse;
END;


FUNCTION winFindOnOff(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=2 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         xx  := dtOnOff^.Button[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
         yy  := dtOnOff^.Button[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
         IF y=yy THEN
         BEGIN
           IF ((x>=xx-1) AND (x<=xx+dtOnOff^.Button[Evt].Len+2)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winFindOnOff := True;
             Exit;
           END;
         END;
       END;
     END;
     winFindOnOff := False;
END;


PROCEDURE winNewOnOff(LabelName: String; x,y: Word; Status,Enabled: Boolean; HelpIndex: Word);
VAR  Work : Word;
BEGIN
     INC(dtNumEvents);
     INC(dtOnOff^.NumOnOffs);
     dtEventQueue[dtNumEvents].EventType := 2;
     dtEventQueue[dtNumEvents].IndexNum  := dtOnOff^.NumOnOffs;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].XPos      := x+1;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].YPos      := y;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].LabelName := LabelName;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].Enabled   := Enabled;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].Status    := Status;
     dtOnOff^.Button[dtOnOff^.NumOnOffs].Len       := LENGTH(LabelName);
     Work := Pos('~',LabelName);
     IF (Work<>0) THEN dtOnOff^.Button[dtOnOff^.NumOnOffs].KeyPress := UpCase(LabelName[Work+1])
                  ELSE dtOnOff^.Button[dtOnOff^.NumOnOffs].KeyPress := #0;
     winDrawOnOff(dtOnOff^.NumOnOffs,False);
END;


END.