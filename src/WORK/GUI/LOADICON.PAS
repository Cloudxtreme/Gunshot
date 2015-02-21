{$I DEFINES.INC}
UNIT LoadIcon;


INTERFACE


FUNCTION LoadFromBank(InString: String): Word;


IMPLEMENTATION


USES Globals,Gr2_Bp,_Win,BHandler,_Icons,_Text,Gx2_BpVC,Gx2_Bp,Shotgun;


FUNCTION LoadFromBank(InString: String): Word;
VAR  XX,YY         : Word;
     LoopX         : Word;
     LoopY         : Word;
     Counter       : Word;
     Work_Icon30_2 : _Icon30x30;
     Work_Icon16_2 : _Icon16x16;
     Action        : Word;
     AllDone       : Boolean;
     Error         : Integer;
BEGIN
     GrDisplayMouse(GrHide);
     NButtons := 0;
     DrawWindow(50,20,530,415,'LOAD ICON FROM BANK - '+InString,LoadIconWindow);
     SystemButton(420,365,520,405,1,False,True);
     SystemIcon(424,369,64);
     OutTextXY(460,379,0,255,1,'Cancel');
     XX      := 60;
     YY      := 55;
     Counter := 0;
     CASE CurrentSize OF
     16:  BEGIN
               ASSIGN(FIcon16,ICONDir+InString);
               RESET(FIcon16);
          END;
     30:  BEGIN
               ASSIGN(FIcon30,ICONDir+InString);
               RESET(FIcon30);
          END;
     END;
     AllDone := False;
     REPEAT
           CASE CurrentSize OF
           16:  READ(FIcon16,Work_Icon16_2);
           30:  READ(FIcon30,Work_Icon30_2);
           END;
           INC(Counter);
           SystemButton(XX,YY,XX+35,YY+35,1,False,True);
           CASE CurrentSize OF
           16:  BEGIN
                     gxDisplayVirtual(xx+3,yy+3,xx+18,yy+18,0,IconHdr,0,0);
                     grSetActiveVirtual(IconHdr);
                     grSetVirtual(gxTrue);
                     WITH Work_Icon16_2 DO
                     BEGIN
                      FOR LoopX := 0 TO 15 DO
                       FOR loopY := 0 TO 15 DO
                        IF Matrix[loopX+1,loopY+1]<>255 THEN
                         GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                     END;
                     grSetVirtual(gxFalse);
                     gxVirtualDisplay(IconHdr,0,0,xx+3,yy+3,xx+18,yy+18,0);
                END;
           30:  BEGIN
                     gxDisplayVirtual(xx+3,yy+3,xx+32,yy+32,0,IconHdr,0,0);
                     grSetActiveVirtual(IconHdr);
                     grSetVirtual(gxTrue);
                     WITH Work_Icon30_2 DO
                     BEGIN
                      FOR LoopX := 0 TO 29 DO
                       FOR loopY := 0 TO 29 DO
                        IF Matrix[loopX+1,loopY+1]<>255 THEN
                         GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                     END;
                     grSetVirtual(gxFalse);
                     gxVirtualDisplay(IconHdr,0,0,xx+3,yy+3,xx+32,yy+32,0);
                END;
           END;
           INC(XX,35);
           IF counter=10 THEN
           BEGIN
                Counter := 0;
                INC(YY,35);
                XX := 60;
           END;
           CASE CurrentSize OF
           16:  IF EOF(FIcon16) THEN AllDone := True;
           30:  IF EOF(FIcon30) THEN AllDone := True;
           END;
     UNTIL AllDone;
     CASE CurrentSize OF
     16:  CLOSE(FIcon16);
     30:  CLOSE(FIcon30);
     END;
     GrDisplayMouse(GrShow);
     REPEAT
           Action := MouseHandler(False);
     UNTIL Action<>0;
     KillWindow;
     LoadFromBank := Action-1;
END;


END.
