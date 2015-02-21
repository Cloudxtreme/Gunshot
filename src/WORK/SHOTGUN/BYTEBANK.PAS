{$I DEFINES.INC}
UNIT ByteBank;


INTERFACE


PROCEDURE DepositBytes;
PROCEDURE WithdrawBytes;


IMPLEMENTATION


USES ANSIMisc,Screens,KeyInput,Globals,BsLog,BsString;


PROCEDURE DepositBytes;
VAR  tttt : longint;
BEGIN
     SendCrLf(2);
     System_Prompt('',94,false,true);
     Get_Number(9,'',False);
     SendCrLf(2);
     IF input_string<>'' THEN
     BEGIN
          tttt := _Numeric(input_string);
          IF (tttt>UserAccess.daily_bytes) THEN
          BEGIN
               System_Prompt(_String(UserAccess.daily_bytes),95,true,false);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.ByteBankBalance)>system_info.BBank_Max) THEN
          BEGIN
               System_Prompt(_String(system_info.BBank_Max),96,true,false);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the byte bank - Deposit of '+_String(tttt)+' bytes',False);
               DEC(UserRecord.DLBytesRemaining,tttt);
               INC(UserRecord.ByteBankBalance,tttt);
          END;
     END;
END;


PROCEDURE WithdrawBytes;
VAR  tttt : longint;
BEGIN
     SendCrLf(2);
     System_Prompt('',97,false,true);
     Get_Number(9,'',False);
     SendCrLf(2);
     IF input_string<>'' THEN
     BEGIN
          tttt := _Numeric(input_string);
          IF (tttt>UserRecord.ByteBankBalance) THEN
          BEGIN
               System_Prompt(_String(UserRecord.ByteBankBalance),98,true,false);
               Get_Enter;
          END
          ELSE IF ((tttt+UserRecord.ByteBankWithdrawls)>system_info.BBank_Trans) THEN
          BEGIN
               System_Prompt(_String(system_info.BBank_Trans),99,true,false);
               System_Prompt(_String(UserRecord.ByteBankWithdrawls),100,true,false);
               Get_Enter;
          END
          ELSE
          BEGIN
               bsWriteLog('Using the byte bank - Withdrawl of '+_String(tttt)+' bytes',False);
               INC(UserRecord.DLBytesRemaining,tttt);
               DEC(UserRecord.ByteBankBalance,tttt);
               INC(UserRecord.ByteBankWithdrawls,tttt);
          END;
     END;
END;


END.