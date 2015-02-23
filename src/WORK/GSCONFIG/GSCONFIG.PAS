{$IFDEF DPMI}
Hello there???
{$ENDIF}
{$M 60000,0,655360}
PROGRAM GSConfig;


USES BsOvr,Dos,Crt,Intrface,BsMouse,CNFGVARS,Menu1,Menu2,Menu3,Menu4,
     BsMulti,Menu5,Menu6a,Menu6b,Menu7,Menu8a,Menu8b,DosShell,BsString,
     Defaults,Dispatch,FileSort,MsgSort,FMode,BsFile,BsKeys,BsVideo,
     KeyCheck;


{$O CnfgVars }
{$O EComms   }
{$O Defaults }
{$O Def2     }
{$O FileMan  }
{$O Menu1    }
{$O Menu2    }
{$O Menu3    }
{$O Menu4    }
{$O Menu5    }
{$O Menu6a   }
{$O Menu6b   }
{$O Menu7    }
{$O Menu8a   }
{$O Menu8b   }
{$O MenuOpt  }
{$O Shotgun  }


PROCEDURE SetUpMenu;
BEGIN
     Colour.DeskTopColour           := 8;
     Colour.MenuBorder              := 0;
     Colour.MenuBackGround          := 7;
     Colour.MenuForeGround          := 0;
     Colour.MenuHotKey              := 4;
     Colour.MenuHighLightBackGround := 15;
     Colour.MenuHighLightForeGround := 0;
     Colour.MenuHighLightHotKey     := 4;
     Colour.MenuDisabled            := 8;
     Colour.WindowBackGround        := 1;
     Colour.WindowFrame             := 0;
     Colour.WindowHeader            := 9;
     Colour.WindowHeaderText        := 15;
     Colour.WindowClose             := 10;
     Colour.EditDisabled            := 7;
     Colour.EditEnabled             := 14;
     Colour.EditBackGround          := 0;
     {MENU HEADERS}
     AddMenuObject(1,0,Header,' Info '        ,1,23,'');
     AddMenuObject(2,0,Header,' System '      ,1,31,'');
     AddMenuObject(3,0,Header,' Users '       ,1,22,'');
     AddMenuObject(4,0,Header,' Conferences ' ,1,46,'');
     AddMenuObject(5,0,Header,' Files '       ,1,33,'');
     AddMenuObject(6,0,Header,' Menus '       ,1,50,'');
     AddMenuObject(7,0,Header,' Links '       ,1,38,'');
     AddMenuObject(8,0,Header,' Nodes '       ,1,49,'');
     DrawPullDownMenu;
     {INFO MENU}
     AddMenuObject(1,1,Item,' About Shotgun       ',0,ORD('A'),'Version information');
     AddMenuObject(1,2,Item,' Config Setup        ',0,ORD('C'),'Change the configuration environment settings');
     AddMenuObject(1,3,SBar,'                     ',0,0,'');
     AddMenuObject(1,4,Item,' DOS Shell        F2 ',0,ORD('D'),'Shell out temorarily to DOS');
     AddMenuObject(1,5,Item,' Quit Config   ALT-X ',0,ORD('Q'),'Exit the configuration and return to DOS');
     {SYSTEM MENU}
     AddMenuObject(2,1 ,Item,' Site Information   ',0,ORD('S'),'Information including BBS name, sysop etc.');
     AddMenuObject(2,2 ,SBar,'                    ',0,0,'');
     AddMenuObject(2,3 ,Item,' Network Addresses  ',0,ORD('N'),'Information on mail networks');
     AddMenuObject(2,4 ,Item,' Origin Lines       ',0,ORD('O'),'Default origin lines for each mail network');
     AddMenuObject(2,5 ,SBar,'                    ',0,0,'');
     AddMenuObject(2,6 ,Item,' Miscellaneous      ',0,ORD('M'),'Various system settings');
     AddMenuObject(2,7 ,Item,' Call Totals        ',0,ORD('C'),'Your system calls to this date');
     AddMenuObject(2,8 ,Item,' Directories        ',0,ORD('D'),'Directories for miscelaneous functions');
     AddMenuObject(2,9 ,SBar,'                    ',0,0,'');
     AddMenuObject(2,10,Item,' Internal CBV       ',0,ORD('I'),'Settings for using the internal CBV');
     AddMenuObject(2,11,Item,' Verifier Table     ',0,ORD('V'),'Phone number translations for the CBV');
     AddMenuObject(2,12,Item,' Time Bank          ',0,ORD('T'),'Settings for using the internal time bank');
     AddMenuObject(2,13,Item,' Byte Bank          ',0,ORD('B'),'Settings for using the internal byte bank');
     AddMenuObject(2,14,Item,' Advanced Functions ',0,ORD('A'),'Access levels for "sysop" type functions');
     AddMenuObject(2,15,SBar,'                    ',0,0,'');
     AddMenuObject(2,16,Item,' Function Keys      ',0,ORD('F'),'Programmable function keys.');
     AddMenuObject(2,17,Item,' Hidden Dial Info   ',0,ORD('H'),'GSMail hidden dial strings.');
     {USERS MENU}
     AddMenuObject(3,1,Item, ' Userbase Editor        ',0,ORD('U'),'Edit the system''s userbase');
     AddMenuObject(3,2,Item, ' Find User              ',0,ORD('F'),'Find a user in the userbase');
     AddMenuObject(3,3,SBar, '                        ',0,0,'');
     AddMenuObject(3,4,Item, ' Access Levels          ',0,ORD('A'),'Set system access levels and profiles');
     AddMenuObject(3,5,Item, ' New User Settings      ',0,ORD('N'),'Access settings for first time callers');
     AddMenuObject(3,6,SBar, '                        ',0,0,'');
     AddMenuObject(3,7,Item, ' Verified Users         ',0,ORD('V'),'All verified users todate - CBV');
     AddMenuObject(3,8,Item, ' !Search Verified Users ',0,ORD('!'),'Search for verified users - CBV');
     AddMenuObject(3,9,SBar, '                        ',0,0,'');
     AddMenuObject(3,10,Item,' System Names           ',0,ORD('S'),'Names to use for system screens (Real/Alias)');
     {CONFERENCES MENU}
     AddMenuObject(4,1,Item,' Sub Groups        ',0,ORD('S'),'Setup for message conference groups');
     AddMenuObject(4,2,Item,' Message Areas     ',0,ORD('M'),'Setup for individual message areas');
     AddMenuObject(4,3,Item,' Order Areas       ',0,ORD('O'),'Sort the order of the message areas');
     AddMenuObject(4,4,SBar,'                   ',0,0,'');
     AddMenuObject(4,5,Item,' Unwanted Language ',0,ORD('U'),'Edit language to be edited out of message bases');
     AddMenuObject(4,6,Item,' QWK Mail Setup    ',0,ORD('Q'),'Basic setup for the QWK mail packer');
     AddMenuObject(4,7,Item,' Import AREAS.BBS  ',0,ORD('I'),'Import AREAS.BBS file for area updating');
     AddMenuObject(4,8,Item,' Export AREAS.BBS  ',0,ORD('E'),'Export all areas to an AREAS.BBS file');
     AddMenuObject(4,9,SBar,'                   ',0,0,'');
     AddMenuObject(4,10,Item,' Report Generation ',0,ORD('R'),'Settings for various system reports');
     {FILES MENU}
     AddMenuObject(5,1 ,Item,' Sub Groups      ',0,ORD('S'),'Setup for file groups');
     AddMenuObject(5,2 ,Item,' File Areas      ',0,ORD('F'),'Setup for individual file areas');
     AddMenuObject(5,3 ,Item,' Order Areas     ',0,ORD('O'),'Sort the order of the file areas');
     AddMenuObject(5,4 ,SBar,'                 ',0,0,'');
     AddMenuObject(5,5 ,Item,' Protocols       ',0,ORD('P'),'Transfer protocol definitions - for ANSI interface');
     AddMenuObject(5,6 ,Item,' Virus Scanners  ',0,ORD('V'),'Virus scanner information');
     AddMenuObject(5,7 ,Item,' Archivers       ',0,ORD('A'),'Command lines for archive processors');
     AddMenuObject(5,8 ,Item,' !Arc Misc       ',0,ORD('!'),'Misc options for archive use/conversions');
     AddMenuObject(5,9 ,SBar,'                 ',0,0,'');
     AddMenuObject(5,10,Item,' CD Rom Settings ',0,ORD('C'),'CD Rom setup');
     AddMenuObject(5,11,Item,' Disc Titles     ',0,ORD('D'),'CD Rom definitions');
     AddMenuObject(5,12,Item,' Import CD Rom   ',0,ORD('I'),'Import a CD Rom from script file');
     AddMenuObject(5,13,Item,' Remove CD Rom   ',0,ORD('R'),'Remove a CD Rom from the BBS');
     AddMenuObject(5,14,SBar,'                 ',0,0,'');
     AddMenuObject(5,15,Item,' Miscellaneous   ',0,ORD('M'),'Miscellaneous file area options');
     AddMenuObject(5,16,Item,' Export Dirs     ',0,ORD('E'),'Export directories for mailer file requests');
     AddMenuObject(5,17,SBar,'                 ',0,0,'');
     AddMenuObject(5,18,Item,' Hatch File      ',0,ORD('H'),'Hatch a file into a file echo');
     {MENU MENU}
     AddMenuObject(6,1 ,Item,' Change Language    ',0,ORD('C'),'Change the current language');
     AddMenuObject(6,2 ,SBar,'                    ',0,0,'');
     AddMenuObject(6,3 ,Item,' Shuttle Logon     *',0,ORD('S'),'Edit the video selection screen');
     AddMenuObject(6,4 ,Item,' Menu Editor       *',0,ORD('M'),'Edit the menu structure');
     AddMenuObject(6,5 ,Item,' Dump Menus        *',0,ORD('D'),'Dump the menus to a text file');
     AddMenuObject(6,6 ,Item,' ANSI Colours      *',0,ORD('A'),'Edit the system colours - ANSI interface');
     AddMenuObject(6,7 ,Item,' VGA Colours       *',0,ORD('V'),'Edit the system colours - VGA interface');
     AddMenuObject(6,8 ,Item,' Key Commands      *',0,ORD('K'),'Edit system keypresses & strings');
     AddMenuObject(6,9 ,SBar,'                    ',0,0,'');
     AddMenuObject(6,10,Item,' 1. New User ANSI  *',0,ORD('1'),'Edit the new user sequence for ANSI callers');
     AddMenuObject(6,11,Item,' 2. New User SVGA  *',0,ORD('2'),'Edit the new user sequence for SVGA callers');
     AddMenuObject(6,12,Item,' Opening Logon     *',0,ORD('O'),'Edit the post logon sequence to the first menu');
     AddMenuObject(6,13,SBar,'                    ',0,0,'');
     AddMenuObject(6,14,Item,' 3. SVGA Editor    *',0,ORD('3'),'Edit the SVGA screens for this language');
     AddMenuObject(6,15,Item,' 4. RIP Editor     *',0,ORD('4'),'Edit the RIP screens for this language');
     AddMenuObject(6,16,Item,' 5. ANSI Editor    *',0,ORD('5'),'Edit the ANSI screens for this language');
     AddMenuObject(6,17,SBar,'                    ',0,0,'');
     AddMenuObject(6,18,Item,' YAPP Compiler     *',0,ORD('Y'),'Compile the system resources for this language');
     {LINKS MENU}
     AddMenuObject(7,1,Item,' Node Configuration ',0,ORD('N'),'Uplink/downlink manager');
     AddMenuObject(7,2,Item,' UUCP Configuration ',0,ORD('U'),'Configuration for FIDO/UUCP message gating');
     AddMenuObject(7,3,Item,' Quick Phonebook    ',0,ORD('Q'),'Quick alias name nodelist lookups for GSMail');
     AddMenuObject(7,4,Item,' Edit Private Nodes ',0,ORD('E'),'Add/edit additional entries for the nodelist for GSMail');
     AddMenuObject(7,5,SBar,'                    ',0,0,'');
     AddMenuObject(7,6,Item,' Passwords          ',0,ORD('P'),'Session passwords for GSMail');
     AddMenuObject(7,7,SBar,'                    ',0,0,'');
     AddMenuObject(7,8,Item,' GSFile Auto-Purge  ',0,ORD('S'),'Areas that GSFile should auto-kill inbound files');
     AddMenuObject(7,9,SBar,'                    ',0,0,'');
     AddMenuObject(7,10,Item,' Call Routing       ',0,ORD('C'),'GSEcho/GSMail mail packet routing');
     AddMenuObject(7,11,SBar,'                    ',0,0,'');
     AddMenuObject(7,12,Item,' Fax Setup        **',0,ORD('F'),'GSMail fax configuration');
     {NODES MENU}
     AddMenuObject(8,1 ,Item,' Select Node      ',0,ORD('S'),'Select the node ### to edit');
     AddMenuObject(8,2 ,SBar,'                  ',0,0,'');
     AddMenuObject(8,3 ,Item,' Device Setup   **',0,ORD('D'),'Modem configuration for current node');
     AddMenuObject(8,4 ,Item,' Node Options   **',0,ORD('N'),'Video and access settings for current node');
     AddMenuObject(8,5 ,SBar,'                  ',0,0,'');
     AddMenuObject(8,6 ,Item,' Mailer Setup   **',0,ORD('M'),'General options for GSMail');
     AddMenuObject(8,7 ,Item,' Files & Paths  **',0,ORD('F'),'Files and paths associated with GSMail');
     AddMenuObject(8,8 ,Item,' Error Levels   **',0,ORD('E'),'Error level exits for GSMail/WFC');
     AddMenuObject(8,9 ,Item,' Result Codes   **',0,ORD('R'),'Modem result codes for GSMail/WFC');
     AddMenuObject(8,10,Item,' Init - Special **',0,ORD('I'),'Pre-dial inits for GSMail');
     AddMenuObject(8,11,Item,' Local Console  **',0,ORD('L'),'Various console settings for GSMail');
     AddMenuObject(8,12,Item,' CallerID         ',0,ORD('C'),'CallerID support configuration');
     AddMenuObject(8,13,SBar,'                  ',0,0,'');
     AddMenuObject(8,14,Item,' 1. Busy Events **',0,ORD('1'),'GSMail events that take the phone offhook');
     AddMenuObject(8,15,Item,' 2. Exit Events **',0,ORD('2'),'GSMail events that drop to an errorlevel');
     AddMenuObject(8,16,Item,' 3. Mail Events **',0,ORD('3'),'GSMail events that block human callers');
     AddMenuObject(8,17,Item,' 4. Poll Events **',0,ORD('4'),'GSMail events that call other systems');
     AddMenuObject(8,18,Item,' 5. Send Events **',0,ORD('5'),'GSMail events that unhold outbound mail');
     AddMenuObject(8,19,Item,' 6. Freq Events **',0,ORD('6'),'GSMail events that refuse file requests');
END;


FUNCTION LoadUpLanguage: String;
BEGIN
     CheckFile('LANGUAGE.DAT');
     ASSIGN(FLangDir,BaseDirectory+'\DATA\LANGUAGE.DAT');
     RESET(FLangDir);
     READ(FLangDir,LangDir);
     CLOSE(FLangDir);
     LoadUpLanguage := LangDir.Directory;
END;


FUNCTION Path(Work: String): String;
BEGIN
     IF Work<>'' THEN
     BEGIN
          IF Work[LENGTH(Work)]='\' THEN Work := _Mid(Work,1,LENGTH(Work)-1);
     END;
     Path := Work;
END;


VAR  SuperCrap : String;


BEGIN
     FileMode := SetFileMode;
     BaseDirectory := _UpperCase(_GetFilePath(ParamStr(0)));
     BaseDirectory := Path(BaseDirectory);
     ChDir(BaseDirectory);
     WorkDir := BaseDirectory+'\!1';
     IF _Mid(_UpperCase(ParamStr(1)),1,2)='-N' THEN
     BEGIN
          SuperCrap := ParamStr(1);
          Delete(SuperCrap,1,2);
          CurrentNode := _Numeric(SuperCrap);
     END;
     _CreatePath(WorkDir);
     CheckRegistered(WorkDir,'GSFile');
     IF NOT(IsItRegistered) THEN
     BEGIN
          _NukeDir(WorkDir,False);
          Halt;
     END;
     OriginalMode := LastMode;
     HighVideo;
     TextMode(C80);
     ClrScr;
     ProgramFinished := False;
     New(Buttons);
     New(Objects);
     New(FileInfo);
     New(FileInfo2);
     New(CBVSetup);
     DoingMessageEdit := False;
     DoingMessageChange := False;
     _InitMouse;
     MouseSpeed;
     _ShowMouse;
     _HideCursor;
     _HighBackGrounds(True);
     SetUpMenu;
     SelectedLanguage := Path(LoadUpLanguage);
     CheckAllFiles;
     DrawLanguage;
     ASSIGN(FSystem_Info,BaseDirectory+'\DATA\SYSTEM.DAT');
     RESET(FSystem_Info);
     READ(FSystem_Info,System_Info);
     CLOSE(FSystem_Info);
     ActiveMenu := 1;
     Activate(ActiveMenu);
     SelectItem := 1;
     DrawSelected(ActiveMenu,SelectItem);
     REPEAT
           Memory;
           DoMenus;
           _SaveWindow(WorkDir+'\MAIN.SCR');
           CASE ActiveMenu OF
           1:   CASE SelectItem OF
                1:   DoAbout;
                2:   DoConfigSetup;
                4:   ShellToDos;
                5:   ProgramFinished := True;
                END;
           2:   CASE SelectItem OF
                1:   DoSiteInfo;
                3:   DoNetWorkInfo;
                4:   DoNetOrigins;
                6:   DoSystemMisc;
                7:   DoCallTotals;
                8:   DoDirectories;
                10:  DoCallBack;
                11:  DoVerifierTranslations;
                12:  DoTimeBank;
                13:  DoByteBank;
                14:  DoSysopFunctions;
                16:  DoFunctionKeys;
                17:  DoHiddenDialInfo;
                END;
           3:   CASE SelectItem OF
                1:   DoUserBaseEditor;
                2:   DoFindUser;
                4:   DoAccessLevels;
                5:   DoNewUser;
                7:   DoVerifiedUsers;
                8:   SearchVerifiedUsers;
                10:  DoSystemNames;
                END;
           4:   CASE SelectItem OF
                1:   DoMessageSubs;
                2:   DoMessageAreas;
                3:   DoMessageOrder;
                5:   DoBadLanguage;
                6:   DoQWKSetup;
                7:   DoAreasBBSImport;
                8:   DoAreasBBSExport;
                10:  DoSystemReports;
                END;
           5:   CASE SelectItem OF
                1:   DoFileSubs;
                2:   DoFileAreas;
                3:   DoFileOrder;
                5:   DoProtocols;
                6:   DoScannerDefs;
                7:   DoArcDefs;
                8:   DoArcConversions;
                10:  DoCDRomManager;
                11:  DoCDRomDefinitions;
                12:  DoImportCDRom;
                13:  DoRemoveCDRom;
                15:  DoMiscFileAreas;
                16:  DoExportDirs;
                18:  DoFileHatch;
                END;
           6:   CASE SelectItem OF
                1:   BEGIN
                          WorkingString := DoLanguage;
                          IF WorkingString<>'' THEN SelectedLanguage := Path(WorkingString);
                     END;
                3:   DoShuttle;
                4:   BEGIN
                          REPEAT
                                EditMenuFile := DoSelectMenu(SelectedLanguage);
                                IF EditMenuFile<>'' THEN DoEditMenu(SelectedLanguage+'\MENUS\'+EditMenuFile);
                          UNTIL EditMenuFile='';
                     END;
                5:   DoDumpMenus;
                6:   DoAnsiColours;
                7:   DoVgaColours;
                8:   DoKeyCommands;
                10:  DoNewUserANSI;
                11:  DoNewUserSVGA;
                12:  DoOpeningSequence;
                14:  DoGrafEdit;
                15:  DoRIPEdit;
                16:  DoANSIEdit;
                18:  DoYappCompiler;
                END;
           7:   CASE SelectItem OF
                1:   DoLinkManager;
                2:   DoUUCP;
                3:   DoPhoneBook;
                4:   DoEditNodes;
                6:   DoSessionPassword;
                8:   DoGSFileKill;
                10:  DoCallRouting;
                12:  DoFaxSetup;
                END;
           8:   CASE SelectItem OF
                1:   DoNodeSelect;
                3:   DoModemSetup;
                4:   DoVideoEmulations;
                6:   DoMailer;
                7:   DoMailerFiles;
                8:   DoErrorLevels;
                9:   DoResultCodes;
                10:  DoSpecialInits;
                11:  DoLocalConsole;
                12:  DoCallerId;
                14:  DoDropEvents;
                15:  DoExitEvents;
                16:  DoMailEvents;
                17:  DoPollEvents;
                18:  DoSendEvents;
                19:  DoFreqEvents;
                END;
           END;
           LoadWindow(WorkDir+'\MAIN.SCR');
           DrawLanguage;
     UNTIL ProgramFinished;
     ShutDown;
END.