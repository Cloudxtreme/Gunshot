{$I DEFINES.INC}
UNIT GetProto;


INTERFACE


PROCEDURE select_protocol;


IMPLEMENTATION


USES Globals,ANSIMisc,Screens,KeyInput;


PROCEDURE select_protocol;
VAR  c             : char;
     Temp          : String;
BEGIN
     ASSIGN(FProtocolInfo,DATA_Directory+'\PROTOCOL.DAT');
     RESET(FProtocolInfo);
     READ(FProtocolInfo,ProtocolInfo);
     CLOSE(FProtocolInfo);
     SendCrLf(2);
     DisplayGraphicsFile('PROTOCOL',false,false,True,True,False);
     Temp := 'Q';
     IF ProtocolInfo.EnableZ=1   THEN Temp := Temp+ProtocolInfo.ZKey;
     IF ProtocolInfo.EnableX=1   THEN Temp := Temp+ProtocolInfo.XKey;
     IF ProtocolInfo.EnableX1K=1 THEN Temp := Temp+ProtocolInfo.X1KKey;
     IF ProtocolInfo.EnableY=1   THEN Temp := Temp+ProtocolInfo.YKey;
     IF ProtocolInfo.EnableYG=1  THEN Temp := Temp+ProtocolInfo.YGKey;
     c := UpCase(Get_Menu_Selection(Temp,'Q'));
          IF c='Q'                 THEN protocol := 255
     ELSE IF c=ProtocolInfo.ZKey   THEN Protocol := 1
     ELSE IF c=ProtocolInfo.XKey   THEN Protocol := 2
     ELSE IF c=ProtocolInfo.X1KKey THEN Protocol := 3
     ELSE IF c=ProtocolInfo.YKey   THEN Protocol := 4
     ELSE IF c=ProtocolInfo.YGKey  THEN Protocol := 5;
END;


END.