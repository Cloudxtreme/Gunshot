{$I DEFINES.INC}
UNIT QBack;


INTERFACE


FUNCTION  DoSysopPress(CC: Char): Boolean;
PROCEDURE RUN_SHELL;
PROCEDURE EditUser;


IMPLEMENTATION


USES Globals,SaveScrn,ChatFull,NodeFile,LoadMenu,Time,AllGone,Status,
     ANSIMisc,Screens,Crt,ApTimer,Adjust,BsMulti,BsExec,Execute,Dos;


FUNCTION DoSysopPress(CC: Char): Boolean;
VAR  DidSomething : Boolean;
     SavedAct     : Word;
BEGIN
     SavedAct := LastActivity;
     DidSomething := False;
     CASE ORD(cc) OF
     59:  BEGIN {F1 - CHAT WITH USER}
               IF NOT(LocalLogon) THEN
               BEGIN
                    Save_Screen;
                    SysopFullChat;
                    Restore_Screen;
                    DoNodeActivity(SavedAct,'');
                    DidSomething := True;
                    User_Paged := False;
               END;
          END;
     60:  BEGIN {F2 - SHELL TO DOS}
               DoNodeActivity(35,'');
               run_shell;
               DoNodeActivity(SavedAct,'');
               DidSomething := True;
          END;
     61:  BEGIN {F3 - TOGGLE SYSOP NEXT}
               IF NOT(LocalLogon) THEN
               BEGIN
                    IF sysop_next=true THEN sysop_next := false
                                       ELSE sysop_next := true;
                    DidSomething := True;
               END;
          END;
     62:  BEGIN {F4 - EDIT USER'S ACCOUNT}
               IF NOT(LocalLogon) THEN
               BEGIN
                    DoNodeActivity(35,'');
                    EditUser;
                    load_menu(LastMenuLoaded);
                    DoNodeActivity(SavedAct,'');
                    DidSomething := True;
               END;
          END;
     65:  BEGIN {F7 - TAKE AWAY A MINUTE}
               IF NOT(LocalLogon) THEN
               BEGIN
                    AdjustUsersTime(False,60);
                    DidSomething := True;
               END;
          END;
     66:  BEGIN {F8 - GIVE THE USER A MINUTE}
               IF NOT(LocalLogon) THEN
               BEGIN
                    AdjustUsersTime(True,60);
                    DidSomething := True;
               END;
          END;
     68:  BEGIN {F10 - BOOT THE CALLER}
               IF NOT(LocalLogon) THEN
               BEGIN
                    DoNodeActivity(3,'');
                    Dispatcher(5);
               END;
          END;
     END;
     IF DidSomething THEN Status_Line;
     DoSysopPress := DidSomething;
END;


PROCEDURE EditUser;
VAR  c          : char;
     OldX,OldY  : Word;
BEGIN
     Save_Screen;
     SendCrLf(2);
     DisplayGraphicsFile('ADJUST_S',true,False,True,True,False);
     Save_Screen2;
     OldX := WhereX;
     OldY := WhereY;
     UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker);
     WINDOW(1,1,80,25);
     EditTheUsersAccount;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     TimeLimit;
     WINDOW(1,1,80,24);
     Restore_Screen2;
     GotoXY(OldX,OldY);
     DisplayGraphicsFile('ADJUST_E',True,False,True,True,False);
     Chdir(Shotgun_Directory);
     _DELAY(1500);
     REPEAT
           IF KeyPressed THEN c := ReadKey;
     UNTIL NOT(KeyPressed);
     Restore_Screen;
END;


PROCEDURE RUN_SHELL;
VAR  loopx        : word;
     loopy        : word;
     bite         : byte;
     work_it      : string;
     c            : char;
     OldX         : Word;
     OldY         : Word;
BEGIN
     Save_Screen;
     SendCrLf(2);
     DisplayGraphicsFile('SHELL',true,false,True,True,False);
     OldX := WhereX;
     OldY := WhereY;
     Save_Screen2;
     FORE(7);
     WINDOW(1,1,80,25);
     ClrScr;
     PutEnviro('PROMPT=Enter EXIT to return to Shotgun Professional!!$_$p$g');
     ExecuteDosCommand(GetEnv('COMSPEC'));
     Chdir(Shotgun_Directory);
     Restore_Screen2;
     WINDOW(1,1,80,24);
     GotoXY(OldX,OldY);
     DisplayGraphicsFile('RETURN',true,false,True,True,False);
     _DELAY(1500);
     REPEAT
           IF KeyPressed THEN c := ReadKey;
     UNTIL NOT(KeyPressed);
     Restore_Screen;
END;


END.