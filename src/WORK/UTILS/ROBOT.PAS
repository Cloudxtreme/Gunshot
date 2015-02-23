{$IFDEF DPMI}
Hello there???
{$ENDIF}
{$I DEFINES.INC}
PROGRAM Robot;
{$M 64000,0,655360}


USES MKMsgAbs,MKOpen,MKGlobT,MKDos,Dos,Crt,BsAkas,
     MKString,BsVideo,Version,Gunshot,BsString;


VAR  Sender      : String;
     SenderAddr  : String;
     FileToSend  : String;
     MessageText : String;
     F           : Text;
     OrigAddr    : AddrType;
     DestAddr    : AddrType;
     InString    : String;
     DestSysop   : String;
     BasePath    : String;
     F2          : Text;
     Msg         : AbsMsgPtr;


PROCEDURE CleanLines;
VAR  Work  : Word;
BEGIN
     {CLEAN IDENTIFIER LINES}
     Delete(Sender,1,5);
     REPEAT
           IF Sender[1]=' ' THEN Delete(Sender,1,1);
     UNTIL Sender[1]<>' ';
     Delete(FileToSend,1,5);
     REPEAT
           IF FileToSend[1]=' ' THEN Delete(FileToSend,1,1);
     UNTIL FileToSend[1]<>' ';
     Delete(MessageText,1,8);
     REPEAT
           IF MessageText[1]=' ' THEN Delete(MessageText,1,1);
     UNTIL MessageText[1]<>' ';
     Delete(BasePath,1,9);
     REPEAT
           IF BasePath[1]=' ' THEN Delete(BasePath,1,1);
     UNTIL BasePath[1]<>' ';

     Work       := Pos(' ',Sender);
     SenderAddr := _Mid(Sender,1,Work-1);
     Delete(Sender,1,Work);
     REPEAT
           IF Sender[1]=' ' THEN Delete(Sender,1,1);
     UNTIL Sender[1]<>' ';
     StringToAddress(SenderAddr,OrigAddr);
END;


PROCEDURE CleanDestination;
VAR  Work  : Word;
     Temp  : String;
BEGIN
     {CLEAN IDENTIFIER LINES}
     Work       := Pos(' ',InString);
     Temp       := _Mid(InString,1,Work-1);
     Delete(InString,1,Work);
     REPEAT
           IF InString[1]=' ' THEN Delete(InString,1,1);
     UNTIL InString[1]<>' ';
     DestSysop := InString;
     InString  := Temp;
     StringToAddress(Temp,DestAddr);
END;


BEGIN
     AppHeader('Robot - Netmail Robot For Gunshot Professional');
     IF ParamStr(1)='' THEN Halt;
     ASSIGN(F,ParamStr(1));
     {$I-}
     RESET(F);
     {$I+}
     IF IOResult=0 THEN
     BEGIN
          READLN(F,Sender);
          READLN(F,FileToSend);
          READLN(F,MessageText);
          READLN(F,BasePath);
          CleanLines;
          GOTOXY(1,7);  ClrEol;
          GOTOXY(1,8);  ClrEol;
          GOTOXY(1,9);  ClrEol;
          GOTOXY(1,10); ClrEol;
          GOTOXY(1,11); ClrEol;
          GOTOXY(1,7);
          WRITELN(' Message From: '+Sender);
          WRITELN('  Origin Addr: '+SenderAddr);
          WRITELN('Attached File: '+FileToSend);
          WRITELN(' Message Body: '+MessageText);
          WRITELN('Fido MSG Path: '+BasePath);
          REPEAT
                IF NOT(EOF(F)) THEN
                BEGIN
                     READLN(F,InString);
                     IF InString[1]<>';' THEN
                     BEGIN
                          CleanDestination;
                          IF OpenOrCreateMsgArea(Msg,'F'+BasePath,1000) THEN
                          BEGIN
                               Msg^.StartNewMsg;
                               Msg^.SetEcho     (True);
                               Msg^.SetMailType (mmtNetMail);
                               Msg^.SetOrig     (OrigAddr);
                               Msg^.SetDest     (DestAddr);
                               Msg^.SetFAttach  (True);
                               Msg^.SetFileReq  (False);
                               Msg^.SetFrom     (Sender);
                               Msg^.SetTo       (DestSysop);
                               Msg^.SetSubj     (FileToSend);
                               Msg^.SetPriv     (True);
                               Msg^.SetDate     (DateStr(GetDosDate));
                               Msg^.SetTime     (TimeStr(GetDosDate));
                               Msg^.SetLocal    (True);
                               Msg^.SetKillSent (True);
                               Msg^.DoStringLn(GetMsgId(OrigAddr));
                               Msg^.DoStringLn(CHR(1)+'PID: GSRobot '+GunshotVersion);

                               ASSIGN(F2,MessageText);
                               {$I-}
                               RESET(F2);
                               {$I+}
                               IF IOResult=0 THEN
                               BEGIN
                                    REPEAT
                                          READLN(F2,InString);
                                          IF (Length(InString)>0)
                                             THEN Msg^.DoStringLn(InString)
                                             ELSE Msg^.DoStringLn('');
                                    UNTIL EOF(F2);
                                    CLOSE(F2);
                               END;
                               Msg^.DoStringLn('');
                               Msg^.DoStringLn('---Created by GSRobot '+GunshotVersion);
                               IF Msg^.WriteMsg=0 THEN;
                               IF CloseMsgArea(Msg) THEN;
                          END;
                     END;
                END;
          UNTIL EOF(F);
          CLOSE(F);
     END;
END.
