{$I DEFINES.INC}
UNIT _Virtual;


INTERFACE


USES Gx2_Bp;


FUNCTION  CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
PROCEDURE DestroyVirtual(VBuffer: GXHeader);


IMPLEMENTATION


USES Gx2_BpVc,ErrorLog;


FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
VAR  Error : Integer;
LABEL        Continue;
BEGIN
     Error := gxCreateVirtual(gxCMM,VBuffer,CT,W,H);
     IF Error=GxSuccess THEN GOTO Continue;
     DoErrorLog(105,'');
     Halt;
     Continue:
     CreateVirtual := True;
END;


PROCEDURE DestroyVirtual(VBuffer: GXHeader);
BEGIN
     gxDestroyVirtual(VBuffer);
END;


END.