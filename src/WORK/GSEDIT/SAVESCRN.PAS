{$I DEFINES.INC}
UNIT SaveScrn;


INTERFACE


PROCEDURE Save_Screen;
PROCEDURE Restore_Screen;
PROCEDURE Save_Screen2;
PROCEDURE Restore_Screen2;
PROCEDURE Save_Screen3;
PROCEDURE Restore_Screen3;


IMPLEMENTATION


USES {$IFNDEF MSDOS}VideoUtils,{$ENDIF}Globals;


{$IFNDEF MSDOS}
var
  SavedScreen1, SavedScreen2, SavedScreen3: TScreenBuffer;
{$ENDIF}


PROCEDURE Save_Screen;
BEGIN
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SaveScreen1,4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenSave(SavedScreen1);
{$ENDIF}
END;


PROCEDURE Restore_Screen;
BEGIN
{$IFDEF MSDOS}
     Move(SaveScreen1,MEM[SegB800:0],4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenRestore(SavedScreen1);
{$ENDIF}
END;


PROCEDURE Save_Screen2;
BEGIN
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SaveScreen2^,4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenSave(SavedScreen2);
{$ENDIF}
END;


PROCEDURE Restore_Screen2;
BEGIN
{$IFDEF MSDOS}
     Move(SaveScreen2^,MEM[SegB800:0],4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenRestore(SavedScreen2);
{$ENDIF}
END;


PROCEDURE Save_Screen3;
BEGIN
{$IFDEF MSDOS}
     Move(MEM[SegB800:0],SaveScreen3^,4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenSave(SavedScreen3);
{$ENDIF}
END;


PROCEDURE Restore_Screen3;
BEGIN
{$IFDEF MSDOS}
     Move(SaveScreen3^,MEM[SegB800:0],4000);
{$ENDIF}
{$IFNDEF MSDOS}
     VideoUtils.ScreenRestore(SavedScreen3);
{$ENDIF}
END;


END.