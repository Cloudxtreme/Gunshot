{$I DEFINES.INC}
UNIT Hatch;


INTERFACE


PROCEDURE HatchTheFile(FileName,Desc: String; AreaNum: Word);


IMPLEMENTATION


USES CnfgVars,BsString,BsFile,BsCrc,Defaults,Version,Dos,
     TicName,Misc,Gunshot,BsFido,MkMisc,BsAkas,KeyCheck;



FUNCTION GetNextFileName: String;
VAR  Temp : String;
BEGIN
     _CreatePath(MailerInfo.Outbound);
     Temp := NextTicName(MailerInfo.Outbound);
     GetNextFileName := Temp;
END;


PROCEDURE StringToAddress(WA: String; VAR ResultAddr: AddrType);
VAR  Loop       : Word;
     Work       : Word;
     Temp       : String;
BEGIN
     {START AT ZERO}
     ResultAddr.Zone  := 0;
     ResultAddr.Net   := 0;
     ResultAddr.Node  := 0;
     ResultAddr.Point := 0;
     {ZONE}
     Work := Pos(':',WA);
     ResultAddr.Zone := _Numeric(_Mid(WA,1,Work-1));
     Delete(WA,1,Work);
     {NET}
     Work := Pos('/',WA);
     ResultAddr.Net := _Numeric(_Mid(WA,1,Work-1));
     Delete(WA,1,Work);
     {NODE}
     Work := Pos('.',WA);
     IF Work=0 THEN
     BEGIN
          ResultAddr.Node := _Numeric(WA);
          Exit;
     END;
     ResultAddr.Net := _Numeric(_Mid(WA,1,Work-1));
     Delete(WA,1,Work);
     ResultAddr.Point := _Numeric(WA);
END;


FUNCTION PathTime: String;
CONST Days   : Array[0..6] Of String[3] = ('Sun','Mon','Tue','Wed','Thr','Fri','Sat');
CONST Months : Array[1..12] Of String[3] = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
     Temp         : String;

     FUNCTION PadIt(InWord: Word): String;
     VAR  Crap : String;
     BEGIN
          Crap := _String(InWord);
          IF LENGTH(Crap)=1 THEN Crap := '0'+Crap;
          PadIt := Crap;
     END;

BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     Temp := ' '+_String(DTToUnixDate(DT))+' '+Days[dow]+' '+Months[mm]+' '+PadIt(dd)+' ';
     Temp := Temp+PadIt(h)+':'+PadIt(m)+':'+PadIt(s)+' '+_String(yy)+' UTC'+System_Info.UTCSetting;
     PathTime := Temp;
END;


PROCEDURE HatchTheFile(FileName,Desc: String; AreaNum: Word);
TYPE Outgoing_Tic = RECORD
     Area         : String[80];
     Origin       : String[80];
     FileName     : String[80];
     Desc         : String[80];
     Crc          : String[80];
     Sig          : String;
     Pw           : String[80];
     AreaName     : String[40];
     END;
VAR  OrigAddr     : AddrType;
     TFile        : Text;
     OutTic       : Outgoing_Tic;
     TicFileName  : String;
     EchoTag      : _GSFileDat_Record;
     FEchoTag     : File Of _GSFileDat_Record;
     SBF          : Text;
     Temp         : String;

     PROCEDURE MakeSeenBys;
     BEGIN
          ASSIGN(SBF,WorkDir+'\SBF.$$$');
          REWRITE(SBF);
          ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
          {$I-}RESET(FEchoTag);{$I+}
          IF IOResult=0 THEN
          BEGIN
               REPEAT
                     READ(FEchoTag,EchoTag);
                     IF EchoTag.AreaId=AreaNum THEN
                     BEGIN
                          Temp := 'Seenby '+AddressToString(EchoTag.Aka);
                          WRITELN(SBF,Temp);
                     END;
               UNTIL EOF(FEchoTag);
               CLOSE(FEchoTag);
          END;
          CLOSE(SBF);
     END;

BEGIN
     CheckFile('MAILER.DAT');
     CheckFile('SYSTEM.DAT');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     OutTic.FileName := 'File '+_NoPath(FileName);
     OutTic.Desc     := 'Desc '+Desc;
     OutTic.Crc      := 'Crc '+FileCrc32(FileName);
     OutTic.Sig      := OurAppName+' '+GunshotCopyright;
     OutTic.Area     := '';
     OutTic.AreaName := '';
     ASSIGN(FFileArea,BaseDirectory+'\DATA\FA000000.DAT');
     RESET(FFileArea);
     REPEAT
           READ(FFileArea,FileArea);
           IF FileArea.AreaID=AreaNum THEN
           BEGIN
                OutTic.Area := 'Area '+FileArea.Area_Tag;
                OutTic.AreaName := 'Areadesc '+FileArea.Area_Name;
           END;
     UNTIL ((EOF(FFileArea)) OR (OutTic.Area<>''));
     CLOSE(FFileArea);
     MakeSeenBys;
     ASSIGN(FEchoTag,BaseDirectory+'\DATA\GSFILE.DAT');
     {$I-}RESET(FEchoTag);{$I+}
     IF IOResult=0 THEN
     BEGIN
          _CreatePath(MailerInfo.NetMail);
          REPEAT
                READ(FEchoTag,EchoTag);
                IF EchoTag.AreaId=AreaNum THEN
                BEGIN
                     {Create the TIC file}
                     TicFileName   := GetNextFileName;
                     OutTic.Origin := '';
                     ASSIGN(FLinks,BaseDirectory+'\DATA\LINKS.DAT');
                     RESET(FLinks);
                     REPEAT
                           READ(FLinks,Links);
                           IF AkasMatch(Links.NetworkAddress,EchoTag.Aka) THEN
                           BEGIN
                                OutTic.Origin := GetNetAddress(Links.AkaToUse);
                                OutTic.Pw     := 'Pw '+_UpperCase(Links.GSFileTIC);
                           END;
                     UNTIL ((EOF(FLinks)) OR (OutTic.Origin<>''));
                     CLOSE(FLinks);
                     ASSIGN(TFile,TicFileName);
                     REWRITE(TFile);
                     WRITELN(TFile,OutTic.Area);
                     WRITELN(TFile,OutTic.AreaName);
                     WRITELN(TFile,'Origin '+OutTic.Origin);
                     WRITELN(TFile,'From '+OutTic.Origin);
                     WRITELN(TFile,OutTic.FileName);
                     WRITELN(TFile,OutTic.Desc);
                     WRITELN(TFile,OutTic.Crc);
                     WRITELN(TFile,OutTic.Sig);
                     WRITELN(TFile,'Path '+OutTic.Origin+PathTime);
                     WRITELN(TFile,'Seenby '+OutTic.Origin);
                     ASSIGN(SBF,WorkDir+'\SBF.$$$');
                     {$I-}RESET(SBF);{$I+}
                     IF IOResult=0 THEN
                     BEGIN
                          REPEAT
                                IF NOT(EOF(SBF)) THEN
                                BEGIN
                                     READLN(SBF,Temp);
                                     WRITELN(TFile,Temp);
                                END;
                          UNTIL EOF(SBF);
                          CLOSE(SBF);
                     END;
                     WRITELN(TFile,OutTic.Pw);
                     CLOSE(TFile);
                     StringToAddress(GetNetAddress(Links.AkaToUse),OrigAddr);
                     {The File}
                     wFidoStartNewMessage(MailerInfo.NetMail,OurAppName,0);
                     wFidoSetMsgFrom(OurAppName);
                     wFidoSetMsgTo(Links.SysopName);
                     wFidoSetMsgSubject(FileName);
                     wFidoSetAkas(OrigAddr,Links.NetWorkAddress);
                     wFidoSetFileAttached(True);
                     CASE Links.NetMailStatus OF
                     2:   wFidoSetHoldForPickup(True);
                     3:   wFidoSetCrash(True);
                     END;
                     wFidoSetDirect(True);
                     wFidoWriteHeader(True);
                     wFidoEndMessage;
                     {The TIC}
                     wFidoStartNewMessage(MailerInfo.NetMail,OurAppName,0);
                     wFidoSetMsgFrom(OurAppName);
                     wFidoSetMsgTo(Links.SysopName);
                     wFidoSetMsgSubject(TicFileName);
                     wFidoSetAkas(OrigAddr,Links.NetWorkAddress);
                     wFidoSetFileAttached(True);
                     wFidoSetKillFile(True);
                     CASE Links.NetMailStatus OF
                     2:   wFidoSetHoldForPickup(True);
                     3:   wFidoSetCrash(True);
                     END;
                     wFidoSetDirect(True);
                     wFidoWriteHeader(True);
                     wFidoEndMessage;
                END;
          UNTIL EOF(FEchoTag);
          CLOSE(FEchoTag);
     END;
     _EraseFile(WorkDir+'\SBF.$$$');
END;


END.
