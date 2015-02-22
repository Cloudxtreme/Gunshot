{$I DEFINES.INC}
UNIT SysDial;


INTERFACE


FUNCTION SystemDialed: Boolean;


IMPLEMENTATION


USES ApTimer,ApMisc,Globals,__Gfx,ApPort,ApCom,Comm,BsMulti,BsString,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


FUNCTION SystemDialed: Boolean;
VAR  C          : Word;
     x,y        : Word;
     d1         : String;
     d2         : String;
     d3         : String;
     d4         : String;
     Temp       : String;
     Ch         : Char;
     Which      : Byte;
     InADial    : Boolean;
     DName      : Array[1..3] Of String;
     Crap       : Word;
     Between    : Boolean;
     BigTimer   : EventTimer;
     Last       : Longint;
     Now        : Longint;
     TheCurrent : Longint;
LABEL           SkipOnIn;

     PROCEDURE WriteStatus(InString: String);
     BEGIN
          x  := ScreenInfo.OrigX1+ScreenInfo.XOffset+20;
          y  := ScreenInfo.OrigY1+ScreenInfo.YOffset+98;
          d1 := d2;
          d2 := d3;
          d3 := d4;
          d4 := _PadRight(InString,30);
          GrDisplayMouse(GrHide);
          OutTextXYS(x,y,7,0,d1);
          OutTextXYS(x,y+15,7,0,d2);
          OutTextXYS(x,y+30,7,0,d3);
          OutTextXYS(x,y+45,7,0,d4);
          GrDisplayMouse(GrShow);
     END;

     FUNCTION Clean(InString: String): String;
     VAR  WorkStr : String;
          Loop    : Word;
     BEGIN
          WorkStr := '';
          FOR Loop := 1 TO LENGTH(InString) DO
          BEGIN
               IF Ord(InString[Loop])>31 THEN WorkStr := WorkStr+InString[Loop];
          END;
          Clean := WorkStr;
     END;

     PROCEDURE ProcessIncoming;
     VAR  CC   : Char;
          Done : Boolean;
     BEGIN
          Temp := '';
          IF CharReady(BBSPort) THEN
          BEGIN
               Done := False;
               REPEAT
                     GetCharTimeout(BBSPort,cc,2);
                     IF AsyncStatus=ecOk THEN
                     BEGIN
                          IF (Ord(cc)>31) THEN Temp := Temp+cc;
                          IF Ord(cc)=13 THEN Done := True;
                     END
                     ELSE Done := True;
               UNTIL Done;
          END;
     END;

     FUNCTION ReturnOk(InString: String): Boolean;
     BEGIN
          ReturnOk := False;
          IF Pos('+FCERROR',    InString)=1 THEN ReturnOk := True;
          IF Pos('+FCON',       InString)=1 THEN ReturnOk := True;
          IF Pos('BUSY',        InString)=1 THEN ReturnOk := True;
          IF Pos('CARRIER',     InString)=1 THEN ReturnOk := True;
          IF Pos('CED',         InString)=1 THEN ReturnOk := True;
          IF Pos('COMPRESSION', InString)=1 THEN ReturnOk := True;
          IF Pos('CONNECT',     InString)=1 THEN ReturnOk := True;
          IF Pos('DATA',        InString)=1 THEN ReturnOk := True;
          IF Pos('ERROR',       InString)=1 THEN ReturnOk := True;
          IF Pos('FAX',         InString)=1 THEN ReturnOk := True;
          IF Pos('NO ANSWER',   InString)=1 THEN ReturnOk := True;
          IF Pos('NO CARRIER',  InString)=1 THEN ReturnOk := True;
          IF Pos('NO DIAL',     InString)=1 THEN ReturnOk := True;
          IF Pos('OK',          InString)=1 THEN ReturnOk := True;
          IF Pos('PROTOTCOL',   InString)=1 THEN ReturnOk := True;
          IF Pos('RING',        InString)=1 THEN ReturnOk := True;
     END;

BEGIN
     d1       := '';
     d2       := '';
     d3       := '';
     d4       := '';
     DName[1] := '16550 UART';
     DName[2] := 'Fossil Driver';
     DName[3] := 'DigiBoard';
     GrDisplayMouse(GrHide);
     DrawWindow(160,145,480,370,'DIALING...',0);
     OutTextXYFR(250,180,0,255,5,'System Name:');
     OutTextXYFR(250,195,0,255,5,'Phone Number:');
     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(170,215,470,230,GrFill);
     OutTextXY(175,215,15,255,1,'Modem Responses');
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(170,235,470,310,GrFill);
     InvertedBox(170,235,470,310);
     OutTextXY(180,315,0,255,5,'COM '+_String(CommDef.Port));
     OutTextXY(180,330,0,255,5,DName[CommDef.Device]);
     OutTextXY(180,345,0,255,5,_String(ReturnRate(CommDef.Baud,CommDef.Device))+' BPS');
     SystemButton(370,320,470,360,1,False,True);
     SystemIcon(380,325,64);
     OutTextXY(415,333,0,255,1,'Cancel');
     GrDisplayMouse(GrShow);
     NewTimerSecs(BigTimer,1);
     InADial    := False;
     Which      := 0;
     Last       := 999999;
     TheCurrent := 1;
     REPEAT
           IF NOT(InADial) THEN
           BEGIN
                IF Which=5 THEN
                BEGIN
                     IF NOT(TimerExpired(BigTimer)) THEN
                     BEGIN
                          Now := RemainingTimeInSecs(BigTimer);
                          IF (Now<>Last) THEN
                          BEGIN
                               Last := Now;
                               GrDisplayMouse(GrHide);
                               WindowHeader('DIALING... '+_String(Now),True);
                               GrDisplayMouse(GrShow);
                          END;
                     END
                     ELSE
                     BEGIN
                          Last := 999999;
                          GrDisplayMouse(GrHide);
                          WindowHeader('DIALING...',True);
                          GrDisplayMouse(GrShow);
                          GOTO SkipOnIn;
                     END;
                END
                ELSE
                BEGIN
                     SkipOnIn:
                     _Delay(CommDef.CommandDelay);
                     INC(Which);
                     IF Which=6 THEN Which := 1;
                     CASE Which OF
                     1:   SendCommandString(CommDef.Hangup,True,True);
                     2:   SendCommandString(CommDef.DataInit,True,True);
                     3:   IF (CommDef.DataInit2<>'') THEN SendCommandString(CommDef.DataInit2,True,True);
                     4:   IF (CommDef.DataInit3<>'') THEN SendCommandString(CommDef.DataInit3,True,True);
                     5:   BEGIN
                               ASSIGN(FDialDir,'SGT.DIR');
                               RESET(FDialDir);
                               SEEK(FDialDir,CallQueue[TheCurrent]-1);
                               READ(FDialDir,DialDir);
                               CLOSE(FDialDir);
                               x  := ScreenInfo.OrigX1+ScreenInfo.XOffset+100;
                               y  := ScreenInfo.OrigY1+ScreenInfo.YOffset+35;
                               GrSetFillStyle(GrFSolid,7,GrOpaque);
                               GrDisplayMouse(GrHide);
                               GrDrawRect(X,Y,X+215,Y+30,GrFill);
                               OutTextXY(X,Y,0,255,5,DialDir.Name);
                               OutTextXY(X,Y+15,0,255,5,DialDir.Phone);
                               GrDisplayMouse(GrShow);
                               SendCommandString(CommDef.DPrefix+DialDir.Phone,True,True);
                               INC(TheCurrent);
                               IF (TheCurrent>NumInQueue) THEN TheCurrent := 1;
                               InADial := True;
                          END;
                     END;
                END;
           END;
           c := MouseHandler(False);
           IF C=0 THEN TimeSlice;
           IF CharReady(BBSPort) THEN
           BEGIN
                ProcessInComing;
                IF (Temp<>'') THEN
                BEGIN
                     IF ReturnOk(Temp) THEN WriteStatus(Temp);
                     IF Temp='NO CARRIER' THEN
                     BEGIN
                          InADial := False;
                          NewTimerSecs(BigTimer,CommDef.DialTimeout);
                     END
                     ELSE IF Temp='BUSY' THEN
                     BEGIN
                          InADial := False;
                          NewTimerSecs(BigTimer,CommDef.DialTimeout);
                     END
                     ELSE IF _Mid(Temp,1,7)='NO DIAL' THEN
                     BEGIN
                          InADial := False;
                          NewTimerSecs(BigTimer,CommDef.DialTimeout);
                     END
                     ELSE IF _Mid(Temp,1,8)='CONNECT ' THEN
                     BEGIN
                          _Delay(500);
                          SetDTR(BBSPort,True);
                          SetRTS(BBSPort,True);
                          KillWindow;
                          Crap := Pos('/',Temp);
                          IF (Crap<>0) THEN Temp := _Mid(Temp,1,Crap-1);
                          ActualBaud := _Numeric(_Mid(Temp,9,LENGTH(Temp)));
                          GrDisplayMouse(GrHide);
                          _Delay(500);
                          DrawWindow(220,200,420,260,'CONNECT!',0);
                          OutTextXY(250,235,0,255,1,'Connected at '+_String(ActualBaud)+' bps');
                          _Delay(500);
                          GrDisplayMouse(GrShow);
                          KillWindow;
                          SystemDialed := True;
                          Exit;
                     END;
                END;
           END;
     UNTIL C=NButtons;
     WindowHeader(ScreenInfo.Title,False);
     GrDisplayMouse(GrHide);
     SendCommandString(CommDef.Hangup,True,True);
     FlushInBuffer(BBSPort);
     GrDisplayMouse(GrShow);
     KillWindow;
     SystemDialed := False;
END;


END.