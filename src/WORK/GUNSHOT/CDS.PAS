{$I DEFINES.INC}
UNIT CDS;


INTERFACE


FUNCTION  IsCDOnline    (Num: Word): Boolean;
FUNCTION  IsCDToggled   (Num: Word): Boolean;
FUNCTION  GetCDName     (Num: Word): String;
PROCEDURE StartCDToggle;


IMPLEMENTATION


USES Globals,Shotgun,BsFile;


FUNCTION IsCDOnline(Num: Word): Boolean;
BEGIN
     IF CDRoms.CDNumber=Num THEN
     BEGIN
          CASE CDRoms.CDEnabled OF
          0:   IsCDOnline := False;
          1:   IsCDOnline := True;
          END;
          Exit;
     END;
     ASSIGN(FCDRoms,DATA_Directory+'\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FCDRoms,CDRoms);
                IF CDRoms.CDNumber=Num THEN
                BEGIN
                     CASE CDRoms.CDEnabled OF
                     0:   IsCDOnline := False;
                     1:   IsCDOnline := True;
                     END;
                     CLOSE(FCDRoms);
                     Exit;
                END;
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms);
     END;
     IsCDOnline := False;
END;


FUNCTION GetCDName(Num: Word): String;
BEGIN
     IF CDRoms.CDNumber=Num THEN
     BEGIN
          GetCDName := CDRoms.CDName;
          Exit;
     END;
     ASSIGN(FCDRoms,DATA_Directory+'\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FCDRoms,CDRoms);
                IF CDRoms.CDNumber=Num THEN
                BEGIN
                     GetCDName := CDRoms.CDName;
                     CLOSE(FCDRoms);
                     Exit;
                END;
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms);
     END;
     GetCDName := '';
END;


PROCEDURE StartCDToggle;
VAR  FCDRoms2 : File Of _CDRom_Record;
BEGIN
     ASSIGN(FCDRoms,DATA_Directory+'\CDROMS.DAT');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          ASSIGN(FCDRoms2,NODE_Directory+'\CDROMS.$$$');
          REWRITE(FCDRoms2);
          REPEAT
                READ(FCDRoms,CDRoms);
                WRITE(FCDRoms2,CDRoms);
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms2);
          CLOSE(FCDRoms);
     END
     ELSE _EraseFile(NODE_Directory+'\CDROMS.$$$');
END;


FUNCTION IsCDToggled(Num: Word): Boolean;
BEGIN
     IF ToggleCDRoms.CDNumber=Num THEN
     BEGIN
          CASE ToggleCDRoms.CDEnabled OF
          0:   IsCDToggled := False;
          1:   IsCDToggled := True;
          END;
          Exit;
     END;
     ASSIGN(FCDRoms,NODE_Directory+'\CDROMS.$$$');
     {$I-}RESET(FCDRoms);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FCDRoms,ToggleCDRoms);
                IF ToggleCDRoms.CDNumber=Num THEN
                BEGIN
                     CASE ToggleCDRoms.CDEnabled OF
                     0:   IsCDToggled := False;
                     1:   IsCDToggled := True;
                     END;
                     CLOSE(FCDRoms);
                     Exit;
                END;
          UNTIL EOF(FCDRoms);
          CLOSE(FCDRoms);
     END;
     IsCDToggled := False;
END;


END.
