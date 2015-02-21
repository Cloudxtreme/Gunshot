{$I DEFINES.INC}
UNIT _Fields;


INTERFACE


PROCEDURE SystemField(x1,y1: Word; EntryType,MaxLength: Byte; Stuff: String);
PROCEDURE ChangeField(Number: Word);
PROCEDURE RedrawField;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Text,BsString;


{==========================================================================}
{                                                                          }
{         PLACES AN ENTRY FIELD ON THE SCREEN FOR HANDLING                 }
{                                                                          }
{==========================================================================}
PROCEDURE SystemField(x1,y1: Word; EntryType,MaxLength: Byte; Stuff: String);
VAR  x2,y2 : Word;
BEGIN
     x2 := x1+20+(MaxLength*8);
     y2 := y1+20;
     INC(NFields);
     IF NFields=1 THEN Fields[NFields].Active := True
                  ELSE Fields[NFields].Active := False;
     Fields[NFields].x1         := x1;
     Fields[NFields].y1         := y1;
     Fields[NFields].x2         := x2;
     Fields[NFields].y2         := y2;
     Fields[NFields].Text       := Stuff;
     Fields[NFields].CursorPos  := LENGTH(Stuff)+1;
     Fields[NFields].EntryType  := EntryType;
     Fields[NFields].MaxLength  := MaxLength;
     IF NFields=FieldNum THEN
     BEGIN
          GrSetColor(8);
          GrSetFillStyle(GrFSolid,FieldBackground,GrOpaque);
          GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill+GrOutline);
          OutTextXYS(x1+10,y1+3,FieldForeground,255,Stuff+'_');
     END
     ELSE
     BEGIN
          GrSetFillStyle(GrFSolid,FieldBackground,GrOpaque);
          GrDrawRect(x1+1,y1+1,x2-1,y2-1,GrFill);
          OutTextXYS(x1+10,y1+3,FieldDisabled,255,Stuff);
     END;
     GrSetColor(15);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(8);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;
{==========================================================================}
{                                                                          }
{         ADVANCES TO THE NEXT, PREVIOUS OR RANDOM FIELD                   }
{                                                                          }
{==========================================================================}
PROCEDURE ChangeField(Number: Word);
VAR  x2,y2 : Word;
BEGIN
     IF NFields<=1 THEN Exit;
     {First, kill the last one}
     Fields[FieldNum].Active := False;
     GrSetColor(FieldBackground);
     GrDrawRect(Fields[FieldNum].x1+1,Fields[FieldNum].y1+1,
                Fields[FieldNum].x2-1,Fields[FieldNum].y2-1,GrOutline);
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldDisabled,
                FieldBackground,_PadRight(Fields[FieldNum].Text,Fields[FieldNum].MaxLength+1));
     {Set the new one active}
     FieldNum := Number;
     Fields[FieldNum].Active := True;
     Fields[FieldNum].CursorPos := LENGTH(Fields[FieldNum].Text)+1;
     {Draw it out}
     GrSetColor(8);
     GrDrawRect(Fields[FieldNum].x1+1,Fields[FieldNum].y1+1,
                Fields[FieldNum].x2-1,Fields[FieldNum].y2-1,GrOutline);
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldForeground,255,
                _PadRight(Fields[FieldNum].Text+'_',Fields[FieldNum].MaxLength+1));
END;
{==========================================================================}
{                                                                          }
{         REDRAWS A FIELD AFTER EDITING                                    }
{                                                                          }
{==========================================================================}
PROCEDURE RedrawField;
BEGIN
     OutTextXYS(Fields[FieldNum].x1+10,Fields[FieldNum].y1+3,FieldForeground,FieldBackground,
                _PadRight(Fields[FieldNum].Text,Fields[FieldNum].MaxLength+1));
     OutTextXYS(Fields[FieldNum].x1+10+((Fields[FieldNum].CursorPos-1)*8),
                Fields[FieldNum].y1+3,FieldForeground,255,'_');
END;


END.