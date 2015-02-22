{$I DEFINES.INC}
UNIT BsFrames;


INTERFACE


PROCEDURE winDisabledFrame(x1,y1,x2,y2: Word);
PROCEDURE winDropShadow(x1,y1,x2,y2 : Word);
PROCEDURE winInvertedFrame(x1,y1,x2,y2: Word);
PROCEDURE winRaisedFrame(x1,y1,x2,y2: Word);
PROCEDURE winWindowFrame(x1,y1,x2,y2 : Word);


IMPLEMENTATION


USES BsGlobal,BsMouse,BsString,BsVideo;


PROCEDURE winDisabledFrame(x1,y1,x2,y2: Word);
VAR  Loop    : Word;
     TheAttr : Word;
BEGIN
     _HideMouse;
     INC(x1,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(x2,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y1,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     INC(y2,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     TheAttr := dtColours^.FrameLow;
     FastWrite(_Replicate(' ',x2-x1+1),y1,x1,TheAttr);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          FastWrite(' ',Loop,x1,TheAttr);
          FastWrite(' ',Loop,x2,TheAttr);
     END;
     FastWrite(_Replicate(' ',x2-x1+1),y2,x1,TheAttr);
     _ShowMouse;
END;


PROCEDURE winDropShadow(x1,y1,x2,y2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((y2*160)+(x1*2))+1;
     FOR Loop := x1 to x2 DO
     BEGIN
{$IFDEF MSDOS}     
          Mem[SegB800:x] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          WriteLn('REEPORT BSFRAMES winDropShadow'); Halt;
{$ENDIF}
          INC(x,2);
     END;
     y := ((y1*160)+((x2)*2))+1;
     FOR Loop := y1 to y2 DO
     BEGIN
{$IFDEF MSDOS}
          Mem[SegB800:y] := 8;
{$ENDIF}
{$IFNDEF MSDOS}
          WriteLn('REEPORT BSFRAMES winDropShadow'); Halt;
{$ENDIF}
          INC(y,160);
     END;
END;


PROCEDURE winInvertedFrame(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     _HideMouse;
     INC(x1,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(x2,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y1,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     INC(y2,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     Attr1 := dtColours^.FrameLow;
     Attr2 := dtColours^.FrameHigh;
     FastWrite('Ú',y1,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y1,x1+1,Attr1);
     FastWrite('¿',y1,x2,Attr2);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          FastWrite('³',Loop,x1,Attr1);
          FastWrite('³',Loop,x2,Attr2);
     END;
     FastWrite('À',y2,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y2,x1+1,Attr2);
     FastWrite('Ù',y2,x2,Attr2);
     _ShowMouse;
END;


PROCEDURE winRaisedFrame(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     _HideMouse;
     INC(x1,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(x2,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y1,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     INC(y2,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     Attr1 := dtColours^.FrameHigh;
     Attr2 := dtColours^.FrameLow;
     FastWrite('Ú',y1,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y1,x1+1,Attr1);
     FastWrite('¿',y1,x2,Attr2);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          FastWrite('³',Loop,x1,Attr1);
          FastWrite('³',Loop,x2,Attr2);
     END;
     FastWrite('À',y2,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y2,x1+1,Attr2);
     FastWrite('Ù',y2,x2,Attr2);
     _ShowMouse;
END;


PROCEDURE winWindowFrame(x1,y1,x2,y2 : Word);
VAR  Loop : Word;
     Temp : String;
BEGIN
     CASE dtApp^.AppStyle OF
     1:   BEGIN {Front Door}
            FOR Loop := y1 TO y2 DO
            BEGIN
                   IF Loop=y1 THEN Temp := 'É'+_Replicate('Í',x2-x1-1)+'»'
              ELSE IF Loop=y2 THEN Temp := 'È'+_Replicate('Í',x2-x1-1)+'¼'
              ELSE Temp := 'º'+_Replicate(' ',x2-x1-1)+'º';
              FastWrite(Temp,Loop,x1,dtColours^.WindowBorderH);
            END;
          END;
     2,5: BEGIN {Turbo Vision}
            FOR Loop := y1 TO y2 DO
            BEGIN
                   IF Loop=y1 THEN Temp := 'É'+_Replicate('Í',x2-x1-1)+'»'
              ELSE IF Loop=y2 THEN Temp := 'È'+_Replicate('Í',x2-x1-1)+'¼'
              ELSE Temp := 'º'+_Replicate(' ',x2-x1-1)+'º';
              FastWrite(Temp,Loop,x1,dtColours^.WindowBorderH);
            END;
          END;
     3:   BEGIN {Norton Utilities}
            FOR Loop := y1 TO y2 DO
            BEGIN
                   IF Loop=y1 THEN Temp := 'Ú'+_Replicate('Ä',x2-x1-1)+'¿'
              ELSE IF Loop=y2 THEN Temp := 'À'+_Replicate('Ä',x2-x1-1)+'Ù'
              ELSE Temp := '³'+_Replicate(' ',x2-x1-1)+'³';
              FastWrite(Temp,Loop,x1,dtColours^.DeskTopBorder);
            END;
          END;
     4:   BEGIN {Shotgun Professional}
            FOR Loop := y1 TO y2 DO
            BEGIN
              IF Loop=y1 THEN
              BEGIN
                FastWrite('Ú'+_Replicate('Ä',x2-x1-1),Loop,x1,dtColours^.WindowBorderH);
                FastWrite('¿',Loop,x2,dtColours^.WindowBorderL);
              END
              ELSE IF Loop=y2 THEN
              BEGIN
                FastWrite('À',Loop,x1,dtColours^.WindowBorderH);
                FastWrite(_Replicate('Ä',x2-x1-1)+'Ù',Loop,x1+1,dtColours^.WindowBorderL);
              END
              ELSE
              BEGIN
                FastWrite('³',Loop,x1,dtColours^.WindowBorderH);
                FastWrite(_Replicate(' ',x2-x1-1)+'³',Loop,x1+1,dtColours^.WindowBorderL);
              END;
            END;
          END;
     END;
END;


END.