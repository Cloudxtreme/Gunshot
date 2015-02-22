{$I DEFINES.INC}
UNIT FTSC0001;


INTERFACE


USES Shotgun;


FUNCTION  FTS0001Sender(FTS6Bypass: Boolean): Boolean;
FUNCTION  FTS0001Receiver(FTS6Bypass: Boolean): Boolean;
FUNCTION  FTS0001RemoteHasSomething : Boolean;
FUNCTION  FTS0001WeHaveSomething(FTS6Bypass: Boolean): Byte;
PROCEDURE InitFTS1Dat(WorkAddr: AddrType);


IMPLEMENTATION


USES Globals,DrawScrn,BsLog,ApTimer,ApMisc,BsMulti,NetMail,ApPort,
     ApCom,Misc,XFer,NList,FtscProd,Transfer,FastW1,BsAkas,BsString,
     BsFile,BsCom,Dos,EMSI;


FUNCTION CreateRecordsFTS1: Boolean;
VAR  Loop       : Word;
     PktType    : Byte;
     FFile      : File;
     BytesRead  : Word;
     AllDone    : Boolean;
BEGIN
     ASSIGN(FFile,Mailer2Info.InSecureInbound+'TMP$$$$$.PKT');
     RESET(FFile,1);
     BLOCKREAD(FFile,Type2PPacket,SizeOf(Type2PPacket),BytesRead);
     CLOSE(FFile);
     IF (BytesRead<>SizeOf(Type2PPacket)) THEN
     BEGIN
          bsWriteLog('Bad FTS-1 packet from remote!',False);
          SessionFailure := True;
          CreateRecordsFTS1 := False;
          Exit;
     END;
     IF ((Type2PPacket.day=0) AND (Type2PPacket.hour=0) AND (Type2PPacket.min=0) AND
        (Type2PPacket.sec=0) AND (Type2PPacket.baud=2)) THEN
     BEGIN
          PktType := 2; { fsc-0045 }
     END
     ELSE IF Type2PPacket.capword=0 THEN
     BEGIN
          PktType := 1; { fts-0001 }
     END
     ELSE IF ((Type2PPacket.capword=1) AND (Type2PPacket.baud<>2)) THEN
     BEGIN
          PktType := 3; { fsc-0039 }
     END
     ELSE
     BEGIN
          bsWriteLog('Bad FTS-1 packet from remote!',False);
          SessionFailure := True;
          CreateRecordsFTS1 := False;
          Exit;
     END;
     FillChar(RemoteSystem,SizeOf(RemoteSystem),0);
     IF CallingOut THEN RemoteSystem.CallAddress := MailQueue^[MailQueuePointer].DestAddr;
     RemoteSystem.NumberOfAkas := 1;
     CASE PktType OF
     1:   BEGIN
               ASSIGN(FFile,Mailer2Info.InSecureInbound+'TMP$$$$$.PKT');
               RESET(FFile,1);
               BLOCKREAD(FFile,Type2Packet,SizeOf(Type2Packet),BytesRead);
               CLOSE(FFile);
               RemoteSystem.Akas[1].Zone  := Type2Packet.OrigZone;
               RemoteSystem.Akas[1].Net   := Type2Packet.OrigNet;
               RemoteSystem.Akas[1].Node  := Type2Packet.OrigNode;
               FOR Loop := 1 TO 8 DO
               BEGIN
                    IF ((Type2Packet.Password[Loop]<>#32) AND
                       (Type2Packet.Password[Loop]<>#0)) THEN
                    BEGIN
                         RemoteSystem.SessionPassword := RemoteSystem.SessionPassword+UpCase(Type2Packet.Password[Loop]);
                    END;
               END;
               RemoteSystem.MailerName := GetProductName(Type2Packet.ProductCode);
          END;
     2:   BEGIN
               ASSIGN(FFile,Mailer2Info.InSecureInbound+'TMP$$$$$.PKT');
               RESET(FFile,1);
               BLOCKREAD(FFile,Type22Packet,SizeOf(Type22Packet),BytesRead);
               CLOSE(FFile);
               RemoteSystem.Akas[1].Zone  := Type22Packet.OrigZone;
               RemoteSystem.Akas[1].Net   := Type22Packet.OrigNet;
               RemoteSystem.Akas[1].Node  := Type22Packet.OrigNode;
               RemoteSystem.Akas[1].Point := Type22Packet.OrigPoint;
               FOR Loop := 1 TO 8 DO
               BEGIN
                    IF ((Type22Packet.Password[Loop]<>#32) AND
                       (Type22Packet.Password[Loop]<>#0)) THEN
                    BEGIN
                         RemoteSystem.SessionPassword := RemoteSystem.SessionPassword+UpCase(Type22Packet.Password[Loop]);
                    END;
               END;
               RemoteSystem.MailerVersion := _String(Type22Packet.ProductVer);
               RemoteSystem.MailerName := GetProductName(Type22Packet.ProductCode);
          END;
     3:   BEGIN
               ASSIGN(FFile,Mailer2Info.InSecureInbound+'TMP$$$$$.PKT');
               RESET(FFile,1);
               BLOCKREAD(FFile,Type2PPacket,SizeOf(Type2PPacket),BytesRead);
               CLOSE(FFile);
               RemoteSystem.Akas[1].Zone  := Type2PPacket.OrigZone;
               RemoteSystem.Akas[1].Net   := Type2PPacket.OrigNet;
               RemoteSystem.Akas[1].Node  := Type2PPacket.OrigNode;
               RemoteSystem.Akas[1].Point := Type2PPacket.OrigPoint;
               FOR Loop := 1 TO 8 DO
               BEGIN
                    IF ((Type2PPacket.Password[Loop]<>#32) AND
                       (Type2PPacket.Password[Loop]<>#0)) THEN
                    BEGIN
                         RemoteSystem.SessionPassword := RemoteSystem.SessionPassword+UpCase(Type2PPacket.Password[Loop]);
                    END;
               END;
               RemoteSystem.MailerVersion := _String(Type2PPacket.PVMajor)+'.'+_String(Type2PPacket.PVMinor);
               RemoteSystem.MailerName := GetProductName((Type2PPacket.PrdCodH*256)+Type2PPacket.PrdCodL);
          END;
     END;
     IF NOT(AkaIsOk(RemoteSystem.Akas[1])) THEN
     BEGIN
       FillChar(RemoteSystem.Akas[1],SizeOf(RemoteSystem.Akas[1]),0);
     END;
     RemoteSystem.BBSName := GetBBSName(RemoteSystem.Akas[1]);
     RemoteSystem.Sysop   := 'Unknown';
     IF RemoteSystem.BBSName<>'-Unlisted-' THEN RemoteSystem.Sysop := NodeListSysop;
     RemoteSystem.Location := 'Somewhere';
     bsWriteLog(RemoteSystem.BBSName+', '+AddressToString(RemoteSystem.Akas[1]),False);
     bsWriteLog('Sysop: '+RemoteSystem.Sysop,False);
     bsWriteLog('Using: '+RemoteSystem.MailerName+' '+RemoteSystem.MailerVersion,False);
     IF NOT(Mailer2Info.MailFromUnlistedSystems) THEN
     BEGIN
       IF NOT(NodeFound(RemoteSystem.Akas[1])) THEN
       BEGIN
         StatusWindow('!Remote system unlisted: '+AddressToString(RemoteSystem.Akas[1]));
         bsWriteLog('Remote system unlisted: '+AddressToString(RemoteSystem.Akas[1]),False);
         SessionFailure := True;
         CreateRecordsFTS1 := False;
         Exit;
       END;
     END;
     {Check Our Session Password}
     IF _FileExists('\SHOTGUN\DATA\PASSWORD.DAT') THEN
     BEGIN
          ASSIGN(FSessionPW,'\SHOTGUN\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF AkasMatch(RemoteSystem.Akas[1],SessionPW.SystemAddress) THEN
                BEGIN
                     SessionPW.SystemPW := _UpperCase(SessionPW.SystemPW);
                     IF (RemoteSystem.SessionPassword<>SessionPW.SystemPW) THEN
                     BEGIN
                          CLOSE(FSessionPW);
                          bsWriteLog('Invalid password "'+RemoteSystem.SessionPassword+'"',False);
                          bsWriteLog('Expected "'+SessionPW.SystemPW+'" from '+AddressToString(RemoteSystem.Akas[1]),False);
                          SessionFailure := True;
                          CreateRecordsFTS1 := False;
                          Exit;
                     END
                     ELSE
                     BEGIN
                          CLOSE(FSessionPW);
                          SecureSession := True;
                          IF (RemoteSystem.SessionPassword<>'')
                             THEN bsWriteLog('Password protected session',False);
                          CreateRecordsFTS1 := True;
                          Exit;
                     END;
                END;
          UNTIL EOF(FSessionPW);
          CLOSE(FSessionPW);
     END;
     IF (RemoteSystem.SessionPassword<>'') THEN
     BEGIN
          bsWriteLog('Unexpected password "'+RemoteSystem.SessionPassword+'"',False);
     END;
     CreateRecordsFTS1 := True;
END;


PROCEDURE InitFTS1Dat(WorkAddr: AddrType);
VAR  AllDone   : Boolean;
     FFile     : File;
     Work      : Word;
     Temp      : String;

     PROCEDURE MatchTheZone;
     BEGIN
          AllDone := False;
          ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
          RESET(FNetwork);
          REPEAT
                READ(FNetwork,Network);
                IF WorkAddr.Zone=Network.Net_Address.Zone THEN
                BEGIN
                     YourSystem.Address := Network.Net_Address;
                     AllDone := True;
                END;
          UNTIL ((EOF(FNetwork)) OR (AllDone));
          CLOSE(FNetwork);
     END;

BEGIN
     {OUR NETWORK ADDRESS}
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     YourSystem.Address := Network.Net_Address;
     {MATCH REMOTES ZONE}
     IF CallingOut THEN
     BEGIN
          IF ((MailerInfo.MatchZones) AND (CurrentAka=1)) THEN MatchTheZone;
     END
     ELSE MatchTheZone;
     {APPLY SESSION PASSWORD}
     YourSystem.SessionPassword := '';
     IF _FileExists('\SHOTGUN\DATA\PASSWORD.DAT') THEN
     BEGIN
          AllDone := False;
          ASSIGN(FSessionPW,'\SHOTGUN\DATA\PASSWORD.DAT');
          RESET(FSessionPW);
          REPEAT
                READ(FSessionPW,SessionPW);
                IF AkasMatch(WorkAddr,SessionPW.SystemAddress) THEN
                BEGIN
                     YourSystem.SessionPassword := _UpperCase(SessionPW.SystemPW);
                     AllDone := True;
                END;
          UNTIL ((EOF(FSessionPW)) OR (AllDone));
          CLOSE(FSessionPW);
     END;
     Work := 0;
     CreateType2PPacket(YourSystem.Address,WorkAddr,YourSystem.SessionPassword);
     ASSIGN(FFile,MailerInfo.OutPkts+'TMP$$$$$.PKT');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,Type2PPacket,SizeOf(Type2PPacket));
     BLOCKWRITE(FFile,Work,SizeOf(Work));
     CLOSE(FFile);
     IF CallingOut THEN
     BEGIN
          RemoteSystem.NumberOfAkas  := 0;
          RemoteSystem.CallAddress   := WorkAddr;
          RemoteSystem.Akas[1]       := WorkAddr;
          RemoteSystem.MailerName    := 'Unknown';
          RemoteSystem.MailerVersion := '';
          RemoteSystem.BBSName       := 'Unknown';
          RemoteSystem.Location      := 'Somewhere';
          RemoteSystem.Sysop         := 'Unknown';
          Temp := GetBBSName(WorkAddr);
          IF Temp<>'-Unlisted-' THEN
          BEGIN
            RemoteSystem.Sysop   := NodelistSysop;
            RemoteSystem.BBSName := NodelistSystem;
          END;
     END;
     DrawSessionWindow(5);
END;


FUNCTION GetModem7FileName: String;
VAR  C         : Char;
     Tmp       : String;
     Tmp2      : String;
     MainTimer : EventTimer;
     Retries   : Byte;
     TTimer    : EventTimer;
     Loop      : Byte;
     BCheck    : Word;
     Work      : Byte;
LABEL            MR0,MR1,MR2,MR3,MR4;
BEGIN
     NewTimerSecs(MainTimer,60);
     Retries := 0;

     (* File Name Avoidance - We Don't want it
     MRS0:
          INC(Retries);
          PutChar(bsBBSPort,'C');

     MRS1:
          NewTimerSecs(TTimer,1);
          REPEAT
            IF CharReady(bsBBSPort) THEN
            BEGIN
              PeekChar(bsBBSPort,C,1);
              CASE C OF
              #$01,
              #$16:  BEGIN
                       GetModem7FileName := '<SKIPPED>';
                       Exit;
                     END;
              ELSE   GetChar(bsBBSPort,C);
              END;
            END;
          UNTIL TimerExpired(TTimer);
          IF Retries=5 THEN GOTO MR0;
          GOTO MRS0;
     *)

     MR0:
          Retries := 0;
          Tmp     := '';
          IF ((TimerExpired(MainTimer)) OR (Retries=20)) THEN
          BEGIN
               GetModem7FileName := '';
               Exit;
          END;
          INC(Retries);
          PutChar(bsBBSPort,#$15);

     MR1:
          NewTimerSecs(TTimer,4);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$06 : BEGIN {ACK}
                                 GOTO MR2;
                            END;
                     #$04 : BEGIN {EOT}
                                 GetModem7FileName := '';
                                 Exit;
                            END;
                     END;
                END;
          UNTIL TimerExpired(TTimer);
          GOTO MR0;

     MR2:
          NewTimerSecs(TTimer,4);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$04 : BEGIN {EOT}
                                 GetModem7FileName := '';
                                 Exit;
                            END;
                     #$1A : BEGIN {SUB}
                                 Tmp    := Tmp+C;
                                 BCheck := 0;
                                 FOR Loop := 1 TO LENGTH(Tmp) DO
                                     BCheck := UpdateChecksum(Ord(Tmp[Loop]),BCheck);
                                 Dec(Tmp[0]);
                                 Work := Lo(BCheck);
                                 PutChar(bsBBSPort,Chr(Work));
                                 GOTO MR3;
                            END;
                     'u'  : GOTO MR0;
                     ELSE   BEGIN
                                 PutChar(bsBBSPort,#$06);
                                 Tmp := Tmp+C;
                                 GOTO MR2;
                            END;
                     END;
                END;
          UNTIL TimerExpired(TTimer);
          GOTO MR0;

     MR3:
          NewTimerSecs(TTimer,4);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$06 : BEGIN {ACK}
                                 GOTO MR4;
                            END;
                     ELSE   GOTO MR0;
                     END;
                END;
          UNTIL TimerExpired(TTimer);
          GOTO MR0;

     MR4:

     Tmp2 := _Mid(Tmp,1,8)+'.'+_Mid(Tmp,9,11);
     Tmp  := _RemoveSpaces(Tmp2);
     GetModem7FileName := Tmp;
END;


FUNCTION SendModem7FileName(FName: String): Boolean;
VAR  Loop      : Byte;
     BCheck    : Word;
     ChkSum    : Byte;
     Retries   : Byte;
     Temp      : String;
     MainTimer : EventTimer;
     TTimer    : EventTimer;
     CharCount : Byte;
     C         : Char;
LABEL            MS0,MS1,MS2;
BEGIN
     Temp := _PadRight(_NoExtension(FName),8)+_PadRight(_GetFileExtension(FName),3);
     BCheck := 0;
     FOR Loop := 1 TO LENGTH(Temp) DO BCheck := UpdateChecksum(Ord(Temp[Loop]),BCheck);
     BCheck := UpdateChecksum(Ord(#$1A),BCheck);
     ChkSum := Lo(BCheck);

     NewTimerSecs(MainTimer,60);
     Retries := 0;
     MS0:
          CharCount := 0;
          IF ((TimerExpired(MainTimer)) OR (Retries=20)) THEN
          BEGIN
               SendModem7FileName := False;
               Exit;
          END;
          IF CharReady(bsBBSPort) THEN
          BEGIN
               PeekChar(bsBBSPort,C,1);
               CASE C OF
               #$15 : BEGIN {NAK}
                           GetChar(bsBBSPort,C);
                           INC(CharCount);
                           PutChar(bsBBSPort,#$06);
                           PutChar(bsBBSPort,Temp[CharCount]);
                           GOTO MS1;
                      END;
               'C':   BEGIN {Remote Wishes To Skip It}
                           SendModem7FileName := True;
                           Exit;
                      END;
               ELSE   GetChar(bsBBSPort,C);
               END;
          END;
          GOTO MS0;

     MS1:
          NewTimerSecs(TTimer,4);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     CASE C OF
                     #$06 : BEGIN {ACK}
                                 INC(CharCount);
                                 IF CharCount=12 THEN
                                 BEGIN
                                      PutChar(bsBBSPort,#$1A);
                                      GOTO MS2;
                                 END
                                 ELSE
                                 BEGIN
                                      PutChar(bsBBSPort,Temp[CharCount]);
                                      GOTO MS1;
                                 END;
                            END;
                     ELSE   BEGIN
                                 PutChar(bsBBSPort,'u');
                                 INC(Retries);
                                 GOTO MS0;
                            END;
                     END;
                END;
          UNTIL TimerExpired(TTimer);
          PutChar(bsBBSPort,'u');
          INC(Retries);
          GOTO MS0;

     MS2:
          NewTimerSecs(TTimer,4);
          REPEAT
                IF CharReady(bsBBSPort) THEN
                BEGIN
                     GetChar(bsBBSPort,C);
                     IF Ord(C)=ChkSum THEN
                     BEGIN
                          PutChar(bsBBSPort,#$06);
                          SendModem7FileName := True;
                          Exit;
                     END
                     ELSE
                     BEGIN
                          PutChar(bsBBSPort,'u');
                          INC(Retries);
                          GOTO MS0;
                     END;
                END;
          UNTIL TimerExpired(TTimer);
          PutChar(bsBBSPort,'u');
          INC(Retries);
          GOTO MS0;

END;


FUNCTION FTS0001Sender(FTS6Bypass: Boolean): Boolean;
VAR  GotIt   : Boolean;
     AllDone : Boolean;
     TTimer  : EventTimer;
     C       : Char;
LABEL        JumpIn,Skip;
BEGIN
     GotIt := True;
     IF CallingOut THEN InitFTS1Dat(MailQueue^[MailQueuePointer].DestAddr)
                   ELSE InitFTS1Dat(RemoteSystem.Akas[1]);
     IF TransmitFiles(MailerInfo.OutPkts+'TMP$$$$$.PKT','X') THEN
     BEGIN
          IF FTS6Bypass THEN GOTO JumpIn;
          SetUpOutgoingTransfer;
          JumpIn:
          IF (FilesToSend<>0) THEN
          BEGIN
               ASSIGN(FListFile,Shotgun_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
               RESET(FListFile);
               REPEAT
                     READ(FListFile,ListFile);
                     IF SendModem7FileName(_NoPath(ListFile.FName)) THEN
                     BEGIN
                          ShesAFreak := ListFile.IsFreq;
                          IF NOT(TransmitFiles(ListFile.FName,'T')) THEN GotIt := False;
                     END
                     ELSE GotIt := False;
                     IF NOT(GotIt) THEN
                     BEGIN
                          CLOSE(FListFile);
                          GOTO Skip;
                     END;
               UNTIL EOF(FListFile);
               CLOSE(FListFile);
          END;
          AllDone := False;
          NewTimerSecs(TTimer,10);
          REPEAT
                IF TimerExpired(TTimer) THEN
                BEGIN
                     AllDone := True;
                END
                ELSE
                BEGIN
                     IF CharReady(bsBBSPort) THEN
                     BEGIN
                          GetChar(bsBBSPort,C);
                          IF C=#$15 THEN AllDone := True;
                     END;
                END;
          UNTIL AllDone;
          PutChar(bsBBSPort,#$04);
     END
     ELSE GotIt := False;
     Skip:
     _EraseFile(MailerInfo.OutPkts+'TMP$$$$$.PKT');
     FTS0001Sender := GotIt;
END;


FUNCTION FTS0001RemoteHasSomething: Boolean;
VAR  GotSomething : Boolean;
     TTimer       : EventTimer;
     C            : Char;
BEGIN
     GotSomething := True;
     NewTimerSecs(TTimer,60);
     REPEAT
           IF NOT(bsCarrierDetected) THEN GotSomething := False;
           IF TimerExpired(TTimer) THEN GotSomething := False;
           IF CharReady(bsBBSPort) THEN
           BEGIN
                GetChar(bsBBSPort,C);
                CASE C OF
                #$AE:  BEGIN
                         FTS0001RemoteHasSomething := True;
                         Exit;
                       END;
                END;
           END;
     UNTIL NOT(GotSomething);
     FTS0001RemoteHasSomething := False;
END;


FUNCTION FTS0001WeHaveSomething(FTS6Bypass: Boolean): Byte;
VAR  AllDone : Boolean;
     TTimer  : EventTimer;
     C       : Char;
     Tries   : Word;
LABEL          JumpIn;
BEGIN
     IF FTS6Bypass THEN GOTO JumpIn;
     SetUpOutgoingTransfer;
     JumpIn:
     IF (FilesToSend<>0) THEN
     BEGIN
          FOR Tries := 1 TO 5 DO
          BEGIN
               AllDone := False;
               PutChar(bsBBSPort,#$AE);
               NewTimerSecs(TTimer,5);
               REPEAT
                     IF TimerExpired(TTimer) THEN AllDone := True;
                     IF NOT(bsCarrierDetected) THEN AllDone := True;
                     IF CharReady(bsBBSPort) THEN
                     BEGIN
                          PeekChar(bsBBSPort,C,1);
                          IF ((C='C') OR (C=#$15)) THEN
                          BEGIN
                               FTS0001WeHaveSomething := 1;
                               Exit;
                          END
                          ELSE GetChar(bsBBSPort,C);
                     END;
               UNTIL AllDone;
          END;
          FTS0001WeHaveSomething := 2;
     END
     ELSE FTS0001WeHaveSomething := 0;
END;


FUNCTION FTS0001Receiver(FTS6Bypass: Boolean): Boolean;
VAR  PacketName : String;
     Error      : Boolean;
LABEL             JumpIn;
BEGIN
     Error := False;
     IF FTS6Bypass THEN GOTO JumpIn;
     _EraseFile(Mailer2Info.InSecureInbound+'TMP$$$$$.PKT');
     IF ReceiveFiles(Mailer2Info.InSecureInbound+'TMP$$$$$.PKT','X') THEN
     BEGIN
          IF CreateRecordsFTS1 THEN
          BEGIN
               JumpIn:
               DrawSessionWindow(5);
               REPEAT
                     PacketName := GetModem7FileName;
                     IF (PacketName<>'') THEN
                     BEGIN
                          IF SecureSession THEN
                          BEGIN
                               _EraseFile(MailerInfo.Inbound+PacketName);
                               IF NOT(ReceiveFiles(MailerInfo.Inbound+PacketName,'T')) THEN Error := True;
                          END
                          ELSE
                          BEGIN
                               _EraseFile(Mailer2Info.InSecureInbound+PacketName);
                               IF NOT(ReceiveFiles(Mailer2Info.InSecureInbound+PacketName,'T')) THEN Error := True;
                          END;
                     END;
               UNTIL ((PacketName='') OR (Error) OR (NOT(bsCarrierDetected)));
          END
          ELSE Error := True;
     END
     ELSE Error := True;
     IF Error THEN FTS0001Receiver := False
              ELSE FTS0001Receiver := True;
END;


END.