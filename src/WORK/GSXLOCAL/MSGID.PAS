{$I DEFINES.INC}
UNIT MsgId;


INTERFACE


FUNCTION GetFromMsgId(Num: Word): Word;


IMPLEMENTATION


USES Globals;


FUNCTION GetFromMsgId(Num: Word): Word;
VAR  Counter : Word;
BEGIN
     Counter := 0;
     ASSIGN(FMessageArea,DATA_Directory+'\MA000000.DAT');
     RESET(FMessageArea);
     REPEAT
           READ(FMessageArea,MessageAreas);
           INC(Counter);
           IF MessageAreas.AreaID = Num THEN
           BEGIN
                CLOSE(FMessageArea);
                GetFromMsgId := Counter;
                Exit;
           END;
     UNTIL EOF(FMessageArea);
     CLOSE(FMessageArea);
     GetFromMsgId := 1;
END;


END.
