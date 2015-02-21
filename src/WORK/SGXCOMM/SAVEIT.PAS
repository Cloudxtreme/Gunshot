{$I DEFINES.INC}
UNIT SaveIt;


INTERFACE


VAR  SSavedMsgGroup  : Word;
     SSavedMsgArea   : Word;
     SSavedFileGroup : Word;
     SSavedFileArea  : Word;
     SSavedMenu      : String[8];


PROCEDURE SaveCurrentMsgGroupArea;
PROCEDURE LoadCurrentMsgGroupArea;
PROCEDURE SaveCurrentFileGroupArea;
PROCEDURE LoadCurrentFileGroupArea;
PROCEDURE SaveCurrentMenu;


IMPLEMENTATION


USES Globals,FilHeadr,MsgHeadr;


PROCEDURE SaveCurrentMsgGroupArea;
BEGIN
     SSavedMsgGroup := CurrentMessageSub;
     SSavedMsgArea  := CurrentMessageArea;
END;


PROCEDURE LoadCurrentMsgGroupArea;
BEGIN
     CurrentMessageSub  := SSavedMsgGroup;
     CurrentMessageArea := SSavedMsgArea;
     header2(CurrentMessageSub,CurrentMessageArea,True);
END;


PROCEDURE SaveCurrentFileGroupArea;
BEGIN
     SSavedFileGroup := CurrentFileSub;
     SSavedFileArea  := CurrentFileArea;
END;


PROCEDURE LoadCurrentFileGroupArea;
BEGIN
     CurrentFileSub  := SSavedFileGroup;
     CurrentFileArea := SSavedFileArea;
     header(CurrentFileSub,CurrentFileArea,True);
END;


PROCEDURE SaveCurrentMenu;
BEGIN
     SSavedMenu := loaded_menu;
END;


END.