{$I DEFINES.INC}
UNIT SBuffer;


INTERFACE


PROCEDURE ClearBuffer;
PROCEDURE AddToBuffer(In1,In2: String);
FUNCTION  ProcessBuffer(InString: String): String;


IMPLEMENTATION


USES Globals,ErrorLog,BsString;


PROCEDURE ClearBuffer;
BEGIN
     InBuffer := 0;
END;


PROCEDURE AddToBuffer(In1,In2: String);
BEGIN
     IF InBuffer<=110 THEN
     BEGIN
          INC(InBuffer);
          WorkBuffer^[InBuffer].Token := In1;
          WorkBuffer^[InBuffer].Replacement := In2;
     END
     ELSE DoErrorLog(5,'');
END;


FUNCTION ProcessBuffer(InString: String): String;
VAR  StartToken   : Word;
     EndToken     : Word;
     Loop         : Word;
     Loop2        : Word;
     NumChars     : Byte;
     Temp         : String;
     Doit         : Boolean;
     PreProcessed : Word;
     Pads         : Word;
LABEL               Skip;
BEGIN
     IF InBuffer<>0 THEN
     BEGIN
          IF Pos('@',InString)=0 THEN GOTO Skip;
          FOR Loop := 1 TO InBuffer DO
          BEGIN
               StartToken := Pos(WorkBuffer^[Loop].Token,InString);
               IF StartToken<>0 THEN
               BEGIN
                    IF WorkBuffer^[Loop].Replacement=DontSend THEN WorkBuffer^[Loop].Replacement := '';
                    EndToken := _Pos2('@',InString,StartToken+1);
                    IF EndToken<>0 THEN
                    BEGIN
                         NumChars := EndToken-StartToken+1;
                         Delete(InString,StartToken,NumChars);
                         Insert(WorkBuffer^[Loop].Replacement,InString,StartToken);
                    END;
               END;
          END;
     END;
     Skip:
     ProcessBuffer := InString;
END;


END.
