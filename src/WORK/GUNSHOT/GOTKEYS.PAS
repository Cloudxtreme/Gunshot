{$I DEFINES.INC}
UNIT GotKeys;


INTERFACE


FUNCTION GotTheKeys(UsersKeys,OptionsKeys: Array Of Byte): Boolean;


IMPLEMENTATION


FUNCTION GotTheKeys(UsersKeys,OptionsKeys: Array Of Byte): Boolean;
VAR  Loop    : Word;
     AllIsOk : Boolean;
BEGIN
     AllIsOk := True;
     FOR Loop := 0 TO 9 DO
     BEGIN
          IF OptionsKeys[Loop]<>0 THEN
          BEGIN
               IF UsersKeys[Loop]=0 THEN AllIsOk := False;
          END;
     END;
     GotTheKeys := AllIsOk;
END;


END.