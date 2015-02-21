{$I DEFINES.INC}
UNIT _Save;


INTERFACE


PROCEDURE save_mouse;
PROCEDURE load_mouse;
PROCEDURE SaveCurrentWindow  (FName: String);
PROCEDURE LoadCurrentWindow  (FName: String);
PROCEDURE DrawShellWindow    (InString: String);


IMPLEMENTATION


USES Gx2_Bp,Gr2_Bp,BsGraph,Globals,Crt,_Mouse,_Text;


PROCEDURE save_mouse;
BEGIN
     SavedMouseX := GetMouseX;
     SavedMouseY := GetMouseY;
     GrDisplayMouse(GrHide);
     GrTrackMouse(GrNoTrack);
     GrStopMouse;
     GotoXY(1,1);
END;


PROCEDURE load_mouse;
BEGIN
     GrSetMouseMode(gxGraphics);
     GrInitMouse;
     GrSetMouseMode(gxGraphics);
     GrTrackMouse(GrTrack);
     GrSetMouseBounds(0,0,GraphMaxX-5,GraphMaxY-5);
     SetPixeltoMickey(3,5);
     ChangeMouse(DefaultMouse);
     GrSetMousePos(SavedMouseX,SavedMouseY);
     GrDisplayMouse(GrShow);
END;


PROCEDURE SaveCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
BEGIN
     ASSIGN(FPickInfo,SESSION_Directory+'\'+FName+'.INF');
     REWRITE(FPickInfo);
     WRITE(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
     PickInfo.Active := False;
END;


PROCEDURE LoadCurrentWindow(FName: String);
VAR  FPickInfo : File Of Pick_Info;
BEGIN
     ASSIGN(FPickInfo,SESSION_Directory+'\'+FName+'.INF');
     RESET(FPickInfo);
     READ(FPickInfo,PickInfo);
     CLOSE(FPickInfo);
END;


PROCEDURE DrawShellWindow(InString: String);
BEGIN
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(15,YWindow-15,260,YWindow+30,GrFill);
     GrSetColor(0);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(10,YWindow-20,255,YWindow+25,GrFill+GrOutline);
     OutTextXY(30,YWindow-12,0,255,1,InString);
     OutTextXY(30,YWindow+3,0,255,1,'Please be patient...');
END;


END.