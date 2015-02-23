{$I DEFINES.INC}
UNIT MENU2;


INTERFACE


PROCEDURE DoSiteInfo;
PROCEDURE DoNetWorkInfo;
PROCEDURE DoSystemMisc;
PROCEDURE DoCallTotals;
PROCEDURE DoDirectories;
PROCEDURE DoCallBack;
PROCEDURE DoTimeBank;
PROCEDURE DoByteBank;
PROCEDURE DoSysopFunctions;
PROCEDURE DoVerifierTranslations;
PROCEDURE DoNetOrigins;
PROCEDURE DoFunctionKeys;
PROCEDURE DoHiddenDialInfo;


IMPLEMENTATION


USES IntrFace,BsMouse,BsString,Crt,Defaults,CnfgVars,Valid,Misc,BsAkas,BsFile;


PROCEDURE DoHiddenDialInfo;
BEGIN
     CheckFile('HIDDEN.DAT');
     ASSIGN(FHiddenDial,BaseDirectory+'\DATA\HIDDEN.DAT');
     RESET(FHiddenDial);
     READ(FHiddenDial,HiddenDial);
     CLOSE(FHiddenDial);
     DrawWindow(20,5,59,20,'HIDDEN DIAL STRINGS',True);
     AddObject(25,7,1,30,HiddenDial.TheString[1],True);
     AddObject(25,8,1,30,HiddenDial.TheString[2],True);
     AddObject(25,9,1,30,HiddenDial.TheString[3],True);
     AddObject(25,10,1,30,HiddenDial.TheString[4],True);
     AddObject(25,11,1,30,HiddenDial.TheString[5],True);
     AddObject(25,12,1,30,HiddenDial.TheString[6],True);
     AddObject(25,13,1,30,HiddenDial.TheString[7],True);
     AddObject(25,14,1,30,HiddenDial.TheString[8],True);
     AddObject(25,15,1,30,HiddenDial.TheString[9],True);
     AddObject(25,16,1,30,HiddenDial.TheString[10],True);
     AddButton(49,18,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     DoObjects;
     ClearObjects;
     ClearButtons;
     HiddenDial.TheString[1]  := Objects^[1].Stuff;
     HiddenDial.TheString[2]  := Objects^[2].Stuff;
     HiddenDial.TheString[3]  := Objects^[3].Stuff;
     HiddenDial.TheString[4]  := Objects^[4].Stuff;
     HiddenDial.TheString[5]  := Objects^[5].Stuff;
     HiddenDial.TheString[6]  := Objects^[6].Stuff;
     HiddenDial.TheString[7]  := Objects^[7].Stuff;
     HiddenDial.TheString[8]  := Objects^[8].Stuff;
     HiddenDial.TheString[9]  := Objects^[9].Stuff;
     HiddenDial.TheString[10] := Objects^[10].Stuff;
     ASSIGN(FHiddenDial,BaseDirectory+'\DATA\HIDDEN.DAT');
     REWRITE(FHiddenDial);
     WRITE(FHiddenDial,HiddenDial);
     CLOSE(FHiddenDial);
END;


PROCEDURE DoSiteInfo;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(12,8,68,18,'SITE INFO',True);
     AddObject(35,10,1,30,System_Info.bbs_name,True);
     AddObject(35,11,1,30,System_Info.location,True);
     AddObject(35,13,1,30,System_Info.sysop,True);
     AddObject(35,14,1,30,System_Info.alias,True);
     AddButton(58,16,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(16,10); WRITE('         BBS Name');
     GotoXY(16,11); WRITE('     BBS Location');
     GotoXY(16,13); WRITE(' Sysops REAL Name');
     GotoXY(16,14); WRITE('Sysops ALIAS Name');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.bbs_name := Objects^[1].Stuff;
     System_Info.location := Objects^[2].Stuff;
     System_Info.sysop    := Objects^[3].Stuff;
     System_Info.alias    := Objects^[4].Stuff;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


PROCEDURE DoSystemMisc;
VAR  Work   : Word;
     Temp   : String;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     IF (System_Info.DateFormat>3) THEN System_Info.DateFormat := 3;
     IF Ord(System_Info.UTCSetting[0])>3 THEN System_Info.UTCSetting := '';
     Toggle[1].Flips   := 3;
     Toggle[1].Current := System_Info.SwapMethod;
     Toggle[1].Flip[1] := 'EMS/XMS';
     Toggle[1].Flip[2] := 'EMS/XMS/DISK';
     Toggle[1].Flip[3] := 'DISK';
     Toggle[2].Flips   := 3;
     Toggle[2].Current := System_Info.DateFormat;
     Toggle[2].Flip[1] := 'MM/DD/YYYY';
     Toggle[2].Flip[2] := 'DD/MM/YYYY';
     Toggle[2].Flip[3] := 'YYYY/MM/DD';
     DrawWindow(9,4,63,21,'MISC SYSTEM SETTINGS',True);
     AddObject(40,6,2,3,_String(Trunc(System_Info.Sys_Idle/60)),True);
     AddObject(40,7,3,4,TimeStrng(System_Info.Page_Start),True);
     AddObject(40,8,3,4,TimeStrng(System_Info.Page_End),True);
     AddObject(40,9,2,3,_String(System_Info.Page_Max),True);
     AddObject(40,10,2,3,_String(System_Info.ANSIExit),True);
     AddObject(40,11,2,3,_String(System_Info.EchoExit),True);
     AddObject(40,12,2,3,_String(System_Info.LocalExit),True);
     AddObject(40,13,6,3,_String(System_Info.Suspend_FList),True);
     AddObject(40,14,6,3,_String(System_Info.MessageDebug),True);
     AddObject(40,15,8,20,'1',True);
     AddObject(40,16,8,20,'2',True);
     AddObject(40,17,1,3,System_Info.UTCSetting,True);
     AddButton(53,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(12,6);   WRITE('    System Idle (minutes):');
     GotoXY(12,7);   WRITE('   Start Page Time (24hr):');
     GotoXY(12,8);   WRITE('     End Page Time (24hr):');
     GotoXY(12,9);   WRITE(' Max Pages In One Session:');
     GotoXY(12,10);  WRITE(' NON-SVGA Errorlevel Exit:');
     GotoXY(12,11);  WRITE(' Mail Exit컫컴컴횱cho/Net:');
     GotoXY(12,12);  WRITE('           읕컴Local Only:');
     GotoXY(12,13);  WRITE('Time Suspend QWK/FileList:');
     GotoXY(12,14);  WRITE('Message Debug Information:');
     GotoXY(12,15);  WRITE('          Swapping Method:');
     GotoXY(12,16);  WRITE('       System Date Format:');
     GotoXY(12,17);  WRITE('        UTC Setting (+/-):');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.Sys_Idle      := Numeric(Objects^[1].Stuff,LongInteger)*60;
     System_Info.Page_Start    := ReturnTime(Objects^[2].Stuff);
     System_Info.Page_End      := ReturnTime(Objects^[3].Stuff);
     System_Info.Page_Max      := Numeric(Objects^[4].Stuff,ByteInteger);
     System_Info.ANSIExit      := Numeric(Objects^[5].Stuff,ByteInteger);
     System_Info.EchoExit      := Numeric(Objects^[6].Stuff,ByteInteger);
     System_Info.LocalExit     := Numeric(Objects^[7].Stuff,ByteInteger);
     System_Info.Suspend_FList := Numeric(Objects^[8].Stuff,ByteInteger);
     System_Info.MessageDebug  := Numeric(Objects^[9].Stuff,ByteInteger);
     System_Info.SwapMethod    := Toggle[1].Current;
     System_Info.DateFormat    := Toggle[2].Current;
     System_Info.UTCSetting    := Objects^[12].Stuff;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


PROCEDURE DoCallTotals;
BEGIN
     CheckFile('SYSCALLS.DAT');
     ASSIGN(FTotals,BaseDirectory+'\DATA\SYSCALLS.DAT');
     RESET(FTotals);
     READ(FTotals,Totals);
     CLOSE(FTotals);
     DrawWindow(20,8,60,17,'CALL TOTALS',True);
     AddObject(47,12,2,10,_String(Totals.Total_Calls),True);
     AddObject(47,13,2,10,_String(Totals.Today_Calls),True);
     AddButton(50,15,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(14);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(25,10); WRITE('Last Active Call Date: ');
                    WRITE(UnpackedDate2(Totals.Date_Today));
     TextColor_BS(11);
     GotoXY(22,12); WRITE('    Total System Calls:');
     GotoXY(22,13); WRITE('Calls Last Active Date:');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Totals.Total_Calls := Numeric(Objects^[1].Stuff,LongInteger);
     Totals.Today_Calls := Numeric(Objects^[2].Stuff,LongInteger);
     ASSIGN(FTotals,BaseDirectory+'\DATA\SYSCALLS.DAT');
     REWRITE(FTotals);
     WRITE(FTotals,Totals);
     CLOSE(FTotals);
END;


PROCEDURE DoDirectories;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     {$I-}READ(FSystem_Info,System_Info);{$I+}
     IF IOResult=0 THEN;
     CLOSE(FSystem_Info);
     DrawWindow(10,8,70,17,'SYSTEM DIRECTORIES',True);
     AddObject(28,10,1,40,System_Info.FileAttach,True);
     AddObject(28,11,1,40,System_Info.BadQwk,True);
     AddObject(28,12,1,40,System_Info.BadFiles,True);
     AddObject(28,13,1,1,System_Info.NodeDrive,True);
     AddButton(60,15,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('File Attaches');
     GotoXY(13,11); WRITE(' Bad QWK Path');
     GotoXY(13,12); WRITE('Bad File Path');
     GotoXY(13,13); WRITE('   Node Drive');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.FileAttach := ValidateIt(Objects^[1].Stuff,'PATH');
     System_Info.BadQwk     := ValidateIt(Objects^[2].Stuff,'PATH');
     System_Info.BadFiles   := ValidateIt(Objects^[3].Stuff,'PATH');
     System_Info.NodeDrive  := Objects^[4].Stuff;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


PROCEDURE DoCallBack;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('CALLBACK.DAT');
     ASSIGN(FCBVSetup,BaseDirectory+'\DATA\CALLBACK.DAT');
     RESET(FCBVSetup);
     READ(FCBVSetup,CBVSetup^);
     CLOSE(FCBVSetup);
     DrawWindow(18,5,57,21,'CALL BACK VERIFIER SETTINGS',True);
     AddObject(47,7,6,3 ,_String(CBVSetup^.ForceUse),True);
     AddObject(47,8,6,3 ,_String(CBVSetup^.VerifyLD),True);
     AddObject(47,9,6,3 ,_String(CBVSetup^.LDPass),True);
     AddObject(47,11,3,4,TimeStrng(CBVSetup^.CBVStart),True);
     AddObject(47,12,3,4,TimeStrng(CBVSetup^.CBVEnd),True);
     AddObject(47,14,2,5 ,_String(CBVSetup^.VAccess),True);
     AddObject(47,16,6,3 ,_String(CBVSetup^.UserToLogBackIn),True);
     AddObject(47,17,2,2 ,_String(CBVSetup^.CallRetries),True);
     AddButton(47,19,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(22,7);  WRITE('    Force Using The CBV');
     GotoXY(22,8);  WRITE('   Verify Long Distance');
     GotoXY(22,9);  WRITE('Pass through LD Callers');
     GotoXY(22,11); WRITE('Verification Start Time');
     GotoXY(22,12); WRITE('  Verification End Time');
     GotoXY(22,14); WRITE('  Verified Access Level');
     GotoXY(22,16); WRITE('     User To Call After');
     GotoXY(22,17); WRITE('Number Of Call Attempts');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     CBVSetup^.ForceUse        := Numeric(Objects^[1].Stuff,ByteInteger);
     CBVSetup^.VerifyLD        := Numeric(Objects^[2].Stuff,ByteInteger);
     CBVSetup^.LDPass          := Numeric(Objects^[3].Stuff,ByteInteger);
     CBVSetup^.CBVStart        := ReturnTime(Objects^[4].Stuff);
     CBVSetup^.CBVEnd          := ReturnTime(Objects^[5].Stuff);
     CBVSetup^.VAccess         := Numeric(Objects^[6].Stuff,WordInteger);
     CBVSetup^.UserToLogBackIn := Numeric(Objects^[7].Stuff,ByteInteger);
     CBVSetup^.CallRetries     := Numeric(Objects^[8].Stuff,ByteInteger);
     ASSIGN(FCBVSetup,BaseDirectory+'\DATA\CALLBACK.DAT');
     REWRITE(FCBVSetup);
     WRITE(FCBVSetup,CBVSetup^);
     CLOSE(FCBVSetup);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoTimeBank;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(20,5,60,12,'TIME BANK SETTINGS',True);
     AddObject(48,7 ,2,9 ,_String(Trunc(System_Info.TBank_Max/60)),True);
     AddObject(48,8 ,2,9 ,_String(Trunc(System_Info.TBank_Trans/60)),True);
     AddButton(50,10,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(23,7);  WRITE('  Max Balance (Minutes)');
     GotoXY(23,8);  WRITE('Max Transaction Per Day');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.TBank_Max   := Numeric(Objects^[1].Stuff,LongInteger)*60;
     System_Info.TBank_Trans := Numeric(Objects^[2].Stuff,LongInteger)*60;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoByteBank;
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(20,5,60,12,'BYTE BANK SETTINGS',True);
     AddObject(48,7 ,2,9 ,_String(System_Info.BBank_Max),True);
     AddObject(48,8 ,2,9 ,_String(System_Info.BBank_Trans),True);
     AddButton(50,10,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextBackGround_BS(Colour.WindowBackGround);
     TextColor_BS(11);
     GotoXY(23,7);  WRITE('    Max Balance (Bytes)');
     GotoXY(23,8);  WRITE('Max Transaction Per Day');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.BBank_Max   := Numeric(Objects^[1].Stuff,LongInteger);
     System_Info.BBank_Trans := Numeric(Objects^[2].Stuff,LongInteger);
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DoSysopFunctions;
BEGIN
     CheckFile('SYSTEM.DAT');
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     DrawWindow(12,4,68,20,'SYSOP FUNCTIONS',True);
     AddObject(55,6 ,2,5,_String(System_Info.PrivateRead),True);
     AddObject(55,7 ,2,5,_String(System_Info.MessageCarbonCopy),True);
     AddObject(55,8 ,2,5,_String(System_Info.MessageCopy),True);
     AddObject(55,9 ,2,5,_String(System_Info.MessageMove),True);
     AddObject(55,10,2,5,_String(System_Info.MessageForward),True);
     AddObject(55,11,2,5,_String(System_Info.MessageKill),True);
     AddObject(55,12,2,5,_String(System_Info.MessageInfo),True);
     AddObject(55,14,2,5,_String(System_Info.FileMove),True);
     AddObject(55,15,2,5,_String(System_Info.FileCopy),True);
     AddObject(55,16,2,5,_String(System_Info.FileKill),True);
     AddButton(58,18,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(16,6);  WRITE('Message Areas컫 Read Private Messages');
     GotoXY(16,7);  WRITE('              쳐 Carbon Copy Messages');
     GotoXY(16,8);  WRITE('              쳐컴컴컴� Copy Messages');
     GotoXY(16,9);  WRITE('              쳐컴컴컴� Move Messages');
     GotoXY(16,10); WRITE('              쳐컴컴 Forward Messages');
     GotoXY(16,11); WRITE('              쳐컴컴컴� Kill Messages');
     GotoXY(16,12); WRITE('              읕컴컴 See Kludge Lines');
     GotoXY(16,14); WRITE('File Areas컴컴쩡컴컴컴컴컴 Move Files');
     GotoXY(16,15); WRITE('              쳐컴컴컴컴컴 Copy Files');
     GotoXY(16,16); WRITE('              읕컴컴컴컴컴 Kill Files');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     System_Info.PrivateRead       := Numeric(Objects^[1].Stuff,WordInteger);
     System_Info.MessageCarbonCopy := Numeric(Objects^[2].Stuff,WordInteger);
     System_Info.MessageCopy       := Numeric(Objects^[3].Stuff,WordInteger);
     System_Info.MessageMove       := Numeric(Objects^[4].Stuff,WordInteger);
     System_Info.MessageForward    := Numeric(Objects^[5].Stuff,WordInteger);
     System_Info.MessageKill       := Numeric(Objects^[6].Stuff,WordInteger);
     System_Info.MessageInfo       := Numeric(Objects^[7].Stuff,WordInteger);
     System_Info.FileMove          := Numeric(Objects^[8].Stuff,WordInteger);
     System_Info.FileCopy          := Numeric(Objects^[9].Stuff,WordInteger);
     System_Info.FileKill          := Numeric(Objects^[10].Stuff,WordInteger);
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     REWRITE(FSystem_Info);
     WRITE(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
END;


PROCEDURE EditTranslation(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
     RESET(FTranslation);
     SEEK(FTranslation,Number-1);
     READ(FTranslation,Translation);
     CLOSE(FTranslation);
     DrawWindow(10,8,44,15,'EDIT DIAL TRANSLATION',True);
     AddObject(28,10,1,12,Translation.LookFor,True);
     AddObject(28,11,1,12,Translation.Replacement,True);
     AddButton(34,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('  Dial String');
     GotoXY(13,11); WRITE('  Replacement');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     Translation.LookFor     := Objects^[1].Stuff;
     Translation.Replacement := Objects^[2].Stuff;
     ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
     RESET(FTranslation);
     SEEK(FTranslation,Number-1);
     WRITE(FTranslation,Translation);
     CLOSE(FTranslation);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteTranslation(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\TRANSLAT.DAT',SizeOf(Translation),Number);
END;


PROCEDURE AddTranslation;
BEGIN
     FillChar(Translation,SizeOf(Translation),0);
     ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
     {$I-}RESET(FTranslation);{$I+}
     IF (IOResult<>0) THEN REWRITE(FTranslation)
                      ELSE SEEK(FTranslation,FileSize(FTranslation));
     WRITE(FTranslation,Translation);
     CLOSE(FTranslation);
END;


PROCEDURE InsertTranslation(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(Translation,SizeOf(Translation),0);
     IF _FileExists(BaseDirectory+'\DATA\TRANSLAT.DAT') THEN
     BEGIN
          ASSIGN(FTranslation2,BaseDirectory+'\DATA\TRANSLAT.DAT');
          RENAME(FTranslation2,BaseDirectory+'\DATA\TRANSLAT.BAK');
          ASSIGN(FTranslation2,BaseDirectory+'\DATA\TRANSLAT.BAK');
          ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
          RESET(FTranslation2);
          REWRITE(FTranslation);
          Counting := 0;
          REPEAT
                READ(FTranslation2,Translation2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FTranslation,Translation);
                WRITE(FTranslation,Translation2);
          UNTIL EOF(FTranslation2);
          CLOSE(FTranslation);
          CLOSE(FTranslation2);
          ERASE(FTranslation2);
     END
     ELSE
     BEGIN
          ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
          REWRITE(FTranslation);
          WRITE(FTranslation,Translation);
          CLOSE(FTranslation);
     END;
END;


PROCEDURE DoVerifierTranslations;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
          RESET(FTranslation);
          REPEAT
                Read(FTranslation,Translation);
                PickListFile.A := _PadRight(Translation.LookFor,22)+Translation.Replacement;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FTranslation);
          CLOSE(FTranslation);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
     {$I-}RESET(FTranslation);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FTranslation);
          CLOSE(FTranslation);
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
     PickList_A_Title := _PadRight(' Dial String           Replacement',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('DIAL TRANSLATIONS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditTranslation(PickItem);
                     ASSIGN(FTranslation,BaseDirectory+'\DATA\TRANSLAT.DAT');
                     RESET(FTranslation);
                     PickListItems := FileSize(FTranslation);
                     CLOSE(FTranslation);
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
                          DeleteTranslation(PickItem);
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
                          AddTranslation;
                          EditTranslation(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertTranslation(PickItem);
                          EditTranslation(PickItem);
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
                     AddTranslation;
                     EditTranslation(PickListItems+1);
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


PROCEDURE EditNetworkInfo(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     RESET(FNetworkInfo);
     SEEK(FNetworkInfo,Number-1);
     READ(FNetworkInfo,NetworkInfo);
     CLOSE(FNetworkInfo);
     DrawWindow(10,8,53,15,'EDIT NETWORK ADDRESS',True);
     AddObject(28,10,1,20,AddressToString(NetworkInfo.Net_Address),True);
     AddObject(28,11,1,15,NetworkInfo.Net_Domain,True);
     AddButton(43,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(13,10); WRITE('  Net Address');
     GotoXY(13,11); WRITE('  Domain Name');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     StringToAddress(Objects^[1].Stuff,NetworkInfo.Net_Address);
     NetworkInfo.Net_Domain  := Objects^[2].Stuff;
     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     RESET(FNetworkInfo);
     SEEK(FNetworkInfo,Number-1);
     WRITE(FNetworkInfo,NetworkInfo);
     CLOSE(FNetworkInfo);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteNetworkInfo(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\NETWORK.DAT',SizeOf(NetworkInfo),Number);
END;


PROCEDURE AddNetworkInfo;
BEGIN
     FillChar(NetworkInfo,SizeOf(NetworkInfo),0);
     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF (IOResult<>0) THEN REWRITE(FNetworkInfo)
                      ELSE SEEK(FNetworkInfo,FileSize(FNetworkInfo));
     WRITE(FNetworkInfo,NetworkInfo);
     CLOSE(FNetworkInfo);
END;


PROCEDURE InsertNetworkInfo(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(NetworkInfo,SizeOf(NetworkInfo),0);
     IF _FileExists(BaseDirectory+'\DATA\NETWORK.DAT') THEN
     BEGIN
          ASSIGN(FNetworkInfo2,BaseDirectory+'\DATA\NETWORK.DAT');
          RENAME(FNetworkInfo2,BaseDirectory+'\DATA\NETWORK.BAK');
          ASSIGN(FNetworkInfo2,BaseDirectory+'\DATA\NETWORK.BAK');
          ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
          RESET(FNetworkInfo2);
          REWRITE(FNetworkInfo);
          Counting := 0;
          REPEAT
                READ(FNetworkInfo2,NetworkInfo2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FNetworkInfo,NetworkInfo);
                WRITE(FNetworkInfo,NetworkInfo2);
          UNTIL EOF(FNetworkInfo2);
          CLOSE(FNetworkInfo);
          CLOSE(FNetworkInfo2);
          ERASE(FNetworkInfo2);
     END
     ELSE
     BEGIN
          ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
          REWRITE(FNetworkInfo);
          WRITE(FNetworkInfo,NetworkInfo);
          CLOSE(FNetworkInfo);
     END;
END;


PROCEDURE DoNetworkInfo;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
          RESET(FNetWorkInfo);
          REPEAT
                Read(FNetWorkInfo,NetWorkInfo);
                PickListFile.A := _PadRight(AddressToString(NetworkInfo.Net_Address),25)+NetworkInfo.Net_Domain;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FNetWorkInfo);
          CLOSE(FNetWorkInfo);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FNetWorkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
     {$I-}RESET(FNetWorkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FNetWorkInfo);
          CLOSE(FNetWorkInfo);
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
     PickList_A_Title := _PadRight(' Network Address          Domain Name',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('NETWORK ADDRESSES');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditNetworkInfo(PickItem);
                     ASSIGN(FNetworkInfo,BaseDirectory+'\DATA\NETWORK.DAT');
                     RESET(FNetworkInfo);
                     PickListItems := FileSize(FNetworkInfo);
                     CLOSE(FNetworkInfo);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteNetworkInfo(PickItem);
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
                          AddNetworkInfo;
                          EditNetworkInfo(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertNetworkInfo(PickItem);
                          EditNetworkInfo(PickItem);
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
                     AddNetworkInfo;
                     EditNetworkInfo(PickListItems+1);
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


PROCEDURE EditNetOrigins(Number: Longint);
BEGIN
     _SaveWindow(WorkDir+'\EDITACC.SCR');
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     RESET(FNetOrigins);
     SEEK(FNetOrigins,Number-1);
     READ(FNetOrigins,NetOrigins);
     CLOSE(FNetOrigins);
     DrawWindow(5,9,75,15,'EDIT NETWORK ORIGIN LINE',True);
     AddObject(21,11,1,50,NetOrigins.Net_Origin,True);
     AddButton(65,13,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(8,11); WRITE('Origin Line');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     NetOrigins.Net_Origin := Objects^[1].Stuff;
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     RESET(FNetOrigins);
     SEEK(FNetOrigins,Number-1);
     WRITE(FNetOrigins,NetOrigins);
     CLOSE(FNetOrigins);
     LoadWindow(WorkDir+'\EDITACC.SCR');
END;


PROCEDURE DeleteNetOrigins(Number: Longint);
BEGIN
     _EraseFileRecord(BaseDirectory+'\DATA\ORIGINS.DAT',SizeOf(NetOrigins),Number);
END;


PROCEDURE AddNetOrigins;
BEGIN
     FillChar(NetOrigins,SizeOf(NetOrigins),0);
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     {$I-}RESET(FNetOrigins);{$I+}
     IF (IOResult<>0) THEN REWRITE(FNetOrigins)
                      ELSE SEEK(FNetOrigins,FileSize(FNetOrigins));
     WRITE(FNetOrigins,NetOrigins);
     CLOSE(FNetOrigins);
END;


PROCEDURE InsertNetOrigins(Number: Longint);
VAR  Counting : Longint;
BEGIN
     FillChar(NetOrigins,SizeOf(NetOrigins),0);
     IF _FileExists(BaseDirectory+'\DATA\ORIGINS.DAT') THEN
     BEGIN
          ASSIGN(FNetOrigins2,BaseDirectory+'\DATA\ORIGINS.DAT');
          RENAME(FNetOrigins2,BaseDirectory+'\DATA\ORIGINS.BAK');
          ASSIGN(FNetOrigins2,BaseDirectory+'\DATA\ORIGINS.BAK');
          ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
          RESET(FNetOrigins2);
          REWRITE(FNetOrigins);
          Counting := 0;
          REPEAT
                READ(FNetOrigins2,NetOrigins2);
                INC(Counting);
                IF Counting=Number THEN WRITE(FNetOrigins,NetOrigins);
                WRITE(FNetOrigins,NetOrigins2);
          UNTIL EOF(FNetOrigins2);
          CLOSE(FNetOrigins);
          CLOSE(FNetOrigins2);
          ERASE(FNetOrigins2);
     END
     ELSE
     BEGIN
          ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
          REWRITE(FNetOrigins);
          WRITE(FNetOrigins,NetOrigins);
          CLOSE(FNetOrigins);
     END;
END;


PROCEDURE DoNetOrigins;
VAR  Loop       : Word;
     OuttaHere  : Boolean;
     Action     : Word;
LABEL             OverAgain;

     PROCEDURE Reload;
     BEGIN
          ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
          RESET(FNetOrigins);
          REPEAT
                Read(FNetOrigins,NetOrigins);
                PickListFile.A := NetOrigins.Net_Origin;
                PickListFile.B := '';
                WRITE(FPickListFile,PickListFile);
          UNTIL EOF(FNetOrigins);
          CLOSE(FNetOrigins);
     END;

BEGIN
     OverAgain:
     PickListPerPage := 16;
     PickItem        := 0;
     PickTop         := 0;
     PickListItems   := 0;
     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
     {$I-}RESET(FNetOrigins);{$I+}
     IF IOResult=0 THEN
     BEGIN
          PickListItems := FileSize(FNetOrigins);
          CLOSE(FNetOrigins);
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
     PickList_A_Title := _PadRight(' Origin Line',41);
     PickList_B_Title := '          ';
     PickListX        := 11;
     PickListY        := 4;
     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
     REWRITE(FPickListFile);
     IF PickListItems<>0 THEN Reload;
     CLOSE(FPickListFile);
     SetUpPickList('NETWORK ORIGINS');
     REPEAT
           Action := DoPickList;
           CASE Action OF
           0:   OuttaHere := True; {NORMAL QUIT}
           1:   IF (PickItem<>0) THEN
                BEGIN {EDIT}
                     EditNetOrigins(PickItem);
                     ASSIGN(FNetOrigins,BaseDirectory+'\DATA\ORIGINS.DAT');
                     RESET(FNetOrigins);
                     PickListItems := FileSize(FNetOrigins);
                     CLOSE(FNetOrigins);
                     ASSIGN(FPickListFile,WorkDir+'\PICK.LST');
                     REWRITE(FPickListFile);
                     Reload;
                     CLOSE(FPickListFile);
                     GOTO OverAgain;
                END;
           2:   IF PickListItems>1 THEN
                BEGIN {DELETE}
                     IF Confirmed THEN
                     BEGIN
                          DeleteNetOrigins(PickItem);
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
                          AddNetOrigins;
                          EditNetOrigins(PickListItems+1);
                     END
                     ELSE
                     BEGIN
                          InsertNetOrigins(PickItem);
                          EditNetOrigins(PickItem);
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
                     AddNetOrigins;
                     EditNetOrigins(PickListItems+1);
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


PROCEDURE DoFunctionKeys;
BEGIN
     CheckFile('FKEYS.DAT');
     ASSIGN(FFunctionKeys,BaseDirectory+'\DATA\FKEYS.DAT');
     RESET(FFunctionKeys);
     READ(FFunctionKeys,FunctionKeys);
     CLOSE(FFunctionKeys);
     DrawWindow(2,5,78,20,'FUNCTION KEYS',True);
     AddObject(15,7,1,60,FunctionKeys.GSMail_F1,True);
     AddObject(15,8,1,60,FunctionKeys.GSMail_F2,True);
     AddObject(15,9,1,60,FunctionKeys.GSMail_F3,True);
     AddObject(15,10,1,60,FunctionKeys.GSMail_F4,True);
     AddObject(15,11,1,60,FunctionKeys.GSMail_F5,True);
     AddObject(15,12,1,60,FunctionKeys.GSMail_F6,True);
     AddObject(15,13,1,60,FunctionKeys.GSMail_F7,True);
     AddObject(15,14,1,60,FunctionKeys.GSMail_F8,True);
     AddObject(15,15,1,60,FunctionKeys.GSMail_F9,True);
     AddObject(15,16,1,60,FunctionKeys.GSMail_F10,True);
     AddButton(68,18,' QUIT ',True,1,16);
     DrawObjects;
     DrawButtons;
     _HideMouse;
     TextColor_BS(11);
     TextBackGround_BS(Colour.WindowBackGround);
     GotoXY(4,7);  WRITE('GSMail횲1');
     GotoXY(4,8);  WRITE('    쳐횲2');
     GotoXY(4,9);  WRITE('    쳐횲3');
     GotoXY(4,10); WRITE('    쳐횲4');
     GotoXY(4,11); WRITE('    쳐횲5');
     GotoXY(4,12); WRITE('    쳐횲6');
     GotoXY(4,13); WRITE('    쳐횲7');
     GotoXY(4,14); WRITE('    쳐횲8');
     GotoXY(4,15); WRITE('    쳐횲9');
     GotoXY(4,16); WRITE('    읕F10');
     _ShowMouse;
     DoObjects;
     ClearObjects;
     ClearButtons;
     FunctionKeys.GSMail_F1  := Objects^[1].Stuff;
     FunctionKeys.GSMail_F2  := Objects^[2].Stuff;
     FunctionKeys.GSMail_F3  := Objects^[3].Stuff;
     FunctionKeys.GSMail_F4  := Objects^[4].Stuff;
     FunctionKeys.GSMail_F5  := Objects^[5].Stuff;
     FunctionKeys.GSMail_F6  := Objects^[6].Stuff;
     FunctionKeys.GSMail_F7  := Objects^[7].Stuff;
     FunctionKeys.GSMail_F8  := Objects^[8].Stuff;
     FunctionKeys.GSMail_F9  := Objects^[9].Stuff;
     FunctionKeys.GSMail_F10 := Objects^[10].Stuff;
     ASSIGN(FFunctionKeys,BaseDirectory+'\DATA\FKEYS.DAT');
     REWRITE(FFunctionKeys);
     WRITE(FFunctionKeys,FunctionKeys);
     CLOSE(FFunctionKeys);
END;


END.
