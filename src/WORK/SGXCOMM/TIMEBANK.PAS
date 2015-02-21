{$I DEFINES.INC}
UNIT TimeBank;


INTERFACE


PROCEDURE DepositTime;
PROCEDURE WithdrawTime;


IMPLEMENTATION


USES Screens,KeyInput,Globals,BsLog,BsString,Gfx,Time,ApTimer;


PROCEDURE DepositTime;
VAR  tttt : Word;
BEGIN
     System_Prompt('',87);
     Get_Enter;
     TimeLimit;
     IF Fields[1].Text<>'' THEN
     BEGIN
          tttt := _Numeric(Fields[1].Text)*60;
          IF (tttt>RemainingTimeInSecs(UsersTicker)) THEN
          BEGIN
               System_Prompt(_String(Trunc(RemainingTimeInSecs(UsersTicker)/60)),88);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.SecondsInBank)>system_info.TBank_Max) THEN
          BEGIN
               System_Prompt(_String(Trunc(system_info.TBank_Max/60)),89);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the time bank - Deposit of '+_String(Trunc(tttt/60))+' minutes',True);
               AdjustUsersTime(False,tttt);
               INC(UserRecord.SecondsInBank,tttt);
               TimeLimit;
          END;
     END;
END;


PROCEDURE WithdrawTime;
VAR  tttt : Word;
BEGIN
     System_Prompt('',90);
     Get_Enter;
     IF Fields[1].Text<>'' THEN
     BEGIN
          tttt := _Numeric(Fields[1].Text)*60;
          IF (tttt>UserRecord.SecondsInBank) THEN
          BEGIN
               System_Prompt(_String(Trunc(UserRecord.SecondsInBank/60)),91);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.TimeBankWithdrawls)>system_info.TBank_Trans) THEN
          BEGIN
               System_Prompt(_String(Trunc(UserRecord.TimeBankWithdrawls/60)),92);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the time bank - Withdrawl of '+_String(Trunc(tttt/60))+' minutes',True);
               AdjustUsersTime(True,tttt);
               DEC(UserRecord.SecondsInBank,tttt);
               INC(UserRecord.TimeBankWithdrawls,tttt);
               TimeLimit;
          END;
     END;
END;


END.