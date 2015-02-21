{$I DEFINES.INC}
UNIT CanMenus;


INTERFACE


PROCEDURE display_menu;


IMPLEMENTATION


USES Globals,MsgHeadr,FilHeadr,Screens;


PROCEDURE display_menu;
BEGIN
     CASE menu^[1].Tags[2] OF
     2:   header(CurrentFileSub,CurrentFileArea,True);
     3:   header2(CurrentMessageSub,CurrentMessageArea,True);
     END;
     DisplayGraphicFile(Loaded_Menu,False,False,True);
END;


END.
