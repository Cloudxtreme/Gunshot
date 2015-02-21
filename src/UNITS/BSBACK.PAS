{$I DEFINES.INC}
UNIT BsBack;


INTERFACE


FUNCTION  winDoBackground(x,y: Word): Boolean;
PROCEDURE winDrawBackPal(Index: Word; MakeCurrent: Boolean);
PROCEDURE winMakeBackChange(Index: Word; Direction: Byte);
PROCEDURE winNewBackPal(KeyPress: Char; x,y,Current: Word; Enabled: Boolean; HelpIndex: Word);
PROCEDURE winSetBackground(Index,x,y: Word);


IMPLEMENTATION


USES BsGlobal,BsFrames,BsMouse,BsMulti,BsVideo,BsWindow;


FUNCTION winDoBackground(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=4 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         IF dtBackGround^.Palette[Evt].Enabled THEN
         BEGIN
           xx  := dtBackGround^.Palette[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
           yy  := dtBackGround^.Palette[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
           IF ((x>xx) AND (x<xx+13) AND (y>yy) AND (y<yy+3)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winDoBackground := True;
             Exit;
           END;
         END;
       END;
     END;
     winDoBackground := False;
END;


PROCEDURE winDrawBackPal(Index: Word; MakeCurrent: Boolean);
VAR  X,Y  : Word;
     Loop : Word;
     Work : Word;
     Col  : Word;
BEGIN
     X := dtBackGround^.Palette[Index].XPos;
     Y := dtBackGround^.Palette[Index].YPos;
     IF MakeCurrent THEN winRaisedFrame(x,y,x+13,y+3)
                    ELSE winInvertedFrame(x,y,x+13,y+3);
     _HideMouse;
     INC(X,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(Y,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     Work := x+1;
     FOR Loop := 0 TO 7 DO
     BEGIN
       FastWrite('ллл',y+1,work,Loop);
       IF ((dtBackGround^.Palette[Index].Enabled) AND (Loop=dtBackGround^.Palette[Index].Current)) THEN
       BEGIN
         CASE Loop OF
         0:   FastWrite('',y+1,work+1,(0*16)+15);
         1:   FastWrite('',y+1,work+1,(1*16)+15);
         ELSE FastWrite('',y+1,work+1,(0*16)+Loop);
         END;
       END;
       INC(Work,3);
       IF Loop=3 THEN
       BEGIN
         INC(y);
         Work := x+1;
       END;
     END;
     _ShowMouse;
END;


PROCEDURE winMakeBackChange(Index: Word; Direction: Byte);
BEGIN
     IF dtBackGround^.Palette[Index].Enabled THEN
     BEGIN
       CASE Direction OF
       1:   BEGIN
              IF dtBackGround^.Palette[Index].Current>3 THEN
              BEGIN
                DEC(dtBackGround^.Palette[Index].Current,4);
                winDrawBackPal(Index,True);
              END;
            END;
       2:   BEGIN
              IF dtBackGround^.Palette[Index].Current<4 THEN
              BEGIN
                INC(dtBackGround^.Palette[Index].Current,4);
                winDrawBackPal(Index,True);
              END;
            END;
       3:   BEGIN
              IF dtBackGround^.Palette[Index].Current>0 THEN
              BEGIN
                DEC(dtBackGround^.Palette[Index].Current);
                winDrawBackPal(Index,True);
              END;
            END;
       4:   BEGIN
              IF dtBackGround^.Palette[Index].Current<7 THEN
              BEGIN
                INC(dtBackGround^.Palette[Index].Current);
                winDrawBackPal(Index,True);
              END;
            END;
       END;
     END;
END;


PROCEDURE winNewBackPal(KeyPress: Char; x,y,Current: Word; Enabled: Boolean; HelpIndex: Word);
BEGIN
     INC(dtNumEvents);
     INC(dtBackGround^.NumBackGround);
     dtEventQueue[dtNumEvents].EventType := 4;
     dtEventQueue[dtNumEvents].IndexNum  := dtBackGround^.NumBackGround;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtBackGround^.Palette[dtBackGround^.NumBackGround].KeyPress := UpCase(KeyPress);
     dtBackGround^.Palette[dtBackGround^.NumBackGround].XPos     := x;
     dtBackGround^.Palette[dtBackGround^.NumBackGround].YPos     := y;
     dtBackGround^.Palette[dtBackGround^.NumBackGround].Enabled  := Enabled;
     dtBackGround^.Palette[dtBackGround^.NumBackGround].Current  := Current;
     winDrawBackPal(dtBackGround^.NumBackGround,False);
END;


PROCEDURE winSetBackground(Index,x,y: Word);
VAR  xx,yy : Word;
     Work  : Word;
     Wadd  : Word;
BEGIN
     xx := dtBackGround^.Palette[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos+1;
     yy := dtBackGround^.Palette[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos+1;
          IF y=yy THEN wAdd := 0
     ELSE IF y=yy+1 THEN wAdd := 4
     ELSE Exit;
     IF x IN [xx..xx+2] THEN
     BEGIN
       INC(wAdd,0);
       IF (dtBackGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtBackGround^.Palette[Index].Current := wAdd;
         winDrawBackPal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+3..xx+5] THEN
     BEGIN
       INC(wAdd,1);
       IF (dtBackGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtBackGround^.Palette[Index].Current := wAdd;
         winDrawBackPal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+6..xx+8] THEN
     BEGIN
       INC(wAdd,2);
       IF (dtBackGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtBackGround^.Palette[Index].Current := wAdd;
         winDrawBackPal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+9..xx+11] THEN
     BEGIN
       INC(wAdd,3);
       IF (dtBackGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtBackGround^.Palette[Index].Current := wAdd;
         winDrawBackPal(Index,True);
       END
       ELSE TimeSlice;
     END;
END;


END.