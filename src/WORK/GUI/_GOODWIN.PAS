{$I DEFINES.INC}
UNIT _GoodWin;


INTERFACE


FUNCTION CheckRightWindows: Boolean;


IMPLEMENTATION


USES Globals,_VSave,Gunshot;


FUNCTION CheckRightWindows: Boolean;
VAR  HowMany  : Word;
     RawFile2 : _Raw_File;
     WhatToDo : Boolean;
     C        : Word;
BEGIN
     HowMany  := 0;
     WhatToDo := True;
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     {$I-}RESET(FWorkSg);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FWorkSg,RawFile2);
                IF RawFile2.Number=11 THEN INC(HowMany);
          UNTIL EOF(FWorkSg);
          CLOSE(FWorkSg);
     END;
     CASE HowMany OF
     0:   BEGIN
               IF NOT(VerifySave('All screens except BACKGRND.SG must have',
                  'a window as part of the screen. Do you','want to save this screen?'))
                  THEN WhatToDo := False;
          END;
     1:   ;
     ELSE BEGIN
               IF NOT(VerifySave('All screens can contain only one window.',
                  'Do you want to save this screen?','')) THEN WhatToDo := False;
          END;
     END;
     CheckRightWindows := WhatToDo;
END;


END.
