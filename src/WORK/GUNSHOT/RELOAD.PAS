{$I DEFINES.INC}
UNIT ReLoad;


INTERFACE


PROCEDURE DumpUser;
PROCEDURE ReloadUser;


IMPLEMENTATION


USES Globals,ApTimer,Time;


PROCEDURE DumpUser;
BEGIN
     UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker);
     SavedTicker := UserRecord.SecondsRemaining;
     ASSIGN(FUserRecord,NODE_Directory+'\USERS.BBS');
     REWRITE(FUserRecord);
     WRITE(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
END;


PROCEDURE ReloadUser;
BEGIN
     Chdir(Gunshot_Directory);
     ASSIGN(FUserRecord,NODE_Directory+'\USERS.BBS');
     RESET(FUserRecord);
     READ(FUserRecord,UserRecord);
     CLOSE(FUserRecord);
     IF (SavedTicker<>UserRecord.SecondsRemaining) THEN
     BEGIN
          NewTimerSecs(UsersTicker,UserRecord.SecondsRemaining);
     END
     ELSE
     BEGIN
          IF TimerExpired(UsersTicker) THEN NewTimerSecs(UsersTicker,10);
          UserRecord.SecondsRemaining := RemainingTimeInSecs(UsersTicker);
     END;
     TimeLimit;
END;


END.
