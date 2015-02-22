{$I DEFINES.INC}
UNIT Sema;


INTERFACE


PROCEDURE CreateSemaphore(Number: Word);
FUNCTION  GotARescan: Boolean;


IMPLEMENTATION


USES Globals,BsMulti,ApTimer,BsFile;


PROCEDURE CreateSemaphore(Number: Word);
VAR  Temp  : String;
     FFile : File;
BEGIN
     CASE Number OF
     1:   Temp := 'CFGSCAN.NOW';
     2:   Temp := 'RESCAN.NOW';
     END;
     _CreatePath(MailerInfo.Semaphores);
     ASSIGN(FFile,MailerInfo.Semaphores+Temp);
     REWRITE(FFile);
     CLOSE(FFile);
     IF Temp='RESCAN.NOW' THEN RescanDateTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
END;


FUNCTION GotARescan: Boolean;
VAR  NewTime : Longint;
BEGIN
     GotARescan := False;
     IF TimerExpired(RescanTimer) THEN
     BEGIN
          NewTime := _FileDate(MailerInfo.Semaphores+'RESCAN.NOW');
          IF (NewTime<>RescanDateTime) THEN
          BEGIN
               RescanDateTime := NewTime;
               GotARescan := True;
          END;
          NewTimerSecs(RescanTimer,6);
     END
     ELSE TimeSlice;
END;


END.