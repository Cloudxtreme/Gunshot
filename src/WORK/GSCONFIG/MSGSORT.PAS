{$I DEFINES.INC}
UNIT MsgSort;


INTERFACE


PROCEDURE DoMessageOrder;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,Crt,Defaults,CnfgVars,Dos,Dispatch,FastW1,Valid,Shotgun,BsFile,BsVideo;


PROCEDURE DoMessageOrder;
VAR  Return    : Word;
     DirInfo   : SearchRec;
     FileName  : String;
     FFileSize : Word;
     I         : Word;
     J         : Word;
     Msg1      : _MessageArea_Record;
     Msg2      : _MessageArea_Record;
     TempMsg   : _MessageArea_Record;
     Poop      : Longint;
     HighSub   : Word;
     Spin      : Array[1..4] Of Char;
     SpinCount : Byte;

     FUNCTION ZeroPadded(Number: Word): String;
     VAR  Temp : String;
          Loop : Word;
     BEGIN
          Temp := _String(Number);
          FOR Loop := LENGTH(Temp) TO 5 DO Temp := '0'+Temp;
          ZeroPadded := Temp;
     END;

     PROCEDURE GetHighSub;
     BEGIN
          HighSub := 0;
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          REPEAT
                READ(FMessageArea,MessageArea);
                IF (MessageArea.Sub>HighSub) THEN HighSub := MessageArea.Sub;
          UNTIL EOF(FMessageArea);
          CLOSE(FMessageArea);
     END;

     PROCEDURE DoAlpha;
     VAR Done : boolean;
         Jump : Longint;
         I2   : Longint;
         J2   : Longint;
         N2   : Longint;
     BEGIN
          Spin[1]   := '/';
          Spin[2]   := '-';
          Spin[3]   := '\';
          Spin[4]   := '|';
          SpinCount := 1;
          _HideMouse;
          GotoXY(25,12); Write('Sorting Areas To Disk....');
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          RESET(FMessageArea);
          N2 := FileSize(FMessageArea);
          Jump := N2;
          WHILE (Jump>1) DO
          BEGIN
               Jump := Jump DIV 2;
               REPEAT
                     FastWrite(Spin[SpinCount],12,49,31);
                     INC(SpinCount);
                     IF SpinCount=5 THEN SpinCount := 1;
                     Done := true;
                     FOR J2 := 1 to (N2-Jump) DO
                     BEGIN
                          I2 := J2+Jump;
                          SEEK(FMessageArea,j2-1); READ(FMessageArea,Msg1);
                          SEEK(FMessageArea,i2-1); READ(FMessageArea,Msg2);
                          IF Msg1.Area_Name>Msg2.Area_Name THEN
                          BEGIN
                               TempMsg := Msg1;
                               Msg1    := Msg2;
                               Msg2    := TempMsg;
                               SEEK(FMessageArea,j2-1); WRITE(FMessageArea,Msg1);
                               SEEK(FMessageArea,i2-1); WRITE(FMessageArea,Msg2);
                               Done := false
                          END;
                     END;
               UNTIL Done;
          END;
          CLOSE(FMessageArea);
          _ShowMouse;
     END;

     PROCEDURE DoGroup;
     VAR  Poop2 : Word;
     BEGIN
          _HideMouse;
          GotoXY(25,12); Write('Sorting By Sub Group.....');
          CompileMessageAreas(3,False);
          GetHighSub;
          ASSIGN(FMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
          REWRITE(FMessageArea);
          FOR Poop2 := 1 TO HighSub DO
          BEGIN
               IF _FileExists(BaseDirectory+'\DATA\MA'+ZeroPadded(Poop2)+'.DAT') THEN
               BEGIN
                    ASSIGN(FMessageArea2,BaseDirectory+'\DATA\MA'+ZeroPadded(Poop2)+'.DAT');
                    RESET(FMessageArea2);
                    REPEAT
                          READ(FMessageArea2,MessageArea);
                          WRITE(FMessageArea,MessageArea);
                    UNTIL EOF(FMessageArea2);
                    CLOSE(FMessageArea2);
               END;
          END;
          CLOSE(FMessageArea);
          _ShowMouse;
     END;

BEGIN
     Toggle[1].Flips   := 3;
     Toggle[1].Current := 1;
     Toggle[1].Flip[1] := 'GROUP/ALPHA SORT';
     Toggle[1].Flip[2] := 'GROUP SORT ONLY';
     Toggle[1].Flip[3] := 'ALPHA SORT ONLY';
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(18,9,60,15,'CONFERENCE ORDERING',True);
     AddObject(38,11,8,20,'1',True);
     AddButton(44,13,' CANCEL ',True,1,46);
     AddButton(54,13,' OK ',True,1,32);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(21,11); Write('Ordering Method');
     _ShowMouse;
     REPEAT
           Return := DoObjects;
     UNTIL (Return<>0);
     ClearObjects;
     ClearButtons;
     IF Return=2 THEN
     BEGIN
          DrawWindow(18,9,60,15,'ORDERING AREAS',True);
          TextBackGround_BS(Colour.WindowBackGround);
          TextColor_BS(11);
          CASE Toggle[1].Current OF
          1:   BEGIN
                    DoAlpha;
                    DoGroup;
               END;
          2:   DoGroup;
          3:   DoAlpha;
          END;
     END;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


END.
