{$I DEFINES.INC}
UNIT Toggle;


INTERFACE


PROCEDURE StartToggle(Scrap: Longint);
PROCEDURE RedrawToggle;
PROCEDURE EndToggle;
PROCEDURE DoToggle;


IMPLEMENTATION


USES Globals,ANSIMisc;


PROCEDURE StartToggle (Scrap: Longint);
BEGIN
     ToggleChar[1] := '|';
     ToggleChar[2] := '/';
     ToggleChar[3] := '-';
     ToggleChar[4] := '\';
     ToggleCount := 0;
END;


PROCEDURE EndToggle;
BEGIN
     WRITECHAR(#08);
     WRITECHAR(' ');
     WRITECHAR(#08);
END;


PROCEDURE DoToggle;
BEGIN
     INC(ToggleCount);
     IF ToggleCount=5 THEN ToggleCount := 1;
     WRITECHAR(#08);
     WRITECHAR(ToggleChar[ToggleCount]);
END;


PROCEDURE RedrawToggle;
BEGIN
     WRITECHAR(ToggleChar[ToggleCount]);
END;


END.