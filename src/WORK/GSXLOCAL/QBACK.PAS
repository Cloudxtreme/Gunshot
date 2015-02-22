{$I DEFINES.INC}
UNIT QBack;


INTERFACE


FUNCTION  DoSysopPress(CC: Char): Boolean;
PROCEDURE RUN_SHELL;


IMPLEMENTATION


USES _Buffers,Execute,Dos,Globals,Crt,NodeFile,Gx2_Bp,Img2_Bp,BsGraph,Status;


PROCEDURE RUN_SHELL;
VAR  c : char;
BEGIN
     Save_Screen;
     ExecuteDosCommand(GetEnv('COMSPEC'));
     Chdir(Shotgun_Directory);
     Load_Screen;
     REPEAT
           IF KeyPressed THEN c := ReadKey;
     UNTIL NOT(KeyPressed);
END;


FUNCTION DoSysopPress(CC: Char): Boolean;
VAR  DidSomething : Boolean;
     SavedAct     : Word;
     dipal        : Array[0..767] Of Byte;
     Loop         : Word;
     What         : Word;
     c1,c2,c3     : Integer;
BEGIN
     SavedAct := LastActivity;
     DidSomething := False;
     CASE ORD(cc) OF
     60:  BEGIN {F2 - SHELL TO DOS}
               DoNodeActivity(35,'');
               run_shell;
               DoNodeActivity(SavedAct,'');
               DidSomething := True;
          END;
     67:  BEGIN {SCREEN CAPTURE}
               What := 0;
               FOR Loop := 0 TO 255 DO
               BEGIN
                    gxGetPaletteRGB(Loop,c1,c2,c3);
                    dipal[What]   := c1;
                    dipal[What+1] := c2;
                    dipal[What+2] := c3;
                    INC(What,3);
               END;
               imgDisplayFile(0,0,GraphMaxX,GraphMaxY,0,'SESSION.BMP',imgBMP,imgTRUNC,@DiPal);
          END;
     END;
     IF DidSomething THEN Status_Line;
     DoSysopPress := DidSomething;
END;


END.
