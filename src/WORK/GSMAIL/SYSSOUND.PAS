{$I DEFINES.INC}
UNIT SysSound;


INTERFACE


PROCEDURE DoSound(WhichOne: Byte);


IMPLEMENTATION


USES Crt,Globals,Time;


PROCEDURE DoSound(WhichOne: Byte);
VAR  Work : Longint;
BEGIN
     IF Mailer2Info.UseSound THEN
     BEGIN
          Work := Getting_Time;
          IF ((Work>=Mailer2Info.SoundStart) AND (Work<=Mailer2Info.SoundEnd)) THEN
          BEGIN
               CASE WhichOne OF
               1:   BEGIN {New Mail}
                         sound(1800); delay(60); nosound;
                         sound(2400); delay(60); nosound;
                         sound(1800); delay(60); nosound;
                         sound(2400); delay(60); nosound;
                    END;
               2:   BEGIN {New Fax}
                         sound(1800); delay(60); nosound;
                         sound(1200); delay(60); nosound;
                         sound(1800); delay(60); nosound;
                         sound(1200); delay(60); nosound;
                    END;
               END;
          END;
     END;
END;


END.
