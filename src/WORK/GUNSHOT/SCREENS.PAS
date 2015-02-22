{$I DEFINES.INC}
UNIT Screens;


INTERFACE


FUNCTION  DisplayGraphicsFile(ATemp: String; Cr,UseBuf,AddLastSpace,Log,IsPrompt: Boolean): Boolean;
PROCEDURE system_prompt(insert_text: string; file_index: word; cr_lf,AddLastSpace: boolean);
PROCEDURE full_heading(work: string);


IMPLEMENTATION


USES Globals,ApCom,Special,SBuffer,Crt,ANSIMisc,BsString,
     Comm,KeyInput,Status,ErrorLog,BsKeys,BsFile;


FUNCTION DisplayGraphicsFile(ATemp: String; Cr,UseBuf,AddLastSpace,Log,IsPrompt: Boolean): Boolean;
VAR  Counter      : Word;
     AnsiFile     : Text;
     pretemp      : String;
     Temp         : String;
     Buf          : Array[1..8192] Of Char;
     C            : Char;
     IsRipError   : Boolean;

     PROCEDURE SendTheFile(FName: String);
     VAR  loop : Word;
     BEGIN
          IF ((IsRip) AND NOT(IsPrompt)) THEN ResetRip;
          AnsiHideEverything;
          ASSIGN(AnsiFile,FName);
          SetTextBuf(AnsiFile,Buf);
          RESET(AnsiFile);
          Counter := 0;
          REPEAT
                READLN(AnsiFile,Temp);
                INC(Counter);
                IF UseBuf THEN Temp := ProcessBuffer(Temp,False);
                IF Temp<>DontSend THEN
                BEGIN
                     IF (Counter<>1) THEN SendCrLf(1);
                     IF (Pos('{PAUSE}',Temp)<>0) THEN
                     BEGIN
                          System_Prompt('',60,false,False);
                          IF NOT(LocalLogon) THEN ClearInBuffer;
                          AnsiShowEverything;
                          REPEAT
                                c := GetKeyPress;
                          UNTIL ((c=#13) OR (c=#27));
                          AnsiHideEverything;
                          GotoXYAnsi(WhereX,WhereY);
                          ClrEolANSI;
                          Counter := 0;
                     END
                     ELSE WRITEANSI(Temp,false,true);
                END;
          UNTIL EOF(AnsiFile);
          CLOSE(AnsiFile);
               IF Cr=True THEN SendCrLf(1)
          ELSE IF AddLastSpace THEN WRITEANSI(' ',false,true);
          AnsiShowEverything;
          Status_Line;
     END;

BEGIN
     pretemp    := atemp;
     atemp      := atemp+'.ANS';
     DidHeader  := False;
     DidHeader2 := False;
     DidMsgInfo := False;
     IF ((IsRip) AND (_FileExists(RIPDirectory+'\'+pretemp+'.RIP'))) THEN
     BEGIN
          ResetRip;
          AnsiHideEverything;
          IsRipError := False;
          ASSIGN(AnsiFile,RIPDirectory+'\'+pretemp+'.RIP');
          SetTextBuf(AnsiFile,Buf);
          RESET(AnsiFile);
          REPEAT
            READLN(AnsiFile,Temp);
            IF ((Temp[1]<>#255) AND (Temp<>'')) THEN
            BEGIN
              Temp := Process_Special(Temp,False);
              IF UseBuf THEN Temp := ProcessBuffer(Temp,True);
              {Send Remote First}
              IF NOT(LocalLogon) THEN PutString(BBSPort,Temp+#13#10);
              {Draw Locally}
              IF RipInitialized THEN
              BEGIN
                IF Temp[Ord(Temp[0])]='\' THEN
                BEGIN
                  DEC(Temp[0]);
                  RIP^.ParseRipStr(Temp,False);
                END
                ELSE RIP^.ParseRipStr(Temp+#13#10,False);
              END;
            END;
          UNTIL EOF(AnsiFile);
          CLOSE(AnsiFile);
          AnsiShowEverything;
          Status_Line;
          DisplayGraphicsFile := True;
          Exit;
     END
     ELSE IF _FileExists(ANSIDirectory+'\'+atemp) THEN
     BEGIN
          SendTheFile(ANSIDirectory+'\'+atemp);
          DisplayGraphicsFile := True;
          Exit;
     END;
     IF Log THEN DoErrorLog(13,atemp);
     DisplayGraphicsFile := False;
END;


PROCEDURE system_prompt(insert_text: string;file_index: word;cr_lf,AddLastSpace: boolean);
BEGIN
     ClearBuffer;
     AddToBuffer('@INSERT',insert_text);
     DisplayGraphicsFile('_P'+_String(file_index),Cr_Lf,True,AddLastSpace,True,True);
END;


PROCEDURE full_heading(work: string);
BEGIN
     ClearBuffer;
     AddToBuffer('@HEADER',Work);
     DisplayGraphicsFile('FULLHEAD',True,True,True,True,False);
END;


END.
