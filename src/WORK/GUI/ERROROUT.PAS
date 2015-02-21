{$I DEFINES.INC}
UNIT ErrorOut;


INTERFACE


PROCEDURE DropError(Num: Word);


IMPLEMENTATION


USES Crt;


PROCEDURE DropError(Num: Word);
VAR  Temp : String;
BEGIN
     CASE Num OF
     1:   Temp := 'Mouse not installed. Please load your mouse driver.';
     2:   Temp := 'SVGA mode not found. Try using a VESA driver.';
     3:   Temp := 'Could not install DMM manager. Free some conventional mem.';
     4:   Temp := 'Buffer allocation error @entry point : #004';
     5:   Temp := 'Buffer allocation error @entry point : #005';
     6:   Temp := 'Buffer allocation error @entry point : #006';
     7:   Temp := 'Buffer allocation error @entry point : #007';
     8:   Temp := 'Buffer allocation error @entry point : #008';
     9:   Temp := 'Buffer allocation error @entry point : #009';
     10:  Temp := 'Font loader error @entry point : #001';
     11:  Temp := 'Font loader error @entry point : #001';
     12:  Temp := 'Couldn''t install XMM driver. Install EMS memory.';
     13:  Temp := 'Buffer allocation error @entry point : #010';
     END;
     TextMode(co80);
     ClrScr;
     TextBackground(4);
     TextColor(15);
     ClrEol;
     WRITELN('  SERIOUS CRITICAL ERROR!!!');
     TextBackground(0);
     WRITELN;
     WRITELN('     '+Temp);
     WRITELN;
     Halt;
END;


END.
