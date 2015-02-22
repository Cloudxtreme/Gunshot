{$I DEFINES.INC}
UNIT Time;


INTERFACE


PROCEDURE DATE_TIME;
FUNCTION  LongToStringTime      (TimeNumber: Longint) : String;
FUNCTION  Getting_Time_No_Secs                        : longint;
FUNCTION  Getting_Time                                : longint;


IMPLEMENTATION


USES Dos,Globals;


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
     IF Hours<10   THEN HStr := ' '+HStr;
     IF Minutes<10 THEN MStr := '0'+MStr;
     LongToStringTime := HStr+':'+MStr;
END;


FUNCTION Getting_Time: longint;
VAR  h1,m1,s1,hund1 : Word;
     temp_time      : longint;
     temp_time2     : longint;
BEGIN
     GetTime(h1,m1,s1,hund1);
     temp_time    := h1;
     temp_time    := temp_time*60;
     temp_time    := temp_time*60;
     temp_time2   := m1;
     temp_time2   := temp_time2*60;
     getting_time := temp_time+temp_time2+s1;
END;


FUNCTION Getting_Time_No_Secs: longint;
VAR  h1,m1,s1,hund1 : Word;
     temp_time      : longint;
     temp_time2     : longint;
BEGIN
     GetTime(h1,m1,s1,hund1);
     temp_time    := h1;
     temp_time    := temp_time*60;
     temp_time    := temp_time*60;
     temp_time2   := m1;
     temp_time2   := temp_time2*60;
     getting_time_no_secs := temp_time+temp_time2;
END;


PROCEDURE DATE_TIME;
CONST months : array [1..12] of String[20] =
               ('January','February','March','April','May','June','July',
                'August','September','October','November','December');
CONST days   : array [1..7] of String[20] =
               ('Sunday','Monday','Tuesday','Wednesday',
                'Thursday','Friday','Saturday');
VAR  yy,mm,dd,dow        : Word;
     hr,min,sec,hund     : Word;
     ext                 : String;
     date_time_temp      : string;
BEGIN
     {DATE}
     GetDate(yy,mm,dd,dow);
     TheMonth  := mm;
     TheDay    := dd;
     TheYear   := yy;
     MMDDYYYY := '';
     STR(mm,date_time_temp);
     IF LENGTH(Date_Time_Temp)=1 THEN Date_Time_Temp := '0'+Date_Time_Temp;
     MMDDYYYY := MMDDYYYY+Date_Time_Temp+'-';
     STR(dd,date_time_temp);
     IF LENGTH(Date_Time_Temp)=1 THEN Date_Time_Temp := '0'+Date_Time_Temp;
     MMDDYYYY := MMDDYYYY+Date_Time_Temp+'-';
     STR(yy,date_time_temp);
     MMDDYYYY := MMDDYYYY+Date_Time_Temp;
     STR(dd,date_time_temp);
     SystemDate := days[dow+1]+' '+months[mm]+' '+date_time_temp+',';
     STR(yy,date_time_temp);
     SystemDate := SystemDate+date_time_temp;
     {TIME}
     GetTime(hr,min,sec,hund);
     TheHour   := hr;
     TheMinute := min;
     TheSecond := sec;
     IF hr>11 THEN ext := 'pm'
              ELSE ext := 'am';
     IF hr>12 THEN hr := hr-12;
     IF hr=0 THEN hr := 12;
     STR(hr,date_time_temp);
     SystemTime := date_time_temp+':';
     STR(min,date_time_temp);
     IF LENGTH(date_time_temp)=1 THEN date_time_temp := '0'+date_time_temp;
     SystemTime := SystemTime+date_time_temp+ext;
END;


END.