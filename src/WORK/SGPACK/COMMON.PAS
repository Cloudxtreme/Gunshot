{$I DEFINES.INC}
UNIT Common;


INTERFACE


FUNCTION OutOfDate(InDate: String): Boolean;
FUNCTION PriorToDate(InDate: String): Boolean;


IMPLEMENTATION


USES BsTime,Globals;


FUNCTION OutOfDate(InDate: String): Boolean;
BEGIN
     IF PurgeDays=0 THEN
     BEGIN
       OutOfDate := False;
       Exit;
     END;
     IF DaysBetween(_PackedDate(InDate),TodaysDate)>PurgeDays
        THEN OutOfDate := True
        ELSE OutOfDate := False;
END;


FUNCTION PriorToDate(InDate: String): Boolean;
BEGIN
     IF BeforeDate=0 THEN
     BEGIN
       PriorToDate := False;
       Exit;
     END;
     IF _PackedDate(InDate)<BeforeDate
        THEN PriorToDate := True
        ELSE PriorToDate := False;
END;


END.