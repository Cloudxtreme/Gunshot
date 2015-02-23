{$M 8192,0,64000}
PROGRAM LineMonitorForDOS;
{$I DEFINES.INC}
USES Crt,Dos,Version,FMode,Gunshot,BsString,BsMulti,BsFile,BsKeys,BsVideo;


VAR  Node      : _NodeFile_Record;
     FNode     : File Of _NodeFile_Record;
     AllDone   : Boolean;
     TheTimes  : Array[1..16] Of Longint;
     StartNode : Byte;
     Looper    : Word;
     C         : Char;


PROCEDURE UpdateInfo;
VAR  DirInfo   : SearchRec;
     Loop      : Byte;
     Temp      : String;
     Work      : Word;
BEGIN
     FOR Work := 1 TO 16 DO
     BEGIN
          FindFirst('\GUNSHOT\INTRNODE\NODE'+_String(StartNode+Work-1)+'.$$$',AnyFile-Directory-VolumeID,DirInfo);
          IF DosError=0 THEN
          BEGIN
               IF (DirInfo.Time<>TheTimes[Work]) THEN
               BEGIN
                    ASSIGN(FNode,'\GUNSHOT\INTRNODE\'+DirInfo.Name);
                    {$I-}
                    RESET(FNode);
                    READ(FNode,Node);
                    CLOSE(FNode);
                    {$I+}
                    IF IOResult=0 THEN
                    BEGIN
                         FastWrite(_PadRight(Node.User,26),8+Work,8,10);
                         FastWrite(_PadRight(Node.Activity,36),8+Work,36,2);
                         FastWrite(_PadLeft(Node.Baud,6),8+Work,73,4);
                         TheTimes[Work] := DirInfo.Time;
                    END;
               END;
          END
          ELSE
          BEGIN
               IF (TheTimes[Work]<>0) THEN
               BEGIN
                    TheTimes[Work] := 0;
                    FastWrite(_PadRight('',26),8+Work,8,7);
                    FastWrite(_PadRight('',36),8+Work,36,7);
                    FastWrite('       ',8+Work,73,7);
               END;
          END;
     END;
     _Delay(1000);
END;

BEGIN
     FileMode := SetFileMode;
     FillChar(TheTimes,SizeOf(TheTimes),255);
     IF (ParamStr(1)<>'') THEN StartNode := _Numeric(ParamStr(1))
                          ELSE StartNode := 1;
     _CreatePath('\GUNSHOT\INTRNODE');
     _HideCursor;
     AppHeader('LineMon - Line Activity Monitor For Gunshot Professional');
     FastWrite('ÚÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄ¿',6,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',7,1,1);
     FastWrite('ÃÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄ´',8,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',9,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',10,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',11,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',12,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',13,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',14,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',15,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',16,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',17,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',18,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',19,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',20,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',21,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',22,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',23,1,1);
     FastWrite('³    ³                           ³                                     ³       ³',24,1,1);
     FastWrite('ÀÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÙ',25,1,1);
     FastWrite(' ## ',7,2,31);
     FastWrite(_PadBoth(' User Online',27),7,7,31);
     FastWrite(_PadBoth(' Node Activity',37),7,35,31);
     FastWrite(' Baud  ',7,73,31);
     FOR Looper := 1 TO 16 DO FastWrite(_String(StartNode+Looper-1),8+Looper,3,7);
     AllDone := False;
     REPEAT
           UpdateInfo;
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                CASE C OF
                #0:  C := ReadKey;
                #13,
                #27,
                #32: AllDone := True;
                END;
           END;
     UNTIL AllDone;
     TextColor(7);
     TextBackground(0);
     ClrScr;
     _ShowCursor;
END.
