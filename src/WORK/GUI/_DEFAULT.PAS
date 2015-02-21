{$I DEFINES.INC}
UNIT _Default;


INTERFACE


PROCEDURE Tool4; {LINES}
PROCEDURE Tool5; {BOXES}
PROCEDURE Tool6; {CIRCLES}
PROCEDURE Tool7; {FLOOD FILL}
PROCEDURE Tool8; {NORMAL BUTTONS}
PROCEDURE Tool9; {PANEL BUTTONS}
PROCEDURE Tool10; {POP BUTTONS}
PROCEDURE Tool11; {WINDOWS}
PROCEDURE Tool12; {ICONS}
PROCEDURE Tool13; {TEXT}
PROCEDURE Tool14; {POLYLINES}
PROCEDURE Tool15; {POLYGONS}
PROCEDURE Tool16; {BEZIER CURVES}
PROCEDURE Tool17; {BEZIER OBJECTS}
PROCEDURE Tool18; {PROGRESS INDICATOR}
PROCEDURE Tool19; {PROMPT BOXES}
PROCEDURE Tool20; {DIMENSION FRAMES}
PROCEDURE Tool21; {PICK LISTS}
PROCEDURE Tool22; {GRAPHIC IMAGES}
PROCEDURE Tool23; {STRING PADS}
PROCEDURE Tool24; {CUSTOM CONTROLS}
PROCEDURE Tool25; {ANIMATED ICONS}
PROCEDURE Tool26; {PLAIN ARC}
PROCEDURE Tool27; {CLICKABLE REGIONS}
PROCEDURE Tool28; {TEXT BOX}
PROCEDURE Tool34; {TRASH CAN}


IMPLEMENTATION


USES Globals,Gr2_Bp,ObjSet,SetWork;


PROCEDURE Tool4; {LINES}
BEGIN
     HoldRaw.number   := 4;
     HoldRaw.colour1  := 15;  {Colour}
     HoldRaw.colour2  := 1;   {Line Thickness}
     GrDisplayMouse(GrHide);
     ScreenSetup4;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool5; {BOXES}
BEGIN
     HoldRaw.number   := 5;
     HoldRaw.colour1  := 15;  {Outline Colour}
     HoldRaw.colour2  := 0;   {Fill Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup5;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool6; {CIRCLES}
BEGIN
     HoldRaw.number   := 6;
     HoldRaw.colour1  := 15;  {Outline Colour}
     HoldRaw.colour2  := 0;   {Fill Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup6;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool7; {FLOOD FILL}
BEGIN
     HoldRaw.number   := 7;
     HoldRaw.colour1  := 0;   {Fill Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup7;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool8; {NORMAL BUTTONS}
BEGIN
     HoldRaw.number   := 8;
     HoldRaw.colour1  := 7;  {Face Colour}
     HoldRaw.colour2  := 15; {Highlight Colour}
     HoldRaw.colour3  := 8;  {Shadow Colour}
     HoldRaw.Return   := 'A';
     GrDisplayMouse(GrHide);
     ScreenSetup8;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool9; {PANEL BUTTONS}
BEGIN
     HoldRaw.number   := 9;
     HoldRaw.colour1  := 7;  {Face Colour}
     HoldRaw.colour2  := 15; {Highlight Colour}
     HoldRaw.colour3  := 8;  {Shadow Colour}
     HoldRaw.Return   := 'A';
     GrDisplayMouse(GrHide);
     ScreenSetup9;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool10; {POP BUTTONS}
BEGIN
     HoldRaw.number   := 10;
     HoldRaw.Return   := 'A';
     GrDisplayMouse(GrHide);
     ScreenSetup10;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool11; {WINDOWS}
BEGIN
     HoldRaw.number   := 11;
     HoldRaw.Style    := 1;  {Classic Relief}
     HoldRaw.Colour1  := 7;  {Window Background}
     HoldRaw.Colour2  := 7;  {Window Border}
     HoldRaw.Colour3  := 15; {Window Highlight}
     HoldRaw.Colour4  := 8;  {Window Shadow}
     HoldRaw.Colour5  := 57; {Header Background}
     HoldRaw.Colour6  := 60; {Header highlight}
     HoldRaw.Colour7  := 54; {Header Shadow}
     HoldRaw.Colour8  := 15; {Header Text Colour}
     HoldRaw.Colour9  := 0;  {Minimizable}
     HoldRaw.Colour10 := 0;  {Translucent}
     HoldRaw.Text     := 'Untitled Window';
     GetWindowDefaults;
     GrDisplayMouse(GrHide);
     ScreenSetup11;
     GrDisplayMouse(GrShow);
END;

PROCEDURE Tool12; {ICONS}
BEGIN
     HoldRaw.number   := 12;
     HoldRaw.Style    := 30; {Icon Size}
     HoldRaw.Colour1  := 1;  {Icon Number}
     HoldRaw.Colour3  := 0;  {no effect}
     HoldRaw.ObjFile  := 'ICONLIB1.30';
     GrDisplayMouse(GrHide);
     ScreenSetup12;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool13; {TEXT}
BEGIN
     HoldRaw.number   := 13;
     HoldRaw.Colour1  := 15; {Text Colour}
     HoldRaw.Colour2  := 0;  {Text Shadow}
     HoldRaw.Colour3  := 0;  {Is There Shadow}
     HoldRaw.Colour4  := 0;  {Italics}
     HoldRaw.Colour5  := 0;  {Underlined}
     HoldRaw.Colour6  := 0;  {Bold}
     HoldRaw.Colour7  := 1;  {Default System Font}
     HoldRaw.ObjFile  := '';
     HoldRaw.Text     := '';
     GrDisplayMouse(GrHide);
     ScreenSetup13;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool14; {POLYLINES}
BEGIN
     HoldRaw.number   := 14;
     HoldRaw.colour1  := 15;  {Colour}
     HoldRaw.colour2  := 1;   {Line Thickness}
     GrDisplayMouse(GrHide);
     ScreenSetup14;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool15; {POLYGONS}
BEGIN
     HoldRaw.number   := 15;
     HoldRaw.colour1  := 15;  {Line Colour}
     HoldRaw.colour2  := 0;   {Fill Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup15;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool16; {BEZIER CURVES}
BEGIN
     HoldRaw.number   := 16;
     HoldRaw.colour1  := 15;  {Colour}
     HoldRaw.colour2  := 1;   {Line Thickness}
     GrDisplayMouse(GrHide);
     ScreenSetup16;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool17; {BEZIER OBJECTS}
BEGIN
     HoldRaw.number   := 17;
     HoldRaw.colour1  := 15;  {Line Colour}
     HoldRaw.colour2  := 0;   {Fill Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup17;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool18; {PROGRESS INDICATOR}
BEGIN
     HoldRaw.number   := 18;
     HoldRaw.colour1  := 4;   {Colour}
     GrDisplayMouse(GrHide);
     ScreenSetup18;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool19; {PROMPT BOXES}
BEGIN
     HoldRaw.number   := 19;
     HoldRaw.colour1  := 1;   {Back Colour}
     HoldRaw.colour2  := 15;  {Normal Text}
     HoldRaw.colour3  := 7;   {Disabled Text}
     HoldRaw.colour4  := 1;   {Prompt ### - Real Name}
     GrDisplayMouse(GrHide);
     ScreenSetup19;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool20; {DIMENSION FRAMES}
BEGIN
     HoldRaw.number   := 20;
     HoldRaw.colour1  := 8;   {Upper Left}
     HoldRaw.colour2  := 15;  {Lower Right}
     GrDisplayMouse(GrHide);
     ScreenSetup20;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool21; {PICK LISTS}
BEGIN
     HoldRaw.number   := 21;
     GrDisplayMouse(GrHide);
     ScreenSetup21;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool22; {GRAPHIC IMAGES}
BEGIN
     HoldRaw.ObjFile  := '';
     HoldRaw.Colour1  := 0; {grayscale}
     HoldRaw.Colour2  := 1; {dither}
     HoldRaw.Colour3  := 0; {no effect}
     HoldRaw.number   := 22;
     GrDisplayMouse(GrHide);
     ScreenSetup22;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool23; {STRING PADS}
BEGIN
     HoldRaw.Colour1  := 7;
     HoldRaw.number   := 23;
     GrDisplayMouse(GrHide);
     ScreenSetup23;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool24; {CUSTOM CONTROLS}
BEGIN
     HoldRaw.number   := 24;
     HoldRaw.Style    := 30; {Icon Size}
     HoldRaw.Colour1  := 90; {Icon Number}
     HoldRaw.Colour2  := 90; {Icon Number}
     HoldRaw.Colour3  := 0;  {no effect}
     HoldRaw.ObjFile  := 'ICONLIB1.30';
     GrDisplayMouse(GrHide);
     ScreenSetup24;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool25; {ANIMATED ICONS}
BEGIN
     HoldRaw.number   := 25;
     HoldRaw.Style    := 30; {Icon Size}
     HoldRaw.Colour1  := 100; {Icon Number}
     HoldRaw.Colour2  := 100; {Icon Number}
     HoldRaw.Colour3  := 100; {Icon Number}
     HoldRaw.Colour4  := 100; {Icon Number}
     HoldRaw.Colour5  := 100; {Icon Number}
     HoldRaw.Colour6  := 100; {Icon Number}
     HoldRaw.Colour7  := 100; {Icon Number}
     HoldRaw.Colour8  := 100; {Icon Number}
     HoldRaw.Colour9  := 0;   {no effect}
     HoldRaw.ObjFile  := 'ICONLIB1.30';
     GrDisplayMouse(GrHide);
     ScreenSetup25;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool26; {PLAIN ARC}
BEGIN
     HoldRaw.number   := 26;
     HoldRaw.colour1  := 15;  {Colour}
     HoldRaw.colour2  := 1;   {Line Thickness}
     GrDisplayMouse(GrHide);
     ScreenSetup26;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool27; {CLICKABLE REGIONS}
BEGIN
     HoldRaw.number   := 27;
     HoldRaw.Return   := 'A';
     GrDisplayMouse(GrHide);
     ScreenSetup27;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool28; {TEXT BOX}
BEGIN
     HoldRaw.number   := 28;
     HoldRaw.Text     := '';
     GrDisplayMouse(GrHide);
     ScreenSetup28;
     GrDisplayMouse(GrShow);
END;


PROCEDURE Tool34; {TRASH CAN}
BEGIN
     GrDisplayMouse(GrHide);
     SetupWork;
     MouseOn := True;
     GrDisplayMouse(GrShow);
END;


END.
