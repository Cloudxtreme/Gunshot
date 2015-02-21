{$I DEFINES.INC}
UNIT GoodLang;


INTERFACE


FUNCTION clean_language(work_string: string): string;


IMPLEMENTATION


USES BsString,Globals;


FUNCTION clean_language(work_string: string): string;
VAR  Work       : Word;
     Loop       : Word;
BEGIN
     ASSIGN(FBadLang,DATA_Directory+'\BADLANG.DAT');
     {$I-}RESET(FBadLang);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FBadLang,BadLang);
                BadLang.Phrase := _UpperCase(BadLang.Phrase);
                IF BadLang.Phrase<>'' THEN
                BEGIN
                     REPEAT
                           work := Pos(BadLang.Phrase,_UpperCase(Work_String));
                           IF Work<>0 THEN
                           BEGIN
                                FOR Loop := 1 TO Length(BadLang.Phrase) DO
                                    Work_String[work+Loop-1] := '*';
                           END;
                     UNTIL Work=0;
                END;
          UNTIL EOF(FBadLang);
          CLOSE(FBadLang);
          clean_language := work_string;
     END
     ELSE clean_language := work_string;
END;


END.