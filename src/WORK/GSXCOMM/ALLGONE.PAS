{$I DEFINES.INC}
UNIT AllGone;


INTERFACE


PROCEDURE Dispatcher(dispatch_type: byte);


IMPLEMENTATION


USES Globals,ApTimer,BsString,BsFile,Time,BsLog,UserFile,
     Calls,BsMulti,ApPort,ApCom,Crt,Comm,ExtDos,NodeFile,
     BsComp,BsTime;


PROCEDURE ShutDownGraphicsSystem;
BEGIN
     DISPOSE(CBuffer);
     TBufferedFile.Done;
END;


PROCEDURE Dispatcher(dispatch_type: byte);
VAR  c             : char;
     dispatch_temp : string[20];
     TimerInfo     : EventTimer;
     Count         : Word;
     Retcode       : Integer;
     TheExitCode   : Word;
BEGIN
     _EraseFile(Gunshot_Directory+'\DROPFILE\DORINFO'+NodeString+'.DEF');
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
                    bsWriteLog(user_name+' logged off',True);
                    WriteUser;
               END;
          1  : BEGIN
                    bsWriteLog(user_name+' logged off',True);
                    WriteUser;
               END;
          2  : BEGIN
                    bsWriteLog(user_name+' dropped carrier',True);
                    WriteUser;
               END;
          3  : BEGIN
                    bsWriteLog(user_name+' exceeded time limit',True);
                    WriteUser;
               END;
          4  : BEGIN
                    bsWriteLog(user_name+' did not respond',True);
                    WriteUser;
               END;
          5  : BEGIN
                    bsWriteLog(user_name+' was booted off',True);
                    WriteUser;
               END;
          6  : BEGIN
                    bsWriteLog(user_name+' entered incorrect passwords',True);
               END;
          7  : BEGIN
                    bsWriteLog('System exit due to a pending system event',True);
                    WriteUser;
               END;
          END;
          IF ((user_name<>'') AND (UserRecord.UserList=1) AND (SuccessfulLogon)) THEN generate_last_callers;
          bsWriteLog('Session errors: '+_String(SessionErrors),True);
          _Delay(6000);
          PutStringTimeout(BBSPort,#255#2#13,YappDelay);
          _Delay(1000);
     END;
     HANGUP;
     ShutDownGraphicsSystem;
     ClrScr;
     TEXTCOLOR(7);
     TEXTBACKGROUND(0);
     WRITELN;
     IF sysop_next=True THEN
     BEGIN
          _Delay(1000);
          FlushInBuffer(BBSPort);
          SetDTR(BBSPort,True);
          PutStringTimeout(BBSPort,NodeInfo.OffHook+#13,182);
          TEXTCOLOR(15);
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
          Hangup;
     END;
     Comm_deinit;
     DISPOSE(MENU);
     Clear_Dirs;
     ClearNode;
     TheExitCode := 0;
     IF EnteredLocal THEN TheExitCode := System_Info.LocalExit;
     IF EnteredEcho THEN TheExitCode := System_Info.EchoExit;
     Window(1,1,80,25);
     TextColor(7);
     ClrScr;
     TextColor(11);
     TextBackground(1);
     GotoXY(1,1); ClrEol;
     GotoXY(1,1); WRITE('  Gunshot Professional End Run');
     TextColor(15);
     TextBackground(0);
     GotoXY(1,3);
     WRITELN('  Exit errorlevel: '+_String(TheExitCode));
     WRITELN;
     IF dispatch_type=8 THEN
     BEGIN
          WRITELN('  Exit due to critical error. Language was not found. SGX must');
          WRITELN('  be launched after SG. See SAMPLE.BAT for more information.');
          WRITELN;
     END;
     DoNodeActivity(99,'');
     Halt(TheExitCode);
END;


END.
