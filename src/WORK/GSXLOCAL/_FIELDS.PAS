{$I DEFINES.INC}
UNIT _Fields;


INTERFACE


USES Globals,Gunshot;


PROCEDURE SystemField        (Raw: _Raw_File);
PROCEDURE ChangeField        (Number: Word);
PROCEDURE DrawEnabledField   (Num: Word);
PROCEDURE FieldText          (Index: Word; InString: String);
PROCEDURE RedrawField;
PROCEDURE DrawFields;


IMPLEMENTATION


USES _Convert,_Text,_Win,Gr2_Bp,Dates,BsString;


{==========================================================================}
{                                                                          }
{         PLACES AN ENTRY FIELD ON THE SCREEN FOR HANDLING - DOES NOT      }
{         DRAW THE BACKGROUND, JUST THE TEXT & DEFINES THE REST.           }
{                                                                          }
{==========================================================================}
PROCEDURE SystemField(Raw: _Raw_File);
VAR  x1,y1,
     x2,y2 : Word;
BEGIN
     FieldNum := 1;
     IF NFields=15 THEN Exit;
     INC(NFields);
     IF NFields=1
        THEN Fields^[NFields].Active := True
        ELSE Fields^[NFields].Active := False;
     Fields^[NFields].EntryType      := Raw.Colour4;
     Fields^[NFields].Length         := GetStringWidth(Raw.Colour4);
     Fields^[NFields].x1             := Raw.x1;
     Fields^[NFields].y1             := Raw.y1;
     Fields^[NFields].x2             := Raw.x1+(Fields^[NFields].Length*8)+20;
     Fields^[NFields].y2             := Raw.y1+20;
     Fields^[NFields].TextBack       := Raw.Colour1;
     Fields^[NFields].TextEnabled    := Raw.Colour2;
     Fields^[NFields].TextDisabled   := Raw.Colour3;
     Fields^[NFields].Text           := '';
     CASE Raw.Colour4 OF
     1:   Fields^[NFields].Text := UserRecord.Name;      {user's real name}
     2:   Fields^[NFields].Text := UserRecord.Alias;     {user's alias}
     3:   Fields^[NFields].Text := UserRecord.Password;  {user's password}
     4:   Fields^[NFields].Text := TranslateDate1(UserRecord.birth[1]+UserRecord.birth[2]+'/'+
                                   UserRecord.birth[3]+UserRecord.birth[4]+'/'+
                                   UserRecord.birth[5]+UserRecord.birth[6]); {user's birthdate}
     5:   Fields^[NFields].Text := UserRecord.Street;    {user's street address}
     6:   Fields^[NFields].Text := UserRecord.City;      {user's city}
     7:   Fields^[NFields].Text := UserRecord.Prov;      {user's province}
     8:   Fields^[NFields].Text := UserRecord.Country;   {user's country}
     9:   Fields^[NFields].Text := UserRecord.Postal;    {user's postal code}
     10:  Fields^[NFields].Text := UserRecord.Data;      {user's data phone}
     11:  Fields^[NFields].Text := UserRecord.Voice;     {user's voice phone}
     16:  Fields^[NFields].Text := _String(UserRecord.File_Lines); {# file display lines}
     18:  Fields^[NFields].Text := '  /  /  ';
     28:  Fields^[NFields].Text := UserRecord.BBS;       {Users BBS Name}
     29:  Fields^[NFields].Text := UserRecord.BBS_Net;   {Users BBS Address}
     30:  Fields^[NFields].Text := UserRecord.BBS_Phone; {Users BBS Phone Number}
     31:  Fields^[NFields].Text := UserRecord.Note;      {Users Comment}
     END;
     IF (LENGTH(Fields^[NFields].Text)>Fields^[NFields].Length)
        THEN Fields^[NFields].Text[0] := Chr(Fields^[NFields].Length);
     {Special Case For Dates}
     IF ((Fields^[NFields].EntryType=4) OR (Fields^[NFields].EntryType=18)) THEN
     BEGIN
          Fields^[NFields].CursorPos := 1;
     END
     ELSE Fields^[NFields].CursorPos := Length(Fields^[NFields].Text)+1;
     GrSetFillStyle(GrFSolid,Fields^[NFields].TextBack,GrOpaque);
     GrDrawRect(Fields^[NFields].x1,Fields^[NFields].y1,
                Fields^[NFields].x2,Fields^[NFields].y2,GrFill);
END;
{==========================================================================}
{                                                                          }
{         ADVANCES TO THE NEXT, PREVIOUS OR RANDOM FIELD                   }
{                                                                          }
{==========================================================================}
PROCEDURE ChangeField(Number: Word);
VAR  x2,y2 : Word;
     Temp  : String;
BEGIN
     IF NFields<=1 THEN Exit;
     {First, kill the last one}
     Fields^[FieldNum].Active := False;
     GrSetColor(Fields^[FieldNum].TextBack);
     GrDrawRect(Fields^[FieldNum].x1,Fields^[FieldNum].y1,
                Fields^[FieldNum].x2,Fields^[FieldNum].y2,GrOutline);
     GrDrawRect(Fields^[FieldNum].x1+1,Fields^[FieldNum].y1+1,
                Fields^[FieldNum].x2-1,Fields^[FieldNum].y2-1,GrOutline);
     IF Fields^[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields^[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields^[FieldNum].Text));
          OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextDisabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Temp,Fields^[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextDisabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Fields^[FieldNum].Text,Fields^[FieldNum].Length+1));
     {Set the new one active}
     FieldNum                  := Number;
     Fields^[FieldNum].Active  := True;
     {Special Case For Dates}
     IF ((Fields^[FieldNum].EntryType=4) OR (Fields^[FieldNum].EntryType=18)) THEN
     BEGIN
          Fields^[FieldNum].CursorPos := 1;
     END
     ELSE Fields^[FieldNum].CursorPos := LENGTH(Fields^[FieldNum].Text)+1;
     {Draw it out}
     DrawEnabledField(FieldNum);
     IF Fields^[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields^[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields^[FieldNum].Text));
          OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextEnabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Temp,Fields^[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextEnabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Fields^[FieldNum].Text,Fields^[FieldNum].Length+1));
     OutTextXY(Fields^[FieldNum].x1+9+((Fields^[FieldNum].CursorPos-1)*8),
               Fields^[FieldNum].y1+3,Fields^[FieldNum].TextEnabled,255,2,'_');
END;
{==========================================================================}
{                                                                          }
{         DRAWS OUT THE SYSTEM FIELDS ON THE SCREEN                        }
{                                                                          }
{==========================================================================}
PROCEDURE DrawEnabledField(Num: Word);
BEGIN
     InvertedBox(Fields^[Num].x1,Fields^[Num].y1,
                 Fields^[Num].x2,Fields^[Num].y2);
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrDrawRect(Fields^[Num].x1+1,Fields^[Num].y1+1,
                Fields^[Num].x2-1,Fields^[Num].y2-1,GrOutline);
     GrSetLineStyle(GrLSolid,1);
END;
{==========================================================================}
{                                                                          }
{         REDRAWS A FIELD AFTER EDITING                                    }
{                                                                          }
{==========================================================================}
PROCEDURE RedrawField;
VAR  Temp : String;
BEGIN
     IF Fields^[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields^[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields^[FieldNum].Text));
          OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextEnabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Temp,Fields^[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields^[FieldNum].x1+9,
                    Fields^[FieldNum].y1+3,
                    Fields^[FieldNum].TextEnabled,
                    Fields^[FieldNum].TextBack,2,
                    _PadRight(Fields^[FieldNum].Text,Fields^[FieldNum].Length+1));
     OutTextXY(Fields^[FieldNum].x1+9+((Fields^[FieldNum].CursorPos-1)*8),
               Fields^[FieldNum].y1+3,
               Fields^[FieldNum].TextEnabled,255,2,'_');
END;


PROCEDURE DrawFields;
VAR  Loop : Word;
     Temp : String;
BEGIN
     FOR Loop := 1 TO NFields DO
     BEGIN
          IF Loop=FieldNum THEN
          BEGIN
               DrawEnabledField(Loop);
               IF Fields^[Loop].EntryType=3 THEN
               BEGIN
                    FillChar(Temp,Length(Fields^[Loop].Text)+1,#254);
                    Temp[0] := Chr(Length(Fields^[Loop].Text));
                    OutTextXY(Fields^[Loop].x1+9,
                              Fields^[Loop].y1+3,
                              Fields^[Loop].TextEnabled,
                              Fields^[Loop].TextBack,2,
                              _PadRight(Temp,Fields^[Loop].Length+1));
               END
               ELSE OutTextXY(Fields^[Loop].x1+9,
                              Fields^[Loop].y1+3,
                              Fields^[Loop].TextEnabled,
                              Fields^[Loop].TextBack,2,
                              _PadRight(Fields^[Loop].Text,Fields^[Loop].Length+1));
               OutTextXY(Fields^[Loop].x1+9+((Fields^[Loop].CursorPos-1)*8),
                         Fields^[Loop].y1+3,
                         Fields^[Loop].TextEnabled,255,2,'_');
          END
          ELSE
          BEGIN
               GrSetColor(Fields^[Loop].TextBack);
               GrDrawRect(Fields^[Loop].x1,Fields^[Loop].y1,
                          Fields^[Loop].x2,Fields^[Loop].y2,GrOutline);
               GrDrawRect(Fields^[Loop].x1+1,Fields^[Loop].y1+1,
                          Fields^[Loop].x2-1,Fields^[Loop].y2-1,GrOutline);
               IF Fields^[Loop].EntryType=3 THEN
               BEGIN
                    FillChar(Temp,Length(Fields^[Loop].Text)+1,#254);
                    Temp[0] := Chr(Length(Fields^[Loop].Text));
                    OutTextXY(Fields^[Loop].x1+9,
                              Fields^[Loop].y1+3,
                              Fields^[Loop].TextDisabled,
                              Fields^[Loop].TextBack,2,
                              Temp);
               END
               ELSE OutTextXY(Fields^[Loop].x1+9,
                              Fields^[Loop].y1+3,
                              Fields^[Loop].TextDisabled,
                              Fields^[Loop].TextBack,2,
                              Fields^[Loop].Text);
          END;
     END;
END;


PROCEDURE FieldText(Index: Word; InString: String);
VAR  BBytesSent : Word;
BEGIN
     IF LENGTH(InString)>Fields^[Index].Length THEN
        InString := _Mid(InString,1,Fields^[Index].Length);
     Fields^[Index].Text := InString;
     CASE Fields^[Index].EntryType OF
     4:   Fields^[Index].CursorPos := 1;
     18:  Fields^[Index].CursorPos := 1;
     ELSE Fields^[Index].CursorPos := Length(Fields^[Index].Text)+1;
     END;
END;


END.
