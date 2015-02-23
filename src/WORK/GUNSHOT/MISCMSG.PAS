{$I DEFINES.INC}
UNIT MiscMsg;


INTERFACE


USES Gunshot;


FUNCTION  TimeToLongint   (St: String)                           : Longint;
FUNCTION  ItsYours        (MessageTo,RealName,AliasName: String) : Boolean;
FUNCTION  GetNetOrigin    (Num: Word)                            : String;
FUNCTION  GetNetAddress   (Num: Word)                            : String;
FUNCTION  Remove_Kludge   (St: String)                           : String;
PROCEDURE FastBase_Yours;


IMPLEMENTATION


USES Globals,BsString,BsAkas;


FUNCTION Remove_Kludge(St: String): String;
VAR  Work : Word;
BEGIN
     {^A LINES}
     REPEAT
           Work := Pos(#1,St);
           IF (Work<>0) THEN St[Work] := '@';
     UNTIL Work=0;
     {SEEN-BY LINES}
     IF Pos('SEEN-BY',St)=1 THEN
     BEGIN
          St[5] := '@';
     END;
     {TEAR LINES}
     IF Pos('--- ',St)=1 THEN
     BEGIN
          St[2] := '+';
     END;
     {TEAR LINES}
     IF Pos(' * Origin',St)=1 THEN
     BEGIN
          St[2] := '+';
     END;
     Remove_Kludge := St;
END;


FUNCTION TimeToLongint(St: String): Longint;
VAR  Temp       : String;
     Worker     : Longint;
     W2         : Longint;
     Code       : Integer;
BEGIN
     Temp := _Mid(St,1,2); VAL(Temp,W2,Code); Worker := W2*3600;
     Temp := _Mid(St,4,5); VAL(Temp,W2,Code); Worker := Worker+(W2*60);
     Temp := _Mid(St,7,8); VAL(Temp,W2,Code); Worker := Worker+W2;
     TimeToLongint := Worker;
END;


PROCEDURE FastBase_Yours;
VAR  UsersRealName  : String;
     UsersAliasName : String;
     MessageFrom    : String;
     MessageTo      : String;
     Loop           : Word;
BEGIN
     MessageFrom    := _UpperCase(FastBaseHdr.MsgFrom);
     MessageTo      := _UpperCase(FastBaseHdr.MsgTo);
     UsersRealName  := _UpperCase(UserRecord.Name);
     UsersAliasName := _UpperCase(UserRecord.Alias);
     CanKill        := False;
     IsYours        := False;
     CanSee         := False;
     {Adjust Vars For UUCP Messages}
     IF ((MessageAreas.Area_Type>=30) AND (MessageAreas.Area_Type<=32)) THEN
     BEGIN
          FOR Loop := 1 TO LENGTH(UsersRealName) DO IF UsersRealName[Loop]=' ' THEN UsersRealName[Loop] := '.';
          FOR Loop := 1 TO LENGTH(UsersAliasName) DO IF UsersAliasName[Loop]=' ' THEN UsersAliasName[Loop] := '.';
          FOR Loop := 1 TO LENGTH(MessageFrom) DO IF MessageFrom[Loop]=' ' THEN MessageFrom[Loop] := '.';
          FOR Loop := 1 TO LENGTH(MessageTo) DO IF MessageTo[Loop]=' ' THEN MessageTo[Loop] := '.';
          Loop := Pos('@',MessageFrom); IF Loop<>0 THEN MessageFrom := _Mid(MessageFrom,1,Loop-1);
          Loop := Pos('@',MessageTo); IF Loop<>0 THEN MessageTo := _Mid(MessageTo,1,Loop-1);
     END;
     {Security Level Passthroughs}
     IF UserRecord.Security>=system_info.MessageKill THEN CanKill := True;
     IF (UserRecord.Security>=system_info.PrivateRead) THEN CanSee := True;
     IF FastBaseHdr.Priv=False THEN CanSee := True;
     {Crunch}
     IF UsersRealName=MessageFrom THEN
     BEGIN
          CanKill := True;
          CanSee := True;
     END;
     IF UsersRealName=MessageTo THEN
     BEGIN
          CanKill := True;
          CanSee := True;
          IsYours := True;
     END;
     IF (UsersAliasName<>'') THEN
     BEGIN
          IF UsersAliasName=MessageFrom THEN
          BEGIN
               CanKill := True;
               CanSee := True;
          END;
          IF UsersAliasName=MessageTo THEN
          BEGIN
               CanKill := True;
               CanSee := True;
               IsYours := True;
          END;
     END;
END;


FUNCTION ItsYours(MessageTo,RealName,AliasName: String): Boolean;
VAR  IsItYours : Boolean;
     Loop      : Word;
BEGIN
     IsItYours := False;
     MessageTo := _UpperCase(MessageTo);
     IF ((MessageAreas.Area_Type>=30) AND (MessageAreas.Area_Type<=32)) THEN
     BEGIN
          FOR Loop := 1 TO LENGTH(RealName) DO IF RealName[Loop]=' ' THEN RealName[Loop] := '.';
          FOR Loop := 1 TO LENGTH(AliasName) DO IF AliasName[Loop]=' ' THEN AliasName[Loop] := '.';
          FOR Loop := 1 TO LENGTH(MessageTo) DO IF MessageTo[Loop]=' ' THEN MessageTo[Loop] := '.';
          Loop := Pos('@',MessageTo); IF Loop<>0 THEN MessageTo := _Mid(MessageTo,1,Loop-1);
     END;
     {determine if its yours}
     IF RealName=MessageTo THEN IsItYours := True;
     IF (AliasName<>'') THEN
     BEGIN
          IF AliasName=MessageTo THEN IsItYours := True;
     END;
     ItsYours := IsItYours;
END;


FUNCTION GetNetAddress(Num: Word): String;
BEGIN
     ASSIGN(FNetWorkInfo,DATA_Directory+'\NETWORK.DAT');
     {$I-}RESET(FNetworkInfo);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetworkInfo)>=Num THEN
          BEGIN
               SEEK(FNetworkInfo,Num-1);
               READ(FNetworkInfo,NetworkInfo);
               GetNetAddress := AddressToString(NetworkInfo.Net_Address);
          END
          ELSE GetNetAddress := '';
          CLOSE(FNetworkInfo);
     END
     ELSE GetNetAddress :=  '';
END;


FUNCTION GetNetOrigin(Num: Word): String;
BEGIN
     ASSIGN(FNetOrigins,DATA_Directory+'\ORIGINS.DAT');
     {$I-}RESET(FNetOrigins);{$I+}
     IF IOResult=0 THEN
     BEGIN
          IF FileSize(FNetOrigins)>=Num THEN
          BEGIN
               SEEK(FNetOrigins,Num-1);
               READ(FNetOrigins,NetOrigins);
               GetNetOrigin := NetOrigins.Net_Origin;
          END
          ELSE GetNetOrigin := '';
          CLOSE(FNetOrigins);
     END
     ELSE GetNetOrigin := '';
END;


END.