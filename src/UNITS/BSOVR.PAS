{$F+,I-,O-,N-}
{$D-,L-,R- }


UNIT BsOvr;


INTERFACE


IMPLEMENTATION


USES OVERLAY,OVERXMS,DOS,OVRVARS;


FUNCTION OvrName : STRING;
VAR  ofd     : DirStr;
     ofb     : NameStr;
     ofx     : ExtStr;
     DirInfo : SearchRec;
BEGIN
     IF ParamStr(0)= '' THEN
     BEGIN
          WRITELN('This program requires DOS 3.0 or higher');
          Halt(0);
     END;
     FSplit(ParamStr(0),ofd,ofb,ofx);
     FindFirst(ofd+ofb+'.OVR',AnyFile-Directory-VolumeID,DirInfo);
     IF DosError=0 THEN OvrName := ofd+ofb+'.OVR'
                   ELSE OvrName := ofd+ofb+'.EXE';
END;


PROCEDURE ShowError(Number: Integer);
VAR  Temp : String;
BEGIN
     Str(Number,Temp);
     WRITELN('Overlay buffer error: '+Temp);
     Halt(0);
END;


BEGIN
     OvrInit(OvrName);
     IF OvrResult<>0 THEN ShowError(OvrResult);
     OvrInitXMS;
     IF (OvrResult<>0) THEN
     BEGIN
          OvrInitEMS;
          IF (OvrResult<>0) THEN
          BEGIN
               OvrSetBuf(128000);
               _OverlayBufLoc := 2;
          END;
     END
     ELSE _OverlayBufLoc := 1;
     _OverLayBufferSize := OvrGetBuf;
END.
