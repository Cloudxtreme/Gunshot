{$I DEFINES.INC}
UNIT Time;


INTERFACE


{Users time calculations functions}
FUNCTION  TimeRemainingString   : String;
FUNCTION  MinutesOn             : Longint;
FUNCTION  MinutesRemaining      : Longint;
FUNCTION  AbsTimeLeft           : Longint;
PROCEDURE AdjustUsersTime       (AddSecs: Boolean; NumSecs: LongInt);
PROCEDURE TimeLimit;
{System time functions}
FUNCTION  GETTING_TIME          : longint;
FUNCTION  MMDDYYYY              : String;
FUNCTION  RemoveTime            (TimeNumber: Longint)    : Longint;
{Time formatting}
FUNCTION  LongToStringTime      (TimeNumber: Longint)    : String;
FUNCTION  LongToFormattedTime   (TimeNumber: Longint)    : String;
FUNCTION  StringToLongTime      (InString: String)       : Longint;
FUNCTION  ProperDateToFancyDate (STRNG: String)          : String;


IMPLEMENTATION


USES Dos,ApTimer,Globals,AllGone,BsString;


FUNCTION ProperDateToFancyDate(STRNG: String): String;
CONST months : array [1..12] of String =
               ('January','February','March','April',
                'May','June','July','August','September',
                'October','November','December');
VAR  Temp : String;
     MN   : Longint;
BEGIN
     MN := _Numeric(_Mid(Strng,1,2));
     Temp := Months[MN]+' ';
     Temp := Temp+_String(_Numeric(_Mid(Strng,4,5)))+',';
     Temp := Temp+_Mid(Strng,7,10);
     ProperDateToFancyDate := Temp;
END;


FUNCTION LongToStringTime(TimeNumber: Longint): String;
VAR  Minutes    : Longint;
     Hours      : Longint;
     MStr       : String;
     HStr       : String;
BEGIN
     Hours := Trunc(TimeNumber/3600);
     TimeNumber := TimeNumber-(Hours*3600);
     Minutes := Trunc(TimeNumber/60);
     STR(Hours,HStr);
     STR(Minutes,MStr);
     IF Hours<10   THEN HStr := '0'+HStr;
     IF Minutes<10 THEN MStr := '0'+MStr;
     LongToStringTime := HStr+':'+MStr;
END;


FUNCTION LongToFormattedTime(TimeNumber: Longint): String;
VAR  Minutes    : Longint;
     Hours      : Longint;
     MStr       : String;
     HStr       : String;
     Prefix     : String;
BEGIN
     Hours := Trunc(TimeNumber/3600);
     TimeNumber := TimeNumber-(Hours*3600);
     Minutes := Trunc(TimeNumber/60);
     IF Hours>12 THEN
     BEGIN
          Prefix := 'pm';
          DEC(Hours,12);
     END
     ELSE Prefix := 'am';
     STR(Hours,HStr);
     STR(Minutes,MStr);
     IF Minutes<10 THEN MStr := '0'+MStr;
     LongToFormattedTime := HStr+':'+MStr+prefix;
END;


FUNCTION StringToLongTime(InString: String): Longint;
VAR  Minutes    : Longint;
     Hours      : Longint;
     Seconds    : Longint;
     Code       : Integer;
BEGIN
     VAL(_Mid(InString,1,2),Hours,Code);
     VAL(_Mid(InString,4,5),Minutes,Code);
     VAL(_Mid(InString,7,8),Seconds,Code);
     Hours   := Hours*3600;
     Minutes := Minutes*60;
     StringToLongTime := Hours+Minutes+Seconds;
END;


FUNCTION GETTING_TIME: longint;
VAR  GETTING_TIME_h,
     GETTING_TIME_m,
     GETTING_TIME_s,
     GETTING_TIME_hund           : Word;
     GETTING_TIME_temp_time      : longint;
     GETTING_TIME_temp_time2     : longint;
BEGIN
     GetTime(GETTING_TIME_h,GETTING_TIME_m,GETTING_TIME_s,GETTING_TIME_hund);
     GETTING_TIME_temp_time  := GETTING_TIME_h;
     GETTING_TIME_temp_time  := GETTING_TIME_temp_time*60;
     GETTING_TIME_temp_time  := GETTING_TIME_temp_time*60;
     GETTING_TIME_temp_time2 := GETTING_TIME_m;
     GETTING_TIME_temp_time2 := GETTING_TIME_temp_time2*60;
     getting_time            := GETTING_TIME_temp_time+
                                GETTING_TIME_temp_time2+
                                GETTING_TIME_s;
END;


FUNCTION MMDDYYYY: String;
VAR  yy,mm,dd,dow        : Word;
     hr,min,sec,hund     : Word;
     date_time_temp      : string[80];
     TMMDDYYYY           : String[80];
BEGIN
     GetDate(yy,mm,dd,dow);
     TMMDDYYYY := '';
     STR(mm,date_time_temp);
     IF LENGTH(Date_Time_Temp)=1 THEN Date_Time_Temp := '0'+Date_Time_Temp;
     TMMDDYYYY := TMMDDYYYY+Date_Time_Temp+'-';
     STR(dd,date_time_temp);
     IF LENGTH(Date_Time_Temp)=1 THEN Date_Time_Temp := '0'+Date_Time_Temp;
     TMMDDYYYY := TMMDDYYYY+Date_Time_Temp+'-';
     STR(yy,date_time_temp);
     TMMDDYYYY := TMMDDYYYY+Date_Time_Temp;
     MMDDYYYY := TMMDDYYYY;
END;


FUNCTION TimeRemainingString: String;
VAR  TotalSeconds : Longint;
     Hours        : Longint;
     Minutes      : Longint;
     Seconds      : Longint;
     HH,MM,SS     : String;
BEGIN
     TotalSeconds := RemainingTimeInSecs(UsersTicker);
     Hours        := Trunc(TotalSeconds/3600); DEC(TotalSeconds,(Hours*3600));
     Minutes      := Trunc(TotalSeconds/60);   DEC(TotalSeconds,(Minutes*60));
     Seconds      := TotalSeconds;
     HH           := _String(Hours);
     MM           := _String(Minutes);
     SS           := _String(Seconds);
     IF LENGTH(HH)=1 THEN HH := '0'+HH;
     IF LENGTH(MM)=1 THEN MM := '0'+MM;
     IF LENGTH(SS)=1 THEN SS := '0'+SS;
     TimeRemainingString := HH+':'+MM+':'+SS;
END;


FUNCTION MinutesRemaining: Longint;
VAR  WorkTime : Longint;
BEGIN
     WorkTime := Round(RemainingTimeInSecs(UsersTicker)/60);
     MinutesRemaining := WorkTime;
END;


FUNCTION MinutesOn: Longint;
VAR  WorkTime : Longint;
BEGIN
     WorkTime := Round(ElapsedTimeInSecs(UsersTicker)/60);
     MinutesOn := WorkTime;
END;


PROCEDURE AdjustUsersTime(AddSecs: Boolean; NumSecs: LongInt);
VAR  WorkTime : Longint;
BEGIN
     WorkTime := RemainingTimeInSecs(UsersTicker);
     IF AddSecs THEN INC(WorkTime,NumSecs)
                ELSE DEC(WorkTime,NumSecs);
     IF WorkTime<0 THEN WorkTime := 1;
     IF WorkTime>1400*60 THEN WorkTime := 1400*60;
     UserRecord.SecondsRemaining := WorkTime;
     NewTimerSecs(UsersTicker,WorkTime);
END;


PROCEDURE TimeLimit;
BEGIN
     IF NOT(Doing_Logon) THEN
     BEGIN
          IF TimerExpired(UsersTicker) THEN dispatch(3);
          IF EventMinutes<>32000 THEN
          BEGIN
               IF TimerExpired(EventTicker) THEN dispatch(7);
          END;
     END;
END;


FUNCTION AbsTimeLeft: Longint;
VAR  ETime    : Longint;
     UTime    : Longint;
BEGIN
     IF EventMinutes<>32000 THEN
     BEGIN
          ETime := RemainingTimeInSecs(EventTicker);
          UTime := RemainingTimeInSecs(UsersTicker);
          IF ETime<UTime THEN AbsTimeLeft := ETime
                         ELSE AbsTimeLeft := UTime;
     END
     ELSE
     BEGIN
          UTime := RemainingTimeInSecs(UsersTicker);
          AbsTimeLeft := UTime;
     END;
END;


FUNCTION RemoveTime(TimeNumber: Longint): Longint;
VAR  DT1,DT2  : DateTime;
     Work     : Longint;
BEGIN
     FillChar(DT2,SizeOf(DT2),0);
     UnpackTime(TimeNumber,DT1);
     WITH DT1 DO
     BEGIN
          DT2.Day   := Day;
          DT2.Month := Month;
          DT2.Year  := Year;
     END;
     PackTime(DT2,Work);
     RemoveTime := Work;
END;


END.
