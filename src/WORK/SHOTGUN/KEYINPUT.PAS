{$I DEFINES.INC}
UNIT KeyInput;


INTERFACE


PROCEDURE Get_String(l: word; s: string; solid,NoLetter,UCase: boolean; Required: Boolean);
PROCEDURE Get_Password(l: word; s: string; solid: boolean; Required: Boolean);
PROCEDURE GetADate(s: string; Required: Boolean);
PROCEDURE Get_Name(l: word; s: string; solid: boolean; Required: Boolean);
PROCEDURE Get_Number(l: word; s: string; Required: Boolean);
FUNCTION  Get_Menu_Selection(selections: string;ent: char): char;
FUNCTION  GETKEYORNUMBER(selections: string;ent: char): string;
FUNCTION  GetMainKeyPress: char;
FUNCTION  CommLookAhead: Char;
FUNCTION  GETKEYPRESS: char;
FUNCTION  GET_YES_NO: boolean;
PROCEDURE get_enter;


IMPLEMENTATION


USES Globals,Crt,ApPort,ApTimer,Comm,ANSIMisc,AllGone,Time,Carrier,QBack,
     BsMulti,Screens,MiscStr,BsKeys,Commands,ApCom,BsString;


FUNCTION CommLookAhead: Char;
VAR  c    : Char;
BEGIN
     C := #0;
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
          NewTimerSecs(CarrierTimer,4);
          IF LocalLogon THEN
          BEGIN
               IF KeyPressed THEN
               BEGIN
                    C := ReadKey;
                    IF ORD(c)=0 THEN
                    BEGIN
                         C := ReadKey;
                         C := CHR(0);
                    END;
               END
               ELSE TimeSlice;
          END
          ELSE
          BEGIN
               IF NOT(CheckDCD(BBSPort)) THEN
               BEGIN
                    FlushInBuffer(BBSPort);
                    FlushOutBuffer(BBSPort);
                    Dispatcher(2);
               END
               ELSE TimeSlice;
               IF CharReady(BBSPort) THEN
               BEGIN
                    GetChar(BBSPort,c);
                    IF ORD(c)=0 THEN
                    BEGIN
                         GetChar(BBSPort,c);
                         C := CHR(0);
                    END;
               END;
          END;
     END
     ELSE TimeSlice;
     CommLookAhead := C;
END;


FUNCTION GetMainKeyPress: char;
VAR  c              : char;
     LastX          : Word;
     LastY          : Word;
     TimerInfo      : EventTimer;
BEGIN
     c := chr(0);
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           IF TimerExpired(TimerInfo) THEN
           BEGIN
                IF ((NOT(NodeInfo.NoTimeout)) OR (NOT(LocalLogon))) THEN
                BEGIN
                     SendCrLf(2);
                     DisplayGraphicsFile('TIMEOUT',true,false,True,True,False);
                     Dispatcher(4);
                END;
           END;
           TimeLimit;
           IF NOT(LocalLogon) THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,c);
                     IF ord(c)=0 THEN
                     BEGIN
                          GetChar(BBSPort,c);
                          C := IsTheKeyOk(C,True);
                     END
                     ELSE
                     BEGIN
                          GetMainKeyPress := c;
                          Exit;
                     END;
                END
                ELSE
                BEGIN
                     CheckForCarrier;
                     TimeSlice;
                END;
           END;
           IF Keypressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                     C := IsTheKeyOk(C,True);
                END
                ELSE
                BEGIN
                     GetMainKeyPress := c;
                     Exit;
                END;
           END
           ELSE IF LocalLogon THEN TimeSlice;
           IF IsRip THEN
           BEGIN
             RIP^.CheckMouse;
             IF RIP^.CharInBuffer THEN
             BEGIN
               C := RIP^.GetNextChar;
             END;
           END;
     UNTIL (ord(c)<>0);
     GetMainKeyPress := c;
END;


FUNCTION Get_Menu_Selection(selections: string;ent: char): char;
VAR  press      : char;
     enough     : boolean;
     good_loop  : byte;
BEGIN
     enough := false;
     REPEAT
           Press := UpCase(GetKeyPress);
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
     FORE(15);
     WRITECHAR(press);
     Get_Menu_Selection := press;
END;


FUNCTION GETKEYPRESS: char;
VAR  c         : char;
     TimerInfo : EventTimer;
BEGIN
     c := chr(0);
     NewTimerSecs(TimerInfo,system_info.Sys_Idle);
     REPEAT
           IF TimerExpired(TimerInfo) THEN
           BEGIN
                IF ((NOT(NodeInfo.NoTimeout)) OR (NOT(LocalLogon))) THEN
                BEGIN
                     SendCrLf(2);
                     DisplayGraphicsFile('TIMEOUT',true,false,True,True,False);
                     dispatcher(4);
                END;
           END;
           TimeLimit;
           IF NOT(LocalLogon) THEN
           BEGIN
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,c);
                     IF ord(c)=0 THEN
                     BEGIN
                          GetChar(BBSPort,c);
                          C := IsTheKeyOk(C,True);
                     END
                     ELSE
                     BEGIN
                          GetKeyPress := c;
                          Exit;
                     END;
                END
                ELSE
                BEGIN
                     CheckForCarrier;
                     TimeSlice;
                END;
           END;
           IF KeyPressed THEN
           BEGIN
                c := ReadKey;
                IF ORD(c)=0 THEN
                BEGIN
                     c := ReadKey;
                     IF DoSysopPress(C) THEN NewTimerSecs(TimerInfo,system_info.Sys_Idle);
                     C := IsTheKeyOk(C,True);
                END
                ELSE
                BEGIN
                     GetKeyPress := c;
                     Exit;
                END;
           END
           ELSE IF LocalLogon THEN TimeSlice;
           IF IsRip THEN
           BEGIN
             RIP^.CheckMouse;
             IF RIP^.CharInBuffer THEN
             BEGIN
               C := RIP^.GetNextChar;
             END;
           END;
     UNTIL (ord(c)<>0);
     GetKeyPress := c;
END;


FUNCTION GET_YES_NO: boolean;
VAR  c     : char;
     P1,P2 : Char;
BEGIN
     P1 := UpCase(GetCommandKeyPress('MISC',1));
     P2 := UpCase(GetCommandKeyPress('MISC',2));
     WRITECHAR(' ');
     c := chr(0);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
     UNTIL ((UpCase(c)=P1) OR (UpCase(c)=P2));
     FORE(15);
     IF UpCase(c)=P1 THEN
     BEGIN
          Get_Yes_No := True;
          WRITEANSI(GetCommandString('MISC',1),false,false);
     END
     ELSE IF UpCase(c)=P2 THEN
     BEGIN
          Get_Yes_No := False;
          WRITEANSI(GetCommandString('MISC',2),false,false);
     END;
END;


FUNCTION GetKeyOrNumber(selections: string;ent: char): string;
VAR  ct1                 : char;
     len                 : byte;
     s                   : string;
     getkey_loop         : word;
     finished            : boolean;
BEGIN
     numeric      := false;
     s            := '';
     input_string := '';
     len          := length(s);
     finished     := false;
     WRITEANSI(s,false,False);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           ct1 := UpCase(GetKeyPress);
           IF ((ord(ct1)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(ct1);
                     WRITECHAR(' ');
                     WRITECHAR(ct1);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     WRITECHAR(ct1);
                     WRITECHAR(' ');
                     WRITECHAR(ct1);
                END;
           END
           ELSE IF (ord(ct1)=13) THEN
           BEGIN
                IF LENGTH(s)<>0 THEN
                BEGIN
                     input_string := s;
                     numeric      := true;
                     finished     := true;
                END
                ELSE
                BEGIN
                     IF ent<>chr(0) THEN
                     BEGIN
                          numeric      := false;
                          input_string := ent;
                          finished     := true;
                          WRITECHAR(ent);
                     END;
                END;
           END
           ELSE IF ((ord(ct1)>47) AND (ord(ct1)<58)) THEN
           BEGIN
                inc(len);
                s := s+ct1;
                numeric := true;
                WRITECHAR(ct1);
           END
           ELSE IF ((ord(ct1)>64) AND (ord(ct1)<91)) THEN
           BEGIN
                FOR getkey_loop := 1 TO LENGTH(selections) DO
                BEGIN
                     IF selections[getkey_loop]=ct1 THEN
                     BEGIN
                          len := 1;
                          s := ct1;
                          input_string := s;
                          WRITECHAR(ct1);
                          numeric      := false;
                          finished     := true;
                     END;
                END;
           END
           ELSE IF ((ord(ct1)=42) OR (ord(ct1)=43) OR (ord(ct1)=45)) THEN
           BEGIN
                FOR getkey_loop := 1 TO LENGTH(selections) DO
                BEGIN
                     IF selections[getkey_loop]=ct1 THEN
                     BEGIN
                          len := 1;
                          s := ct1;
                          input_string := s;
                          WRITECHAR(ct1);
                          numeric      := false;
                          finished     := true;
                     END;
                END;
           END
           ELSE IF ((ord(ct1)>96) AND (ord(ct1)<123)) THEN
           BEGIN
                FOR getkey_loop := 1 TO LENGTH(selections) DO
                BEGIN
                     IF selections[getkey_loop]=ct1 THEN
                     BEGIN
                          len := 1;
                          s := ct1;
                          input_string := s;
                          WRITECHAR(ct1);
                          numeric      := false;
                          finished     := true;
                     END;
                END;
           END
           ELSE IF Ord(ct1)=127 THEN
           BEGIN
                IF (s<>'') THEN
                BEGIN
                     FOR GetKey_Loop := 1 TO len DO
                     BEGIN
                          WRITECHAR(#8);
                          WRITECHAR(' ');
                          WRITECHAR(#8);
                     END;
                END;
                s := '';
                len := 0;
           END;
     UNTIL finished;
     GetKeyOrNumber := input_string;
     SendCrLf(1);
END;


PROCEDURE get_enter;
VAR  c : char;
BEGIN
     c := chr(0);
     System_Prompt('',60,false,False);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
     UNTIL ((c=#13) OR (c=#27));
     SendCrLf(1);
END;


PROCEDURE GetADate(s: string; Required: Boolean);
VAR  c                   : char;
     len                 : byte;
     loop                : word;
     T1,T2,T3            : String[4];
     Place1              : Byte;
     Place2              : Byte;
     StartX              : Byte;
     StartY              : Byte;

     PROCEDURE ClearTheDate;
     BEGIN
          GotoXYAnsi(StartX,StartY);
          IF System_Info.DateFormat=3
             THEN WRITEANSI('    /  /  ',false,false)
             ELSE WRITEANSI('  /  /    ',false,false);
          GotoXYAnsi(StartX,StartY);
     END;

BEGIN
     StartX := WhereX;
     StartY := WhereY;
     T1 := _Mid(s,1,2);
     T2 := _Mid(s,3,4);
     T3 := _Mid(s,5,8);
     CASE System_Info.DateFormat OF
     1:   BEGIN {MM/DD/YYYY}
            Place1 := 3;
            Place2 := 6;
          END;
     2:   BEGIN {DD/MM/YYYY}
            s := T2+T1+T3;
            Place1 := 3;
            Place2 := 6;
          END;
     3:   BEGIN {YYYY/MM/DD}
            s := T3+T1+T2;
            Place1 := 5;
            Place2 := 8;
          END;
     END;
     input_string := '';
     len := length(s);
     ForeBack(15,Colours.InputFieldBackGround);
     ClearTheDate;
     IF len<>0 THEN
     BEGIN
          FOR Loop := 1 TO len DO
          BEGIN
               WRITECHAR(s[loop]);
               IF ((Loop=Place1-1) OR (Loop=Place2-1)) THEN WRITECHAR('/');
          END;
     END;
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
           IF ((ord(c)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(#08);
                     WRITECHAR(' ');
                     WRITECHAR(#08);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     CASE System_Info.DateFormat OF
                     1,2: IF ((len=1) OR (len=3)) THEN WRITECHAR(#08);
                     ELSE IF ((len=3) OR (len=5)) THEN WRITECHAR(#08);
                     END;
                     WRITECHAR(#08);
                     WRITECHAR(' ');
                     WRITECHAR(#08);
                END;
           END
           ELSE IF ord(c)=13 THEN
           BEGIN
                input_string := s;
                IF Required THEN
                BEGIN
                     IF LENGTH(input_string)<>8 THEN c := #0
                                                ELSE back(0);
                END
                ELSE back(0);
           END
           ELSE IF ((ord(c)>47) AND (ord(c)<58) AND (len<8)) THEN
           BEGIN
                inc(len);
                s := s+c;
                WRITECHAR(c);
                CASE System_Info.DateFormat OF
                1,2: IF ((len=2) OR (len=4)) THEN WRITECHAR('/');
                ELSE IF ((len=4) OR (len=6)) THEN WRITECHAR('/');
                END;
           END
           ELSE IF Ord(c)=127 THEN
           BEGIN
                IF (s<>'') THEN ClearTheDate;
                s := '';
                len := 0;
           END;
     UNTIL (ord(c)=13);
     IF (input_string<>'') THEN
     BEGIN
       CASE System_Info.DateFormat OF
       1:   BEGIN {MM/DD/YYYY}
              T1 := _Mid(input_string,1,2);
              T2 := _Mid(input_string,3,4);
              T3 := _Mid(input_string,5,8);
              input_string := T1+T2+T3;
            END;
       2:   BEGIN {DD/MM/YYYY}
              T1 := _Mid(input_string,1,2);
              T2 := _Mid(input_string,3,4);
              T3 := _Mid(input_string,5,8);
              input_string := T2+T1+T3;
            END;
       ELSE BEGIN {YYYY/MM/DD}
              T1 := _Mid(input_string,1,4);
              T2 := _Mid(input_string,5,6);
              T3 := _Mid(input_string,7,8);
              input_string := T2+T3+T1;
            END;
       END;
     END;
END;


PROCEDURE Get_String(l: word; s: string; solid,NoLetter,UCase: boolean; Required: Boolean);
VAR  c                   : char;
     len                 : byte;
     loop                : word;
BEGIN
     input_string := '';
     len          := length(s);
     Fore(Colours.InputFieldForeground);
     IF solid THEN
     BEGIN
       back(Colours.InputFieldBackGround);
       WRITEANSI(_PadRight('',L),False,False);
       AnsiLeft(l);
     END;
     WRITEANSI(s,false,True);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
           IF UCase THEN c := UpCase(c);
           IF ((ord(c)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END;
           END
           ELSE IF (ord(c)=13) THEN
           BEGIN
                input_string := s;
                IF Required THEN
                BEGIN
                     IF input_string='' THEN c := #0
                                        ELSE Back(0);
                END
                ELSE back(0);
           END
           ELSE IF Ord(c)=127 THEN
           BEGIN
                IF (s<>'') THEN
                BEGIN
                     FOR Loop := 1 TO len DO
                     BEGIN
                          WRITECHAR(#8);
                          WRITECHAR(' ');
                          WRITECHAR(#8);
                     END;
                END;
                s := '';
                len := 0;
           END
           ELSE IF (len<l) THEN
           BEGIN
                C := IsTheKeyOk(C,False);
                IF (C<>#0) THEN
                BEGIN
                     IF NoLetter THEN
                     BEGIN
                          IF ((Ord(c)<65) OR (Ord(c)>122) OR ((Ord(c)>90) AND (Ord(c)<97))) THEN
                          BEGIN
                               inc(len);
                               s := s+c;
                               WRITECHAR(c);
                          END;
                     END
                     ELSE
                     BEGIN
                          inc(len);
                          s := s+c;
                          WRITECHAR(c);
                     END;
                END;
           END;
     UNTIL (ord(c)=13);
END;


PROCEDURE Get_Password(l: word; s: string; solid: boolean; Required: Boolean);
VAR  c                   : char;
     len                 : byte;
     loop                : word;
BEGIN
     s := _UpperCase(s);
     input_string := '';
     len          := length(s);
     Fore(15);
     IF solid THEN
     BEGIN
       back(Colours.InputFieldBackGround);
       WRITEANSI(_PadRight('',L),False,False);
       AnsiLeft(l);
     END;
     FOR loop := 1 TO len DO WRITECHAR('þ');
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := UpCase(GetKeyPress);
           IF ((ord(c)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END;
           END
           ELSE IF (ord(c)=13) THEN
           BEGIN
                input_string := s;
                IF Required THEN
                BEGIN
                     IF input_string='' THEN c := #0
                                        ELSE Back(0);
                END
                ELSE back(0);
           END
           ELSE IF Ord(c)=127 THEN
           BEGIN
                IF (s<>'') THEN
                BEGIN
                     FOR Loop := 1 TO len DO
                     BEGIN
                          WRITECHAR(#8);
                          WRITECHAR(' ');
                          WRITECHAR(#8);
                     END;
                END;
                s := '';
                len := 0;
           END
           ELSE IF (len<l) THEN
           BEGIN
                C := IsTheKeyOk(C,False);
                IF (C<>#0) THEN
                BEGIN
                     inc(len);
                     s := s+c;
                     WRITECHAR('þ');
                END;
           END;
     UNTIL (ord(c)=13);
END;


PROCEDURE Get_Name(l: word; s: string; solid: boolean; Required: Boolean);
VAR  c                   : char;
     len                 : byte;
     loop                : word;
BEGIN
     {219 - solid block}
     input_string := '';
     len          := length(s);
     Fore(Colours.InputFieldForeground);
     IF solid THEN
     BEGIN
          back(Colours.InputFieldBackGround);
          WRITEANSI(_PadRight('',L),False,False);
          AnsiLeft(l);
     END;
     WRITEANSI(s,false,true);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
           IF ((ord(c)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END;
           END
           ELSE IF (ord(c)=13) THEN
           BEGIN
                input_string := s;
                IF Required THEN
                BEGIN
                     IF input_string='' THEN c := #0
                                        ELSE Back(0);
                END
                ELSE back(0);
           END
           ELSE IF Ord(c)=127 THEN
           BEGIN
                IF (s<>'') THEN
                BEGIN
                     FOR Loop := 1 TO len DO
                     BEGIN
                          WRITECHAR(#8);
                          WRITECHAR(' ');
                          WRITECHAR(#8);
                     END;
                END;
                s := '';
                len := 0;
           END
           ELSE IF (len<l) THEN
           BEGIN
                C := IsTheKeyOk(C,False);
                IF (C<>#0) THEN
                BEGIN
                     IF (len>0) THEN
                     BEGIN
                          IF _Mid(s,len,len)=' ' THEN c:= UpCase(c);
                     END
                     ELSE c := UpCase(c);
                     inc(len);
                     s := s+c;
                     WRITECHAR(c);
                END;
           END;
     UNTIL (ord(c)=13);
     Input_String := _RemoveLeftSpaces(Input_String);
     Input_String := _RemoveRightSpaces(Input_String);
END;


PROCEDURE Get_Number(l: word; s: string; Required: Boolean);
VAR  c                   : char;
     len                 : byte;
     loop                : word;
BEGIN
     input_string := '';
     len          := length(s);
     fore(Colours.InputFieldForeGround);
     back(Colours.InputFieldBackGround);
     WRITEANSI(_PadRight('',L),False,False);
     AnsiLeft(l);
     WRITEANSI(s,false,true);
     IF NOT(LocalLogon) THEN ClearInBuffer;
     REPEAT
           c := GetKeyPress;
           IF ((ord(c)=8) AND (len>0)) THEN
           BEGIN
                dec(len);
                IF len=0 THEN
                BEGIN
                     s := '';
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END
                ELSE
                BEGIN
                     s := _Mid(s,1,len);
                     WRITECHAR(c);
                     WRITECHAR(' ');
                     WRITECHAR(c);
                END;
           END
           ELSE IF (ord(c)=13) THEN
           BEGIN
                input_string := s;
                IF Required THEN
                BEGIN
                     IF input_string='' THEN c := #0
                                        ELSE Back(0);
                END
                ELSE back(0);
           END
           ELSE IF ((ord(c)>47) AND (ord(c)<58) AND (len<l)) THEN
           BEGIN
                inc(len);
                s := s+c;
                WRITECHAR(c);
           END
           ELSE IF Ord(c)=127 THEN
           BEGIN
                IF (s<>'') THEN
                BEGIN
                     FOR Loop := 1 TO len DO
                     BEGIN
                          WRITECHAR(#8);
                          WRITECHAR(' ');
                          WRITECHAR(#8);
                     END;
                END;
                s := '';
                len := 0;
           END;
     UNTIL (ord(c)=13);
     back(0);
END;


END.
