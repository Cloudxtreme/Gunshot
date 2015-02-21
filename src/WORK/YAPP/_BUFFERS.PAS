{$I DEFINES.INC}
UNIT _Buffers;


INTERFACE


PROCEDURE LoadUnderGround (x1,y1,x2,y2: Word);
PROCEDURE Get             (x1,y1,x2,y2: Word);
PROCEDURE Get2            (x1,y1,x2,y2: Word);
PROCEDURE Put             (x,y: Word; InWindow,Kill: Boolean);
PROCEDURE Put2            (x,y: Word; Kill: Boolean);
PROCEDURE SaveCutout      (x1,y1,x2,y2: word; IndexNum: Word);
PROCEDURE LoadCutout      (IndexNum: Word);
PROCEDURE KillCutout      (IndexNum: Word);
PROCEDURE SaveUnderGround;
PROCEDURE SaveBackDrop;
PROCEDURE KillBackDrop;
PROCEDURE save_screen;
PROCEDURE load_screen;


IMPLEMENTATION


USES Gx2_Bp,Gx2_BpVC,Gr2_Bp,_Virtual,BsGraph,Globals,_Save;


{==========================================================================}
{                                                                          }
{         GETS A SCREEN CUTOUT                                             }
{                                                                          }
{==========================================================================}
PROCEDURE Get(x1,y1,x2,y2: Word);
BEGIN
     CreateVirtual(GetPut,x2-x1+1,y2-y1+1,TheDisplay);
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut,0,0);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE Put(x,y: Word; InWindow,Kill: Boolean);
BEGIN
     IF InWindow THEN gxVirtualDisplay(GetPut,0,0,x,y,GraphMaxX,YWindow,0)
                 ELSE gxVirtualDisplay(GetPut,0,0,x,y,GraphMaxX,GraphMaxY,0);
     IF Kill THEN gxDestroyVirtual(GetPut);
END;
{==========================================================================}
{                                                                          }
{         SAVES A SCREEN CUTOUT TO XMS/EMS/DISK MEMORY                     }
{                                                                          }
{==========================================================================}
PROCEDURE SaveCutout(x1,y1,x2,y2: word; IndexNum: Word);
BEGIN
     IF SavedCutouts[IndexNum].Active THEN KillCutout(IndexNum);
     CreateVirtual(SavedCutouts[IndexNum].Cutout,x2-x1+1,y2-y1+1,TheDisplay);
     gxDisplayVirtual(x1,y1,x2,y2,0,SavedCutouts[IndexNum].Cutout,0,0);
     SavedCutouts[IndexNum].Coordinates[1] := x1;
     SavedCutouts[IndexNum].Coordinates[2] := y1;
     SavedCutouts[IndexNum].Coordinates[3] := x2;
     SavedCutouts[IndexNum].Coordinates[4] := y2;
     SavedCutouts[IndexNum].Active         := True;
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE LoadCutout(IndexNum: Word);
BEGIN
     IF SavedCutouts[IndexNum].Active THEN
     BEGIN
          gxVirtualDisplay(SavedCutouts[IndexNum].Cutout,0,0,
                           SavedCutouts[IndexNum].Coordinates[1],
                           SavedCutouts[IndexNum].Coordinates[2],
                           SavedCutouts[IndexNum].Coordinates[3],
                           SavedCutouts[IndexNum].Coordinates[4],0);
     END;
END;
{==========================================================================}
{                                                                          }
{         KILLS A SAVED CUTOUT                                             }
{                                                                          }
{==========================================================================}
PROCEDURE KillCutout(IndexNum: Word);
BEGIN
     IF SavedCutouts[IndexNum].Active
        THEN gxDestroyVirtual(SavedCutouts[IndexNum].Cutout);
     SavedCutouts[IndexNum].Active := False;
END;
{==========================================================================}
{                                                                          }
{         SAVES THE SCREEN TO DISK                                         }
{                                                                          }
{==========================================================================}
PROCEDURE save_screen;
BEGIN
     Save_Mouse;
     CreateVirtual(SvScreen,GraphMaxX+1,GraphMaxY+1,TheDisplay);
     gxDisplayVirtual(0,0,GraphMaxX,GraphMaxY,0,SvScreen,0,0);
     Fade_Out;
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
     Fade_In;
     gxSetMode(gxText);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE load_screen;
BEGIN
     gxSetMode(gxGraphics);
     gxSetConvertPalette(GxPAL5,@P256);
     GxSetDisplayPalette(@P256);
     Fade_Out;
     gxVirtualDisplay(SvScreen,0,0,0,0,GraphMaxX,GraphMaxY,0);
     gxDestroyVirtual(SvScreen);
     load_mouse;
     Fade_In;
END;
{==========================================================================}
{                                                                          }
{         GETS A CUTOUT FOR THE CURRENT WINDOW                             }
{                                                                          }
{==========================================================================}
PROCEDURE SaveUnderGround;
BEGIN
     gxDisplayVirtual(0,0,GraphMaxX,YWindow,0,WindowBack,0,0);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE CUTOUT BELOW THE LAST WINDOW                        }
{                                                                          }
{==========================================================================}
PROCEDURE LoadUnderGround(x1,y1,x2,y2: Word);
BEGIN
     gxVirtualDisplay(WindowBack,x1,y1,x1,y1,x2,y2,0);
END;
{==========================================================================}
{                                                                          }
{         GETS A SCREEN CUTOUT                                             }
{                                                                          }
{==========================================================================}
PROCEDURE Get2(x1,y1,x2,y2: Word);
BEGIN
     CreateVirtual(GetPut2,x2-x1+1,y2-y1+1,TheDisplay);
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut2,0,0);
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE Put2(x,y: Word; Kill: Boolean);
BEGIN
     gxVirtualDisplay(GetPut2,0,0,x,y,GraphMaxX,YWindow,0);
     IF Kill THEN gxDestroyVirtual(GetPut2);
END;
{==========================================================================}
{                                                                          }
{         SAVES THE SCREEN BACKGROUND AS CURRENT                           }
{                                                                          }
{==========================================================================}
PROCEDURE SaveBackDrop;
BEGIN
     CreateVirtual(ScreenBack,GraphMaxX+1,YWindow+1,TheDisplay);
     gxDisplayVirtual(0,0,GraphMaxX,YWindow,0,ScreenBack,0,0);
END;
{==========================================================================}
{                                                                          }
{         KILLS THE SCREEN BACKGROUND                                      }
{                                                                          }
{==========================================================================}
PROCEDURE KillBackDrop;
BEGIN
     gxDestroyVirtual(ScreenBack);
END;


END.
