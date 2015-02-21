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


USES Globals;


PROCEDURE Save_Screen;
BEGIN
     Move(MEM[SegB800:0],SaveScreen1,4000);
END;


PROCEDURE Restore_Screen;
BEGIN
     Move(SaveScreen1,MEM[SegB800:0],4000);
END;


PROCEDURE Save_Screen2;
BEGIN
     Move(MEM[SegB800:0],SaveScreen2^,4000);
END;


PROCEDURE Restore_Screen2;
BEGIN
     Move(SaveScreen2^,MEM[SegB800:0],4000);
END;


PROCEDURE Save_Screen3;
BEGIN
     Move(MEM[SegB800:0],SaveScreen3^,4000);
END;


PROCEDURE Restore_Screen3;
BEGIN
     Move(SaveScreen3^,MEM[SegB800:0],4000);
END;


END.