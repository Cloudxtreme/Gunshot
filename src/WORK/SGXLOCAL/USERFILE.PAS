{$I DEFINES.INC}
UNIT UserFile;


INTERFACE


PROCEDURE Subscription;
PROCEDURE WriteNewUser;
PROCEDURE UpdateDlRatio;
PROCEDURE WriteUser;
PROCEDURE UpdateAccess            (access_level: word);
PROCEDURE GetAccessLevelDefaults  (access_level: word);
PROCEDURE SetUsersAccessDefaults  (access_level: word);
PROCEDURE GetUserInfo             (User: String; VAR UserExists,CanRead: Boolean; ReadAccess: Word);
FUNCTION  GetUserName             (User: Longint): String;
FUNCTION  UserFound               : boolean;
FUNCTION  AliasExists             : boolean;


IMPLEMENTATION


USES Globals,ErrorLog,Time,ApTimer,BsString,BsTime;


{RETRIEVES A USER ACCESS LEVEL}
PROCEDURE GetAccessLevelDefaults(access_level: word);
BEGIN
     ASSIGN(FUserAccess,DATA_Directory+'\ACCESS.DAT');
     RESET(FUserAccess);
     REPEAT
           READ(FUserAccess,UserAccess);
     UNTIL ((UserAccess.Access_Level=Access_Level) OR (EOF(FUserAccess)));
     CLOSE(FUserAccess);
     IF UserAccess.Access_Level<>Access_Level THEN
     BEGIN
          DoErrorLog(23,_String(Access_Level));
          FillChar(UserAccess,SizeOf(UserAccess),0);
     END;
END;


{RETURNS TRUE IF THE USER IS IN THE DATABASE}
FUNCTION UserFound: boolean;
VAR  done      : Byte;
     LogonIBM  : Byte;
BEGIN
     LogonIBM  := UserRecord.Ibm;
     userfound := false;
     new_user_number := 0;
     ASSIGN(FUserRecord,DATA_Directory+'\USERS.BBS');
     {$I-}RESET(FUserRecord);{$I+}
     IF (ioresult=0) THEN
     BEGIN
          done  := 0;
          read(FUserRecord,UserRecord);
          new_user_number := UserRecord.user_number;
          REPEAT
                read(FUserRecord,UserRecord);
                IF (_UpperCase(UserRecord.name)=_UpperCase(user_name)) THEN
                BEGIN
                     done := 1;
                     userfound  := true;
                     user_name   := UserRecord.name;
                END
                ELSE IF (_UpperCase(UserRecord.alias)=_UpperCase(user_name)) THEN
                BEGIN
                     IF System_Info.Alias_System THEN
                     BEGIN
                          done := 1;
                          userfound  := true;
                          user_name   := UserRecord.name;
                     END;
                END;
          UNTIL (eof(FUserRecord) OR (done=1));
          CLOSE(FUserRecord);
          IF Done<>1 THEN UserRecord.Ibm := LogonIBM;
     END
     ELSE userfound := false;
END;


{FOR FIRST TIME CALLERS - SETS INITIAL ACCESS LEVELS}
PROCEDURE SetUsersAccessDefaults(access_level: word);
VAR  AccLevel : Word;
BEGIN
     AccLevel := 0;
     ASSIGN(FUserAccess,DATA_Directory+'\ACCESS.DAT');
     RESET(FUserAccess);
     REPEAT
           READ(FUserAccess,UserAccess);
           IF UserAccess.Access_Level<=Access_Level THEN AccLevel := UserAccess.Access_Level;
     UNTIL ((UserAccess.Access_Level=Access_Level) OR (EOF(FUserAccess)));
     CLOSE(FUserAccess);
     IF UserAccess.Access_Level<>Access_Level THEN
     BEGIN
          DoErrorLog(24,_String(Access_Level));
          FillChar(UserAccess.Access_Level,SizeOf(UserAccess.Access_Level),0);
     END;
     UserRecord.security            := UserAccess.Access_Level;
     UserRecord.sex                 := 1;
     UserRecord.page                := UserAccess.Page;
     Move(UserAccess.Tags,UserRecord.Tags,10);
     UserRecord.file_lines          := 18;
     UserRecord.uploads             := 0;
     UserRecord.DLBytesToday        := 0;
     UserRecord.dl_total            := 0;
     UserRecord.files_uploaded      := 0;
     UserRecord.files_downloaded    := 0;
     UserRecord.file_ratio          := UserAccess.File_Ratio;
     UserRecord.byte_ratio          := UserAccess.Byte_Ratio;
     UserRecord.DLBytesRemaining    := UserAccess.Daily_Bytes;
     UserRecord.first_call          := _ProperDateNoTime;
     UserRecord.last_call           := _ProperDate;
     UserRecord.total_calls         := 0;
     UserRecord.SecondsRemaining    := UserAccess.Time;
     UserRecord.punt                := 0;
     UserRecord.userlist            := 1;
     UserRecord.PageFlag            := 1;
     UserRecord.ibm                 := 1;
     UserRecord.bad_logon           := 0;
     UserRecord.ver_user            := UserAccess.Verified;
     UserRecord.SecondsInBank       := UserAccess.TBank;
     UserRecord.ByteBankBalance     := UserAccess.BBank;
     UserRecord.TimeBankWithdrawls  := 0;
     UserRecord.ByteBankWithdrawls  := 0;
     UserRecord.SubLastChange       := _ProperDateNoTime;
     UserRecord.SubModel            := UserAccess.SubModel;
     UserRecord.Sub_Expiry          := 0;
     UserRecord.Expiry_Adjust       := UserAccess.ExpiryAccessLevel;
     UserRecord.SubMinutesUsed      := 0;
     UserRecord.SubCalendarDaysUsed := 0;
     UserRecord.SubCallDaysUsed     := 0;
END;


{PUTS A NEWS USER INTO THE DATABASE}
PROCEDURE WriteNewUser;
BEGIN
     ASSIGN(FUserRecord,DATA_Directory+'\users.bbs');
     RESET(FUserRecord);
     read(FUserRecord,UserRecord2^);
     UserRecord2^.user_number := new_user_number+1;
     RESET(FUserRecord);
     write(FUserRecord,UserRecord2^);
     SEEK(FUserRecord,FileSize(FUserRecord));
     write(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
END;


{CHECKS TO SEE IF AN ALIAS IS ALREADY IN USE}
FUNCTION AliasExists: boolean;
VAR  Temp : String;
BEGIN
     aliasExists := false;
     Temp := _UpperCase(UserRecord.alias);
     ASSIGN(FUserRecord,DATA_Directory+'\USERS.BBS');
     {$I-}RESET(FUserRecord);{$I+}
     IF (ioresult=0) THEN
     BEGIN
          read(FUserRecord,UserRecord2^);
          REPEAT
                read(FUserRecord,UserRecord2^);
                UserRecord2^.Name  := _UpperCase(UserRecord2^.Name);
                UserRecord2^.Alias := _UpperCase(UserRecord2^.Alias);
                IF ((UserRecord2^.name=Temp) OR (UserRecord2^.alias=Temp)) THEN
                BEGIN
                     aliasExists := true;
                END;
          UNTIL eof(FUserRecord);
          CLOSE(FUserRecord);
     END;
END;


{FOR UPDATING ACCESS LEVELS AFTER VERIFYING}
PROCEDURE UpdateAccess(access_level: word);
VAR  AccLevel : Longint;
BEGIN
     AccLevel := 999999;
     ASSIGN(FUserAccess,DATA_Directory+'\ACCESS.DAT');
     RESET(FUserAccess);
     REPEAT
           READ(FUserAccess,UserAccess);
           IF UserAccess.Access_Level<=Access_Level THEN AccLevel := UserAccess.Access_Level;
     UNTIL ((UserAccess.Access_Level=Access_Level) OR (EOF(FUserAccess)));
     CLOSE(FUserAccess);
     IF ((UserAccess.Access_Level<>Access_Level) OR (AccLevel=999999)) THEN
     BEGIN
          DoErrorLog(25,_String(Access_Level));
          FillChar(UserAccess.Access_Level,SizeOf(UserAccess.Access_Level),0);
     END;
     UserRecord.security            := UserAccess.Access_Level;
     UserRecord.SecondsRemaining    := UserAccess.Time;
     UserRecord.file_ratio          := UserAccess.File_Ratio;
     UserRecord.byte_ratio          := UserAccess.Byte_Ratio;
     UserRecord.DLBytesRemaining    := UserAccess.Daily_Bytes;
     Move(UserAccess.Tags,UserRecord.Tags,10);
     UserRecord.SecondsInBank       := UserAccess.TBank;
     UserRecord.ByteBankBalance     := UserAccess.BBank;
     UserRecord.page                := UserAccess.Page;
     UserRecord.ver_user            := UserAccess.Verified;
     UserRecord.Expiry_Adjust       := UserAccess.ExpiryAccessLevel;
     UserRecord.SubModel            := UserAccess.SubModel;
     UserRecord.Sub_Expiry          := 0;
     UserRecord.SubCalendarDaysUsed := 0;
     UserRecord.SubCallDaysUsed     := 0;
     UserRecord.SubLastChange       := _ProperDateNoTime;
     UserRecord.SubMinutesUsed      := 0;
     NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
END;


{UPDATES THE USER'S UL/DL RATIO}
PROCEDURE UpdateDlRatio;
VAR  ul_bytes : longint;
     dl_bytes : longint;
BEGIN
     IF UserAccess.NoFileRatio=1 THEN
     BEGIN
          ul_ratio := 1;
          dl_ratio := 1;
          Exit;
     END;
     dl_bytes := UserRecord.dl_total;
     ul_bytes := UserRecord.uploads;
     IF dl_bytes=0 THEN
     BEGIN
          ul_ratio := ul_bytes;
          IF ul_ratio>15 THEN ul_ratio := 15;
          dl_ratio := 1;
     END
     ELSE IF ul_bytes=0 THEN
     BEGIN
          dl_ratio := dl_bytes;
          IF dl_ratio>15 THEN dl_ratio := 15;
          ul_ratio := 1;
     END
     ELSE
     BEGIN
          IF dl_bytes>=ul_bytes THEN
          BEGIN
               ul_ratio := 1;
               dl_ratio := ROUND(dl_bytes/ul_bytes);
          END
          ELSE
          BEGIN
               dl_ratio := 1;
               ul_ratio := ROUND(ul_bytes/dl_bytes);
          END;
          IF ul_ratio>15 THEN ul_ratio := 15;
          IF dl_ratio>15 THEN dl_ratio := 15;
     END;
END;


{UPDATES THE USER'S ACCOUNT TO THE DATABASE - SHOULD BE CALLED WHENEVER}
{THE USERS STATS OR OPTIONS CHANGE IN ANY WAY!!!!                      }
PROCEDURE WriteUser;
VAR
     location   : longint;
BEGIN
     location := 0;
     ASSIGN(FUserRecord,DATA_Directory+'\users.bbs');
     RESET(FUserRecord);
     REPEAT
           read(FUserRecord,UserRecord2^);
           IF ((UserRecord2^.user_number=UserRecord.user_number) AND
              (UserRecord2^.name=UserRecord.name)) THEN
           BEGIN
                location := FilePos(FUserRecord);
           END;
     UNTIL ((EOF(FUserRecord)) OR (location<>0));
     CLOSE(FUserRecord);
     IF location<>0 THEN
     BEGIN
          DEC(location);
          ASSIGN(FUserRecord,DATA_Directory+'\users.bbs');
          RESET(FUserRecord);
          SEEK(FUserRecord,location);
          WRITE(FUserRecord,UserRecord);
          CLOSE(FUserRecord);
     END;
END;


PROCEDURE Subscription;
VAR  OldTBank : Longint;
     OldBBank : Longint;
BEGIN
     OldBBank := UserRecord.ByteBankBalance;
     OldTBank := UserRecord.SecondsInBank;
     CASE UserRecord.SubModel OF
     0:   ; {Not A Subscriber}
     1:   BEGIN {Calendar Day Expiry}
               IF UserRecord.SubCalendarDaysUsed>UserAccess.SubCalendarDays THEN
               BEGIN
                    UpdateAccess(UserRecord.Expiry_adjust);
                    UserRecord.SecondsInBank   := OldTBank;
                    UserRecord.ByteBankBalance := OldBBank;
               END;
          END;
     2:   BEGIN {Call Day Expiry}
               IF UserRecord.SubCallDaysUsed>UserAccess.SubCallDays THEN
               BEGIN
                    UpdateAccess(UserRecord.Expiry_adjust);
                    UserRecord.SecondsInBank   := OldTBank;
                    UserRecord.ByteBankBalance := OldBBank;
               END;
          END;
     3:   BEGIN {Minutes Used Expiry}
               IF UserRecord.SubMinutesUsed>UserAccess.SubMinutes THEN
               BEGIN
                    UpdateAccess(UserRecord.Expiry_adjust);
                    UserRecord.SecondsInBank   := OldTBank;
                    UserRecord.ByteBankBalance := OldBBank;
               END;
          END;
     ELSE BEGIN {Calendar Date Expiry - Original}
               IF UserRecord.Sub_Expiry<=_ProperDateNoTime THEN
               BEGIN
                    UpdateAccess(UserRecord.Expiry_adjust);
                    UserRecord.SecondsInBank   := OldTBank;
                    UserRecord.ByteBankBalance := OldBBank;
               END;
          END;
     END;
END;


PROCEDURE GetUserInfo(User: String; VAR UserExists,CanRead: Boolean; ReadAccess: Word);
VAR  Enough : Boolean;
BEGIN
     UserExists := False;
     CanRead    := False;
     ASSIGN(FUserRecord,DATA_Directory+'\users.bbs');
     RESET(FUserRecord);
     READ(FUserRecord,UserRecord2^);
     Enough := False;
     REPEAT
           READ(FUserRecord,UserRecord2^);
           IF ((_UpperCase(UserRecord2^.Name)=_UpperCase(User)) OR
              (_UpperCase(UserRecord2^.Name)=_UpperCase(User))) THEN
           BEGIN
                Enough     := True;
                UserExists := True;
                IF (UserRecord2^.Security>=ReadAccess)
                   THEN CanRead := True
                   ELSE CanRead := False;
           END;
     UNTIL ((Enough) OR (EOF(FUserRecord)));
     CLOSE(FUserRecord);
END;


FUNCTION GetUserName(User: Longint): String;
BEGIN
     ASSIGN(FUserRecord,DATA_Directory+'\USERS.BBS');
     {$I-}RESET(FUserRecord);{$I+}
     IF (IOResult=0) THEN
     BEGIN
          READ(FUserRecord,UserRecord);
          REPEAT
                READ(FUserRecord,UserRecord);
                IF UserRecord.User_Number=User THEN
                BEGIN
                     GetUserName := UserRecord.name;
                     CLOSE(FUserRecord);
                     Exit;
                END;
          UNTIL EOF(FUserRecord);
          CLOSE(FUserRecord);
     END;
     GetUserName := '';
END;


END.
