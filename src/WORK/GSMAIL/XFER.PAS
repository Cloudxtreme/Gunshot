{$I DEFINES.INC}
UNIT XFer;


INTERFACE


FUNCTION  TransmitFiles     (Filename: String; Proto: Char)   : Boolean;
FUNCTION  ReceiveFiles      (Filename: String; Proto: Char)   : Boolean;
PROCEDURE DrawSessionWindow (WhichWay: Byte);


IMPLEMENTATION


USES Globals,Crt,FastW1,SaveScrn,DrawScrn,ApAbsPcl,BsLog,BsMulti,
     ApMisc,ApXModem,ApZModem,ApTimer,ApPort,ApCom,Dos,Misc,BsAkas,
     BsString,BsFile,BsTime,BsCom,BsVideo,DoProg,Time;


VAR CarrierTimer      : EventTimer;
    LastFile          : String;
    CurrentYPos       : Byte;
    FileCount         : Longint;


PROCEDURE WaitForAutoStart;
VAR  ZInitTimer : EventTimer;
     AllDone    : Boolean;
     Temp       : String;
     C          : Char;
BEGIN
     AllDone := False;
     NewTimerSecs(ZInitTimer,2);
     Temp := '';
     REPEAT
       IF TimerExpired(ZInitTimer) THEN Exit;
       IF CharReady(bsBBSPort) THEN
       BEGIN
         GetChar(bsBBSPort,C);
         Temp := Temp+C;
         IF (Pos(#24+'B00',Temp)<>0) THEN Exit;
         IF Ord(Temp[0])>200 THEN Delete(Temp,1,50);
       END
       ELSE TimeSlice;
     UNTIL AllDone;
END;


PROCEDURE DrawSessionWindow(WhichWay: Byte);
VAR  TTT : String;

     PROCEDURE DrawMainWindow;
     VAR  Loop : Word;
     BEGIN
          WhereXYAbs(KeepXY);
          SaveScreen(1);
          IF CallingOut
             THEN FastWrite(' Press Esc to abort the session                                        OUTBOUND ',
                            NumLines,1,GunshotColours.GSMailStatusHighlight)
             ELSE FastWrite(' Press Esc to abort the session                                         INBOUND ',
                            NumLines,1,GunshotColours.GSMailStatusHighlight);
          DrawWindow(3,2,78,NumLines-2,'',True);
          CASE GunshotColours.GSMailWindowFrameStyle OF
          1:   BEGIN {3D}
                 FastWrite('À',6,3,GunshotColours.GSMailWindowFrameHigh);
                 FastWrite(_Replicate('Ä',74)+'Ù',6,4,GunshotColours.GSMailWindowFrameLow);
                 FastWrite('Ú'+_Replicate('Ä',74),15,3,GunshotColours.GSMailWindowFrameHigh);
                 FastWrite('¿',15,78,GunshotColours.GSMailWindowFrameLow);
               END;
          2:   BEGIN {Standard}
                 FastWrite('Ã'+_Replicate('Ä',74)+'´',6,3,GunshotColours.GSMailWindowFrameLow);
                 FastWrite('Ã'+_Replicate('Ä',74)+'´',15,3,GunshotColours.GSMailWindowFrameLow);
               END;
          END;
          FOR Loop := 7 TO 14 DO FastWrite('³',Loop,53,GunshotColours.GSMailWindowFrameLow);
     END;

     PROCEDURE ClearDataAreas;
     VAR  Loop : Word;
     BEGIN
          FastWrite('Block Size :         ',7,55,GunshotColours.GSMailWindowText);
          FastWrite('CRC Type   :         ',8,55,GunshotColours.GSMailWindowText);
          FastWrite('Errors     :         ',9,55,GunshotColours.GSMailWindowText);
          FastWrite('File Start :         ',10,55,GunshotColours.GSMailWindowText);
          FastWrite('Total Time :',11,55,GunshotColours.GSMailWindowText);
          FastWrite('Status   :                    Speed :',7,6,GunshotColours.GSMailWindowText);
          FastWrite('Protocol :                    Time  :          ',8,6,GunshotColours.GSMailWindowText);
          FastWrite('Filename :                    Left  :          ',9,6,GunshotColours.GSMailWindowText);
          FastWrite('Bytes    :                    CPS   :          ',10,6,GunshotColours.GSMailWindowText);
          FastWrite('Sent     :                    Eff % :          ',11,6,GunshotColours.GSMailWindowText);
          FastWrite('Current  :',13,6,GunshotColours.GSMailWindowText);
          FastWrite('°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°',13,17,GunshotColours.GSMailProgressBarBack);
          FastWrite('    ',13,48,GunshotColours.GSMailWindowText);
          IF (SessionType<>'FTS-1') THEN
          BEGIN
            IF TransferMode=Transmit THEN
            BEGIN
              FastWrite('Total    :',14,6,GunshotColours.GSMailWindowText);
              FastWrite('°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°',14,17,GunshotColours.GSMailProgressBarBack);
              FastWrite('    ',14,48,GunshotColours.GSMailWindowText);
            END
            ELSE FastWrite(_Replicate(' ',46),14,6,GunshotColours.GSMailWindowText);
          END;
          FastWrite('Sync With Remote',7,17,GunshotColours.GSMailWindowHighlight);
          FastWrite(_PadRight(' ###  Filename       Status     Bytes     Date        CPS    Time',74),
                    16,4,GunshotColours.GSMailMenuSelected);
          FOR Loop := 17 TO NumLines-3 DO FastWrite(_Replicate(' ',74),Loop,4,GunshotColours.GSMailWindowText);
          pCurrent := 0;
     END;

BEGIN
  CASE WhichWay OF
  0:   BEGIN
         DrawMainWindow;
         FastWrite(_Mid(RemoteSystem.BBSName,1,60),3,5,GunshotColours.GSMailWindowHighlight);
         IF RemoteSystem.MailerVersion=''
           THEN TTT := RemoteSystem.MailerName
           ELSE TTT := RemoteSystem.MailerName+' '+RemoteSystem.MailerVersion;
         FastWrite(TTT,3,77-LENGTH(TTT),GunshotColours.GSMailWindowText);
         FastWrite(RemoteSystem.Location,4,5,GunshotColours.GSMailWindowText);
         FastWrite(RemoteSystem.Sysop,5,5,GunshotColours.GSMailWindowText);
         TTT := AddressToString(RemoteSystem.Akas[1]);
         FastWrite(TTT,4,77-LENGTH(TTT),GunshotColours.GSMailWindowText);
         FastWrite(SessionType,5,77-LENGTH(SessionType),GunshotColours.GSMailWindowText);
         FastWrite(_String(ConnectRate),7,44,GunshotColours.GSMailWindowHighlight);
       END;
  1,2: ClearDataAreas;
  3:   BEGIN
         RestoreScreen(1);
         TextColor(7);
         TextBackGround(0);
         GotoXYAbs(KeepXY);
       END;
  4:   BEGIN
         DrawMainWindow;
         ClearDataAreas;
         FastWrite(SessionType,5,77-LENGTH(SessionType),GunshotColours.GSMailWindowText);
         FastWrite(_String(ConnectRate),7,44,GunshotColours.GSMailWindowHighlight);
       END;
  5:   BEGIN
         FastWrite(_Mid(RemoteSystem.BBSName,1,60),3,5,GunshotColours.GSMailWindowHighlight);
         IF RemoteSystem.MailerVersion=''
           THEN TTT := RemoteSystem.MailerName
           ELSE TTT := RemoteSystem.MailerName+' '+RemoteSystem.MailerVersion;
         FastWrite(TTT,3,77-LENGTH(TTT),GunshotColours.GSMailWindowText);
         FastWrite(RemoteSystem.Location,4,5,GunshotColours.GSMailWindowText);
         FastWrite(RemoteSystem.Sysop,5,5,GunshotColours.GSMailWindowText);
         TTT := AddressToString(RemoteSystem.Akas[1]);
         FastWrite(TTT,4,77-LENGTH(TTT),GunshotColours.GSMailWindowText);
       END;
  END;
END;


{$F+}
PROCEDURE WindowStatus(P: ProtocolRecPtr; Starting,Ending: Boolean);
VAR   CurFileSize         : Longint;
      CurBytesRemaining   : Longint;
      CurBytesTransferred : Longint;
      CurElapsedTics      : Longint;
      LastBytesSent       : Longint;
      S                   : String;
      R                   : Longint;
      ActualCPS           : Longint;
      Temp                : String;
      Work                : Word;
      Efficiency          : Real;
      MaxCPS              : Real;
      Ext                 : String;
      Eff                 : Longint;
      TheFile             : String;
      TheProto            : String[30];

      PROCEDURE ClearProgress;
      BEGIN
           FastWrite('°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°',13,17,GunshotColours.GSMailProgressBarBack);
           FastWrite('    ',13,48,GunshotColours.GSMailWindowText);
           pCurrent := 0;
      END;

      PROCEDURE ClearData;
      BEGIN
           FastWrite('Protocol :                    Time  :          ',8,6,GunshotColours.GSMailWindowText);
           FastWrite('Filename :                    Left  :          ',9,6,GunshotColours.GSMailWindowText);
           FastWrite('Bytes    :                    CPS   :          ',10,6,GunshotColours.GSMailWindowText);
           FastWrite('Sent     :                    Eff % :          ',11,6,GunshotColours.GSMailWindowText);
           FastWrite('Block Size :         ',7,55,GunshotColours.GSMailWindowText);
           FastWrite('CRC Type   :         ',8,55,GunshotColours.GSMailWindowText);
           FastWrite('Errors     :         ',9,55,GunshotColours.GSMailWindowText);
           FastWrite('File Start :         ',10,55,GunshotColours.GSMailWindowText);
      END;

BEGIN
     FastWrite(HoursMinutesSeconds(ElapsedTimeInSecs(SessionTimer)),11,68,GunshotColours.GSMailWindowHighlight);
     IF ((Starting) OR (Ending)) THEN
     BEGIN
       ClearData;
       ClearProgress;
     END
     ELSE
     BEGIN
       WITH P^.PData^ DO
       BEGIN
         TheFile := _UpperCase(GetFileName(P));
         IF TheFile='' THEN
         BEGIN
           ClearData;
           ClearProgress;
           LastFile := TheFile;
         END
         ELSE
         BEGIN
           IF LastFile<>TheFile THEN
           BEGIN
             ClearData;
             ClearProgress;
             LastFile := TheFile;
           END;
           CurBytesTransferred := GetBytesTransferred(P);
           CurElapsedTics := GetElapsedTics(P);
           CurFileSize       := GetFileSize(P);
           CurBytesRemaining := GetBytesRemaining(P);
           IF Protocol=ZModem THEN TheProto := 'ZModem       '
                              ELSE TheProto := 'XModem       ';
           IF ((CurBytesTransferred>CurFileSize) AND (CurFileSize<>0)) THEN CurBytesTransferred := CurFileSize;
           FastWrite(TheProto,8,17,GunshotColours.GSMailWindowHighlight);
           Temp := TheFile;
           Ext  := _GetFileExtension(Temp);
                IF Ext='REQ' THEN FastWrite('File Request',9,17,GunshotColours.GSMailWindowHighlight)
           ELSE IF Ext='PKT' THEN FastWrite('Mail Packet ',9,17,GunshotColours.GSMailWindowHighlight)
           ELSE FastWrite(_PadRight(Temp,12),9,17,GunshotColours.GSMailWindowHighlight);
           IF (TheProto<>'XModem       ') THEN
           BEGIN
             S := _String(CurFileSize);
             FastWrite(_PadRight(S,9),10,17,GunshotColours.GSMailWindowHighlight);
             FastWrite(_PadRight(_String(CurBytesTransferred),9),11,17,GunshotColours.GSMailWindowHighlight);
             FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurFileSize)),6),
                       8,44,GunshotColours.GSMailWindowHighlight);
             FastWrite(_PadRight(FormatMinSec(EstimateTransferSecs(P,CurBytesRemaining)),6),
                       9,44,GunshotColours.GSMailWindowHighlight);
           END
           ELSE
           BEGIN
             FastWrite('n/a      ',10,17,GunshotColours.GSMailWindowHighlight);
             FastWrite('n/a      ',11,17,GunshotColours.GSMailWindowHighlight);
             FastWrite('n/a   ',8,44,GunshotColours.GSMailWindowHighlight);
             FastWrite('n/a   ',9,44,GunshotColours.GSMailWindowHighlight);
           END;
           IF CurElapsedTics>0 THEN
           BEGIN
             R         := CurBytesTransferred-GetInitialFilePos(P);
             ActualCPS := Trunc(R/(CurElapsedTics/18.2));
             LastCPS   := ActualCPS;
           END
           ELSE ActualCPS := 0;
           FastWrite(_PadRight(_String(ActualCPS),6),10,44,GunshotColours.GSMailWindowHighlight);
           MaxCPS := ConnectRate DIV 10;
           IF MaxCPS>0 THEN Efficiency := (ActualCPS/MaxCPS)*100.0
                       ELSE Efficiency := 0.0;
           Eff := Round(Efficiency);
           LastPercent := _String(Eff)+'%';
           FastWrite(_PadRight(_String(Eff),8),11,44,GunshotColours.GSMailWindowHighlight);
           IF (CurFileSize<>0) THEN DoProgressBar(CurBytesTransferred,CurFileSize,30,pCurrent,17,13,True);
           IF ((TransferMode=Transmit) AND (SessionType<>'FTS-1')) THEN
           BEGIN
             IF (BytesToSend<>0) THEN DoProgressBar(BytesActuallySent+CurBytesTransferred,BytesToSend,30,pTotal,17,14,True);
           END;
           FastWrite(_PadRight(_String(GetBlockSize(P)),9),7,68,GunshotColours.GSMailWindowHighlight);
           CASE GetCheckType(P) OF
           bcNone:      Temp := bcsNone;
           bcCheckSum1: Temp := bcsCheckSum1;
           bcCheckSum2: Temp := bcsCheckSum2;
           bcCrc16:     Temp := bcsCrc16;
           bcCrc32:     Temp := bcsCrc32;
           bcCrcK:      Temp := bcsCrcK;
           END;
           FastWrite(_PadRight(Temp,9),8,68,GunshotColours.GSMailWindowHighlight);
           FastWrite(_PadRight(_String(GetTotalErrors(P)),9),9,68,GunshotColours.GSMailWindowHighlight);
           FastWrite(_PadRight(_String(GetInitialFilePos(P)),9),10,68,GunshotColours.GSMailWindowHighlight);
         END;
       END;
     END;
END;
{$F-}

{$F+}
PROCEDURE LogFileActivity(P : ProtocolRecPtr; LogFileStatus : LogFileType);
VAR  TheExt    : String;
     FFile     : File;
     FSize     : Longint;
     IsAPacket : Boolean;
     IsABundle : Boolean;

     PROCEDURE AdvancePointer;
     BEGIN
          INC(CurrentYPos);
          INC(FileCount);
          IF CurrentYPos>NumLines-3 THEN
          BEGIN
            Get(4,18,77,NumLines-3);
            Put(4,17);
            FastWrite(_Replicate(' ',74),NumLines-3,4,GunshotColours.GSMailWindowText);
            CurrentYPos := NumLines-3;
          END;
     END;

     PROCEDURE DoSent;
     BEGIN
          FastWrite(_String(FileCount),CurrentYPos,5,GunshotColours.GSMailWindowText);
          FastWrite(_NoPath(GetPathName(P)),CurrentYPos,10,GunshotColours.GSMailWindowText);
          FastWrite('Complete',CurrentYPos,25,GunshotColours.GSMailWindowText);
          FastWrite(_String(FSize),CurrentYPos,36,GunshotColours.GSMailWindowText);
          FastWrite(_UnpackedDate(_FileDate(GetPathName(P))),CurrentYPos,46,GunshotColours.GSMailWindowText);
          FastWrite(_String(LastCPS),CurrentYPos,58,GunshotColours.GSMailWindowText);
          FastWrite(FormatMinSec(Tics2Secs(GetElapsedTics(P))),CurrentYPos,65,GunshotColours.GSMailWindowText);
          AdvancePointer;
     END;

     PROCEDURE DoStart;
     BEGIN
          FastWrite(_String(FileCount),CurrentYPos,5,GunshotColours.GSMailWindowHighlight);
          FastWrite(_NoPath(GetPathName(P)),CurrentYPos,10,GunshotColours.GSMailWindowHighlight);
          FastWrite('Current ',CurrentYPos,25,GunshotColours.GSMailWindowHighlight);
     END;

     PROCEDURE DoFail;
     BEGIN
          FastWrite(_String(FileCount),CurrentYPos,5,GunshotColours.GSMailWindowText);
          FastWrite(_NoPath(GetPathName(P)),CurrentYPos,10,GunshotColours.GSMailWindowText);
          FastWrite('Failed  ',CurrentYPos,25,GunshotColours.GSMailWindowText);
          AdvancePointer;
     END;

     PROCEDURE DoSkip;
     BEGIN
          FastWrite(_String(FileCount),CurrentYPos,5,GunshotColours.GSMailWindowText);
          FastWrite(_NoPath(GetPathName(P)),CurrentYPos,10,GunshotColours.GSMailWindowText);
          FastWrite('Skipped ',CurrentYPos,25,GunshotColours.GSMailWindowText);
          AdvancePointer;
     END;

BEGIN
     CASE LogFileStatus OF
     lfReceiveStart:
       BEGIN
         DoStart;
       END;
     lfReceiveOk:
       BEGIN
         FSize := GetFileSize(P);
         TheExt := _GetFileExtension(GetPathName(P));
         IsAPacket := False;
         IsABundle := False;
         IF TheExt='PKT' THEN IsAPacket := True;
         IF TheExt='TIC' THEN ReceivedMail := True;
         IF TheExt='GIP' THEN ReceivedMail := True;
         TheExt[0] := #2;
         IF TheExt='SU' THEN IsABundle := True;
         IF TheExt='MO' THEN IsABundle := True;
         IF TheExt='TU' THEN IsABundle := True;
         IF TheExt='WE' THEN IsABundle := True;
         IF TheExt='TH' THEN IsABundle := True;
         IF TheExt='FR' THEN IsABundle := True;
         IF TheExt='SA' THEN IsABundle := True;
         IF IsAPacket THEN
         BEGIN
           INC(MailHistory.ReceivedNetmailBytes,FSize);
           ReceivedMail := True;
         END
         ELSE IF IsABundle THEN
         BEGIN
           INC(MailHistory.ReceivedBundleBytes,FSize);
           ReceivedMail := True;
         END
         ELSE
         BEGIN
           INC(MailHistory.ReceivedOtherBytes,FSize);
         END;
         bsWriteLog('Rcvd '+GetPathName(P),False);
         bsWriteLog('ÀÄ Efficiency '+LastPercent+' ('+_String(FSize)+' bytes), '+_String(LastCPS)+' CPS',False);
         INC(MailHistory.ReceivedTotalBytes,FSize);
         INC(FilesActuallySent);
         DoSent;
       END;
     lfReceiveFail:
       BEGIN
         bsWriteLog('Rcvd '+GetPathName(P)+' (incomplete)',False);
         DoFail;
       END;
     lfReceiveSkip:
       BEGIN
         bsWriteLog('Rcvd '+GetPathName(P)+' (skipped)',False);
         DoSkip;
       END;
     lfTransmitStart:
       BEGIN
         DoStart;
       END;
     lfTransmitOk:
       BEGIN
         FSize := GetFileSize(P);
         INC(BytesActuallySent,FSize);
         TheExt := _GetFileExtension(GetPathName(P));
         IsAPacket := False;
         IsABundle := False;
         IF TheExt='PKT' THEN IsAPacket := True;
         TheExt[0] := #2;
         IF TheExt='SU' THEN IsABundle := True;
         IF TheExt='MO' THEN IsABundle := True;
         IF TheExt='TU' THEN IsABundle := True;
         IF TheExt='WE' THEN IsABundle := True;
         IF TheExt='TH' THEN IsABundle := True;
         IF TheExt='FR' THEN IsABundle := True;
         IF TheExt='SA' THEN IsABundle := True;
         IF IsAPacket THEN
         BEGIN
           INC(MailHistory.SentNetmailBytes,FSize);
         END
         ELSE IF IsABundle THEN
         BEGIN
           INC(MailHistory.SentBundleBytes,FSize);
         END
         ELSE
         BEGIN
           IF GetProtocol(P)=6 THEN
           BEGIN
             IF ListFile.IsFreq THEN
             BEGIN
               INC(MailHistory.SentFreqBytes,FSize);
             END
             ELSE
             BEGIN
               INC(MailHistory.SentOtherBytes,FSize);
             END;
           END
           ELSE
           BEGIN
             IF ShesAFreak THEN
             BEGIN
               INC(MailHistory.SentFreqBytes,FSize);
             END
             ELSE
             BEGIN
               INC(MailHistory.SentOtherBytes,FSize);
             END;
           END;
         END;
         bsWriteLog('Sent '+GetPathName(P),False);
         bsWriteLog('ÀÄ Efficiency '+LastPercent+' ('+_String(FSize)+' bytes), '+_String(LastCPS)+' CPS',False);
         INC(MailHistory.SentTotalBytes,FSize);
         INC(FilesActuallySent);
         DoSent;
       END;
     lfTransmitFail:
       BEGIN
         Success := False;
         bsWriteLog('Sent '+GetPathName(P)+' (incomplete)',False);
         DoFail;
       END;
     lfTransmitSkip:
       BEGIN
         bsWriteLog('Sent '+GetPathName(P)+' (skipped)',False);
         INC(BytesActuallySent,GetFileSize(P));
         DoSkip;
       END;
     END;
END;
{$F-}

{$F+}
FUNCTION KbdAbort : Boolean;
VAR  Ch : Char;
BEGIN
     KbdAbort := False;
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
       NewTimerSecs(CarrierTimer,3);
       IF KeyPressed THEN
       BEGIN
         Ch := ReadKey;
         IF Ch = #0 THEN Ch := ReadKey;
         IF Ch = #27 THEN
         BEGIN
           KbdAbort := True;
           WeAbort  := True;
         END;
       END;
       IF NOT(bsCarrierDetected) THEN
       BEGIN
         KbdAbort := True;
         WeAbort  := True;
       END;
     END;
END;
{$F-}

{$F+}
FUNCTION GetNextFile(PROTO: ProtocolRecPtr; VAR FName: PathStr): Boolean;
BEGIN
     INC(CurrentFileNum);
     IF CurrentFileNum>FilesToSend THEN
     BEGIN
          FName := '';
          GetNextFile := False;
     END
     ELSE
     BEGIN
          {$I-}READ(FListFile,ListFile);{$I+}
          IF IOResult=0 THEN
          BEGIN
               FName := ListFile.FName;
               GetNextFile := True;
          END
          ELSE
          BEGIN
               FName := '';
               GetNextFile := False;
          END;
     END;
END;
{$F-}

PROCEDURE TransferFiles;
BEGIN
     DefProtocolOptions := apRTSLowForWrite;
     FilesActuallySent  := 0;
     BytesActuallySent  := 0;
     CurrentYPos        := 17;
     FileCount          := 1;
     LastFile           := '';
     Success            := True;
     WeAbort            := False;
     pTotal             := 0;
     NewTimerSecs(CarrierTimer,3);
     CASE Protocol OF
     Xmodem : BEGIN
                   InitXmodem(PROTO,bsBBSPort,False,False);
                   IF GetAsyncStatus=ecOk THEN
                   BEGIN
                        SetBlockWait(PROTO,RelaxedBlockWait);
                        SetFinishWaitXM(PROTO,Secs2Tics(10));
                        SetHandshakeWait(PROTO,Secs2Tics(3),10);
                        SetShowStatusProc(PROTO,WindowStatus);
                        SetOverwriteOption(PROTO,WriteRename);
                        SetActualBPS(PROTO,ConnectRate);
                        SetLogFileProc(PROTO,LogFileActivity);
                        SetAbortFunc(bsBBSPort,KbdAbort);
                        CASE TransferMode OF
                        Transmit : BEGIN
                                        SetFileMask(PROTO,SrcFileName);
                                        ProtocolTransmitXM(PROTO);
                                   END;
                        Receive  : BEGIN
                                        SetReceiveFileName(PROTO,SrcFileName);
                                        ProtocolReceiveXM(PROTO);
                                   END;
                        END;
                        DoneXmodem(PROTO);
                        SetAbortFunc(bsBBSPort,NoAbortFunc);
                   END
                   ELSE Success := False;
              END;
     Zmodem : BEGIN
                   TelixDelay := 0;
                   IF DoingZAP THEN DefProtocolOptions := DefProtocolOptions OR apZmodem8K;
                   InitZmodem(PROTO,bsBBSPort);
                   IF GetAsyncStatus=ecOk THEN
                   BEGIN
                        IF transferMode=transmit THEN
                        BEGIN
                             ASSIGN(FListFile,Gunshot_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
                             {$I-}RESET(FListFile);{$I+}
                             IF IOResult=0 THEN;
                        END;
                        IF transferMode=transmit THEN SetNextFileFunc(PROTO,GetNextFile);
                        SetShowStatusProc(PROTO,WindowStatus);
                        SetFinishWaitZM(PROTO,Secs2Tics(5),2);
                        SetHandshakeWait(PROTO,Secs2Tics(10),6);
                        SetActualBPS(PROTO,ConnectRate);
                        SetRecoverOption(PROTO,True);
                        SetLogFileProc(PROTO,LogFileActivity);
                        IF DoingZap THEN SetBigSubPacketOption(PROTO,True);
                        SetAbortFunc(bsBBSPort,KbdAbort);
                        SetFileMgmtOptions(PROTO,True,False,WriteDifferent);
                        CASE TransferMode OF
                        Transmit : ProtocolTransmitZM(PROTO);
                        Receive  : BEGIN
                                        SetDestinationDirectory(PROTO,SrcFileName);
                                        ProtocolReceiveZM(PROTO);
                                   END;
                        END;
                        DoneZmodem(PROTO);
                        SetAbortFunc(bsBBSPort,NoAbortFunc);
                        IF transferMode=transmit THEN
                        BEGIN
                             {$I-}CLOSE(FListFile);{$I+}
                             IF IOResult=0 THEN;
                             _EraseFile(Gunshot_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
                        END;
                   END
                   ELSE Success := False;
              END;
      END;
END;


FUNCTION TransmitFiles(Filename: String; Proto: Char): Boolean;
BEGIN
     TransferMode := Transmit;
     DrawSessionWindow(1);
     CASE Proto OF
     'X': BEGIN
               Protocol := XModem;
          END;
     'Z': BEGIN
               Protocol := ZModem;
               WaitForAutoStart;
          END;
     END;
     SrcFilename := FileName;
     FastWrite('Sending         ',7,17,GunshotColours.GSMailWindowHighlight);
     TransferFiles;
     IF ((FilesActuallySent=0) AND (FilesToSend<>0)) THEN Success := False;
     TransmitFiles := Success;
     IF WeAbort THEN TransmitFiles := False;
END;


FUNCTION ReceiveFiles(Filename: String; Proto: Char): Boolean;
BEGIN
     TransferMode := Receive;
     DrawSessionWindow(2);
     CASE Proto OF
     'X': BEGIN
               Protocol := XModem;
          END;
     'Z': BEGIN
               Protocol := ZModem;
               _Delay(1000);
          END;
     END;
     SrcFilename := FileName;
     IF Proto='Z' THEN ReceivedMail := False;
     FastWrite('Receiving       ',7,17,GunshotColours.GSMailWindowHighlight);
     TransferFiles;
     ReceiveFiles  := Success;
     IF WeAbort THEN ReceiveFiles := False;
END;


END.