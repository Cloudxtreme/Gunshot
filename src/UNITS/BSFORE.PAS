{$I DEFINES.INC}
UNIT BsFore;


INTERFACE


FUNCTION  winDoForeground(x,y: Word): Boolean;
PROCEDURE winDrawForePal(Index: Word; MakeCurrent: Boolean);
PROCEDURE winMakeForeChange(Index: Word; Direction: Byte);
PROCEDURE winNewForePal(KeyPress: Char; x,y,Current: Word; Enabled: Boolean; HelpIndex: Word);
PROCEDURE winSetForeground(Index,x,y: Word);


IMPLEMENTATION


USES BsFrames,BsGlobal,BsMouse,BsMulti,BsVideo,BsWindow;


FUNCTION winDoForeground(x,y: Word): Boolean;
VAR  Loop : Word;
     Evt  : Word;
     xx   : Word;
     yy   : Word;
BEGIN
     FOR Loop := 1 TO dtNumEvents DO
     BEGIN
       IF dtEventQueue[Loop].EventType=5 THEN
       BEGIN
         Evt := dtEventQueue[Loop].IndexNum;
         IF dtForeGround^.Palette[Evt].Enabled THEN
         BEGIN
           xx  := dtForeGround^.Palette[Evt].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos;
           yy  := dtForeGround^.Palette[Evt].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos;
           IF ((x>xx) AND (x<xx+13) AND (y>yy) AND (y<yy+5)) THEN
           BEGIN
             IF (dtCurrentEvent<>Loop) THEN
             BEGIN
               winClearCurrentEvent;
               dtCurrentEvent := Loop;
               winDrawCurrentEvent;
             END;
             winDoForeground := True;
             Exit;
           END;
         END;
       END;
     END;
     winDoForeground := False;
END;


PROCEDURE winDrawForePal(Index: Word; MakeCurrent: Boolean);
VAR  X,Y     : Word;
     Loop    : Word;
     Work    : Word;
     Col     : Word;
BEGIN
     X := dtForeGround^.Palette[Index].XPos;
     Y := dtForeGround^.Palette[Index].YPos;
     IF MakeCurrent THEN winRaisedFrame(x,y,x+13,y+5)
                    ELSE winInvertedFrame(x,y,x+13,y+5);
     _HideMouse;
     INC(X,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(Y,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     Work := x+1;
     FOR Loop := 0 TO 15 DO
     BEGIN
       FastWrite('ллл',y+1,work,Loop);
       IF ((dtForeGround^.Palette[Index].Enabled) AND (Loop=dtForeGround^.Palette[Index].Current)) THEN
       BEGIN
         CASE Loop OF
         0:   FastWrite('',y+1,work+1,(0*16)+15);
         1:   FastWrite('',y+1,work+1,(1*16)+15);
         ELSE FastWrite('',y+1,work+1,(0*16)+Loop);
         END;
       END;
       INC(Work,3);
       IF Loop IN [3,7,11] THEN
       BEGIN
         INC(y);
         Work := x+1;
       END;
     END;
     _ShowMouse;
END;


PROCEDURE winMakeForeChange(Index: Word; Direction: Byte);
BEGIN
     IF dtForeGround^.Palette[Index].Enabled THEN
     BEGIN
       CASE Direction OF
       1:   BEGIN
              IF dtForeGround^.Palette[Index].Current>3 THEN
              BEGIN
                DEC(dtForeGround^.Palette[Index].Current,4);
                winDrawForePal(Index,True);
              END;
            END;
       2:   BEGIN
              IF dtForeGround^.Palette[Index].Current<12 THEN
              BEGIN
                INC(dtForeGround^.Palette[Index].Current,4);
                winDrawForePal(Index,True);
              END;
            END;
       3:   BEGIN
              IF dtForeGround^.Palette[Index].Current>0 THEN
              BEGIN
                DEC(dtForeGround^.Palette[Index].Current);
                winDrawForePal(Index,True);
              END;
            END;
       4:   BEGIN
              IF dtForeGround^.Palette[Index].Current<15 THEN
              BEGIN
                INC(dtForeGround^.Palette[Index].Current);
                winDrawForePal(Index,True);
              END;
            END;
       END;
     END;
END;


PROCEDURE winNewForePal(KeyPress: Char; x,y,Current: Word; Enabled: Boolean; HelpIndex: Word);
BEGIN
     INC(dtNumEvents);
     INC(dtForeGround^.NumForeGround);
     dtEventQueue[dtNumEvents].EventType := 5;
     dtEventQueue[dtNumEvents].IndexNum  := dtForeGround^.NumForeGround;
     dtEventQueue[dtNumEvents].HelpIndex := HelpIndex;
     dtForeGround^.Palette[dtForeGround^.NumForeGround].KeyPress := UpCase(KeyPress);
     dtForeGround^.Palette[dtForeGround^.NumForeGround].XPos     := x;
     dtForeGround^.Palette[dtForeGround^.NumForeGround].YPos     := y;
     dtForeGround^.Palette[dtForeGround^.NumForeGround].Enabled  := Enabled;
     dtForeGround^.Palette[dtForeGround^.NumForeGround].Current  := Current;
     winDrawForePal(dtForeGround^.NumForeGround,False);
END;


PROCEDURE winSetForeground(Index,x,y: Word);
VAR  xx,yy : Word;
     Work  : Word;
     Wadd  : Word;
BEGIN
     xx := dtForeGround^.Palette[Index].XPos+dtWindows^.Window[dtWindows^.NumWindows].XPos+1;
     yy := dtForeGround^.Palette[Index].YPos+dtWindows^.Window[dtWindows^.NumWindows].YPos+1;
          IF y=yy THEN wAdd := 0
     ELSE IF y=yy+1 THEN wAdd := 4
     ELSE IF y=yy+2 THEN wAdd := 8
     ELSE IF y=yy+3 THEN wAdd := 12
     ELSE Exit;
     IF x IN [xx..xx+2] THEN
     BEGIN
       INC(wAdd,0);
       IF (dtForeGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtForeGround^.Palette[Index].Current := wAdd;
         winDrawForePal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+3..xx+5] THEN
     BEGIN
       INC(wAdd,1);
       IF (dtForeGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtForeGround^.Palette[Index].Current := wAdd;
         winDrawForePal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+6..xx+8] THEN
     BEGIN
       INC(wAdd,2);
       IF (dtForeGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtForeGround^.Palette[Index].Current := wAdd;
         winDrawForePal(Index,True);
       END
       ELSE TimeSlice;
     END
     ELSE IF x IN [xx+9..xx+11] THEN
     BEGIN
       INC(wAdd,3);
       IF (dtForeGround^.Palette[Index].Current<>wAdd) THEN
       BEGIN
         dtForeGround^.Palette[Index].Current := wAdd;
         winDrawForePal(Index,True);
       END
       ELSE TimeSlice;
     END;
END;


END.