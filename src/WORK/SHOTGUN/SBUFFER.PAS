{$I DEFINES.INC}
UNIT SBuffer;


INTERFACE


PROCEDURE ClearBuffer;
PROCEDURE AddToBuffer(In1,In2: String);
FUNCTION  ProcessBuffer(InString: String; IsRip: Boolean): String;


IMPLEMENTATION


USES Globals,ErrorLog,Special,BsString;


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


FUNCTION ProcessBuffer(InString: String; IsRip: Boolean): String;
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
                    IF WorkBuffer^[Loop].Replacement=DontSend THEN
                    BEGIN
                         IF NOT(IsRip) THEN
                         BEGIN
                              InString := DontSend;
                              GOTO Skip;
                         END
                         ELSE WorkBuffer^[Loop].Replacement := '';
                    END;
                    EndToken := _Pos2('@',InString,StartToken+1);
                    IF EndToken<>0 THEN
                    BEGIN
                         NumChars := EndToken-StartToken+1;
                         Delete(InString,StartToken,NumChars);
                         IF WorkBuffer^[Loop].Token='@INSERT' THEN
                         BEGIN
                              Insert(WorkBuffer^[Loop].Replacement,InString,StartToken);
                         END
                         ELSE
                         BEGIN
                              PreProcessed := LENGTH(Process_Special(WorkBuffer^[Loop].Replacement,True));
                              Pads         := NumChars-PreProcessed;
                              IF PreProcessed>NumChars THEN
                              BEGIN
                                   WorkBuffer^[Loop].Replacement := _Mid(WorkBuffer^[Loop].Replacement,1,
                                                                    LENGTH(WorkBuffer^[Loop].Replacement)-
                                                                    (PreProcessed-NumChars));
                                   PreProcessed := NumChars;
                                   Pads         := NumChars-PreProcessed;
                              END;
                              Temp := WorkBuffer^[Loop].Replacement+_PadRight('',Pads);
                              IF WorkBuffer^[Loop].Replacement<>'' THEN
                              BEGIN
                                   IF WorkBuffer^[Loop].Replacement[1]=Chr(1)
                                      THEN Temp := WorkBuffer^[Loop].Replacement[2];
                                   IF WorkBuffer^[Loop].Replacement[1]=Chr(2) THEN
                                   BEGIN
                                        Temp := WorkBuffer^[Loop].Replacement;
                                        Delete(Temp,1,1);
                                   END;
                              END;
                              Insert(Temp,InString,StartToken);
                         END;
                    END;
               END;
          END;
     END;
     Skip:
     ProcessBuffer := InString;
END;


END.
