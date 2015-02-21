{$I DEFINES.INC}
UNIT _Convert;


INTERFACE


FUNCTION ConvertColourCodes  (InString: String): String;
FUNCTION GetStringWidth      (VarNumber: Byte): Word;


IMPLEMENTATION


USES BsString;


{==========================================================================}
{                                                                          }
{         CONVERTS COLOUR CODES TO A USEABLE FORMAT                        }
{                                                                          }
{==========================================================================}
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
{==========================================================================}
{                                                                          }
{         RETURNS THE WIDTH REQUIRED FOR PROMPT BOXES                      }
{                                                                          }
{==========================================================================}
FUNCTION GetStringWidth(VarNumber: Byte): Word;
BEGIN
     CASE VarNumber OF
     1:   GetStringWidth := 30; {user's real name}
     2:   GetStringWidth := 30; {user's alias}
     3:   GetStringWidth := 20; {user's password}
     4:   GetStringWidth := 8;  {user's birthdate}
     5:   GetStringWidth := 30; {user's street address}
     6:   GetStringWidth := 30; {user's city}
     7:   GetStringWidth := 30; {user's province}
     8:   GetStringWidth := 30; {user's country}
     9:   GetStringWidth := 20; {user's postal code}
     10:  GetStringWidth := 20; {user's data phone}
     11:  GetStringWidth := 20; {user's voice phone}
     12:  GetStringWidth := 9;  {deposit bytes}
     13:  GetStringWidth := 9;  {withdraw bytes}
     14:  GetStringWidth := 4;  {deposit minutes}
     15:  GetStringWidth := 4;  {withdraw minutes}
     16:  GetStringWidth := 2;  {# file display lines}
     17:  GetStringWidth := 12; {General File Name}
     18:  GetStringWidth := 8;  {General Date}
     19:  GetStringWidth := 9;  {General Numeric}
     20:  GetStringWidth := 30; {General Proper Name}
     21:  GetStringWidth := 10; {General String 10}
     22:  GetStringWidth := 20; {General String 20}
     23:  GetStringWidth := 30; {General String 30}
     24:  GetStringWidth := 40; {General String 40}
     25:  GetStringWidth := 50; {General String 50}
     26:  GetStringWidth := 60; {General String 60}
     27:  GetStringWidth := 70; {General String 70}
     28:  GetStringWidth := 30; {Users BBS Name}
     29:  GetStringWidth := 20; {Users BBS Address}
     30:  GetStringWidth := 20; {Users BBS Phone Number}
     31:  GetStringWidth := 60; {Users Comment}
     END;
END;


END.
