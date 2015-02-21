{$I DEFINES.INC}
UNIT FileID;


INTERFACE


FUNCTION GetFromFileId(Num: Word): Word;


IMPLEMENTATION


USES Globals;


FUNCTION GetFromFileId(Num: Word): Word;
VAR  Counter : Word;
BEGIN
     Counter := 0;
     ASSIGN(FFileArea,DATA_Directory+'\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileAreas);
           INC(Counter);
           IF FileAreas.AreaID = Num THEN
           BEGIN
                CLOSE(FFileArea);
                GetFromFileId := Counter;
                Exit;
           END;
     UNTIL EOF(FFileArea);
     CLOSE(FFileArea);
     GetFromFileId := 1;
END;


END.
