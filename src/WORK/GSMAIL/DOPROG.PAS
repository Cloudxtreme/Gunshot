{$I DEFINES.INC}
UNIT DoProg;


INTERFACE


PROCEDURE DoProgressBar(Current,Total,Maximum: Longint; VAR LastStat: Longint; x1,y1: Word; ShowPercent: Boolean);


IMPLEMENTATION


USES Globals,BsVideo,BsString;


PROCEDURE DoProgressBar(Current,Total,Maximum: Longint; VAR LastStat: Longint; x1,y1: Word; ShowPercent: Boolean);
CONST DisabledBar : String[50] = ('같같같같같같같같같같같같같같같같같같같같같같같같같');
VAR   ToCopy  : Longint;
      Percent : Longint;
      Temp    : String;
BEGIN
     IF Total=0 THEN Exit;
     ToCopy := Round((Current*Maximum)/Total);
     IF (ToCopy>Maximum) THEN ToCopy := Maximum;
     IF (LastStat<>ToCopy) THEN
     BEGIN
       Progress[0] := Chr(ToCopy);
       DisabledBar[0] := Chr(Maximum-ToCopy);
       FastWrite(Progress,y1,x1,GunshotColours.GSMailProgressBar);
       FastWrite(DisabledBar,y1,x1+ToCopy,GunshotColours.GSMailProgressBarBack);
       IF ShowPercent THEN
       BEGIN
         Percent := Round((Current*100)/Total);
         Temp := _PadRight(_String(Percent)+'%',4);
         FastWrite(Temp,y1,x1+Maximum+1,GunshotColours.GSMailWindowHighlight);
       END;
       LastStat := ToCopy;
     END;
END;


END.
