{$I DEFINES.INC}
UNIT Carrier;


INTERFACE


PROCEDURE CheckForCarrier;


IMPLEMENTATION


USES ApCom,AllGone,BsMulti,Globals,Status,ApTimer;


PROCEDURE CheckForCarrier;
BEGIN
     IF TimerExpired(CarrierTimer) THEN
     BEGIN
          NewTimerSecs(CarrierTimer,4);
          IF NOT(CheckDCD(BBSPort)) THEN
          BEGIN
               status_line;
               FlushInBuffer(BBSPort);
               FlushOutBuffer(BBSPort);
               Dispatcher(2);
          END
          ELSE TimeSlice;
     END
     ELSE TimeSlice;
END;


END.
