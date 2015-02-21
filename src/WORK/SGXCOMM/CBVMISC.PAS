{$I DEFINES.INC}
UNIT CBVMisc;


INTERFACE


FUNCTION  GetCBVEnd: Longint;
FUNCTION  GetCBVStart: Longint;
FUNCTION  GetCBVEnabled: Byte;


IMPLEMENTATION


USES Globals,Shotgun;


FUNCTION GetCBVEnd: Longint;
VAR  CBVSetup  : _CallBack_Record;
     FCBVSetup : File Of _CallBack_Record;
BEGIN
     ASSIGN(FCBVSetup,DATA_Directory+'\CALLBACK.DAT');
     RESET(FCBVSetup);
     READ(FCBVSetup,CBVSetup);
     CLOSE(FCBVSetup);
     GetCBVEnd := CBVSetup.CBVEnd;
END;


FUNCTION GetCBVStart: Longint;
VAR  CBVSetup  : _CallBack_Record;
     FCBVSetup : File Of _CallBack_Record;
BEGIN
     ASSIGN(FCBVSetup,DATA_Directory+'\CALLBACK.DAT');
     RESET(FCBVSetup);
     READ(FCBVSetup,CBVSetup);
     CLOSE(FCBVSetup);
     GetCBVStart := CBVSetup.CBVStart;
END;


FUNCTION GetCBVEnabled: Byte;
VAR  CBVSetup  : _CallBack_Record;
     FCBVSetup : File Of _CallBack_Record;
BEGIN
     ASSIGN(FCBVSetup,DATA_Directory+'\CALLBACK.DAT');
     RESET(FCBVSetup);
     READ(FCBVSetup,CBVSetup);
     CLOSE(FCBVSetup);
     GetCBVEnabled := CBVSetup.ForceUse;
END;


END.