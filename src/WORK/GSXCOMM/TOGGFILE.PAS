{$I DEFINES.INC}
UNIT ToggFile;


INTERFACE


PROCEDURE ToggleFileArea(SearchFile: Word; OnOff: Boolean);


IMPLEMENTATION


USES TagArea,Globals,BsString;


PROCEDURE ToggleFileArea(SearchFile: Word; OnOff: Boolean);
VAR  FFile  : File;
     Tagged : Boolean;
BEGIN
     IF SearchFile<>0 THEN
     BEGIN
          IsFileTagged(SearchFile);
          Tagged := OnOff;
          ASSIGN(FFile,Gunshot_Directory+'\FILETAGS\'+_String(UserRecord.User_Number)+'.BBS');
          RESET(FFile,1);
          SEEK(FFile,SearchFile-1);
          BLOCKWRITE(FFile,Tagged,1);
          CLOSE(FFile);
     END;
END;


END.