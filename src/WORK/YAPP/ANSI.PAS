{$I DEFINES.INC}
UNIT ANSI;


INTERFACE


PROCEDURE RunningDosDoor;


IMPLEMENTATION


USES _Save,_Buffers,ApPort,ApCom,ApTimer,Fx,Startup,
     Globals,Crt,AnsiSide,Dos,ApAnsi,BsVideo,BsString;


PROCEDURE RunningDosDoor;
VAR  ccc       : Char;
     OuttaHere : Boolean;
     Temp      : String;
     Work      : Word;
     XPos      : Word;
     TTT       : EventTimer;
     x,y       : Word;
     Actual    : Word;
     SvX       : Word;
     SvY       : Word;
BEGIN
     Save_Screen;
     HighVideo;
     Textcolor(7);
     Textbackground(0);
     TextMode(C80);
     ClrScr;
     FastWrite(_PadRight('            ³              ³                 ³',80),25,1,16);
     FastWrite('Alt-X Quit',25,2,27);
     FastWrite('Alt-H Hangup',25,15,27);
     FastWrite('Alt-Z DOS Shell',25,30,27);
     Window(1,1,80,24);
     Textcolor(7);
     Textbackground(0);
     GotoXY(1,1);
     PutChar(BBSPort,#255);
     OuttaHere := False;
     REPEAT
           IF CharReady(BBSPort) THEN
           BEGIN
                GetChar(BBSPort,ccc);
                IF ccc=#255 THEN
                BEGIN
                     NewTimerSecs(TTT,3);
                     Temp := ccc;
                     REPEAT
                           IF CharReady(BBSPort) THEN
                           BEGIN
                                GetChar(BBSPort,ccc);
                                Temp := Temp+ccc;
                           END;
                     UNTIL ((CCC=#13) OR (TimerExpired(TTT)));
                     IF Temp=#255#121#13 THEN OuttaHere := True
                                         ELSE WriteStringAnsi(Temp);
                END
                ELSE IF ccc=#24 THEN
                BEGIN
                     NewTimerSecs(TTT,4);
                     Temp := ccc;
                     REPEAT
                           IF CharReady(BBSPort) THEN
                           BEGIN
                                GetChar(BBSPort,ccc);
                                Temp := Temp+ccc;
                           END;
                     UNTIL ((Pos(#24+'B00',Temp)<>0) OR (TimerExpired(TTT)));
                     IsGfx := False;
                     IF (Pos(#24+'B00',Temp)<>0) THEN ReceiveFiles(YappDef.DlDir)
                                                 ELSE WriteStringAnsi(Temp);
                END
                ELSE WriteCharAnsi(ccc);
           END
           ELSE
           BEGIN
                IF KeyPressed THEN
                BEGIN
                     ccc := ReadKey;
                     IF ccc=#00 THEN
                     BEGIN
                          ccc := ReadKey;
                          CASE ORD(ccc) OF
                          35:  HangUp;
                          71:  PutString(BBSPort,#27#91#72); {home}
                          72:  PutString(BBSPort,#27#91#65); {U arrow}
                          75:  PutString(BBSPort,#27#91#68); {L arrow}
                          77:  PutString(BBSPort,#27#91#67); {R arrow}
                          79:  PutString(BBSPort,#27#91#75); {end}
                          80:  PutString(BBSPort,#27#91#66); {D arrow}
                          83:  PutString(BBSPort,#127);      {delete}
                          119: PutString(BBSPort,#27#91#76); {ctrl+home}
                          132: PutString(BBSPort,#27#91#77); {ctrl+PgUp}
                          46:  PutString(BBSPort,#27+'[1;37m'+#27+'[40m'+chr(27)+'[2J');
                          59:  SendCommandString(YappDef.F1,False,False);
                          60:  SendCommandString(YappDef.F2,False,False);
                          61:  SendCommandString(YappDef.F3,False,False);
                          62:  SendCommandString(YappDef.F4,False,False);
                          63:  SendCommandString(YappDef.F5,False,False);
                          64:  SendCommandString(YappDef.F6,False,False);
                          65:  SendCommandString(YappDef.F7,False,False);
                          66:  SendCommandString(YappDef.F8,False,False);
                          67:  SendCommandString(YappDef.F9,False,False);
                          68:  SendCommandString(YappDef.F10,False,False);
                          44:  BEGIN {Dos Shell}
                                    SaveTextScreen;
                                    SvX := WhereX;
                                    SvY := WhereY;
                                    Window(1,1,80,25);
                                    ClrScr;
                                    Exec(GetEnv('COMSPEC'),' /C '+GetEnv('COMSPEC'));
                                    ChDir(SGT_Directory);
                                    Window(1,1,80,24);
                                    LoadTextScreen;
                                    GotoXY(SvX,SvY);
                               END;
                          ELSE PutString(BBSPort,#0+ccc);
                          END;
                     END
                     ELSE PutChar(BBSPort,ccc);
                END
                ELSE IF NoCarrier THEN OuttaHere := True;
           END;
     UNTIL OuttaHere;
     Window(1,1,80,25);
     Load_Screen;
     PutChar(BBSPort,#255);
END;


END.
