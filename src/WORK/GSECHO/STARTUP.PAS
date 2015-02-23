{$I DEFINES.INC}
UNIT StartUp;


INTERFACE


PROCEDURE ProgramStartup;
PROCEDURE ProgramShutDown;
PROCEDURE CreateTemporaryDirs;
PROCEDURE KillTemporaryDirs;
PROCEDURE WriteNodeFile;
PROCEDURE StartNodesOff;
PROCEDURE KillZeroNodes;
PROCEDURE ForceMailerRescan;
PROCEDURE ShowLastTossStats;
PROCEDURE ProcessAddedAreas;
FUNCTION  ThereIsSomethingToDo: Boolean;


IMPLEMENTATION


USES FMode,BsVideo,Crt,Globals,BsString,BsFile,BsLog,MkMsgAbs,MkDos,
     KeyCheck,Shotgun,BsExec,Dos,BsFido,Common,Version,MkOpen,MkString,
     BsAkas,BsTime,_EchoTag;


FUNCTION LoadInDataFiles: Boolean;
VAR  Status      : Boolean;
     FMailer     : File Of _Mailer_Record;
     FArcDefs    : File Of _Archiver_Record;
     FSystemInfo : File Of _SystemDat_Record;
BEGIN
     Status := True;

     IF _FileExists(BaseDirectory+'\DATA\MAILER.DAT') THEN
     BEGIN
       ASSIGN(FMailer,BaseDirectory+'\DATA\MAILER.DAT');
       RESET(FMailer);
       {$I-}SEEK(FMailer,NodeNumber-1);{$I+}
       IF IOResult=0 THEN READ(FMailer,Mailer)
                     ELSE Status := False;
       CLOSE(FMailer);
     END
     ELSE Status := False;

     IF _FileExists(BaseDirectory+'\DATA\ARCHIVE.DAT') THEN
     BEGIN
       ASSIGN(FArcDefs,BaseDirectory+'\DATA\ARCHIVE.DAT');
       RESET(FArcDefs);
       READ(FArcDefs,ArcDefs);
       CLOSE(FArcDefs);
     END
     ELSE Status := False;

     IF _FileExists(BaseDirectory+'\DATA\SYSTEM.DAT') THEN
     BEGIN
       ASSIGN(FSystemInfo,BaseDirectory+'\DATA\SYSTEM.DAT');
       RESET(FSystemInfo);
       READ(FSystemInfo,SystemInfo);
       CLOSE(FSystemInfo);
     END
     ELSE Status := False;

     IF NOT(_FileExists(BaseDirectory+'\DATA\NETWORK.DAT')) THEN Status := False;
     IF NOT(_FileExists(BaseDirectory+'\DATA\LINKS.DAT')) THEN Status := False;

     LoadInDataFiles := Status;
END;


PROCEDURE Help;
BEGIN
     AppHeader('GSEcho - Echo Mail Processor For Shotgun Professional');
     Window(1,1,80,25);
     GotoXY(1,7);
     TextColor(7);
     WriteLn('GSEcho Command Line Options:');
     WriteLn;
     WriteLn('      GSECHO.EXE <arg> <arg> ...');
     WriteLn;
     WriteLn('             -N<xxx>      : xxx is the node number to use.');
     WriteLn('             -TOSS        : Toss inbound mail into the system.');
     WriteLn('             -SCAN        : Pack mail for sending to other systems.');
     WriteLn('             -ECHOTOSS    : Use Shotgun''s ECHOTOSS features during SCAN.');
     WriteLn('             -NOSTRIP     : Don''t strip message control lines during TOSS.');
     WriteLn('             -NODUPES     : Disable dupe message detection.');
     WriteLn('             -KEEPAFIX    : Keep a copy of areafix messages.');
     TextColor(7);
     Halt;
END;


PROCEDURE ProgramStartup;
VAR  Loop : Word;
     Temp : String;
BEGIN
     FileMode := SetFileMode;
     IF ParamCount=0 THEN Help;
     Toss              := False;
     UseEchoToss       := False;
     StripControlLines := True;
     NodeNumber        := 1;
     CheckDupes        := True;
     DoNotify          := False;
     KeepAFix          := False;
     BaseDirectory     := _UpperCase(_GetFilePath(ParamStr(0)));
     DEC(BaseDirectory[0]);
     TempUnpack        := BaseDirectory+'\!5';
     TempOutbound      := BaseDirectory+'\!6';
     FOR loop := 1 TO paramcount DO
     BEGIN
       Temp := _UpperCase(ParamStr(Loop));
       IF Temp='-TOSS' THEN
       BEGIN
         Toss := True;
       END
       ELSE IF Temp='-KEEPAFIX' THEN
       BEGIN
         KeepAFix := True;
       END
       ELSE IF Temp='-SCAN' THEN
       BEGIN
         Toss := False;
       END
       ELSE IF Temp='-ECHOTOSS' THEN
       BEGIN
         UseEchoToss := True;
       END
       ELSE IF Temp='-NOSTRIP' THEN
       BEGIN
         StripControlLines := False;
       END
       ELSE IF Temp='-?' THEN
       BEGIN
         Help;
       END
       ELSE IF Temp='-NOSEC' THEN
       BEGIN
         {IGNORED}
       END
       ELSE IF Temp='-NODUPES' THEN
       BEGIN
         CheckDupes := False;
       END
       ELSE IF Temp='-NOTIFY' THEN
       BEGIN
         DoNotify := True;
       END
       ELSE IF _Mid(Temp,1,2)='-N' THEN
       BEGIN
         Delete(Temp,1,2);
         NodeNumber := _Numeric(Temp);
       END;
     END;
     IF Toss
        THEN AppHeader('GSEcho - Echo Mail Processor For Shotgun Professional [TOSS]')
        ELSE AppHeader('GSEcho - Echo Mail Processor For Shotgun Professional [SCAN]');
     IF NOT(LoadInDataFiles) THEN Halt;
     CASE SystemInfo.SwapMethod OF
     1:   SwapMethod := USE_EMS or USE_XMS;
     2:   SwapMethod := USE_ALL;
     3:   SwapMethod := USE_FILE or CHECK_NET;
     END;
     Window(1,7,80,25);
     ClrScr;
     New(MsgTextBuffer);
     FLinkGroups.Init(32768);
     FLinksInfo.Init(32768);
     FEchoTag.Init(32768);
     _CreatePath(BaseDirectory+'\LOGS');
     _CreatePath(BaseDirectory+'\INTRNODE');
END;


PROCEDURE ProgramShutDown;
BEGIN
     Dispose(MsgTextBuffer);
     CloseGSEchoDat;
     FLinkGroups.Done;
     FLinksInfo.Done;
     FEchoTag.Done;
END;


PROCEDURE CreateTemporaryDirs;
BEGIN
     _CreatePath(TempUnpack);
     _CreatePath(TempOutbound);
END;


PROCEDURE KillTemporaryDirs;
BEGIN
     _NukeDir(TempUnpack,False);
     _NukeDir(TempOutbound,False);
END;


PROCEDURE WriteNodeFile;
VAR  FNode : File Of _NodeFile_Record;
     Node  : _NodeFile_Record;
BEGIN
     FillChar(Node,SizeOf(Node),0);
     Node.User     := 'GSEcho';
     Node.Activity := 'Processing Network Mail';
     Node.Node     := NodeNumber;
     ASSIGN(FNode,BaseDirectory+'\INTRNODE\NODE'+_String(NodeNumber)+'.$$$');
     {$I-}RESET(FNode);{$I+}
     IF IOResult<>0 THEN REWRITE(FNode);
     WRITE(FNode,Node);
     CLOSE(FNode);
END;


FUNCTION ThereIsSomethingToDo: Boolean;
VAR  Loop        : Word;
     Temp        : String;
     DirInfo     : SearchRec;
     i,j         : Word;
     TempFRecord : FFileRecord;
     NeedToDo    : Boolean;
     OrigAddr    : AddrType;
     DestAddr    : AddrType;
LABEL              OuttaHere;
BEGIN
     NumBundles := 0;
     NeedToDo   := False;
     Thereisanareafix := False;
     {Arc Mail Bundles}
     FOR Loop := 1 TO 7 DO
     BEGIN
       CASE Loop OF
       1:   Temp := '*.SU?';
       2:   Temp := '*.MO?';
       3:   Temp := '*.TU?';
       4:   Temp := '*.WE?';
       5:   Temp := '*.TH?';
       6:   Temp := '*.FR?';
       7:   Temp := '*.SA?';
       END;
       FindFirst(Mailer.Inbound+Temp,AnyFile-Directory-VolumeID,DirInfo);
       WHILE DosError=0 DO
       BEGIN
         NeedToDo := True;
         INC(NumBundles);
         FileNames[NumBundles].FName := DirInfo.Name;
         FileNames[NumBundles].FDate := DirInfo.Time;
         FindNext(DirInfo);
       END;
     END;
     {Raw Packets}
     FindFirst(Mailer.Inbound+'*.PKT',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
       NeedToDo := True;
       INC(NumBundles);
       FileNames[NumBundles].FName := DirInfo.Name;
       FileNames[NumBundles].FDate := DirInfo.Time;
       FindNext(DirInfo);
     END;
     {Sort Them By Date}
     IF (NumBundles<>0) THEN
     BEGIN
       FOR i := 1 TO NumBundles DO
       BEGIN
         FOR j := 1 TO NumBundles DO
         BEGIN
           IF (FileNames[i].FDate<FileNames[j].FDate) THEN
           BEGIN
             TempFRecord  := FileNames[i];
             FileNames[i] := FileNames[j];
             FileNames[j] := TempFRecord;
           END;
         END;
       END;
     END;
     rFidoStartUpArea(Mailer.NetMail);
     IF (rFidoNumberOfMsgs<>0) THEN
     BEGIN
       FOR Loop := 1 TO rFidoNumberOfMsgs DO
       BEGIN
         IF rFidoOpenMessage(Loop) THEN
         BEGIN
           Temp := _UpperCase(rFidoGetMsgTo);
           IF ((Temp='GSECHO') OR (Temp='AREAFIX') OR (Temp='AREAMGR')) THEN
           BEGIN
             IF ((NOT rFidoIsReceived) AND (NOT rFidoIsLocal)) THEN
             BEGIN
               rFidoGetAkas(OrigAddr,DestAddr);
               IF IsOurNode(DestAddr) THEN
               BEGIN
                 NeedToDo := True;
                 Thereisanareafix := True;
               END;
             END;
           END;
           rFidoCloseMessage;
         END;
       END;
     END;
     rFidoCloseArea;
     IF DoNotify THEN NeedToDo := True;
     ThereIsSomethingToDo := NeedToDo;
END;


PROCEDURE StartNodesOff;
VAR  FFile                     : File;
     Temp                      : String;
     Loop                      : Word;
     Year,Month,Day,DayOfWeek  : Word;
     Hour,Minute,Second,Sec100 : Word;
     MajorVersion              : Byte;
     MinorVersion              : Byte;
     BytesRead                 : Word;
     LinksInfo                 : _Links_Record;
BEGIN
     Temp := ShotgunVersion;
     Delete(Temp,1,1);
     IF NOT(_IsNumeric(Temp[LENGTH(Temp)])) THEN DEC(Temp[0]);
     Loop := Pos('.',Temp);
     MajorVersion := _Numeric(_Mid(Temp,1,Loop-1));
     MinorVersion := _Numeric(_Mid(Temp,Loop+1,LENGTH(Temp)));
     GetDate(Year,Month,Day,DayOfWeek);
     GetTime(Hour,Minute,Second,Sec100);
     Temp := _String(Year);
     Delete(Temp,1,2);
     Year := _Numeric(Temp);
     FLinksInfo.OpenFile(BaseDirectory+'\DATA\LINKS.DAT',SetFileMode);
     REPEAT
       FLinksInfo.BlkRead(LinksInfo,SizeOf(LinksInfo),BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
         FillChar(Type2PPacket,SizeOf(Type2PPacket),0);
         Type2PPacket.PktVer    := 2;
         Type2PPacket.CapWord   := 1;
         Type2PPacket.Year      := Year;
         Type2PPacket.Month     := Month;
         Type2PPacket.Day       := Day;
         Type2PPacket.Hour      := Hour;
         Type2PPacket.Min       := Minute;
         Type2PPacket.Sec       := Second;
         Type2PPacket.Baud      := Mailer.BaudRate;
         Type2PPacket.PrdCodL   := Lo(FTSCProductCode);
         Type2PPacket.PrdCodH   := Hi(FTSCProductCode);
         Type2PPacket.PVMajor   := MajorVersion;
         Type2PPacket.PVMinor   := MinorVersion;
         FOR Loop := 1 TO LENGTH(LinksInfo.GSEchoPacket) DO Type2PPacket.Password[Loop] := LinksInfo.GSEchoPacket[Loop];
         Type2PPacket.QDestZone := LinksInfo.NetworkAddress.Zone;
         Type2PPacket.DestZone  := LinksInfo.NetworkAddress.Zone;
         Type2PPacket.DestNet   := LinksInfo.NetworkAddress.Net;
         Type2PPacket.DestNode  := LinksInfo.NetworkAddress.Node;
         Type2PPacket.DestPoint := LinksInfo.NetworkAddress.Point;
         GetNetAddress(LinksInfo.AkaToUse);
         Type2PPacket.QOrigZone := NetworkInfo.Net_Address.Zone;
         Type2PPacket.OrigZone  := NetworkInfo.Net_Address.Zone;
         Type2PPacket.OrigNet   := NetworkInfo.Net_Address.Net;
         Type2PPacket.OrigNode  := NetworkInfo.Net_Address.Node;
         Type2PPacket.OrigPoint := NetworkInfo.Net_Address.Point;
         ASSIGN(FFile,TempOutbound+'\'+System_Crc(LinksInfo.NetworkAddress)+'.OUT');
         REWRITE(FFile,1);
         BLOCKWRITE(FFile,Type2PPacket,SizeOf(Type2PPacket));
         CLOSE(FFile);
       END;
     UNTIL BytesRead=0;
     FLinksInfo.CloseFile;
END;


PROCEDURE KillZeroNodes;
VAR  DirInfo : SearchRec;
     Work    : Word;
     FFile   : File;
BEGIN
     Work := 0;
     FindFirst(TempOutbound+'\*.OUT',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
       IF DirInfo.Size=58 THEN
       BEGIN
         {Kill Those That Have No Messages}
         _EraseFile(TempOutbound+'\'+DirInfo.Name);
       END
       ELSE
       BEGIN
         {Cap Off Those That Need It}
         ASSIGN(FFile,TempOutbound+'\'+DirInfo.Name);
         RESET(FFile,1);
         SEEK(FFile,FileSize(FFile));
         BLOCKWRITE(FFile,Work,SizeOf(Work));
         CLOSE(FFile);
       END;
       FindNext(DirInfo);
     END;
END;


PROCEDURE ForceMailerRescan;
VAR  FFile : File;
BEGIN
     _CreatePath(Mailer.Semaphores);
     ASSIGN(FFile,Mailer.Semaphores+'RESCAN.NOW');
     REWRITE(FFile);
     CLOSE(FFile);
END;


PROCEDURE ShowLastTossStats;
VAR  Temp  : String;
     KbSec : Longint;
     Kb    : Longint;
BEGIN
     Kb := Round(NumBytes/1024);
     IF Kb=0 THEN Kb := 1;
     IF Elapsed=0 THEN KbSec := 0
                  ELSE KBSec := Round(Kb/Elapsed);
     IF ((KbSec=0) AND (Kb<>0)) THEN KbSec := Kb;
     ClrScr;

     Temp :=  'Bundles: '+_PadRight(_String(NumBundles),10)+
             'Echomail: '+_PadRight(_String(NumEchoMails),10)+
             ' Seconds: '+_String(Elapsed);
     FastWrite(Temp,7,2,7); bsWriteLog(Temp,False);

     Temp :=  'Packets: '+_PadRight(_String(NumPackets),10)+
             ' Netmail: '+_PadRight(_String(NumNetmails),10)+
             'Msgs/Sec: '+_String(MsgsPerSecond);
     FastWrite(Temp,8,2,7); bsWriteLog(Temp,False);

     Temp :=  '     Kb: '+_PadRight(_String(Kb),10)+
             'Exported: '+_PadRight(_String(NumExported),10)+
             '  Kb/Sec: '+_String(KbSec);
     FastWrite(Temp,9,2,7); bsWriteLog(Temp,False);

     Temp :=  '  Dupes: '+_PadRight(_String(NumDupes),10)+
             ' Areafix: '+_String(RunningAFix);
     FastWrite(Temp,10,2,7); bsWriteLog(Temp,False);

     FastWrite('컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�',11,1,8);
     FastWrite('All done!',12,1,7);
     Window(1,1,80,25);
     GOTOXY(1,13);
END;


PROCEDURE ProcessAddedAreas;
VAR  GotIt    : Boolean;
     AreaType : Char;
     TFile    : Text;
     Temp     : String;
     FReports : File Of _Report_Record;
     Reports  : _Report_Record;
BEGIN
     IF _FileExists(TempOutbound+'\AUTOADD.TXT') THEN
     BEGIN
       ASSIGN(FReports,BaseDirectory+'\DATA\REPORTS.DAT');
       {$I-}RESET(FReports);{$I+}
       IF IOResult=0 THEN
       BEGIN
         REPEAT
           READ(FReports,Reports);
           IF Reports.ReportType=6 THEN
           BEGIN
             GotIt := False;
             ASSIGN(FTossMessageArea,BaseDirectory+'\DATA\MA000000.DAT');
             {$I-}RESET(FTossMessageArea);{$I+}
             IF IOResult=0 THEN
             BEGIN
               REPEAT
                 READ(FTossMessageArea,TossMessageArea);
                 IF TossMessageArea.AreaId=Reports.MsgAreaNumber THEN GotIt := True;
               UNTIL ((GotIt) OR (EOF(FTossMessageArea)));
               CLOSE(FTossMessageArea);
               IF GotIt THEN
               BEGIN
                 GetNetAddress(TossMessageArea.address);
                 CASE TossMessageArea.Base_Type OF
                 1:  AreaType := 'J';
                 2:  AreaType := 'S';
                 3:  AreaType := 'F';
                 END;
                 IF TossMessageArea.MaxMsgs=0 THEN TossMessageArea.MaxMsgs := 1000;
                 IF OpenOrCreateMsgArea(TossMsg,AreaType+TossMessageArea.Dos_Name,TossMessageArea.MaxMsgs) THEN
                 BEGIN
                   TossMsg^.StartNewMsg;
                   CASE TossMessageArea.Area_Type OF
                   1..3:   BEGIN
                                TossMsg^.SetMailType(mmtNormal);
                           END;
                   20..22: BEGIN
                                TossMsg^.SetMailType(mmtNetMail);
                                TossMsg^.SetEcho(True);
                           END;
                   10..12: BEGIN
                                TossMsg^.SetMailType(mmtEchoMail);
                                TossMsg^.SetEcho(True);
                           END;
                   END;
                   TossMsg^.SetOrig(NetWorkInfo.net_address);
                   TossMsg^.SetDest(NetWorkInfo.net_address);
                   TossMsg^.SetFrom(Reports.MsgFrom);
                   TossMsg^.SetTo(Reports.MsgTo);
                   TossMsg^.SetSubj(Reports.MsgSubject);
                   TossMsg^.SetDate(DateStr(GetDosDate));
                   TossMsg^.SetTime(TimeStr(GetDosDate));
                   TossMsg^.SetLocal(True);
                   CASE TossMessageArea.Area_Type OF
                   2,21,11: TossMsg^.SetPriv(True);
                   ELSE     TossMsg^.SetPriv(False);
                   END;
                   TossMsg^.DoStringLn(GetMsgId(NetWorkInfo.net_address));
                   TossMsg^.DoStringLn(CHR(1)+'PID: '+OurAppName);
                   TossMsg^.DoStringLn('');
                   TossMsg^.DoStringLn(_GetPrettyDate+'; '+_GetPrettyTime);
                   TossMsg^.DoStringLn('');
                   TossMsg^.DoStringLn('The following areas were auto-created by GSEcho:');
                   TossMsg^.DoStringLn(_Replicate('�',75));
                   ASSIGN(TFile,TempOutbound+'\AUTOADD.TXT');
                   RESET(TFile);
                   REPEAT
                     READLN(TFile,Temp);
                     TossMsg^.DoStringLn(Temp);
                   UNTIL EOF(TFile);
                   CLOSE(TFile);
                   TossMsg^.DoStringLn('');
                   TossMsg^.DoStringLn('--- '+OurAppName);
                   TossMsg^.DoStringLn(' * Origin: '+GetNetOrigin(TossMessageArea.origin)+
                                       ' ('+GetNetAddress(TossMessageArea.address)+')');
                   TossMsg^.WriteMsg;
                   CloseMsgArea(TossMsg);
                 END;
               END;
             END;
           END;
         UNTIL EOF(FReports);
         CLOSE(FReports);
       END;
       _EraseFile(TempOutbound+'\AUTOADD.TXT');
     END;
END;


END.
