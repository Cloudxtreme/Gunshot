{$I DEFINES.INC}
UNIT Fido;


INTERFACE


FUNCTION  LastAppropriateFido(LRP: Word): Word;
PROCEDURE PurgeFido;
PROCEDURE RenumberFido;
PROCEDURE LastReadFido;
PROCEDURE PackFido;


IMPLEMENTATION


USES Globals,Dos,BsFile,BsString;


PROCEDURE PurgeFido;
VAR  Loop : Word;
BEGIN
     IF ((NumMsgs<=MessageAreas.MaxMsgs) OR (MessageAreas.Area_Type>=20)) THEN
     BEGIN
       INC(TotalMsgs,NumMsgs);
       Exit;
     END
     ELSE INC(TotalMsgs,MessageAreas.MaxMsgs);
     FOR Loop := 1 TO NumMsgs-MessageAreas.MaxMsgs DO
     BEGIN
       _EraseFile(MessageAreas.Dos_Name+_String(Indexes[Loop])+'.MSG');
     END;
     NewBase := NumMsgs-MessageAreas.MaxMsgs+1;
END;


PROCEDURE RenumberFido;
VAR  Loop    : Word;
     Counter : Word;
BEGIN
     IF (NumMsgs<=MessageAreas.MaxMsgs) THEN Exit;
     Counter := 1;
     FOR Loop := NewBase TO NumMsgs DO
     BEGIN
       IF (Indexes[Loop]<>Counter) THEN
       BEGIN
         _RenameFile(MessageAreas.Dos_Name+_String(Indexes[Loop])+'.MSG',
                     MessageAreas.Dos_Name+_String(Counter)+'.MSG');
       END;
       INC(Counter);
     END;
END;


FUNCTION LastAppropriateFido(LRP: Word): Word;
VAR  Work    : Longint;
     Counter : Word;
     Loop    : Word;
BEGIN
     Work    := 1;
     Counter := 1;
     FOR Loop := NewBase TO NumMsgs DO
     BEGIN
       IF Indexes[Loop]<=LRP THEN Work := Counter;
       INC(Counter);
     END;
     LastAppropriateFido := Work;
END;


PROCEDURE LastReadFido;
TYPE Last_Read = RECORD
     LRP       : Word;
     END;
VAR  LastRead  : Last_Read;
     FLastRead : File Of Last_Read;
     UsrNumber : Longint;
BEGIN
     IF (NumMsgs<=MessageAreas.MaxMsgs) THEN Exit;
     UsrNumber := 0;
     ASSIGN(FLastRead,MessageAreas.Dos_Name+'LASTREAD');
     {$I-}RESET(FLastRead);{$I+}
     IF IOResult=0 THEN
     BEGIN
       REPEAT
         READ(FLastRead,LastRead);
         LastRead.LRP := LastAppropriateFido(LastRead.LRP);
         SEEK(FLastRead,UsrNumber);
         WRITE(FLastRead,LastRead);
         INC(UsrNumber);
       UNTIL EOF(FLastRead);
       CLOSE(FLastRead);
     END;
END;


PROCEDURE PackFido;
VAR  DirInfo    : SearchRec;
     Loop       : Word;
     Loop2      : Word;
     SearchFile : String;
     Work       : Word;
BEGIN
     IF MessageAreas.MaxMsgs=0 THEN MessageAreas.MaxMsgs := 1000;
     {GET ALL THE MESSAGE NAMES}
     NumMsgs := 0;
     NewBase := 1;
     FindFirst(MessageAreas.Dos_Name+'*.MSG',Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
       INC(NumMsgs);
       SearchFile := _NoExtension(_UpperCase(DirInfo.Name));
       Indexes[NumMsgs] := _Numeric(SearchFile);
       FindNext(DirInfo);
     END;
     IF NumMsgs=0 THEN Exit;
     Temp := 'AREA: '+_PadRight(MessageAreas.Area_Name,41);
     WRITE(Temp);
     Temp := 'MSGS: '+_PadRight(_String(NumMsgs),5);
     WRITE(Temp);
     Temp := 'KEEP: '+_PadRight(_String(MessageAreas.MaxMsgs),5);
     WRITE(Temp);
     {CREATE THE SORTED INDEXES}
     FOR Loop := 1 TO NumMsgs DO
     BEGIN
       FOR Loop2 := 1 TO NumMsgs DO
       BEGIN
         IF Indexes[Loop]<Indexes[Loop2] THEN
         BEGIN
           Work := Indexes[Loop];
           Indexes[Loop]  := Indexes[Loop2];
           Indexes[Loop2] := Work;
         END;
       END;
     END;
     PurgeFido;
     RenumberFido;
     LastReadFido;
     WRITELN('Done!  ');
END;


END.
