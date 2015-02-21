{$I DEFINES.INC}
UNIT BsTime;


INTERFACE


FUNCTION _PackedDate(InString: String): Longint;
FUNCTION _UnpackedDate(Work: Longint): String;
FUNCTION _GetPrettyDate: String;
FUNCTION _GetPrettyTime: String;
FUNCTION _ProperDateNoTime: Longint;
FUNCTION _DayOfWeek: String;
FUNCTION _ProperDate: Longint;
FUNCTION DaysBetween(Date1,Date2: Longint): Longint;
FUNCTION FormatMinSec(TotalSecs: LongInt): String;
FUNCTION _MMDDYYYY: String;


IMPLEMENTATION


USES Dos,BsString;


FUNCTION _UnpackedDate(Work: Longint): String;
VAR  DT       : DateTime;
     DD,MM,YY : String;
BEGIN
     UnpackTime(Work,DT);
     WITH DT DO
     BEGIN
       DD := _String(Day);
       MM := _String(Month);
       YY := _String(Year);
     END;
     IF MM[0]=#1 THEN MM := '0'+MM;
     IF DD[0]=#1 THEN DD := '0'+DD;
     _UnpackedDate := MM+'-'+DD+'-'+YY;
END;


FUNCTION _PackedDate(InString: String): Longint;
VAR  WorkTime : Longint;
     DT       : DateTime;
BEGIN
     FillChar(DT,SizeOf(DT),0);
     WITH DT DO
     BEGIN
       Year  := _Numeric(_Mid(InString,7,10));
       Month := _Numeric(_Mid(InString,1,2));
       Day   := _Numeric(_Mid(InString,4,5));
     END;
     PackTime(DT,WorkTime);
     _PackedDate := WorkTime;
END;


FUNCTION _GetPrettyDate: String;
VAR  Y,M,D,DOW   : Word;
     MonthString : String;
BEGIN
     GetDate(Y,M,D,DOW);
     CASE M OF
     1:   MonthString := 'January ';
     2:   MonthString := 'February ';
     3:   MonthString := 'March ';
     4:   MonthString := 'April ';
     5:   MonthString := 'May ';
     6:   MonthString := 'June ';
     7:   MonthString := 'July ';
     8:   MonthString := 'August ';
     9:   MonthString := 'September ';
     10:  MonthString := 'October ';
     11:  MonthString := 'November ';
     12:  MonthString := 'December ';
     END;
     _GetPrettyDate := MonthString+_String(D)+','+_String(Y);
END;


FUNCTION _GetPrettyTime: String;
VAR  h,m,s,hund : Word;
     Temp1      : String[2];
     Temp2      : String[2];
     DayTime    : String[2];
BEGIN
     GetTime(h,m,s,hund);
     IF h>12 THEN
     BEGIN
       Dec(h,12);
       DayTime := 'pm';
     END
     ELSE DayTime := 'am';
     Temp1 := _String(h);
     Temp2 := _String(m);
     IF Length(Temp2)=1 THEN Temp2 := '0'+Temp2;
     IF Temp1='0' THEN Temp1 := '12';
     _GetPrettyTime := Temp1+':'+Temp2+DayTime;
END;


FUNCTION _ProperDateNoTime: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     PackTime(DT,WorkDate);
     _ProperDateNoTime := WorkDate;
END;


FUNCTION _ProperDate: Longint;
VAR  DT           : DateTime;
     WorkDate     : Longint;
     yy,mm,dd,dow : Word;
     h,m,s,s100   : Word;
BEGIN
     GetDate(yy,mm,dd,dow);
     GetTime(h,m,s,s100);
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := yy;
     DT.Month := mm;
     DT.Day   := dd;
     DT.Hour  := h;
     DT.Min   := m;
     DT.Sec   := s;
     PackTime(DT,WorkDate);
     _ProperDate := WorkDate;
END;


FUNCTION FormatMinSec(TotalSecs: LongInt): String;
VAR  Min,Sec : LongInt;
     S       : String;
BEGIN
     Min := TotalSecs DIV 60;
     Sec := TotalSecs MOD 60;
     Str(Sec:2,S);
     IF S[1]=' ' THEN S[1] := '0';
     FormatMinSec := _String(Min)+':'+S;
END;


FUNCTION _MMDDYYYY: String;
VAR  y,m,d,dow : Word;
     yy,mm,dd  : String;
BEGIN
     GetDate(y,m,d,dow);
     yy := _String(y);
     mm := _String(m);
     dd := _String(d);
     IF mm[0]=#1 THEN mm := '0'+mm;
     IF dd[0]=#1 THEN dd := '0'+dd;
     _MMDDYYYY := mm+'-'+dd+'-'+yy;
END;


FUNCTION _DayOfWeek: String;
VAR  Y,M,D,DOW : Word;
BEGIN
     GetDate(Y,M,D,DOW);
     CASE DOW OF
     0:   _DayOfWeek := 'Sunday';
     1:   _DayOfWeek := 'Monday';
     2:   _DayOfWeek := 'Tuesday';
     3:   _DayOfWeek := 'Wednesday';
     4:   _DayOfWeek := 'Thursday';
     5:   _DayOfWeek := 'Friday';
     6:   _DayOfWeek := 'Saturday';
     END;
END;


FUNCTION Jul(TheDate: Longint): Real;
VAR  i,j,k,j2,ju : Real;
     DT          : DateTime;
     mo,da,yr    : Integer;
BEGIN
     UnpackTime(TheDate,DT);
     WITH DT DO
     BEGIN
          da := Day;
          mo := Month;
          yr := Year-1900;
     END;
     i   := yr;
     j   := mo;
     k   := da;
     j2  := int((j-14)/12);
     ju  := k-32075+int(1461*(i+4800+j2)/4);
     ju  := ju+int(367*(j-2-j2*12)/12);
     ju  := ju-int(3*int((i+4900+j2)/100)/4);
     Jul := ju;
END;


FUNCTION DaysBetween(Date1,Date2: Longint): Longint;
VAR  JDate1 : Real;
     JDate2 : Real;
     Out1   : String[25];
     Out2   : String[25];
     Code   : Integer;
     First  : Longint;
     Second : Longint;
BEGIN
     JDate1 := jul(Date1);
     JDate2 := jul(Date2);
     STR(JDate1:10:0,Out1);
     STR(JDate2:10:0,Out2);
     VAL(Out1,First,Code);
     VAL(Out2,Second,Code);
     DaysBetween := Second-First;
END;


END.