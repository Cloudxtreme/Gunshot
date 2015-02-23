{$I DEFINES.INC}
UNIT Comm;


INTERFACE


PROCEDURE InitializeModem;
PROCEDURE RemoveARQ           (VAR InString: String);
FUNCTION  ReturnOk            (InString: String)                            : Boolean;
FUNCTION  RemoveBrackets      (InString: String)                            : String;
FUNCTION  PPos                (SrchString: String)                          : Word;
FUNCTION  Comm_Rx_String      (CheckDblEsc,CheckEMSIs,CheckFTSC: Boolean)   : Boolean;
FUNCTION  Comm_Rx_String_EMSI_No_Process                                    : Boolean;
FUNCTION  Comm_Rx_String_IDENT                                              : Boolean;
FUNCTION  Comm_Rx_String_EMSI                                               : Boolean;
FUNCTION  ProcessIncoming                                                   : String;
FUNCTION  Comm_Rx_Akas                                                      : Boolean;


IMPLEMENTATION


USES Globals,ApUart,ApFossil,ApDigi14,ApPort,ApCom,ApInt14,ApMisc,BsKeys,
     BsMulti,ApFax12,ApTimer,DrawScrn,Sema,Time,BsString,BsCom,Crt;


FUNCTION Comm_Rx_String(CheckDblEsc,CheckEMSIs,CheckFTSC: Boolean): Boolean;
VAR  c       : Char;
     AllDone : Boolean;
     NumEsc  : Word;
BEGIN
     InBuffer := 0;
     AllDone  := False;
     NumEsc   := 0;
     REPEAT
           GetCharTimeout(bsBBSPort,c,40);
           IF AsyncStatus=ecOk THEN
           BEGIN
                IF Ord(c)=13 THEN
                BEGIN
                     INC(InBuffer);
                     ModemBuffer[InBuffer] := C;
                     AllDone := True;
                END
                ELSE IF ((Ord(c)=32) AND (CheckFTSC)) THEN
                BEGIN
                     INC(InBuffer);
                     ModemBuffer[InBuffer] := C;
                     AllDone := True;
                END
                ELSE
                BEGIN
                     IF CheckFTSC THEN
                     BEGIN
                          IF C=#$05 THEN AllDone := True;
                          IF C=#$F1 THEN AllDone := True;
                          IF C=#$AE THEN AllDone := True;
                     END;
                     IF Ord(C)=27 THEN INC(NumEsc);
                     INC(InBuffer);
                     ModemBuffer[InBuffer] := C;
                     IF ((CheckDblEsc) AND (NumEsc=2)) THEN AllDone := True;
                END;
           END
           ELSE AllDone := True;
           IF ((CheckEMSIs) AND (NOT(AllDone))) THEN
           BEGIN
                IF (PPos(_Mid(EMSI_INQ,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_REQ,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_ACK,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_NAK,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_CLI,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_ICI,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_HBT,3,14))<>0) THEN AllDone := True;
                IF (PPos(_Mid(EMSI_IRQ,3,14))<>0) THEN AllDone := True;
           END;
     UNTIL AllDone;
     IF InBuffer=0 THEN Comm_Rx_String := False
                   ELSE Comm_Rx_String := True;
END;


FUNCTION ReturnOk(InString: String): Boolean;
BEGIN
     ReturnOk := False;
     ResultType := 0;
     IF InString='' THEN
     BEGIN
          ReturnOk := False;
          Exit;
     END;
     IF ((ExtCodes.Busy<>'') AND (ExtCodes.Busy=InString)) THEN
     BEGIN
          ResultType := 2;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Error<>'') AND (ExtCodes.Error=InString)) THEN
     BEGIN
          ResultType := 3;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Fax<>'') AND (ExtCodes.Fax=InString)) THEN
     BEGIN
          ResultType := 4;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.NoAnswer<>'') AND (ExtCodes.NoAnswer=InString)) THEN
     BEGIN
          ResultType := 5;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.NoCarrier<>'') AND (ExtCodes.NoCarrier=InString)) THEN
     BEGIN
          ResultType := 6;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.NoDialTone<>'') AND (ExtCodes.NoDialTone=InString)) THEN
     BEGIN
          ResultType := 7;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Ok<>'') AND (ExtCodes.Ok=InString)) THEN
     BEGIN
          ResultType := 8;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Ring<>'') AND (ExtCodes.Ring=InString)) THEN
     BEGIN
          ResultType := 9;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Ringing<>'') AND (ExtCodes.Ringing=InString)) THEN
     BEGIN
          ResultType := 10;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.Voice<>'') AND (ExtCodes.Voice=InString)) THEN
     BEGIN
          ResultType := 11;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.CIDDate<>'') AND (Pos(ExtCodes.CIDDate,InString)=1)) THEN
     BEGIN
          ResultType := 12;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.CIDTime<>'') AND (Pos(ExtCodes.CIDTime,InString)=1)) THEN
     BEGIN
          ResultType := 13;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.CIDName<>'') AND (Pos(ExtCodes.CIDName,InString)=1)) THEN
     BEGIN
          ResultType := 14;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.CIDNumber<>'') AND (Pos(ExtCodes.CIDNumber,InString)=1)) THEN
     BEGIN
          ResultType := 15;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef1<>'') AND (Pos(ExtCodes.UserDef1,InString)=1)) THEN
     BEGIN
          ResultType := 16;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef2<>'') AND (Pos(ExtCodes.UserDef2,InString)=1)) THEN
     BEGIN
          ResultType := 17;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef3<>'') AND (Pos(ExtCodes.UserDef3,InString)=1)) THEN
     BEGIN
          ResultType := 18;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef4<>'') AND (Pos(ExtCodes.UserDef4,InString)=1)) THEN
     BEGIN
          ResultType := 19;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef5<>'') AND (Pos(ExtCodes.UserDef5,InString)=1)) THEN
     BEGIN
          ResultType := 20;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef6<>'') AND (Pos(ExtCodes.UserDef6,InString)=1)) THEN
     BEGIN
          ResultType := 21;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef7<>'') AND (Pos(ExtCodes.UserDef7,InString)=1)) THEN
     BEGIN
          ResultType := 22;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef8<>'') AND (Pos(ExtCodes.UserDef8,InString)=1)) THEN
     BEGIN
          ResultType := 23;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef9<>'') AND (Pos(ExtCodes.UserDef9,InString)=1)) THEN
     BEGIN
          ResultType := 24;
          ReturnOk := True;
          Exit;
     END;
     IF ((ExtCodes.UserDef10<>'') AND (Pos(ExtCodes.UserDef10,InString)=1)) THEN
     BEGIN
          ResultType := 25;
          ReturnOk := True;
          Exit;
     END;
     ASSIGN(FErrLevel,Gunshot_Directory+'\DATA\ERRLEVEL.'+_String(SimNode));
     RESET(FErrLevel);
     REPEAT
           READ(FErrLevel,ErrLevel);
           IF (ErrLevel.ConnectMessage<>'') THEN
           BEGIN
                IF Pos(ErrLevel.ConnectMessage,InString)=1 THEN
                BEGIN
                     ResultType := 1;
                     ReturnOk := True;
                     CLOSE(FErrLevel);
                     Exit;
                END;
           END;
     UNTIL EOF(FErrLevel);
     CLOSE(FErrLevel);
END;


FUNCTION RemoveBrackets(InString: String): String;
VAR  Pos1 : Word;
     Pos2 : Word;
BEGIN
     Pos1 := Pos('{',InString);
     Pos2 := Pos('}',InString);
     InString := _Mid(InString,Pos1+1,Pos2-1);
     RemoveBrackets := InString;
END;


PROCEDURE InitializeModem;
VAR   Loop      : Word;
      Temp      : String;
      BytesSent : Word;
      Work      : Longint;
      WeeWee    : EventTimer;

      PROCEDURE Collect;
      VAR   TTT : EventTimer;
      LABEL       OverAgain;
      BEGIN
           OverAgain:
           NewTimer(TTT,36);
           WHILE (NOT(CharReady(bsBBSPort)) AND NOT(TimerExpired(TTT))) DO TimeSlice;
           IF CharReady(bsBBSPort) THEN
           BEGIN
                ProcessIncoming;
                IF ReturnOk(ModemResult) THEN ModemStatusWindow(ModemResult)
                                         ELSE GOTO OverAgain;
           END;
      END;

      PROCEDURE DoDelay;
      BEGIN
           REPEAT
                 TimeSlice;
           UNTIL (ElapsedTimeInMSecs(WeeWee)>=NodeInfo.CommandDelay);
      END;

BEGIN
     FOR Loop := 1 TO 3 DO
     BEGIN
       IF NodeInfo.InitString[Loop]<>'' THEN
       BEGIN
         Temp := NodeInfo.InitString[Loop]+#13;
         PutBlockDirect(bsBBSPort,Temp[1],LENGTH(Temp),BytesSent);
         NewTimer(WeeWee,1440);
         Collect;
         DoDelay;
       END;
     END;
     IF MailerInfo.HandleFaxes THEN
     BEGIN
          {Set Fax Class}
          CASE FaxCodes.FaxRecvClass OF
          1:   Temp := 'AT+FCLASS=1'+#13;
          2:   Temp := 'AT+FCLASS=2'+#13;
          3:   Temp := 'AT+FCLASS=2.0'+#13;
          END;
          PutBlockDirect(bsBBSPort,Temp[1],LENGTH(Temp),BytesSent);
          bsClearInBuffer;
          {Turn On Adaptive Answer}
          IF FaxCodes.FaxRecvClass=3
             THEN Temp := 'AT+FAA=1;+FNR=1,1,1,1'+#13
             ELSE Temp := 'AT+FAA=1'+#13;
          PutBlockDirect(bsBBSPort,Temp[1],LENGTH(Temp),BytesSent);
          bsClearInBuffer;
          {Turn On Hardware Handshaking}
          Temp := FaxCodes.SetHardwareCompression+#13;
          PutBlockDirect(bsBBSPort,Temp[1],LENGTH(Temp),BytesSent);
          bsClearInBuffer;
     END;
     IF Mailer2Info.UseSpeakerToggle THEN
     BEGIN
          Work := Getting_Time;
          IF ((Work>=Mailer2Info.SpeakerStart) AND (Work<=Mailer2Info.SpeakerEnd))
             THEN Temp := 'ATM1'+#13
             ELSE Temp := 'ATM0'+#13;
          PutBlockDirect(bsBBSPort,Temp[1],LENGTH(Temp),BytesSent);
          NewTimer(WeeWee,1440);
          Collect;
     END;
     IF TimerWait<3600 THEN
     BEGIN
          TimerWait := TimerWait*4;
          IF (TimerWait>3600) THEN TimerWait := 3600;
     END;
     NewTimerSecs(InitTimer,TimerWait);
     Waiting := False;
     RingCount := 0;
END;


PROCEDURE RemoveARQ(VAR InString: String);
VAR  Work : Word;
BEGIN
     Delete(InString,1,8);
     Work := Pos('/',InString);
     IF (Work<>0) THEN InString[0] := Chr(Work-1);
     Work := Pos(' ',InString);
     IF (Work<>0) THEN InString[0] := Chr(Work-1);
     InString := 'CONNECT '+InString;
END;


FUNCTION ProcessIncoming: String;
VAR  C    : Char;
     Done : Boolean;
LABEL       OneMoreTry;
BEGIN
     ModemResult := '';
     ResultType  := 0;
     IF CharReady(bsBBSPort) THEN
     BEGIN
          OneMoreTry:
          ModemResult := '';
          ResultType  := 0;
          Done        := False;
          REPEAT
                GetCharTimeout(bsBBSPort,c,40);
                IF AsyncStatus=ecOk THEN
                BEGIN
                     IF (Ord(c)>31) THEN ModemResult := ModemResult+c;
                     IF Ord(C)=13 THEN Done := True;
                END
                ELSE Done := True;
          UNTIL Done;
          IF ((ModemResult<>'') AND (NOT(ReturnOk(ModemResult)))) THEN GOTO OneMoreTry;
     END
     ELSE TimeSlice;
     ProcessIncoming := ModemResult;
END;


FUNCTION PPos(SrchString: String): Word;
VAR  Loop    : Word;
     Loop2   : Word;
     FoundAt : Integer;
     Start   : Word;
     Screwed : Boolean;
LABEL          PassIt;
BEGIN
     FoundAt := 0;
     IF InBuffer<>0 THEN
     BEGIN
          FOR Loop := 1 TO InBuffer DO
          BEGIN
               IF ModemBuffer[Loop]=SrchString[1] THEN
               BEGIN
                    Start   := Loop;
                    Screwed := False;
                    FOR Loop2 := Start TO (Start+Length(SrchString)-1) DO
                    BEGIN
                         IF ModemBuffer[Loop2]<>SrchString[Loop2-Start+1] THEN
                         BEGIN
                              Screwed := True;
                              GOTO PassIt;
                         END;
                    END;
                    PassIt:
                    IF NOT(Screwed) THEN
                    BEGIN
                         PPos := Start;
                         Exit;
                    END;
               END;
          END;
     END;
     PPos := 0;
END;


PROCEDURE GrabEscapeCharacter;
VAR  C       : Char;
     EscTemp : String;
BEGIN
     GetCharTimeout(bsBBSPort,c,40);
     IF AsyncStatus=ecOk THEN
     BEGIN
          IF C='\' THEN
          BEGIN
               INC(InBuffer);
               ModemBuffer[InBuffer] := C;
          END
          ELSE
          BEGIN
               EscTemp := '$'+C;
               GetCharTimeout(bsBBSPort,c,40);
               IF AsyncStatus=ecOk THEN
               BEGIN
                    IF ((C='}') OR (C=']')) THEN
                    BEGIN
                         INC(InBuffer);
                         ModemBuffer[InBuffer] := '\';
                         INC(InBuffer);
                         ModemBuffer[InBuffer] := C;
                    END
                    ELSE
                    BEGIN
                         EscTemp := EscTemp+C;
                         INC(InBuffer);
                         ModemBuffer[InBuffer] := Chr(_Numeric(EscTemp));
                    END;
               END;
          END;
     END
     ELSE
     BEGIN
          INC(InBuffer);
          ModemBuffer[InBuffer] := C;
     END;
END;


FUNCTION Comm_Rx_String_EMSI: Boolean;
VAR  c       : Char;
     AllDone : Boolean;
LABEL          OverAgain;
BEGIN
     OverAgain:
     InBuffer := 0;
     AllDone  := False;
     REPEAT
           GetCharTimeout(bsBBSPort,c,40);
           IF AsyncStatus=ecOk THEN
           BEGIN
                CASE C OF
                '}': BEGIN
                          INC(InBuffer);
                          ModemBuffer[InBuffer] := C;
                          IF InBuffer=1 THEN GOTO OverAgain;
                     END;
                '\': GrabEscapeCharacter;
                ELSE BEGIN
                          INC(InBuffer);
                          ModemBuffer[InBuffer] := C;
                     END;
                END;
           END
           ELSE AllDone := True;
           IF ModemBuffer[InBuffer]='}' THEN AllDone := True;
     UNTIL AllDone;
     IF InBuffer=0 THEN Comm_Rx_String_EMSI := False
                   ELSE Comm_Rx_String_EMSI := True;
END;


FUNCTION Comm_Rx_String_EMSI_No_Process: Boolean;
VAR  c       : Char;
     AllDone : Boolean;
LABEL          OverAgain;
BEGIN
     OverAgain:
     InBuffer := 0;
     AllDone  := False;
     REPEAT
           GetCharTimeout(bsBBSPort,c,40);
           IF AsyncStatus=ecOk THEN
           BEGIN
                CASE C OF
                '}': BEGIN
                          INC(InBuffer);
                          ModemBuffer[InBuffer] := C;
                          IF InBuffer=1 THEN GOTO OverAgain;
                     END;
                ELSE BEGIN
                          INC(InBuffer);
                          ModemBuffer[InBuffer] := C;
                     END;
                END;
           END
           ELSE AllDone := True;
           IF ModemBuffer[InBuffer]='}' THEN AllDone := True;
     UNTIL AllDone;
     IF InBuffer=0 THEN Comm_Rx_String_EMSI_No_Process := False
                   ELSE Comm_Rx_String_EMSI_No_Process := True;
END;


FUNCTION Comm_Rx_Akas: Boolean;
VAR  c           : Char;
     GetAkaTimer : EventTimer;
BEGIN
     NewTimerSecs(GetAkaTimer,10);
     InBuffer := 0;
     REPEAT
       IF CharReady(bsBBSPort) THEN
       BEGIN
         GetChar(bsBBSPort,C);
         CASE C OF
         '}': BEGIN
                IF (InBuffer<>0) THEN
                BEGIN
                  INC(InBuffer);
                  ModemBuffer[InBuffer] := C;
                  Comm_Rx_Akas := True;
                  Exit;
                END;
              END;
         ELSE BEGIN
                INC(InBuffer);
                ModemBuffer[InBuffer] := C;
              END;
         END;
       END
       ELSE TimeSlice;
     UNTIL TimerExpired(GetAkaTimer);
     Comm_Rx_Akas := False;
END;


FUNCTION Comm_Rx_String_IDENT: Boolean;
VAR  c       : Char;
     AllDone : Boolean;
BEGIN
     InBuffer := 0;
     AllDone  := False;
     REPEAT
           GetCharTimeout(bsBBSPort,c,40);
           IF AsyncStatus=ecOk THEN
           BEGIN
                CASE C OF
                '\': GrabEscapeCharacter;
                ELSE BEGIN
                          INC(InBuffer);
                          ModemBuffer[InBuffer] := C;
                     END;
                END;
           END
           ELSE AllDone := True;
           IF ModemBuffer[InBuffer]=#13 THEN AllDone := True;
     UNTIL AllDone;
     IF InBuffer=0 THEN Comm_Rx_String_IDENT := False
                   ELSE Comm_Rx_String_IDENT := True;
END;


END.
