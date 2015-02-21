{$I DEFINES.INC}
UNIT _Token;


INTERFACE


PROCEDURE LoadBuffer;
FUNCTION  ProcessBuffer(InString: String): String;


IMPLEMENTATION


USES Globals;


PROCEDURE LoadBuffer;
VAR  FWork_Buffer : File;
     BytesRead    : Word;
BEGIN
     InBuffer := 0;
     ASSIGN(FWork_Buffer,SESSION_Directory+'\BUFFER.DAT');
     {$I-}RESET(FWork_Buffer,1);{$I+}
     IF IOResult=0 THEN
     BEGIN
          BLOCKREAD(FWork_Buffer,WorkBuffer^,SizeOf(WorkBuffer^),BytesRead);
          CLOSE(FWork_Buffer);
          InBuffer := Round(BytesRead/(SizeOf(BufferItem)));
     END;
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
                    EndToken := 0;
                    Loop2    := StartToken+1;
                    REPEAT
                          IF InString[Loop2]='@' THEN EndToken := Loop2;
                          INC(Loop2);
                    UNTIL ((EndToken<>0) OR (Loop2>Length(InString)));
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