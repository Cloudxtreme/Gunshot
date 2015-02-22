{$I DEFINES.INC}
UNIT QBack;


INTERFACE


FUNCTION  DoSysopPress(CC: Char): Boolean;
PROCEDURE RUN_SHELL;
PROCEDURE EditUser;


IMPLEMENTATION


USES ApPort,ApCom,SaveScrn,ApTimer,Crt,Globals,NodeFile,
     Execute,Dos,Adjust,Time,LoadMenu,AllGone,Status,BsExec;


PROCEDURE RUN_SHELL;
VAR  c     : char;
     Temp  : String;
     TFile : Text;
BEGIN
     ASSIGN(TFile,SGDirectory+'\SHELL.TXT');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READLN(TFile,Temp);
          CLOSE(TFile);
     END
     ELSE Temp := 'The sysop is shelling out to DOS.';
     PutStringTimeout(BBSPort,#255#123+Temp+#13,YappDelay);
     Save_Screen2;
     TextBackground(0);
     TextColor(7);
     Window(1,1,80,25);
     ClrScr;
     PutEnviro('PROMPT=Enter EXIT to return to Shotgun Professional!!$_$p$g');
     ExecuteDosCommand(GetEnv('COMSPEC'));
     Chdir(Shotgun_Directory);
     REPEAT
           IF KeyPressed THEN c := ReadKey;
     UNTIL NOT(KeyPressed);
     Window(1,1,80,24);
     Restore_Screen2;
     PutCharTimeout(BBSPort,#13,YappDelay);
END;


PROCEDURE EditUser;
VAR  c     : char;
     Temp  : String;
     TFile : Text;
BEGIN
     ASSIGN(TFile,SGDirectory+'\ADJUST_S.TXT');
     {$I-}RESET(TFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          READLN(TFile,Temp);
          CLOSE(TFile);
     END
     ELSE Temp := 'The sysop is adjusting your account.';
     PutStringTimeout(BBSPort,#255#123+Temp+#13,YappDelay);
     Save_Screen2;
     UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker);
     EditTheUsersAccount;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     TimeLimit;
     REPEAT
           IF KeyPressed THEN c := ReadKey;
     UNTIL NOT(KeyPressed);
     Restore_Screen2;
     PutCharTimeout(BBSPort,#13,YappDelay);
END;


FUNCTION DoSysopPress(CC: Char): Boolean;
VAR  DidSomething : Boolean;
     SavedAct     : Word;
BEGIN
     SavedAct := LastActivity;
     DidSomething := False;
     CASE ORD(cc) OF
     59:  BEGIN {F1 - CHAT WITH USER}
               RunTheChat := True;
               DidSomething := True;
               User_Paged := False;
          END;
     60:  BEGIN {F2 - SHELL TO DOS}
               DoNodeActivity(35,'');
               run_shell;
               DoNodeActivity(SavedAct,'');
               DidSomething := True;
          END;
     61:  BEGIN {F3 - TOGGLE SYSOP NEXT}
               IF sysop_next=true THEN sysop_next := false
                                  ELSE sysop_next := true;
               DidSomething := True;
          END;
     62:  BEGIN {F4 - EDIT USER'S ACCOUNT}
               DoNodeActivity(35,'');
               EditUser;
               load_menu(LastMenuLoaded);
               DoNodeActivity(SavedAct,'');
               DidSomething := True;
          END;
     65:  BEGIN {F7 - TAKE AWAY A MINUTE}
               AdjustUsersTime(False,60);
               DidSomething := True;
          END;
     66:  BEGIN {F8 - GIVE THE USER A MINUTE}
               AdjustUsersTime(True,60);
               DidSomething := True;
          END;
     68:  BEGIN {F10 - BOOT THE CALLER}
               DoNodeActivity(3,'');
               Dispatcher(5);
          END;
     END;
     IF DidSomething THEN Status_Line;
     DoSysopPress := DidSomething;
END;


END.