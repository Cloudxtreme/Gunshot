{$I DEFINES.INC}
UNIT ANSIMisc;


INTERFACE


FUNCTION  get_fore(col: string): string;
PROCEDURE WRITEANSI(output_line: string; line_feed,process: boolean);
PROCEDURE WRITECHAR(character: String);
PROCEDURE ForeBack(FGround,BGround: Byte);
PROCEDURE back(col: word);
PROCEDURE fore(col: word);
PROCEDURE space(num: word);
PROCEDURE GotoXYAnsi(x,y: word);
PROCEDURE SendCrLf(Num: Byte);
PROCEDURE AnsiRight(Num: Byte);
PROCEDURE AnsiLeft(Num: Byte);
PROCEDURE ClrEolANSI;
PROCEDURE CLRPORTSCR;
PROCEDURE ResetRip;
PROCEDURE AnsiHideEveryThing;
PROCEDURE AnsiShowEveryThing;
FUNCTION  ColourString(InByte: Byte): String;


IMPLEMENTATION


USES Globals,Special,NoIBM,ApCom,ApPort,ApANSI,Status,BsString,BsKeys,RipLink;


PROCEDURE SendCrLf(Num: Byte);
VAR  Sent : Word;
     Temp : String;
     Loop : Byte;
BEGIN
     Temp := #$0D#$0A;
     FOR Loop := 1 TO Num DO
     BEGIN
       IF NOT(LocalLogon) THEN PutBlockDirect(BBSPort,Temp[1],2,Sent);
       IF IsRip THEN
       BEGIN
         RIP^.MouseOff;
         IF RipInitialized THEN RIP^.DoTextStr(Temp);
         RIP^.MouseOn;
       END
       ELSE WriteStringAnsi(Temp);
     END;
END;


PROCEDURE GotoXYAnsi(x,y: word);
BEGIN
     WRITEANSI(#27+'['+_String(y)+';'+_String(x)+'f',False,False);
END;


PROCEDURE AnsiRight(Num: Byte);
BEGIN
     WRITEANSI(#27+'['+_String(Num)+'C',False,False);
END;


PROCEDURE AnsiLeft(Num: Byte);
BEGIN
     WRITEANSI(#27+'['+_String(Num)+'D',False,False);
END;


PROCEDURE ClrEolANSI;
BEGIN
     WRITEANSI(#27+'[K',false,False);
END;


PROCEDURE space(num: word);
BEGIN
     IF (Num<=4) THEN WRITEANSI(_Replicate(' ',Num),False,False)
                 ELSE WRITEANSI(#27+'['+_String(Num)+'C',False,False);
END;


PROCEDURE back(col: word);
VAR  colour_code : String;
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
     ELSE Exit;
     END;
     WRITEANSI(colour_code,False,False);
END;


PROCEDURE fore(col: word);
VAR  colour_code : string;
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
     ELSE  Exit;
     END;
     WRITEANSI(colour_code,False,False);
END;


PROCEDURE ForeBack(FGround,BGround: Byte);
VAR  Temp : String;
BEGIN
     Temp := #27+'[';
     CASE FGround OF
     0  :  Temp := #27+'[0;30;';
     1  :  Temp := #27+'[0;34;';
     2  :  Temp := #27+'[0;32;';
     3  :  Temp := #27+'[0;36;';
     4  :  Temp := #27+'[0;31;';
     5  :  Temp := #27+'[0;35;';
     6  :  Temp := #27+'[0;33;';
     7  :  Temp := #27+'[0;37;';
     8  :  Temp := #27+'[1;30;';
     9  :  Temp := #27+'[1;34;';
     10 :  Temp := #27+'[1;32;';
     11 :  Temp := #27+'[1;36;';
     12 :  Temp := #27+'[1;31;';
     13 :  Temp := #27+'[1;35;';
     14 :  Temp := #27+'[1;33;';
     15 :  Temp := #27+'[1;37;';
     END;
     CASE BGround OF
     0:   Temp := Temp+'40m';
     1:   Temp := Temp+'44m';
     2:   Temp := Temp+'42m';
     3:   Temp := Temp+'46m';
     4:   Temp := Temp+'41m';
     5:   Temp := Temp+'45m';
     6:   Temp := Temp+'43m';
     7:   Temp := Temp+'47m';
     END;
     WRITEANSI(Temp,False,False);
END;


FUNCTION get_fore(col: string): string;
VAR  colour_code  : string;
     col_val      : word;
     Code         : Integer;
BEGIN
     colour_code := '';
     VAL(col,col_val,code);
     CASE col_val OF
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
     get_fore := colour_code;
END;


PROCEDURE CLRPORTSCR;
BEGIN
     IF IsRip THEN
     BEGIN
          WRITECHAR(#13);
          WRITECHAR(#$0C);
          BACK(0);
          FORE(15);
     END
     ELSE
     BEGIN
          BACK(0);
          FORE(15);
          WRITECHAR(#$0C);
     END;
     status_line;
END;


PROCEDURE ResetRip;
BEGIN
     IF RipInitialized THEN
     BEGIN
       RIP^.MouseOff;
       RIP^.DoTextStr(#13#10);
       RIP^.RipResetWindows;
       RIP^.MouseOn;
     END;
     IF NOT(LocalLogon) THEN
     BEGIN
       PutString(BBSPort,#13#10);
       PutString(BBSPort,'!|*'+#13#10);
     END;
END;


PROCEDURE AnsiHideEveryThing;
BEGIN
     _HideCursor;
     IF ((IsRip) AND (RipInitialized)) THEN
     BEGIN
       RIP^.MouseOff;
       RIPMouseOverride := True;
     END;
END;


PROCEDURE AnsiShowEveryThing;
BEGIN
     _ShowCursor;
     IF ((IsRip) AND (RipInitialized)) THEN
     BEGIN
       RIPMouseOverride := False;
       RIP^.MouseOn;
     END;
END;


PROCEDURE WRITEANSI(output_line: string; line_feed,process: boolean);
VAR  Sent : Word;
BEGIN
     had_a_clear := false;
     IF Process           THEN output_line := process_special(output_line,False);
     IF had_a_clear       THEN ClrPortScr;
     IF UserRecord.IBM<>1 THEN output_line := strip_ibm(output_line);
     IF line_feed         THEN output_line := output_line+#$0D#$0A;
     IF NOT(LocalLogon)   THEN PutBlockDirect(BBSPort,Output_Line[1],Ord(Output_Line[0]),Sent);
     IF IsRip THEN
     BEGIN
          RIP^.MouseOff;
          IF RipInitialized THEN RIP^.DoTextStr(output_line);
          RIP^.MouseOn;
     END
     ELSE WriteStringAnsi(output_line);
END;


PROCEDURE WRITECHAR(Character: String);
BEGIN
     IF UserRecord.Ibm<>1 THEN character := strip_ibm(character);
     IF NOT(LocalLogon)   THEN PutCharTimeout(BBSPort,character[1],182);
     IF IsRip THEN
     BEGIN
          RIP^.MouseOff;
          IF RipInitialized THEN RIP^.DoTextChar(character[1]);
          RIP^.MouseOn;
     END
     ELSE WriteCharAnsi(character[1]);
END;


FUNCTION ColourString(InByte: Byte): String;
VAR  Temp : String;
BEGIN
     Temp := '{'+_String(InByte)+'}';
     ColourString := Temp;
END;


END.
