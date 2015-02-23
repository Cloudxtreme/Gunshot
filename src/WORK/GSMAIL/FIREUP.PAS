{$I DEFINES.INC}
UNIT FireUp;


INTERFACE


PROCEDURE StartUp;
PROCEDURE ShutDown;
PROCEDURE LoadVars;


IMPLEMENTATION


USES Globals,Crt,Comm,ApFax12,BsMulti,ApCom,ApAbsFax,DrawScrn,Dos,
     ApTimer,FastW1,Info,BsLog,Scan,Sema,Misc,FMode,BsCom,Saver,
     BusyFile,BsAkas,BsString,BsFile,BsKeys,BsExec,BsVideo,Version,
     KeyCheck;


PROCEDURE get_params;
VAR  loop         : word;
     parameters   : array[1..10] of string[10];
     param        : char;
     code         : integer;
     Temp2        : String;
     ParamFile    : Text;
     Temp3        : String;
     Bingo        : Boolean;
     Work         : Word;
BEGIN
     SimNode    := 0;
     CurrentAka := 1;
     FOR loop := 1 TO paramcount DO
     BEGIN
          Temp2 := _UpperCase(ParamStr(Loop));
          IF _Mid(Temp2,1,2)='-N' THEN
          BEGIN
               Delete(Temp2,1,2);
               IF (Temp2[1] IN ['0'..'9']) THEN SimNode := _Numeric(Temp2);
          END
          ELSE IF _Mid(Temp2,1,4)='-AKA' THEN
          BEGIN
               Delete(Temp2,1,4);
               Work := _Numeric(Temp2);
               IF ((Work>0) AND (Work<20)) THEN CurrentAka := Work;
          END;
     END;
     IF SimNode=0 THEN
     BEGIN
          ClrScr;
          WRITELN('Invalid startup parameter.');
          WRITELN;
          WRITELN(' USAGE:  GSMAIL -Nxxx     (xxx-node number)');
          WRITELN;
          Halt(1);
     END;
END;


PROCEDURE StartUp;
CONST FaxClasses : Array[1..3] Of String[10] = ('Class 1','Class 2','Class 2.0');
VAR  Temp1    : String;
     Temp2    : String;
     Temp3    : String;
     Temp4    : String;
     DriveLtr : Byte;
BEGIN
     FileMode    := SetFileMode;
     DataChanged := True;
     New(MailQueue);

     Gunshot_Directory := _UpperCase(_GetFilePath(ParamStr(0)));
     IF Gunshot_Directory[Length(Gunshot_Directory)]='\' THEN DEC(Gunshot_Directory[0]);
     ChDir(Gunshot_Directory);

     get_params;
     LoadVars;
     CheckRegistered(MailerInfo.Outpkts,'GSMail');
     IF NOT(IsItRegistered) THEN
     BEGIN
          FNodeIndx.Done;
          FNodeList.Done;
          FUserList.Done;
          Dispose(MailQueue);
          Halt(1);
     END;
     bsSetLog(OurAppName,'',SimNode);

     _ClearOurBusyFiles;
     _EraseFile(MailerInfo.Semaphores+'RESET.'+_String(SimNode));
     ClearCIDSemaphore;

     CASE Mailer2Info.UseVideoLines OF
     0:   NumLines := 25;
     1:   NumLines := 28;
     2:   NumLines := 30;
     3:   NumLines := 50;
     END;

     FillChar(LastUserOnline,SizeOf(LastUserOnline),0);
     IF _FileExists(Gunshot_Directory+'\DATA\LAST'+_String(SimNode)+'.DAT') THEN
     BEGIN
          ASSIGN(FLastUserOnline,Gunshot_Directory+'\DATA\LAST'+_String(SimNode)+'.DAT');
          RESET(FLastUserOnline);
          READ(FLastUserOnline,LastUserOnline);
          CLOSE(FLastUserOnline);
     END;

     CASE NodeInfo.ComDevice OF
     1:   DeviceName := 'UART';
     2:   DeviceName := bsGetFossilName(NodeInfo.ComPort-1);
     3:   DeviceName := 'DigiBoard';
     4:   DeviceName := 'BIOS (Int$14)';
     5:   DeviceName := 'LAN (Int$14)';
     6:   DeviceName := 'OS/2 VDM';
     END;
     check_it := bsOpenPort(NodeInfo.ComPort,NodeInfo.ComDevice,NodeInfo.BaudRate,
                            16384,False,NodeInfo.PortAddr,NodeInfo.IRQ,NodeInfo.Fifos,
                            NodeInfo.FlowControl,NodeInfo.ptBufferGetChar,
                            NodeInfo.ptHandleFossilBug,NodeInfo.ptTrueOutBuffFree,
                            NodeInfo.ptPutCharWait,NodeInfo.ptReadWriteWait,
                            NodeInfo.ptClearFlow);
     IF NOT(Check_It) THEN
     BEGIN
          ClrScr;
          TextColor(15);
          WRITELN('Unable to initialize port!');
          WRITELN('Please check your com port');
          WRITELN('settings....');
          WRITELN;
          WRITELN('GSMail exiting.....');
          WRITELN;
          TextColor(7);
          Halt(1);
     END;
     bsOnHook(NodeInfo.OnHook);
     DrawTheScreen;
     FastWrite('#'+_String(SimNode),1,8,GunshotColours.GSMailStatusHighlight);
     ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     FastWrite(AddressToString(NetWork.Net_Address),2,8,GunshotColours.GSMailStatusHighlight);
     FastWrite(LastUserOnline.Name,1,34,GunshotColours.GSMailStatusHighlight);
     FastWrite(LastUserOnline.TimeOn,2,34,GunshotColours.GSMailStatusHighlight);
     FastWrite(LastUserOnline.TimeOff,3,34,GunshotColours.GSMailStatusHighlight);
     LastCalls;
     SystemInformation(True);
     {Operating System}
     Temp1 := 'OS/MULTI þ '+_GetOperatingSystem;
     Temp2 := 'DEVICE   þ '+DeviceName;
     Temp3 := 'PORT     þ COM'+_String(NodeInfo.ComPort)+' [';
     Temp3 := Temp3+_String(bsReturnRate(NodeInfo.BaudRate,NodeInfo.ComDevice))+' bps]';
     StatusWindow(Temp1);
     StatusWindow(Temp2);
     StatusWindow(Temp3);
     bsWriteLog(Temp1,False);
     bsWriteLog(Temp2,False);
     bsWriteLog(Temp3,False);
     IF MailerInfo.HandleFaxes THEN
     BEGIN
       Temp4 := 'FAX SEND þ '+FaxClasses[FaxCodes.FaxSendClass];
       StatusWindow(Temp4);
       bsWriteLog(Temp4,False);
       Temp4 := 'FAX RECV þ '+FaxClasses[FaxCodes.FaxRecvClass];
       StatusWindow(Temp4);
       bsWriteLog(Temp4,False);
     END;
     IF MailerInfo.Inbound[2]=':'
        THEN DriveLtr := Ord(UpCase(MailerInfo.Inbound[1]))-64
        ELSE DriveLtr := Ord(UpCase(Gunshot_Directory[1]))-64;
     IF (DiskFree(DriveLtr)<5120000) THEN
     BEGIN
       StatusWindow('!WARNING!! Less than 5mb free on inbound drive!');
       bsWriteLog('WARNING!! Less than 5mb free on inbound drive!',False);
     END;
     IF NOT(MailerInfo.BBSOnly) THEN ScanNewMail;
     ScanNewFaxes;
     StatusWindow('Initializing Modem');
     _ShowCursor;
     InitializeModem;
     Finished     := False;
     HaltCode     := 0;
     CallingOut   := False;
     ReceivedMail := False;
     StatusWindow('Waiting for a call or event');
     WriteNodeFile('GSMail','Waiting For A Caller','');
     CfgRescanTime := _FileDate(MailerInfo.Semaphores+'CFGSCAN.NOW');
     MsgRescanTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
END;


PROCEDURE ShutDown;
VAR  DirInfo : SearchRec;
BEGIN
     FindFirst(Gunshot_Directory+'\TEMP\GSM'+_String(SimNode)+'.*',AnyFile-Directory-VolumeID,DirInfo);
     WHILE DosError=0 DO
     BEGIN
          _EraseFile(Gunshot_Directory+'\TEMP\'+DirInfo.Name);
          FindNext(DirInfo);
     END;
     _EraseFile(Gunshot_Directory+'\INTRNODE\TMPSEND.'+_String(SimNode));
     _EraseFile(Gunshot_Directory+'\INTRNODE\QUEUETMP.'+_String(SimNode));
     _Delay(1000);
     bsClosePort(True);
     SetOrigVideoMode;
     Dispose(MailQueue);
     FNodeIndx.Done;
     FNodeList.Done;
     FUserList.Done;
END;


PROCEDURE LoadVars;
BEGIN
     ASSIGN(FConfigSetup,Gunshot_Directory+'\DATA\GSCONFIG.DAT');
     RESET(FConfigSetup);
     READ(FConfigSetup,ConfigSetup);
     CLOSE(FConfigSetup);

     ASSIGN(FHiddenDial,Gunshot_Directory+'\DATA\HIDDEN.DAT');
     RESET(FHiddenDial);
     READ(FHiddenDial,HiddenDial);
     CLOSE(FHiddenDial);

     ASSIGN(FSystemInfo,Gunshot_Directory+'\DATA\SYSTEM.DAT');
     RESET(FSystemInfo);
     READ(FSystemInfo,SystemInfo);
     CLOSE(FSystemInfo);

     ASSIGN(FNodeInfo,Gunshot_Directory+'\DATA\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,SimNode-1);
     READ(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);

     ASSIGN(FExtCodes,Gunshot_Directory+'\DATA\EXTCODES.'+_String(SimNode));
     RESET(FExtCodes);
     READ(FExtCodes,ExtCodes);
     CLOSE(FExtCodes);

     ASSIGN(FFaxCodes,Gunshot_Directory+'\DATA\FAXCODES.'+_String(SimNode));
     RESET(FFaxCodes);
     READ(FFaxCodes,FaxCodes);
     CLOSE(FFaxCodes);

     ASSIGN(FGunshotColours,Gunshot_Directory+'\DATA\GSSCHEME.DAT');
     RESET(FGunshotColours);
     READ(FGunshotColours,GunshotColours);
     CLOSE(FGunshotColours);
     FillChar(Progress,SizeOf(Progress),GunshotColours.GSMailProgressChar);
     Progress[0] := #40;

     ASSIGN(FFunctionKeys,Gunshot_Directory+'\DATA\FKEYS.DAT');
     RESET(FFunctionKeys);
     READ(FFunctionKeys,FunctionKeys);
     CLOSE(FFunctionKeys);

     ASSIGN(FMailerInfo,Gunshot_Directory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,SimNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);

     ASSIGN(FMailer2Info,Gunshot_Directory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,SimNode-1);
     READ(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);

     ASSIGN(FExternalApps,Gunshot_Directory+'\DATA\EXTERNAL.DAT');
     RESET(FExternalApps);
     READ(FExternalApps,ExternalApps);
     CLOSE(FExternalApps);

     NewTimerSecs(SaverAdvance,5);
     NewTimerSecs(SaverTimer,Mailer2Info.BlankerTimeout);
     SaverX    := 1;
     SaverY    := 1;
     SaverCurB := 0;
     MailOnly  := MailerInfo.MailOnly;
     FreqsOk   := MailerInfo.AllowFreqs;

     CASE SystemInfo.SwapMethod OF
     1:   SwapMethod := USE_EMS or USE_XMS;
     2:   SwapMethod := USE_ALL;
     3:   SwapMethod := USE_FILE or CHECK_NET;
     END;

     _CreatePath(MailerInfo.Outpkts);
     _CreatePath(MailerInfo.Outpkts+'EXC\');
     _CreatePath(Mailer2Info.InSecureInbound);
     _CreatePath(MailerInfo.Semaphores);
     _CreatePath(MailerInfo.Netmail);
     _CreatePath(MailerInfo.Inbound);
     _CreatePath(MailerInfo.Outbound);
     _CreatePath(MailerInfo.Nodelist);
     _CreatePath(Gunshot_Directory+'\LOGS');
     _CreatePath(Gunshot_Directory+'\TEMP');
     _CreatePath(Gunshot_Directory+'\NODE'+_String(SimNode));

     FNodeIndx.Init(FBuffSize);
     FNodeList.Init(FBuffSize);
     FUserList.Init(FBuffSize);
END;


END.
