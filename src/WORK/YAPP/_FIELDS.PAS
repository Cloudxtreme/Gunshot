{$I DEFINES.INC}
UNIT _Fields;


INTERFACE


USES Gunshot;


PROCEDURE SystemField        (Raw: _Raw_File);
PROCEDURE ChangeField        (Number: Word);
PROCEDURE DrawEnabledField   (Num: Word);
PROCEDURE RedrawField;
PROCEDURE DrawFields;


IMPLEMENTATION


USES _Win,Gr2_Bp,_Text,GfxProto,_Convert,BsString,Globals;


PROCEDURE DrawEnabledField(Num: Word);
BEGIN
     InvertedBox(Fields[Num].x1,Fields[Num].y1,Fields[Num].x2,Fields[Num].y2);
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrDrawRect(Fields[Num].x1+1,Fields[Num].y1+1,Fields[Num].x2-1,Fields[Num].y2-1,GrOutline);
     GrSetLineStyle(GrLSolid,1);
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
               IF Fields[Loop].EntryType=3 THEN
               BEGIN
                    FillChar(Temp,Length(Fields[Loop].Text)+1,#254);
                    Temp[0] := Chr(Length(Fields[Loop].Text));
                    OutTextXY(Fields[Loop].x1+9,Fields[Loop].y1+3,
                              Fields[Loop].TextEnabled,Fields[Loop].TextBack,2,
                              _PadRight(Temp,Fields[Loop].Length+1));
               END
               ELSE OutTextXY(Fields[Loop].x1+9,Fields[Loop].y1+3,
                              Fields[Loop].TextEnabled,Fields[Loop].TextBack,2,
                              _PadRight(Fields[Loop].Text,Fields[Loop].Length+1));
               OutTextXY(Fields[Loop].x1+9+((Fields[Loop].CursorPos-1)*8),
                         Fields[Loop].y1+3,Fields[Loop].TextEnabled,255,2,'_');
          END
          ELSE
          BEGIN
               GrSetColor(Fields[Loop].TextBack);
               GrDrawRect(Fields[Loop].x1,Fields[Loop].y1,Fields[Loop].x2,Fields[Loop].y2,GrOutline);
               GrDrawRect(Fields[Loop].x1+1,Fields[Loop].y1+1,Fields[Loop].x2-1,Fields[Loop].y2-1,GrOutline);
               IF Fields[Loop].EntryType=3 THEN
               BEGIN
                    FillChar(Temp,Length(Fields[Loop].Text)+1,#254);
                    Temp[0] := Chr(Length(Fields[Loop].Text));
                    OutTextXY(Fields[Loop].x1+9,Fields[Loop].y1+3,
                              Fields[Loop].TextDisabled,Fields[Loop].TextBack,2,
                              Temp);
               END
               ELSE OutTextXY(Fields[Loop].x1+9,Fields[Loop].y1+3,
                              Fields[Loop].TextDisabled,Fields[Loop].TextBack,2,
                              Fields[Loop].Text);
          END;
     END;
END;


PROCEDURE ChangeField(Number: Word);
VAR  x2,y2 : Word;
     Temp  : String;
BEGIN
     IF NFields<=1 THEN Exit;
     {First, kill the last one}
     Fields[FieldNum].Active := False;
     GrSetColor(Fields[FieldNum].TextBack);
     GrDrawRect(Fields[FieldNum].x1,Fields[FieldNum].y1,Fields[FieldNum].x2,Fields[FieldNum].y2,GrOutline);
     GrDrawRect(Fields[FieldNum].x1+1,Fields[FieldNum].y1+1,Fields[FieldNum].x2-1,Fields[FieldNum].y2-1,GrOutline);
     IF Fields[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields[FieldNum].Text));
          OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextDisabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Temp,Fields[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextDisabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Fields[FieldNum].Text,Fields[FieldNum].Length+1));
     {Set the new one active}
     FieldNum                := Number;
     Fields[FieldNum].Active := True;
     {Special Case For Dates}
     IF ((Fields[FieldNum].EntryType=4) OR (Fields[FieldNum].EntryType=18))
        THEN Fields[FieldNum].CursorPos := 1
        ELSE Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
     {Draw it out}
     DrawEnabledField(FieldNum);
     IF Fields[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields[FieldNum].Text));
          OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Temp,Fields[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Fields[FieldNum].Text,Fields[FieldNum].Length+1));
     OutTextXY(Fields[FieldNum].x1+9+((Fields[FieldNum].CursorPos-1)*8),
               Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,255,2,'_');
END;


PROCEDURE RedrawField;
VAR  Temp : String;
BEGIN
     IF Fields[FieldNum].EntryType=3 THEN
     BEGIN
          FillChar(Temp,Length(Fields[FieldNum].Text)+1,#254);
          Temp[0] := Chr(Length(Fields[FieldNum].Text));
          OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Temp,Fields[FieldNum].Length+1));
     END
     ELSE OutTextXY(Fields[FieldNum].x1+9,Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,
                    Fields[FieldNum].TextBack,2,_PadRight(Fields[FieldNum].Text,Fields[FieldNum].Length+1));
     OutTextXY(Fields[FieldNum].x1+9+((Fields[FieldNum].CursorPos-1)*8),
               Fields[FieldNum].y1+3,Fields[FieldNum].TextEnabled,255,2,'_');
END;


PROCEDURE SystemField(Raw: _Raw_File);
VAR  x1,y1,
     x2,y2 : Word;
BEGIN
     FieldNum := 1;
     IF NFields=15 THEN Exit;
     INC(NFields);
     IF NFields=1
        THEN Fields[NFields].Active := True
        ELSE Fields[NFields].Active := False;
     Fields[NFields].EntryType      := Raw.Colour4;
     Fields[NFields].Length         := GetStringWidth(Raw.Colour4);
     Fields[NFields].x1             := Raw.x1;
     Fields[NFields].y1             := Raw.y1;
     Fields[NFields].x2             := Raw.x1+(Fields[NFields].Length*8)+20;
     Fields[NFields].y2             := Raw.y1+20;
     Fields[NFields].TextBack       := Raw.Colour1;
     Fields[NFields].TextEnabled    := Raw.Colour2;
     Fields[NFields].TextDisabled   := Raw.Colour3;
     Fields[NFields].Text           := '';
     CASE Raw.Colour4 OF
     1:   Fields[NFields].Text := GetVariable(12,0);  {user's real name}
     2:   Fields[NFields].Text := GetVariable(9,0);   {user's alias}
     3:   Fields[NFields].Text := GetVariable(107,0); {user's password}
     4:   Fields[NFields].Text := GetVariable(53,0);  {user's birthdate}
     5:   Fields[NFields].Text := GetVariable(3,0);   {user's street address}
     6:   Fields[NFields].Text := GetVariable(19,0);  {user's city}
     7:   Fields[NFields].Text := GetVariable(14,0);  {user's province}
     8:   Fields[NFields].Text := GetVariable(16,0);  {user's country}
     9:   Fields[NFields].Text := GetVariable(7,0);   {user's postal code}
     10:  Fields[NFields].Text := GetVariable(17,0);  {user's data phone}
     11:  Fields[NFields].Text := GetVariable(11,0);  {user's voice phone}
     16:  Fields[NFields].Text := GetVariable(71,0);  {# file display lines}
     18:  Fields[NFields].Text := '  /  /    ';
     28:  Fields[NFields].Text := GetVariable(83,0); {Users BBS Name}
     29:  Fields[NFields].Text := GetVariable(84,0); {Users BBS Address}
     30:  Fields[NFields].Text := GetVariable(85,0); {Users BBS Phone Number}
     31:  Fields[NFields].Text := GetVariable(86,0); {Users Comment}
     END;
     IF (LENGTH(Fields[NFields].Text)>Fields[NFields].Length)
        THEN Fields[NFields].Text[0] := Chr(Fields[NFields].Length);
     {Special Case For Dates}
     IF ((Fields[NFields].EntryType=4) OR (Fields[NFields].EntryType=18)) THEN
     BEGIN
          Fields[NFields].CursorPos := 1;
     END
     ELSE Fields[NFields].CursorPos := Length(Fields[NFields].Text)+1;
     GrSetFillStyle(GrFSolid,Fields[NFields].TextBack,GrOpaque);
     GrDrawRect(Fields[NFields].x1,Fields[NFields].y1,
                Fields[NFields].x2,Fields[NFields].y2,GrFill);
END;


END.
