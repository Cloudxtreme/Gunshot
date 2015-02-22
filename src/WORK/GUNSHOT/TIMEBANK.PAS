{$I DEFINES.INC}
UNIT TimeBank;


INTERFACE


PROCEDURE DepositTime;
PROCEDURE WithdrawTime;


IMPLEMENTATION


USES ANSIMisc,Screens,KeyInput,Globals,BsLog,BsString,Time,ApTimer;


PROCEDURE DepositTime;
VAR  tttt : Word;
BEGIN
     SendCrLf(2);
     System_Prompt('',87,false,true);
     Get_Number(4,'',False);
     SendCrLf(2);
     TimeLimit;
     IF input_string<>'' THEN
     BEGIN
          tttt := _Numeric(input_string)*60;
          IF (tttt>RemainingTimeInSecs(UsersTicker)) THEN
          BEGIN
               System_Prompt(_String(Trunc(RemainingTimeInSecs(UsersTicker)/60)),88,true,false);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.SecondsInBank)>system_info.TBank_Max) THEN
          BEGIN
               System_Prompt(_String(Trunc(system_info.TBank_Max/60)),89,true,false);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the time bank - Deposit of '+_String(Trunc(tttt/60))+' minutes',False);
               AdjustUsersTime(False,tttt);
               INC(UserRecord.SecondsInBank,tttt);
               TimeLimit;
          END;
     END;
END;


PROCEDURE WithdrawTime;
VAR  tttt : Word;
BEGIN
     SendCrLf(2);
     System_Prompt('',90,false,true);
     Get_Number(4,'',False);
     SendCrLf(2);
     IF input_string<>'' THEN
     BEGIN
          tttt := _Numeric(input_string)*60;
          IF (tttt>UserRecord.SecondsInBank) THEN
          BEGIN
               System_Prompt(_String(Trunc(UserRecord.SecondsInBank/60)),91,true,false);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.TimeBankWithdrawls)>system_info.TBank_Trans) THEN
          BEGIN
               System_Prompt(_String(Trunc(system_info.TBank_Trans/60)),92,true,false);
               System_Prompt(_String(Trunc(UserRecord.TimeBankWithdrawls/60)),93,true,false);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the time bank - Withdrawl of '+_String(Trunc(tttt/60))+' minutes',False);
               AdjustUsersTime(True,tttt);
               DEC(UserRecord.SecondsInBank,tttt);
               INC(UserRecord.TimeBankWithdrawls,tttt);
               TimeLimit;
          END;
     END;
END;


END.
