{$I DEFINES.INC}
UNIT Editor;


INTERFACE


FUNCTION GetInput(X,Y,Len,Attr: Word; Stuff: String; Blocked: Boolean): String;


IMPLEMENTATION


USES FastW1,BsMulti,Crt,BsString,BsKeys,BsVideo;


FUNCTION GetInput(X,Y,Len,Attr: Word; Stuff: String; Blocked: Boolean): String;
VAR  AllDone   : Boolean;
     OldX,OldY : Word;
     Loop      : Word;
     C         : Char;
LABEL            JumpIn;

     PROCEDURE Redraw;
     BEGIN
          IF Blocked THEN
          BEGIN
               FastWrite(_Replicate('±',Len),Y,X,1);
               FastWrite(Stuff,Y,X,15);
          END
          ELSE FastWrite(_PadRight(Stuff,Len),Y,X,31);
          GotoXY(X+Length(Stuff),Y);
     END;

BEGIN
     OldX := WhereX;
     OldY := WhereY;
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
                               Stuff := '';
                               AllDone := True;
                          END;
                     ELSE BEGIN
                               C := IsTheKeyOk(C,False);
                               IF (C<>#0) THEN
                               BEGIN
                                    JumpIn:
                                    IF LENGTH(Stuff)<Len THEN
                                    BEGIN
                                         Stuff := Stuff+c;
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
     FastWrite(_PadRight(Stuff,Len),Y,X,Attr);
     GotoXY(OldX,OldY);
     GetInput := Stuff;
END;


END.