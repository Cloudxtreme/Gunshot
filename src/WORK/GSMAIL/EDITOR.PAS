{$I DEFINES.INC}
UNIT Editor;


INTERFACE


FUNCTION aGetInput(X,Y,Len,Attr: Word; Stuff: String; Blocked,UpperC: Boolean): String;


IMPLEMENTATION


USES FastW1,BsMulti,Crt,BsKeys,Globals,BsString,BsVideo;


FUNCTION aGetInput(X,Y,Len,Attr: Word; Stuff: String; Blocked,UpperC: Boolean): String;
VAR  AllDone   : Boolean;
     OldXY     : Word;
     Loop      : Word;
     C         : Char;
LABEL            JumpIn;

     PROCEDURE Redraw;
     BEGIN
          IF Blocked THEN
          BEGIN
               FastWrite(_Replicate('±',Len),Y,X,GunshotColours.GSMailDataEntryBack);
               FastWrite(Stuff,Y,X,GunshotColours.GSMailDataEntry);
          END
          ELSE FastWrite(_PadRight(Stuff,Len),Y,X,GunshotColours.GSMailDataEntry);
          FastW1.GotoXY(X+Length(Stuff),Y);
     END;

BEGIN
     WhereXYAbs(OldXY);
     Redraw;
     _ShowCursor;
     c := Chr(0);
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF (Ord(c)=0) THEN
                BEGIN
                     c := ReadKey;
                     C := IsTheKeyOk(C,True);
                     IF (C<>#0) THEN GOTO JumpIn;
                END
                ELSE
                BEGIN
                     CASE Ord(C) OF
                     8:   BEGIN
                               IF LENGTH(Stuff)>0 THEN
                               BEGIN
                                    Delete(Stuff,LENGTH(Stuff),1);
                                    Redraw;
                               END;
                          END;
                     127: BEGIN
                               Stuff := '';
                               Redraw;
                          END;
                     13:  AllDone := True;
                     27:  BEGIN
                               Stuff := #27;
                               AllDone := True;
                          END;
                     ELSE BEGIN
                               C := IsTheKeyOk(C,False);
                               IF (C<>#0) THEN
                               BEGIN
                                    JumpIn:
                                    IF LENGTH(Stuff)<Len THEN
                                    BEGIN
                                         IF UpperC THEN Stuff := Stuff+UpCase(c)
                                                   ELSE Stuff := Stuff+c;
                                         Redraw;
                                    END;
                               END;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     _HideCursor;
     IF Stuff=#27 THEN FastWrite(_PadRight('',Len),Y,X,Attr)
                  ELSE FastWrite(_PadRight(Stuff,Len),Y,X,Attr);
     GotoXYAbs(OldXY);
     aGetInput := Stuff;
END;


END.