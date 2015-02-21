{$I DEFINES.INC}
UNIT Time;


INTERFACE


FUNCTION  LongToStringTime      (TimeNumber: Longint) : String;
FUNCTION  HoursMinutesSeconds   (InSeconds: Longint)  : String;
FUNCTION  Getting_Time_No_Secs                        : longint;
FUNCTION  Getting_Time                                : longint;


IMPLEMENTATION


USES Dos,Globals,BsString;


FUNCTION LongToStringTime(TimeNumber: Longint): String;
VAR  Minutes    : Longint;
     Hours      : Longint;
     MStr       : String;
     HStr       : String;
BEGIN
     Hours := Trunc(TimeNumber/3600);
     TimeNumber := TimeNumber-(Hours*3600);
     Minutes := Trunc(TimeNumber/60);
     IF Hours=0 THEN Hours := 12;
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


FUNCTION HoursMinutesSeconds(InSeconds: Longint): String;
VAR  Hours        : Longint;
     Minutes      : Longint;
     Seconds      : Longint;
     HH,MM,SS     : String;
BEGIN
     Hours        := Trunc(InSeconds/3600); DEC(InSeconds,(Hours*3600));
     Minutes      := Trunc(InSeconds/60);   DEC(InSeconds,(Minutes*60));
     Seconds      := InSeconds;
     HH           := _String(Hours);
     MM           := _String(Minutes);
     SS           := _String(Seconds);
     IF LENGTH(HH)=1 THEN HH := '0'+HH;
     IF LENGTH(MM)=1 THEN MM := '0'+MM;
     IF LENGTH(SS)=1 THEN SS := '0'+SS;
     HoursMinutesSeconds := HH+':'+MM+':'+SS;
END;


END.