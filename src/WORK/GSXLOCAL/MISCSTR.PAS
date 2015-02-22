{$I DEFINES.INC}
UNIT MiscStr;


INTERFACE


FUNCTION  Get_Language(file_index: word): string;
FUNCTION  PhoneNumber(InString: String): String;
FUNCTION  ZeroPadded(Number: Word): String;
FUNCTION  UsersFirstName: String;
FUNCTION  UsersLastName: String;


IMPLEMENTATION


USES Globals,BsString;


FUNCTION PhoneNumber(InString: String): String;
VAR  Temp : String;
     Work : Word;
BEGIN
     Temp := '';
     FOR Work := 1 TO LENGTH(InString) DO
     BEGIN
          IF ((Ord(InString[Work])>=48) AND (Ord(InString[Work])<=57)) THEN
          BEGIN
               Temp := Temp+InString[Work];
          END
          ELSE IF InString[Work]='-' THEN
          BEGIN
               Temp := Temp+InString[Work];
          END;
     END;
     PhoneNumber := Temp;
END;


FUNCTION UsersFirstName: String;
VAR  Work : Word;
     Temp : String;
BEGIN
     Temp := UserRecord.Name;
     Work := Pos(' ',Temp);
     IF Work<>0 THEN Temp := _Mid(Temp,1,Work-1);
     UsersFirstName := Temp;
END;


FUNCTION UsersLastName: String;
VAR  Work : Word;
     Temp : String;
BEGIN
     Temp := UserRecord.Name;
     REPEAT
           Work := Pos(' ',Temp);
           IF Work<>0 THEN Delete(Temp,1,Work);
     UNTIL Work=0;
     UsersLastName := Temp;
END;


FUNCTION Get_Language(file_index: word): string;
VAR  TFile : Text;
     Temp  : String;
BEGIN
     Temp := '';
     ASSIGN(TFile,LanguageDirectory+'ANSI\_P'+_String(file_index)+'.ANS');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READLN(TFile,Temp);
          CLOSE(TFile);
     END;
     Get_Language := Temp;
END;


FUNCTION ZeroPadded(Number: Word): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := _String(Number);
     FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
     ZeroPadded := Temp;
END;


END.
