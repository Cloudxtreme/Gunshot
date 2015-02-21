{$I DEFINES.INC}
UNIT _Virtual;


INTERFACE


USES Gx2_Bp;


FUNCTION  CreateVirtual (VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
PROCEDURE load_cutout   (x,y: Integer; IndexNum,ForeBack: Word);
PROCEDURE save_cutout   (x1,y1,x2,y2: word; IndexNum,ForeBack: Word);
PROCEDURE kill_cutout   (IndexNum,ForeBack: Word);


IMPLEMENTATION


USES Globals,Gx2_BpVC,BsGraph,ErrorOut;


{===========================================================================}
{                                                                           }
{                             UTILITY ROUTINES                              }
{           REQUIRED FOR DRAWING MANY OF THE GRAPHICS PRIMITIVES            }
{                                                                           }
{===========================================================================}
FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
VAR  Error : Integer;
LABEL        Continue;
BEGIN
     Error := gxCreateVirtual(gxCMM,VBuffer,CT,W,H);
     IF Error=GxSuccess THEN GOTO Continue;
     CreateVirtual := False;
     Exit;
     Continue:
     CreateVirtual := True;
END;
{==========================================================================}
{                                                                          }
{         SAVES A SCREEN CUTOUT TO XMS/EMS/DISK MEMORY                     }
{                                                                          }
{==========================================================================}
PROCEDURE save_cutout(x1,y1,x2,y2: word; IndexNum,ForeBack: Word);
VAR  Error  : Integer;
LABEL         Continue;
BEGIN
     IF CutActive[IndexNum,ForeBack]=False THEN
     BEGIN
          IF CreateVirtual(Cutouts[IndexNum,ForeBack],x2-x1+1,y2-y1+1,TheDisplay) THEN GOTO Continue;
          DropError(4);
     END;
     Continue:
     Error := gxDisplayVirtual(x1,y1,x2,y2,0,Cutouts[IndexNum,ForeBack],0,0);
     CutCoord[IndexNum,ForeBack,1] := x1;
     CutCoord[IndexNum,ForeBack,2] := y1;
     CutCoord[IndexNum,ForeBack,3] := x2;
     CutCoord[IndexNum,ForeBack,4] := y2;
     IF Error=GxSuccess THEN CutActive[IndexNum,ForeBack] := True
                        ELSE CutActive[IndexNum,ForeBack] := False;
END;
{==========================================================================}
{                                                                          }
{         RESTORES THE SCREEN SAVED TO DISK                                }
{                                                                          }
{==========================================================================}
PROCEDURE load_cutout(x,y: Integer; IndexNum,ForeBack: Word);
BEGIN
     IF CutActive[IndexNum,ForeBack]=True THEN
     BEGIN
          gxVirtualDisplay(Cutouts[IndexNum,ForeBack],0,0,
                           CutCoord[IndexNum,ForeBack,1]+x,
                           CutCoord[IndexNum,ForeBack,2]+y,
                           CutCoord[IndexNum,ForeBack,3]+x,
                           CutCoord[IndexNum,ForeBack,4]+y,
                           0);
     END;
END;
{==========================================================================}
{                                                                          }
{         KILLS THE BUFFER ASSOCIATED WITH A SCREEN CUTOUT                 }
{                                                                          }
{==========================================================================}
PROCEDURE kill_cutout(IndexNum,ForeBack: Word);
BEGIN
     IF CutActive[IndexNum,ForeBack]=True THEN
     BEGIN
          gxDestroyVirtual(Cutouts[IndexNum,ForeBack]);
          CutActive[IndexNum,ForeBack] := False;
     END;
END;


END.