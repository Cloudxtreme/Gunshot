{$I DEFINES.INC}
UNIT ChatMisc;


INTERFACE


PROCEDURE GetChatName;


IMPLEMENTATION


USES SaveScrn,Crt,Globals,BsMulti,BsKeys;


PROCEDURE GetChatName;
VAR  c       : Char;
     Temp    : String;
     AllDone : Boolean;
LABEL       JumpIn;
BEGIN
     Temp     := '';
     Save_Screen2;
     Window(1,1,80,25);
     TextBackGround(1);
     TextColor(11);
     GotoXY(1,25);  ClrEol;
     GotoXY(5,25);  WRITE('Chat With User As:');
     GotoXY(24,25); WRITE('[');
     GotoXY(55,25); WRITE(']');
     TextColor(8);
     TextBackground(0);
     GotoXY(25,25); WRITE('______________________________');
     GotoXY(25,25);
     IF (System_Info.Alias<>'') THEN Temp := System_Info.Alias
                                ELSE Temp := System_Info.Sysop;
     TextColor(14);
     WRITE(Temp);
     C := #0;
     AllDone := False;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     C := IsTheKeyOk(C,True);
                     IF (C<>#0) THEN GOTO JumpIn;
                END
                ELSE
                BEGIN
                     CASE ORD(C) OF
                     13:  AllDone := True;
                     8:   BEGIN
                               IF (Temp<>'') THEN
                               BEGIN
                                    Delete(Temp,Length(Temp),1);
                                    TextColor(8);
                                    WRITE(#8+'_'+#8);
                               END;
                          END;
                     ELSE BEGIN
                               C := IsTheKeyOk(C,False);
                               IF (C<>#0) THEN
                               BEGIN
                                    JumpIn:
                                    IF Length(Temp)<29 THEN
                                    BEGIN
                                         Temp := Temp+C;
                                         TextColor(14);
                                         WRITE(C);
                                    END;
                               END;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL AllDone;
     Window(1,1,80,24);
     Restore_Screen2;
     System_Info.Sysop := Temp;
     System_Info.Alias := Temp;
END;


END.
