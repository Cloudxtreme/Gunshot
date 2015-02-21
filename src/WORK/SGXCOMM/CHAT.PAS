{$I DEFINES.INC}
UNIT Chat;


INTERFACE


PROCEDURE CLRPORTSCR;
PROCEDURE SysopFullChat;
PROCEDURE WRITEANSI    (output_line: string; line_feed: boolean);
PROCEDURE WRITECHAR    (Character: String);
PROCEDURE back         (col: word);
PROCEDURE fore         (col: word);


IMPLEMENTATION


USES ApPort,ApCom,ApAnsi,Crt,Globals,Status,BsMulti,SaveScrn,
     Yapp,BsLog,NodeFile,ApTimer,Special,Carrier,BsString;


PROCEDURE WRITEANSI(output_line: string; line_feed: boolean);
VAR  Sent : Word;
BEGIN
     IF line_feed THEN output_line := output_line+#$0D#$0A;
     PutBlockTimeout(BBSPort,Output_Line[1],Length(Output_Line),Sent,YappDelay);
     WriteStringAnsi(output_line);
END;


PROCEDURE WRITECHAR(Character: String);
BEGIN
     PutCharTimeout(BBSPort,character[1],182);
     WriteCharAnsi(character[1]);
END;


PROCEDURE back(col: word);
VAR  colour_code         : string;
BEGIN
     CASE col OF
     0:   colour_code := #27+'[40m';
     1:   colour_code := #27+'[44m';
     2:   colour_code := #27+'[42m';
     3:   colour_code := #27+'[46m';
     4:   colour_code := #27+'[41m';
     5:   colour_code := #27+'[45m';
     6:   colour_code := #27+'[43m';
     7:   colour_code := #27+'[47m';
     END;
     WRITEANSI(colour_code,False);
END;


PROCEDURE fore(col: word);
VAR  colour_code         : string;
BEGIN
     CASE col OF
     0  :  colour_code := #27+'[0;30m';
     1  :  colour_code := #27+'[0;34m';
     2  :  colour_code := #27+'[0;32m';
     3  :  colour_code := #27+'[0;36m';
     4  :  colour_code := #27+'[0;31m';
     5  :  colour_code := #27+'[0;35m';
     6  :  colour_code := #27+'[0;33m';
     7  :  colour_code := #27+'[0;37m';
     8  :  colour_code := #27+'[1;30m';
     9  :  colour_code := #27+'[1;34m';
     10 :  colour_code := #27+'[1;32m';
     11 :  colour_code := #27+'[1;36m';
     12 :  colour_code := #27+'[1;31m';
     13 :  colour_code := #27+'[1;35m';
     14 :  colour_code := #27+'[1;33m';
     15 :  colour_code := #27+'[1;37m';
     END;
     WRITEANSI(colour_code,False);
END;


PROCEDURE CLRPORTSCR;
BEGIN
     BACK(0);
     FORE(15);
     WRITECHAR(#$0C);
     status_line;
END;


PROCEDURE SendCrLf(Num: Byte);
VAR  Loop : Word;
BEGIN
     FOR Loop := 1 TO Num DO WRITEANSI('',True);
END;


FUNCTION GoodKey(InChar: Char): Boolean;
VAR  AnyGood : Boolean;
BEGIN
     AnyGood := False;
     IF ((Ord(InChar)>31) AND (Ord(InChar)<128)) THEN AnyGood := True;
     GoodKey := AnyGood;
END;


PROCEDURE GetChatName;
VAR  c    : Char;
     Temp : String;
BEGIN
     Temp     := '';
     Save_Screen2;
     Window(1,1,80,25);
     TextBackGround(1);
     TextColor(11);
     GotoXY(1,25);  ClrEol;
     GotoXY(5,25);  WRITE('Chat With User As:');
     GotoXY(24,25); WRITE('[');
     GotoXY(55,25); WRITE(']');
     TextColor(8);
     TextBackground(0);
     GotoXY(25,25); WRITE('______________________________');
     GotoXY(25,25);
     IF (System_Info.Alias<>'') THEN Temp := System_Info.Alias
                                ELSE Temp := System_Info.Sysop;
     TextColor(14);
     WRITE(Temp);
     C := #0;
     REPEAT
           IF KeyPressed THEN
           BEGIN
                C := ReadKey;
                IF C=#0 THEN
                BEGIN
                     C := ReadKey;
                     C := #0;
                END
                ELSE
                BEGIN
                     CASE ORD(C) OF
                     8:   BEGIN
                               IF (Temp<>'') THEN
                               BEGIN
                                    Delete(Temp,Length(Temp),1);
                                    TextColor(8);
                                    WRITE(#8+'_'+#8);
                               END;
                          END;
                     ELSE IF ((ORD(c)>31) AND (Ord(c)<128)) THEN
                          BEGIN
                               IF Length(Temp)<29 THEN
                               BEGIN
                                    Temp := Temp+C;
                                    TextColor(14);
                                    WRITE(C);
                               END;
                          END;
                     END;
                END;
           END
           ELSE TimeSlice;
     UNTIL C=#13;
     Window(1,1,80,24);
     Restore_Screen2;
     System_Info.Sysop := Temp;
     System_Info.Alias := Temp;
END;


PROCEDURE GotoXYAnsi(x,y: word);
BEGIN
     WRITEANSI(#27+'['+_String(y)+';'+_String(x)+'f',False);
END;


PROCEDURE ClrEolANSI;
BEGIN
     WRITEANSI(CHR(27)+'[K',false);
END;


PROCEDURE SysopFullChat;
VAR  c           : char;
     prior       : Longint;
     current     : Longint;
     difference  : Longint;
     sysop_key   : char;
     user_key    : char;
     who_last    : byte;
     Loop        : Word;
     SysopX      : Word;
     SysopY      : Word;
     UserX       : Word;
     UserY       : Word;
     OldTime     : Longint;
     OldSysop    : String[30];
     OldAlias    : String[30];
     AnsDir      : String[50];
     TFile       : Text;
     Temp        : String;
LABEL              Skip;

     PROCEDURE NextLineSysop;
     BEGIN
          SendCrLf(1);
          INC(SysopY);
          IF SysopY=12 THEN SysopY := 3;
          SysopX := 1;
          GotoXYANSI(SysopX,SysopY);
          ClrEolANSI;
          IF SysopY=11 THEN
          BEGIN
               GotoXYANSI(1,3);
               ClrEolANSI;
               GotoXYANSI(SysopX,SysopY);
          END
          ELSE
          BEGIN
               GotoXYANSI(1,SysopY+1);
               ClrEolANSI;
               GotoXYANSI(SysopX,SysopY);
          END;
     END;

     PROCEDURE NextLineUser;
     BEGIN
          SendCrLf(1);
          INC(UserY);
          IF UserY=24 THEN UserY := 15;
          UserX := 1;
          GotoXYANSI(UserX,UserY);
          ClrEolANSI;
          IF UserY=23 THEN
          BEGIN
               GotoXYANSI(1,15);
               ClrEolANSI;
               GotoXYANSI(UserX,UserY);
          END
          ELSE
          BEGIN
               GotoXYANSI(1,UserY+1);
               ClrEolANSI;
               GotoXYANSI(UserX,UserY);
          END;
     END;

BEGIN
     PutStringTimeout(BBSPort,#255#120#13,YappDelay);
     IF GetYAPPAck THEN
     BEGIN
          bsWriteLog('Chatting with the sysop',True);
          DoNodeActivity(39,'');
          OldTime  := RemainingTimeInSecs(UsersTicker);
          OldSysop := System_Info.Sysop;
          OldAlias := System_Info.Alias;
          GetChatName;
          Save_Screen2;
          AnsDir := SGDirectory;
          FOR Loop := LENGTH(AnsDir) DOWNTO 1 DO
          BEGIN
               IF AnsDir[Loop]='\' THEN
               BEGIN
                    AnsDir[0] := Chr(Loop-1);
                    GOTO Skip;
               END;
          END;
          Skip:
          Loop := 1;
          ASSIGN(TFile,AnsDir+'\ANSI\SYSCHAT.ANS');
          {$I-}
          RESET(TFile);
          {$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     READLN(TFile,Temp);
                     Temp := process_special(Temp,False);
                     IF Loop=1 THEN WRITEANSI(Temp,false)
                     ELSE
                     BEGIN
                          SendCrLf(1);
                          WRITEANSI(Temp,false);
                     END;
                     INC(Loop);
               UNTIL EOF(TFile);
               CLOSE(TFile);
          END;
          GotoXY(1,3);
          TextColor(7);  WRITE(' Press ');
          TextColor(8);  WRITE('[');
          TextColor(14); WRITE('ESC');
          TextColor(8);  WRITE(']');
          TextColor(7);  WRITE(' To Exit ');
          SysopX := 1;
          SysopY := 4;
          UserX  := 1;
          UserY  := 15;
          Back(0);
          Fore(7);
          GotoXYANSI(SysopX,SysopY);
          who_last := 0;
          REPEAT
                IF KeyPressed THEN
                BEGIN
                     sysop_key := ReadKey;
                     IF ORD(sysop_key)=0 THEN
                     BEGIN
                          sysop_key := ReadKey;
                     END
                     ELSE
                     BEGIN
                          IF who_last<>2 THEN GotoXYANSI(sysopx,sysopy);
                          who_last := 2;
                          IF ((sysop_key=' ') AND (SysopX>70)) THEN
                          BEGIN
                               NextLineSysop;
                          END
                          ELSE IF ORD(sysop_key)=13 THEN
                          BEGIN
                               NextLineSysop;
                          END
                          ELSE IF ((ORD(sysop_key)=8) AND (SysopX>1)) THEN
                          BEGIN
                               WRITEANSI(#$08+' '+#$08,false);
                               DEC(SysopX);
                          END
                          ELSE
                          BEGIN
                               IF GoodKey(sysop_key) THEN
                               BEGIN
                                    WRITECHAR(sysop_key);
                                    INC(SysopX);
                                    IF SysopX=80 THEN NextLineSysop;
                               END;
                          END;
                     END;
                END;
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,User_Key);
                     IF ord(User_Key)=0 THEN
                     BEGIN
                          GetChar(BBSPort,User_Key);
                     END
                     ELSE IF ord(User_Key)=27 THEN
                     BEGIN
                          _Delay(30);
                          FlushInBuffer(BBSPort);
                     END
                     ELSE
                     BEGIN
                          IF who_last<>1 THEN GotoXYANSI(userx,usery);
                          who_last := 1;
                          IF ((user_key=' ') AND (UserX>70)) THEN
                          BEGIN
                               NextLineUser;
                          END
                          ELSE IF ORD(user_key)=13 THEN
                          BEGIN
                               NextLineUser;
                          END
                          ELSE IF ((ORD(user_key)=8) AND (userX>1)) THEN
                          BEGIN
                               WRITEANSI(#$08+' '+#$08,false);
                               DEC(userX);
                          END
                          ELSE
                          BEGIN
                               IF GoodKey(user_key) THEN
                               BEGIN
                                    WRITECHAR(user_key);
                                    INC(userX);
                                    IF UserX=80 THEN NextLineUser;
                               END;
                          END;
                     END;
                END
                ELSE CheckForCarrier;
          UNTIL (ord(sysop_key)=27);
          NewTimerSecs(UsersTicker,OldTime);
          System_Info.Sysop := OldSysop;
          System_Info.Alias := OldAlias;
          Restore_Screen2;
          PutStringTimeout(BBSPort,#255#121#13,YappDelay);
          IF NOT(GetYAPPAck) THEN
          BEGIN
               bsWriteLog('Graphics session lost on return from chat',True);
               Halt;
          END;
     END;
     RunTheChat := False;
END;


END.
