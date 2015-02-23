{$I DEFINES.INC}
UNIT TermHelp;


INTERFACE


PROCEDURE DoTerminalHelp;


IMPLEMENTATION


USES DrawScrn,Crt,FastW1,Globals,BsKeys,BsVideo;


PROCEDURE DoTerminalHelp;
TYPE ScrnType    = Array[1..8000] Of Char;
VAR  SavedScreen : ^ScrnType;
     C           : Char;
BEGIN
     New(SavedScreen);
     Move(MEM[SegB800:0],SavedScreen^,ScreenBytes);
     _HideCursor;
     DrawWindow(18,8,58,17,'TERMINAL HELP',True);
     InvertedBox(20,9,56,16);
     FastWrite('PgUp ........ Send Files         ',10,22,ShotgunColours.GSMailWindowText);
     FastWrite('PgDn ........ Receive Files      ',11,22,ShotgunColours.GSMailWindowText);
     FastWrite('ALT-C ....... Clear The Screen   ',12,22,ShotgunColours.GSMailWindowText);
     FastWrite('ALT-H ....... Hangup The Modem   ',13,22,ShotgunColours.GSMailWindowText);
     FastWrite('ALT-X ....... Quit The Terminal  ',14,22,ShotgunColours.GSMailWindowText);
     FastWrite('F2 .......... DOS Shell          ',15,22,ShotgunColours.GSMailWindowText);
     C := ReadKey;
     IF Ord(C)=0 THEN C := ReadKey;
     Move(SavedScreen^,MEM[SegB800:0],ScreenBytes);
     Dispose(SavedScreen);
     _ShowCursor;
END;


END.
