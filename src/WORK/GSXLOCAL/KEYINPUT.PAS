{$I DEFINES.INC}
UNIT KeyInput;


INTERFACE


FUNCTION  CommLookAhead                                             : Char;
FUNCTION  GET_YES_NO                                                : boolean;
FUNCTION  GetKeyPress                                               : char;
FUNCTION  Get_Menu_Selection (selections: string;ent: char)         : char;
PROCEDURE get_enter;


IMPLEMENTATION


USES _BHandle,Crt,ApTimer,Globals,AllGone,Time,QBack,BsMulti,Commands,BsKeys;


FUNCTION CommLookAhead: Char;
VAR  c : Char;
BEGIN
     C := ButtonHandler;
     IF KeyPressed THEN
     BEGIN
          C := ReadKey;
          IF ORD(c)=0 THEN
          BEGIN
               C := ReadKey;
               C := CHR(0);
          END;
     END;
     CommLookAhead := C;
END;


FUNCTION GetKeyPress: char;
VAR  c              : char;
     TimerInfo      : EventTimer;
BEGIN
     c := chr(0);
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     REPEAT
           IF TimerExpired(TimerInfo) THEN
           BEGIN
                IF NOT(NodeInfo^.NoTimeout) THEN dispatch(4);
           END;
           TimeLimit;
           IF NFields=0 THEN
           BEGIN
                C := ButtonHandler;
                CASE DidDragDrop OF
                1:   BEGIN
                          GetKeyPress := Chr(1);
                          Exit;
                     END;
                2:   BEGIN
                          GetKeyPress := Chr(2);
                          Exit;
                     END;
                END;
                IF keypressed THEN
                BEGIN
                     c := ReadKey;
                     IF ORD(c)=0 THEN
                     BEGIN
                          c := ReadKey;
                          IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                          HandleKeys(C,True);
                          c := chr(0);
                     END;
                END
                ELSE TimeSlice;
           END
           ELSE
           BEGIN
                C := ButtonHandler;
                CASE DidDragDrop OF
                1:   BEGIN
                          GetKeyPress := Chr(1);
                          Exit;
                     END;
                2:   BEGIN
                          GetKeyPress := Chr(2);
                          Exit;
                     END;
                END;
                IF keypressed THEN
                BEGIN
                     c := ReadKey;
                     IF ORD(c)=0 THEN
                     BEGIN
                          c := ReadKey;
                          IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                          IF HandleKeys(C,True)
                             THEN C := Chr(0)          {taken care of}
                             ELSE C := _AltToNormal(C); {convert to Alt-A etc.}
                     END
                     ELSE IF HandleKeys(C,False) THEN C := Chr(0); {taken care of}
                END
                ELSE TimeSlice;
           END;
     UNTIL (ord(c)<>0);
     GetKeyPress := c;
END;


FUNCTION Get_Menu_Selection(selections: string;ent: char): char;
VAR  press      : char;
     enough     : boolean;
     good_loop  : byte;
BEGIN
     enough := false;
     REPEAT
           Press := UpCase(GetKeyPress);
           IF (ScreenNumber<>0) THEN
           BEGIN
                IF ((Press=#1) OR (Press=#2)) THEN
                BEGIN
                     Get_Menu_Selection := press;
                     Exit;
                END;
           END;
           FOR good_loop := 1 TO LENGTH(selections) DO
           BEGIN
                IF press=selections[good_loop] THEN enough := true;
           END;
           IF ent<>CHR(0) THEN
           BEGIN
                IF Press=chr(13) THEN
                BEGIN
                     press  := ent;
                     enough := true;
                END;
           END;
     UNTIL enough;
     Get_Menu_Selection := press;
END;


FUNCTION GET_YES_NO: boolean;
VAR  c     : char;
     P1,P2 : Char;
BEGIN
     P1 := UpCase(GetCommandKeyPress('MISC',1));
     P2 := UpCase(GetCommandKeyPress('MISC',2));
     c := chr(0);
     REPEAT
           c := GetKeyPress;
     UNTIL ((UpCase(c)=P1) OR (UpCase(c)=P2));
     IF UpCase(c)=P1 THEN Get_Yes_No := True
                     ELSE Get_Yes_No := False;
END;


PROCEDURE get_enter;
VAR  c : char;
BEGIN
     c := chr(0);
     REPEAT
           c := GetKeyPress;
     UNTIL ((c=#13) OR (c=#27));
     c := chr(0);
END;


END.
