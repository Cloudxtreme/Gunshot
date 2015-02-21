{$I DEFINES.INC}
UNIT BsLabel;


INTERFACE


PROCEDURE winLabel(InString: String; x,y: Word; Highlight: Boolean);
PROCEDURE winLabelFR(InString: String; x,y: Word; Highlight: Boolean);
PROCEDURE winText(InString: String; x,y,TheAttr: Word);


IMPLEMENTATION


USES BsGlobal,BsMouse,BsVideo;


PROCEDURE winLabel(InString: String; x,y: Word; Highlight: Boolean);
BEGIN
     INC(x,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     _HideMouse;
     IF Highlight THEN FastWrite(InString,y,x,dtColours^.WindowHighlight)
                  ELSE FastWrite(InString,y,x,dtColours^.WindowText);
     _ShowMouse;
END;


PROCEDURE winLabelFR(InString: String; x,y: Word; Highlight: Boolean);
BEGIN
     INC(x,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     _HideMouse;
     IF Highlight THEN FastWrite(InString,y,x-LENGTH(InString)+1,dtColours^.WindowHighlight)
                  ELSE FastWrite(InString,y,x-LENGTH(InString)+1,dtColours^.WindowText);
     _ShowMouse;
END;


PROCEDURE winText(InString: String; x,y,TheAttr: Word);
BEGIN
     _HideMouse;
     INC(x,dtWindows^.Window[dtWindows^.NumWindows].XPos);
     INC(y,dtWindows^.Window[dtWindows^.NumWindows].YPos);
     FastWrite(InString,y,x,TheAttr);
     _ShowMouse;
END;


END.