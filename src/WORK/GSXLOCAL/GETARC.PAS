{$I DEFINES.INC}
UNIT GetArc;


INTERFACE


FUNCTION select_archiver: Byte;


IMPLEMENTATION


USES Screens,Globals,KeyInput;


FUNCTION select_archiver: Byte;
VAR  c    : char;
     Temp : Byte;
BEGIN
     Temp := 0;
     DisplayGraphicFile('ARCHIVER',False,True,True);
     c := Get_Menu_Selection('123456789Q','1');
     CASE UpCase(c) OF
     '1': Temp := 1;
     '2': Temp := 2;
     '3': Temp := 3;
     '4': Temp := 4;
     '5': Temp := 5;
     '6': Temp := 6;
     '7': Temp := 7;
     '8': Temp := 8;
     '9': Temp := 9;
     'Q': Temp := 0;
     END;
     ASSIGN(FArcUtils,DATA_Directory+'\ARCUTILS.DAT');
     RESET(FArcUtils);
     IF (Temp>FileSize(FArcUtils)) THEN Temp := 0;
     CLOSE(FArcUtils);
     Select_Archiver := Temp;
END;


END.
