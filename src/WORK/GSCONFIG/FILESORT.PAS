{$I DEFINES.INC}
UNIT FileSort;


INTERFACE


PROCEDURE DoFileOrder;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,Crt,Defaults,CnfgVars,Hatch,BsVideo,
     FileMan,Import,Dos,Dispatch,FastW1,Valid,Shotgun,BsFile;


PROCEDURE DoFileOrder;
VAR  Return    : Word;
     DirInfo   : SearchRec;
     FileName  : String;
     FFileSize : Word;
     I         : Word;
     J         : Word;
     File1     : _FileArea_Record;
     File2     : _FileArea_Record;
     TempFile  : _FileArea_Record;
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
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          REPEAT
                READ(FFileArea,FileArea);
                IF (FileArea.Sub>HighSub) THEN HighSub := FileArea.Sub;
          UNTIL EOF(FFileArea);
          CLOSE(FFileArea);
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
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          RESET(FFileArea);
          N2 := FileSize(FFileArea);
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
                          SEEK(FFileArea,j2-1); READ(FFileArea,File1);
                          SEEK(FFileArea,i2-1); READ(FFileArea,File2);
                          IF File1.Area_Name>File2.Area_Name THEN
                          BEGIN
                               TempFile := File1;
                               File1    := File2;
                               File2    := TempFile;
                               SEEK(FFileArea,j2-1); WRITE(FFileArea,File1);
                               SEEK(FFileArea,i2-1); WRITE(FFileArea,File2);
                               Done := false
                          END;
                     END;
               UNTIL Done;
          END;
          CLOSE(FFileArea);
          _ShowMouse;
     END;

     PROCEDURE DoGroup;
     VAR  Poop2 : Word;
     BEGIN
          _HideMouse;
          GotoXY(25,12); Write('Sorting By Sub Group.....');
          CompileMessageAreas(2,False);
          GetHighSub;
          ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
          REWRITE(FFileArea);
          FOR Poop2 := 1 TO HighSub DO
          BEGIN
               IF _FileExists(BaseDirectory+'\DATA\FA'+ZeroPadded(Poop2)+'.DAT') THEN
               BEGIN
                    ASSIGN(FFileArea2,BaseDirectory+'\DATA\FA'+ZeroPadded(Poop2)+'.DAT');
                    RESET(FFileArea2);
                    REPEAT
                          READ(FFileArea2,FileArea);
                          WRITE(FFileArea,FileArea);
                    UNTIL EOF(FFileArea2);
                    CLOSE(FFileArea2);
               END;
          END;
          CLOSE(FFileArea);
          _ShowMouse;
     END;

BEGIN
     Toggle[1].Flips   := 3;
     Toggle[1].Current := 1;
     Toggle[1].Flip[1] := 'GROUP/ALPHA SORT';
     Toggle[1].Flip[2] := 'GROUP SORT ONLY';
     Toggle[1].Flip[3] := 'ALPHA SORT ONLY';
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(18,9,60,15,'FILE AREA ORDERING',True);
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
