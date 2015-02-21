{$I DEFINES.INC}
UNIT SaveScrn;


INTERFACE


PROCEDURE Save_Screen2;
PROCEDURE Restore_Screen2;


IMPLEMENTATION


USES Globals,Crt;


PROCEDURE Save_Screen2;
BEGIN
     SavedCursorX := WhereX;
     SavedCursorY := WhereY;
     Move(MEM[SegB800:0],SAVESCRN_Scr2[1],4000);
END;


PROCEDURE Restore_Screen2;
BEGIN
     Move(SAVESCRN_Scr2[1],MEM[SegB800:0],4000);
     GotoXY(SavedCursorX,SavedCursorY);
END;


END.