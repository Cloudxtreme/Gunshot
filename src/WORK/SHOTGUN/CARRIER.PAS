{$I DEFINES.INC}
UNIT Carrier;


INTERFACE


PROCEDURE CheckForCarrier;


IMPLEMENTATION


USES Globals,ApTimer,ApCom,AllGone,BsMulti,Status;


PROCEDURE CheckForCarrier;
BEGIN
     IF LocalLogon THEN
     BEGIN
          TimeSlice;
          Exit;
     END
     ELSE
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
END;


END.