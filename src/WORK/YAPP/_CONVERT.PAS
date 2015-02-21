{$I DEFINES.INC}
UNIT _Convert;


INTERFACE


FUNCTION ConvertColourCodes  (InString: String): String;
FUNCTION GetStringWidth      (VarNumber: Byte): Word;


IMPLEMENTATION


USES BsString;


FUNCTION ConvertColourCodes(InString: String): String;
VAR  Work : Word;
     Loop : Word;
     Temp : String;
     SS   : String;
BEGIN
     FOR Loop := 0 TO 15 DO
     BEGIN
          SS   := _String(Loop);
          Temp := '{'+SS+'}';
          REPEAT
                Work := Pos(Temp,InString);
                IF (Work<>0) THEN
                BEGIN
                     Delete(InString,Work,LENGTH(Temp));
                     Insert(#1+CHR(Loop),InString,Work);
                END;
          UNTIL Work=0;
          IF (Loop<10) THEN Temp := '|0'+SS
                       ELSE Temp := '|'+SS;
          REPEAT
                Work := Pos(Temp,InString);
                IF (Work<>0) THEN
                BEGIN
                     Delete(InString,Work,3);
                     Insert(#1+CHR(Loop),InString,Work);
                END;
          UNTIL Work=0;
     END;
     ConvertColourCodes := InString;
END;


FUNCTION GetStringWidth(VarNumber: Byte): Word;
CONST Widths : Array [1..31] Of Byte =
               (30,30,20,10,30,30,30,30,20,20,20,9,9,4,4,2,
               12,10,9,30,10,20,30,40,50,60,70,30,20,20,60);
BEGIN
     IF ((VarNumber>0) AND (VarNumber<32))
        THEN GetStringWidth := Widths[VarNumber]
        ELSE GetStringWidth := 1;
END;


END.
