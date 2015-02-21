USES BsExec,BsString,BsFile,FMode;


TYPE Yapp_DropFile    = RECORD
     Port             : Byte;
     PortAddr         : String[4];
     Irq              : Byte;
     Device           : Byte;
     Baud             : Longint;
     Logon            : String[30];
     Password         : String[20];
     F1               : String[30];
     F2               : String[30];
     F3               : String[30];
     F4               : String[30];
     F5               : String[30];
     F6               : String[30];
     F7               : String[30];
     F8               : String[30];
     F9               : String[30];
     F10              : String[30];
     Sound            : Boolean;
     UlDir            : String[50];
     DlDir            : String[50];
     VideoSize        : Word;
     END;
VAR  YappDropFile     : Yapp_DropFile;
     FYappDropFile    : File Of Yapp_DropFile;
     CommDefPort      : Byte;
     CommDefIrq       : Byte;
     CommDefDevice    : Byte;
     CommDefPortAddr  : String[4];
     ActualBaud       : Longint;
     CommDefSound     : Boolean;
     CommDefVideoMode : Longint;
     Sig              : String;
     TTemp            : String;


PROCEDURE CreateDropFile;
BEGIN
     FillChar(YappDropFile,SizeOf(YappDropFile),0);
     YappDropFile.Port      := CommDefPort;
     YappDropFile.PortAddr  := CommDefPortAddr;
     YappDropFile.Irq       := CommDefIrq;
     YappDropFile.Device    := CommDefDevice;
     YappDropFile.Baud      := ActualBaud;
     YappDropFile.Sound     := CommDefSound;
     YappDropFile.VideoSize := CommDefVideoMode;
     YappDropFile.UlDir     := 'C:\';
     YappDropFile.DlDir     := 'C:\';
     ASSIGN(FYappDropFile,'YAPPINFO.DEF');
     REWRITE(FYappDropFile);
     WRITE(FYappDropFile,YappDropFile);
     CLOSE(FYappDropFile);
END;


PROCEDURE ReadINIFile;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     CommDefPort      := 1;
     CommDefPortAddr  := '3F8';
     CommDefIrq       := 4;
     CommDefDevice    := 1;
     ActualBaud       := 14400;
     CommDefSound     := True;
     CommDefVideoMode := 640;
     ASSIGN(TFile,'GLAUNCH.INI');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READLN(TFile,Temp);
                Temp := _UpperCase(_RemoveSpaces(Temp));
                IF ((Temp[1]=';') OR (Temp='')) THEN
                BEGIN
                     {Do Nothing}
                END
                ELSE IF _Mid(Temp,1,7)='COMPORT' THEN
                BEGIN
                     Delete(Temp,1,8);
                     CommDefPort := _Numeric(Temp);
                END
                ELSE IF _Mid(Temp,1,6)='DEVICE' THEN
                BEGIN
                     Delete(Temp,1,7);
                     IF Temp='UART' THEN
                     BEGIN
                          CommDefDevice := 1;
                     END
                     ELSE IF Temp='FOSSIL' THEN
                     BEGIN
                          CommDefDevice := 2;
                     END
                     ELSE IF Temp='DIGIBOARD' THEN
                     BEGIN
                          CommDefDevice := 3;
                     END;
                END
                ELSE IF _Mid(Temp,1,3)='IRQ' THEN
                BEGIN
                     Delete(Temp,1,4);
                     CommDefIrq := _Numeric(Temp);
                END
                ELSE IF _Mid(Temp,1,8)='PORTADDR' THEN
                BEGIN
                     Delete(Temp,1,9);
                     CommDefPortAddr := Temp;
                END
                ELSE IF _Mid(Temp,1,15)='USESOUNDBLASTER' THEN
                BEGIN
                     Delete(Temp,1,16);
                     IF Temp[1]='Y' THEN CommDefSound := True
                                    ELSE CommDefSound := False;
                END
                ELSE IF _Mid(Temp,1,9)='VIDEOSIZE' THEN
                BEGIN
                     Delete(Temp,1,10);
                     CommDefVideoMode := _Numeric(Temp);
                END;
          UNTIL EOF(TFile);
          CLOSE(TFile);
     END;
END;


BEGIN
     FileMode := SetFileMode;
     TTemp := ParamStr(1);
     ActualBaud := _Numeric(TTemp);
     ReadINIFile;
     CreateDropFile;
     IF CommDefSound THEN Sig := ' 1 $$BB$$SS$$ '
                     ELSE Sig := ' 0 $$BB$$SS$$ ';
     DoExec('YAPP_E.EXE',_String(CommDefPort)+' '+_String(ActualBaud)+Sig+'C:\ -NOROM',USE_ALL,'C:\');
     IF _FileExists('YAPP16.EXE') THEN
     BEGIN
          _EraseFile('YAPP_E.EXE');
          _RenameFile('YAPP16.EXE','YAPP_E.EXE');
     END;
END.
