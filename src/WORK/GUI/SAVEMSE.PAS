{$I DEFINES.INC}
UNIT SaveMse;


INTERFACE


PROCEDURE SaveMouseToBank(InString: String);


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,BHandler,_Icons,_Text,Shotgun;


PROCEDURE SaveMouseToBank(InString: String);
VAR  XX,YY         : Word;
     LoopX         : Word;
     LoopY         : Word;
     Counter       : Word;
     Action        : Word;
     FMouseDef2    : File Of _Mouse_Def;
     MouseDef2     : _Mouse_Def;
     AllDone       : Boolean;
     Byte1         : Byte;
     Byte2         : Byte;
     Work          : Word;
BEGIN
     GrDisplayMouse(GrHide);
     NButtons := 0;
     DrawWindow(50,20,380,265,'SAVE MOUSE TO BANK - '+InString,LoadIconWindow);
     SystemButton(270,215,370,255,1,False,True);
     SystemIcon(274,219,64);
     OutTextXY(310,229,0,255,1,'Cancel');
     XX      := 60;
     YY      := 55;
     Counter := 0;
     ASSIGN(FMouseDef2,ICONDir+InString);
     RESET(FMouseDef2);
     AllDone := False;
     REPEAT
           READ(FMouseDef2,MouseDef2);
           INC(Counter);
           SystemButton(XX,YY,XX+20,YY+20,1,False,True);
           {Mask First}
           FOR LoopX := 0 TO 15 DO
           BEGIN
                FOR LoopY := 0 TO 15 DO
                BEGIN
                     IF MouseDef2.Mask[LoopX+1,LoopY+1]=True THEN
                        GrPutPixel(XX+LoopX+2,YY+LoopY+2,0);
                END;
           END;
           {Cursor Next}
           FOR LoopX := 0 TO 15 DO
           BEGIN
                FOR LoopY := 0 TO 15 DO
                BEGIN
                     IF MouseDef2.Cursor[LoopX+1,LoopY+1]=True THEN
                        GrPutPixel(XX+LoopX+2,YY+LoopY+2,MouseDef2.Colour);
                END;
           END;
           INC(XX,20);
           IF counter=10 THEN
           BEGIN
                Counter := 0;
                INC(YY,20);
                XX := 60;
           END;
           IF EOF(FMouseDef2) THEN AllDone := True;
     UNTIL AllDone;
     CLOSE(FMouseDef2);
     GrDisplayMouse(GrShow);
     REPEAT
           Action := MouseHandler(False);
     UNTIL Action<>0;
     KillWindow;
     IF Action<>1 THEN
     BEGIN
          DEC(Action);
          ASSIGN(FMouseDef2,ICONDir+InString);
          RESET(FMouseDef2);
          SEEK(FMouseDef2,Action-1);
          WRITE(FMouseDef2,MouseDef);
          CLOSE(FMouseDef2);
     END;
END;


END.
