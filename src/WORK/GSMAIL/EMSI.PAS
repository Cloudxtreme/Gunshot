{$I DEFINES.INC}
UNIT Emsi;

{===========================================================================}
{                                                                           }
{  EMSI Routines - These are the handshake, and session end/start routines  }
{                  required for EMSI type sessions. ANYTHING to do with     }
{                  EMSI is in this unit!                                    }
{                                                                           }
{===========================================================================}

INTERFACE


USES Shotgun,KeyCheck;


PROCEDURE LogOurEMSI;
PROCEDURE LogTheirEMSI;
PROCEDURE EMSIBadPassword    (BadPassword: Boolean);
PROCEDURE InitEMSIDat        (InAddress: AddrType);
PROCEDURE LoadAkaToMatch     (InAddress: AddrType);
FUNCTION  StartupMailSession (WeAreCallingOut: Boolean) : Byte;
FUNCTION  AkaIsOk            (TheAka: AddrType)         : Boolean;
FUNCTION  DoOutGoingEMSI                                : Boolean;
FUNCTION  DoInComingEMSI                                : Boolean;


IMPLEMENTATION


USES ApTimer,ApPort,BsMulti,DrawScrn,Globals,BsAkas,BsCom,BsLog,
     Comm,Banner,ApCom,Misc,Version,ApMisc,BsFile,BsString;


FUNCTION AkaIsOk(TheAka: AddrType): Boolean;
VAR  FNetwork2 : File Of _Network_Record;
     Network2  : _Network_Record;
     Temp      : String;
BEGIN
     ASSIGN(FNetwork2,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork2);
     REPEAT
       READ(FNetwork2,Network2);
       IF AkasMatch(Network2.Net_Address,TheAka) THEN
       BEGIN
         Temp := 'Invalid system address: '+AddressToString(TheAka);
         StatusWindow('!'+Temp);
         bsWriteLog(Temp,False);
         AkaIsOk := False;
         CLOSE(FNetwork2);
         Exit;
       END;
     UNTIL EOF(FNetwork2);
     CLOSE(FNetwork2);
     AkaIsOk := True;
END;

{===========================================================================}
{                                                                           }
{ Returns a word CRC16 value of a the data packet                           }
{                                                                           }
{===========================================================================}
FUNCTION emsiCRC16: Word;
VAR  wcrc : Word;
     t,r  : Word;
     Temp : String;
BEGIN
     wcrc:=0;
     Temp := 'EMSI_DAT'+Length_EMSI_DAT;
     FOR t:=1 TO Length(Temp) DO
     BEGIN
          wcrc:=(wcrc XOR (ord(temp[t]) SHL 8));
          FOR r:=1 TO 8 DO IF (wcrc AND $8000)>0
              THEN wcrc:=((wcrc SHL 1) XOR $1021)
              ELSE wcrc:=(wcrc SHL 1);
     END;
     FOR t:=1 TO ELength DO
     BEGIN
          wcrc:=(wcrc XOR (ord(EMSI_DAT[t]) SHL 8));
          FOR r:=1 TO 8 DO IF (wcrc AND $8000)>0
              THEN wcrc:=((wcrc SHL 1) XOR $1021)
              ELSE wcrc:=(wcrc SHL 1);
     END;
     emsiCRC16:=(wcrc AND $FFFF);
END;
{===========================================================================}
{                                                                           }
{ Creates your EMSI record to match the current session                     }
{                                                                           }
{===========================================================================}
PROCEDURE InitEMSIDat(InAddress: AddrType);
VAR  AllDone   : Boolean;
     tt        : String;
     Loop      : Word;
     Temp      : String;
LABEL            SkipOut;

     PROCEDURE MatchTheZone;
     BEGIN
          AllDone := False;
          ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          REPEAT
                READ(FNetwork,Network);
                IF InAddress.Zone=Network.Net_Address.Zone THEN
                BEGIN
                     YourSystem.Address := Network.Net_Address;
                     AllDone := True;
                END;
          UNTIL ((EOF(FNetwork)) OR (AllDone));
          CLOSE(FNetwork);
     END;

BEGIN
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     {THESE ARE SESSION DEPENDENT - DEFAULTS}
     YourSystem.Address := Network.Net_Address;
     YourSystem.SessionPassword := '';
     EMSIPresentAllAkas := True;
     {MATCH REMOTES ZONE}
     IF CallingOut THEN
     BEGIN
          IF ((MailerInfo.MatchZones) AND (CurrentAka=1)) THEN MatchTheZone;
     END
     ELSE MatchTheZone;
     {APPLY SESSION PASSWORD}
     IF _FileExists('\SHOTGUN\DATA\PASSWORD.DAT') THEN
     BEGIN
          AllDone := False;
          ASSIGN(FSessionPW,'\SHOTGUN\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF CallingOut THEN
                BEGIN
                     IF AkasMatch(InAddress,SessionPW.SystemAddress) THEN
                     BEGIN
                          IF CallingOut THEN EMSIPresentAllAkas := SessionPW.PresentAllAkas;
                          YourSystem.SessionPassword := _UpperCase(SessionPW.SystemPW);
                          AllDone := True;
                     END;
                END
                ELSE
                BEGIN
                     FOR Loop := 1 TO RemoteSystem.NumberOfAkas DO
                     BEGIN
                          IF AkasMatch(RemoteSystem.Akas[Loop],SessionPW.SystemAddress) THEN
                          BEGIN
                               YourSystem.SessionPassword := _UpperCase(SessionPW.SystemPW);
                               AllDone := True;
                               GOTO SkipOut;
                          END;
                     END;
                     SkipOut:
                END;
          UNTIL ((EOF(FSessionPW)) OR (AllDone));
          CLOSE(FSessionPW);
     END;
     {READ FROM SETUP FILE ONCE}
     YourSystem.Sysop              := SystemInfo.Sysop;
     YourSystem.PhoneNumber        := MailerInfo.Phone;
     YourSystem.Location           := SystemInfo.Location;
     YourSystem.BBSName            := MailerInfo.NodeName;
     YourSystem.NodelistFlags      := MailerInfo.Flags;
     YourSystem.BaudRate           := _String(MailerInfo.BaudRate);
     {THESE NEVER CHANGE!}
     YourSystem.LinkCodes          := '8N1,PUA';
     YourSystem.MailerProductCode  := '010E';
     YourSystem.MailerName         := 'SGMail';
     YourSystem.MailerVersion      := ShotgunVersion;
     IF Pos('/Gold+',OurAppName)<>0
        THEN YourSystem.MailerSerialNumber := 'Gold+'
        ELSE YourSystem.MailerSerialNumber := 'nc';
     IF CallingOut THEN
     BEGIN
          IF ((DoZap) AND (ConnectRate>=14400))
             THEN YourSystem.CompatabilityCodes := 'ZAP,ZMO,ARC,FNC,NRQ'
             ELSE YourSystem.CompatabilityCodes := 'ZMO,ARC,FNC,NRQ';
     END
     ELSE
     BEGIN
          {HYD}
          tt := _UpperCase(RemoteSystem.CompatabilityCodes);
          Temp := '';
          IF ConnectRate<MailerInfo.FreqBaud THEN Temp := ',NRQ';
          IF NOT(MailerInfo.AllowFreqs) THEN Temp := ',NRQ';
          IF ((DoZap) AND (ConnectRate>=14400)) THEN
          BEGIN
                    IF Pos('ZAP',tt)<>0 THEN YourSystem.CompatabilityCodes := 'ZAP'+Temp
               ELSE IF Pos('ZMO',tt)<>0 THEN YourSystem.CompatabilityCodes := 'ZMO'+Temp
                                        ELSE YourSystem.CompatabilityCodes := 'NCP';
          END
          ELSE
          BEGIN
               IF Pos('ZMO',tt)<>0 THEN YourSystem.CompatabilityCodes := 'ZMO'+Temp
                                   ELSE YourSystem.CompatabilityCodes := 'NCP';
          END;
     END;
END;
{===========================================================================}
{                                                                           }
{ Match A Remote's Zone                                                     }
{                                                                           }
{===========================================================================}
PROCEDURE LoadAkaToMatch(InAddress: AddrType);
VAR  AllDone : Boolean;
BEGIN
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     AllDone := False;
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     REPEAT
           READ(FNetwork,Network);
           IF InAddress.Zone=Network.Net_Address.Zone THEN AllDone := True;
     UNTIL ((EOF(FNetwork)) OR (AllDone));
     CLOSE(FNetwork);
END;
{===========================================================================}
{                                                                           }
{ Translates your EMSI record to a packet to be send during the session     }
{                                                                           }
{===========================================================================}
PROCEDURE Create_EMSI_DAT;
VAR  OurAddStr : String;
     Temp      : String;

     PROCEDURE AddAString(InString: String);
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO LENGTH(InString) DO
          BEGIN
               INC(ELength);
               EMSI_DAT[ELength] := InString[Loop];
          END;
     END;

     PROCEDURE AddThoseAkas;
     BEGIN
          ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          REPEAT
                READ(FNetwork,Network);
                Temp := AddressToString(Network.Net_Address);
                IF (Temp<>OurAddStr) THEN AddAString(' '+Temp);
          UNTIL EOF(FNetwork);
          CLOSE(FNetwork);
     END;

BEGIN
     ELength := 0;
     FillChar(EMSI_DAT,SizeOf(EMSI_DAT),0);
     IF CallingOut THEN
     BEGIN
          OurAddStr := AddressToString(YourSystem.Address);
          AddAString('{EMSI}{'+OurAddStr);
          IF EMSIPresentAllAkas THEN AddThoseAkas;
          AddAString('}{'+YourSystem.SessionPassword+'}');
          AddAString('{'+YourSystem.LinkCodes+'}');
          AddAString('{'+YourSystem.CompatabilityCodes+'}');
          AddAString('{'+YourSystem.MailerProductCode+'}');
          AddAString('{'+YourSystem.MailerName+'}');
          AddAString('{'+YourSystem.MailerVersion+'}');
          AddAString('{'+YourSystem.MailerSerialNumber+'}');
          AddAString('{IDENT}');
          AddAString('{['+YourSystem.BBSName+']');
          AddAString('['+YourSystem.Location+']');
          AddAString('['+YourSystem.Sysop+']');
          AddAString('['+YourSystem.PhoneNumber+']');
          AddAString('['+YourSystem.BaudRate+']');
          AddAString('['+YourSystem.NodelistFlags+']}');
          Length_EMSI_DAT := HexW(ELength);
     END
     ELSE
     BEGIN
          OurAddStr := AddressToString(YourSystem.Address);
          AddAString('{EMSI}{'+OurAddStr);
          IF MailerInfo.PresentAkas THEN AddThoseAkas;
          AddAString('}{'+YourSystem.SessionPassword+'}');
          AddAString('{'+YourSystem.LinkCodes+'}');
          AddAString('{'+YourSystem.CompatabilityCodes+'}');
          AddAString('{'+YourSystem.MailerProductCode+'}');
          AddAString('{'+YourSystem.MailerName+'}');
          AddAString('{'+YourSystem.MailerVersion+'}');
          AddAString('{'+YourSystem.MailerSerialNumber+'}');
          AddAString('{IDENT}');
          AddAString('{['+YourSystem.BBSName+']');
          AddAString('['+YourSystem.Location+']');
          AddAString('['+YourSystem.Sysop+']');
          AddAString('['+YourSystem.PhoneNumber+']');
          AddAString('['+YourSystem.BaudRate+']');
          AddAString('['+YourSystem.NodelistFlags+']}');
          Length_EMSI_DAT := HexW(ELength);
     END;
     CRC := HexW(emsiCRC16);
     AddAString(CRC);
END;
{===========================================================================}
{                                                                           }
{ Translates your EMSI record to a packet to be send during the session     }
{                                                                           }
{===========================================================================}
PROCEDURE Create_BAD_EMSI_DAT(BadPassword: Boolean);
VAR  OurAddStr : String;
     Temp      : String;

     PROCEDURE AddAString(InString: String);
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO LENGTH(InString) DO
          BEGIN
               INC(ELength);
               EMSI_DAT[ELength] := InString[Loop];
          END;
     END;

     PROCEDURE AddThoseAkas;
     BEGIN
          ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          REPEAT
                READ(FNetwork,Network);
                Temp := AddressToString(Network.Net_Address);
                IF (Temp<>OurAddStr) THEN AddAString(' '+Temp);
          UNTIL EOF(FNetwork);
          CLOSE(FNetwork);
     END;

BEGIN
     ELength := 0;
     FillChar(EMSI_DAT,SizeOf(EMSI_DAT),0);
     OurAddStr := AddressToString(YourSystem.Address);
     AddAString('{EMSI}{'+OurAddStr);
     IF MailerInfo.PresentAkas THEN AddThoseAkas;
     AddAString('}{}');
     AddAString('{'+YourSystem.LinkCodes+'}');
     AddAString('{'+YourSystem.CompatabilityCodes+'}');
     AddAString('{'+YourSystem.MailerProductCode+'}');
     AddAString('{'+YourSystem.MailerName+'}');
     AddAString('{'+YourSystem.MailerVersion+'}');
     AddAString('{'+YourSystem.MailerSerialNumber+'}');
     AddAString('{IDENT}');
     IF BadPassword THEN
     BEGIN
       AddAString('{[** Session Password Error! **]');
       AddAString('[** Please Check Your Setup **]');
     END
     ELSE
     BEGIN
       AddAString('{[** Your Main AKA Is Not Listed! **]');
       AddAString('[**** Please Check Your Setup *****]');
     END;
     AddAString('['+YourSystem.Sysop+']');
     AddAString('['+YourSystem.PhoneNumber+']');
     AddAString('['+YourSystem.BaudRate+']');
     AddAString('['+YourSystem.NodelistFlags+']}');
     Length_EMSI_DAT := HexW(ELength);
     CRC := HexW(emsiCRC16);
     AddAString(CRC);
END;
{===========================================================================}
{                                                                           }
{ Initial handshake to identify EMSI sessions.                              }
{                                                                           }
{===========================================================================}
FUNCTION StartupMailSession(WeAreCallingOut: Boolean): Byte; {0-FTSC 1-YOOHOO
                                                    2-EMSI 3-HUMAN/NO CARRIER}
VAR  Loop         : Word;
     UserTimer    : EventTimer;
     Timer1       : EventTimer;
     Timer2       : EventTimer;
     EscNum       : Byte;
     TSyncNum     : Byte;
     C            : Char;
     J            : Char;
     LookinMail   : Boolean;
     Temp         : String;
     DelayTimer   : EventTimer;
LABEL               OutGoing1,OutGoing2;
LABEL               Abort1,Abort2;
BEGIN
     IF WeAreCallingOut THEN
     BEGIN
       StatusWindow('Attempting to establish mail session');

       OutGoing1: {Whack Return}
                  NewTimerSecs(UserTimer,30);
                  NewTimerSecs(DelayTimer,1);
                  J := #13;
                  PutChar(bsBBSPort,J);
                  REPEAT
                    IF CharReady(bsBBSPort) THEN GOTO OutGoing2;
                    IF TimerExpired(DelayTimer) THEN
                    BEGIN
                      IF J=#13 THEN J := #32
                               ELSE J := #13;
                      PutChar(bsBBSPort,J);
                      NewTimerSecs(DelayTimer,1);
                    END
                    ELSE TimeSlice;
                  UNTIL TimerExpired(UserTimer);
                  StatusWindow('!Remote not responding to sign-on');
                  bsWriteLog('Remote not responding to sign-on',False);
                  SessionFailure := True;
                  StartupMailSession := 3;
                  Exit;

       OutGoing2: {Session Startup}
                  TSyncNum := 0;
                  Temp     := '';
                  NewTimerSecs(UserTimer,60);
                  NewTimerSecs(DelayTimer,4);
                  REPEAT
                    IF NOT(bsCarrierDetected) THEN GOTO Abort1;
                    IF CharReady(bsBBSPort) THEN
                    BEGIN
                      WHILE CharReady(bsBBSPort) DO
                      BEGIN
                        GetChar(bsBBSPort,C);
                        IF (Ord(C)>31) THEN Temp := Temp+C;
                        IF ((Pos(EMSI_REQ,Temp)<>0) AND (DoEMSI)) THEN
                        BEGIN {EMSI}
                          bsClearInBuffer;
                          bsSendString(EMSI_INQ);
                          StartupMailSession := 2;
                          Exit;
                        END
                        ELSE IF ((C=#$05) AND (DoYooHoo)) THEN
                        BEGIN {YOOHOO}
                          bsClearInBuffer;
                          StartupMailSession := 1;
                          Exit;
                        END
                        ELSE IF ((C='C') OR (C=#$15)) THEN
                        BEGIN {FTS-1}
                          IF (TSyncNum>1) THEN
                          BEGIN
                            StartupMailSession := 0;
                            Exit;
                          END;
                        END;
                        IF LENGTH(Temp)>250 THEN Delete(Temp,1,200);
                      END;
                    END
                    ELSE
                    BEGIN
                      IF TimerExpired(DelayTimer) THEN
                      BEGIN
                        IF DoEmsi THEN PutString(bsBBSPort,EMSI_INQ+EMSI_INQ);
                        IF DoYooHoo THEN PutChar(bsBBSPort,#$F1);
                        PutChar(bsBBSPort,#$AE);
                        PutChar(bsBBSPort,#13);
                        NewTimerSecs(DelayTimer,4);
                        INC(TSyncNum);
                      END
                      ELSE TimeSlice;
                    END;
                  UNTIL TimerExpired(UserTimer);
                  Abort1:
                  StatusWindow('!Session handshake timeout .004');
                  bsWriteLog('Session handshake timeout .004',False);
                  SessionFailure := True;
                  StartupMailSession := 3;
                  Exit;
     END
     ELSE
     BEGIN
       IF MailerInfo.BBSOnly THEN
       BEGIN
         HumanCaller := True;
         StartupMailSession := 3;
         Exit;
       END;
       DoEmsi      := True;
       DoYooHoo    := True;
       TSyncNum    := 0;
       EscNum      := 0;
       HumanCaller := False;
       LookinMail  := False;
       Temp        := '';
       IF NOT(MailerInfo.EnableEMSI) THEN DoEMSI := False;
       IF NOT(MailerInfo.EnableYooHoo) THEN DoYooHoo := False;
       IF Mailer2Info.UseZedZapTransfers
          THEN DoZap := True
          ELSE DoZap := False;
       IF (ConnectRate<14400) THEN DoZap := False;
       _Delay(2000);
       bsSendString('SGMail '+ShotgunVersion+#10);
       IF DoEMSI THEN bsSendString(EMSI_REQ);
       IF MailerInfo.MailOnly THEN
       BEGIN
         IF MailOnly THEN bsSendString('Mail only system. Please hang-up.'+#10);
         SendMailOnlyBanner;
       END
       ELSE bsSendString('Press Escape twice for '+TakeOutTheC(MailerInfo.BBSSoftware)+#10);
       NewTimerSecs(UserTimer,MailerInfo.SecondsToBBS);
       REPEAT
         IF NOT(bsCarrierDetected) THEN GOTO Abort2;
         IF CharReady(bsBBSPort) THEN
         BEGIN
           WHILE CharReady(bsBBSPort) DO
           BEGIN
             GetChar(bsBBSPort,C);
             IF (Ord(C)>31) THEN Temp := Temp+C;
             IF ((Pos(EMSI_INQ,Temp)<>0) AND (DoEMSI)) THEN
             BEGIN {EMSI}
               HumanCaller := False;
               StartupMailSession := 2;
               Exit;
             END
             ELSE IF (Pos('*EMSI',Temp)<>0) THEN
             BEGIN {MAKE SURE WE DON'T TIMEOUT NOW!}
               LookinMail := True;
               NewTimerSecs(UserTimer,60);
             END
             ELSE IF ((C=#$F1) AND (DoYooHoo)) THEN
             BEGIN {YOOHOO}
                 HumanCaller := False;
                 StartupMailSession := 1;
                 Exit;
             END
             ELSE IF C=#$AE THEN
             BEGIN {FTS-1}
               LookinMail := True;
               NewTimerSecs(UserTimer,60);
               INC(TSyncNum);
               IF (TSyncNum>=2) THEN
               BEGIN
                 HumanCaller := False;
                 StartupMailSession := 0;
                 Exit;
               END;
             END
             ELSE IF ((C=#13) OR (C=#32)) THEN
             BEGIN {WHACKING RETURN}
               PutChar(bsBBSPort,#13);
               PutChar(bsBBSPort,#13);
             END
             ELSE IF NOT(LookinMail) THEN
             BEGIN {HUMAN}
               IF C=#27 THEN
               BEGIN
                 INC(EscNum);
                 IF (EscNum>=2) THEN
                 BEGIN
                   HumanCaller := True;
                   StartupMailSession := 3;
                   Exit;
                 END;
               END;
             END;
             IF LENGTH(Temp)>250 THEN Delete(Temp,1,200);
           END;
         END
         ELSE TimeSlice;
       UNTIL TimerExpired(UserTimer);
       IF LookinMail THEN
       BEGIN
         Abort2:
         StatusWindow('!Mail session startup error .006');
         bsWriteLog('Mail session startup error .006',False);
         SessionFailure := True;
         HumanCaller := False;
       END
       ELSE
       BEGIN
         HumanCaller := True;
         StartupMailSession := 3;
       END;
     END;
END;
{===========================================================================}
{                                                                           }
{ Log our EMSI packet.                                                      }
{                                                                           }
{===========================================================================}
PROCEDURE LogOurEMSI;
VAR  Temp : String;
     Loop : Word;
     C    : Char;
     Last : Word;
     LLen : Byte;

     PROCEDURE DumpIt;
     BEGIN
          Temp := '³ '+_PadRight(Temp,63)+' ³';
          bsWriteLog(Temp,False);
          Temp := '';
          Loop := Last;
     END;

BEGIN
     bsWriteLog('ÚÄSent EMSI PacketÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',False);
     Loop := 1;
     Temp := '';
     Last := 1;
     REPEAT
           C := EMSI_DAT[Loop];
           Temp := Temp+C;
           IF ((C=']') OR (C='}') OR (C=' ')) THEN
           BEGIN
                CASE C OF
                ']': IF ((EMSI_DAT[Loop+1]<>']') AND (Loop+1<=ELength)) THEN Last := Loop;
                '}': IF ((EMSI_DAT[Loop+1]<>'}') AND (Loop+1<=ELength)) THEN Last := Loop;
                ' ': IF (Loop+1<=ELength) THEN Last := Loop;
                END;
                LLen := LENGTH(Temp);
           END;
           IF LENGTH(Temp)>=63 THEN
           BEGIN
                Temp := _Mid(Temp,1,LLen);
                DumpIt;
           END;
           INC(Loop);
     UNTIL (Loop=ELength+1);
     IF (Temp<>'') THEN DumpIt;
     bsWriteLog('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',False);
END;
{===========================================================================}
{                                                                           }
{ Log their EMSI packet.                                                    }
{                                                                           }
{===========================================================================}
PROCEDURE LogTheirEMSI;
VAR  Temp : String;
     Loop : Word;
     C    : Char;
     Last : Word;
     LLen : Byte;

     PROCEDURE DumpIt;
     BEGIN
          Temp := '³ '+_PadRight(Temp,63)+' ³';
          bsWriteLog(Temp,False);
          Temp := '';
          Loop := Last;
     END;

BEGIN
     bsWriteLog('ÚÄReceived EMSI PacketÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',False);
     Loop := 1;
     Temp := '';
     Last := 1;
     REPEAT
           C := Their_EMSI_DAT[Loop];
           Temp := Temp+C;
           IF ((C=']') OR (C='}') OR (C=' ')) THEN
           BEGIN
                CASE C OF
                ']': IF ((Their_EMSI_DAT[Loop+1]<>']') AND (Loop+1<=TELength)) THEN Last := Loop;
                '}': IF ((Their_EMSI_DAT[Loop+1]<>'}') AND (Loop+1<=TELength)) THEN Last := Loop;
                ' ': IF (Loop+1<=TELength) THEN Last := Loop;
                END;
                LLen := LENGTH(Temp);
           END;
           IF LENGTH(Temp)>=63 THEN
           BEGIN
                Temp := _Mid(Temp,1,LLen);
                DumpIt;
           END;
           INC(Loop);
     UNTIL (Loop=TELength+1);
     IF (Temp<>'') THEN DumpIt;
     bsWriteLog('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',False);
END;
{===========================================================================}
{                                                                           }
{ Send our EMSI packet and wait for ACK.                                    }
{                                                                           }
{===========================================================================}
FUNCTION DoOutGoingEMSI: Boolean;
VAR  Tries      : Byte;
     Timer1     : EventTimer;
     Timer2     : EventTimer;
     Loop2      : Word;
     BBytesSent : Word;
LABEL Step1,Step2,Step3,Step4,Step5;
LABEL Again;
BEGIN
     Create_EMSI_DAT;
     Step1:
           Tries  := 0;
           NewTimerSecs(Timer1,60);
     Step2:
           PutString(bsBBSPort,'**EMSI_DAT'+Length_EMSI_DAT);
           PutBlockDirect(bsBBSPort,EMSI_DAT,ELength,BBytesSent);
           PutChar(bsBBSPort,#13);
           IF Tries=0 THEN LogOurEMSI;
           INC(Tries);
           IF Tries>6 THEN
           BEGIN
                DoOutGoingEMSI := False;
                StatusWindow('!EMSI handshake failure .007');
                bsWriteLog('EMSI handshake failure .007',False);
                SessionFailure := True;
                Exit;
           END;
           IF NOT(bsCarrierDetected) THEN
           BEGIN
                StatusWindow('!Remote dropped carrier .008');
                bsWriteLog('Remote dropped carrier .008',False);
                SessionFailure := True;
                DoOutGoingEMSI := False;
                Exit;
           END;
     Step3:
           NewTimerSecs(Timer2,20);
     Step4:
           Again:
           REPEAT
                 IF TimerExpired(Timer1) THEN
                 BEGIN
                      DoOutGoingEMSI := False;
                      StatusWindow('!EMSI handshake failure .009');
                      bsWriteLog('EMSI handshake failure .009',False);
                      SessionFailure := True;
                      Exit;
                 END;
                 IF TimerExpired(Timer2) THEN GOTO Step2;
                 IF NOT(bsCarrierDetected) THEN
                 BEGIN
                      StatusWindow('!Remote dropped carrier .010');
                      bsWriteLog('Remote dropped carrier .010',False);
                      SessionFailure := True;
                      DoOutGoingEMSI := False;
                      Exit;
                 END;
           UNTIL CharReady(bsBBSPort);
           Comm_Rx_String(False,True,False);
           IF ModemBuffer[1]=#13 THEN GOTO Again;
           IF PPos(EMSI_ACK)<>0 THEN GOTO Step5;
           IF PPos(EMSI_REQ)<>0 THEN GOTO Step3;
           IF PPos(EMSI_HBT)<>0 THEN
           BEGIN
                NewTimerSecs(Timer1,60);
                NewTimerSecs(Timer2,20);
                GOTO Step4;
           END;
           IF NOT(TimerExpired(Timer2)) THEN GOTO Again;
           GOTO Step2;
     Step5:
           DoOutGoingEMSI := True;
           Exit;
END;
{===========================================================================}
{                                                                           }
{ Send our EMSI packet and wait for ACK.                                    }
{                                                                           }
{===========================================================================}
PROCEDURE EMSIBadPassword(BadPassword: Boolean);
VAR  Tries      : Byte;
     Timer1     : EventTimer;
     Timer2     : EventTimer;
     Loop2      : Word;
     BBytesSent : Word;
LABEL Step1,Step2,Step3,Step4,Step5;
LABEL Again;
BEGIN
     Create_BAD_EMSI_DAT(BadPassword);
     Step1:
           Tries  := 0;
           NewTimerSecs(Timer1,60);
     Step2:
           PutString(bsBBSPort,'**EMSI_DAT'+Length_EMSI_DAT);
           PutBlockDirect(bsBBSPort,EMSI_DAT,ELength,BBytesSent);
           PutChar(bsBBSPort,#13);
           IF Tries=0 THEN LogOurEMSI;
           INC(Tries);
           IF Tries>6 THEN
           BEGIN
                StatusWindow('!EMSI handshake failure .011');
                bsWriteLog('EMSI handshake failure .011',False);
                SessionFailure := True;
                Exit;
           END;
           IF NOT(bsCarrierDetected) THEN
           BEGIN
                StatusWindow('!Remote dropped carrier .012');
                bsWriteLog('Remote dropped carrier .012',False);
                SessionFailure := True;
                Exit;
           END;
     Step3:
           NewTimerSecs(Timer2,20);
     Step4:
           Again:
           REPEAT
                 IF TimerExpired(Timer1) THEN
                 BEGIN
                      StatusWindow('!EMSI handshake failure .013');
                      bsWriteLog('EMSI handshake failure .013',False);
                      SessionFailure := True;
                      Exit;
                 END;
                 IF TimerExpired(Timer2) THEN GOTO Step2;
                 IF NOT(bsCarrierDetected) THEN
                 BEGIN
                      StatusWindow('!Remote dropped carrier .014');
                      bsWriteLog('Remote dropped carrier .014',False);
                      SessionFailure := True;
                      Exit;
                 END;
           UNTIL CharReady(bsBBSPort);
           Comm_Rx_String(False,True,False);
           IF ModemBuffer[1]=#13 THEN GOTO Again;
           IF PPos(EMSI_ACK)<>0 THEN GOTO Step5;
           IF PPos(EMSI_REQ)<>0 THEN GOTO Step3;
           IF PPos(EMSI_HBT)<>0 THEN
           BEGIN
                NewTimerSecs(Timer1,60);
                NewTimerSecs(Timer2,20);
                GOTO Step4;
           END;
           IF NOT(TimerExpired(Timer2)) THEN GOTO Again;
           GOTO Step2;
     Step5:
           Exit;
END;


PROCEDURE AddToTheirEMSI(Ch: Char);
BEGIN
     INC(TELength);
     Their_EMSI_DAT[TELength] := Ch;
END;


PROCEDURE GrabEMSIData;
VAR  Loop    : Word;
     GotIt   : Boolean;
     Temp    : String;
     AllDone : Boolean;
     Counter : Word;
     Work    : Word;
     Current : Word;
     C       : Char;
     TmpAka  : AddrType;
BEGIN
     FillChar(RemoteSystem,SizeOf(RemoteSystem),0);
     IF CallingOut THEN RemoteSystem.CallAddress := MailQueue^[MailQueuePointer].DestAddr;

     {Addresses/AKAs}
     Comm_Rx_Akas;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);

     AllDone := False;
     Counter := 0;
     Loop    := 2;
     REPEAT
           IF Loop<=(InBuffer-1) THEN
           BEGIN
                Temp := '';
                REPEAT
                      Temp := Temp+ModemBuffer[Loop];
                      INC(Loop);
                UNTIL ((ModemBuffer[Loop]=' ') OR (ModemBuffer[Loop]='}') OR (Loop>(InBuffer-1)));
                INC(Loop);
                Work := Pos('@',Temp);
                IF (Work<>0) THEN Temp[0] := Chr(Work-1);
                IF (Counter<100) THEN
                BEGIN
                  StringToAddress(Temp,TmpAka);
                  IF AkaIsOk(TmpAka) THEN
                  BEGIN
                    INC(Counter);
                    RemoteSystem.Akas[Counter] := TmpAka;
                  END;
                END;
           END
           ELSE AllDone := True;
     UNTIL AllDone;
     RemoteSystem.NumberOfAkas := Counter;
     IF RemoteSystem.NumberOfAkas=0 THEN
     BEGIN
       FillChar(RemoteSystem.Akas[1],SizeOf(RemoteSystem.Akas[1]),0);
       RemoteSystem.NumberOfAkas := 1;
     END;

     {Session Password}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     IF InBuffer<>2 THEN
     BEGIN
          FOR Loop := 2 TO (InBuffer-1) DO
              RemoteSystem.SessionPassword := RemoteSystem.SessionPassword+UpCase(ModemBuffer[Loop]);
     END;

     {Link Codes}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.LinkCodes := RemoteSystem.LinkCodes+ModemBuffer[Loop];

     {Compatibility Codes}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.CompatabilityCodes := RemoteSystem.CompatabilityCodes+ModemBuffer[Loop];

     {Mailer Product Code}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.MailerProductCode := RemoteSystem.MailerProductCode+ModemBuffer[Loop];

     {Mailer Name}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.MailerName := RemoteSystem.MailerName+ModemBuffer[Loop];

     {Mailer Version}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.MailerVersion := RemoteSystem.MailerVersion+ModemBuffer[Loop];

     {Mailer Serial Number}
     Comm_Rx_String_EMSI;
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     FOR Loop := 2 TO (InBuffer-1) DO
         RemoteSystem.MailerSerialNumber := RemoteSystem.MailerSerialNumber+ModemBuffer[Loop];

     {Wait For IDENT}
     GotIt := False;
     REPEAT
           Comm_Rx_String_EMSI_No_Process;
           FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
           IF PPos('{IDENT}')<>0 THEN GotIt := True;
     UNTIL GotIt;

     {IDENT Information}
     Comm_Rx_String_IDENT;
     Dec(InBuffer);
     FOR Loop := 1 TO InBuffer DO AddToTheirEMSI(ModemBuffer[Loop]);
     Current := 1;
     Loop := 3;
     REPEAT
       C := ModemBuffer[Loop];
       INC(Loop);
       IF ((C=']') AND (ModemBuffer[Loop]='[')) THEN
       BEGIN
         INC(Current);
         INC(Loop);
       END
       ELSE IF ((C=']') AND (ModemBuffer[Loop]='}')) THEN
       BEGIN
         INC(Current);
         INC(Loop);
       END
       ELSE
       BEGIN
         IF ((C=']') AND (ModemBuffer[Loop]=']')) THEN INC(Loop);
         CASE Current OF
         1:   RemoteSystem.BBSName := RemoteSystem.BBSName+C;
         2:   RemoteSystem.Location := RemoteSystem.Location+C;
         3:   RemoteSystem.Sysop := RemoteSystem.Sysop+C;
         4:   RemoteSystem.PhoneNumber := RemoteSystem.PhoneNumber+C;
         5:   RemoteSystem.BaudRate := RemoteSystem.BaudRate+C;
         6:   RemoteSystem.NodeListFlags := RemoteSystem.NodeListFlags+C;
         END;
       END;
     UNTIL (Loop>InBuffer);
END;
{===========================================================================}
{                                                                           }
{ Get the remotes EMSI packet and send ACK if all is OK.                    }
{                                                                           }
{===========================================================================}
FUNCTION DoInComingEMSI: Boolean;
VAR  Tries      : Byte;
     Timer1     : EventTimer;
     Timer2     : EventTimer;
     Work1      : Word;
     Work2      : Word;
     Loop       : Word;
     Loop2      : Word;
     CC         : Char;
     Temp       : String;
     Temp2      : String;
LABEL Step1,Step2,Step3,Step4,Step5,Step6;
LABEL Again;
BEGIN
     FillChar(Their_EMSI_DAT,SizeOf(Their_EMSI_DAT),0);
     TELength := 0;
     Step1:
           Tries := 0;
           NewTimerSecs(Timer1,20);
           NewTimerSecs(Timer2,60);
     Step2:
           IF NOT(bsCarrierDetected) THEN
           BEGIN
                StatusWindow('!Remote dropped carrier .015');
                bsWriteLog('Remote dropped carrier .015',False);
                SessionFailure := True;
                DoInComingEMSI := False;
                Exit;
           END;
           INC(Tries);
           IF Tries>6 THEN
           BEGIN
                DoInComingEMSI := False;
                StatusWindow('!EMSI handshake failure .016');
                bsWriteLog('EMSI handshake failure .016',False);
                SessionFailure := True;
                Exit;
           END;
           IF NOT(CallingOut) THEN
           BEGIN
                bsSendString(EMSI_REQ);
                GOTO Step3;
           END;
           IF Tries>1 THEN
           BEGIN
                bsSendString(EMSI_NAK);
                GOTO Step3;
           END;
           GOTO Step4;
     Step3:
           NewTimerSecs(Timer1,20);
     Step4:
           Again:
           REPEAT
                 IF TimerExpired(Timer2) THEN
                 BEGIN
                      DoInComingEMSI := False;
                      StatusWindow('!EMSI handshake failure .017');
                      bsWriteLog('EMSI handshake failure .017',False);
                      SessionFailure := True;
                      Exit;
                 END;
                 IF NOT(bsCarrierDetected) THEN
                 BEGIN
                      StatusWindow('!Remote dropped carrier .018');
                      bsWriteLog('Remote dropped carrier .018',False);
                      SessionFailure := True;
                      DoInComingEMSI := False;
                      Exit;
                 END;
                 IF TimerExpired(Timer1) THEN GOTO Step2;
           UNTIL CharReady(bsBBSPort);
           Comm_Rx_String_EMSI_No_Process;
           IF PPos('{EMSI}')<>0 THEN GOTO Step5;
           IF ModemBuffer[1]=#13 THEN GOTO Again;
           IF ModemBuffer[1]+ModemBuffer[2]=' '+#13 THEN GOTO Again;
           IF PPos(EMSI_HBT)<>0 THEN
           BEGIN
                NewTimerSecs(Timer1,20);
                NewTimerSecs(Timer2,60);
           END;
           GOTO Step3;
     Step5:
           {BOGUS PACKET GOTO STEP2!}
           TELength := 6;
           Move(ModemBuffer[PPos('{EMSI}')],Their_EMSI_DAT[1],TELength);

           GrabEMSIData;
           LogTheirEMSI;

           {PACKET IS OK?}
           bsSendString(EMSI_ACK);
           bsSendString(EMSI_ACK);
           StatusWindow(RemoteSystem.BBSName);
           bsWriteLog(RemoteSystem.BBSName,False);
           Loop := 1;
           Temp := '';
           REPEAT
                 Temp2 := AddressToString(RemoteSystem.Akas[Loop]);
                 IF ((LENGTH(Temp)+1+LENGTH(Temp2))>40) THEN
                 BEGIN
                      StatusWindow('AKA: '+Temp);
                      bsWriteLog('AKA: '+Temp,False);
                      Temp := Temp2+' ';
                 END
                 ELSE Temp := Temp+Temp2+' ';
                 INC(Loop);
           UNTIL (Loop>RemoteSystem.NumberOfAkas);
           IF (Temp<>'') THEN
           BEGIN
                StatusWindow('AKA: '+Temp);
                bsWriteLog('AKA: '+Temp,False);
           END;
           StatusWindow('Sysop: '+RemoteSystem.Sysop);
           bsWriteLog('Sysop: '+RemoteSystem.Sysop,False);
           StatusWindow('From: '+RemoteSystem.Location);
           bsWriteLog('From: '+RemoteSystem.Location,False);
           IF RemoteSystem.MailerSerialNumber='' THEN
           BEGIN
                StatusWindow('Using: '+RemoteSystem.MailerName+' '+
                                       RemoteSystem.MailerVersion);
                bsWriteLog('Using: '+RemoteSystem.MailerName+' '+
                                       RemoteSystem.MailerVersion,False);
           END
           ELSE
           BEGIN
                StatusWindow('Using: '+RemoteSystem.MailerName+' '+
                                       RemoteSystem.MailerVersion+'/'+
                                        RemoteSystem.MailerSerialNumber);
                bsWriteLog('Using: '+RemoteSystem.MailerName+' '+
                                       RemoteSystem.MailerVersion+'/'+
                                       RemoteSystem.MailerSerialNumber,False);
           END;
           StatusWindow('Flags: '+RemoteSystem.NodelistFlags);
           bsWriteLog('Flags: '+RemoteSystem.NodelistFlags,False);
           StatusWindow('CompCodes: '+RemoteSystem.CompatabilityCodes);
           bsWriteLog('CompCodes: '+RemoteSystem.CompatabilityCodes,False);
           IF DoZap THEN
           BEGIN
                IF (Pos('ZAP',RemoteSystem.CompatabilityCodes)<>0)
                   THEN DoingZap := True
                   ELSE DoingZap := False;
           END
           ELSE DoingZap := False;
           GOTO Step6;
     Step6:
           DoInComingEMSI := True;
           Exit;
END;


END.
