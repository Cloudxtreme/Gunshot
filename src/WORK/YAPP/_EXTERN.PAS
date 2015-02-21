{$I DEFINES.INC}
UNIT _Extern;


INTERFACE


PROCEDURE PlayFLIFile  (FileName: String);
PROCEDURE PlayVocFile  (FName: String);


IMPLEMENTATION


USES _Save,_Virtual,Gx2_Bp,Gx2_BpVC,Gr2_Bp,Crt,
     Globals,BsGraph,_Mouse,Dos,BsFile;


PROCEDURE PlayFLIFile(FileName: String);
VAR  C : Char;
BEGIN
     Save_Mouse;
     CreateVirtual(SvScreen,GraphMaxX+1,GraphMaxY+1,TheDisplay);
     gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen,0,0);
     Fade_Out;
     gxClearDisplay(0,0);
     SwapVectors;
     Exec('PLAYFLI.EXE',FileName+' $$BB$$SS$$ 0');
     SwapVectors;
     GxSetDisplay(TheDisplay);
     GxSetMode(GxGraphics);
     gxSetConvertPalette(GxPAL5,@P256);
     GxSetDisplayPalette(@P256);
     Fade_Off;
     gxVirtualDisplay(SvScreen,0,0,0,0,GraphMaxX,GraphMaxY,0);
     Fade_In;
     gxDestroyVirtual(SvScreen);
     load_mouse;
     REPEAT IF KeyPressed THEN c := ReadKey; UNTIL NOT(KeyPressed);
END;


PROCEDURE PlayVocFile(FName: String);
BEGIN
     IF _FileExists('PLAYVOC.EXE') THEN
     BEGIN
          SavedMouseX := GetMouseX;
          SavedMouseY := GetMouseY;
          GrDisplayMouse(GrHide);
          GrTrackMouse(GrNoTrack);
          GrStopMouse;
          SwapVectors;
          Exec('PLAYVOC.EXE',FName+' $$BB$$SS$$');
          SwapVectors;
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
END;


END.
