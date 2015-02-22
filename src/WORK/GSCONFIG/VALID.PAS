{$I DEFINES.INC}
UNIT Valid;


INTERFACE


FUNCTION ValidateIt(InString: String; PathType: String): String;


IMPLEMENTATION


USES BsString,BsFile;


FUNCTION ValidateIt(InString: String; PathType: String): String;
BEGIN
     InString := _UpperCase(InString);
     InString := _RemoveSpaces(InString);
     IF PathType='FILE' THEN
     BEGIN
          IF InString[LENGTH(InString)]='\' THEN
             InString := _Mid(InString,1,LENGTH(InString)-1);
     END
     ELSE IF PathType='PATH' THEN
     BEGIN
          IF InString[LENGTH(InString)]<>'\' THEN
             InString := InString+'\';
          _CreatePath(InString);
          IF IoResult=0 THEN;
     END;
     ValidateIt := InString;
END;


END.