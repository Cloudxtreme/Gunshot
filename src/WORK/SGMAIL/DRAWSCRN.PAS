{$I DEFINES.INC}
UNIT DrawScrn;


INTERFACE


PROCEDURE QueueWindow       (InString: String);
PROCEDURE StatusWindow      (InString: String);
PROCEDURE ModemStatusWindow (InString: String);
PROCEDURE DrawWindow        (x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
PROCEDURE DropShadow        (xx1,yy1,xx2,yy2 : Word);
PROCEDURE InvertedBox       (x1,y1,x2,y2: Word);
PROCEDURE Get               (x1,y1,x2,y2: Word);
PROCEDURE Put               (x,y: Word);
PROCEDURE DrawTheScreen;
PROCEDURE ClearTheWindows;
PROCEDURE RemoveDialWindow;
PROCEDURE DrawDialWindow;
PROCEDURE SetOurVideoMode;
PROCEDURE SetOrigVideoMode;


IMPLEMENTATION


USES Crt,FastW1,Globals,Time,SaveScrn,Misc,Version,
     ApAnsi,BsAkas,BsString,BsVideo,BsKeys;


PROCEDURE ClearTheWindows;
VAR  Loop : Word;
BEGIN
     FOR Loop := QueueWindowTop TO (Window2-1) DO FastWrite(_Replicate(' ',22),Loop,2,ShotgunColours.SGMailNormalText);
     FOR Loop := 5 TO (Window1-1) DO FastWrite(_Replicate(' ',55),Loop,25,ShotgunColours.SGMailNormalText);
     FOR Loop := (Window1+1) TO (Window2-1) DO FastWrite(_Replicate(' ',55),Loop,25,ShotgunColours.SGMailNormalText);
END;


PROCEDURE StatusWindow(InString: String);
VAR  TempTime : String;
     TheAttr  : Word;
     Work     : Word;
BEGIN
     IF DialWindowActive THEN Exit;
     TheAttr := ShotgunColours.SGMailNormalText;
     IF InString[1]='!' THEN
     BEGIN
          Delete(InString,1,1);
          TheAttr := ShotgunColours.SGMailErrorText;
     END;
     TempTime := ' '+LongToStringTime(Getting_Time)+' '+InString;
     IF TempTime[2]=' ' THEN TempTime[2] := '0';
     Get(25,6,79,Window1-1);
     Put(25,5);
     FastWrite(_PadRight(TempTime,55),Window1-1,25,TheAttr);
     Work := LENGTH(TempTime)+25;
     IF Work>80 THEN Work := 80;
     apGotoXY(Work,Window1-1);
END;


PROCEDURE ModemStatusWindow(InString: String);
VAR  Work : Word;
BEGIN
     IF DialWindowActive THEN Exit;
     InString := ' '+InString;
     Get(25,Window1+2,79,Window2-1);
     Put(25,Window1+1);
     FastWrite(_PadRight(InString,55),Window2-1,25,ShotgunColours.SGMailNormalText);
     Work := LENGTH(InString)+25;
     IF Work>80 THEN Work := 80;
     apGotoXY(Work,Window2-1);
END;


PROCEDURE QueueWindow(InString: String);
BEGIN
     IF DialWindowActive THEN Exit;
     Get(2,QueueWindowTop+1,23,Window2-1);
     Put(2,QueueWindowTop);
     FastWrite(' '+_PadRight(InString,21),Window2-1,2,ShotgunColours.SGMailNormalText);
END;


PROCEDURE SetOurVideoMode;
BEGIN
     ClrScr;
     CASE NumLines OF
     25:  TextMode(CO80);
     28:  ExtendedVideoMode(28);
     30:  ExtendedVideoMode(30);
     50:  TextMode(CO80+Font8x8);
     END;
     ScreenBytes := (160*NumLines);
     Window1     := (Trunc(NumLines/2))+1;
     Window2     := NumLines-7;
     SetAnsiHeight(24);
     CheckSnow := False;
     ReinitFastWrite;
END;


PROCEDURE SetOrigVideoMode;
BEGIN
     ClrScr;
     TextMode(OldLines);
     TextColor(7);
     TextBackGround(0);
     ClrScr;
END;


PROCEDURE DropShadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
          Mem[SegB800:x] := ShotgunColours.SGMailWindowShadow;
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
          Mem[SegB800:y] := ShotgunColours.SGMailWindowShadow;
          INC(y,160);
     END;
END;


PROCEDURE Get(x1,y1,x2,y2: Word);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     GetPut1.NumLines := y2-y1+1;
     Count := 1;
     FOR Loop := y1 TO y2 DO
     BEGIN
          GetPut1.Lines[Count].LineLength := x2-x1+1;
          Move(MEM[SegB800:(((Loop-1)*160)+((x1-1)*2))],GetPut1.Lines[Count].Line,(x2-x1+1)*2);
          INC(Count);
     END;
END;


PROCEDURE Put(x,y: Word);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     Count := 1;
     FOR Loop := y TO (y+GetPut1.NumLines-1) DO
     BEGIN
          Move(GetPut1.Lines[Count].Line,MEM[SegB800:(((Loop-1)*160)+((x-1)*2))],(GetPut1.Lines[Count].LineLength)*2);
          INC(Count);
     END;
END;


PROCEDURE RemoveDialWindow;
BEGIN
     IF DialWindowActive THEN
     BEGIN
          RestoreScreen(1);
          _ShowCursor;
          GotoXYAbs(DialSave);
          TextColor(7);
          TextBackground(0);
          FastWrite(_PadRight('',80),Window2+7,1,ShotgunColours.SGMailNormalText);
     END;
     DialWindowActive := False;
END;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
     Temp   : String;
     Attr1  : Word;
     Attr2  : Word;
BEGIN
     CASE ShotgunColours.SGMailWindowFrameStyle OF
     1:   BEGIN {3D}
            IF Shad THEN DropShadow(x1,y1,x2,y2);
            Attr1 := ShotgunColours.SGMailWindowFrameLow;
            Attr2 := ShotgunColours.SGMailWindowFrameHigh;
            FOR LoopY := y1 TO y2 DO
            BEGIN
              IF LoopY=y1 THEN
              BEGIN
                FastWrite('Ú',LoopY,x1,Attr2);
                FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr2);
                FastWrite('¿',LoopY,x2,Attr1);
              END
              ELSE IF LoopY=y2 THEN
              BEGIN
                FastWrite('À',LoopY,x1,Attr2);
                FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr1);
                FastWrite('Ù',LoopY,x2,Attr1);
              END
              ELSE
              BEGIN
                FastWrite('³',LoopY,x1,Attr2);
                FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,Attr1);
                FastWrite('³',LoopY,x2,Attr1);
              END;
            END;
            IF (Title<>'') THEN
            BEGIN
              Title := ' '+Title+' ';
              FastWrite(Title,y1,x1+3,ShotgunColours.SGMailWindowTitle);
            END;
          END;
     2:   BEGIN {Standard}
            IF Shad THEN DropShadow(x1,y1,x2,y2);
            Attr1 := ShotgunColours.SGMailWindowFrameLow;
            FOR LoopY := y1 TO y2 DO
            BEGIN
              IF LoopY=y1 THEN
              BEGIN
                FastWrite('Õ'+_Replicate('Í',x2-x1-1)+'¸',LoopY,x1,Attr1);
              END
              ELSE IF LoopY=y2 THEN
              BEGIN
                FastWrite('Ô'+_Replicate('Í',x2-x1-1)+'¾',LoopY,x1,Attr1);
              END
              ELSE
              BEGIN
                FastWrite('³'+_Replicate(' ',x2-x1-1)+'³',LoopY,x1,Attr1);
              END;
            END;
            IF (Title<>'') THEN FastWrite(Title,y1,x1+3,ShotgunColours.SGMailWindowTitle);
          END;
     END;
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     IF ShotgunColours.SGMailWindowFrameStyle=1 THEN
     BEGIN
       Attr1 := ShotgunColours.SGMailWindowFrameLow;
       Attr2 := ShotgunColours.SGMailWindowFrameHigh;
       FastWrite('Ú',y1,x1,Attr1);
       FastWrite(_Replicate('Ä',x2-x1-1),y1,x1+1,Attr1);
       FastWrite('¿',y1,x2,Attr2);
       FOR Loop := y1+1 TO y2-1 DO
       BEGIN
         FastWrite('³',Loop,x1,Attr1);
         FastWrite('³',Loop,x2,Attr2);
       END;
       FastWrite('À',y2,x1,Attr1);
       FastWrite(_Replicate('Ä',x2-x1-1),y2,x1+1,Attr2);
       FastWrite('Ù',y2,x2,Attr2);
     END;
END;


PROCEDURE DrawDialWindow;
VAR  TopLine : Word;
     Loop    : Word;
     Temp    : String;
     Work    : Byte;
BEGIN
     TopLine := Window1-4;
     DialWindowActive := True;
     WhereXYAbs(DialSave);
     _HideCursor;
     SaveScreen(1);
     CASE ShotgunColours.SGMailWindowFrameStyle OF
     1:   BEGIN {3D}
            DrawWindow(43,TopLine,78,TopLine+6,'',True);
            InvertedBox(45,TopLine+2,76,TopLine+5);
          END;
     2:   BEGIN {Standard}
            DrawWindow(43,TopLine,78,TopLine+5,'',True);
          END;
     END;
     FastWrite(_PadBoth(NodeListSystem,30),TopLine+1,46,ShotgunColours.SGMailWindowHighlight);
     FastWrite(_PadBoth(AddressToString(MailQueue^[MailQueuePointer].DestAddr),30),TopLine+3,
               46,ShotgunColours.SGMailWindowText);
     Temp := NodeListPhone;
     FOR Loop := 1 TO 10 DO
     BEGIN
       IF (HiddenDial.TheString[Loop]<>'') THEN
       BEGIN
         REPEAT
           Work := Pos(HiddenDial.TheString[Loop],Temp);
           IF (Work<>0) THEN Delete(Temp,Work,LENGTH(HiddenDial.TheString[Loop]));
         UNTIL Work=0;
       END;
     END;
     FastWrite(_PadBoth(Temp,30),TopLine+4,46,ShotgunColours.SGMailWindowText);
     TextColor(7);
     TextBackground(0);
END;


PROCEDURE DrawTheScreen;
VAR  Temp : String;
     Loop : Word;
BEGIN
  Temp := ShotgunVersion;
  Delete(Temp,1,1);
  Temp := _PadRight(Temp,5);
  HighVideo;
  OldLines := LastMode;
  SetOurVideoMode;
  _HideCursor;
  FOR Loop := 1 TO NumLines DO FastWrite(_PadRight('',80),Loop,1,ShotgunColours.SGMailNormalText);
  FastWrite(' Node:                     Last:                                     Mail:      ',
            1,1,ShotgunColours.SGMailStatusText);
  FastWrite('  Aka:                       On:                                      BBS:      ',
            2,1,ShotgunColours.SGMailStatusText);
  FastWrite('                            Off:                                      Fax:      ',
            3,1,ShotgunColours.SGMailStatusText);
  FastWrite('Úğğ        ğğÄÄÄÄÄÄÄÄÄÄÂğğ      ğğÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',
            4,1,ShotgunColours.SGMailFrame);
  FOR Loop := 5 TO QueueWindowTop-2 DO
  BEGIN
    FastWrite('³',Loop,1,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,24,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,80,ShotgunColours.SGMailFrame);
  END;

  FastWrite('Ãğğ     ğğÄÄÄÄÄÄÄÄÄÄÄÄÄ´',QueueWindowTop-1,1,ShotgunColours.SGMailFrame);
  FastWrite('³',QueueWindowTop-1,80,ShotgunColours.SGMailFrame);

  FOR Loop := QueueWindowTop TO (Window1-1) DO
  BEGIN
    FastWrite('³',Loop,1,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,24,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,80,ShotgunColours.SGMailFrame);
  END;
  FastWrite('³',Window1,1,ShotgunColours.SGMailFrame);
  FastWrite('Ãğğ     ğğÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',Window1,24,ShotgunColours.SGMailFrame);
  FOR Loop := (Window1+1) TO (Window2-1) DO
  BEGIN
    FastWrite('³',Loop,1,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,24,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,80,ShotgunColours.SGMailFrame);
  END;
  FastWrite('Ãğğ    ğğÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂğğ  ğğÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',Window2,1,
            ShotgunColours.SGMailFrame);
  FOR Loop := (Window2+1) TO (Window2+3) DO
  BEGIN
    FastWrite('³',Loop,1,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,41,ShotgunColours.SGMailFrame);
    FastWrite('³',Loop,80,ShotgunColours.SGMailFrame);
  END;
  FastWrite('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',Window2+4,1,
            ShotgunColours.SGMailFrame);
  FastWrite('³',Window2+5,1,ShotgunColours.SGMailFrame);
  FastWrite('³',Window2+5,59,ShotgunColours.SGMailFrame);
  FastWrite('°±²             ²±°',Window2+5,61,ShotgunColours.SGMailFrame);
  FastWrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',Window2+6,1,ShotgunColours.SGMailFrame);
  FastWrite('Settings',4,4,ShotgunColours.SGMailFrameLabels);
  FastWrite('Queue',QueueWindowTop-1,4,ShotgunColours.SGMailFrameLabels);
  FastWrite('Status',4,27,ShotgunColours.SGMailFrameLabels);
  FastWrite('Modem',Window1,27,ShotgunColours.SGMailFrameLabels);
  FastWrite('From',Window2,4,ShotgunColours.SGMailFrameLabels);
  FastWrite('To',Window2,44,ShotgunColours.SGMailFrameLabels);
  FastWrite('Time:',Window2+5,3,ShotgunColours.SGMailTimeDateLabels);
  FastWrite('Date:',Window2+5,17,ShotgunColours.SGMailTimeDateLabels);
  FastWrite(' SGMail '+Temp,Window2+5,64,ShotgunColours.SGMailStatusHighlight);
  FastWrite('Press      For Menu',Window2+6,61,ShotgunColours.SGMailNormalText);
  FastWrite('[  ]',Window2+6,67,ShotgunColours.SGMailToggleBrackets);
  FastWrite('F1',Window2+6,68,ShotgunColours.SGMailToggles);
  FastWrite('[ ]',5,3,ShotgunColours.SGMailToggleBrackets);
  FastWrite('[ ]',6,3,ShotgunColours.SGMailToggleBrackets);
  FastWrite('[ ]',7,3,ShotgunColours.SGMailToggleBrackets);
  FastWrite('[ ]',5,13,ShotgunColours.SGMailToggleBrackets);
  FastWrite('[ ]',6,13,ShotgunColours.SGMailToggleBrackets);
  FastWrite('[ ]',7,13,ShotgunColours.SGMailToggleBrackets);
  FastWrite('Users',5,6,ShotgunColours.SGMailNormalText);
  FastWrite('Faxes',6,6,ShotgunColours.SGMailNormalText);
  FastWrite('Freqs',7,6,ShotgunColours.SGMailNormalText);
  FastWrite('EMSI',5,16,ShotgunColours.SGMailNormalText);
  FastWrite('YooHoo',6,16,ShotgunColours.SGMailNormalText);
  FastWrite('ZedZap',7,16,ShotgunColours.SGMailNormalText);
  ClearTheWindows;
END;


END.
