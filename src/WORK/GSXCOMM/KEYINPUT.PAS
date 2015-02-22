{$I DEFINES.INC}
UNIT KeyInput;


INTERFACE


FUNCTION  CommLookAhead                                              : Char;
FUNCTION  GET_YES_NO                                                 : boolean;
FUNCTION  GetKeyPress                                                : char;
FUNCTION  Get_Menu_Selection  (selections: string;ent: char)         : char;
PROCEDURE get_enter;


IMPLEMENTATION


USES ApTimer,ApPort,ApCom,Globals,AllGone,Time,Gfx,
     Carrier,Crt,QBack,BsMulti,Commands,Screens;


FUNCTION CommLookAhead: Char;
VAR  c : Char;
BEGIN
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
          NewTimerSecs(CarrierTimer,4);
          IF NOT(CheckDCD(BBSPort)) THEN
          BEGIN
               FlushInBuffer(BBSPort);
               FlushOutBuffer(BBSPort);
               Dispatcher(2);
          END
          ELSE TimeSlice;
          C := #0;
          IF CharReady(BBSPort) THEN
          BEGIN
               GetChar(BBSPort,c);
               IF ORD(c)=0 THEN
               BEGIN
                    GetCharTimeout(BBSPort,c,2);
                    C := CHR(0);
               END;
          END;
     END
     ELSE TimeSlice;
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
                DisplayGraphicFile('TIMEOUT',false,True,True);
                dispatcher(4);
           END;
           TimeLimit;
           IF NFields=0 THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,c);
                     IF ord(c)=255 THEN
                     BEGIN
                          SendPickRequest;
                          c := #0;
                     END
                     ELSE IF ord(c)=254 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          HandleIt(c);
                          c := #0;
                     END
                     ELSE IF ord(c)=253 THEN
                     BEGIN
                          SendPickableRequest;
                          c := #0;
                     END
                     ELSE IF ord(c)=251 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          CASE C OF
                          '1': GetKeyPress := #1;
                          '2': GetKeyPress := #2;
                          END;
                          Exit;
                     END
                     ELSE IF ord(c)=0 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          HandleKeys(C,True);
                          c := chr(0);
                     END
                     ELSE
                     BEGIN
                          GetKeyPress := c;
                          Exit;
                     END;
                END
                ELSE CheckForCarrier;
                IF keypressed THEN
                BEGIN
                     c := ReadKey;
                     IF ORD(c)=0 THEN
                     BEGIN
                          c := ReadKey;
                          IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                          HandleKeys(C,True);
                          c := chr(0);
                          IF ((RunTheChat) AND (WaitingAtMenu)) THEN
                          BEGIN
                               GetKeyPress := #13;
                               Exit;
                          END;
                     END
                     ELSE
                     BEGIN
                          GetKeyPress := c;
                          Exit;
                     END;
                END;
           END
           ELSE
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,c);
                     IF ord(c)=255 THEN
                     BEGIN
                          SendPickRequest;
                          c := #0;
                     END
                     ELSE IF ord(c)=254 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          HandleIt(c);
                          c := #0;
                     END
                     ELSE IF ord(c)=253 THEN
                     BEGIN
                          SendPickableRequest;
                          c := #0;
                     END
                     ELSE IF ord(c)=251 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          CASE C OF
                          '1': GetKeyPress := #1;
                          '2': GetKeyPress := #2;
                          END;
                          Exit;
                     END
                     ELSE IF ORD(c)=0 THEN
                     BEGIN
                          GetCharTimeout(BBSPort,c,2);
                          IF HandleKeys(C,True)
                             THEN C := Chr(0)          {taken care of}
                             ELSE C := AltToNormal(C); {convert to Alt-A etc.}
                     END
                     ELSE IF HandleKeys(C,False) THEN C := Chr(0); {taken care of}
                END
                ELSE CheckForCarrier;
                IF keypressed THEN
                BEGIN
                     c := ReadKey;
                     IF ORD(c)=0 THEN
                     BEGIN
                          c := ReadKey;
                          IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                          IF HandleKeys(C,True)
                             THEN C := Chr(0)          {taken care of}
                             ELSE C := AltToNormal(C); {convert to Alt-A etc.}
                          IF ((RunTheChat) AND (WaitingAtMenu)) THEN
                          BEGIN
                               GetKeyPress := #13;
                               Exit;
                          END;
                     END
                     ELSE IF HandleKeys(C,False) THEN C := Chr(0); {taken care of}
                END;
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
     CheckForCarrier;
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
     CheckForCarrier;
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
     CheckForCarrier;
END;


END.
