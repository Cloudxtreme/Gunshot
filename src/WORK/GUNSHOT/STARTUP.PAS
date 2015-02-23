{$I DEFINES.INC}
UNIT STARTUP;


INTERFACE


PROCEDURE Intro;
PROCEDURE defines;
PROCEDURE do_logon;
PROCEDURE new_user;
PROCEDURE get_params;
PROCEDURE FireUpSystem;
PROCEDURE read_system_data;
FUNCTION  got_all_files: boolean;
PROCEDURE SelectLanguage;
PROCEDURE select_video;
PROCEDURE DoOpeningFile;


IMPLEMENTATION


USES ErrorLog,Globals,Crt,BsExec,ApTimer,Screens,KeyInput,ANSIMisc,
     ExtDos,Comm,ApCom,ApPort,BsMulti,Dos,Download,BsLog,SysScrn,
     MsgSrch2,FileSrch,ListFile,CBVMisc,CBV,FilHeadr,MsgHeadr,AllGone,
     GotKeys,UserFile,Time,NodeFile,Reload,Execute,Calls,CID,MiscStr,
     Report,DoorFile,ViewTFil,DoFreqs,CheckUsr,Commands,Version,CDs,
     OvrVars,BsFile,BsString,BsTime,KeyCheck,Shotgun;


VAR  NodeSelected   : Boolean;
     LanguageNum    : Word;
     CommandLine    : String;


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


PROCEDURE defines;
VAR  Loop       : Word;
     Temp       : String;
BEGIN
     NEW(WorkBuffer);
     NEW(Menu);
     FillChar(UserRecord,SizeOf(UserRecord),0);
     tagged                := 0;
     user_name             := '';
     full_day              := 24;
     full_day              := full_day*60;
     full_day              := full_day*60;
     sysop_next            := false;
     user_pages            := 0;
     time_for_downloads    := 0;
     DATA_Directory        := Shotgun_Directory+'\DATA';
     INTR_Directory        := Shotgun_Directory+'\INTRNODE';
     BIN_Directory         := Shotgun_Directory+'\BIN';
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
          NODE_Directory := Shotgun_Directory+'\NODE'+NodeString;
     END
     ELSE
     BEGIN
          Temp := Shotgun_Directory;
          Delete(Temp,1,1);
          NODE_Directory := System_Info.NodeDrive+Temp+'\NODE'+NodeString;
     END;
     SIG_Directory  := Shotgun_Directory+'\ANSISIGS';
     HOLD_Directory := NODE_Directory+'\HOLDFILE';
     SCAN_Directory := NODE_Directory+'\SCAN_DIR';
     CD_Directory   := NODE_Directory+'\CD_TEMP';
     _CreatePath(NODE_Directory);
     _CreatePath(HOLD_Directory);
     _CreatePath(SCAN_Directory);
     _CreatePath(SIG_Directory);
     _CreatePath(BIN_Directory);
     _CreatePath(CD_Directory);
     _CreatePath(Shotgun_Directory+'\MSGTAGS');
     _CreatePath(Shotgun_Directory+'\FILETAGS');
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
     LocalLogon     := false;
     NodeSelected   := False;
     SysopLogon     := False;
     DirectWrites   := True;
     EventMinutes   := 32000; {No Event}
     CommandLine    := '$$BB$$SS ';
     DoQuickLogon   := False;
     LogonUser      := 999999999;
     FOR loop := 1 TO paramcount DO
     BEGIN
          CommandLine := CommandLine+paramstr(loop)+' ';
          parameters[loop] := paramstr(loop);
          IF ((parameters[loop,1]='-') OR (parameters[loop,1]='/')) THEN
          BEGIN
               DELETE(parameters[loop],1,1);
               IF _UpperCase(parameters[loop])='QUICK' THEN
               BEGIN
                    DoQuickLogon := True;
               END
               ELSE IF _UpperCase(parameters[loop])='SYSOP' THEN
               BEGIN
                    SysopLogon := true;
               END
               ELSE IF _UpperCase(parameters[loop])='BIOS' THEN
               BEGIN
                    DirectWrites := False;
               END
               ELSE IF _UpperCase(parameters[loop])='640' THEN
               BEGIN
               END
               ELSE IF _UpperCase(parameters[loop])='800' THEN
               BEGIN
               END
               ELSE IF _UpperCase(parameters[loop])='1024' THEN
               BEGIN
               END
               ELSE IF _UpperCase(parameters[loop])='NOROM' THEN
               BEGIN
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
{FAST USER LOGON}   'U' : VAL(parameters[loop],LogonUser,code);
                    ELSE  DoErrorLog(39,Before);
                    END;
               END;
          END;
     END;
     IF ActualBaud=0 THEN LocalLogon := true;
     IF NOT(LocalLogon) THEN LogonUser := 999999999;
     IF (EventMinutes<>32000) THEN
     BEGIN
          BigCrap := EventMinutes;
          BigCrap := BigCrap*60;
          NewTimerSecs(EventTicker,BigCrap);
     END;
END;


PROCEDURE SelectLanguage;
VAR  Languages  : Word;
     Selectors  : Array[1..25] Of Char;
     SelectOK   : Array[1..25] Of Boolean;
     Loop       : Word;
     C          : Char;
     SelectLang : Byte;
BEGIN
     FOR Loop := 1 TO 25 DO
     BEGIN
          Selectors[Loop] := Chr(48+Loop);
          SelectOK[Loop]  := False;
     END;
     ASSIGN(FLangDir,Shotgun_Directory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     Languages := FileSize(FLangDir);
     CLOSE(FLangDir);
     IF Languages=1 THEN
     BEGIN
          LanguageNum := 1;
          ASSIGN(FLangDir,Shotgun_Directory+'\DATA\LANGUAGE.DAT');
          RESET(FLangDir);
          READ(FLangDir,LangDir);
          CLOSE(FLangDir);
          LanguageDirectory := LangDir.Directory;
     END
     ELSE
     BEGIN
          NewTimerSecs(UsersTicker,system_info.Sys_Idle);
          ASSIGN(FLangDir,Shotgun_Directory+'\DATA\LANGUAGE.DAT');
          RESET(FLangDir);
          Loop := 0;
          REPEAT
                READ(FLangDir,LangDir);
                INC(Loop);
                SelectOK[Loop] := True;
          UNTIL EOF(FLangDir);
          CLOSE(FLangDir);
          DisplayGraphicsFile('LANGSEL',false,false,True,True,False);
          c := GetKeyPress;
          WRITEANSI(c,True,false);
          SendCrLf(1);
          Loop       := 1;
          SelectLang := 0;
          REPEAT
                IF ((Selectors[Loop]=C) AND (SelectOK[Loop])) THEN SelectLang := Loop;
                INC(Loop);
          UNTIL ((Loop=26) OR (SelectLang<>0));
          IF SelectLang=0 THEN SelectLang := 1;
          ASSIGN(FLangDir,Shotgun_Directory+'\DATA\LANGUAGE.DAT');
          RESET(FLangDir);
          SEEK(FLangDir,SelectLang-1);
          READ(FLangDir,LangDir);
          CLOSE(FLangDir);
          LanguageNum := SelectLang;
          LanguageDirectory := LangDir.Directory;
     END;
     ANSIDirectory         := LanguageDirectory+'ANSI';
     RIPDirectory          := LanguageDirectory+'RIP';
     LANG_Directory        := LanguageDirectory+'LANG';
     MENU_Directory        := LanguageDirectory+'MENUS';
     NEWS_Directory        := LanguageDirectory+'NEWS';

     ASSIGN(FColours,LANG_Directory+'\COLOURS.ANS');
     RESET(FColours);
     READ(FColours,Colours);
     CLOSE(FColours);
END;


PROCEDURE CantDoIt(TheOne: Longint);
BEGIN
     DoErrorLog(40,_String(TheOne));
     TEXTCOLOR(7);
     ClrScr;
     WRITELN('CRITICAL ERROR!!! Shotgun can only handle 255 lines!');
     WRITELN;
     Halt;
END;


PROCEDURE FireUpSystem;
VAR  Loop : Word;
     Temp : String;
BEGIN
     GetDir(0,Temp);
     CurrentDrive := Temp[1];
     ClrScr;
     doing_logon  := true;
     NodeNumber   := 1;
     STR(NodeNumber,NodeString);
     Shotgun_Directory := _UpperCase(_GetFilePath(ParamStr(0)));
     IF Shotgun_Directory[Length(Shotgun_Directory)]='\' THEN Dec(Shotgun_Directory[0]);
     ChDir(shotgun_directory);
     get_params;
     HighVideo;
     Textcolor(7);
     Textbackground(0);
     ClrScr;
     TextMode(C80);
     Window(1,1,80,24);
     IF NOT(DirectWrites) THEN DirectVideo := False;
     _CreatePath(shotgun_directory+'\NODE'+NodeString);
     IF (NodeNumber>255) THEN CantDoIt(NodeNumber);
     CheckRegistered(shotgun_directory+'\NODE'+NodeString,'Shotgun');
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


PROCEDURE select_video;
VAR  c        : Char;
     Temp     : String;
     Error    : Integer;
     TFile    : Text;
     TTT      : EventTimer;
     Loop     : Word;
     PPointer : Word;
LABEL           TryAgain,Continue,Continue2,Continue3;
LABEL           RIPAllTheWay,ANSIAllTheWay,SgAllTheWay,SgAllTheWay2;

     FUNCTION Gatherit: String;
     VAR  Crap   : String;
          TTTT   : EventTimer;
          LetsGo : Boolean;
     BEGIN
          Crap   := '';
          LetsGo := False;
          NewTimerSecs(TTTT,20);
          REPEAT
                IF CharReady(BBSPort) THEN
                BEGIN
                     GetChar(BBSPort,C);
                     Crap := Crap+C;
                END
                ELSE
                BEGIN
                     IF CheckDCD(BBSPort) THEN TimeSlice
                                          ELSE Dispatcher(2);
                END;
                IF Pos(#255#255#13,Crap)<>0 THEN LetsGo := True;
                IF Pos('RIPSCRIP015410',Crap)<>0 THEN LetsGo := True;
                IF ((Pos(Chr(27),Crap)<>0) AND (Pos('R',Crap)<>0)) THEN
                BEGIN
                     _Delay(250);
                     IF NOT(CharReady(BBSPort)) THEN LetsGo := True;
                END;
          UNTIL ((TimerExpired(TTTT)) OR (LetsGo));
          GatherIt := Crap;
     END;

BEGIN
     UserRecord.Ibm  := 1;
     IsRip           := False;
     RipInitialized  := False;
     Temp            := '';
     {SEND AUTO DETECTS}
     IF NOT(LocalLogon) THEN
     BEGIN
          ClearInBuffer;
          IF ((NodeInfo.SVGAOk=1) AND (NodeInfo.AutoSVGALogin=1)) THEN PutStringTimeout(BBSPort,#255#0#13,162);
          IF NodeInfo.RIPOk=1  THEN PutStringTimeout(BBSPort,chr(27)+'[!'+#13,162);
          IF NodeInfo.ANSIOk=1 THEN PutStringTimeout(BBSPort,chr(27)+'[6n'+#13,162);
          Temp := GatherIt;
          IF Pos(#255,Temp)<>0 THEN
          BEGIN {SVGA AUTODETECT}
            IF NodeInfo.AutoSVGALogin=1 THEN
            BEGIN
              TEXTCOLOR(14);
              WRITELN('YAPP Client Detect Complete');
              TEXTCOLOR(7);
              GOTO SgAllTheWay2;
            END;
          END
          ELSE IF Pos('RIPSCRIP015410',Temp)<>0 THEN
          BEGIN {RIP AUTODETECT}
            IsRip := True;
            IF NodeInfo.AutoRIPLogin=1 THEN GOTO RipAllTheWay;
          END
          ELSE IF Pos(Chr(27),Temp)<>0 THEN
          BEGIN {ANSI AUTODETECT}
            IF Pos('R',Temp)<>0 THEN
            BEGIN
              IF NodeInfo.AutoANSILogin=1 THEN GOTO ANSIAllTheWay;
            END;
          END;
          _Delay(1000);
          ClearInBuffer;
     END;
     TryAgain:
     DisplayGraphicsFile('VIDEO',false,false,True,True,False);
     Temp := '';
     ASSIGN(FShuttle,LANG_Directory+'\SHUTTLE.DAT');
     RESET(FShuttle);
     REPEAT
           READ(FShuttle,Shuttle);
           CASE Shuttle.Action OF
           1:   IF NodeInfo.ANSIOk=1 THEN Temp := Temp+Shuttle.KeyPress;
           2:   IF NodeInfo.TTYOk=1 THEN Temp := Temp+Shuttle.KeyPress;
           3:   IF NodeInfo.RIPOk=1 THEN Temp := Temp+Shuttle.KeyPress;
           4:   IF NodeInfo.SVGAOk=1 THEN Temp := Temp+Shuttle.KeyPress+#255;
           5:   Temp := Temp+Shuttle.KeyPress;
           6:   Temp := Temp+Shuttle.KeyPress;
           7:   Temp := Temp+Shuttle.KeyPress;
           8:   Temp := Temp+Shuttle.KeyPress;
           END;
     UNTIL EOF(FShuttle);
     CLOSE(FShuttle);
     Input_Key := UpCase(Get_Menu_Selection(Temp,Chr(0)));
     IF Input_Key=#255 THEN GOTO SgAllTheWay;
     ASSIGN(FShuttle,LANG_Directory+'\SHUTTLE.DAT');
     RESET(FShuttle);
     REPEAT
           READ(FShuttle,Shuttle);
     UNTIL ((EOF(FShuttle)) OR (Shuttle.KeyPress=Input_Key));
     CLOSE(FShuttle);
     CASE Shuttle.Action OF
     1:   BEGIN {ANSI}
               ANSIAllTheWay:
               ClearInBuffer;
               IsRip := False;
               RipInitialized := False;
               IF (system_info.ANSIExit<>0) THEN
               BEGIN
                    _EraseFile(INTR_Directory+'\NODE'+NodeString+'.$$$');
                    WINDOW(1,1,80,25);
                    TextBackGround(0);
                    TextColor(7);
                    ClrScr;
                    ClearNode;
                    IF NOT(LocalLogon) THEN Comm_DeInit;
                    Halt(system_info.ANSIExit);
               END;
          END;
     2:   BEGIN {ASCII}
            GOTO TryAgain;
          END;
     3:   BEGIN {RIP}
               RipAllTheWay:
               ClearInBuffer;
               ISRip := True;
               New(RIP,Init(True,BIN_Directory+'\GFXPACK'));
               RipInitialized := True;
          END;
     4:   BEGIN {SVGA}
               SendCrLf(1);
               SgAllTheWay:
               IsRip := False;
               RipInitialized := False;
               {Tell The Remote To Go To Graphics Mode}
               IF NOT(LocalLogon) THEN
               BEGIN
                    PutString(BBSPort,#255#0#13);
                    Temp := '';
                    C    := #0;
                    NewTimerSecs(TTT,60);
                    REPEAT
                          IF CharReady(BBSPort) THEN
                          BEGIN
                               GetChar(BBSPort,C);
                               Temp := Temp+C;
                          END
                          ELSE
                          BEGIN
                               IF CheckDCD(BBSPort) THEN TimeSlice
                                                    ELSE Dispatcher(2);
                          END;
                    UNTIL ((Pos(#255#255#13,Temp)<>0) OR (TimerExpired(TTT)));
                    IF (Pos(#255#255#13,Temp)=0) THEN
                    BEGIN
                         Back(0);
                         Fore(3);
                         SendCrLf(1);
                         WRITEANSI('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',True,True);
                         WRITEANSI('³  YAPP Protocol System Not Detected  ³',True,True);
                         WRITEANSI('³     Connection not established.     ³',True,True);
                         WRITEANSI('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',True,True);
                         Fore(7);
                         SendCrLf(1);
                         Get_Enter;
                         GOTO TryAgain;
                    END;
               END;
               SgAllTheWay2:
               ASSIGN(TFile,NODE_Directory+'\LANGUAGE.SEL');
               REWRITE(TFile);
               Temp := _String(LanguageNum);
               WRITELN(TFile,Temp);
               CLOSE(TFile);
               DISPOSE(WorkBuffer);
               DISPOSE(Menu);
               IF NOT(LocalLogon) THEN
               BEGIN
                    Comm_DeInit;
                    PPointer := DoExec(BIN_Directory+'\GSXCOMM.EXE',CommandLine,SwappingMethod,NODE_Directory);
               END
               ELSE PPointer := DoExec(BIN_Directory+'\GSXLOCAL.EXE',CommandLine,SwappingMethod,NODE_Directory);
               IF PPointer=0 THEN PPointer := DosExitCode;
               Halt(PPointer);
          END;
     5:   BEGIN {DOWNLOAD A FILE}
               SendCrLf(1);
               IF _FileExists(Shuttle.Text) THEN dl_file(Shuttle.Text);
               TextBackground(0);
               TextColor(7);
               GOTO TryAgain;
          END;
     6:   BEGIN
               bsWriteLog('Shuttle menu errorlevel exit: '+_String(Shuttle.ErrorLevel),False);
               IF NOT(LocalLogon) THEN Comm_DeInit;
               SendCrLf(1);
               Halt(Shuttle.ErrorLevel);
          END;
     7:   BEGIN
               bsWriteLog('User logged off from shuttle menu',False);
               SendCrLf(1);
               IF NOT(LocalLogon) THEN
               BEGIN
                    Hangup;
                    Comm_deinit;
               END;
               Halt;
          END;
     8:   BEGIN
               SendCrLf(1);
               IF _FileExists(Shuttle.Text) THEN view_text_file(Shuttle.Text,_NoPath(Shuttle.Text));
               TextBackground(0);
               TextColor(7);
               GOTO TryAgain;
          END;
     END;
END;


PROCEDURE DoOpeningFile;
VAR  OldAccess   : Word;
BEGIN
     ASSIGN(FOpening,LANG_Directory+'\OPENING.DAT');
     RESET(FOpening);
     REPEAT
           READ(FOpening,Opening);
           CASE Opening.FunctionType OF
           1:   BEGIN
                     SendCrLf(1);
                     ShowLastComment;
                     SendCrLf(1);
                END;
           2:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',126,false,false);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               Do_Welcome;
                               ClrPortScr;
                          END
                          ELSE SendCrLf(1);
                     END;
                1:   BEGIN
                          do_welcome;
                          ClrPortScr;
                     END;
                END;
           3:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',127,false,false);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               Do_Once_Only;
                               ClrPortScr;
                          END
                          ELSE SendCrLf(1);
                     END;
                1:   BEGIN
                          do_once_only;
                          ClrPortScr;
                     END;
                END;
           4:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',128,false,false);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               Do_News;
                               ClrPortScr;
                          END
                          ELSE SendCrLf(1);
                     END;
                1:   BEGIN
                          do_news;
                          ClrPortScr;
                     END;
                END;
           5:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',129,false,false);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               show_last_Callers;
                               ClrPortScr;
                          END
                          ELSE SendCrLf(1);
                     END;
                1:   BEGIN
                          show_last_Callers;
                          ClrPortScr;
                     END;
                END;
           6:   CASE Opening.Forced OF
                0:   BEGIN
                          System_Prompt('',118,false,false);
                          IF GET_YES_NO=true THEN
                          BEGIN
                               SendCrLf(1);
                               CurrentMessageSub := 0;
                               New_Mail_Logon;
                               CurrentMessageSub := 1;
                               SendCrLf(1);
                          END
                          ELSE SendCrLf(1);
                     END;
                1:   BEGIN
                          SendCrLf(1);
                          CurrentMessageSub := 0;
                          New_Mail_Logon;
                          CurrentMessageSub := 1;
                          SendCrLf(1);
                     END;
                END;
           7:   CASE Opening.Forced OF
                0:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               System_Prompt('',117,false,false);
                               IF GET_YES_NO=true THEN
                               BEGIN
                                    SendCrLf(1);
                                    CurrentFileSub := 0;
                                    search_new(True);
                                    List_Files(NODE_Directory+'\SEARCH$$');
                                    CurrentFileSub := 1;
                                    SendCrLf(1);
                               END
                               ELSE SendCrLf(1);
                          END;
                     END;
                1:   BEGIN
                          IF UserRecord.Total_Calls<>0 THEN
                          BEGIN
                               SendCrLf(1);
                               CurrentFileSub := 0;
                               search_new(True);
                               List_Files(NODE_Directory+'\SEARCH$$');
                               CurrentFileSub := 1;
                               SendCrLf(1);
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
                     ClrPortScr;
                END;
           9:   BEGIN
                     show_user_specific;
                     ClrPortScr;
                END;
           10:  BEGIN
                     do_user_access;
                     ClrPortScr;
                END;
           11:  BEGIN
                     do_date_specific;
                     ClrPortScr;
                END;
           12:  BEGIN
                     do_birthday;
                     ClrPortScr;
                END;
           END;
     UNTIL EOF(FOpening);
     CLOSE(FOpening);
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
               bsWriteLog('No new users allowed to this node',False);
               SendCrLf(1);
               DisplayGraphicsFile('NONEW',True,False,False,True,False);
               Get_Enter;
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
                    bsWriteLog('User is already logged in on another node',False);
                    SendCrLf(1);
                    DisplayGraphicsFile('NODOUBLE',True,False,False,True,False);
                    Dispatcher(5);
               END
               ELSE Exit;
          END
          ELSE
          BEGIN
               bsWriteLog('User doesn''t have high enough access for this node',False);
               SendCrLf(1);
               DisplayGraphicsFile('NOACCESS',True,False,False,True,False);
               Dispatcher(5);
          END;
     END;
END;


PROCEDURE do_logon;
VAR  bad_pass       : byte;
     success        : boolean;
     old_time_left  : longint;
     c              : Char;
     Temp           : String;
LABEL                 redo,redo2,Redo3;
BEGIN
     CASE _OverlayBufLoc OF
     1:   Temp := '[XMS]';
     2:   Temp := '[EMS]';
     3:   Temp := '[DISK]';
     ELSE Temp := '[Error]';
     END;
     bsWriteLog('Overlay buffer: '+_String(_OverLayBufferSize)+' bytes '+Temp,False);
     bsWriteLog('User logging on at '+BaudString+' BPS',False);
     IF NOT(SysopLogon) THEN
     BEGIN
          DisplayGraphicsFile('PRELOG',true,false,True,True,False);
          SendCrLf(1);
     END;
     SuccessfulLogon := False;
     redo:
     IF (LogonUser<>999999999) THEN
     BEGIN
          User_Name := GetUserName(LogonUser);
     END
     ELSE IF SysopLogon THEN
     BEGIN
          User_Name := system_info.Sysop;
     END
     ELSE
     BEGIN
          REPEAT
                System_Prompt('',113,false,true);
                ClearInBuffer;
                get_name(30,'',true,True);
                SendCrLf(1);
                user_name := input_string;
                IF _UpperCase(user_name)='SYSOP' THEN user_name := '';
                IF Pos(' ',user_name)=0 THEN
                BEGIN
                     IF NOT(system_info.alias_system) THEN user_name := '';
                END;
          UNTIL (user_name<>'');
     END;
     bsWriteLog('User claims to be '+user_name,False);
     IF UserFound THEN
     BEGIN
          CheckLogonAccess(False);
          old_time_left := UserRecord.SecondsRemaining;
          bad_pass := 0;
          success  := false;
          REPEAT
                IF ((SysopLogon) OR (LogonUser<>999999999)) THEN
                BEGIN
                     Input_String := UserRecord.password;
                END
                ELSE
                BEGIN
                     System_Prompt('',63,false,true);
                     Get_Password(20,'',true,True);
                     SendCrLf(1);
                     input_string := _UpperCase(input_string);
                END;
                IF input_string=UserRecord.password THEN
                BEGIN
                     INC(UserRecord.total_calls);
                     RealLastCall := UserRecord.last_call;
                     UserRecord.last_call := _ProperDate;
                     bad_pass := 0;
                     success  := true;
                END
                ELSE
                BEGIN
                     bsWriteLog('Guessing at password',False);
                     success := false;
                     INC(bad_pass);
                     SendCrLf(1);
                     IF Bad_Pass<>3 THEN System_Prompt('',64,true,false);
                     SendCrLf(1);
                END;
          UNTIL ((success) OR (bad_pass=3));
          IF bad_pass=3 THEN
          BEGIN
               UserRecord.bad_logon := 1;
               UserRecord.SecondsRemaining := old_time_left;
               WriteUser;
               dispatcher(6);
          END;
          IF UserRecord.bad_logon<>0 THEN
          BEGIN
               bsWriteLog('Last logon was unsuccessful',False);
               SendCrLf(1);
               DisplayGraphicsFile('BADLOGON',true,false,True,True,False);
               SendCrLf(1);
               Get_Enter;
          END;
          IF UserRecord.Punt=1 THEN
          BEGIN
               bsWriteLog('User is not allowed on the system',False);
               SendCrLf(1);
               DisplayGraphicsFile('BOOTUSER',true,false,True,True,False);
               SendCrLf(1);
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
          SendCrLf(1);
          System_Prompt('',114,true,false);
          System_Prompt(user_name,115,false,false);
          IF Get_Yes_No=False THEN
          BEGIN
               bsWriteLog('User is guessing at his/her name. Entered: '+user_name,False);
               SendCrLf(2);
               GOTO redo;
          END;
          bsWriteLog('New user logging on',False);
          new_user;
     END;
     DoNodeActivity(0,'');
     LastUserOnline.TimeOn := _GetPrettyDate+' - '+_GetPrettyTime;
     IF UserRecord.SecondsRemaining=0 THEN
     BEGIN
          SendCrLf(2);
          DisplayGraphicsFile('TIMEUP',true,false,True,True,False);
          dispatcher(3);
     END;
     CheckCIDInfo;
     Subscription;
     doing_logon := false;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     TimeLimit;
     IF Pos(' ',User_Name)=0 THEN user_name := user_name+' NLN';
     clrportscr;
     SuccessfulLogon := True;
     bsWriteLog('Successful log on as: '+user_name,False);
     IF (EventMinutes<>32000) THEN
     BEGIN
          bsWriteLog('Next event in '+_String(EventMinutes)+' minutes',False);
          bsWriteLog('Event timer set at '+_String(BigCrap),False);
     END;
     IF _FileExists('PRELOG.BAT') THEN
     BEGIN
          DumpUser;
          make_door_files(0,1);
          ExecuteDosCommand('PRELOG.BAT '+NodeString+' '+ComString+' '+BaudString);
          Chdir(Shotgun_Directory);
          ReloadUser;
     END;
END;


PROCEDURE Intro;
VAR  StatsBaud  : _Stats_Baud;
     FStatsBaud : File Of _Stats_Baud;
     Work       : Longint;
     WroteIt    : Boolean;
BEGIN
     IF (ActualBaud<>0) THEN
     BEGIN
       ASSIGN(FStatsBaud,DATA_Directory+'\STATSBAUD.DAT');
       {$I-}RESET(FStatsBaud);{$I+}
       IF IOResult=0 THEN
       BEGIN
         Work := 0;
         WroteIt := False;
         REPEAT
           READ(FStatsBaud,StatsBaud);
           IF StatsBaud.ConnectRate=ActualBaud THEN
           BEGIN
             INC(StatsBaud.ConnectCount);
             SEEK(FStatsBaud,Work);
             WRITE(FStatsBaud,StatsBaud);
             WroteIt := True;
           END;
           INC(Work);
         UNTIL EOF(FStatsBaud);
         IF NOT(WroteIt) THEN
         BEGIN
           StatsBaud.ConnectRate  := ActualBaud;
           StatsBaud.ConnectCount := 1;
           SEEK(FStatsBaud,FileSize(FStatsBaud));
           WRITE(FStatsBaud,StatsBaud);
         END;
         CLOSE(FStatsBaud);
       END
       ELSE
       BEGIN
         StatsBaud.ConnectRate  := ActualBaud;
         StatsBaud.ConnectCount := 1;
         REWRITE(FStatsBaud);
         WRITE(FStatsBaud,StatsBaud);
         CLOSE(FStatsBaud);
       END;
     END;
     CASE System_Info.SwapMethod OF
     1:   SwappingMethod := USE_EMS or USE_XMS;
     2:   SwappingMethod := USE_ALL;
     3:   SwappingMethod := USE_FILE or CHECK_NET;
     END;
     BaudString       := _String(ActualBaud);
     ComString        := _String(NodeInfo.ComPort);
     LockedBaudString := _String(ReturnRate(NodeInfo.BaudRate,NodeInfo.ComDevice));
     SelectLanguage;
     select_video;
     ClrPortScr;
     IF IsRip THEN bsWriteLog('RIP interface selected',False)
              ELSE bsWriteLog('ANSI interface selected',False);
     IF NOT(LocalLogon) THEN cps := TRUNC(ActualBaud/10)
                        ELSE cps := 1650;
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


PROCEDURE new_user;
VAR  proceed : boolean;
     c       : Char;
BEGIN
     FillChar(UserRecord,SizeOf(UserRecord),0);
     SetUsersAccessDefaults(system_info.access_new_user);
     UserRecord.name := user_name;
     UserRecord.user_number := new_user_number;
     UserRecord.Birth := '000000';
     ASSIGN(FNewUserANSI,LANG_Directory+'\NEWUSER.ANS');
     RESET(FNewUserANSI);
     REPEAT
           READ(FNewUserANSI,NewUserANSI);
           CASE NewUserANSI.FunctionType OF
           1:   BEGIN
                     DisplayGraphicsFile(NewUserANSI.FileName,True,False,True,True,False);
                     SendCrLf(1);
                END;
           2:   BEGIN
                     System_Prompt('',145,False,true);
                     Fore(15);
                     Get_Password(20,'',true,True);
                     UserRecord.password := _UpperCase(INPUT_STRING);
                     SendCrLf(1);
                END;
           3:   BEGIN
                     proceed := false;
                     REPEAT
                           System_Prompt('',146,False,true);
                           Fore(15);
                           Get_Password(20,'',true,True);
                           Input_String := _UpperCase(Input_String);
                           SendCrLf(1);
                           IF input_string<>UserRecord.password THEN
                           BEGIN
                                SendCrLf(1);
                                DisplayGraphicsFile('QUEST1',True,False,True,True,False);
                                SendCrLf(1);
                                System_Prompt('',145,False,true);
                                Fore(15);
                                Get_Password(20,'',true,True);
                                UserRecord.password := _UpperCase(INPUT_STRING);
                                SendCrLf(1);
                           END
                           ELSE Proceed := true;
                     UNTIL proceed;
                END;
           4:   BEGIN
                     System_Prompt('',147,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_String(20,'',true,true,false,False);
                     1:   Get_String(20,'',true,true,false,True);
                     END;
                     UserRecord.data := PhoneNumber(Input_String);
                     SendCrLf(1);
                END;
           5:   BEGIN
                     System_Prompt('',148,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_String(20,'',true,true,false,False);
                     1:   Get_String(20,'',true,true,false,True);
                     END;
                     UserRecord.voice := PhoneNumber(Input_String);
                     SendCrLf(1);
                END;
           6:   BEGIN
                     System_Prompt('',149,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_Name(30,'',true,False);
                     1:   Get_Name(30,'',true,True);
                     END;
                     UserRecord.street := Input_String;
                     SendCrLf(1);
                END;
           7:   BEGIN
                     System_Prompt('',150,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_Name(30,'',true,False);
                     1:   Get_Name(30,'',true,True);
                     END;
                     UserRecord.city := Input_String;
                     SendCrLf(1);
                END;
           8:   BEGIN
                     System_Prompt('',151,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_Name(30,'',true,False);
                     1:   Get_Name(30,'',true,True);
                     END;
                     UserRecord.Prov := Input_String;
                     SendCrLf(1);
                END;
           9:   BEGIN
                     System_Prompt('',152,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_Name(30,'',true,False);
                     1:   Get_Name(30,'',true,True);
                     END;
                     UserRecord.Country := Input_String;
                     SendCrLf(1);
                END;
           10:  BEGIN
                     System_Prompt('',153,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_String(20,'',true,false,true,False);
                     1:   Get_String(20,'',true,false,true,True);
                     END;
                     UserRecord.postal := Input_String;
                     SendCrLf(1);
                END;
           11:  IF System_Info.Alias_System THEN
                BEGIN
                     proceed := false;
                     REPEAT
                           System_Prompt('',157,False,true);
                           CASE NewUserANSI.Required OF
                           0:   Get_Name(30,'',true,False);
                           1:   Get_Name(30,'',true,True);
                           END;
                           SendCrLf(1);
                           UserRecord.Alias := Input_String;
                           IF UserRecord.Alias<>'' THEN
                           BEGIN
                                IF AliasExists THEN
                                BEGIN
                                     SendCrLf(1);
                                     DisplayGraphicsFile('QUEST2',True,False,True,True,False);
                                     SendCrLf(1);
                                END
                                ELSE proceed := true;
                           END
                           ELSE IF (NewUserANSI.Required=0) THEN proceed := true;
                     UNTIL proceed;
                END;
           12:  BEGIN
                     System_Prompt('',158,False,true);
                     CASE NewUserANSI.Required OF
                     0:   GetADate('',False);
                     1:   GetADate('',True);
                     END;
                     UserRecord.birth := _Mid(input_string,1,4)+_Mid(input_string,7,8);
                     SendCrLf(1);
                END;
           13:  BEGIN
                     System_Prompt('',159,False,true);
                     C := Get_Menu_Selection(GetCommandKeyPress('MISC',3)+
                                             GetCommandKeyPress('MISC',4),
                                             GetCommandKeyPress('MISC',3));
                     IF UpCase(C)=GetCommandKeyPress('MISC',3) THEN UserRecord.Sex := 1
                                                               ELSE UserRecord.Sex := 0;
                     SendCrLf(1);
                END;
           14:  BEGIN
                     System_Prompt('',160,False,False);
                     IF Get_Yes_No THEN UserRecord.Ibm := 1
                                   ELSE UserRecord.Ibm := 0;
                     SendCrLf(1);
                END;
           15:  BEGIN
                     System_Prompt('',154,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_Name(30,'',true,False);
                     1:   Get_Name(30,'',true,True);
                     END;
                     UserRecord.bbs := Input_String;
                     SendCrLf(1);
                END;
           16:  BEGIN
                     System_Prompt('',155,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_String(20,'',true,true,false,False);
                     1:   Get_String(20,'',true,true,false,True);
                     END;
                     UserRecord.bbs_phone := Input_String;
                     SendCrLf(1);
                END;
           17:  BEGIN
                     System_Prompt('',156,False,true);
                     CASE NewUserANSI.Required OF
                     0:   Get_String(20,'',true,false,false,False);
                     1:   Get_String(20,'',true,false,false,True);
                     END;
                     UserRecord.bbs_net := Input_String;
                     SendCrLf(1);
                END;
           18:  BEGIN
                     Get_Enter;
                     SendCrLf(1);
                END;
           END;
     UNTIL EOF(FNewUserANSI);
     CLOSE(FNewUserANSI);
     WriteNewUser;
     DoNewUserReport;
END;


END.
