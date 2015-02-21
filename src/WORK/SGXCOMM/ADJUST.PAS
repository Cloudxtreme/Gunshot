{$I DEFINES.INC}
UNIT Adjust;


INTERFACE


PROCEDURE EditTheUsersAccount;


IMPLEMENTATION


USES BsVideo,Crt,Globals,BsString,BsMulti,Dos,BsKeys;


TYPE Button_Info = Record
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     Title        : String[20];
     Enabled      : Boolean;
     cc1          : Byte;    {ALT KEY STATUS}
     cc2          : Byte;    {NORM KEY STATUS}
     END;
TYPE Object_Info = Record
     x1           : Word;
     y1           : Word;
     x2           : Word;
     y2           : Word;
     ObjectType   : Word;
     ObjectLength : Word;
     Stuff        : String[80];
     Enabled      : Boolean;
     END;
TYPE ColourScheme = Record
     MenuBackGround          : Byte;
     MenuForeGround          : Byte;
     MenuHotKey              : Byte;
     MenuHighLightBackGround : Byte;
     MenuHighLightForeGround : Byte;
     MenuHighLightHotKey     : Byte;
     MenuBorder              : Byte;
     MenuDisabled            : Byte;
     DeskTopColour           : Byte;
     WindowBackGround        : Byte;
     WindowFrame             : Byte;
     WindowHeader            : Byte;
     WindowHeaderText        : Byte;
     WindowClose             : Byte;
     EditDisabled            : Byte;
     EditEnabled             : Byte;
     EditBackGround          : Byte;
     END;
CONST
     SpaceColour = 8;
     SpaceChar   = '_';
     Enabled     = True;
     Disabled    = False;
TYPE Object_Record = Array[1..40] Of Object_Info;
TYPE Button_Record = Array[1..5] Of Button_Info;
VAR  Colour                   : ColourScheme;
     Objects                  : ^Object_Record;
     Buttons                  : ^Button_Record;
     NumberOfObjects          : Word;
     NumberOfButtons          : Word;
     CurrentObject            : Word;
     DoingInputField          : Boolean;
     EditPos                  : Word;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String);
VAR  LoopY  : Word;
     LoopX  : Word;
BEGIN
     FOR LoopY := y1 TO y2 DO
     BEGIN
          IF LoopY=y1 THEN
          BEGIN
               FastWrite('Ú',LoopY,x1,25);
               FastWrite('¿',LoopY,x2,16);
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               FastWrite('À',LoopY,x1,25);
               FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,16);
               FastWrite('Ù',LoopY,x2,16);
          END
          ELSE
          BEGIN
               FastWrite('³',LoopY,x1,25);
               FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,16);
               FastWrite('³',LoopY,x2,16);
          END;
     END;
     Title := '  '+Title;
     Title := _PadRight(Title,x2-x1-1);
     FastWrite(Title,y1,x1+1,(Colour.WindowHeader*16)+Colour.WindowHeaderText);
END;

{ ObjectType  1 - String     }
{             2 - Numeric    }
{             3 - Time       }
{             4 - Date       }
{             5 - Gender     }
{             6 - Yes/No     }
{             7 - Tags       }
PROCEDURE AddObject(x1,y1,ObjectType,ObjectLength: Word; Stuff: String; Enabled: Boolean);
BEGIN
     INC(NumberOfObjects);
     Objects^[NumberOfObjects].x1           := x1;
     Objects^[NumberOfObjects].y1           := y1;
          IF ObjectType=4 THEN Objects^[NumberOfObjects].x2 := x1+ObjectLength+1
     ELSE IF ObjectType=3 THEN Objects^[NumberOfObjects].x2 := x1+ObjectLength
                          ELSE Objects^[NumberOfObjects].x2 := x1+ObjectLength-1;
     Objects^[NumberOfObjects].y2           := y1;
     Objects^[NumberOfObjects].ObjectType   := ObjectType;
     Objects^[NumberOfObjects].ObjectLength := ObjectLength;
     Objects^[NumberOfObjects].Stuff        := Stuff;
     Objects^[NumberOfObjects].Enabled      := Enabled;
END;


PROCEDURE DrawObjects;
VAR  Loop   : Word;
     Loop2  : Word;
     Poop   : Word;
BEGIN
     TextBackGround(Colour.EditBackGround);
     TextColor(Colour.EditDisabled);
     FOR Loop := 1 TO NumberOfObjects DO
     BEGIN
          GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
          IF Objects^[Loop].ObjectType=3 THEN
          BEGIN
               TextColor(SpaceColour);
               FOR Loop2 := 1 TO 5 DO WRITE(SpaceChar);
               TextColor(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,1,2));
               TextColor(SpaceColour);
               GotoXY(Objects^[Loop].x1+2,Objects^[Loop].y1);
               WRITE(':');
               TextColor(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1+3,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,3,4));
          END
          ELSE IF Objects^[Loop].ObjectType=5 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor(Colour.EditDisabled);
               IF Objects^[Loop].Stuff='1' THEN WRITE('MALE  ')
                                          ELSE WRITE('FEMALE');
          END
          ELSE IF Objects^[Loop].ObjectType=6 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor(Colour.EditDisabled);
               IF Objects^[Loop].Stuff='1' THEN WRITE('YES')
                                          ELSE WRITE('NO ');
          END
          ELSE IF Objects^[Loop].ObjectType=7 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               FOR Poop := 1 TO 10 DO
               BEGIN
                    IF Objects^[Loop].Stuff[Poop]='1' THEN
                    BEGIN
                         TextColor(Colour.EditDisabled);
                         WRITE(CHR(254));
                    END
                    ELSE
                    BEGIN
                         TextColor(SpaceColour);
                         WRITE(SpaceChar);
                    END;
               END;
          END
          ELSE IF Objects^[Loop].ObjectType=4 THEN
          BEGIN
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor(SpaceColour);
               WRITE('  /  /  ');
               TextColor(Colour.EditDisabled);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,1,2));
               GotoXY(Objects^[Loop].x1+3,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,3,4));
               GotoXY(Objects^[Loop].x1+6,Objects^[Loop].y1);
               WRITE(_Mid(Objects^[Loop].Stuff,5,6));
          END
          ELSE
          BEGIN
               TextColor(SpaceColour);
               FOR Loop2 := 1 TO Objects^[Loop].ObjectLength DO WRITE(SpaceChar);
               GotoXY(Objects^[Loop].x1,Objects^[Loop].y1);
               TextColor(Colour.EditDisabled);
               WRITE(Objects^[Loop].Stuff);
          END;
     END;
END;


PROCEDURE AddButton(x1,y1: Word; Title: String; Enabled: Boolean; cc1,cc2: Byte);
BEGIN
     INC(NumberOfButtons);
     IF NumberOfButtons=21 THEN Halt;
     Buttons^[NumberOfButtons].x1           := x1;
     Buttons^[NumberOfButtons].y1           := y1;
     Buttons^[NumberOfButtons].x2           := x1+LENGTH(Title)-1;
     Buttons^[NumberOfButtons].y2           := y1;
     Buttons^[NumberOfButtons].Title        := Title;
     Buttons^[NumberOfButtons].Enabled      := Enabled;
     Buttons^[NumberOfButtons].cc1          := cc1;
     Buttons^[NumberOfButtons].cc2          := cc2;
END;


PROCEDURE DrawButtons;
VAR
     Loop   : Word;
     Loop2  : Word;
     Loop3  : Word;
BEGIN
     FOR Loop := 1 TO NumberOfButtons DO
     BEGIN
          Loop3 := LENGTH(Buttons^[Loop].Title);
          {BUTTON FACE}
          TextBackGround(7);
          GotoXY(Buttons^[Loop].x1,Buttons^[Loop].y1);
          FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
          {BUTTON TEXT}
          GotoXY(Buttons^[Loop].x1,Buttons^[Loop].y1);
          TextColor(4); WRITE(_Mid(Buttons^[Loop].Title,1,2));
          TextColor(0); WRITE(_Mid(Buttons^[Loop].Title,3,Loop3));
          {BUTTON SHADOW}
          TextColor(0); TextBackGround(Colour.WindowBackGround);
          GotoXY(Buttons^[Loop].x1+Loop3,Buttons^[Loop].y1);
          WRITE('Ü');
          GotoXY(Buttons^[Loop].x1+1,Buttons^[Loop].y1+1);
          FOR Loop2 := 1 TO Loop3 DO WRITE('ß');
     END;
END;


PROCEDURE ClearObjects;
BEGIN
     NumberOfObjects := 0;
END;


PROCEDURE ClearButtons;
BEGIN
     NumberOfButtons := 0;
END;


PROCEDURE EnableButton(Number: Word);
VAR
     sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
BEGIN
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor(4);  WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor(0);  WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     TextColor(0);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1); WRITE('[');
     GotoXY(Buttons^[Number].x2,Buttons^[Number].y1); WRITE(']');
END;


PROCEDURE DisableButton(Number: Word);
VAR
     sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
BEGIN
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor(4); WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor(0); WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
END;


PROCEDURE PressButton(Number: Word);
VAR
     sx1,sx2,sy1     : Word;
     Loop3           : Word;
     Loop2           : Word;
     Loop1           : Word;
BEGIN
     Loop3 := LENGTH(Buttons^[Number].Title);
     sx1   := Buttons^[Number].x1;
     sy1   := Buttons^[Number].y1;
     TextBackGround(Colour.WindowBackGround);
     FOR Loop1 := sx1 TO sx1+Loop3 DO
     BEGIN
          GotoXY(Loop1,sy1);   WRITE(' ');
          GotoXY(Loop1,sy1+1); WRITE(' ');
     END;
     {BUTTON FACE}
     TextBackGround(7);
     GotoXY(sx1+1,sy1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(sx1+1,sy1);
     TextColor(4);  WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor(0);  WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
END;


PROCEDURE ReleaseButton(Number: Word);
VAR
     Loop2  : Word;
     Loop3  : Word;
BEGIN
     Loop3 := LENGTH(Buttons^[Number].Title);
     {BUTTON FACE}
     TextBackGround(7);
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     FOR Loop2 := 1 TO Loop3 DO WRITE(' ');
     {BUTTON TEXT}
     GotoXY(Buttons^[Number].x1,Buttons^[Number].y1);
     TextColor(4); WRITE(_Mid(Buttons^[Number].Title,1,2));
     TextColor(0); WRITE(_Mid(Buttons^[Number].Title,3,Loop3));
     {BUTTON SHADOW}
     TextColor(0); TextBackGround(Colour.WindowBackGround);
     GotoXY(Buttons^[Number].x1+Loop3,Buttons^[Number].y1);
     WRITE('Ü');
     GotoXY(Buttons^[Number].x1+1,Buttons^[Number].y1+1);
     FOR Loop2 := 1 TO Loop3 DO WRITE('ß');
END;


FUNCTION TimeStrng(Number: Longint): String;
VAR  Hours        : Word;
     Minutes      : Word;
     TotalMinutes : Longint;
     HourStrng    : String;
     MinStrng     : String;
BEGIN
     TotalMinutes := TRUNC(Number/60);
     Hours        := TRUNC(TotalMinutes/60);
     Minutes      := TotalMinutes-(Hours*60);

     STR(Hours,HourStrng);
     STR(Minutes,MinStrng);
     IF LENGTH(HourStrng)=1 THEN HourStrng := '0'+HourStrng;
     IF LENGTH(MinStrng)=1  THEN MinStrng  := MinStrng+'0';
     TimeStrng := HourStrng+MinStrng;
END;


FUNCTION ReturnTime(Number: String): Longint;
VAR  Loop         : Word;
     Hours        : Longint;
     HoursStrng   : String;
     MinStrng     : String;
     Minutes      : Longint;
     Code         : Integer;
     Total        : Longint;
BEGIN
     IF LENGTH(Number)<>4 THEN FOR Loop := LENGTH(Number) TO 3 DO Number := Number+'0';
     HoursStrng := _Mid(Number,1,2);
     MinStrng   := _Mid(Number,3,4);
     VAL(HoursStrng,Hours,Code);
     VAL(MinStrng,Minutes,Code);
     Total := Hours*3600;
     Total := Total+(Minutes*60);
     ReturnTime := Total;
END;


FUNCTION Tags(Worker: Array Of Byte): String;
VAR  Temp : String;
     Loop : Word;
BEGIN
     Temp := '';
     FOR Loop := 0 TO 9 DO
     BEGIN
          IF Worker[Loop]=1 THEN Temp := Temp+'1'
                            ELSE Temp := Temp+'0';
     END;
     Tags := Temp;
END;


FUNCTION FromBoolean(YesNo: Boolean): String;
BEGIN
     IF YesNo=True THEN FromBoolean := '1'
                   ELSE FromBoolean := '0';
END;


FUNCTION ToBoolean(YesNo: String): Boolean;
BEGIN
     IF YesNo='1' THEN ToBoolean := True
                  ELSE ToBoolean := False;
END;


PROCEDURE DisableObject(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Poop            : Word;
BEGIN
     TextBackGround(Colour.WindowBackGround);
     TextColor(11);
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     GotoXY(sx1-1,sy1); WRITE(' ');
     GotoXY(sx2+1,sy1); WRITE(' ');

     TextBackGround(Colour.EditBackGround);
     TextColor(Colour.EditDisabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor(SpaceColour);
          GotoXY(Objects^[Number].x1+2,Objects^[Number].y1);
          WRITE(':');
          TextColor(Colour.EditDisabled);
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditDisabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditDisabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor(Colour.EditDisabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(SpaceColour);
          WRITE('  /  /  ');
          TextColor(Colour.EditDisabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,6));
     END
     ELSE WRITE(Objects^[Number].Stuff);
END;


PROCEDURE EnableObject(Number: Word);
VAR  sx1,sx2,sy1     : Word;
     Poop            : Word;
BEGIN
     EditPos := Length(Objects^[Number].Stuff)+1;
     TextBackGround(Colour.WindowBackGround);
     TextColor(11);
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     GotoXY(sx1-1,sy1); WRITE('[');
     GotoXY(sx2+1,sy1); WRITE(']');
     TextBackGround(Colour.EditBackGround);
     TextColor(Colour.EditEnabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor(SpaceColour);
          GotoXY(Objects^[Number].x1+2,Objects^[Number].y1);
          WRITE(':');
          TextColor(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+5,sy1);
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor(Colour.EditEnabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(SpaceColour);
          WRITE('  /  /  ');
          TextColor(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,6));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+6,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=5 THEN GotoXY(sx1+7,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=6 THEN GotoXY(sx1+8,sy1);
     END
     ELSE WRITE(Objects^[Number].Stuff);
          IF Objects^[Number].ObjectType=5 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=6 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          _ShowCursor
     END
     ELSE _ShowCursor;
END;


PROCEDURE UpdateObject(Number: Word);
VAR  sx1,sx2,sx3,sy1     : Word;
     Loop                : Word;
     Poop                : Word;
     xxx                 : Word;
     yyy                 : Word;
     Temp                : String;
BEGIN
     xxx := WhereX;
     yyy := WhereY;
     _HideCursor;
     sx1 := Objects^[Number].x1;
     sx2 := Objects^[Number].x2;
     sy1 := Objects^[Number].y1;
     TextBackGround(Colour.EditBackGround);
     TextColor(Colour.EditEnabled);
     GotoXY(sx1,sy1);
     IF Objects^[Number].ObjectType=3 THEN
     BEGIN
          TextColor(SpaceColour);
          FOR Loop := sx1 TO sx2 DO WRITE(SpaceChar);
          TextColor(Colour.EditEnabled);
          GotoXY(sx1,sy1); WRITE(_Mid(Objects^[Number].Stuff,1,2));
          TextColor(SpaceColour);
          GotoXY(sx1+2,sy1); WRITE(':');
          TextColor(Colour.EditEnabled);
          GotoXY(sx1+3,sy1); WRITE(_Mid(Objects^[Number].Stuff,3,4));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+5,sy1);
     END
     ELSE IF Objects^[Number].ObjectType=5 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('MALE  ')
                                       ELSE WRITE('FEMALE');
     END
     ELSE IF Objects^[Number].ObjectType=6 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(Colour.EditEnabled);
          IF Objects^[Number].Stuff='1' THEN WRITE('YES')
                                       ELSE WRITE('NO ');
     END
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          FOR Poop := 1 TO 10 DO
          BEGIN
               IF Objects^[Number].Stuff[Poop]='1' THEN
               BEGIN
                    TextColor(Colour.EditEnabled);
                    WRITE(CHR(254));
               END
               ELSE
               BEGIN
                    TextColor(SpaceColour);
                    WRITE(SpaceChar);
               END;
          END;
     END
     ELSE IF Objects^[Number].ObjectType=4 THEN
     BEGIN
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          TextColor(SpaceColour);
          WRITE('  /  /  ');
          TextColor(Colour.EditEnabled);
          GotoXY(Objects^[Number].x1,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,1,2));
          GotoXY(Objects^[Number].x1+3,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,3,4));
          GotoXY(Objects^[Number].x1+6,Objects^[Number].y1);
          WRITE(_Mid(Objects^[Number].Stuff,5,6));
               IF LENGTH(Objects^[Number].Stuff)=0 THEN GotoXY(sx1+0,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=1 THEN GotoXY(sx1+1,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=2 THEN GotoXY(sx1+3,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=3 THEN GotoXY(sx1+4,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=4 THEN GotoXY(sx1+6,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=5 THEN GotoXY(sx1+7,sy1)
          ELSE IF LENGTH(Objects^[Number].Stuff)=6 THEN GotoXY(sx1+8,sy1);
     END
     ELSE
     BEGIN
          WRITE(Objects^[Number].Stuff);
          sx3 := WhereX;
          TextColor(SpaceColour);
          IF sx3<=sx2 THEN FOR Loop := sx3 TO sx2 DO WRITE(SpaceChar);
          GotoXY(sx3,sy1);
     END;
          IF Objects^[Number].ObjectType=5 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=6 THEN _HideCursor
     ELSE IF Objects^[Number].ObjectType=7 THEN
     BEGIN
          GotoXY(xxx,yyy);
          _ShowCursor;
     END
     ELSE _ShowCursor;
END;


FUNCTION DoObjects: Word;
VAR  OuttaHere    : Boolean;
     x1,x2,y1     : Word;
     CursorX      : Word;
     c            : Char;
     work         : Word;
     TagNumber    : Word;
     OldX         : Word;
     OldY         : Word;
     LeftBox      : Boolean;
     xx1,yy1,xx2  : Word;
     FirstPart    : String;
     LastPart     : String;
LABEL               MoveDown,Finished;
LABEL               ToggleGender,ToggleTags;
BEGIN
     CurrentObject   := 1;
     OuttaHere       := False;

     IF NumberOfObjects=0 THEN
     BEGIN
          DoingInputField := False;
          EnableButton(CurrentObject);
          _HideCursor;
     END
     ELSE
     BEGIN
          DoingInputField := True;
          EnableObject(CurrentObject);
     END;

     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     CASE ORD(c) OF
                     71:  BEGIN {HOME}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    EditPos := 1;
                                    GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                               END;
                          END;
                     15,
                     72 : BEGIN
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    DEC(CurrentObject);
                                    IF CurrentObject=0 THEN
                                    BEGIN
                                         CurrentObject   := NumberOfButtons;
                                         DoingInputField := False;
                                         _HideCursor;
                                         EnableButton(CurrentObject);
                                    END
                                    ELSE EnableObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DEC(CurrentObject);
                                    IF CurrentObject=0 THEN
                                    BEGIN
                                         IF NumberOfObjects=0 THEN
                                         BEGIN
                                              CurrentObject   := NumberOfButtons;
                                              DoingInputField := False;
                                              EnableButton(CurrentObject);
                                         END
                                         ELSE
                                         BEGIN
                                              CurrentObject   := NumberOfObjects;
                                              DoingInputField := True;
                                              EnableObject(CurrentObject);
                                         END;
                                    END
                                    ELSE EnableButton(CurrentObject);
                               END;
                          END;
                     80 : GOTO MoveDown;
                     75 : BEGIN {LEFT ARROW}
                               IF (Objects^[CurrentObject].ObjectType=7) THEN
                               BEGIN
                                    Work := WhereX;
                                    IF Work>Objects^[CurrentObject].x1 THEN
                                    BEGIN
                                         DEC(Work);
                                         GotoXY(Work,Objects^[CurrentObject].y1);
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF (EditPos>1) THEN
                                    BEGIN
                                         DEC(EditPos);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     77 : BEGIN {RIGHT ARROW}
                               IF (Objects^[CurrentObject].ObjectType=7) THEN
                               BEGIN
                                    Work := WhereX;
                                    IF Work<(Objects^[CurrentObject].x1+9) THEN
                                    BEGIN
                                         INC(Work);
                                         GotoXY(Work,Objects^[CurrentObject].y1);
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF (EditPos<Length(Objects^[CurrentObject].Stuff)+1) THEN
                                    BEGIN
                                         INC(EditPos);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     79:  BEGIN {END}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    EditPos := Length(Objects^[CurrentObject].Stuff)+1;
                                    GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                               END;
                          END;
                     83 : BEGIN {DELETE}
                               IF ((Objects^[CurrentObject].ObjectType=1) OR
                                  (Objects^[CurrentObject].ObjectType=2)) THEN
                               BEGIN
                                    IF LENGTH(Objects^[CurrentObject].Stuff)=1 THEN
                                    BEGIN
                                         EditPos := 1;
                                         Objects^[CurrentObject].Stuff := '';
                                         UpdateObject(CurrentObject);
                                    END
                                    ELSE
                                    BEGIN
                                         FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                         LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos+1,
                                                           Length(Objects^[CurrentObject].Stuff));
                                         Objects^[CurrentObject].Stuff := FirstPart+LastPart;
                                         UpdateObject(CurrentObject);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END;
                          END;
                     ELSE BEGIN
                               IF NumberOfButtons<>0 THEN
                               BEGIN
                                    FOR Work := 1 TO NumberOfButtons DO
                                    BEGIN
                                         IF ((Buttons^[Work].cc1=1) AND (Buttons^[Work].cc2=ORD(c))) THEN
                                         BEGIN
                                              IF DoingInputField THEN
                                              BEGIN
                                                   DisableObject(CurrentObject);
                                                   DoObjects := Work;
                                                   OuttaHere := True;
                                              END
                                              ELSE
                                              BEGIN
                                                   DisableButton(CurrentObject);
                                                   DoObjects := Work;
                                                   OuttaHere := True;
                                              END;
                                         END;
                                    END;
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE ORD(c) OF
                     8  : IF ((Objects^[CurrentObject].ObjectType<5) AND (DoingInputField)) THEN
                          BEGIN {BACKSPACE}
                               IF LENGTH(Objects^[CurrentObject].Stuff)=1 THEN
                               BEGIN
                                    EditPos := 1;
                                    Objects^[CurrentObject].Stuff := '';
                                    UpdateObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    IF ((Objects^[CurrentObject].ObjectType=1) OR
                                       (Objects^[CurrentObject].ObjectType=2)) THEN
                                    BEGIN
                                         IF (EditPos>1) THEN
                                         BEGIN
                                              FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-2);
                                              LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                                           Length(Objects^[CurrentObject].Stuff));
                                              Objects^[CurrentObject].Stuff := FirstPart+LastPart;
                                              UpdateObject(CurrentObject);
                                              DEC(EditPos);
                                              GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                         END;
                                    END
                                    ELSE
                                    BEGIN
                                         IF LENGTH(Objects^[CurrentObject].Stuff)>0 THEN
                                         BEGIN
                                              Objects^[CurrentObject].Stuff := _Mid(Objects^[CurrentObject].Stuff,1,
                                                                              Length(Objects^[CurrentObject].Stuff)-1);
                                              UpdateObject(CurrentObject);
                                         END;
                                    END;
                               END;
                          END;
                     9  : BEGIN {TAB}
                               MoveDown:
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    INC(CurrentObject);
                                    IF CurrentObject>NumberOfObjects THEN
                                    BEGIN
                                         CurrentObject   := 1;
                                         DoingInputField := False;
                                         _HideCursor;
                                         EnableButton(CurrentObject);
                                    END
                                    ELSE EnableObject(CurrentObject);
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    INC(CurrentObject);
                                    IF CurrentObject>NumberOfButtons THEN
                                    BEGIN
                                         IF NumberOfObjects=0 THEN
                                         BEGIN
                                              CurrentObject   := 1;
                                              DoingInputField := False;
                                              EnableButton(CurrentObject);
                                         END
                                         ELSE
                                         BEGIN
                                              CurrentObject   := 1;
                                              DoingInputField := True;
                                              EnableObject(CurrentObject);
                                         END;
                                    END
                                    ELSE EnableButton(CurrentObject);
                               END;
                          END;
                     13 : BEGIN
                               IF DoingInputField THEN
                               BEGIN
                                    GOTO MoveDown;
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DoObjects := CurrentObject;
                                    OuttaHere := True;
                               END;
                          END;
                     27 : BEGIN
                               Finished:
                               IF DoingInputField THEN
                               BEGIN
                                    DisableObject(CurrentObject);
                                    DoObjects := 1;
                                    OuttaHere := True;
                               END
                               ELSE
                               BEGIN
                                    DisableButton(CurrentObject);
                                    DoObjects := 1;
                                    OuttaHere := True;
                               END;
                          END;
                     127: IF ((Objects^[CurrentObject].ObjectType<5) AND (DoingInputField)) THEN
                          BEGIN
                               EditPos := 1;
                               Objects^[CurrentObject].Stuff := '';
                               UpdateObject(CurrentObject);
                          END;
                     ELSE IF ((ORD(c)>31) AND (Ord(c)<128)) THEN
                          BEGIN
                               IF (Objects^[CurrentObject].ObjectType=1) THEN
                               BEGIN
                                    IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                    BEGIN
                                         FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                         LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                                           Length(Objects^[CurrentObject].Stuff));
                                         Objects^[CurrentObject].Stuff := FirstPart+C+LastPart;
                                         UpdateObject(CurrentObject);
                                         INC(EditPos);
                                         GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                    END;
                               END
                               ELSE IF (Objects^[CurrentObject].ObjectType=2) THEN
                               BEGIN
                                    IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                                    BEGIN
                                         IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                         BEGIN
                                              FirstPart := _Mid(Objects^[CurrentObject].Stuff,1,EditPos-1);
                                              LastPart  := _Mid(Objects^[CurrentObject].Stuff,EditPos,
                                                           Length(Objects^[CurrentObject].Stuff));
                                              Objects^[CurrentObject].Stuff := FirstPart+C+LastPart;
                                              UpdateObject(CurrentObject);
                                              INC(EditPos);
                                              GotoXY(Objects^[CurrentObject].x1+EditPos-1,Objects^[CurrentObject].y1);
                                         END;
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType>2) AND
                                       (Objects^[CurrentObject].ObjectType<5)) THEN
                               BEGIN
                                    IF ((ORD(c)>47) AND (ORD(c)<58)) THEN
                                    BEGIN
                                         IF LENGTH(Objects^[CurrentObject].Stuff)<Objects^[CurrentObject].ObjectLength THEN
                                         BEGIN
                                              Objects^[CurrentObject].Stuff := Objects^[CurrentObject].Stuff+C;
                                              UpdateObject(CurrentObject);
                                         END;
                                    END;
                               END
                               ELSE IF ((Objects^[CurrentObject].ObjectType=5) OR
                                       (Objects^[CurrentObject].ObjectType=6)) THEN
                               BEGIN
                                    IF ORD(c)=32 THEN
                                    BEGIN
                                         ToggleGender:
                                         IF Objects^[CurrentObject].Stuff='1' THEN Objects^[CurrentObject].Stuff := '0'
                                                                             ELSE Objects^[CurrentObject].Stuff := '1';
                                         UpdateObject(CurrentObject);
                                         _Delay(200);
                                    END;
                               END
                               ELSE IF (Objects^[CurrentObject].ObjectType=7) THEN
                               BEGIN
                                    ToggleTags:
                                    TagNumber := (WhereX-Objects^[CurrentObject].x1)+1;
                                    IF Objects^[CurrentObject].Stuff[TagNumber]='1'
                                       THEN Objects^[CurrentObject].Stuff[TagNumber] := '0'
                                       ELSE Objects^[CurrentObject].Stuff[TagNumber] := '1';
                                    UpdateObject(CurrentObject);
                                    _Delay(200);
                               END;
                          END;
                     END;
                END;
           END;
     UNTIL OuttaHere;
     _HideCursor;
END;


{Unpacks DateTime record into a MMDDYY string}
FUNCTION UnpackedDate(Work: Longint): String;
VAR  DT       : DateTime;
     DD,MM,YY : String;
BEGIN
     UnpackTime(Work,DT);
     WITH DT DO
     BEGIN
          DD := _String(Day);
          MM := _String(Month);
          YY := _String(Year-1900);
     END;
     IF Length(MM)=1 THEN MM := '0'+MM;
     IF Length(DD)=1 THEN DD := '0'+DD;
     IF Length(YY)=1 THEN YY := '0'+YY;
     UnpackedDate := MM+DD+YY;
END;


{Unpacks DateTime record into a MM-DD-YY string}
FUNCTION UnpackedDate2(Work: Longint): String;
VAR  DT       : DateTime;
     DD,MM,YY : String;
BEGIN
     UnpackTime(Work,DT);
     WITH DT DO
     BEGIN
          DD := _String(Day);
          MM := _String(Month);
          YY := _String(Year-1900);
     END;
     IF Length(MM)=1 THEN MM := '0'+MM;
     IF Length(DD)=1 THEN DD := '0'+DD;
     IF Length(YY)=1 THEN YY := '0'+YY;
     UnpackedDate2 := MM+'-'+DD+'-'+YY;
END;


FUNCTION PackedDate(InString: String): Longint;
VAR  WorkTime : Longint;
     DT       : DateTime;
BEGIN
     FillChar(DT,SizeOf(DT),0);
     WITH DT DO
     BEGIN
          Year  := _Numeric(_Mid(InString,5,6))+1900;
          Month := _Numeric(_Mid(InString,1,2));
          Day   := _Numeric(_Mid(InString,3,4));
     END;
     PackTime(DT,WorkTime);
     PackedDate := WorkTime;
END;


PROCEDURE EditTheUsersAccount;
VAR  Loop         : Word;
BEGIN
     Colour.MenuBorder              := 0;
     Colour.MenuBackGround          := 7;
     Colour.MenuForeGround          := 0;
     Colour.MenuHotKey              := 4;
     Colour.MenuHighLightBackGround := 2;
     Colour.MenuHighLightForeGround := 0;
     Colour.MenuHighLightHotKey     := 4;
     Colour.DeskTopColour           := 9;
     Colour.WindowBackGround        := 1;
     Colour.WindowFrame             := 9;
     Colour.WindowHeader            := 3;
     Colour.WindowHeaderText        := 0;
     Colour.EditDisabled            := 7;
     Colour.EditEnabled             := 14;
     Colour.EditBackGround          := 0;
     _HideCursor;
     New(Buttons);
     New(Objects);
     DrawWindow(1,1,80,25,'USER - '+UserRecord.Name);
     AddObject(18,3,1,30,UserRecord.name,True);
     AddObject(18,4,1,30,UserRecord.alias,True);
     AddObject(18,5,1,20,UserRecord.password,True);
     AddObject(18,6,1,30,UserRecord.street,True);
     AddObject(18,7,1,30,UserRecord.city,True);
     AddObject(18,8,1,30,UserRecord.prov,True);
     AddObject(18,9,1,30,UserRecord.country,True);
     AddObject(18,10,1,20,UserRecord.postal,True);
     AddObject(18,11,1,20,UserRecord.voice,True);
     AddObject(18,12,1,20,UserRecord.data,True);
     AddObject(18,13,1,30,UserRecord.bbs,True);
     AddObject(18,14,1,20,UserRecord.bbs_phone,True);
     AddObject(18,15,1,20,UserRecord.bbs_net,True);
     AddObject(18,16,4,6,UserRecord.Birth,True);
     AddObject(18,17,5,6,_String(UserRecord.Sex),True);
     AddObject(18,18,4,6,UnpackedDate(UserRecord.first_call),True);
     AddObject(18,19,4,6,UnpackedDate(UserRecord.last_call),True);
     AddObject(18,20,2,9,_String(UserRecord.Total_Calls),True);
     AddObject(68,3,6,3,_String(UserRecord.PageFlag),True);
     AddObject(68,4,6,3,_String(UserRecord.UserList),True);
     AddObject(68,5,6,3,_String(UserRecord.Ver_User),True);
     AddObject(68,6,6,3,_String(UserRecord.Page),True);
     AddObject(68,7,6,3,_String(UserRecord.Punt),True);
     AddObject(68,8,2,9,_String(UserRecord.uploads),True);
     AddObject(68,9,2,9,_String(UserRecord.DLBytesToday),True);
     AddObject(68,10,2,9,_String(UserRecord.dl_total),True);
     AddObject(68,11,2,9,_String(UserRecord.files_uploaded),True);
     AddObject(68,12,2,9,_String(UserRecord.files_downloaded),True);
     AddObject(68,13,2,9,_String(Trunc(UserRecord.SecondsInBank/60)),True);
     AddObject(68,14,2,9,_String(UserRecord.ByteBankBalance),True);
     AddObject(68,15,2,9,_String(Trunc(UserRecord.SecondsRemaining/60)),True);
     AddObject(68,16,2,5,_String(UserRecord.Security),True);
     AddObject(68,17,7,10,Tags(UserRecord.Tags),True);
     AddObject(7,24,1,60,UserRecord.Note,True);
     AddButton(70,23,' DONE ',True,1,32);
     DrawObjects;
     DrawButtons;
     TextBackGround(Colour.WindowBackGround);
     TextColor(9);
     GotoXY(2,22);  WRITE('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ');
     TextColor(11);
     GotoXY(3,3);   WRITE('NameÄÂÄÄÄReal');
     GotoXY(3,4);   WRITE('     ÀÄÄAlias');
     GotoXY(3,5);   WRITE('     Password');
     GotoXy(3,6);   WRITE('       Street');
     GotoXy(3,7);   WRITE('    City/Town');
     GotoXy(3,8);   WRITE('   Prov/State');
     GotoXy(3,9);   WRITE('      Country');
     GotoXy(3,10);  WRITE('   Postal/Zip');
     GotoXy(3,11);  WRITE('PhoneÄÂÄVoice');
     GotoXy(3,12);  WRITE('      ÀÄÄData');
     GotoXY(3,13);  WRITE('BBSÄÂÄÄÄÄName');
     GotoXY(3,14);  WRITE('    ÃÄÄÄPhone');
     GotoXY(3,15);  WRITE('    ÀÄAddress');
     GotoXY(3,16);  WRITE('   Birth Date');
     GotoXY(3,17);  WRITE('       Gender');
     GotoXY(3,18);  WRITE('CallsÄÂÄFirst');
     GotoXY(3,19);  WRITE('      ÃÄÄLast');
     GotoXY(3,20);  WRITE('      ÀÄTotal');
     GotoXY(50,3);  WRITE('    Can Be Paged');
     GotoXY(50,4);  WRITE('     In Userlist');
     GotoXY(50,5);  WRITE('     Is Verified');
     GotoXY(50,6);  WRITE('  Can Page Sysop');
     GotoXY(50,7);  WRITE('      Locked Out');
     GotoXY(50,8);  WRITE('  Bytes Uploaded');
     GotoXY(50,9);  WRITE('DL BytesÄÂÄToday');
     GotoXY(50,10); WRITE('         ÀÄTotal');
     GotoXY(50,11); WRITE('FilesÄÂÄÄÄUpload');
     GotoXY(50,12); WRITE('      ÀÄDownload');
     GotoXY(50,13); WRITE('BankÄÂÄÄÄMinutes');
     GotoXY(50,14); WRITE('     ÀÄÄÄÄÄBytes');
     GotoXY(50,15); WRITE('    Minutes Left');
     GotoXY(50,16); WRITE('AccessÄÂÄÄÄLevel');
     GotoXY(50,17); WRITE('       ÀÄÄÄÄTags');
     GotoXY(7,23);  WRITE('General comment about this user:');
     REPEAT
     UNTIL DoObjects=1;
     ClearObjects;
     ClearButtons;
     UserRecord.name             := Objects^[1].Stuff;
     UserRecord.alias            := Objects^[2].Stuff;
     UserRecord.password         := _UpperCase(Objects^[3].Stuff);
     UserRecord.street           := Objects^[4].Stuff;
     UserRecord.city             := Objects^[5].Stuff;
     UserRecord.prov             := Objects^[6].Stuff;
     UserRecord.country          := Objects^[7].Stuff;
     UserRecord.postal           := Objects^[8].Stuff;
     UserRecord.voice            := Objects^[9].Stuff;
     UserRecord.data             := Objects^[10].Stuff;
     UserRecord.bbs              := Objects^[11].Stuff;
     UserRecord.bbs_phone        := Objects^[12].Stuff;
     UserRecord.bbs_net          := Objects^[13].Stuff;
     UserRecord.Birth            := Objects^[14].Stuff;
     UserRecord.Sex              := _Numeric(Objects^[15].Stuff);
     UserRecord.first_call       := PackedDate(Objects^[16].Stuff);
     UserRecord.last_call        := PackedDate(Objects^[17].Stuff);
     UserRecord.Total_Calls      := _Numeric(Objects^[18].Stuff);
     UserRecord.PageFlag         := _Numeric(Objects^[19].Stuff);
     UserRecord.UserList         := _Numeric(Objects^[20].Stuff);
     UserRecord.Ver_User         := _Numeric(Objects^[21].Stuff);
     UserRecord.Page             := _Numeric(Objects^[22].Stuff);
     UserRecord.Punt             := _Numeric(Objects^[23].Stuff);
     UserRecord.uploads          := _Numeric(Objects^[24].Stuff);
     UserRecord.DLBytesToday     := _Numeric(Objects^[25].Stuff);
     UserRecord.dl_total         := _Numeric(Objects^[26].Stuff);
     UserRecord.files_uploaded   := _Numeric(Objects^[27].Stuff);
     UserRecord.files_downloaded := _Numeric(Objects^[28].Stuff);
     UserRecord.SecondsInBank    := _Numeric(Objects^[29].Stuff)*60;
     UserRecord.ByteBankBalance  := _Numeric(Objects^[30].Stuff);
     UserRecord.SecondsRemaining := _Numeric(Objects^[31].Stuff)*60;
     UserRecord.Security         := _Numeric(Objects^[32].Stuff);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[33].Stuff[Loop]='1' THEN UserRecord.Tags[Loop] := 1
                                          ELSE UserRecord.Tags[Loop] := 0;
     END;
     UserRecord.Note             := Objects^[34].Stuff;
     Dispose(Buttons);
     Dispose(Objects);
     _ShowCursor;
     TextColor(7);
     TextBackGround(0);
END;


END.
