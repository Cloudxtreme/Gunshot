{$I DEFINES.INC}
UNIT Misc;


INTERFACE


USES Globals,Shotgun;


PROCEDURE ResetDialTimer;
PROCEDURE DialPhone (Num: Byte);
FUNCTION  TakeOutTheC(InString: String): String;
FUNCTION  IsOurNode (InAddress: AddrType): Boolean;


IMPLEMENTATION


USES NList,DrawScrn,BsMulti,ApCom,BsFile,BsAkas,BsString,BsCom,BsLog,ApTimer;


PROCEDURE DoSpecialInit(TheAddress: AddrType);
VAR  Inits  : _Mailer_Inits;
     FInits : File Of _Mailer_Inits;
BEGIN
     IF MailerInfo.HandleFaxes THEN bsSendCommandString('AT+FCLASS=0',NodeInfo.CommandDelay);
     IF _FileExists(Shotgun_Directory+'\DATA\INITS.'+_String(SimNode)) THEN
     BEGIN
       ASSIGN(FInits,Shotgun_Directory+'\DATA\INITS.'+_String(SimNode));
       RESET(FInits);
       REPEAT
         READ(FInits,Inits);
         IF AkasMatch(Inits.CallAddress,TheAddress) THEN
         BEGIN
           bsSendCommandString(Inits.InitString,NodeInfo.CommandDelay);
         END;
       UNTIL EOF(FInits);
       CLOSE(FInits);
     END;
END;


PROCEDURE SetupParams(CallAddr: AddrType);
VAR  AllDone : Boolean;
BEGIN
     DoEmsi   := True;
     DoYooHoo := True;
     IF Mailer2Info.UseZedZapTransfers
        THEN DoZap := True
        ELSE DoZap := False;
     IF _FileExists('\SHOTGUN\DATA\PASSWORD.DAT') THEN
     BEGIN
          AllDone := False;
          ASSIGN(FSessionPW,'\SHOTGUN\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF AkasMatch(CallAddr,SessionPW.SystemAddress) THEN
                BEGIN
                     DoEmsi   := SessionPW.DoEMSI;
                     DoYooHoo := SessionPW.DoWaZOO;
                     IF Mailer2Info.UseZedZapTransfers THEN DoZap := SessionPW.DoZedZap;
                     AllDone  := True;
                END;
          UNTIL ((EOF(FSessionPW)) OR (AllDone));
          CLOSE(FSessionPW);
     END;
     IF NOT(MailerInfo.EnableEMSI) THEN DoEMSI := False;
     IF NOT(MailerInfo.EnableYooHoo) THEN DoYooHoo := False;
END;


PROCEDURE DialPhone(Num: Byte);
VAR  DialNumber : String;
BEGIN
     DialNumber := GetNodeInfo(MailQueue^[Num].DestAddr);
     IF DialNumber<>'' THEN
     BEGIN
          SetupParams(MailQueue^[Num].DestAddr);
          StatusWindow('Calling '+NodeListSystem+', '+AddressToString(MailQueue^[Num].DestAddr));
          bsWriteLog('Calling '+NodeListSystem+', '+AddressToString(MailQueue^[Num].DestAddr)+', '+NodeListPhone,False);
          DoSpecialInit(MailQueue^[Num].DestAddr);
          bsSendCommandString(NodeInfo.Dial+DialNumber,NodeInfo.CommandDelay);
          CallingOut := True;
          DrawDialWindow;
     END;
END;


FUNCTION IsOurNode(InAddress: AddrType): Boolean;
BEGIN
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     REPEAT
           READ(FNetwork,Network);
           IF AkasMatch(InAddress,Network.Net_Address) THEN
           BEGIN
                CLOSE(FNetwork);
                IsOurNode := True;
                Exit;
           END;
     UNTIL EOF(FNetwork);
     CLOSE(FNetwork);
     IsOurNode := False;
END;


PROCEDURE ResetDialTimer;
BEGIN
     IF MailerInfo.DelayFirst
        THEN NewTimerSecs(DialTimer,MailerInfo.RetryDelay)
        ELSE NewTimer(DialTimer,1);
END;


FUNCTION TakeOutTheC(InString: String): String;
VAR  Work : Byte;
BEGIN
     REPEAT
       Work := Pos('C',InString);
       IF (Work<>0) THEN InString[Work] := 'c';
     UNTIL Work=0;
     REPEAT
       Work := Pos(#$05,InString);
       IF (Work<>0) THEN InString[Work] := '.';
     UNTIL Work=0;
     REPEAT
       Work := Pos(#$15,InString);
       IF (Work<>0) THEN InString[Work] := '.';
     UNTIL Work=0;
     REPEAT
       Work := Pos('EMSI',InString);
       IF (Work<>0) THEN
       BEGIN
         Delete(InString,Work,4);
         Insert('emsi',InString,Work);
       END;
     UNTIL Work=0;
     TakeOutTheC := InString;
END;


END.
