{$I DEFINES.INC}
UNIT DropFile;


INTERFACE


PROCEDURE CreateDropFile;


IMPLEMENTATION


USES Globals;


PROCEDURE CreateDropFile;
BEGIN
     YappDropFile.Port      := CommDef.Port;
     YappDropFile.PortAddr  := CommDef.PortAddr;
     YappDropFile.Irq       := CommDef.Irq;
     YappDropFile.Device    := CommDef.Device;
     YappDropFile.Baud      := ActualBaud;
     YappDropFile.Logon     := DialDir.Logon;
     YappDropFile.Password  := DialDir.Password;
     YappDropFile.F1        := DialDir.F1;
     YappDropFile.F2        := DialDir.F2;
     YappDropFile.F3        := DialDir.F3;
     YappDropFile.F4        := DialDir.F4;
     YappDropFile.F5        := DialDir.F5;
     YappDropFile.F6        := DialDir.F6;
     YappDropFile.F7        := DialDir.F7;
     YappDropFile.F8        := DialDir.F8;
     YappDropFile.F9        := DialDir.F9;
     YappDropFile.F10       := DialDir.F10;
     YappDropFile.Sound     := DialDir.Sound;
     YappDropFile.UlDir     := CommDef.ULDir;
     YappDropFile.DlDir     := CommDef.DLDir;
     CASE CommDef.VideoMode OF
     1:   YappDropFile.VideoSize := 800;
     2:   YappDropFile.VideoSize := 1024;
     ELSE YappDropFile.VideoSize := 640;
     END;
     ASSIGN(FYappDropFile,'YAPPINFO.DEF');
     REWRITE(FYappDropFile);
     WRITE(FYappDropFile,YappDropFile);
     CLOSE(FYappDropFile);
END;


END.