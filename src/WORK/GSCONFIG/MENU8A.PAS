{$I DEFINES.INC}
UNIT MENU8A;


INTERFACE


PROCEDURE DoNodeSelect;
PROCEDURE DoModemSetup;
PROCEDURE DoVideoEmulations;
PROCEDURE DoMailer;
PROCEDURE DoMailerFiles;
PROCEDURE DoSessionPassword;
PROCEDURE DoErrorLevels;
PROCEDURE DoSpecialInits;
PROCEDURE DoResultCodes;
PROCEDURE DoLocalConsole;
PROCEDURE DoCallerId;


IMPLEMENTATION


USES IntrFace,BsString,BsFile,Crt,Defaults,CnfgVars,Dispatch,Valid,BsMouse,Misc,Menu8B,BsAkas;


PROCEDURE DoNodeSelect;
VAR  Work : Word;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     DrawWindow(11,9,52,13,'CHANGE CURRENT NODE',True);
     AddObject(32,11,2,5,_String(CurrentNode),True);
     AddButton(42,11,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(13,11); WRITE('    Current Node');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Work := Numeric(Objects^[1].Stuff,WordInteger);
     IF ((Work>0) AND (Work<=255)) THEN CurrentNode := Work;
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE ImportFromModemFile;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
     TheOne    : Word;
BEGIN
     IF NOT(_FileExists(BaseDirectory+'\DATA\MODEMS.DAT')) THEN Exit;
     _SaveWindow(WorkDir+'\MODEMIMP.SCR');
     TheOne           := 0;
     PickListPerPage  := 16;
     PickItem         := 1;
     PickTop          := 1;
     PickListItems    := 0;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := False;
     UseDeleteButton  := False;
     UseInsertButton  := False;
     UseAddButton     := False;
     UseFileButton    := False;
     UseSelectButton  := True;
     PickList_A_Title := _PadRight(' Modem Make/Model',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     ASSIGN(FModems,BaseDirectory+'\DATA\MODEMS.DAT');
     REWRITE(FPickListFile);
     RESET(FModems);
     REPEAT
           READ(FModems,Modems);
           INC(PickListItems);
           PickListFile.A := Modems.ModemName;
           PickListFile.B := '';
           WRITE(FPickListFile,PickListFile);
     UNTIL EOF(FModems);
     CLOSE(FModems);
     CLOSE(FPickListFile);
     SetUpPickList('SET MODEM COMMAND STRINGS FROM DEFAULTS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           6:   IF (PickItem<>0) THEN
                BEGIN
                     OuttaHere       := True;
                     TheOne          := PickItem;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
     IF (TheOne<>0) THEN
     BEGIN
          DrawWindow(10,8,66,16,'WARNING!!',True);
          AddButton(48,14,' CANCEL ',True,1,46);
          AddButton(58,14,' OK ',True,1,24);
          DrawObjects;
          DrawButtons;
          _HideMouse;
          TextColor_BS(11);
          TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(15,10);  WRITE('Doing this will erase your current settings for');
          GotoXY(15,11);  WRITE('your init strings and errorlevel setup for this');
          GotoXY(15,12);  WRITE('node. Are you sure you wish to do this?');
          _ShowMouse;
          Action := DoObjects;
          ClearObjects;
          ClearButtons;
          LoadWindow(WorkDir+'\MODEMIMP.SCR');
          IF Action=2 THEN
          BEGIN
               CheckFile('MAILER.DAT');
               CheckFile('NODES.DAT');
               {LOAD THE DEFAULTS}
               ASSIGN(FModems,BaseDirectory+'\DATA\MODEMS.DAT');
               RESET(FModems);
               SEEK(FModems,TheOne-1);
               READ(FModems,Modems);
               CLOSE(FModems);
               {DO THE NODES.DAT FILE}
               ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
               RESET(FNodeInfo);
               SEEK(FNodeInfo,CurrentNode-1);
               READ(FNodeInfo,NodeInfo);
               NodeInfo.BaudRate      := Modems.BaudRate;
               NodeInfo.CommandDelay  := Modems.CommandDelay;
               NodeInfo.InitString[1] := Modems.Init1;
               NodeInfo.InitString[2] := Modems.Init2;
               NodeInfo.InitString[3] := Modems.Init3;
               NodeInfo.OnHook        := Modems.Hangup;
               NodeInfo.OffHook       := Modems.OffHook;
               NodeInfo.Answer        := Modems.Answer;
               NodeInfo.Dial          := Modems.DialString;
               SEEK(FNodeInfo,CurrentNode-1);
               WRITE(FNodeInfo,NodeInfo);
               CLOSE(FNodeInfo);
               {DO THE MAILER.DAT FILE}
               ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
               RESET(FMailerInfo);
               SEEK(FMailerInfo,CurrentNode-1);
               READ(FMailerInfo,MailerInfo);
               MailerInfo.Flags := 'CM,XA,'+Modems.CompCodes;
               SEEK(FMailerInfo,CurrentNode-1);
               WRITE(FMailerInfo,MailerInfo);
               CLOSE(FMailerInfo);
               {DO THE ERRLEVEL.DAT FILE}
               FillChar(ErrorLevelInfo,SizeOf(ErrorLevelInfo),0);
               ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
               REWRITE(FErrorLevelInfo);
               FOR Loop := 1 TO 30 DO
               BEGIN
                    IF (Modems.ConnectString[Loop]<>'') THEN
                    BEGIN
                         ErrorLevelInfo.ConnectMessage := Modems.ConnectString[Loop];
                         ErrorLevelInfo.ConnectSpeed   := Modems.ConnectSpeed[Loop];
                         ErrorLevelInfo.ErrorLevel     := 100;
                         ErrorLevelInfo.Immediate      := False;
                         ErrorLevelInfo.AllowHumans    := True;
                         WRITE(FErrorLevelInfo,ErrorLevelInfo);
                    END;
               END;
               CLOSE(FErrorLevelInfo);
          END;
     END
     ELSE LoadWindow(WorkDir+'\MODEMIMP.SCR');
END;


PROCEDURE DoModemSetup;
VAR  Stat : Word;
LABEL       AllOverAgain;

     PROCEDURE LoadBackIn;
     BEGIN
          NodeInfo.ComPort           := Numeric(Objects^[1].Stuff,ByteInteger);
          NodeInfo.PortAddr          := _UpperCase(Objects^[2].Stuff);
          NodeInfo.IRQ               := Numeric(Objects^[3].Stuff,ByteInteger);
          NodeInfo.ComDevice         := Toggle[1].Current;
          NodeInfo.BaudRate          := Toggle[2].Current;
          NodeInfo.FlowControl       := Toggle[3].Current-1;
          NodeInfo.Fifos             := Toggle[4].Current-1;
          NodeInfo.ptBufferGetChar   := ToBoolean(Objects^[8].Stuff);
          NodeInfo.ptHandleFossilBug := ToBoolean(Objects^[9].Stuff);
          NodeInfo.ptTrueOutBuffFree := ToBoolean(Objects^[10].Stuff);
          NodeInfo.ptPutCharWait     := ToBoolean(Objects^[11].Stuff);
          NodeInfo.ptReadWriteWait   := ToBoolean(Objects^[12].Stuff);
          NodeInfo.ptClearFlow       := ToBoolean(Objects^[13].Stuff);
          NodeInfo.CommandDelay      := Numeric(Objects^[14].Stuff,WordInteger);
          NodeInfo.InitString[1]     := Objects^[15].Stuff;
          NodeInfo.InitString[2]     := Objects^[16].Stuff;
          NodeInfo.InitString[3]     := Objects^[17].Stuff;
          NodeInfo.OnHook            := Objects^[18].Stuff;
          NodeInfo.OffHook           := Objects^[19].Stuff;
          NodeInfo.Answer            := Objects^[20].Stuff;
          NodeInfo.Dial              := Objects^[21].Stuff;
     END;

BEGIN
     CheckFile('NODES.DAT');
     AllOverAgain:
     ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,CurrentNode-1);
     READ(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);
     {Serial Device}
     Toggle[1].Flips   := 4;
     Toggle[1].Current := NodeInfo.ComDevice;
     Toggle[1].Flip[1] := 'UART';
     Toggle[1].Flip[2] := 'Fossil';
     Toggle[1].Flip[3] := 'DigiBoard';
     Toggle[1].Flip[4] := 'BIOS (Int$14)';
     Toggle[1].Flip[5] := 'LAN (Int$14)';
     Toggle[1].Flip[6] := 'OS/2 VDM';
     {True Baud Rate}
     Toggle[2].Flips    := 10;
     Toggle[2].Current  := NodeInfo.BaudRate;
     Toggle[2].Flip[1]  := '300';
     Toggle[2].Flip[2]  := '600';
     Toggle[2].Flip[3]  := '1200';
     Toggle[2].Flip[4]  := '2400';
     Toggle[2].Flip[5]  := '4800';
     Toggle[2].Flip[6]  := '9600';
     Toggle[2].Flip[7]  := '19200';
     Toggle[2].Flip[8]  := '38400';
     Toggle[2].Flip[9]  := '57600';
     Toggle[2].Flip[10] := '115200';
     {Flow Control}
     IF NodeInfo.FlowControl>3 THEN NodeInfo.FlowControl := 1;
     Toggle[3].Flips    := 4;
     Toggle[3].Current  := NodeInfo.FlowControl+1;
     Toggle[3].Flip[1]  := 'NONE';
     Toggle[3].Flip[2]  := 'CTS/RTS';
     Toggle[3].Flip[3]  := 'DTR/DSR';
     Toggle[3].Flip[4]  := 'XON/XOFF';
     {Fifos}
     IF NodeInfo.Fifos>4 THEN NodeInfo.Fifos := 4;
     Toggle[4].Flips    := 5;
     Toggle[4].Current  := NodeInfo.Fifos+1;
     Toggle[4].Flip[1]  := 'NONE';
     Toggle[4].Flip[2]  := '1';
     Toggle[4].Flip[3]  := '4';
     Toggle[4].Flip[4]  := '8';
     Toggle[4].Flip[5]  := '14';
     DrawWindow(2,2,75,23,'MODEM SETUP - NODE #'+_String(CurrentNode),True);
     AddObject(22,4,2,3,_String(NodeInfo.ComPort),True);
     AddObject(22,5,1,3,NodeInfo.PortAddr,True);
     AddObject(22,6,2,3,_String(NodeInfo.IRQ),True);
     AddObject(22,7,8,20,'1',True);
     AddObject(22,8,8,20,'2',True);
     AddObject(22,9,8,20,'3',True);
     AddObject(22,10,8,20,'4',True);
     AddObject(68,4,6,3,FromBoolean(NodeInfo.ptBufferGetChar),True);
     AddObject(68,5,6,3,FromBoolean(NodeInfo.ptHandleFossilBug),True);
     AddObject(68,6,6,3,FromBoolean(NodeInfo.ptTrueOutBuffFree),True);
     AddObject(68,7,6,3,FromBoolean(NodeInfo.ptPutCharWait),True);
     AddObject(68,8,6,3,FromBoolean(NodeInfo.ptReadWriteWait),True);
     AddObject(68,9,6,3,FromBoolean(NodeInfo.ptClearFlow),True);
     AddObject(22,12,2,5 ,_String(NodeInfo.CommandDelay),True);
     AddObject(22,13,1,40,NodeInfo.InitString[1],True);
     AddObject(22,14,1,40,NodeInfo.InitString[2],True);
     AddObject(22,15,1,40,NodeInfo.InitString[3],True);
     AddObject(22,16,1,16,NodeInfo.OnHook,True);
     AddObject(22,17,1,16,NodeInfo.OffHook,True);
     AddObject(22,18,1,16,NodeInfo.Answer,True);
     AddObject(22,19,1,16,NodeInfo.Dial,True);
     AddButton(55,21,' QUIT ',True,1,16);
     AddButton(63,21,' MODEMS ',True,1,50);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(4,4);  WRITE('     Serial Port');
     GotoXY(4,5);  WRITE(' ** Base Address');
     GotoXY(4,6);  WRITE('   ** IRQ Number');
     GotoXY(4,7);  WRITE('   Serial Device');
     GotoXY(4,8);  WRITE('     * Baud Rate');
     GotoXY(4,9);  WRITE('    Flow Control');
     GotoXY(4,10); WRITE('   Enabled Fifos');
     GotoXY(45,4); WRITE(' Use Buffered Receive');
     GotoXY(45,5); WRITE('FossilÄÂÄÄÄÄÄX00 Hack');
     GotoXY(45,6); WRITE('       ÃÄTrue OutBuff');
     GotoXY(45,7); WRITE('       ÀÄÄÄWait Sends');
     GotoXY(45,8); WRITE('DigiÄÂÄWait Send/Recv');
     GotoXY(45,9); WRITE('     ÀÄÄÄÄÄClear Flow');
     GotoXY(4,12); WRITE('   Command Delay');
     GotoXY(4,13); WRITE('Init StringsÄÂÄ1');
     GotoXY(4,14); WRITE('             ÃÄ2');
     GotoXY(4,15); WRITE('             ÀÄ3');
     GotoXY(4,16); WRITE('  On-Hook String');
     GotoXY(4,17); WRITE(' Off-Hook String');
     GotoXY(4,18); WRITE('   Answer String');
     GotoXY(4,19); WRITE('  Dialing String');
     TextColor_BS(14);
     GotoXY(5,21);  WRITE('** Leave blank for standard settings.');
     GotoXY(5,22);  WRITE(' * BIOS support is only up to 9600 BPS.');
     _ShowMouse;
     REPEAT
           Stat := DoObjects;
           IF Stat=2 THEN
           BEGIN
                ClearObjects;
                ClearButtons;
                LoadBackIn;
                ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
                RESET(FNodeInfo);
                SEEK(FNodeInfo,CurrentNode-1);
                WRITE(FNodeInfo,NodeInfo);
                CLOSE(FNodeInfo);
                ImportFromModemFile;
                GOTO AllOverAgain;
           END;
     UNTIL Stat=1;
     ClearObjects;
     ClearButtons;
     LoadBackIn;
     ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,CurrentNode-1);
     WRITE(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);
END;


PROCEDURE DoMailer;
BEGIN
     CheckFile('MAILER.DAT');
     CheckFile('MAILER2.DAT');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     READ(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
     DrawWindow(4,2,76,23,'MAILER SETUP - NODE #'+_String(CurrentNode),True);
     AddObject(30,4,1,40,MailerInfo.NodeName,True);
     AddObject(30,5,1,20,MailerInfo.Phone,True);
     AddObject(30,6,1,20,MailerInfo.Flags,True);
     AddObject(30,7,1,15,MailerInfo.BBSSoftware,True);
     AddObject(30,8,2,9,_String(MailerInfo.BaudRate),True);
     AddObject(34,10,6,3,FromBoolean(MailerInfo.HandleFaxes),True);
     AddObject(34,11,6,3,FromBoolean(Mailer2Info.UseZedZapTransfers),True);
     AddObject(34,12,6,3,FromBoolean(MailerInfo.MailOnly),True);
     AddObject(34,13,6,3,FromBoolean(MailerInfo.DelayFirst),True);
     AddObject(34,14,2,3,_String(MailerInfo.RetryDelay),True);
     AddObject(34,15,2,3,_String(Mailer2Info.CallsBeforeFail),True);
     AddObject(34,16,2,3,_String(MailerInfo.AnswerOnRing),True);
     AddObject(34,17,2,3,_String(MailerInfo.SecondsToBBS),True);
     AddObject(34,18,2,3,_String(MailerInfo.MailExit),True);
     AddObject(34,19,6,3,FromBoolean(MailerInfo.BBSOnly),True);
     AddObject(64,10,6,3,FromBoolean(MailerInfo.PresentAkas),True);
     AddObject(64,11,6,3,FromBoolean(MailerInfo.MatchZones),True);
     AddObject(64,12,6,3,FromBoolean(Mailer2Info.UnpackPackets),True);
     AddObject(64,13,6,3,FromBoolean(Mailer2Info.UnpackInSecurePkts),True);
     AddObject(64,14,6,3,FromBoolean(Mailer2Info.MailFromUnlistedSystems),True);
     AddObject(64,15,6,3,FromBoolean(Mailer2Info.AllowNodeToDial),True);
     AddObject(64,16,6,3,FromBoolean(MailerInfo.AllowFreqs),True);
     AddObject(64,17,2,9,_String(MailerInfo.FreqBaud),True);
     AddObject(64,18,6,3,FromBoolean(MailerInfo.EnableEMSI),True);
     AddObject(64,19,6,3,FromBoolean(MailerInfo.EnableYooHoo),True);
     AddButton(66,21,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(6,4);   WRITE('             Node Name');
     GotoXY(6,5);   WRITE('     Node Phone Number');
     GotoXY(6,6);   WRITE('        Nodelist Flags');
     GotoXY(6,7);   WRITE('     BBS Software Name');
     GotoXY(6,8);   WRITE('      Maximum Baudrate');
     GotoXY(6,10);  WRITE('  Have GSMail Handle Faxes');
     GotoXY(6,11);  WRITE('    Allow ZedZap Transfers');
     GotoXY(6,12);  WRITE('          Mail Only System');
     GotoXY(6,13);  WRITE('   Delay Before First Call');
     GotoXY(6,14);  WRITE('       Session Retry Delay');
     GotoXY(6,15);  WRITE('   Session Failure Retries');
     GotoXY(6,16);  WRITE('            Answer On Ring');
     GotoXY(6,17);  WRITE('        Seconds Before BBS');
     GotoXY(6,18);  WRITE(' Mail Received Error Level');
     GotoXY(6,19);  WRITE('        BBS Only (No Mail)');
     GotoXY(40,10); WRITE('      Present All AKAs');
     GotoXY(40,11); WRITE('   Match Remotes Zones');
     GotoXY(40,12); WRITE('   Unpack Inbound PKTs');
     GotoXY(40,13); WRITE('Unpack Non-Secure PKTs');
     GotoXY(40,14); WRITE(' Allow Unknown Systems');
     GotoXY(40,15); WRITE('    Allow Node To Dial');
     GotoXY(40,16); WRITE('   Allow File Requests');
     GotoXY(40,17); WRITE('    Min Baud For Freqs');
     GotoXY(40,18); WRITE('   Sessions ÄÂÄÄ  EMSI');
     GotoXY(40,19); WRITE('             ÀÄ YooHoo');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     MailerInfo.NodeName                 := Objects^[1].Stuff;
     MailerInfo.Phone                    := Objects^[2].Stuff;
     MailerInfo.Flags                    := Objects^[3].Stuff;
     MailerInfo.BBSSoftware              := Objects^[4].Stuff;
     MailerInfo.BaudRate                 := Numeric(Objects^[5].Stuff,LongInteger);
     MailerInfo.HandleFaxes              := ToBoolean(Objects^[6].Stuff);
     Mailer2Info.UseZedZapTransfers      := ToBoolean(Objects^[7].Stuff);
     MailerInfo.MailOnly                 := ToBoolean(Objects^[8].Stuff);
     MailerInfo.DelayFirst               := ToBoolean(Objects^[9].Stuff);
     MailerInfo.RetryDelay               := Numeric(Objects^[10].Stuff,ByteInteger);
     Mailer2Info.CallsBeforeFail         := Numeric(Objects^[11].Stuff,ByteInteger);
     MailerInfo.AnswerOnRing             := Numeric(Objects^[12].Stuff,ByteInteger);
     MailerInfo.SecondsToBBS             := Numeric(Objects^[13].Stuff,ByteInteger);
     MailerInfo.MailExit                 := Numeric(Objects^[14].Stuff,ByteInteger);
     MailerInfo.BBSOnly                  := ToBoolean(Objects^[15].Stuff);
     MailerInfo.PresentAkas              := ToBoolean(Objects^[16].Stuff);
     MailerInfo.MatchZones               := ToBoolean(Objects^[17].Stuff);
     Mailer2Info.UnpackPackets           := ToBoolean(Objects^[18].Stuff);
     Mailer2Info.UnpackInSecurePkts      := ToBoolean(Objects^[19].Stuff);
     Mailer2Info.MailFromUnlistedSystems := ToBoolean(Objects^[20].Stuff);
     Mailer2Info.AllowNodeToDial         := ToBoolean(Objects^[21].Stuff);
     MailerInfo.AllowFreqs               := ToBoolean(Objects^[22].Stuff);
     MailerInfo.FreqBaud                 := Numeric(Objects^[23].Stuff,LongInteger);
     MailerInfo.EnableEMSI               := ToBoolean(Objects^[24].Stuff);
     MailerInfo.EnableYooHoo             := ToBoolean(Objects^[25].Stuff);
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     WRITE(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     WRITE(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
END;


PROCEDURE DoMailerFiles;
BEGIN
     CheckFile('MAILER.DAT');
     CheckFile('MAILER2.DAT');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     READ(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     READ(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
     DrawWindow(7,3,70,22,'MAILER PATHS - NODE #'+_String(CurrentNode),True);
     AddObject(27,5,1,40,MailerInfo.Netmail,True);
     AddObject(27,6,1,40,MailerInfo.Outbound,True);
     AddObject(27,7,1,40,MailerInfo.Nodelist,True);
     AddObject(27,8,1,40,MailerInfo.Semaphores,True);
     AddObject(27,9,1,40,MailerInfo.Inbound,True);
     AddObject(27,10,1,40,Mailer2Info.InSecureInbound,True);
     AddObject(27,11,1,40,MailerInfo.OutPkts,True);
     AddObject(27,13,1,40,MailerInfo.Banner,True);
     AddObject(27,14,1,40,MailerInfo.NoMatch,True);
     AddObject(27,15,1,40,MailerInfo.AliasList,True);
     AddObject(27,16,1,40,MailerInfo.DirList,True);
     AddObject(27,17,1,40,MailerInfo.InEvent,True);
     AddButton(60,20,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(9,5);  WRITE('+    Netmail Dir');
     GotoXY(9,6);  WRITE('+   Outbound Dir');
     GotoXY(9,7);  WRITE('+   Nodelist Dir');
     GotoXY(9,8);  WRITE('+  Semaphore Dir');
     GotoXY(9,9);  WRITE('- Secure Inbound');
     GotoXY(9,10); WRITE('-     Non-Secure');
     GotoXY(9,11); WRITE('-  Temp Outbound');
     GotoXY(9,13); WRITE('?    Banner Text');
     GotoXY(9,14); WRITE('?  Bad Freq Text');
     GotoXY(9,15); WRITE('?     Alias List');
     GotoXY(9,16); WRITE('?       Dir List');
     GotoXY(9,17); WRITE('?  In-Event Text');
     TextColor(14);
     GotoXY(14,19); WRITE('+ Should be the same for each node');
     GotoXY(14,20); WRITE('- Should be different for each node');
     GotoXY(14,21); WRITE('? May be different or the same');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     MailerInfo.Netmail          := ValidateIt(Objects^[1].Stuff,'PATH');
     MailerInfo.Outbound         := ValidateIt(Objects^[2].Stuff,'PATH');
     MailerInfo.Nodelist         := ValidateIt(Objects^[3].Stuff,'PATH');
     MailerInfo.Semaphores       := ValidateIt(Objects^[4].Stuff,'PATH');
     MailerInfo.Inbound          := ValidateIt(Objects^[5].Stuff,'PATH');
     Mailer2Info.InSecureInbound := ValidateIt(Objects^[6].Stuff,'PATH');
     MailerInfo.OutPkts          := ValidateIt(Objects^[7].Stuff,'PATH');
     MailerInfo.Banner           := ValidateIt(Objects^[8].Stuff,'FILE');
     MailerInfo.NoMatch          := ValidateIt(Objects^[9].Stuff,'FILE');
     MailerInfo.AliasList        := ValidateIt(Objects^[10].Stuff,'FILE');
     MailerInfo.DirList          := ValidateIt(Objects^[11].Stuff,'FILE');
     MailerInfo.InEvent          := ValidateIt(Objects^[12].Stuff,'FILE');
     ASSIGN(FMailerInfo,BaseDirectory+'\DATA\MAILER.DAT');
     RESET(FMailerInfo);
     SEEK(FMailerInfo,CurrentNode-1);
     WRITE(FMailerInfo,MailerInfo);
     CLOSE(FMailerInfo);
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     WRITE(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
END;


PROCEDURE EditInits(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
     RESET(FInits);
     SEEK(FInits,Number-1);
     READ(FInits,Inits);
     CLOSE(FInits);
     DrawWindow(10,8,72,15,'EDIT GSMAIL PRE-DIAL INIT ENTRY',True);
     AddObject(28,10,1,20,AddressToString(Inits.CallAddress),True);
     AddObject(28,11,1,40,Inits.InitString,True);
     AddButton(62,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE(' Call Address');
     GotoXY(13,11); WRITE('  Init String');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     StringToAddress(Objects^[1].Stuff,Inits.CallAddress);
     Inits.InitString  := _UpperCase(Objects^[2].Stuff);
     ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
     RESET(FInits);
     SEEK(FInits,Number-1);
     WRITE(FInits,Inits);
     CLOSE(FInits);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteInits(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\INITS.'+_String(CurrentNode),SizeOf(Inits),Number);
END;


PROCEDURE AddInits;
BEGIN
     FillChar(Inits,SizeOf(Inits),0);
     ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
     {$I-}RESET(FInits);{$I+}
     IF (IOResult<>0) THEN REWRITE(FInits)
                      ELSE SEEK(FInits,FileSize(FInits));
     WRITE(FInits,Inits);
     CLOSE(FInits);
END;


PROCEDURE InsertInits(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Inits,SizeOf(Inits),0);
     IF _FileExists(BaseDirectory+'\DATA\INITS.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FInits2,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
          RENAME(FInits2,BaseDirectory+'\DATA\INITS.BAK');
          ASSIGN(FInits2,BaseDirectory+'\DATA\INITS.BAK');
          ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
          RESET(FInits2);
          REWRITE(FInits);
          Counting := 0;
          REPEAT
                READ(FInits2,Inits2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FInits,Inits);
                WRITE(FInits,Inits2);
          UNTIL EOF(FInits2);
          CLOSE(FInits);
          CLOSE(FInits2);
          ERASE(FInits2);
     END
     ELSE
     BEGIN
          ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
          REWRITE(FInits);
          WRITE(FInits,Inits);
          CLOSE(FInits);
     END;
END;


PROCEDURE DoSpecialInits;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
          RESET(FInits);
          REPEAT
                Read(FInits,Inits);
                PickListFile.A := _PadRight(AddressToString(Inits.CallAddress),22)+Inits.InitString;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FInits);
          CLOSE(FInits);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
     {$I-}RESET(FInits);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FInits);
          CLOSE(FInits);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Call Address          Init String',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('GSMAIL PRE-DIAL INIT STRINGS - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditInits(PickItem);
                     ASSIGN(FInits,BaseDirectory+'\DATA\INITS.'+_String(CurrentNode));
                     RESET(FInits);
                     PickListItems := FileSize(FInits);
                     CLOSE(FInits);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteInits(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddInits;
                          EditInits(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertInits(PickItem);
                          EditInits(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddInits;
                     EditInits(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditSessionPassword(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
     RESET(FSessionPassword);
     SEEK(FSessionPassword,Number-1);
     READ(FSessionPassword,SessionPassword);
     CLOSE(FSessionPassword);
     DrawWindow(9,8,53,19,'EDIT NETWORK ADDRESS',True);
     AddObject(30,10,1,20,AddressToString(SessionPassword.SystemAddress),True);
     AddObject(30,11,1,8,SessionPassword.SystemPW,True);
     AddObject(30,12,6,3,FromBoolean(SessionPassword.DoEMSI),True);
     AddObject(30,13,6,3,FromBoolean(SessionPassword.DoWaZOO),True);
     AddObject(30,14,6,3,FromBoolean(SessionPassword.DoZedZap),True);
     AddObject(30,15,6,3,FromBoolean(SessionPassword.PresentAllAkas),True);
     AddButton(43,17,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(12,10); WRITE('     Net Address');
     GotoXY(12,11); WRITE('Session Password');
     GotoXY(12,12); WRITE('   EMSI Sessions');
     GotoXY(12,13); WRITE('  WaZOO Sessions');
     GotoXY(12,14); WRITE('ZedZap Transfers');
     GotoXY(12,15); WRITE('Present All Akas');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     StringToAddress(Objects^[1].Stuff,SessionPassword.SystemAddress);
     SessionPassword.SystemPW       := _UpperCase(Objects^[2].Stuff);
     SessionPassword.DoEMSI         := ToBoolean(Objects^[3].Stuff);
     SessionPassword.DoWaZOO        := ToBoolean(Objects^[4].Stuff);
     SessionPassword.DoZedZap       := ToBoolean(Objects^[5].Stuff);
     SessionPassword.PresentAllAkas := ToBoolean(Objects^[6].Stuff);
     ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
     RESET(FSessionPassword);
     SEEK(FSessionPassword,Number-1);
     WRITE(FSessionPassword,SessionPassword);
     CLOSE(FSessionPassword);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteSessionPassword(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\PASSWORD.DAT',SizeOf(SessionPassword),Number);
END;


PROCEDURE AddSessionPassword;
BEGIN
     FillChar(SessionPassword,SizeOf(SessionPassword),0);
     SessionPassword.DoEMSI         := True;
     SessionPassword.DoWaZOO        := True;
     SessionPassword.DoZedZap       := True;
     SessionPassword.PresentAllAkas := True;
     ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
     {$I-}RESET(FSessionPassword);{$I+}
     IF (IOResult<>0) THEN REWRITE(FSessionPassword)
                      ELSE SEEK(FSessionPassword,FileSize(FSessionPassword));
     WRITE(FSessionPassword,SessionPassword);
     CLOSE(FSessionPassword);
END;


PROCEDURE InsertSessionPassword(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(SessionPassword,SizeOf(SessionPassword),0);
     SessionPassword.DoEMSI         := True;
     SessionPassword.DoWaZOO        := True;
     SessionPassword.DoZedZap       := True;
     SessionPassword.PresentAllAkas := True;
     IF _FileExists(BaseDirectory+'\DATA\PASSWORD.DAT') THEN
     BEGIN
          ASSIGN(FSessionPassword2,BaseDirectory+'\DATA\PASSWORD.DAT');
          RENAME(FSessionPassword2,BaseDirectory+'\DATA\PASSWORD.BAK');
          ASSIGN(FSessionPassword2,BaseDirectory+'\DATA\PASSWORD.BAK');
          ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
          RESET(FSessionPassword2);
          REWRITE(FSessionPassword);
          Counting := 0;
          REPEAT
                READ(FSessionPassword2,SessionPassword2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FSessionPassword,SessionPassword);
                WRITE(FSessionPassword,SessionPassword2);
          UNTIL EOF(FSessionPassword2);
          CLOSE(FSessionPassword);
          CLOSE(FSessionPassword2);
          ERASE(FSessionPassword2);
     END
     ELSE
     BEGIN
          ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
          REWRITE(FSessionPassword);
          WRITE(FSessionPassword,SessionPassword);
          CLOSE(FSessionPassword);
     END;
END;


PROCEDURE DoSessionPassword;
VAR  Loop      : Word;
     OuttaHere : Boolean;
     Action    : Word;
LABEL            OverAgain;

     PROCEDURE Reload;
     VAR  Temp : String;
     BEGIN
          ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
          RESET(FSessionPassword);
          REPEAT
                Read(FSessionPassword,SessionPassword);
                Temp := _PadRight(AddressToString(SessionPassword.SystemAddress),20);
                IF SessionPassword.DoEMSI THEN Temp := Temp+'Yes  '
                                          ELSE Temp := Temp+'No   ';
                IF SessionPassword.DoWazoo THEN Temp := Temp+'Yes   '
                                           ELSE Temp := Temp+'No    ';
                IF SessionPassword.DoZedZap THEN Temp := Temp+'Yes '
                                            ELSE Temp := Temp+'No  ';
                IF SessionPassword.PresentAllAkas THEN Temp := Temp+'Yes '
                                                  ELSE Temp := Temp+'No  ';
                PickListFile.A := Temp;
                PickListFile.B := SessionPassword.SystemPW;
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FSessionPassword);
          CLOSE(FSessionPassword);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
     {$I-}RESET(FSessionPassword);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FSessionPassword);
          CLOSE(FSessionPassword);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Network Address     EMSI WaZOO Zap Akas',41);
     PickList_B_Title := 'Password  ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('MAIL SESSION PASSWORDS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditSessionPassword(PickItem);
                     ASSIGN(FSessionPassword,BaseDirectory+'\DATA\PASSWORD.DAT');
                     RESET(FSessionPassword);
                     PickListItems := FileSize(FSessionPassword);
                     CLOSE(FSessionPassword);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteSessionPassword(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddSessionPassword;
                          EditSessionPassword(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertSessionPassword(PickItem);
                          EditSessionPassword(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddSessionPassword;
                     EditSessionPassword(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE EditErrorLevels(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
     RESET(FErrorLevelInfo);
     SEEK(FErrorLevelInfo,Number-1);
     READ(FErrorLevelInfo,ErrorLevelInfo);
     CLOSE(FErrorLevelInfo);
     DrawWindow(25,9,70,19,'EDIT CONNECTION MESSAGES',True);
     AddObject(50,11,1,16,ErrorLevelInfo.ConnectMessage,True);
     AddObject(50,12,2,9 ,_String(ErrorLevelInfo.ConnectSpeed),True);
     AddObject(50,13,2,3 ,_String(ErrorLevelInfo.ErrorLevel),True);
     AddObject(50,14,6,3 ,FromBoolean(ErrorLevelInfo.Immediate),True);
     AddObject(50,15,6,3 ,FromBoolean(ErrorLevelInfo.AllowHumans),True);
     AddButton(60,17,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(29,11); WRITE(' Connection Message');
     GotoXY(29,12); WRITE('      Connect Speed');
     GotoXY(29,13); WRITE('    Errorlevel Exit');
     GotoXY(29,14); WRITE('     Immediate Exit');
     GotoXY(29,15); WRITE('Allow Human Callers');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ErrorLevelInfo.ConnectMessage := _UpperCase(Objects^[1].Stuff);
     ErrorLevelInfo.ConnectSpeed   := Numeric(Objects^[2].Stuff,LongInteger);
     ErrorLevelInfo.ErrorLevel     := Numeric(Objects^[3].Stuff,ByteInteger);
     ErrorLevelInfo.Immediate      := ToBoolean(Objects^[4].Stuff);
     ErrorLevelInfo.AllowHumans    := ToBoolean(Objects^[5].Stuff);
     ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
     RESET(FErrorLevelInfo);
     SEEK(FErrorLevelInfo,Number-1);
     WRITE(FErrorLevelInfo,ErrorLevelInfo);
     CLOSE(FErrorLevelInfo);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteErrorLevels(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode),SizeOf(ErrorLevelInfo),Number);
END;


PROCEDURE AddErrorLevels;
BEGIN
     FillChar(ErrorLevelInfo,SizeOf(ErrorLevelInfo),0);
     ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
     {$I-}RESET(FErrorLevelInfo);{$I+}
     IF (IOResult<>0) THEN REWRITE(FErrorLevelInfo)
                      ELSE SEEK(FErrorLevelInfo,FileSize(FErrorLevelInfo));
     WRITE(FErrorLevelInfo,ErrorLevelInfo);
     CLOSE(FErrorLevelInfo);
END;


PROCEDURE InsertErrorLevels(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(ErrorLevelInfo,SizeOf(ErrorLevelInfo),0);
     IF _FileExists(BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode)) THEN
     BEGIN
          ASSIGN(FErrorLevelInfo2,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
          RENAME(FErrorLevelInfo2,BaseDirectory+'\DATA\ERRLEVEL.BAK');
          ASSIGN(FErrorLevelInfo2,BaseDirectory+'\DATA\ERRLEVEL.BAK');
          ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
          RESET(FErrorLevelInfo2);
          REWRITE(FErrorLevelInfo);
          Counting := 0;
          REPEAT
                READ(FErrorLevelInfo2,ErrorLevelInfo2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FErrorLevelInfo,ErrorLevelInfo);
                WRITE(FErrorLevelInfo,ErrorLevelInfo2);
          UNTIL EOF(FErrorLevelInfo2);
          CLOSE(FErrorLevelInfo);
          CLOSE(FErrorLevelInfo2);
          ERASE(FErrorLevelInfo2);
     END
     ELSE
     BEGIN
          ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
          REWRITE(FErrorLevelInfo);
          WRITE(FErrorLevelInfo,ErrorLevelInfo);
          CLOSE(FErrorLevelInfo);
     END;
END;


PROCEDURE DoErrorLevels;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     VAR  Temp : String;
     BEGIN
          ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
          RESET(FErrorLevelInfo);
          REPEAT
                Read(FErrorLevelInfo,ErrorLevelInfo);
                Temp := _PadRight(ErrorLevelInfo.ConnectMessage,20)+
                        _PadRight(_String(ErrorLevelInfo.ErrorLevel),5);
                IF ErrorLevelInfo.Immediate THEN Temp := Temp+'Yes  '
                                            ELSE Temp := Temp+'No   ';
                IF ErrorLevelInfo.AllowHumans THEN Temp := Temp+'Yes  '
                                              ELSE Temp := Temp+'No   ';
                PickListFile.A := Temp;
                PickListFile.B := _String(ErrorLevelInfo.ConnectSpeed);
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FErrorLevelInfo);
          CLOSE(FErrorLevelInfo);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     CheckFile('ERRLEVEL');
     ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
     {$I-}RESET(FErrorLevelInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FErrorLevelInfo);
          CLOSE(FErrorLevelInfo);
          PickItem := 1;
          PickTop  := 1;
     END;
     OuttaHere        := False;
     UseTwoColumn     := True;
     UseEditButton    := True;
     UseDeleteButton  := True;
     UseInsertButton  := True;
     UseAddButton     := True;
     UseFileButton    := False;
     UseSelectButton  := False;
     PickList_A_Title := _PadRight(' Connect Message     ELvl Imm  Hum',41);
     PickList_B_Title := 'BPS       ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('EDIT ERRORLEVEL EXITS - NODE #'+_String(CurrentNode));
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditErrorLevels(PickItem);
                     ASSIGN(FErrorLevelInfo,BaseDirectory+'\DATA\ERRLEVEL.'+_String(CurrentNode));
                     RESET(FErrorLevelInfo);
                     PickListItems := FileSize(FErrorLevelInfo);
                     CLOSE(FErrorLevelInfo);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>0 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteErrorLevels(PickItem);
                          IF PickItem=PickListItems THEN DEC(PickItem);
                          DEC(PickListItems);
                          IF PickTop>PickListItems THEN DEC(PickTop);
                          ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                          REWRITE(FPickListFile);
                          IF (PickListItems<>0) THEN Reload;
                          CLOSE(FPickListFile);
                          UpdatePickList;
                     END;
                END;
           3:   BEGIN {INSERT}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                          AddErrorLevels;
                          EditErrorLevels(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertErrorLevels(PickItem);
                          EditErrorLevels(PickItem);
                     END;
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           5:   BEGIN {ADD}
                     IF PickListItems=0 THEN
                     BEGIN
                          PickItem := 1;
                          PickTop  := 1;
                     END;
                     AddErrorLevels;
                     EditErrorLevels(PickListItems+1);
                     INC(PickListItems);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           45:  BEGIN {LEAVE THE PROGRAM}
                     OuttaHere       := True;
                     ProgramFinished := True;
                END;
           END;
     UNTIL OuttaHere;
     ERASE(FPickListFile);
END;


PROCEDURE DoResultCodes;
BEGIN
     CheckFile('EXTCODES');
     ASSIGN(FExtCodes,BaseDirectory+'\DATA\EXTCODES.'+_String(CurrentNode));
     RESET(FExtCodes);
     READ(FExtCodes,ExtCodes);
     CLOSE(FExtCodes);
     DrawWindow(3,5,73,22,'MODEM RESULT CODES - NODE #'+_String(CurrentNode),True);
     AddObject(22,7,1,16,ExtCodes.Busy,True);
     AddObject(22,8,1,16,ExtCodes.Error,True);
     AddObject(22,9,1,16,ExtCodes.Fax,True);
     AddObject(22,10,1,16,ExtCodes.NoAnswer,True);
     AddObject(22,11,1,16,ExtCodes.NoCarrier,True);
     AddObject(22,12,1,16,ExtCodes.NoDialTone,True);
     AddObject(22,13,1,16,ExtCodes.Ok,True);
     AddObject(22,14,1,16,ExtCodes.Ring,True);
     AddObject(22,15,1,16,ExtCodes.Ringing,True);
     AddObject(22,16,1,16,ExtCodes.Voice,True);
     AddObject(22,17,1,16,ExtCodes.CIDDate,True);
     AddObject(22,18,1,16,ExtCodes.CIDTime,True);
     AddObject(22,19,1,16,ExtCodes.CIDName,True);
     AddObject(22,20,1,16,ExtCodes.CIDNumber,True);
     AddObject(53,7,1,16,ExtCodes.UserDef1,True);
     AddObject(53,8,1,16,ExtCodes.UserDef2,True);
     AddObject(53,9,1,16,ExtCodes.UserDef3,True);
     AddObject(53,10,1,16,ExtCodes.UserDef4,True);
     AddObject(53,11,1,16,ExtCodes.UserDef5,True);
     AddObject(53,12,1,16,ExtCodes.UserDef6,True);
     AddObject(53,13,1,16,ExtCodes.UserDef7,True);
     AddObject(53,14,1,16,ExtCodes.UserDef8,True);
     AddObject(53,15,1,16,ExtCodes.UserDef9,True);
     AddObject(53,16,1,16,ExtCodes.UserDef10,True);
     AddButton(63,20,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(9,7);   WRITE('       Busy');
     GotoXY(9,8);   WRITE('      Error');
     GotoXY(9,9);   WRITE('        Fax');
     GotoXY(9,10);   WRITE('  No Answer');
     GotoXY(9,11);   WRITE(' No Carrier');
     GotoXY(9,12);   WRITE('No Dialtone');
     GotoXY(9,13);   WRITE('         Ok');
     GotoXY(9,14);  WRITE('       Ring');
     GotoXY(9,15);  WRITE('    Ringing');
     GotoXY(9,16);  WRITE('      Voice');
     GotoXY(9,17);  WRITE('CIDÂÄÄ Date');
     GotoXY(9,18);  WRITE('   ÃÄÄ Time');
     GotoXY(9,19);  WRITE('   ÃÄÄ Name');
     GotoXY(9,20);  WRITE('   À Number');
     GotoXY(41,7);  WRITE(' UserDef 1');
     GotoXY(41,8);  WRITE(' UserDef 2');
     GotoXY(41,9);  WRITE(' UserDef 3');
     GotoXY(41,10); WRITE(' UserDef 4');
     GotoXY(41,11); WRITE(' UserDef 5');
     GotoXY(41,12); WRITE(' UserDef 6');
     GotoXY(41,13); WRITE(' UserDef 7');
     GotoXY(41,14); WRITE(' UserDef 8');
     GotoXY(41,15); WRITE(' UserDef 9');
     GotoXY(41,16); WRITE('UserDef 10');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     ExtCodes.Busy                   := Objects^[1].Stuff;
     ExtCodes.Error                  := Objects^[2].Stuff;
     ExtCodes.Fax                    := Objects^[3].Stuff;
     ExtCodes.NoAnswer               := Objects^[4].Stuff;
     ExtCodes.NoCarrier              := Objects^[5].Stuff;
     ExtCodes.NoDialTone             := Objects^[6].Stuff;
     ExtCodes.Ok                     := Objects^[7].Stuff;
     ExtCodes.Ring                   := Objects^[8].Stuff;
     ExtCodes.Ringing                := Objects^[9].Stuff;
     ExtCodes.Voice                  := Objects^[10].Stuff;
     ExtCodes.CIDDate                := Objects^[11].Stuff;
     ExtCodes.CIDTime                := Objects^[12].Stuff;
     ExtCodes.CIDName                := Objects^[13].Stuff;
     ExtCodes.CIDNumber              := Objects^[14].Stuff;
     ExtCodes.UserDef1               := Objects^[15].Stuff;
     ExtCodes.UserDef2               := Objects^[16].Stuff;
     ExtCodes.UserDef3               := Objects^[17].Stuff;
     ExtCodes.UserDef4               := Objects^[18].Stuff;
     ExtCodes.UserDef5               := Objects^[19].Stuff;
     ExtCodes.UserDef6               := Objects^[20].Stuff;
     ExtCodes.UserDef7               := Objects^[21].Stuff;
     ExtCodes.UserDef8               := Objects^[22].Stuff;
     ExtCodes.UserDef9               := Objects^[23].Stuff;
     ExtCodes.UserDef10              := Objects^[24].Stuff;
     ASSIGN(FExtCodes,BaseDirectory+'\DATA\EXTCODES.'+_String(CurrentNode));
     REWRITE(FExtCodes);
     WRITE(FExtCodes,ExtCodes);
     CLOSE(FExtCodes);
END;


PROCEDURE DoLocalConsole;
BEGIN
     CheckFile('MAILER2.DAT');
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     READ(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
     Toggle[1].Flips   := 4;
     Toggle[1].Current := Mailer2Info.UseVideoLines+1;
     Toggle[1].Flip[1] := '25 LINES';
     Toggle[1].Flip[2] := '28 LINES';
     Toggle[1].Flip[3] := '30 LINES';
     Toggle[1].Flip[4] := '50 LINES';
     DrawWindow(16,5,70,19,'LOCAL CONSOLE SETTINGS - NODE #'+_String(CurrentNode),True);
     AddObject(46,7,8,20,'1',True);
     AddObject(46,8,6,3,FromBoolean(Mailer2Info.UseBlanker),True);
     AddObject(46,9,2,5,_String(Mailer2Info.BlankerTimeout),True);
     AddObject(46,10,6,3,FromBoolean(Mailer2Info.UseSound),True);
     AddObject(46,11,3,4,TimeStrng(Mailer2Info.SoundStart),True);
     AddObject(46,12,3,4,TimeStrng(Mailer2Info.SoundEnd),True);
     AddObject(46,13,6,3,FromBoolean(Mailer2Info.UseSpeakerToggle),True);
     AddObject(46,14,3,4,TimeStrng(Mailer2Info.SpeakerStart),True);
     AddObject(46,15,3,4,TimeStrng(Mailer2Info.SpeakerEnd),True);
     AddButton(60,17,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(20,7);  WRITE('Video Display Mode (VGA)');
     GotoXY(20,8);  WRITE('Screen Blank ÄÂÄÄ Enable');
     GotoXY(20,9);  WRITE('              ÀÄ Timeout');
     GotoXY(20,10); WRITE('System Sounds ÄÂÄ Enable');
     GotoXY(20,11); WRITE('               ÃÄÄ Start');
     GotoXY(20,12); WRITE('               ÀÄÄÄÄ End');
     GotoXY(20,13); WRITE('   Auto Modem ÄÂÄ Enable');
     GotoXY(20,14); WRITE('   Speaker     ÃÄÄ Start');
     GotoXY(20,15); WRITE('               ÀÄÄÄÄ End');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Mailer2Info.UseVideoLines    := Toggle[1].Current-1;
     Mailer2Info.UseBlanker       := ToBoolean(Objects^[2].Stuff);
     Mailer2Info.BlankerTimeout   := Numeric(Objects^[3].Stuff,WordInteger);
     Mailer2Info.UseSound         := ToBoolean(Objects^[4].Stuff);
     Mailer2Info.SoundStart       := ReturnTime(Objects^[5].Stuff);
     Mailer2Info.SoundEnd         := ReturnTime(Objects^[6].Stuff);
     Mailer2Info.UseSpeakerToggle := ToBoolean(Objects^[7].Stuff);
     Mailer2Info.SpeakerStart     := ReturnTime(Objects^[8].Stuff);
     Mailer2Info.SpeakerEnd       := ReturnTime(Objects^[9].Stuff);
     ASSIGN(FMailer2Info,BaseDirectory+'\DATA\MAILER2.DAT');
     RESET(FMailer2Info);
     SEEK(FMailer2Info,CurrentNode-1);
     WRITE(FMailer2Info,Mailer2Info);
     CLOSE(FMailer2Info);
END;


PROCEDURE DoVideoEmulations;
VAR  Loop : Word;
BEGIN
     CheckFile('NODES.DAT');
     ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,CurrentNode-1);
     READ(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);
     DrawWindow(12,4,53,22,'MISCELLANEOUS OPTIONS - NODE #'+_String(CurrentNode),True);
     AddObject(40,6,6,3,_String(NodeInfo.TTYOk),True);
     AddObject(40,7,6,3,_String(NodeInfo.ANSIOk),True);
     AddObject(40,8,6,3,_String(NodeInfo.AutoANSILogin),True);
     AddObject(40,9,6,3,_String(NodeInfo.SVGAOk),True);
     AddObject(40,10,6,3,_String(NodeInfo.AutoSVGALogin),True);
     AddObject(40,11,6,3,_String(NodeInfo.RIPOk),True);
     AddObject(40,12,6,3,_String(NodeInfo.AutoRIPLogin),True);
     AddObject(40,14,6,3,_String(NodeInfo.AllowNewUsers),True);
     AddObject(40,15,2,5,_String(NodeInfo.AccessMinimum),True);
     AddObject(40,16,7,10,Tags(NodeInfo.Tags),True);
     AddObject(40,17,6,3 ,FromBoolean(NodeInfo.UseBlaster),True);
     AddObject(40,18,6,3 ,FromBoolean(NodeInfo.NoTimeout),True);
     AddButton(43,20,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(15,6);  WRITE('Video ModesÂÄÄÄÄÄÄÄ TTY');
     GotoXY(15,7);  WRITE('           ÃÄÂÄÄÄÄ ANSI');
     GotoXY(15,8);  WRITE('           ³ ÀÄÄÄÄ Auto');
     GotoXY(15,9);  WRITE('           ÃÄÂÄÄÄÄ SVGA');
     GotoXY(15,10); WRITE('           ³ ÀÄÄÄÄ Auto');
     GotoXY(15,11); WRITE('           ÀÄÂÄÄÄÄÄ RIP');
     GotoXY(15,12); WRITE('             ÀÄÄÄÄ Auto');
     GotoXY(15,14); WRITE('Allow New Users To Node');
     GotoXY(15,15); WRITE('   Minimum Access Level');
     GotoXY(15,16); WRITE('   Required Access Tags');
     GotoXY(15,17); WRITE('   Use SoundBlaster(TM)');
     GotoXY(15,18); WRITE('  Disable Local Timeout');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     NodeInfo.TTYOk         := Numeric(Objects^[1].Stuff,ByteInteger);
     NodeInfo.ANSIOk        := Numeric(Objects^[2].Stuff,ByteInteger);
     NodeInfo.AutoANSILogin := Numeric(Objects^[3].Stuff,ByteInteger);
     NodeInfo.SVGAOk        := Numeric(Objects^[4].Stuff,ByteInteger);
     NodeInfo.AutoSVGALogin := Numeric(Objects^[5].Stuff,ByteInteger);
     NodeInfo.RIPOk         := Numeric(Objects^[6].Stuff,ByteInteger);
     NodeInfo.AutoRIPLogin  := Numeric(Objects^[7].Stuff,ByteInteger);
     NodeInfo.AllowNewUsers := Numeric(Objects^[8].Stuff,ByteInteger);
     NodeInfo.AccessMinimum := Numeric(Objects^[9].Stuff,WordInteger);
     FOR Loop := 1 TO 10 DO
     BEGIN
          IF Objects^[10].Stuff[Loop]='1' THEN NodeInfo.Tags[Loop] := 1
                                          ELSE NodeInfo.Tags[Loop] := 0;
     END;
     NodeInfo.UseBlaster := ToBoolean(Objects^[11].Stuff);
     NodeInfo.NoTimeout  := ToBoolean(Objects^[12].Stuff);
     ASSIGN(FNodeInfo,BaseDirectory+'\DATA\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,CurrentNode-1);
     WRITE(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);
END;


PROCEDURE DoCallerId;
VAR  Action : Word;

     PROCEDURE ReLoad;
     BEGIN
          ClearObjects;
          ClearButtons;
          CallerId.UseCID              := ToBoolean(Objects^[1].Stuff);
          CallerId.AccessLevelForcing  := ToBoolean(Objects^[2].Stuff);
          CallerId.AccessLevelNoNumber := Numeric(Objects^[3].Stuff,WordInteger);
          CallerId.CBVOverRide         := ToBoolean(Objects^[4].Stuff);
          ASSIGN(FCallerId,BaseDirectory+'\DATA\CALLERID.DAT');
          REWRITE(FCallerId);
          WRITE(FCallerId,CallerId);
          CLOSE(FCallerId);
     END;

     PROCEDURE Redraw;
     BEGIN
          ASSIGN(FCallerId,BaseDirectory+'\DATA\CALLERID.DAT');
          RESET(FCallerId);
          READ(FCallerId,CallerId);
          CLOSE(FCallerId);
          DrawWindow(18,8,70,17,'CALLER ID CONFIGURATION',True);
          AddObject(46,10,6,3,FromBoolean(CallerId.UseCID),True);
          AddObject(46,11,6,3,FromBoolean(CallerId.AccessLevelForcing),True);
          AddObject(46,12,2,5,_String(CallerId.AccessLevelNoNumber),True);
          AddObject(46,13,6,3,FromBoolean(CallerId.CBVOverRide),True);
          AddButton(47,15,' QUIT ',True,1,16);
          AddButton(55,15,' LOCKED OUT ',True,1,38);
          DrawObjects;
          DrawButtons;
          _HideMouse;
          TextColor_BS(11);
          TextBackGround_BS(Colour.WindowBackGround);
          GotoXY(20,10); WRITE('    Use CallerID Support');
          GotoXY(20,11); WRITE('    Access Level Forcing');
          GotoXY(20,12); WRITE('  No Number Access Level');
          GotoXY(20,13); WRITE('        CID Override CBV');
          _ShowMouse;
     END;

BEGIN
     CheckFile('CALLERID.DAT');
     Redraw;
     REPEAT
           Action := DoObjects;
           IF Action=2 THEN
           BEGIN
                Reload;
                DoLockoutRecord;
                Redraw;
           END;
     UNTIL (Action=1);
     ReLoad;
END;


END.