{$I DEFINES.INC}
UNIT ToggMsg;


INTERFACE


PROCEDURE ToggleMsgArea(SearchFile: Word; OnOff: Boolean);


IMPLEMENTATION


USES TagArea,Globals,BsString;


PROCEDURE ToggleMsgArea(SearchFile: Word; OnOff: Boolean);
VAR  FFile  : File;
     Tagged : Boolean;
BEGIN
     IF SearchFile<>0 THEN
     BEGIN
          IsMsgTagged(SearchFile);
          Tagged := OnOff;
          ASSIGN(FFile,Shotgun_Directory+'\MSGTAGS\'+_String(UserRecord.User_Number)+'.BBS');
          RESET(FFile,1);
          SEEK(FFile,SearchFile-1);
          BLOCKWRITE(FFile,Tagged,1);
          CLOSE(FFile);
     END;
END;


END.
