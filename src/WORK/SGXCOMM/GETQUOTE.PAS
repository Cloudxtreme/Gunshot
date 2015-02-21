{$I DEFINES.INC}
UNIT GetQuote;


INTERFACE


FUNCTION select_quote: Byte;


IMPLEMENTATION


USES Screens,Globals,KeyInput;


FUNCTION select_quote: Byte;
VAR  c    : char;
     Temp : Byte;
BEGIN
     Temp := 0;
     DisplayGraphicFile('QUOTE',False,True,True);
     c := Get_Menu_Selection('123Q','1');
     CASE UpCase(c) OF
     '1': Temp := 1;
     '2': Temp := 2;
     '3': Temp := 3;
     'Q': Temp := 0;
     END;
     Select_Quote := Temp;
END;


END.