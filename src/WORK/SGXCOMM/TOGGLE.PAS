{$I DEFINES.INC}
UNIT Toggle;


INTERFACE


PROCEDURE StartToggle(Size: Longint);
PROCEDURE RedrawToggle;
PROCEDURE EndToggle;
PROCEDURE DoToggle;


IMPLEMENTATION


USES ApPort,ApCom,Globals;


PROCEDURE StartToggle(Size: Longint);
BEGIN
     PutStringTimeout(BBSPort,#255#200#13,YappDelay);
     ToggleInfo.Total   := Size;
     ToggleInfo.Current := 0;
     ToggleInfo.Active  := True;
     ToggleInfo.Percent := 0;
     IF ((ToggleInfo.x2-ToggleInfo.x1)>=(ToggleInfo.y2-ToggleInfo.y1))
        THEN ToggleInfo.Horizontal := True
        ELSE ToggleInfo.Horizontal := False;
END;


PROCEDURE EndToggle;
BEGIN
     PutStringTimeout(BBSPort,#255#202#13,YappDelay);
     ToggleInfo.Active := False;
END;


PROCEDURE DoToggle;
VAR  Percent : Word;
     Work    : Word;
BEGIN
     INC(ToggleInfo.Current);
     Percent := Trunc((ToggleInfo.Current/ToggleInfo.Total)*100);
     IF Percent<>ToggleInfo.Percent THEN
     BEGIN
          ToggleInfo.Percent := Percent;
          PutStringTimeout(BBSPort,#255#201#13,YappDelay);
          PutBlockTimeOut(BBSPort,ToggleInfo.Percent,2,Work,YappDelay);
     END;
END;


PROCEDURE RedrawToggle;
VAR  Percent : Word;
     Work    : Word;
BEGIN
     Percent := Trunc((ToggleInfo.Current/ToggleInfo.Total)*100);
     ToggleInfo.Percent := Percent;
     PutStringTimeout(BBSPort,#255#203#13,YappDelay);
     PutBlockTimeOut(BBSPort,ToggleInfo.Percent,2,Work,YappDelay);
END;


END.
