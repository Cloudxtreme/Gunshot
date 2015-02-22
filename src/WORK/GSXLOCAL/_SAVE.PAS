{$I DEFINES.INC}
UNIT _Save;


INTERFACE


PROCEDURE save_mouse;
PROCEDURE load_mouse;
PROCEDURE SaveCurrentWindow  (FName: String);
PROCEDURE LoadCurrentWindow  (FName: String);


IMPLEMENTATION


USES Globals,Gr2_Bp,Gx2_Bp,BsGraph,Crt,_Mouse,BsFile;


PROCEDURE SaveCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
     FFile     : File;
BEGIN
     IF PickInfo.UsingDisk THEN
     BEGIN
          _EraseFile(NODE_Directory+'\'+FName+'.LST');
          ASSIGN(FPickList,NODE_Directory+'\PICK.LST');
          RENAME(FPickList,NODE_Directory+'\'+FName+'.LST');
     END
     ELSE
     BEGIN
          ASSIGN(FFile,NODE_Directory+'\'+FName+'.LST');
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,HugePick^,SizeOf(HugePick^));
          CLOSE(FFile);
     END;
     ASSIGN(FPickInfo,NODE_Directory+'\'+FName+'.INF');
     REWRITE(FPickInfo);
     WRITE(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
     PickInfo.Active := False;
END;


PROCEDURE LoadCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
     FFile     : File;
BEGIN
     ASSIGN(FPickInfo,NODE_Directory+'\'+FName+'.INF');
     RESET(FPickInfo);
     READ(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
     ERASE(FPickInfo);
     _EraseFile(NODE_Directory+'\PICK.LST');
     IF PickInfo.UsingDisk THEN
     BEGIN
          ASSIGN(FPickList,NODE_Directory+'\'+FName+'.LST');
          RENAME(FPickList,NODE_Directory+'\PICK.LST');
     END
     ELSE
     BEGIN
          ASSIGN(FFile,NODE_Directory+'\'+FName+'.LST');
          RESET(FFile,1);
          BLOCKREAD(FFile,HugePick^,SizeOf(HugePick^));
          CLOSE(FFile);
          ERASE(FFile);
     END;
END;


PROCEDURE save_mouse;
BEGIN
     SavedMouseX := MousePosX;
     SavedMouseY := MousePosY;
     HideTheMouse;
     KillTheMouse;
     GotoXY(1,1);
END;


PROCEDURE load_mouse;
BEGIN
     InitTheMouse;
     LastMouse := 1;
     ChangeMouse(DefaultMouse);
     SetMousePos(SavedMouseX,SavedMouseY);
     ShowTheMouse;
END;


END.