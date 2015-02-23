{$I DEFINES.INC}
UNIT StartUp;


INTERFACE


PROCEDURE FireUpSystem;
PROCEDURE Intro;


IMPLEMENTATION


USES Globals,BsFile,Screens,KeyInput,Gfx,UserFile,Report,BsComp,SysScrn,
     MsgSrch2,FileSrch,DoFreqs,ListFile,CBVMisc,CBV,FilHeadr,MsgHeadr,
     ErrorLog,Crt,ApTimer,BsExec,ExtDos,AllGone,Dos,BsMulti,ApCom,ApPort,
     Yapp,BsLog,NodeFile,Download,SBuffer,GotKeys,Time,Reload,Execute,
     Comm,Calls,DoorFile,CheckUsr,CDs,OvrVars,CID,BsTime,BsString,
     KeyCheck,Version;


VAR  NodeSelected : Boolean;
     ModeSelected : Word;
     TermType     : String[30];


PROCEDURE new_user;
VAR  Work       : Word;
     OldPW      : String;
LABEL             OverAgain1,OverAgain2;
BEGIN
     OldPW := UserRecord.Password;
     FillChar(UserRecord,SizeOf(UserRecord),0);
     SetUsersAccessDefaults(system_info.access_new_user);
     UserRecord.Password := OldPW;
     UserRecord.name := user_name;
     UserRecord.user_number := new_user_number;
     UserRecord.Birth := '000000';
     ASSIGN(FNewUserVga,LANG_Directory+'\NEWUSER.VGA');
     RESET(FNewUserVga);
     REPEAT
           READ(FNewUserVga,NewUserVga);
           IF _FileExists(SGDirectory+'\'+NewUserVga.FileName+'.SG') THEN
           BEGIN
               FillChar(Fields,SizeOf(Fields),0);
               OverAgain1:
               DisplayGraphicFile(NewUserVga.FileName,False,True,True);
               OverAgain2:
               Get_Enter;
               FOR Work := 1 TO NFields DO
               BEGIN
                    IF Fields[Work].Text='' THEN
                    BEGIN
                         ChangeField(Work);
                         GOTO OverAgain2;
                    END;
                    IF Fields[Work].EntryType=2 THEN
                    BEGIN
                         IF AliasExists THEN
                         BEGIN
                              DisplayGraphicFile('QUEST2',False,True,True);
                              Get_Enter;
                              GOTO OverAgain1;
                         END;
                    END;
               END;
          END;
     UNTIL EOF(FNewUserVga);
     CLOSE(FNewUserVga);
     WriteNewUser;
     DoNewUserReport;
END;


PROCEDURE LoadGraphicsSystem;
BEGIN
     NEW(CBuffer);
     TBufferedFile.Init(16384);
END;


PROCEDURE DoOpeningFile;
VAR  OldAccess   : Word;
BEGIN
     ASSIGN(FOpening,LANG_Directory+'\OPENING.DAT');
     RESET(FOpening);
     REPEAT
           READ(FOpening,Opening);
           CASE Opening.FunctionType OF
           1:   ShowLastComment;
           2:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',126);
                          IF GET_YES_NO=true THEN Do_Welcome;
                     END;
                1:   do_welcome;
                END;
           3:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',127);
                          IF GET_YES_NO=true THEN Do_Once_Only;
                     END;
                1:   do_once_only;
                END;
           4:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',128);
                          IF GET_YES_NO=true THEN Do_News;
                     END;
                1:   do_news;
                END;
           5:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',129);
                          IF GET_YES_NO=true THEN show_last_Callers;
                     END;
                1:   show_last_Callers;
                END;
           6:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',118);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               CurrentMessageSub := 0;
                               New_Mail_Logon;
                               CurrentMessageSub := 1;
                          END;
                     END;
                1:   BEGIN
                          CurrentMessageSub := 0;
                          New_Mail_Logon;
                          CurrentMessageSub := 1;
                     END;
                END;
           7:   CASE Opening.Forced OF
                0:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               System_Prompt('',117);
                               IF GET_YES_NO=true THEN
                               BEGIN
                                    CurrentFileSub := 0;
                                    search_new(True);
                                    List_Files(NODE_Directory+'\SEARCH$$');
                                    CurrentFileSub := 1;
                               END;
                          END;
                     END;
                1:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               CurrentFileSub := 0;
                               search_new(True);
                               List_Files(NODE_Directory+'\SEARCH$$');
                               CurrentFileSub := 1;
                          END;
                     END;
                END;
           8:   BEGIN
                     IF ((UserRecord.ver_user<>1) AND (GetCBVEnabled=1)) THEN
                     BEGIN
                          OldAccess := UserRecord.Security;
                          CallBackVerifier;
                          IF OldAccess<>UserRecord.Security THEN
                          BEGIN
                               Header2(1,1,True);
                               Header(1,1,True);
                          END;
                     END;
                END;
           9:   show_user_specific;
           10:  do_user_access;
           11:  do_date_specific;
           12:  do_birthday;
           END;
     UNTIL EOF(FOpening);
     CLOSE(FOpening);
END;


PROCEDURE CantDoIt(TheOne: Longint);
BEGIN
     DoErrorLog(40,_String(TheOne));
     TextMode(co80);
     TEXTCOLOR(7);
     ClrScr;
     WRITELN('CRITICAL ERROR!!! Gunshot can only handle 255 lines!');
     WRITELN;
     Halt;
END;


PROCEDURE Hey;
BEGIN
     DoErrorLog(39,'');
     TextMode(co80);
     ClrScr;
     TEXTCOLOR(10);
     WRITELN('This program is a component of the Gunshot Professional package.');
     WRITELN('You do not directly execute this program manually yourself.');
     TEXTCOLOR(7);
     WRITELN;
     Halt;
END;


PROCEDURE get_params;
VAR  loop         : word;
     parameters   : array[1..10] of string[10];
     param        : char;
     code         : integer;
     Before       : String;
BEGIN
     NodeNumber     := 1;
     ActualBaud     := 0;
     NodeSelected   := False;
     EventMinutes   := 32000; {No Event}
     ModeSelected   := 640;
     DoQuickLogon   := False;
     IF (ParamStr(1)<>'$$BB$$SS') THEN Hey;
     FOR loop := 2 TO paramcount DO
     BEGIN
          parameters[loop] := paramstr(loop);
          IF ((parameters[loop,1]='-') OR (parameters[loop,1]='/')) THEN
          BEGIN
               DELETE(parameters[loop],1,1);
               IF _UpperCase(parameters[loop])='BIOS' THEN
               BEGIN

               END
               ELSE IF _UpperCase(parameters[loop])='QUICK' THEN
               BEGIN
                    DoQuickLogon := True;
               END
               ELSE IF _UpperCase(parameters[loop])='640' THEN
               BEGIN
                    ModeSelected := 640;
               END
               ELSE IF _UpperCase(parameters[loop])='800' THEN
               BEGIN
                    {ModeSelected := 800;}
               END
               ELSE IF _UpperCase(parameters[loop])='1024' THEN
               BEGIN
                    {ModeSelected := 1024;}
               END
               ELSE
               BEGIN
                    Before := parameters[loop];
                    param := parameters[loop,1];
                    DELETE(parameters[loop],1,1);
                    CASE Upcase(param) OF
{BAUD}              'B' : VAL(parameters[loop],ActualBaud,code);
{NODE NUMBER}       'N' : BEGIN
                               VAL(parameters[loop],NodeNumber,code);
                               Str(NodeNumber,NodeString);
                               NodeSelected := True;
                          END;
{EVENT PENDING}     'E' : VAL(parameters[loop],EventMinutes,code);
{FAST USER LOGON}   'U' : ;
                    ELSE  DoErrorLog(39,Before);
                    END;
               END;
          END;
     END;
     IF (EventMinutes<>32000) THEN
     BEGIN
          BigCrap := EventMinutes;
          BigCrap := BigCrap*60;
          NewTimerSecs(EventTicker,BigCrap);
     END;
END;


PROCEDURE defines;
VAR  Loop       : Word;
     Temp       : String;
BEGIN
     NEW(MENU);
     FillChar(UserRecord,SizeOf(UserRecord),0);
     tagged                := 0;
     user_name             := '';
     full_day              := 24;
     full_day              := full_day*60;
     full_day              := full_day*60;
     sysop_next            := false;
     user_pages            := 0;
     time_for_downloads    := 0;
     DATA_Directory        := Gunshot_Directory+'\DATA';
     INTR_Directory        := Gunshot_Directory+'\INTRNODE';
     BIN_Directory         := Gunshot_Directory+'\BIN';
     ASSIGN(FSystemInfo,DATA_Directory+'\SYSTEM.DAT');
     RESET(FSystemInfo);
     READ(FSystemInfo,system_info);
     CLOSE(FSystemInfo);
     _CreatePath(INTR_Directory);
     IF NodeSelected=False THEN
     BEGIN
          DoErrorLog(38,'');
          TEXTCOLOR(7);
          ClrScr;
          WRITELN('CRITICAL ERROR!!! No node number was specified. Please use the');
          WRITELN('command switch -Nxx (where xx is the node number you wish to use)');
          WRITELN;
          Halt;
     END;
     IF System_Info.NodeDrive='' THEN
     BEGIN
          NODE_Directory := Gunshot_Directory+'\NODE'+NodeString;
     END
     ELSE
     BEGIN
          Temp := Gunshot_Directory;
          Delete(Temp,1,1);
          NODE_Directory := System_Info.NodeDrive+Temp+'\NODE'+NodeString;
     END;
     SIG_Directory  := Gunshot_Directory+'\ANSISIGS';
     HOLD_Directory := NODE_Directory+'\HOLDFILE';
     SCAN_Directory := NODE_Directory+'\SCAN_DIR';
     CD_Directory   := NODE_Directory+'\CD_TEMP';
     RESOURCES      := Gunshot_Directory+'\RESOURCE\';
     _CreatePath(NODE_Directory);
     _CreatePath(HOLD_Directory);
     _CreatePath(SCAN_Directory);
     _CreatePath(SIG_Directory);
     _CreatePath(BIN_Directory);
     _CreatePath(CD_Directory);
     _CreatePath(Gunshot_Directory+'\MSGTAGS');
     _CreatePath(Gunshot_Directory+'\FILETAGS');
END;


PROCEDURE read_system_data;
BEGIN
     ASSIGN(FNodeInfo,DATA_Directory+'\NODES.DAT');
     RESET(FNodeInfo);
     SEEK(FNodeInfo,NodeNumber-1);
     READ(FNodeInfo,NodeInfo);
     CLOSE(FNodeInfo);
     ASSIGN(FNames,DATA_Directory+'\NAMES.DAT');
     RESET(FNames);
     READ(FNames,Names);
     CLOSE(FNames);
     ASSIGN(FUUCP,DATA_Directory+'\UUCP.DAT');
     RESET(FUUCP);
     READ(FUUCP,UUCP);
     CLOSE(FUUCP);
     ASSIGN(FFreqs,DATA_Directory+'\FREQ.DAT');
     RESET(FFreqs);
     READ(FFreqs,Freqs);
     CLOSE(FFreqs);
     ASSIGN(FArcDefs,DATA_Directory+'\ARCHIVE.DAT');
     RESET(FArcDefs);
     READ(FArcDefs,ArcDefs);
     CLOSE(FArcDefs);
     ASSIGN(FCallerIdRecord,DATA_Directory+'\CALLERID.DAT');
     RESET(FCallerIdRecord);
     READ(FCallerIdRecord,CallerIdRecord);
     CLOSE(FCallerIdRecord);
END;


FUNCTION got_all_files: boolean;
VAR  yup        : boolean;
BEGIN
     yup := true;
     IF NOT(_FileExists(DATA_Directory+'\ACCESS.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\ACCESS.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\ARCHIVE.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\ARCHIVE.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\FA000000.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\FA000000.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\FILEAREA.SUB')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\FILEAREA.SUB');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\LANGUAGE.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\LANGUAGE.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\MA000000.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\MA000000.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\MSGAREA.SUB')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\MSGAREA.SUB');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\NAMES.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\NAMES.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\PROTOCOL.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\PROTOCOL.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\SCANNERS.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\SCANNERS.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\SYSTEM.DAT')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\SYSTEM.DAT');
          yup := false;
     END;
     IF NOT(_FileExists(DATA_Directory+'\USERS.BBS')) THEN
     BEGIN
          DoErrorLog(37,DATA_Directory+'\USERS.BBS');
          yup := false;
     END;
     got_all_files := yup;
END;


PROCEDURE FireUpSystem;
VAR  Loop : Word;
     Temp : String;
BEGIN
     GetDir(0,Temp);
     CurrentDrive := Temp[1];
     ClrScr;
     doing_logon := true;
     NodeNumber  := 1;
     STR(NodeNumber,NodeString);
     Temp := _UpperCase(_GetFilePath(ParamStr(0)));
     Gunshot_Directory := Temp[1]+':\GUNSHOT';
     ChDir(gunshot_directory);
     get_params;
     _CreatePath(gunshot_directory+'\NODE'+NodeString);
     IF (NodeNumber>255) THEN CantDoIt(NodeNumber);
     CheckRegistered(gunshot_directory+'\NODE'+NodeString,'Gunshot');
     bsSetLog(OurAppName,'',NodeNumber);
     defines;
     read_system_data;
     clear_dirs;
     IF Got_All_Files=False THEN
     BEGIN
          TextMode(Co80);
          ClrScr;
          TEXTCOLOR(4);
          WRITELN('CRITICAL ERROR!!! Missing a required data file in the '+DATA_Directory+'\');
          WRITELN('directory. Please run GSCONFIG.EXE to correct the problem.');
          WRITELN;
          TEXTCOLOR(7);
          Halt;
     END;
END;


PROCEDURE SelectLanguage;
VAR  TFile : Text;
     Temp  : String;
     Work  : Word;
BEGIN
     ASSIGN(TFile,NODE_Directory+'\LANGUAGE.SEL');
     {$I-}RESET(TFile);{$I+}
     IF IOResult<>0 THEN Dispatcher(8);
     READLN(TFile,Temp);
     CLOSE(TFile);
     Work := _Numeric(Temp);

     ASSIGN(FLangDir,Gunshot_Directory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     {$I-}
     SEEK(FLangDir,Work-1);
     {$I+}
     IF IOResult<>0 THEN
     BEGIN
          CLOSE(FLangDir);
          Dispatcher(8);
     END;
     READ(FLangDir,LangDir);
     CLOSE(FLangDir);

     LanguageDirectory := LangDir.Directory;
     SGDirectory       := LanguageDirectory+'SG';
     SGXDirectory      := LanguageDirectory+'SGX';
     LANG_Directory    := LanguageDirectory+'LANG';
     MENU_Directory    := LanguageDirectory+'MENUS';
     NEWS_Directory    := LanguageDirectory+'NEWS';
     ASSIGN(FColours,LANG_Directory+'\COLOURS.VGA');
     RESET(FColours);
     READ(FColours,Colours);
     CLOSE(FColours);
END;


PROCEDURE bbs_header;
VAR  dos_ver  : word;
     temp999  : string;
     C        : Char;
     Work     : Word;
     DirInfo  : SearchRec;
BEGIN
     {SEND OUR INITIAL SYSTEM PACKS}
     SendSystemFile(LANG_Directory+'\COLOURS.VGA');
     SendSystemFile(Gunshot_Directory+'\ICONS\BPRESS.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\BUSY.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\DEFAULT.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\FILEDRAG.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\INSERT.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\MSGDRAG.MSE');
     SendSystemFile(Gunshot_Directory+'\ICONS\WINMOVE.MSE');
     IF ((Colours.InternalImage>0) AND (Colours.InternalImage<6)) THEN
     BEGIN
          PutStringTimeout(BBSPort,#255#119+Chr(Colours.InternalImage)+#13,YappDelay);
          GetYAPPAck;
     END;
     temp999 := '';
     PutStringTimeout(BBSPort,#255#127#13,YappDelay);
     GetStringTimeout(BBSPort,Temp999,255,[#13],60);
     Delete(Temp999,LENGTH(Temp999),1);
     C := Temp999[LENGTH(Temp999)];
     IF C='P' THEN
     BEGIN
          Dec(Temp999[0]);
          TermType := 'Extended Dos';
     END
     ELSE IF C='M' THEN
     BEGIN
          Dec(Temp999[0]);
          TermType := 'Macintosh';
     END
     ELSE IF C='O' THEN
     BEGIN
          Dec(Temp999[0]);
          TermType := 'OS/2';
     END
     ELSE IF C='U' THEN
     BEGIN
          Dec(Temp999[0]);
          TermType := 'UNIX';
     END
     ELSE IF C='W' THEN
     BEGIN
          Dec(Temp999[0]);
          TermType := 'Windows';
     END
     ELSE
     BEGIN
          IF C='D' THEN Dec(Temp999[0]);
          TermType := 'DOS';
     END;
     RemoteYappVersion := _Numeric(Temp999);
     IF (RemoteYappVersion<YappVersion) THEN
     BEGIN
          DisplayGraphicFile('BADYAPP',False,True,True);
          IF Get_Yes_No THEN
          BEGIN
               UserRecord.Name     := 'YAPP Update';
               UserRecord.Alias    := '';
               UserRecord.City     := 'Somewhere';
               UserRecord.Prov     := 'Unknown';
               UserRecord.PageFlag := 1;
               bsWriteLog('Updating Yapp Protocol For '+TermType,True);
               DoNodeActivity(0,'');
               IF ((TermType='Dos') OR (TermType='Extended Dos')) THEN
               BEGIN
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\GST.HLP')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\GST.HLP',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\GST.EXE')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\GST.EXE',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\PLAYVOC.EXE')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\PLAYVOC.EXE',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\PLAYFLI.EXE')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\PLAYFLI.EXE',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\MODEMS.DAT')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\MODEMS.DAT',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\YAPP.GXL')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\YAPP.GXL',True);
                    IF _FileExists(Gunshot_Directory+'\NEWYAPP\YAPP16.EXE')
                       THEN dl_file(Gunshot_Directory+'\NEWYAPP\YAPP16.EXE',True);
                    PutStringTimeout(BBSPort,#255#130#13,YappDelay);
               END
               ELSE
               BEGIN
                    ClearBuffer;
                    AddToBuffer('@USERSTERMINAL',TermType);
                    DisplayGraphicFile('CANTUPDT',True,True,True);
                    Get_Enter;
               END;
          END;
          Dispatcher(0);
     END;
     IF _FileExists(Gunshot_Directory+'\FLICS\BACKGRND.FLI')
        THEN PlayFLIFile(Gunshot_Directory+'\FLICS\BACKGRND.FLI');
     DisplayGraphicFile('BACKGRND',False,True,True);
END;


PROCEDURE CheckLogonAccess(NewUser: Boolean);
BEGIN
     IF NewUser THEN
     BEGIN
          IF NodeInfo.AllowNewUsers=1 THEN
          BEGIN
               Exit;
          END
          ELSE
          BEGIN
               bsWriteLog('No new users allowed to this node',True);
               DisplayGraphicFile('NONEW',False,True,True);
               Dispatcher(5);
          END;
     END
     ELSE
     BEGIN
          IF ((UserRecord.Security>=NodeInfo.AccessMinimum) AND
             (GotTheKeys(UserRecord.Tags,NodeInfo.Tags))) THEN
          BEGIN
               IF UserIsAlreadyOnline THEN
               BEGIN
                    bsWriteLog('User is already logged in on another node',True);
                    DisplayGraphicFile('NODOUBLE',False,True,True);
                    Dispatcher(5);
               END
               ELSE Exit;
          END
          ELSE
          BEGIN
               bsWriteLog('User doesn''t have high enough access for this node',True);
               DisplayGraphicFile('NOACCESS',False,True,True);
               Dispatcher(5);
          END;
     END;
END;


PROCEDURE do_logon;
VAR  bad_pass       : byte;
     old_time_left  : longint;
     c              : Char;
     User_Password  : String;
     Temp1          : String;
     Temp2          : String;
     RemoteEMSXMS   : Longint;
     RemoteOS       : String;
     Temp           : String;
LABEL                 redo,SkipThis;
BEGIN
     CASE _OverlayBufLoc OF
     1:   Temp := '[XMS]';
     2:   Temp := '[EMS]';
     3:   Temp := '[DISK]';
     ELSE Temp := '[Error]';
     END;
     bsWriteLog('Overlay buffer: '+_String(_OverLayBufferSize)+' bytes '+Temp,True);
     bsWriteLog('User logging on at '+BaudString+' BPS',True);
     bad_pass := 0;
     FlushInBuffer(BBSPort);
     PutStringTimeout(BBSPort,#255#134#13,YappDelay);
     GetStringTimeout(BBSPort,Temp1,255,[#13],80);
     GetStringTimeout(BBSPort,Temp2,255,[#13],80);
     IF ((Temp1<>'') AND (Temp2<>'')) THEN
     BEGIN
          Delete(Temp1,LENGTH(Temp1),1);
          Delete(Temp2,LENGTH(Temp2),1);
          IF ((Temp1<>'') AND (Temp2<>'')) THEN
          BEGIN
               user_name     := Temp1;
               user_password := _UpperCase(Temp2);
               IF _UpperCase(user_name)='SYSOP' THEN user_name := '';
               IF Pos(' ',user_name)=0 THEN
               BEGIN
                    IF NOT(system_info.alias_system) THEN user_name := '';
               END;
               IF ((User_Name<>'') AND (User_Password<>'')) THEN GOTO SkipThis;
          END;
     END;
     redo:
     DisplayGraphicFile('PRELOG',false,True,True);
     SuccessfulLogon := False;
     User_Name := '';
     REPEAT
           C := GetKeyPress;
           IF C=#13 THEN
           BEGIN
                user_name     := UserRecord.Name;
                user_password := UserRecord.Password;
                IF _UpperCase(user_name)='SYSOP' THEN user_name := '';
                IF Pos(' ',user_name)=0 THEN
                BEGIN
                     IF NOT(system_info.alias_system) THEN user_name := '';
                END;
           END;
     UNTIL ((user_name<>'') AND (User_Password<>''));
     SkipThis:
     bsWriteLog('User claims to be '+user_name,True);
     IF UserFound THEN
     BEGIN
          CheckLogonAccess(False);
          old_time_left := UserRecord.SecondsRemaining;
          IF User_Password=UserRecord.password THEN
          BEGIN
               INC(UserRecord.total_calls);
               RealLastCall := UserRecord.last_call;
               UserRecord.last_call := _ProperDate;
               bad_pass := 0;
          END
          ELSE
          BEGIN
               INC(bad_pass);
               IF Bad_Pass<>3 THEN
               BEGIN
                    bsWriteLog('Guessing at password',True);
                    System_Prompt('',64);
                    Get_Enter;
                    UserRecord.Password := '';
                    GOTO Redo;
               END
               ELSE
               BEGIN
                    UserRecord.bad_logon := 1;
                    UserRecord.SecondsRemaining := old_time_left;
                    WriteUser;
                    dispatcher(6);
               END;
          END;
          IF UserRecord.bad_logon<>0 THEN
          BEGIN
               bsWriteLog('Last logon was unsuccessful',True);
               DisplayGraphicFile('BADLOGON',False,True,True);
               Get_Enter;
          END;
          IF UserRecord.Punt=1 THEN
          BEGIN
               bsWriteLog('User is not allowed on the system',True);
               DisplayGraphicFile('BOOTUSER',False,True,True);
               dispatcher(5);
          END;
          UserRecord.bad_logon := 0;
          GetAccessLevelDefaults(UserRecord.Security);
          IF RemoveTime(RealLastCall)<>_ProperDateNoTime THEN
          BEGIN
               UserRecord.SecondsRemaining   := UserAccess.Time;
               UserRecord.DLBytesRemaining   := UserAccess.Daily_Bytes;
               UserRecord.DLBytesToday       := 0;
               UserRecord.TimeBankWithdrawls := 0;
               UserRecord.ByteBankWithdrawls := 0;
               IF UserRecord.SubModel=2 THEN INC(UserRecord.SubCallDaysUsed);
               IF UserRecord.SubModel=1 THEN UserRecord.SubCalendarDaysUsed :=
                                             DaysBetween(UserRecord.SubLastChange,_ProperDateNoTime);
          END;
     END
     ELSE
     BEGIN
          CheckLogonAccess(True);
          System_Prompt(user_name,114);
          IF Get_Yes_No=False THEN
          BEGIN
               bsWriteLog('User is guessing at his/her name. Entered: '+user_name,True);
               UserRecord.Name     := '';
               UserRecord.Password := '';
               GOTO redo;
          END;
          bsWriteLog('New user logging on',True);
          UserRecord.Name := User_Name;
          UserRecord.Password := User_Password;
          new_user;
     END;
     DoNodeActivity(0,'');
     LastUserOnline.TimeOn := _GetPrettyDate+' - '+_GetPrettyTime;
     IF UserRecord.SecondsRemaining=0 THEN
     BEGIN
          DisplayGraphicFile('TIMEUP',false,True,True);
          dispatcher(3);
     END;
     CheckCIDInfo;
     Subscription;
     doing_logon := false;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     TimeLimit;
     IF Pos(' ',User_Name)=0 THEN user_name := user_name+' NLN';
     SuccessfulLogon := True;
     bsWriteLog('Successful log on as: '+user_name,True);
     IF (EventMinutes<>32000) THEN
     BEGIN
          bsWriteLog('Next event in '+_String(EventMinutes)+' minutes',True);
          bsWriteLog('Event timer set at '+_String(BigCrap),True);
     END;
     IF _FileExists('PRELOG.BAT') THEN
     BEGIN
          DumpUser;
          make_door_files(0,1);
          ExecuteDosCommand('PRELOG.BAT '+NodeString+' '+ComString+' '+BaudString);
          Chdir(Gunshot_Directory);
          ReloadUser;
     END;
     FlushInBuffer(BBSPort);
     {Check Remote Memory}
     RemoteEMSXMS := 512000;
     PutStringTimeout(BBSPort,#255#136#13,YappDelay);
     GetStringTimeout(BBSPort,Temp1,255,[#13],80);
     GetStringTimeout(BBSPort,Temp2,255,[#13],80);
     IF ((Temp1<>'') AND (Temp2<>'')) THEN
     BEGIN
          Delete(Temp1,LENGTH(Temp1),1);
          Delete(Temp2,LENGTH(Temp2),1);
          IF ((Temp1<>'') AND (Temp2<>'')) THEN
          BEGIN
               RemoteEMSXMS := _Numeric(Temp1);
               bsWriteLog('Remote EMS/XMS......: '+Temp1,True);
          END
          ELSE bsWriteLog('Memory check unavailable',True);
     END
     ELSE bsWriteLog('Memory check unavailable',True);
     {Check Remote Video Mode}
     PutStringTimeout(BBSPort,#255#137#13,YappDelay);
     GetStringTimeout(BBSPort,Temp1,255,[#13],80);
     IF (Temp1<>'') THEN
     BEGIN
          Delete(Temp1,LENGTH(Temp1),1);
          IF (Temp1<>'') THEN
          BEGIN
                   IF Temp1='1024' THEN Temp2 := '1024x768x256'
               ELSE IF Temp1='800' THEN Temp2 := '800x600x256'
               ELSE IF Temp1='640' THEN Temp2 := '640x480x256';
               bsWriteLog('Video mode: '+Temp2,True);
          END
          ELSE bsWriteLog('Video mode unavailable',True);
     END
     ELSE bsWriteLog('Video mode unavailable',True);
     {Check Remote Operating System}
     PutStringTimeout(BBSPort,#255#138#13,YappDelay);
     GetStringTimeout(BBSPort,RemoteOS,255,[#13],80);
     IF (RemoteOS<>'') THEN
     BEGIN
          Delete(RemoteOS,LENGTH(RemoteOS),1);
          IF (RemoteOS<>'') THEN bsWriteLog('Operating system: '+RemoteOS,True)
                            ELSE bsWriteLog('Operating system unavailable',True);
     END
     ELSE bsWriteLog('Operating system unavailable',True);
     bsWriteLog('Terminal Software: '+TermType+' v'+_String(RemoteYappVersion),True);
     {Warn User Of Low EMS/XMS}
     IF (RemoteEMSXMS<1024000) THEN
     BEGIN
          IF DisplayGraphicFile('LOWEMS',False,True,True) THEN
          BEGIN
               bsWriteLog('User warned about low EMS/XMS memory',True);
               Get_Enter;
          END;
     END;
END;


PROCEDURE Intro;
BEGIN
     Window(1,1,80,24);
     CASE System_Info.SwapMethod OF
     1:   {EMS/XMS}      SwappingMethod := USE_EMS or USE_XMS;
     2:   {EMS/XMS/Disk} SwappingMethod := USE_ALL;
     3:   {Disk}         SwappingMethod := USE_FILE or CHECK_NET;
     END;
     BaudString       := _String(ActualBaud);
     ComString        := _String(NodeInfo.ComPort);
     LockedBaudString := _String(ReturnRate(NodeInfo.BaudRate,NodeInfo.ComDevice));
     SelectLanguage;
     LoadGraphicsSystem;
     bbs_header;
     bsWriteLog('SVGA interface selected',True);
     cps := TRUNC(ActualBaud/10);
     IF CPS=0 THEN
     BEGIN
          CPS := 1650;
          DoErrorLog(1,' - Connect rate not passed. Use the -B parameter!');
     END;
     do_logon;
     doing_logon := false;
     get_call_totals;
     Header2(1,1,True);
     Header(1,1,True);
     UpdateDlRatio;
     IF NOT(DoQuickLogon) THEN DoOpeningFile;
     CheckYourFreqs;
     StartCDToggle;
     LastMenuLoaded := UserAccess.first_menu;
     redraw_menu := true;
END;


END.
