{$I DEFINES.INC}
UNIT Cutouts;


INTERFACE


PROCEDURE save_screen;
PROCEDURE load_screen;
PROCEDURE Get(x1,y1,x2,y2: Word);
PROCEDURE Put(x,y: Word; Kill: Boolean);


IMPLEMENTATION


USES _Virtual,Globals,BsGraph,ErrorOut,Gx2_BpVC;


{==========================================================================}
{                                                                          }
{         SAVES THE SCREEN TO DISK                                         }
{                                                                          }
{==========================================================================}
PROCEDURE save_screen;
VAR  Error  : Integer;
LABEL         Continue;
BEGIN
     IF CreateVirtual(SvScreen,GraphMaxX+1,GraphMaxY+1,TheDisplay) THEN GOTO Continue;
     DropError(5);
     Continue:
     Error := gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen,0,0);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE load_screen;
BEGIN
     gxVirtualDisplay(SvScreen,0,0,0,0,GraphMaxX,GraphMaxY,0);
     gxDestroyVirtual(SvScreen);
END;
{==========================================================================}
{                                                                          }
{         GETS A SCREEN CUTOUT                                             }
{                                                                          }
{==========================================================================}
PROCEDURE Get(x1,y1,x2,y2: Word);
LABEL Continue;
BEGIN
     IF CreateVirtual(GetPut,x2-x1+1,y2-y1+1,TheDisplay) THEN GOTO Continue;
     DropError(6);
     Continue:
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut,0,0);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE Put(x,y: Word; Kill: Boolean);
BEGIN
     gxVirtualDisplay(GetPut,0,0,x,y,639,YWindow,0);
     IF Kill THEN gxDestroyVirtual(GetPut);
END;


END.