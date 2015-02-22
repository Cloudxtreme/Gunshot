{$I DEFINES.INC}
UNIT AllGone;


INTERFACE


PROCEDURE Dispatcher(dispatch_type: byte);


IMPLEMENTATION


USES ApTimer,Globals,Time,BsLog,Screens,UserFile,ANSIMisc,
     Calls,Comm,Crt,ApCom,ExtDos,NodeFile,BsFile,BsTime,
     BsMulti,BsString;


PROCEDURE Dispatcher(dispatch_type: byte);
VAR  c             : char;
     dispatch_temp : string[20];
     TimerInfo     : EventTimer;
     Count         : Word;
     Retcode       : Integer;
     TheExitCode   : Word;
BEGIN
     _EraseFile(Shotgun_Directory+'\DROPFILE\DORINFO'+NodeString+'.DEF');
     LastUserOnline.TimeOff := _GetPrettyDate+' - '+_GetPrettyTime;
     IF (UserRecord.Name<>'') THEN
     BEGIN
          IF SuccessfulLogon=True THEN
          BEGIN
               LastUserOnline.Name := UserRecord.Name;
               ASSIGN(FLastUserOnline,DATA_Directory+'\LAST'+NodeString+'.DAT');
               REWRITE(FLastUserOnline);
               WRITE(FLastUserOnline,LastUserOnline);
               CLOSE(FLastUserOnline);
          END;
     END;
     IF user_name<>'' THEN
     BEGIN
          IF SuccessfulLogon=True THEN
          BEGIN
               UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker);
               IF UserRecord.SubModel=3 THEN INC(UserRecord.SubMinutesUsed,MinutesOn);
               UserRecord.last_logoff := _ProperDate;
          END;
          CASE dispatch_type OF
          0  : BEGIN
                    bsWriteLog(user_name+' logged off',False);
                    WriteUser;
               END;
          1  : BEGIN
                    bsWriteLog(user_name+' logged off',False);
                    WriteUser;
               END;
          2  : BEGIN
                    bsWriteLog(user_name+' dropped carrier',False);
                    WriteUser;
               END;
          3  : BEGIN
                    bsWriteLog(user_name+' exceeded time limit',False);
                    WriteUser;
               END;
          4  : BEGIN
                    bsWriteLog(user_name+' did not respond',False);
                    WriteUser;
               END;
          5  : BEGIN
                    bsWriteLog(user_name+' was booted off',False);
                    WriteUser;
               END;
          6  : BEGIN
                    bsWriteLog(user_name+' entered incorrect passwords',False);
               END;
          7  : BEGIN
                    bsWriteLog('System exit due to a pending system event',False);
                    WriteUser;
               END;
          END;
          IF ((user_name<>'') AND (UserRecord.UserList=1) AND (SuccessfulLogon)) THEN generate_last_callers;
          IF LocalLogon THEN _Delay(2000)
                        ELSE _Delay(5000);
     END;
     IF NOT(LocalLogon) THEN HANGUP;
     TextMode(Co80);
     TEXTCOLOR(7);
     TEXTBACKGROUND(0);
     WRITELN;
     IF sysop_next=True THEN
     BEGIN
          IF NOT(LocalLogon) THEN
          BEGIN
               _Delay(1000);
               ClearInBuffer;
               SetDTR(BBSPort,True);
               PutStringTimeout(BBSPort,NodeInfo.OffHook+#13,182);
          END;
          WRITELN('Waiting for sysop reply....... <PRESS A KEY!>');
          WRITELN;
          NewTimerSecs(TimerInfo,300);
          REPEAT
                sound(900);
                _delay(50);
                nosound;
                _delay(100);
                sound(1200);
                _delay(50);
                nosound;
                _delay(1000);
          UNTIL ((KeyPressed) OR (TimerExpired(TimerInfo)));
          nosound;
          IF KeyPressed THEN c := ReadKey;
          IF NOT(LocalLogon) THEN Hangup;
     END;
     IF NOT(LocalLogon) THEN Comm_deinit;
     DISPOSE(WorkBuffer);
     DISPOSE(Menu);
     Clear_Dirs;
     ClearNode;
     TheExitCode := 0;
     IF EnteredLocal THEN TheExitCode := System_Info.LocalExit;
     IF EnteredEcho THEN TheExitCode := System_Info.EchoExit;
     IF ((IsRip) AND (RipInitialized)) THEN Dispose(RIP,Done);
     WINDOW(1,1,80,25);
     TextColor(7);
     ClrScr;
     TextColor(11);
     TextBackground(1);
     GotoXY(1,1); ClrEol;
     GotoXY(1,1); WRITE('  Shotgun Professional End Run');
     TextColor(15);
     TextBackground(0);
     GotoXY(1,3);
     WRITELN('  Exit errorlevel: '+_String(TheExitCode));
     WRITELN;
     TextColor(7);
     DoNodeActivity(99,'');
     Halt(TheExitCode);
END;


END.
