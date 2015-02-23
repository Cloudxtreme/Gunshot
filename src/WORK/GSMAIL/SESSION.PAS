{$I DEFINES.INC}
UNIT Session;


INTERFACE


PROCEDURE DoMailSession;


IMPLEMENTATION


USES ApTimer,Globals,EMSI,DrawScrn,BsLog,BsMulti,ApCom,BsAkas,Crt,
     Ftsc0001,Ftsc0006,Sema,XFer,Transfer,BusyFile,Comm,ApPort,
     Misc,Gunshot,BsKeys,BsString,BsCom,NList,UnDial,Time;


PROCEDURE DoMailSession;
VAR  MailSessionType : Byte;
     C               : Char;
     TheAttr         : Word;
     Loop            : Word;
     RunTheUnpack    : Boolean;
     FirstTo         : AddrType;
     SecondTo        : AddrType;
     DialOut         : Boolean;
     Temp            : String;
LABEL                  Skip1,Skip2,PasswordFailure1,PasswordFailure2;

     PROCEDURE LogBadPassword;
     BEGIN
          StatusWindow('!Invalid password "'+RemoteSystem.SessionPassword+'"');
          StatusWindow('!Expected "'+YourSystem.SessionPassword+'" from '+
                       AddressToString(RemoteSystem.Akas[1]));
          bsWriteLog('Invalid password "'+RemoteSystem.SessionPassword+'"',False);
          bsWriteLog('Expected "'+YourSystem.SessionPassword+'" from '+
                       AddressToString(RemoteSystem.Akas[1]),False);
          SessionFailure := True;
     END;

     PROCEDURE LogUnknown;
     BEGIN
          StatusWindow('!Remote system unlisted: '+AddressToString(RemoteSystem.Akas[1]));
          bsWriteLog('Remote system unlisted: '+AddressToString(RemoteSystem.Akas[1]),False);
          SessionFailure := True;
     END;

     PROCEDURE WriteTheNodeFile;
     BEGIN
          WriteNodeFile('GSMail','Mail Session ('+AddressToString(RemoteSystem.Akas[1])+')',_String(ConnectRate));
     END;

BEGIN
     NewTimerSecs(SessionTimer,1440*60);
     RescanRequired  := False;
     SecureSession   := False;
     SessionFailure  := False;
     DialOut         := CallingOut;
     MailSessionType := StartupMailSession(CallingOut);
     CASE MailSessionType OF
     0:   BEGIN {FTS-0001}
               WriteNodeFile('GSMail','Mail Session',_String(ConnectRate));
               SessionType := 'FTS-1';
               ReceivedMail := False;
               _HideCursor;
               FillChar(FirstTo,SizeOf(FirstTo),0);
               FillChar(SecondTo,SizeOf(SecondTo),0);
               IF CallingOut THEN
               BEGIN
                 StatusWindow('Sending FTS-1 handshake packet');
                 bsWriteLog('Sending FTS-1 handshake packet',False);
                 DrawSessionWindow(4);
                 IF FTS0001Sender(False) THEN
                 BEGIN
                   FirstTo := MailQueue^[MailQueuePointer].DestAddr;
                   IF FTS0001RemoteHasSomething THEN
                   BEGIN
                     bsWriteLog('Receiving FTS-1 handshake packet',False);
                     IF FTS0001Receiver(False) THEN
                     BEGIN
                       SecondTo := RemoteSystem.Akas[1];
                       RunTheUnpack := True;
                     END
                     ELSE
                     BEGIN
                       RunTheUnpack := False;
                       SessionFailure := True;
                     END;
                   END
                   ELSE RunTheUnpack := True;
                   UpdateTo;
                   CallingOut := False;
                 END
                 ELSE
                 BEGIN
                   RunTheUnpack := False;
                   SessionFailure := True;
                 END;
               END
               ELSE
               BEGIN
                 FillChar(RemoteSystem,SizeOf(RemoteSystem),0);
                 StatusWindow('Receiving FTS-1 handshake packet');
                 bsWriteLog('Receiving FTS-1 handshake packet',False);
                 DrawSessionWindow(4);
                 IF FTS0001Receiver(False) THEN
                 BEGIN
                   FirstTo := RemoteSystem.Akas[1];
                   CASE FTS0001WeHaveSomething(False) OF
                   0:  BEGIN
                         bsWriteLog('Nothing to send for '+AddressToString(FirstTo),False);
                         RunTheUnpack := True;
                       END;
                   1:  BEGIN
                         bsWriteLog('Sending FTS-1 handshake packet',False);
                         IF FTS0001Sender(False) THEN
                         BEGIN
                           SecondTo := RemoteSystem.Akas[1];
                           RunTheUnpack := True;
                         END
                         ELSE
                         BEGIN
                           RunTheUnpack := False;
                           SessionFailure := True;
                         END;
                       END;
                   2:  BEGIN
                         bsWriteLog('Timeout waiting for handshake reply',False);
                         RunTheUnpack := False;
                         SessionFailure := True;
                       END;
                   END;
                   UpdateFrom;
                 END
                 ELSE
                 BEGIN
                   RunTheUnpack := False;
                   SessionFailure := True;
                 END;
               END;
               DrawSessionWindow(3);
               IF RunTheUnpack THEN
               BEGIN
                    IF SecondTo.Zone=0 THEN
                    BEGIN
                         RemoteSystem.Akas[1] := FirstTo;
                         RemoteSystem.NumberOfAkas := 1;
                    END
                    ELSE
                    BEGIN
                         RemoteSystem.Akas[1] := FirstTo;
                         RemoteSystem.Akas[2] := SecondTo;
                         RemoteSystem.NumberOfAkas := 2;
                    END;
                    ClearFileQueue;
               END;
               _ShowCursor;
               bsClearInBuffer;
          END;
     1:   BEGIN {YooHoo/WaZOO}
            _HideCursor;
            IF CallingOut THEN
            BEGIN
              StatusWindow('Sending YooHoo handshake packet');
              bsWriteLog('Sending YooHoo handshake packet',False);
              IF YooHooSender=True THEN
              BEGIN
                WriteTheNodeFile;
                IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword<>'')) THEN
                BEGIN
                  StatusWindow('Password protected session');
                  bsWriteLog('Password protected session',False);
                  SecureSession := True;
                END;
                IF NOT(_NodeIsBusy(RemoteSystem.Akas[1])) THEN
                BEGIN
                  _NodeBusy(RemoteSystem.Akas[1]);
                  _HideCursor;
                  CASE FTSCType OF
                  1:   SessionType := 'FTS-6/ZedZap';
                  2:   SessionType := 'FTS-6/ZedZip';
                  3:   SessionType := 'FTS-6/DietIFNA';
                  ELSE SessionType := 'Unknown';
                  END;
                  DrawSessionWindow(0);
                  SetUpOutgoingTransfer;
                  IF FTSCType=3 THEN
                  BEGIN {DIET_IFNA}
                    DrawSessionWindow(1);
                    IF FTS0001Sender(True) THEN
                    BEGIN
                      IF FTS0001RemoteHasSomething THEN
                      BEGIN
                        IF FTS0001Receiver(True) THEN
                        BEGIN
                          Success := True;
                        END
                        ELSE
                        BEGIN
                          SessionFailure := True;
                          Success := False;
                        END;
                      END
                      ELSE Success := True;
                    END
                    ELSE
                    BEGIN
                      Success := False;
                      SessionFailure := True;
                    END;
                  END
                  ELSE
                  BEGIN
                    TransmitFiles('','Z');
                    IF FilesToSend=0 THEN
                    BEGIN
                      _Delay(750);
                      PutString(bsBBSPort,'*'+#24+'C'+#8#0#0#0#0#220#188+'R'+#246);
                      _Delay(750);
                      PutString(bsBBSPort,'OO'+#13);
                    END;
                    IF NOT(bsCarrierDetected) THEN Success := False;
                    IF Success THEN
                    BEGIN
                      IF SecureSession THEN ReceiveFiles(MailerInfo.Inbound,'Z')
                                       ELSE ReceiveFiles(Mailer2Info.InSecureInbound,'Z');
                    END;
                  END;
                  DrawSessionWindow(3);
                  IF Success THEN ClearFileQueue
                             ELSE SessionFailure := True;
                  _ShowCursor;
                  _KillBusy;
                END
                ELSE
                BEGIN
                  StatusWindow('!System active on another line!');
                  bsWriteLog('System active on another line!',False);
                  SessionFailure := True;
                END;
                UpdateTo;
                CallingOut := False;
              END
              ELSE SessionFailure := True;
            END
            ELSE
            BEGIN
              StatusWindow('Receiving YooHoo handshake packet');
              bsWriteLog('Receiving YooHoo handshake packet',False);
              IF YooHooReceiver=True THEN
              BEGIN
                IF NOT(Mailer2Info.MailFromUnlistedSystems) THEN
                BEGIN
                  IF NOT(NodeFound(RemoteSystem.Akas[1])) THEN
                  BEGIN
                    LogUnknown;
                    GOTO PasswordFailure1;
                  END;
                END;
                IF (YourSystem.SessionPassword<>'') THEN
                BEGIN
                  IF (RemoteSystem.SessionPassword<>YourSystem.SessionPassword) THEN
                  BEGIN
                     LogBadPassword;
                     GOTO PasswordFailure1;
                  END;
                END;
                IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword='')) THEN
                BEGIN
                  StatusWindow('Unexpected password "'+RemoteSystem.SessionPassword+'"');
                  bsWriteLog('Unexpected password "'+RemoteSystem.SessionPassword+'"',False);
                END;
                IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword<>'')) THEN
                BEGIN
                  StatusWindow('Password protected session');
                  bsWriteLog('Password protected session',False);
                  SecureSession := True;
                END;
                WriteTheNodeFile;
                IF NOT(_NodeIsBusy(RemoteSystem.Akas[1])) THEN
                BEGIN
                  _NodeBusy(RemoteSystem.Akas[1]);
                  _HideCursor;
                  CASE FTSCType OF
                  1:   SessionType := 'FTS-6/ZedZap';
                  2:   SessionType := 'FTS-6/ZedZip';
                  3:   SessionType := 'FTS-6/DietIFNA';
                  ELSE SessionType := 'Unknown';
                  END;
                  DrawSessionWindow(0);
                  IF FTSCType=3 THEN
                  BEGIN {DIET_IFNA}
                    DrawSessionWindow(1);
                    IF FTS0001Receiver(True) THEN
                    BEGIN
                      SetUpOutgoingTransfer;
                      CASE FTS0001WeHaveSomething(True) OF
                      0:  bsWriteLog('Nothing to send for '+AddressToString(RemoteSystem.Akas[1]),False);
                      1:  BEGIN
                            IF FTS0001Sender(True) THEN
                            BEGIN
                              Success := True;
                            END
                            ELSE
                            BEGIN
                              Success := False;
                              SessionFailure := True;
                            END;
                          END;
                      2:  BEGIN
                            bsWriteLog('Timeout waiting for handshake reply',False);
                            SessionFailure := True;
                            Success := False;
                          END;
                      END;
                    END
                    ELSE
                    BEGIN
                      Success := False;
                      SessionFailure := True;
                    END;
                  END
                  ELSE
                  BEGIN
                    IF SecureSession THEN ReceiveFiles(MailerInfo.Inbound,'Z')
                                     ELSE ReceiveFiles(Mailer2Info.InSecureInbound,'Z');
                    IF NOT(bsCarrierDetected) THEN Success := False;
                    IF Success THEN
                    BEGIN
                      SetUpOutgoingTransfer;
                      TransmitFiles('','Z');
                      IF FilesToSend=0 THEN
                      BEGIN
                        _Delay(750);
                        PutString(bsBBSPort,'*'+#24+'C'+#8#0#0#0#0#220#188+'R'+#246);
                        _Delay(750);
                        PutString(bsBBSPort,'OO'+#13);
                      END;
                    END;
                  END;
                  DrawSessionWindow(3);
                  IF Success THEN ClearFileQueue
                             ELSE SessionFailure := True;
                  _ShowCursor;
                  _KillBusy;
                END
                ELSE
                BEGIN
                  StatusWindow('!System active on another line!');
                  bsWriteLog('System active on another line!',False);
                  SessionFailure := True;
                END;
                UpdateFrom;
                PasswordFailure1:
              END
              ELSE SessionFailure := True;
            END;
            _ShowCursor;
            bsClearInBuffer;
          END;
     2:   BEGIN {EMSI}
               _HideCursor;
               IF CallingOut THEN
               BEGIN
                    InitEMSIDat(MailQueue^[MailQueuePointer].DestAddr);
                    IF DoOutGoingEMSI=True THEN
                    BEGIN
                         StatusWindow('Receiving EMSI handshake packet');
                         bsWriteLog('Receiving EMSI handshake packet',False);
                         IF DoInComingEMSI=True THEN
                         BEGIN
                              WriteTheNodeFile;
                              IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword<>'')) THEN
                              BEGIN
                                   StatusWindow('Password protected session');
                                   bsWriteLog('Password protected session',False);
                                   SecureSession := True;
                              END;
                              FOR Loop := 1 TO RemoteSystem.NumberOfAkas DO
                              BEGIN
                                   IF _NodeIsBusy(RemoteSystem.Akas[Loop]) THEN
                                   BEGIN
                                        StatusWindow('!System active on another line!');
                                        bsWriteLog('System active on another line!',False);
                                        SessionFailure := True;
                                        GOTO Skip1;
                                   END;
                              END;
                              FOR Loop := 1 TO RemoteSystem.NumberOfAkas DO
                                  _NodeBusy(RemoteSystem.Akas[Loop]);
                              _HideCursor;
                              IF DoingZAP THEN SessionType := 'EMSI/ZedZap'
                                          ELSE SessionType := 'EMSI/ZedZip';
                              DrawSessionWindow(0);
                              SetUpOutgoingTransfer;
                              TransmitFiles('','Z');
                              IF FilesToSend=0 THEN
                              BEGIN
                                   _Delay(750);
                                   PutString(bsBBSPort,'*'+#24+'C'+#8#0#0#0#0#220#188+'R'+#246);
                                   _Delay(750);
                                   PutString(bsBBSPort,'OO'+#13);
                              END;
                              IF Success THEN
                              BEGIN
                                   IF SecureSession THEN ReceiveFiles(MailerInfo.Inbound,'Z')
                                                    ELSE ReceiveFiles(Mailer2Info.InSecureInbound,'Z');
                              END;
                              DrawSessionWindow(3);
                              IF Success THEN ClearFileQueue
                                         ELSE SessionFailure := True;
                              _ShowCursor;
                              _KillBusy;
                              Skip1:
                              UpdateTo;
                              CallingOut := False;
                         END
                         ELSE SessionFailure := True;
                    END
                    ELSE SessionFailure := True;
               END
               ELSE
               BEGIN
                    StatusWindow('Receiving EMSI handshake packet');
                    bsWriteLog('Receiving EMSI handshake packet',False);
                    IF DoInComingEMSI=True THEN
                    BEGIN
                         InitEMSIDat(RemoteSystem.Akas[1]);
                         IF NOT(Mailer2Info.MailFromUnlistedSystems) THEN
                         BEGIN
                           IF NOT(NodeFound(RemoteSystem.Akas[1])) THEN
                           BEGIN
                             LogUnknown;
                             EMSIBadPassword(False);
                             GOTO PasswordFailure2;
                           END;
                         END;
                         IF (YourSystem.SessionPassword<>'') THEN
                         BEGIN
                           IF (RemoteSystem.SessionPassword<>YourSystem.SessionPassword) THEN
                           BEGIN
                             LogBadPassword;
                             EMSIBadPassword(True);
                             GOTO PasswordFailure2;
                           END;
                         END;
                         IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword='')) THEN
                         BEGIN
                              StatusWindow('Unexpected password "'+RemoteSystem.SessionPassword+'"');
                              bsWriteLog('Unexpected password "'+RemoteSystem.SessionPassword+'"',False);
                         END;
                         IF ((RemoteSystem.SessionPassword<>'') AND (YourSystem.SessionPassword<>'')) THEN
                         BEGIN
                           StatusWindow('Password protected session');
                           bsWriteLog('Password protected session',False);
                           SecureSession := True;
                         END;
                         IF DoOutGoingEMSI=True THEN
                         BEGIN
                           WriteTheNodeFile;
                           FOR Loop := 1 TO RemoteSystem.NumberOfAkas DO
                           BEGIN
                             IF _NodeIsBusy(RemoteSystem.Akas[Loop]) THEN
                             BEGIN
                               StatusWindow('!System active on another line!');
                               bsWriteLog('System active on another line!',False);
                               SessionFailure := True;
                               GOTO Skip2;
                             END;
                           END;
                           FOR Loop := 1 TO RemoteSystem.NumberOfAkas DO
                               _NodeBusy(RemoteSystem.Akas[Loop]);
                           _HideCursor;
                           IF DoingZAP THEN SessionType := 'EMSI/ZedZap'
                                       ELSE SessionType := 'EMSI/ZedZip';
                           DrawSessionWindow(0);
                           IF SecureSession THEN ReceiveFiles(MailerInfo.Inbound,'Z')
                                            ELSE ReceiveFiles(Mailer2Info.InSecureInbound,'Z');
                           IF Success THEN
                           BEGIN
                             SetUpOutgoingTransfer;
                             TransmitFiles('','Z');
                             IF FilesToSend=0 THEN
                             BEGIN
                               _Delay(750);
                               PutString(bsBBSPort,'*'+#24+'C'+#8#0#0#0#0#220#188+'R'+#246);
                               _Delay(750);
                               PutString(bsBBSPort,'OO'+#13);
                             END;
                           END;
                           DrawSessionWindow(3);
                           IF Success THEN ClearFileQueue
                                      ELSE SessionFailure := True;
                           _ShowCursor;
                           _KillBusy;
                           Skip2:
                           UpdateFrom;
                         END
                         ELSE SessionFailure := True;
                         PasswordFailure2:
                    END
                    ELSE SessionFailure := True;
               END;
               _ShowCursor;
               bsClearInBuffer;
          END;
     END;
     IF (MailSessionType<3) THEN
     BEGIN
          UpdateMailSession(DialOut,SessionFailure);
          IF SessionFailure THEN
          BEGIN
               StatusWindow('!Session Failed');
               bsWriteLog('Session Failed',False);
               IF DialOut THEN AddUndialable(MailQueue^[MailQueuePointer].DestAddr);
          END
          ELSE
          BEGIN
               Temp := HoursMinutesSeconds(ElapsedTimeInSecs(SessionTimer));
               StatusWindow('Session Complete ['+Temp+']');
               bsWriteLog('Session Complete ['+Temp+']',False);
               IF DialOut THEN ClearUndialable(MailQueue^[MailQueuePointer].DestAddr);
          END;
          ClearInboundFreqs;
     END;
     WHILE KeyPressed DO C := ReadKey;
END;


END.