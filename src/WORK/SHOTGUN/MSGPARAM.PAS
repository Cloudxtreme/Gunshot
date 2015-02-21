{$I DEFINES.INC}
UNIT MsgParam;


INTERFACE


FUNCTION Write_Alias: boolean;
FUNCTION Write_Sig: boolean;
FUNCTION Write_Private: boolean;


IMPLEMENTATION


USES ANSIMisc,KeyInput,Screens;


FUNCTION Write_Alias: boolean;
BEGIN
     SendCrLf(1);
     System_Prompt('',71,false,false);
     Write_Alias := Get_Yes_No;
     SendCrLf(1);
END;


FUNCTION Write_Sig: boolean;
BEGIN
     SendCrLf(1);
     System_Prompt('',162,false,false);
     Write_Sig := Get_Yes_No;
     SendCrLf(1);
END;


FUNCTION Write_Private: boolean;
BEGIN
     SendCrLf(1);
     System_Prompt('',72,false,false);
     Write_Private := Get_Yes_No;
     SendCrLf(1);
END;


END.