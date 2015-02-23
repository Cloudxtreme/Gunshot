{$I DEFINES.INC}
UNIT AllGone;


INTERFACE


PROCEDURE dispatch(dispatch_type: byte);


IMPLEMENTATION


USES Gr2_Bp,BsGraph,_Buffers,Gx2_Bp,Gx2_BpVC,Globals,Tx2_Bp,ApTimer,
     Time,BsLog,Screens,UserFile,Calls,Crt,ExtDos,HeapVars,_Mouse,
     _Virtual,NodeFile,BsFile,BsTime,BsString;


PROCEDURE ShutDownGraphicsSystem;
VAR  Loop : Word;
BEGIN
     Fade_Out;
     KillBackDrop;
     FOR Loop := 1 TO 10 DO KillCutout(Loop);
     IF NCustom<>0 THEN
     BEGIN
          FOR Loop := 1 TO NCustom DO
          BEGIN
               DestroyVirtual(Custom^[Loop].Icon1);
               DestroyVirtual(Custom^[Loop].Icon2);
          END;
     END;
     IF NAnimate<>0 THEN
     BEGIN
          FOR Loop := 1 TO NAnimate DO
          BEGIN
               DestroyVirtual(Animate^[Loop].Icon[1]);
               DestroyVirtual(Animate^[Loop].Icon[2]);
               DestroyVirtual(Animate^[Loop].Icon[3]);
               DestroyVirtual(Animate^[Loop].Icon[4]);
               DestroyVirtual(Animate^[Loop].Icon[5]);
               DestroyVirtual(Animate^[Loop].Icon[6]);
               DestroyVirtual(Animate^[Loop].Icon[7]);
               DestroyVirtual(Animate^[Loop].Icon[8]);
          END;
     END;
     DestroyVirtual(IconHdr);
     DestroyVirtual(OffScreen);
     DestroyVirtual(WindowBack);
     txFreeFont(SystemFont);
     txFreeFont(HelvFont);
     txFreeFont(RomanFont);
     IF (LastFont<>'$%@$#^!%sf@$') THEN txFreeFont(workfont);
     txFreeFont(BitFont8x16);
     txFreeFont(BitFont8x14);
     txFreeFont(BitFont8x8);
     HideTheMouse;
     KillTheMouse;
     gxSetMode(GxText);
     gxDone;
     DisposeHeapVars;
END;

{ GOES THROUGH LOG OFF SEQUENCE }
PROCEDURE dispatch(dispatch_type: byte);
VAR  c             : char;
     dispatch_temp : string[20];
     TimerInfo     : EventTimer;
     Count         : Word;
     Retcode       : Integer;
     TheExitCode   : Word;
BEGIN
     IF doing_logoff THEN Exit;
     doing_logoff := true;
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
               IF dispatch_type<>3
                  THEN UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker)
                  ELSE UserRecord.SecondsRemaining := 0;
               IF UserRecord.SubModel=3 THEN INC(UserRecord.SubMinutesUsed,MinutesOn);
               UserRecord.last_logoff := _ProperDate;
          END;
          CASE dispatch_type OF
          0  : BEGIN
                    bsWriteLog(user_name+' logged off',False);
                    DisplayGraphicFile('GOODBYE',false,True,True);
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
                    DisplayGraphicFile('TIMEUP',false,True,True);
                    WriteUser;
               END;
          4  : BEGIN
                    bsWriteLog(user_name+' did not respond',False);
                    DisplayGraphicFile('TIMEOUT',false,True,True);
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
                    DisplayGraphicFile('EVENTIME',false,True,True);
                    WriteUser;
               END;
          END;
          IF ((user_name<>'') AND (UserRecord.UserList=1) AND (SuccessfulLogon)) THEN generate_last_callers;
          Delay(1000);
          HideTheMouse;
          LoadBackDrop(0,0,GraphMaxX,YWindow);
          ShowTheMouse;
          Delay(1000);
     END;
     ShutDownGraphicsSystem;
     ClrScr;
     TEXTCOLOR(7);
     TEXTBACKGROUND(0);
     WRITELN;
     Clear_Dirs;
     ClearNode;
     TheExitCode := 0;
     IF EnteredLocal THEN TheExitCode := System_Info.LocalExit;
     IF EnteredEcho THEN TheExitCode := System_Info.EchoExit;
     WINDOW(1,1,80,25);
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
