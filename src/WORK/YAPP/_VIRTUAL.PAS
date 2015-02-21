{$I DEFINES.INC}
UNIT _Virtual;


INTERFACE


USES Gx2_Bp;


FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;


IMPLEMENTATION


USES Gx2_BpVC,Globals,Crt;


FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
VAR  Error : Integer;
LABEL        Continue;
BEGIN
     Error := gxCreateVirtual(gxCMM,VBuffer,CT,W,H);
     IF Error=GxSuccess THEN GOTO Continue;
     TextMode(co80);
     Halt(1);
     Continue:
     CreateVirtual := True;
END;


END.