{$I DEFINES.INC}
UNIT IconMisc;


INTERFACE


PROCEDURE LoadInIcon (Num: Word);
FUNCTION  WhatSize   (FileN: String): Word;


IMPLEMENTATION


USES Globals,BsFile,Shotgun;


FUNCTION WhatSize(FileN: String): Word;
VAR  Work_Icon30_2  : _Icon30x30;
     Work_Icon16_2  : _Icon16x16;
     FWork_Icon30_2 : File Of _Icon30x30;
     FWork_Icon16_2 : File Of _Icon16x16;
     Work           : Word;
     FFile          : File;
     FSize          : Longint;
BEGIN
     {CHECK 30 FIRST}
     FSize := _FileSize(FileN);
     IF FSize/SizeOf(_Icon30x30)=Trunc(FSize/SizeOf(_Icon30x30)) THEN
     BEGIN
          WhatSize := 30;
          Exit;
     END;
     {CHECK 16 NEXT}
     FSize := _FileSize(FileN);
     IF FSize/SizeOf(_Icon16x16)=Trunc(FSize/SizeOf(_Icon16x16)) THEN
     BEGIN
          WhatSize := 16;
          Exit;
     END;
     {LASTLY ASSUME 30}
     WhatSize := 30;
END;


PROCEDURE LoadInIcon(Num: Word);
BEGIN
     CASE CurrentSize OF
     16:  BEGIN
               ASSIGN(FIcon16,ICONDir+CurrentIFile);
               RESET(FIcon16);
               SEEK(FIcon16,Num-1);
               READ(FIcon16,Work_Icon16);
               CLOSE(FIcon16);
          END;
     30:  BEGIN
               ASSIGN(FIcon30,ICONDir+CurrentIFile);
               RESET(FIcon30);
               SEEK(FIcon30,Num-1);
               READ(FIcon30,Work_Icon30);
               CLOSE(FIcon30);
          END;
     END;
END;


END.
