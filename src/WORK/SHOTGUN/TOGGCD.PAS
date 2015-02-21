{$I DEFINES.INC}
UNIT ToggCD;


INTERFACE


PROCEDURE ToggleCDRom(CDNumber: Word; OnOff: Boolean);


IMPLEMENTATION


USES Globals,Shotgun;


PROCEDURE ToggleCDRom(CDNumber: Word; OnOff: Boolean);
VAR  Counter : Word;
BEGIN
     Counter := 0;
     ASSIGN(FCDRoms,NODE_Directory+'\CDROMS.$$$');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FCDRoms,ToggleCDRoms);
                INC(Counter);
                IF ToggleCDRoms.CDNumber=CDNumber THEN
                BEGIN
                     IF OnOff THEN ToggleCDRoms.CDEnabled := 1
                              ELSE ToggleCDRoms.CDEnabled := 0;
                     SEEK(FCDRoms,Counter-1);
                     WRITE(FCDRoms,ToggleCDRoms);
                     CLOSE(FCDRoms);
                     Exit;
                END;
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms);
     END;
END;


END.