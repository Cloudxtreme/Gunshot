{$I DEFINES.INC}
UNIT Info;


INTERFACE


PROCEDURE DrawAka;
PROCEDURE LastCalls;
PROCEDURE SystemInformation(IsFirst: Boolean);


IMPLEMENTATION


USES Globals,FastW1,Time,Sema,Events,BsMulti,Misc,ApTimer,Saver,
     ApPort,BsAkas,BsString,BsTime,BsVideo;


PROCEDURE DrawAka;
BEGIN
     ASSIGN(FNetwork,Gunshot_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     SEEK(FNetwork,CurrentAka-1);
     READ(FNetwork,Network);
     CLOSE(FNetwork);
     FastWrite(_PadRight(AddressToString(NetWork.Net_Address),20),2,8,GunshotColours.GSMailStatusHighlight);
END;


PROCEDURE LastCalls;
BEGIN
     ASSIGN(FLCallers,Gunshot_Directory+'\DATA\LCALLSGM.'+_String(SimNode));
     {$I-}RESET(FLCallers);{$I+}
     IF IOResult=0 THEN
     BEGIN
          {$I-}READ(FLCallers,LCallers);{$I+}
          IF IOResult=0 THEN;
          CLOSE(FLCallers);
     END
     ELSE
     BEGIN
          FillChar(LCallers,SizeOf(LCallers),0);
          REWRITE(FLCallers);
          WRITE(FLCallers,LCallers);
          CLOSE(FLCallers);
     END;
     ASSIGN(FMailHistory,Gunshot_Directory+'\DATA\MAILHIST.'+_String(SimNode));
     {$I-}RESET(FMailHistory);{$I+}
     IF IOResult=0 THEN
     BEGIN
          SEEK(FMailHistory,6);
          READ(FMailHistory,MailHistory);
          CLOSE(FMailHistory);
     END
     ELSE
     BEGIN
          FillChar(MailHistory,SizeOf(MailHistory),0);
          REWRITE(FMailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          WRITE(FMailHistory,MailHistory);
          CLOSE(FMailHistory);
     END;
     IF IOResult=0 THEN;
END;


PROCEDURE SystemInformation(IsFirst: Boolean);
VAR  Temp : String;

     PROCEDURE DateStuff;
     BEGIN
          FastWrite(_PadRight(_DayOfWeek+' '+_GetPrettyDate,27),Window2+5,23,GunshotColours.GSMailTimeDateData);
          FastWrite(_PadRight(_GetPrettyTime,8),Window2+5,9,GunshotColours.GSMailTimeDateData);
          {Users}
          IF MailerInfo.MailOnly THEN Temp := ' ' ELSE Temp := 'þ';
          FastWrite(Temp,5,4,GunshotColours.GSMailToggles);
          {Faxes}
          IF MailerInfo.HandleFaxes THEN Temp := 'þ' ELSE Temp := ' ';
          FastWrite(Temp,6,4,GunshotColours.GSMailToggles);
          {Freqs}
          IF MailerInfo.AllowFreqs THEN Temp := 'þ' ELSE Temp := ' ';
          FastWrite(Temp,7,4,GunshotColours.GSMailToggles);
          {EMSI}
          IF MailerInfo.EnableEMSI THEN Temp := 'þ' ELSE Temp := ' ';
          FastWrite(Temp,5,14,GunshotColours.GSMailToggles);
          {YooHoo}
          IF MailerInfo.EnableYooHoo THEN Temp := 'þ' ELSE Temp := ' ';
          FastWrite(Temp,6,14,GunshotColours.GSMailToggles);
          {ZedZap}
          IF Mailer2Info.UseZedZapTransfers THEN Temp := 'þ' ELSE Temp := ' ';
          FastWrite(Temp,7,14,GunshotColours.GSMailToggles);
     END;

BEGIN
     IF DataChanged THEN
     BEGIN
          KillSaver;
          DataChanged := False;
          {Clear Out Old Stuff}
          FastWrite(_PadRight('',39),Window2+1,2,GunshotColours.GSMailInfoHighlight);
          FastWrite(_PadRight('',39),Window2+2,2,GunshotColours.GSMailInfo);
          FastWrite(_PadRight('',39),Window2+3,2,GunshotColours.GSMailInfo);
          FastWrite(_PadRight('',38),Window2+1,42,GunshotColours.GSMailInfoHighlight);
          FastWrite(_PadRight('',38),Window2+2,42,GunshotColours.GSMailInfo);
          FastWrite(_PadRight('',38),Window2+3,42,GunshotColours.GSMailInfo);
          {CALL TOTALS}
          FastWrite(_PadRight(_String(LCallers.MailCalls),5),1,76,GunshotColours.GSMailStatusHighlight);
          FastWrite(_PadRight(_String(LCallers.BBSCalls),5),2,76,GunshotColours.GSMailStatusHighlight);
          FastWrite(_PadRight(_String(LCallers.FAXCalls),5),3,76,GunshotColours.GSMailStatusHighlight);
          {FROM}
          FastWrite(_Mid(LCallers.FrmSystem,1,38),Window2+1,3,GunshotColours.GSMailInfoHighlight);
          FastWrite(_Mid(LCallers.FrmLocation,1,38),Window2+2,3,GunshotColours.GSMailInfo);
          FastWrite(LCallers.FrmCallDate+', '+LCallers.FrmCallTime,Window2+3,3,GunshotColours.GSMailInfo);
          Temp := LCallers.FrmAddress;
          FastWrite(Temp,Window2+3,40-LENGTH(Temp),GunshotColours.GSMailInfo);
          {TO}
          FastWrite(_Mid(LCallers.ToSystem,1,37),Window2+1,43,GunshotColours.GSMailInfoHighlight);
          FastWrite(_Mid(LCallers.ToLocation,1,37),Window2+2,43,GunshotColours.GSMailInfo);
          FastWrite(LCallers.ToCallDate+', '+LCallers.ToCallTime,Window2+3,43,GunshotColours.GSMailInfo);
          Temp := LCallers.ToAddress;
          FastWrite(Temp,Window2+3,79-LENGTH(Temp),GunshotColours.GSMailInfo);
     END
     ELSE TimeSlice;
     IF IsFirst THEN
     BEGIN
          KillSaver;
          DateStuff;
     END
     ELSE
     BEGIN
          IF TimerExpired(InfoTimer) THEN
          BEGIN
               TimeSlice;
               CheckSemaphores;
               IF (LastTime<>_GetPrettyTime) THEN
               BEGIN
                    LastTime := _GetPrettyTime;
                    CheckCallerDate;
                    CheckEvents;
                    IF NOT(SaverActive) THEN DateStuff;
               END
               ELSE TimeSlice;
               NewTimerSecs(InfoTimer,6);
          END
          ELSE TimeSlice;
     END;
END;


END.