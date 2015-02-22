{$I DEFINES.INC}
UNIT MsgParam;


INTERFACE


FUNCTION Write_Alias: boolean;
FUNCTION Write_Sig: boolean;
FUNCTION Write_Private: boolean;


IMPLEMENTATION


USES Screens,KeyInput;


FUNCTION Write_Alias: boolean;
BEGIN
     System_Prompt('',71);
     Write_Alias := Get_Yes_No;
END;


FUNCTION Write_Sig: boolean;
BEGIN
     System_Prompt('',162);
     Write_Sig := Get_Yes_No;
END;


FUNCTION Write_Private: boolean;
BEGIN
     System_Prompt('',72);
     Write_Private := Get_Yes_No;
END;


END.